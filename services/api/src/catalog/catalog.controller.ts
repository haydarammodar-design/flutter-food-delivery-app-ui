import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CatalogService } from './catalog.service';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { UpdatePublicationDto } from './dto/update-publication.dto';

@ApiTags('catalog')
@Controller({ path: 'merchants', version: '1' })
export class PublicCatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get(':merchantSlug/products')
  findPublic(
    @Param('merchantSlug') merchantSlug: string,
    @Query() query: CatalogQueryDto,
  ) {
    return this.catalogService.findPublicByMerchantSlug(merchantSlug, query);
  }
}

@ApiTags('merchant catalog')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.MERCHANT)
@Controller({ path: 'merchant-catalog', version: '1' })
export class MerchantCatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('merchants')
  findManageableMerchants(@CurrentUser() user: AuthenticatedUser) {
    return this.catalogService.findManageableMerchants(user);
  }

  @Get(':merchantId/products')
  findManaged(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Query() query: CatalogQueryDto,
  ) {
    return this.catalogService.findManaged(user, merchantId, query);
  }

  @Post(':merchantId/products')
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Body() dto: CreateProductDto,
  ) {
    return this.catalogService.create(user, merchantId, dto);
  }

  @Patch(':merchantId/products/:productId')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.catalogService.update(user, merchantId, productId, dto);
  }

  @Patch(':merchantId/products/:productId/publish')
  updatePublication(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() dto: UpdatePublicationDto,
  ) {
    return this.catalogService.updatePublication(
      user,
      merchantId,
      productId,
      dto,
    );
  }

  @Patch(':merchantId/products/:productId/inventory')
  updateInventory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() dto: UpdateInventoryDto,
  ) {
    return this.catalogService.updateInventory(
      user,
      merchantId,
      productId,
      dto,
    );
  }

  @Delete(':merchantId/products/:productId/image')
  clearImage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Param('productId', ParseUUIDPipe) productId: string,
  ) {
    return this.catalogService.clearImage(user, merchantId, productId);
  }

  @Delete(':merchantId/products/:productId')
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('merchantId', ParseUUIDPipe) merchantId: string,
    @Param('productId', ParseUUIDPipe) productId: string,
  ) {
    return this.catalogService.remove(user, merchantId, productId);
  }
}
