import { DeliveryStatus } from '@prisma/client';

export enum DeliveryStatusRequest {
  ACCEPTED = 'accepted',
  ARRIVED = 'arrived',
  PICKED_UP = 'picked_up',
  DELIVERED = 'delivered',
}

const requestStatusMap: Record<DeliveryStatusRequest, DeliveryStatus> = {
  [DeliveryStatusRequest.ACCEPTED]: DeliveryStatus.ACCEPTED,
  [DeliveryStatusRequest.ARRIVED]: DeliveryStatus.ARRIVED,
  [DeliveryStatusRequest.PICKED_UP]: DeliveryStatus.PICKED_UP,
  [DeliveryStatusRequest.DELIVERED]: DeliveryStatus.DELIVERED,
};

const responseStatusMap: Record<DeliveryStatus, string> = {
  [DeliveryStatus.OFFERED]: 'offered',
  [DeliveryStatus.ACCEPTED]: 'accepted',
  [DeliveryStatus.ARRIVED]: 'arrived',
  [DeliveryStatus.PICKED_UP]: 'picked_up',
  [DeliveryStatus.DELIVERED]: 'delivered',
  [DeliveryStatus.CANCELLED]: 'cancelled',
};

const transitions: Record<DeliveryStatus, readonly DeliveryStatus[]> = {
  [DeliveryStatus.OFFERED]: [DeliveryStatus.ACCEPTED],
  [DeliveryStatus.ACCEPTED]: [DeliveryStatus.ARRIVED],
  [DeliveryStatus.ARRIVED]: [DeliveryStatus.PICKED_UP],
  [DeliveryStatus.PICKED_UP]: [DeliveryStatus.DELIVERED],
  [DeliveryStatus.DELIVERED]: [],
  [DeliveryStatus.CANCELLED]: [],
};

export function requestedDeliveryStatus(
  status: DeliveryStatusRequest,
): DeliveryStatus {
  return requestStatusMap[status];
}

export function deliveryStatusForResponse(status: DeliveryStatus): string {
  return responseStatusMap[status];
}

export function isDeliveryTransitionAllowed(
  from: DeliveryStatus,
  to: DeliveryStatus,
): boolean {
  return transitions[from].includes(to);
}

export function expectedDeliveryStatus(
  status: DeliveryStatus,
): DeliveryStatus | undefined {
  return transitions[status][0];
}
