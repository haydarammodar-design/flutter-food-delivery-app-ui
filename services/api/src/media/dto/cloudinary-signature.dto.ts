import { IsOptional, IsUUID } from 'class-validator';

export class CloudinarySignatureDto {
  @IsOptional()
  @IsUUID()
  merchantId?: string;
}
