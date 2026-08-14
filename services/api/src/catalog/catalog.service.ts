import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { JobsService } from '../jobs/jobs.service';
import { MerchantAccessService } from '../merchants/merchant-access.service';
import { PrismaService } from '../prisma/prisma.service';
import { CatalogQueryDto } from './dto/catalog-query.dto';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { UpdatePublicationDto } from './dto/update-publication.dto';

const categorySummarySelect = {
  id: true,
  name: true,
  slug: true,
} satisfies Prisma.CategorySelect;

const managedMerchantSelect = {
  id: true,
  name: true,
  type: true,
  isActive: true,
  isOpen: true,
} satisfies Prisma.MerchantSelect;

const productSelect = {
  id: true,
  merchantId: true,
  categoryId: true,
  sku: true,
  name: true,
  description: true,
  imageUrl: true,
  price: true,
  compareAtPrice: true,
  currency: true,
  tags: true,
  isPublished: true,
  isAvailable: true,
  trackInventory: true,
  inventoryQuantity: true,
  lowStockThreshold: true,
  allowSubstitutions: true,
  substitutionNote: true,
  sortOrder: true,
  createdAt: true,
  updatedAt: true,
  category: { select: categorySummarySelect },
} satisfies Prisma.CatalogProductSelect;

type CatalogProduct = Prisma.CatalogProductGetPayload<{
  select: typeof productSelect;
}>;

