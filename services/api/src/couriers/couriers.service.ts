import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateCourierAvailabilityDto } from './dto/update-courier-availability.dto';
import { UpdateCourierProfileDto } from './dto/update-courier-profile.dto';

const courierProfileSelect = {
  id: true,
  userId: true,
  vehicleType: true,
  vehiclePlate: true,
  isAvailable: true,
  currentLatitude: true,
  currentLongitude: true,
  createdAt: true,
  updatedAt: true,
  user: {
    select: {
      email: true,
      firstName: true,
      lastName: true,
      phone: true,
    },
  },
} satisfies Prisma.CourierProfileSelect;

type CourierProfileRecord = Prisma.CourierProfileGetPayload<{
  select: typeof courierProfileSelect;
}>;

@Injectable()
export class CouriersService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(user: AuthenticatedUser) {
    const profile = await this.prisma.courierProfile.upsert({
      where: { userId: user.id },
      update: {},
      create: { userId: user.id },
      select: courierProfileSelect,
    });
    return this.serializeProfile(profile);
  }

  async updateProfile(user: AuthenticatedUser, dto: UpdateCourierProfileDto) {
    const profile = await this.prisma.courierProfile.upsert({
      where: { userId: user.id },
      update: {
        ...(dto.vehicleType !== undefined
          ? { vehicleType: dto.vehicleType }
          : {}),
        ...(dto.vehiclePlate !== undefined
          ? { vehiclePlate: dto.vehiclePlate }
          : {}),
      },
      create: {
        userId: user.id,
        vehicleType: dto.vehicleType,
        vehiclePlate: dto.vehiclePlate,
      },
      select: courierProfileSelect,
    });
    return this.serializeProfile(profile);
  }

  async updateAvailability(
    user: AuthenticatedUser,
    dto: UpdateCourierAvailabilityDto,
  ) {
    const profile = await this.prisma.courierProfile.upsert({
      where: { userId: user.id },
      update: {
        isAvailable: dto.isAvailable,
        ...(dto.latitude !== undefined
          ? { currentLatitude: dto.latitude }
          : {}),
        ...(dto.longitude !== undefined
          ? { currentLongitude: dto.longitude }
          : {}),
      },
      create: {
        userId: user.id,
        isAvailable: dto.isAvailable,
        currentLatitude: dto.latitude,
        currentLongitude: dto.longitude,
      },
      select: courierProfileSelect,
    });
    return this.serializeProfile(profile);
  }

  private serializeProfile(profile: CourierProfileRecord) {
    return {
      id: profile.id,
      userId: profile.userId,
      email: profile.user.email,
      name: [profile.user.firstName, profile.user.lastName]
        .filter(Boolean)
        .join(' '),
      phone: profile.user.phone,
      vehicleType: profile.vehicleType,
      vehiclePlate: profile.vehiclePlate,
      isAvailable: profile.isAvailable,
      location: {
        latitude:
          profile.currentLatitude === null
            ? null
            : Number(profile.currentLatitude),
        longitude:
          profile.currentLongitude === null
            ? null
            : Number(profile.currentLongitude),
      },
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    };
  }
}
