import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DeliveryStatus, OrderStatus, Prisma } from '@prisma/client';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import {
  deliveryStatusForResponse,
  expectedDeliveryStatus,
  isDeliveryTransitionAllowed,
  requestedDeliveryStatus,
} from './delivery-state';
import { UpdateDeliveryStatusDto } from './dto/update-delivery-status.dto';

const activeDeliveryStatuses = [
  DeliveryStatus.ACCEPTED,
  DeliveryStatus.ARRIVED,
  DeliveryStatus.PICKED_UP,
];

const deliveryInclude = {
  order: {
    select: {
      id: true,
      orderNumber: true,
      status: true,
      currency: true,
      customerNotes: true,
      deliveryAddressSnapshot: true,
      customer: {
        select: {
          firstName: true,
          lastName: true,
          phone: true,
        },
      },
      merchant: {
        select: {
          id: true,
          name: true,
          streetAddress: true,
          city: true,
          state: true,
          postalCode: true,
          countryCode: true,
          latitude: true,
          longitude: true,
        },
      },
      deliveryAddress: {
        select: {
          recipientName: true,
          phone: true,
          line1: true,
          line2: true,
          city: true,
          state: true,
          postalCode: true,
          countryCode: true,
          latitude: true,
          longitude: true,
          deliveryNotes: true,
        },
      },
    },
  },
} satisfies Prisma.DeliveryInclude;

type DeliveryRecord = Prisma.DeliveryGetPayload<{
  include: typeof deliveryInclude;
}>;

@Injectable()
export class DeliveriesService {
  constructor(private readonly prisma: PrismaService) {}

  async findOffers() {
    const deliveries = await this.prisma.delivery.findMany({
      where: {
        status: DeliveryStatus.OFFERED,
        courierId: null,
      },
      include: deliveryInclude,
      orderBy: { offeredAt: 'desc' },
    });

    return {
      offers: deliveries.map((delivery) => this.serializeDelivery(delivery)),
    };
  }

  async findActive(user: AuthenticatedUser) {
    const deliveries = await this.prisma.delivery.findMany({
      where: {
        courierId: user.id,
        status: { in: activeDeliveryStatuses },
      },
      include: deliveryInclude,
      orderBy: { updatedAt: 'desc' },
    });

    return {
      deliveries: deliveries.map((delivery) =>
        this.serializeDelivery(delivery),
      ),
    };
  }

  async updateStatus(
    user: AuthenticatedUser,
    deliveryId: string,
    dto: UpdateDeliveryStatusDto,
  ) {
    const requestedStatus = requestedDeliveryStatus(dto.status);
    const delivery =
      requestedStatus === DeliveryStatus.ACCEPTED
        ? await this.acceptOffer(user, deliveryId)
        : await this.advanceOwnedDelivery(user, deliveryId, requestedStatus);

    return this.serializeDelivery(delivery);
  }

  private async acceptOffer(user: AuthenticatedUser, deliveryId: string) {
    return this.inDispatchTransaction(async (transaction) => {
      const profile = await transaction.courierProfile.findUnique({
        where: { userId: user.id },
        select: { isAvailable: true },
      });
      if (!profile?.isAvailable) {
        throw new ForbiddenException(
          'Set courier availability to true before accepting a delivery.',
        );
      }

      const activeDelivery = await transaction.delivery.findFirst({
        where: {
          courierId: user.id,
          status: { in: activeDeliveryStatuses },
        },
        select: { id: true },
      });
      if (activeDelivery) {
        throw new ConflictException(
          'Complete the current delivery before accepting another offer.',
        );
      }

      const delivery = await transaction.delivery.findUnique({
        where: { id: deliveryId },
        select: { id: true, orderId: true, courierId: true, status: true },
      });
      if (!delivery) {
        throw new NotFoundException('Delivery not found.');
      }
      if (
        delivery.status !== DeliveryStatus.OFFERED ||
        delivery.courierId !== null
      ) {
        throw new ConflictException(
          'This delivery offer has already been claimed.',
        );
      }

      const now = new Date();
      await transaction.delivery.update({
        where: { id: delivery.id },
        data: {
          courierId: user.id,
          status: DeliveryStatus.ACCEPTED,
          acceptedAt: now,
        },
      });
      await this.updateOrderForDeliveryStatus(
        transaction,
        delivery.orderId,
        user.id,
        DeliveryStatus.ACCEPTED,
        now,
      );
      await this.createDeliveryHistory(
        transaction,
        delivery.id,
        user.id,
        DeliveryStatus.OFFERED,
        DeliveryStatus.ACCEPTED,
      );

      return transaction.delivery.findUniqueOrThrow({
        where: { id: delivery.id },
        include: deliveryInclude,
      });
    });
  }

