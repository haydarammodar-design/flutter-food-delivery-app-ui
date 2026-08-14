import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MerchantAccessService {
  constructor(private readonly prisma: PrismaService) {}

  async assertCanManageMerchant(user: AuthenticatedUser, merchantId: string) {
    const merchant = await this.prisma.merchant.findUnique({
      where: { id: merchantId },
      select: { id: true, isActive: true },
    });
    if (!merchant) {
      throw new NotFoundException('Merchant not found.');
    }
    if (user.role === Role.ADMIN) {
      return merchant;
    }
    if (user.role !== Role.MERCHANT) {
      throw new ForbiddenException(
        'Only merchant members can manage this catalog.',
      );
    }

    const membership = await this.prisma.merchantMembership.findFirst({
      where: {
        merchantId,
        userId: user.id,
        isActive: true,
      },
      select: { id: true },
    });
    if (!membership) {
      throw new ForbiddenException(
        'You are not an active member of this merchant.',
      );
    }

    return merchant;
  }
}
