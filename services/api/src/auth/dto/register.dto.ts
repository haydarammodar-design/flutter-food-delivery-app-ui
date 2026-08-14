import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import {
  trimLowercaseString,
  trimString,
} from '../../common/utils/string-transformers';

export class RegisterDto {
  @Transform(trimLowercaseString)
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(80)
  firstName?: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(80)
  lastName?: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(32)
  phone?: string;
}
