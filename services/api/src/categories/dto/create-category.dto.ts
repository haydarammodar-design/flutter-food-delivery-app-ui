import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  Min,
} from 'class-validator';
import {
  trimLowercaseString,
  trimString,
} from '../../common/utils/string-transformers';

export class CreateCategoryDto {
  @Transform(trimString)
  @IsString()
  @MaxLength(100)
  name!: string;

  @IsOptional()
  @Transform(trimLowercaseString)
  @IsString()
  @MaxLength(120)
  slug?: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  imageUrl?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  sortOrder?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
