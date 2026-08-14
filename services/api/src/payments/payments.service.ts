import {
  BadGatewayException,
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OrderStatus, PaymentProvider, PaymentStatus } from '@prisma/client';
import Stripe from 'stripe';
import { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async createPaymentIntent(
    user: AuthenticatedUser,
    dto: CreatePaymentIntentDto,
  ) {
    const secretKey = this.config.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey || secretKey.startsWith('replace-with-')) {
      throw new ServiceUnavailableException(
        'Stripe payments are unavailable because STRIPE_SECRET_KEY is not configured.',
      );
    }

    const order = await this.prisma.order.findFirst({
      where: { id: dto.orderId, customerId: user.id },
      select: {
        id: true,
        status: true,
        currency: true,
        totalAmount: true,
      },
    });
    if (!order) {
      throw new NotFoundException('Order not found.');
    }
    if (order.status !== OrderStatus.PENDING_PAYMENT) {
      throw new BadRequestException(
        'A payment intent can only be created for an order awaiting payment.',
      );
    }

    const amount = Math.round(Number(order.totalAmount) * 100);
    if (!Number.isSafeInteger(amount) || amount < 1) {
      throw new BadRequestException('Order total must be greater than zero.');
    }

    let paymentIntent: Stripe.PaymentIntent;
    try {
      const stripe = new Stripe(secretKey);
      paymentIntent = await stripe.paymentIntents.create(
        {
          amount,
          currency: order.currency.toLowerCase(),
          metadata: {
            orderId: order.id,
            customerId: user.id,
          },
        },
        { idempotencyKey: `order-payment-intent-${order.id}` },
      );
    } catch {
      throw new BadGatewayException(
        'Unable to create a Stripe payment intent.',
      );
    }

    const payment = await this.prisma.payment.upsert({
      where: { externalId: paymentIntent.id },
      create: {
        orderId: order.id,
        provider: PaymentProvider.STRIPE,
        externalId: paymentIntent.id,
        status: this.toPaymentStatus(paymentIntent.status),
        amount: order.totalAmount,
        currency: order.currency,
        providerResponse: {
          id: paymentIntent.id,
          status: paymentIntent.status,
        },
      },
      update: {
        status: this.toPaymentStatus(paymentIntent.status),
        providerResponse: {
          id: paymentIntent.id,
          status: paymentIntent.status,
        },
      },
      select: { id: true },
    });

    return {
      paymentId: payment.id,
      paymentIntentId: paymentIntent.id,
      clientSecret: paymentIntent.client_secret,
      status: paymentIntent.status,
      amount,
      currency: order.currency,
    };
  }

  private toPaymentStatus(status: Stripe.PaymentIntent.Status): PaymentStatus {
    switch (status) {
      case 'succeeded':
        return PaymentStatus.SUCCEEDED;
      case 'canceled':
        return PaymentStatus.CANCELLED;
      case 'requires_action':
        return PaymentStatus.REQUIRES_ACTION;
      default:
        return PaymentStatus.PENDING;
    }
  }
}
