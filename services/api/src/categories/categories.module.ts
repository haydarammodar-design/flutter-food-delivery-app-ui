import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import {
  AdminCategoriesController,
  PublicCategoriesController,
} from './categories.controller';
import { CategoriesService } from './categories.service';

@Module({
  imports: [AuthModule],
  controllers: [PublicCategoriesController, AdminCategoriesController],
  providers: [CategoriesService],
})
export class CategoriesModule {}
