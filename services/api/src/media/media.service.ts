import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { Role } from '@prisma/client';
import { rename, unlink } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { MerchantAccessService } from '../merchants/merchant-access.service';
import { CloudinarySignatureDto } from './dto/cloudinary-signature.dto';
import { LocalImageUploadDto } from './dto/local-image-upload.dto';

const imageExtensions = new Map<string, string>([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
  ['image/gif', '.gif'],
]);

type UploadedImage = {
  mimetype: string;
  path: string;
};

@Injectable()
export class MediaService {
  constructor(
    private readonly config: ConfigService,
    private readonly merchantAccess: MerchantAccessService,
  ) {}

  async createCloudinaryUploadSignature(
    user: AuthenticatedUser,
    dto: CloudinarySignatureDto,
  ) {
    const credentials = this.getCloudinaryCredentials();
    let folder = 'food-delivery/admin';

    if (dto.merchantId) {
      await this.merchantAccess.assertCanManageMerchant(user, dto.merchantId);
      folder = `food-delivery/merchants/${dto.merchantId}`;
    } else if (user.role === Role.MERCHANT) {
      throw new BadRequestException(
        'merchantId is required for merchant media uploads.',
      );
    }

    const timestamp = Math.floor(Date.now() / 1000);
    const signature = cloudinary.utils.api_sign_request(
      { folder, timestamp },
      credentials.apiSecret,
    );

    return {
      provider: 'cloudinary',
      uploadUrl: `https://api.cloudinary.com/v1_1/${credentials.cloudName}/auto/upload`,
      fields: {
        api_key: credentials.apiKey,
        timestamp,
        folder,
        signature,
      },
    };
  }

  async storeLocalImage(
    user: AuthenticatedUser,
    dto: LocalImageUploadDto,
    file: UploadedImage | undefined,
  ) {
    if (!file) {
      throw new BadRequestException(
        'Upload a JPEG, PNG, WebP, or GIF image no larger than 5 MB.',
      );
    }

    const extension = imageExtensions.get(file.mimetype);
    if (!extension) {
      await this.removeTemporaryFile(file.path);
      throw new BadRequestException(
        'Upload a JPEG, PNG, WebP, or GIF image no larger than 5 MB.',
      );
    }

    try {
      await this.merchantAccess.assertCanManageMerchant(user, dto.merchantId);
      const filename = `${randomUUID()}${extension}`;
      await rename(file.path, join(dirname(file.path), filename));

      return { url: `${this.publicApiUrl()}/uploads/${filename}` };
    } catch (error: unknown) {
      await this.removeTemporaryFile(file.path);
      throw error;
    }
  }

  private getCloudinaryCredentials() {
    const provider = this.config
      .get<string>('MEDIA_PROVIDER')
      ?.trim()
      .toLowerCase();
    if (provider !== 'cloudinary') {
      throw new ServiceUnavailableException(
        'Media uploads are unavailable. Set MEDIA_PROVIDER=cloudinary and configure Cloudinary credentials.',
      );
    }

    const cloudName = this.config.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = this.config.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = this.config.get<string>('CLOUDINARY_API_SECRET');
    if (!cloudName || !apiKey || !apiSecret) {
      throw new ServiceUnavailableException(
        'Cloudinary uploads are unavailable because CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, or CLOUDINARY_API_SECRET is missing.',
      );
    }

    return { cloudName, apiKey, apiSecret };
  }

  private publicApiUrl() {
    const configuredUrl = this.config.get<string>('PUBLIC_API_URL')?.trim();
    const port = this.config.get<string>('PORT') ?? '3000';
    return (configuredUrl || `http://localhost:${port}`).replace(/\/+$/, '');
  }

  private async removeTemporaryFile(path: string) {
    await unlink(path).catch(() => undefined);
  }
}
