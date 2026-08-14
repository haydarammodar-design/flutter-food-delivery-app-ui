import {
  Body,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { Role } from '@prisma/client';
import { join } from 'node:path';
import type { AuthenticatedUser } from '../common/auth/authenticated-user.interface';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CloudinarySignatureDto } from './dto/cloudinary-signature.dto';
import { LocalImageUploadDto } from './dto/local-image-upload.dto';
import { MediaService } from './media.service';

const localUploadDirectory = join(process.cwd(), 'uploads');
const supportedImageTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
]);

type UploadedImage = {
  mimetype: string;
  path: string;
};

@ApiTags('media')
@ApiBearerAuth('access-token')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.MERCHANT)
@Controller({ path: 'media', version: '1' })
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('cloudinary/signature')
  createCloudinaryUploadSignature(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CloudinarySignatureDto,
  ) {
    return this.mediaService.createCloudinaryUploadSignature(user, dto);
  }

  @Post('uploads')
  @UseInterceptors(
    FileInterceptor('file', {
      dest: localUploadDirectory,
      limits: { fileSize: 5 * 1024 * 1024, files: 1 },
      fileFilter: (_request, file, callback) => {
        callback(null, supportedImageTypes.has(file.mimetype));
      },
    }),
  )
  uploadLocalImage(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: LocalImageUploadDto,
    @UploadedFile() file: UploadedImage | undefined,
  ) {
    return this.mediaService.storeLocalImage(user, dto, file);
  }
}
