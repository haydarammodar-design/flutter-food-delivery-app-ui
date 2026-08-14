import { Transform } from 'class-transformer';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { trimString } from '../../common/utils/string-transformers';

export class UpdateCourierProfileDto {
  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(80)
  vehicleType?: string;

  @IsOptional()
  @Transform(trimString)
  @IsString()
  @MaxLength(40)
  vehiclePlate?: string;
}
