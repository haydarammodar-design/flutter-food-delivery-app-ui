import { HealthService } from './health/health.service';

describe('HealthService', () => {
  it('returns an API liveness response', () => {
    const result = new HealthService().getStatus();

    expect(result.status).toBe('ok');
    expect(result.service).toBe('food-delivery-api');
    expect(result.timestamp).toEqual(expect.any(String));
  });
});
