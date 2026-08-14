import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';

async function bootstrap() {
  const uploadDirectory = join(process.cwd(), 'uploads');
  mkdirSync(uploadDirectory, { recursive: true });

  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  configureApp(app);
  app.useStaticAssets(uploadDirectory, { prefix: '/uploads/' });
  app.enableShutdownHooks();

  const config = app.get(ConfigService);
  const port = Number(config.get<string>('PORT') ?? 3000);
  await app.listen(port, '0.0.0.0');
}

void bootstrap().catch((error: unknown) => {
  const logger = new Logger('Bootstrap');
  logger.error(
    'Unable to start the API.',
    error instanceof Error ? error.stack : String(error),
  );
  process.exitCode = 1;
});