  private async advanceOwnedDelivery(
    user: AuthenticatedUser,
    deliveryId: string,
    requestedStatus: DeliveryStatus,
  ) {
    return this.inDispatchTransaction(async (transaction) => {
      const delivery = await transaction.delivery.findFirst({
        where: { id: deliveryId, courierId: user.id },
        select: { id: true, orderId: true, status: true },
      });
      if (!delivery) {
        throw new NotFoundException('Delivery not found.');
      }
      if (!isDeliveryTransitionAllowed(delivery.status, requestedStatus)) {
        const expected = expectedDeliveryStatus(delivery.status);
        const current = deliveryStatusForResponse(delivery.status);
        const next = expected ? deliveryStatusForResponse(expected) : 'none';
        throw new BadRequestException(
          `Cannot change a delivery from ${current} to ${deliveryStatusForResponse(requestedStatus)}. Expected ${next}.`,
        );
      }

      const now = new Date();
      await transaction.delivery.update({
        where: { id: delivery.id },
        data: this.deliveryStatusUpdate(requestedStatus, now),
      });
      await this.updateOrderForDeliveryStatus(
        transaction,
        delivery.orderId,
        user.id,
        requestedStatus,
        now,
      );
      await this.createDeliveryHistory(
        transaction,
        delivery.id,
        user.id,
        delivery.status,
        requestedStatus,
      );

      return transaction.delivery.findUniqueOrThrow({
        where: { id: delivery.id },
        include: deliveryInclude,
      });
    });
  }

  private deliveryStatusUpdate(status: DeliveryStatus, now: Date) {
    switch (status) {
      case DeliveryStatus.ARRIVED:
        return { status, arrivedAt: now };
      case DeliveryStatus.PICKED_UP:
        return { status, pickedUpAt: now };
      case DeliveryStatus.DELIVERED:
        return { status, deliveredAt: now };
      default:
        return { status };
    }
  }

  private async updateOrderForDeliveryStatus(
    transaction: Prisma.TransactionClient,
    orderId: string,
    courierId: string,
    deliveryStatus: DeliveryStatus,
    now: Date,
  ): Promise<void> {
    if (deliveryStatus === DeliveryStatus.PICKED_UP) {
      await transaction.order.update({
        where: { id: orderId },
        data: { courierId, status: OrderStatus.OUT_FOR_DELIVERY },
      });
      await this.createOrderStatusHistory(
        transaction,
        orderId,
        courierId,
        OrderStatus.OUT_FOR_DELIVERY,
        'Courier picked up the order.',
      );
      return;
    }

    if (deliveryStatus === DeliveryStatus.DELIVERED) {
      await transaction.order.update({
        where: { id: orderId },
        data: {
          courierId,
          status: OrderStatus.DELIVERED,
          deliveredAt: now,
        },
      });
      await this.createOrderStatusHistory(
        transaction,
        orderId,
        courierId,
        OrderStatus.DELIVERED,
        'Courier marked the delivery as completed.',
      );
      return;
    }

    await transaction.order.update({
      where: { id: orderId },
      data: { courierId },
    });
  }

  private async createDeliveryHistory(
    transaction: Prisma.TransactionClient,
    deliveryId: string,
    courierId: string,
    previousStatus: DeliveryStatus,
    status: DeliveryStatus,
  ): Promise<void> {
    const sequence =
      (await transaction.deliveryStatusHistory.count({
        where: { deliveryId },
      })) + 1;
    await transaction.deliveryStatusHistory.create({
      data: {
        deliveryId,
        changedById: courierId,
        sequence,
        previousStatus,
        status,
        note: `Courier updated delivery to ${deliveryStatusForResponse(status)}.`,
      },
    });
  }

  private async createOrderStatusHistory(
    transaction: Prisma.TransactionClient,
    orderId: string,
    courierId: string,
    status: OrderStatus,
    note: string,
  ): Promise<void> {
    const sequence =
      (await transaction.orderStatusHistory.count({ where: { orderId } })) + 1;
    await transaction.orderStatusHistory.create({
      data: {
        orderId,
        changedById: courierId,
        sequence,
        status,
        note,
      },
    });
  }

  private async inDispatchTransaction<T>(
    callback: (transaction: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    try {
      return await this.prisma.$transaction(callback, {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      });
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2034'
      ) {
        throw new ConflictException(
          'This delivery changed while it was being updated. Refresh and try again.',
        );
      }
      throw error;
    }
  }

