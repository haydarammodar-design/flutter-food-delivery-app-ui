import { DeliveryStatus } from '@prisma/client';
import {
  DeliveryStatusRequest,
  expectedDeliveryStatus,
  isDeliveryTransitionAllowed,
  requestedDeliveryStatus,
} from './delivery-state';

describe('delivery state machine', () => {
  it('only permits the courier dispatch sequence', () => {
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.OFFERED,
        DeliveryStatus.ACCEPTED,
      ),
    ).toBe(true);
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.ACCEPTED,
        DeliveryStatus.ARRIVED,
      ),
    ).toBe(true);
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.ARRIVED,
        DeliveryStatus.PICKED_UP,
      ),
    ).toBe(true);
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.PICKED_UP,
        DeliveryStatus.DELIVERED,
      ),
    ).toBe(true);
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.OFFERED,
        DeliveryStatus.PICKED_UP,
      ),
    ).toBe(false);
    expect(
      isDeliveryTransitionAllowed(
        DeliveryStatus.DELIVERED,
        DeliveryStatus.ARRIVED,
      ),
    ).toBe(false);
  });

  it('maps accepted API values to persisted delivery states', () => {
    expect(requestedDeliveryStatus(DeliveryStatusRequest.PICKED_UP)).toBe(
      DeliveryStatus.PICKED_UP,
    );
    expect(expectedDeliveryStatus(DeliveryStatus.ARRIVED)).toBe(
      DeliveryStatus.PICKED_UP,
    );
  });
});
