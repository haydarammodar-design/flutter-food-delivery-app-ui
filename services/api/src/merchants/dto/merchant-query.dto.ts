import { Transform, Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { MerchantType } from '@prisma/client';
import { trimString } from '../../common/utils/string-transformers';

export class MerchantQueryDto {
  @IsOptional()
  @IsEnum(MerchantType)
  type?: MerchantType;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(100)
  q?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
