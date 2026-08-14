import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { CategoriesModule } from './categories/categories.module';
import { CatalogModule } from './catalog/catalog.module';
import { CouriersModule } from './couriers/couriers.module';
import { DeliveriesModule } from './deliveries/deliveries.module';
import { HealthModule } from './health/health.module';
import { JobsModule } from './jobs/jobs.module';
import { MediaModule } from './media/media.module';
import { MerchantsModule } from './merchants/merchants.module';
import { PaymentsModule } from './payments/payments.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    PrismaModule,
    JobsModule,
    AuthModule,
    HealthModule,
    CategoriesModule,
    MerchantsModule,
    CatalogModule,
    CouriersModule,
    DeliveriesModule,
    MediaModule,
    PaymentsModule,
  ],
})
export class AppModule {}
