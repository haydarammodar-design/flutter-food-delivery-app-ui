import {
  Injectable,
  Logger,
  OnApplicationShutdown,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue } from 'bullmq';

export interface CatalogChangeEvent {
  action:
    | 'created'
    | 'updated'
    | 'published'
    | 'unpublished'
    | 'inventory_updated'
    | 'deleted';
  merchantId: string;
  productId: string;
  occurredAt: string;
}

@Injectable()
export class JobsService implements OnModuleInit, OnApplicationShutdown {
  private readonly logger = new Logger(JobsService.name);
  private queue?: Queue<CatalogChangeEvent>;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    if (this.config.get<string>('REDIS_ENABLED') !== 'true') {
      this.logger.log(
        'Catalog jobs are disabled because REDIS_ENABLED is not true.',
      );
      return;
    }

    const port = Number(this.config.get<string>('REDIS_PORT') ?? 6379);
    const db = Number(this.config.get<string>('REDIS_DB') ?? 0);
    this.queue = new Queue<CatalogChangeEvent>('catalog-events', {
      connection: {
        host: this.config.get<string>('REDIS_HOST') ?? '127.0.0.1',
        port: Number.isFinite(port) ? port : 6379,
        db: Number.isFinite(db) ? db : 0,
        username: this.config.get<string>('REDIS_USERNAME') || undefined,
        password: this.config.get<string>('REDIS_PASSWORD') || undefined,
      },
    });
    this.queue.on('error', (error: Error) => {
      this.logger.error('Catalog jobs Redis connection error.', error.stack);
    });
  }

  async publishCatalogChanged(
    event: Omit<CatalogChangeEvent, 'occurredAt'>,
  ): Promise<void> {
    if (!this.queue) {
      return;
    }

    try {
      await this.queue.add(
        'catalog.changed',
        { ...event, occurredAt: new Date().toISOString() },
        {
          removeOnComplete: 1000,
          removeOnFail: 5000,
        },
      );
    } catch (error: unknown) {
      this.logger.warn(
        `Unable to enqueue catalog change for ${event.productId}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  async onApplicationShutdown(): Promise<void> {
    await this.queue?.close();
  }
}
