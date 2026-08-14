import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MerchantsModule } from '../merchants/merchants.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';

@Module({
  imports: [AuthModule, MerchantsModule],
  controllers: [MediaController],
  providers: [MediaService],
})
export class MediaModule {}
