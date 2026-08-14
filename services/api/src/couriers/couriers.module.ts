import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CouriersController } from './couriers.controller';
import { CouriersService } from './couriers.service';

@Module({
  imports: [AuthModule],
  controllers: [CouriersController],
  providers: [CouriersService],
  exports: [CouriersService],
})
export class CouriersModule {}
