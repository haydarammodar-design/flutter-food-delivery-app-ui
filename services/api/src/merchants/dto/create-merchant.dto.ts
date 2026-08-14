import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Length,
  MaxLength,
  Min,
} from 'class-validator';
import { MerchantType } from '@prisma/client';
import {
  trimLowercaseString,
  trimString,
  trimUppercaseString,
} from '../../common/utils/string-transformers';

export class CreateMerchantDto {
  @Transform(trimString)
  @IsString()
  @MaxLength(140)
  name!: string;

  @IsOptional()
  @Transform(trimLowercaseString)
  @IsString()
  @MaxLength(160)
  slug?: string;

  @IsEnum(MerchantType)
  type!: MerchantType;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(2000)
  description?: string;

  @Transform(trimLowercaseString)
  @IsEmail()
  @MaxLength(320)
  contactEmail!: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(32)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  streetAddress?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  state?: string;

  @IsOptional()
  @IsString()
  @MaxLength(24)
  postalCode?: string;

  @IsOptional()
  @Transform(trimUppercaseString)
  @IsString()
  @Length(2, 2)
  countryCode?: string;

  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  longitude?: number;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  logoUrl?: string;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2048)
  coverImageUrl?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  minimumOrderAmount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  deliveryFee?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  estimatedDeliveryMinutes?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsBoolean()
  isOpen?: boolean;

  @IsOptional()
  @IsUUID()
  ownerUserId?: string;
}
