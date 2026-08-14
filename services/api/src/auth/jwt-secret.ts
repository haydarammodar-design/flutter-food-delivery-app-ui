import { Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomBytes } from 'crypto';

let ephemeralDevelopmentSecret: string | undefined;

export function resolveJwtSecret(config: ConfigService): string {
  const configuredSecret = config.get<string>('JWT_SECRET');
  const isProduction = config.get<string>('NODE_ENV') === 'production';

  if (configuredSecret && !configuredSecret.startsWith('replace-with-')) {
    return configuredSecret;
  }

  if (isProduction) {
    throw new ServiceUnavailableException(
      'JWT_SECRET must be configured in production.',
    );
  }

  if (!ephemeralDevelopmentSecret) {
    ephemeralDevelopmentSecret = randomBytes(32).toString('hex');
    new Logger('AuthModule').warn(
      'JWT_SECRET is not configured. Generated development tokens expire after this process restarts.',
    );
  }

  return ephemeralDevelopmentSecret;
}
