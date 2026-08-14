import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CreateMerchantDto } from './dto/create-merchant.dto';
import { MerchantQueryDto } from './dto/merchant-query.dto';
import { MerchantsService } from './merchants.service';

@ApiTags('merchants')
@Controller({ path: 'merchants', version: '1' })
export class PublicMerchantsController {
  constructor(private readonly merchantsService: MerchantsService) {}

  @Get()
  discover(@Query() query: MerchantQueryDto) {
    return this.merchantsService.discover(query);
  }

  @Get(':slug')
  findOne(@Param('slug') slug: string) {
    return this.merchantsService.findPublicBySlug(slug);
  }
}

@ApiTags('admin merchants')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
@Controller({ path: 'admin/merchants', version: '1' })
export class AdminMerchantsController {
  constructor(private readonly merchantsService: MerchantsService) {}

  @Get()
  findAll(@Query() query: MerchantQueryDto) {
    return this.merchantsService.findAllForAdmin(query);
  }

  @Post()
  create(@Body() dto: CreateMerchantDto) {
    return this.merchantsService.create(dto);
  }

  @Delete(':merchantId')
  remove(@Param('merchantId', ParseUUIDPipe) merchantId: string) {
    return this.merchantsService.remove(merchantId);
  }
}