@Injectable()
export class CatalogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly merchantAccess: MerchantAccessService,
    private readonly jobs: JobsService,
  ) {}

  async findPublicByMerchantSlug(slug: string, dto: CatalogQueryDto) {
    const merchant = await this.prisma.merchant.findFirst({
      where: { slug, isActive: true },
      select: { id: true, slug: true, name: true, isOpen: true },
    });
    if (!merchant) {
      throw new NotFoundException('Merchant not found.');
    }

    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const where = this.productWhere(merchant.id, dto, true);
    const [products, total] = await Promise.all([
      this.prisma.catalogProduct.findMany({
        where,
        select: productSelect,
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.catalogProduct.count({ where }),
    ]);

    return {
      merchant,
      data: products.map((product) => this.serializeProduct(product)),
      meta: this.pagination(page, limit, total),
    };
  }

  async findManaged(
    user: AuthenticatedUser,
    merchantId: string,
    dto: CatalogQueryDto,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    const page = dto.page ?? 1;
    const limit = dto.limit ?? 20;
    const where = this.productWhere(merchantId, dto, false);
    const [products, total] = await Promise.all([
      this.prisma.catalogProduct.findMany({
        where,
        select: productSelect,
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.catalogProduct.count({ where }),
    ]);

    return {
      data: products.map((product) => this.serializeProduct(product)),
      meta: this.pagination(page, limit, total),
    };
  }

  async findManageableMerchants(user: AuthenticatedUser) {
    const merchants = await this.prisma.merchant.findMany({
      where:
        user.role === Role.ADMIN
          ? {}
          : {
              memberships: {
                some: { userId: user.id, isActive: true },
              },
            },
      select: managedMerchantSelect,
      orderBy: { name: 'asc' },
    });

    return { data: merchants };
  }

  async create(
    user: AuthenticatedUser,
    merchantId: string,
    dto: CreateProductDto,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.assertCategoryExists(dto.categoryId);

    try {
      const product = await this.prisma.catalogProduct.create({
        data: {
          merchantId,
          categoryId: dto.categoryId,
          sku: dto.sku,
          name: dto.name,
          description: dto.description,
          imageUrl: dto.imageUrl,
          price: dto.price,
          compareAtPrice: dto.compareAtPrice,
          currency: dto.currency ?? 'USD',
          tags: dto.tags ?? [],
          isPublished: dto.isPublished ?? false,
          isAvailable: dto.isAvailable ?? true,
          trackInventory: dto.trackInventory ?? true,
          inventoryQuantity: dto.inventoryQuantity ?? 0,
          lowStockThreshold: dto.lowStockThreshold ?? 0,
          allowSubstitutions: dto.allowSubstitutions ?? false,
          substitutionNote: dto.substitutionNote,
          sortOrder: dto.sortOrder ?? 0,
        },
        select: productSelect,
      });
      await this.publishChange('created', product);
      return this.serializeProduct(product);
    } catch (error: unknown) {
      this.rethrowKnownWriteError(error);
    }
  }

  async update(
    user: AuthenticatedUser,
    merchantId: string,
    productId: string,
    dto: UpdateProductDto,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.findActiveProduct(merchantId, productId);
    await this.assertCategoryExists(dto.categoryId);

    try {
      const product = await this.prisma.catalogProduct.update({
        where: { id: productId },
        data: {
          ...(dto.sku !== undefined ? { sku: dto.sku } : {}),
          ...(dto.name !== undefined ? { name: dto.name } : {}),
          ...(dto.categoryId !== undefined
            ? { categoryId: dto.categoryId }
            : {}),
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
          ...(dto.imageUrl !== undefined ? { imageUrl: dto.imageUrl } : {}),
          ...(dto.price !== undefined ? { price: dto.price } : {}),
          ...(dto.compareAtPrice !== undefined
            ? { compareAtPrice: dto.compareAtPrice }
            : {}),
          ...(dto.currency !== undefined ? { currency: dto.currency } : {}),
          ...(dto.tags !== undefined ? { tags: dto.tags } : {}),
          ...(dto.isAvailable !== undefined
            ? { isAvailable: dto.isAvailable }
            : {}),
          ...(dto.trackInventory !== undefined
            ? { trackInventory: dto.trackInventory }
            : {}),
          ...(dto.inventoryQuantity !== undefined
            ? { inventoryQuantity: dto.inventoryQuantity }
            : {}),
          ...(dto.lowStockThreshold !== undefined
            ? { lowStockThreshold: dto.lowStockThreshold }
            : {}),
          ...(dto.allowSubstitutions !== undefined
            ? { allowSubstitutions: dto.allowSubstitutions }
            : {}),
          ...(dto.substitutionNote !== undefined
            ? { substitutionNote: dto.substitutionNote }
            : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
        },
        select: productSelect,
      });
      await this.publishChange('updated', product);
      return this.serializeProduct(product);
    } catch (error: unknown) {
      this.rethrowKnownWriteError(error);
    }
  }

  async updatePublication(
    user: AuthenticatedUser,
    merchantId: string,
    productId: string,
    dto: UpdatePublicationDto,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.findActiveProduct(merchantId, productId);

    const product = await this.prisma.catalogProduct.update({
      where: { id: productId },
      data: { isPublished: dto.published },
      select: productSelect,
    });
    await this.publishChange(
      dto.published ? 'published' : 'unpublished',
      product,
    );
    return this.serializeProduct(product);
  }

  async clearImage(
    user: AuthenticatedUser,
    merchantId: string,
    productId: string,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.findActiveProduct(merchantId, productId);

    const product = await this.prisma.catalogProduct.update({
      where: { id: productId },
      data: { imageUrl: null },
      select: productSelect,
    });
    await this.publishChange('updated', product);
    return this.serializeProduct(product);
  }

  async updateInventory(
    user: AuthenticatedUser,
    merchantId: string,
    productId: string,
    dto: UpdateInventoryDto,
  ) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.findActiveProduct(merchantId, productId);

    const product = await this.prisma.catalogProduct.update({
      where: { id: productId },
      data: {
        inventoryQuantity: dto.quantity,
        ...(dto.isAvailable !== undefined
          ? { isAvailable: dto.isAvailable }
          : {}),
        ...(dto.trackInventory !== undefined
          ? { trackInventory: dto.trackInventory }
          : {}),
        ...(dto.lowStockThreshold !== undefined
          ? { lowStockThreshold: dto.lowStockThreshold }
          : {}),
        ...(dto.allowSubstitutions !== undefined
          ? { allowSubstitutions: dto.allowSubstitutions }
          : {}),
        ...(dto.substitutionNote !== undefined
          ? { substitutionNote: dto.substitutionNote }
          : {}),
      },
      select: productSelect,
    });
    await this.publishChange('inventory_updated', product);
    return this.serializeProduct(product);
  }

  async remove(user: AuthenticatedUser, merchantId: string, productId: string) {
    await this.merchantAccess.assertCanManageMerchant(user, merchantId);
    await this.findActiveProduct(merchantId, productId);

    const product = await this.prisma.catalogProduct.update({
      where: { id: productId },
      data: { deletedAt: new Date(), isPublished: false },
      select: productSelect,
    });
    await this.publishChange('deleted', product);
    return { id: product.id, deleted: true };
  }

  private productWhere(
    merchantId: string,
    dto: CatalogQueryDto,
    publicOnly: boolean,
  ): Prisma.CatalogProductWhereInput {
    const filters: Prisma.CatalogProductWhereInput[] = [
      {
        merchantId,
        deletedAt: null,
        ...(publicOnly ? { isPublished: true, isAvailable: true } : {}),
      },
    ];
    if (publicOnly) {
      filters.push({
        OR: [{ categoryId: null }, { category: { is: { isActive: true } } }],
      });
    }
    if (dto.categoryId) {
      filters.push({ categoryId: dto.categoryId });
    }
    if (dto.q) {
      filters.push({
        OR: [
          { name: { contains: dto.q, mode: 'insensitive' } },
          { description: { contains: dto.q, mode: 'insensitive' } },
          { tags: { has: dto.q.toLowerCase() } },
        ],
      });
    }

    return { AND: filters };
  }

  private async assertCategoryExists(categoryId?: string): Promise<void> {
    if (!categoryId) {
      return;
    }
    const category = await this.prisma.category.findUnique({
      where: { id: categoryId },
      select: { id: true },
    });
    if (!category) {
      throw new NotFoundException('Category not found.');
    }
  }

  private async findActiveProduct(merchantId: string, productId: string) {
    const product = await this.prisma.catalogProduct.findFirst({
      where: { id: productId, merchantId, deletedAt: null },
      select: { id: true },
    });
    if (!product) {
      throw new NotFoundException('Catalog product not found.');
    }
    return product;
  }

  private async publishChange(
    action:
      | 'created'
      | 'updated'
      | 'published'
      | 'unpublished'
      | 'inventory_updated'
      | 'deleted',
    product: CatalogProduct,
  ): Promise<void> {
    await this.jobs.publishCatalogChanged({
      action,
      merchantId: product.merchantId,
      productId: product.id,
    });
  }

  private serializeProduct(product: CatalogProduct) {
    const inStock =
      product.isAvailable &&
      (!product.trackInventory || product.inventoryQuantity > 0);

    return {
      id: product.id,
      merchantId: product.merchantId,
      category: product.category,
      sku: product.sku,
      name: product.name,
      description: product.description,
      imageUrl: product.imageUrl,
      price: Number(product.price),
      compareAtPrice:
        product.compareAtPrice === null ? null : Number(product.compareAtPrice),
      currency: product.currency,
      tags: product.tags,
      isPublished: product.isPublished,
      inventory: {
        quantity: product.inventoryQuantity,
        trackInventory: product.trackInventory,
        lowStockThreshold: product.lowStockThreshold,
        isAvailable: product.isAvailable,
        inStock,
        allowSubstitutions: product.allowSubstitutions,
        substitutionNote: product.substitutionNote,
      },
      sortOrder: product.sortOrder,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    };
  }

  private pagination(page: number, limit: number, total: number) {
    return {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    };
  }

  private rethrowKnownWriteError(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException(
        'A product with this SKU already exists for this merchant.',
      );
    }
    throw error;
  }
}
