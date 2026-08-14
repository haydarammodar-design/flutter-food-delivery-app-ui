import { IsUUID } from 'class-validator';

export class LocalImageUploadDto {
  @IsUUID()
  merchantId!: string;
}
