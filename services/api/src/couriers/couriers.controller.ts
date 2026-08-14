import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { UpdateCourierAvailabilityDto } from './dto/update-courier-availability.dto';
import { UpdateCourierProfileDto } from './dto/update-courier-profile.dto';
import { CouriersService } from './couriers.service';

@ApiTags('courier profile')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.COURIER)
@Controller({ path: 'couriers', version: '1' })
export class CouriersController {
  constructor(private readonly couriersService: CouriersService) {}

  @Get('me')
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.couriersService.getProfile(user);
  }

  @Patch('me')
  updateProfile(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCourierProfileDto,
  ) {
    return this.couriersService.updateProfile(user, dto);
  }

  @Patch('me/availability')
  updateAvailability(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateCourierAvailabilityDto,
  ) {
    return this.couriersService.updateAvailability(user, dto);
  }
}
