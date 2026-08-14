import { BadRequestException } from '@nestjs/common';

export function toSlug(value: string): string {
  const slug = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  if (!slug) {
    throw new BadRequestException(
      'A name or slug containing letters or numbers is required.',
    );
  }

  return slug;
}