  private serializeDelivery(delivery: DeliveryRecord) {
    const pickupAddress = this.formatMerchantAddress(delivery);
    const dropoff = this.deliveryAddress(delivery);
    const customerName = [
      delivery.order.customer.firstName,
      delivery.order.customer.lastName,
    ]
      .filter(Boolean)
      .join(' ');

    return {
      id: delivery.id,
      deliveryId: delivery.id,
      orderId: delivery.order.id,
      reference: delivery.order.orderNumber,
      orderNumber: delivery.order.orderNumber,
      status: deliveryStatusForResponse(delivery.status),
      merchantName: delivery.order.merchant.name,
      merchant: {
        id: delivery.order.merchant.id,
        name: delivery.order.merchant.name,
      },
      pickupAddress,
      pickup: {
        name: delivery.order.merchant.name,
        formattedAddress: pickupAddress,
        address: {
          line1: delivery.order.merchant.streetAddress,
          city: delivery.order.merchant.city,
          state: delivery.order.merchant.state,
          postalCode: delivery.order.merchant.postalCode,
          countryCode: delivery.order.merchant.countryCode,
        },
        latitude:
          delivery.order.merchant.latitude === null
            ? null
            : Number(delivery.order.merchant.latitude),
        longitude:
          delivery.order.merchant.longitude === null
            ? null
            : Number(delivery.order.merchant.longitude),
        note: delivery.pickupNote,
      },
      dropoffAddress: dropoff.formattedAddress,
      dropoff: {
        formattedAddress: dropoff.formattedAddress,
        address: dropoff.address,
        latitude: dropoff.latitude,
        longitude: dropoff.longitude,
        note: delivery.dropoffNote ?? dropoff.note,
      },
      customerName: customerName || 'Customer',
      customerPhone: delivery.order.customer.phone ?? '',
      customer: {
        name: customerName || 'Customer',
        phone: delivery.order.customer.phone ?? '',
      },
      earnings: Number(delivery.earnings),
      distanceKm: Number(delivery.distanceKm),
      etaMinutes: delivery.etaMinutes,
      route: {
        distanceKm: Number(delivery.distanceKm),
        etaMinutes: delivery.etaMinutes,
      },
      payout: {
        amount: Number(delivery.earnings),
        currency: delivery.order.currency,
      },
      pickupNote: delivery.pickupNote,
      dropoffNote: delivery.dropoffNote ?? dropoff.note,
      customerNotes: delivery.order.customerNotes,
      offeredAt: delivery.offeredAt,
      acceptedAt: delivery.acceptedAt,
      arrivedAt: delivery.arrivedAt,
      pickedUpAt: delivery.pickedUpAt,
      deliveredAt: delivery.deliveredAt,
      updatedAt: delivery.updatedAt,
    };
  }

  private formatMerchantAddress(delivery: DeliveryRecord): string {
    const merchant = delivery.order.merchant;
    return this.joinAddress([
      merchant.streetAddress,
      merchant.city,
      merchant.state,
      merchant.postalCode,
      merchant.countryCode,
    ]);
  }

  private deliveryAddress(delivery: DeliveryRecord) {
    const address = delivery.order.deliveryAddress;
    const snapshot = delivery.order.deliveryAddressSnapshot;
    const line1 = address?.line1 ?? this.snapshotValue(snapshot, 'line1');
    const line2 = address?.line2 ?? this.snapshotValue(snapshot, 'line2');
    const city = address?.city ?? this.snapshotValue(snapshot, 'city');
    const state = address?.state ?? this.snapshotValue(snapshot, 'state');
    const postalCode =
      address?.postalCode ?? this.snapshotValue(snapshot, 'postalCode');
    const countryCode =
      address?.countryCode ?? this.snapshotValue(snapshot, 'countryCode');

    return {
      formattedAddress: this.joinAddress([
        line1,
        line2,
        city,
        state,
        postalCode,
        countryCode,
      ]),
      address: {
        line1,
        line2,
        city,
        state,
        postalCode,
        countryCode,
      },
      latitude:
        address?.latitude === null || address?.latitude === undefined
          ? null
          : Number(address.latitude),
      longitude:
        address?.longitude === null || address?.longitude === undefined
          ? null
          : Number(address.longitude),
      note:
        address?.deliveryNotes ?? this.snapshotValue(snapshot, 'deliveryNotes'),
    };
  }

  private joinAddress(parts: Array<string | null | undefined>): string {
    return parts.filter((part): part is string => Boolean(part)).join(', ');
  }

  private snapshotValue(
    snapshot: Prisma.JsonValue,
    key: string,
  ): string | null {
    if (
      typeof snapshot !== 'object' ||
      snapshot === null ||
      Array.isArray(snapshot)
    ) {
      return null;
    }
    const value = snapshot[key];
    return typeof value === 'string' ? value : null;
  }
}
