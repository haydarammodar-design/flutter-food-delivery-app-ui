import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { JobsModule } from '../jobs/jobs.module';
import { MerchantsModule } from '../merchants/merchants.module';
import {
  MerchantCatalogController,
  PublicCatalogController,
} from './catalog.controller';
import { CatalogService } from './catalog.service';

@Module({
  imports: [AuthModule, JobsModule, MerchantsModule],
  controllers: [PublicCatalogController, MerchantCatalogController],
  providers: [CatalogService],
})
export class CatalogModule {}
