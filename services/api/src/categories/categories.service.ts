import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { toSlug } from '../common/utils/slug';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

const categorySelect = {
  id: true,
  name: true,
  slug: true,
  description: true,
  imageUrl: true,
  sortOrder: true,
  isActive: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.CategorySelect;

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async findPublic() {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      select: categorySelect,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });

    return { data: categories };
  }

  async findAll() {
    const categories = await this.prisma.category.findMany({
      select: categorySelect,
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });

    return { data: categories };
  }

  async create(dto: CreateCategoryDto) {
    try {
      const category = await this.prisma.category.create({
        data: {
          name: dto.name,
          slug: toSlug(dto.slug ?? dto.name),
          description: dto.description,
          imageUrl: dto.imageUrl,
          sortOrder: dto.sortOrder ?? 0,
          isActive: dto.isActive ?? true,
        },
        select: categorySelect,
      });
      return category;
    } catch (error: unknown) {
      this.rethrowKnownWriteError(error);
    }
  }

  async update(id: string, dto: UpdateCategoryDto) {
    await this.ensureExists(id);

    try {
      return await this.prisma.category.update({
        where: { id },
        data: {
          ...(dto.name !== undefined ? { name: dto.name } : {}),
          ...(dto.slug !== undefined ? { slug: toSlug(dto.slug) } : {}),
          ...(dto.description !== undefined
            ? { description: dto.description }
            : {}),
          ...(dto.imageUrl !== undefined ? { imageUrl: dto.imageUrl } : {}),
          ...(dto.sortOrder !== undefined ? { sortOrder: dto.sortOrder } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
        },
        select: categorySelect,
      });
    } catch (error: unknown) {
      this.rethrowKnownWriteError(error);
    }
  }

  async remove(id: string) {
    await this.ensureExists(id);
    const productCount = await this.prisma.catalogProduct.count({
      where: { categoryId: id },
    });
    if (productCount > 0) {
      throw new BadRequestException(
        'A category with catalog products cannot be deleted. Deactivate it instead.',
      );
    }

    await this.prisma.category.delete({ where: { id } });
    return { id, deleted: true };
  }

  private async ensureExists(id: string): Promise<void> {
    const category = await this.prisma.category.findUnique({
      where: { id },
      select: { id: true },
    });
    if (!category) {
      throw new NotFoundException('Category not found.');
    }
  }

  private rethrowKnownWriteError(error: unknown): never {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new ConflictException('A category with this slug already exists.');
    }
    throw error;
  }
}
