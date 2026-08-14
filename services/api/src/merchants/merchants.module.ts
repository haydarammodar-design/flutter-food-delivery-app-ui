import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MerchantAccessService } from './merchant-access.service';
import {
  AdminMerchantsController,
  PublicMerchantsController,
} from './merchants.controller';
import { MerchantsService } from './merchants.service';

@Module({
  imports: [AuthModule],
  controllers: [PublicMerchantsController, AdminMerchantsController],
  providers: [MerchantsService, MerchantAccessService],
  exports: [MerchantAccessService],
})
export class MerchantsModule {}
