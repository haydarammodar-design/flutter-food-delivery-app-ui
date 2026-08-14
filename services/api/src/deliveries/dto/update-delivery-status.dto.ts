import { Transform } from 'class-transformer';
import { IsEnum } from 'class-validator';
import { trimLowercaseString } from '../../common/utils/string-transformers';
import { DeliveryStatusRequest } from '../delivery-state';

export class UpdateDeliveryStatusDto {
  @Transform(trimLowercaseString)
  @IsEnum(DeliveryStatusRequest)
  status!: DeliveryStatusRequest;
}
