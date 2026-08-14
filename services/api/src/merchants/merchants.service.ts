import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { toSlug } from '../common/utils/slug';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMerchantDto } from './dto/create-merchant.dto';
import { MerchantQueryDto } from './dto/merchant-query.dto';

const merchantSelect = {
  id: true,
  name: true,
  slug: true,
  type: true,
  description: true,
  contactEmail: true,
  phone: true,
  streetAddress: true,
  city: true,
  state: true,
  postalCode: true,
  countryCode: true,
  latitude: true,
  longitude: true,
  logoUrl: true,
  coverImageUrl: true,
  minimumOrderAmount: true,
  deliveryFee: true,
  estimatedDeliveryMinutes: true,
  isActive: true,
  isOpen: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.MerchantSelect;

type MerchantRecord = Prisma.MerchantGetPayload<{
  select: typeof merchantSelect;
}>;

@Injectable()
export class MerchantsService {
  constructor(private readonly prisma: PrismaService) {}

  async discover(dto: MerchantQueryDto) {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const where: Prisma.MerchantWhereInput = {
      isActive: true,
      ...(dto.type ? { type: dto.type } : {}),
      ...(dto.q
        ? {
            OR: [
              { name: { contains: dto.q, mode: 'insensitive' } },
              { description: { contains: dto.q, mode: 'insensitive' } },
              { city: { contains: dto.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [merchants, total] = await Promise.all([
      this.prisma.merchant.findMany({
        where,
        select: merchantSelect,
        orderBy: { name: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.merchant.count({ where }),
    ]);

    return this.paginated(merchants, page, limit, total);
  }

  async findPublicBySlug(slug: string) {
    const merchant = await this.prisma.merchant.findFirst({
      where: { slug, isActive: true },
      select: merchantSelect,
    });
    if (!merchant) {
      throw new NotFoundException('Merchant not found.');
    }

    const productCount = await this.prisma.catalogProduct.count({
      where: {
        merchantId: merchant.id,
        isPublished: true,
        isAvailable: true,
        deletedAt: null,
      },
    });

    return { ...this.serializeMerchant(merchant), productCount };
  }

  async findAllForAdmin(dto: MerchantQueryDto) {
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const where: Prisma.MerchantWhereInput = {
      ...(dto.type ? { type: dto.type } : {}),
      ...(dto.q
        ? {
            OR: [
              { name: { contains: dto.q, mode: 'insensitive' } },
              { slug: { contains: dto.q, mode: 'insensitive' } },
              { contactEmail: { contains: dto.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [merchants, total] = await Promise.all([
      this.prisma.merchant.findMany({
        where,
        select: merchantSelect,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.merchant.count({ where }),
    ]);

    return this.paginated(merchants, page, limit, total);
  }

  async create(dto: CreateMerchantDto) {
    if (dto.ownerUserId) {
      const owner = await this.prisma.user.findUnique({
        where: { id: dto.ownerUserId },
        select: { role: true },
      });
      if (!owner) {
        throw new NotFoundException('Merchant owner user not found.');
      }
      if (owner.role !== Role.MERCHANT && owner.role !== Role.ADMIN) {
        throw new BadRequestException(
          'The merchant owner must have the MERCHANT or ADMIN role.',
        );
      }
    }

    try {
      const merchant = await this.prisma.$transaction(async (transaction) => {
        const createdMerchant = await transaction.merchant.create({
          data: {
            name: dto.name,
            slug: toSlug(dto.slug ?? dto.name),
            type: dto.type,
            description: dto.description,
            contactEmail: dto.contactEmail,
            phone: dto.phone,
            streetAddress: dto.streetAddress,
            city: dto.city,
            state: dto.state,
            postalCode: dto.postalCode,
            countryCode: dto.countryCode ?? 'US',
            latitude: dto.latitude,
            longitude: dto.longitude,
            logoUrl: dto.logoUrl,
            coverImageUrl: dto.coverImageUrl,
            minimumOrderAmount: dto.minimumOrderAmount ?? 0,
            deliveryFee: dto.deliveryFee ?? 0,
            estimatedDeliveryMinutes: dto.estimatedDeliveryMinutes ?? 30,
            isActive: dto.isActive ?? true,
            isOpen: dto.isOpen ?? true,
          },
          select: merchantSelect,
        });

        if (dto.ownerUserId) {
          await transaction.merchantMembership.create({
            data: {
              merchantId: createdMerchant.id,
              userId: dto.ownerUserId,
              role: 'OWNER',
            },
          });
        }

        return createdMerchant;
      });

      return this.serializeMerchant(merchant);
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'A merchant with this slug already exists.',
        );
      }
      throw error;
    }
  }

  async remove(merchantId: string) {
    const existingMerchant = await this.prisma.merchant.findUnique({
      where: { id: merchantId },
      select: { id: true },
    });
    if (!existingMerchant) {
      throw new NotFoundException('Merchant not found.');
    }

    const merchant = await this.prisma.merchant.update({
      where: { id: merchantId },
      data: { isActive: false, isOpen: false },
      select: merchantSelect,
    });
    return this.serializeMerchant(merchant);
  }

  private paginated(
    items: MerchantRecord[],
    page: number,
    limit: number,
    total: number,
  ) {
    return {
      data: items.map((merchant) => this.serializeMerchant(merchant)),
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  private serializeMerchant(merchant: MerchantRecord) {
    return {
      ...merchant,
      latitude: merchant.latitude === null ? null : Number(merchant.latitude),
      longitude:
        merchant.longitude === null ? null : Number(merchant.longitude),
      minimumOrderAmount: Number(merchant.minimumOrderAmount),
      deliveryFee: Number(merchant.deliveryFee),
    };
  }
}
