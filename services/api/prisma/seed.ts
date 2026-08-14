import {
  DeliveryStatus,
  MembershipRole,
  MerchantType,
  OrderStatus,
  PaymentProvider,
  PaymentStatus,
  PrismaClient,
  Role,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const seedPassword = process.env.SEED_PASSWORD;
  const adminPassword = process.env.ADMIN_PASSWORD ?? seedPassword;

  if (!seedPassword || !adminPassword) {
    throw new Error(
      'Set SEED_PASSWORD and ADMIN_PASSWORD before running the Prisma seed.',
    );
  }

  const passwordHash = await bcrypt.hash(seedPassword, 12);
  const adminPasswordHash = await bcrypt.hash(adminPassword, 12);

  const admin = await prisma.user.upsert({
    where: { email: process.env.ADMIN_EMAIL ?? 'admin@example.test' },
    update: {
      firstName: 'Platform',
      lastName: 'Admin',
      passwordHash: adminPasswordHash,
      role: Role.ADMIN,
      isActive: true,
    },
    create: {
      email: process.env.ADMIN_EMAIL ?? 'admin@example.test',
      firstName: 'Platform',
      lastName: 'Admin',
      passwordHash: adminPasswordHash,
      role: Role.ADMIN,
    },
  });

  const customer = await prisma.user.upsert({
    where: { email: 'customer@example.test' },
    update: {
      firstName: 'Casey',
      lastName: 'Customer',
      phone: '+15550002001',
      passwordHash,
      role: Role.CUSTOMER,
      isActive: true,
    },
    create: {
      email: 'customer@example.test',
      firstName: 'Casey',
      lastName: 'Customer',
      phone: '+15550002001',
      passwordHash,
      role: Role.CUSTOMER,
    },
  });

  const merchantUser = await prisma.user.upsert({
    where: { email: 'merchant@example.test' },
    update: {
      firstName: 'Morgan',
      lastName: 'Merchant',
      passwordHash,
      role: Role.MERCHANT,
      isActive: true,
    },
    create: {
      email: 'merchant@example.test',
      firstName: 'Morgan',
      lastName: 'Merchant',
      passwordHash,
      role: Role.MERCHANT,
    },
  });

  const courier = await prisma.user.upsert({
    where: { email: 'courier@example.test' },
    update: {
      firstName: 'Chris',
      lastName: 'Courier',
      passwordHash,
      role: Role.COURIER,
      isActive: true,
    },
    create: {
      email: 'courier@example.test',
      firstName: 'Chris',
      lastName: 'Courier',
      passwordHash,
      role: Role.COURIER,
    },
  });

  const restaurant = await prisma.merchant.upsert({
    where: { slug: 'harbor-kitchen' },
    update: {
      name: 'Harbor Kitchen',
      type: MerchantType.RESTAURANT,
      isActive: true,
      isOpen: true,
    },
    create: {
      name: 'Harbor Kitchen',
      slug: 'harbor-kitchen',
      type: MerchantType.RESTAURANT,
      description: 'Comfort food made for delivery.',
      contactEmail: 'orders@harborkitchen.example.test',
      phone: '+15550001001',
      streetAddress: '100 Harbor Street',
      city: 'Springfield',
      state: 'CA',
      postalCode: '90001',
      latitude: 34.0522,
      longitude: -118.2437,
      minimumOrderAmount: 10,
      deliveryFee: 2.99,
      estimatedDeliveryMinutes: 30,
    },
  });

  const grocery = await prisma.merchant.upsert({
    where: { slug: 'market-garden' },
    update: {
      name: 'Market Garden',
      type: MerchantType.GROCERY,
      isActive: true,
      isOpen: true,
    },
    create: {
      name: 'Market Garden',
      slug: 'market-garden',
      type: MerchantType.GROCERY,
      description: 'Fresh produce and pantry essentials.',
      contactEmail: 'hello@marketgarden.example.test',
      phone: '+15550001002',
      streetAddress: '55 Market Lane',
      city: 'Springfield',
      state: 'CA',
      postalCode: '90002',
      latitude: 34.0622,
      longitude: -118.2537,
      minimumOrderAmount: 15,
      deliveryFee: 3.99,
      estimatedDeliveryMinutes: 45,
    },
  });

  await Promise.all(
    [restaurant, grocery].map((merchant) =>
      prisma.merchantMembership.upsert({
        where: {
          merchantId_userId: {
            merchantId: merchant.id,
            userId: merchantUser.id,
          },
        },
        update: { role: MembershipRole.OWNER, isActive: true },
        create: {
          merchantId: merchant.id,
          userId: merchantUser.id,
          role: MembershipRole.OWNER,
        },
      }),
    ),
  );

  const burgers = await prisma.category.upsert({
    where: { slug: 'burgers' },
    update: { name: 'Burgers', isActive: true, sortOrder: 10 },
    create: {
      name: 'Burgers',
      slug: 'burgers',
      description: 'Restaurant favorites.',
      sortOrder: 10,
    },
  });

  const produce = await prisma.category.upsert({
    where: { slug: 'produce' },
    update: { name: 'Produce', isActive: true, sortOrder: 20 },
    create: {
      name: 'Produce',
      slug: 'produce',
      description: 'Fresh grocery staples.',
      sortOrder: 20,
    },
  });

  const burger = await prisma.catalogProduct.upsert({
    where: {
      merchantId_sku: { merchantId: restaurant.id, sku: 'HK-CLASSIC-001' },
    },
    update: {
      categoryId: burgers.id,
      name: 'Classic Harbor Burger',
      price: 12.99,
      isPublished: true,
      isAvailable: true,
      trackInventory: true,
      inventoryQuantity: 32,
      allowSubstitutions: false,
    },
    create: {
      merchantId: restaurant.id,
      categoryId: burgers.id,
      sku: 'HK-CLASSIC-001',
      name: 'Classic Harbor Burger',
      description: 'Beef patty, pickles, lettuce, tomato, and house sauce.',
      price: 12.99,
      tags: ['popular', 'burger'],
      isPublished: true,
      isAvailable: true,
      trackInventory: true,
      inventoryQuantity: 32,
      lowStockThreshold: 5,
      allowSubstitutions: false,
      sortOrder: 10,
    },
  });

  const bananas = await prisma.catalogProduct.upsert({
    where: {
      merchantId_sku: { merchantId: grocery.id, sku: 'MG-BANANAS-001' },
    },
    update: {
      categoryId: produce.id,
      name: 'Organic Bananas',
      price: 2.49,
      isPublished: true,
      isAvailable: true,
      trackInventory: true,
      inventoryQuantity: 18,
      allowSubstitutions: true,
      substitutionNote: 'Substitute with conventional bananas if needed.',
    },
    create: {
      merchantId: grocery.id,
      categoryId: produce.id,
      sku: 'MG-BANANAS-001',
      name: 'Organic Bananas',
      description: 'One bunch of organic bananas.',
      price: 2.49,
      tags: ['organic', 'produce'],
      isPublished: true,
      isAvailable: true,
      trackInventory: true,
      inventoryQuantity: 18,
      lowStockThreshold: 4,
      allowSubstitutions: true,
      substitutionNote: 'Substitute with conventional bananas if needed.',
      sortOrder: 10,
    },
  });

  const deliveryAddress = await prisma.address.upsert({
    where: { userId_label: { userId: customer.id, label: 'Home' } },
    update: { isDefault: true },
    create: {
      userId: customer.id,
      label: 'Home',
      recipientName: 'Casey Customer',
      phone: '+15550002001',
      line1: '42 Customer Avenue',
      city: 'Springfield',
      state: 'CA',
      postalCode: '90003',
      countryCode: 'US',
      latitude: 34.0722,
      longitude: -118.2637,
      deliveryNotes: 'Leave at the front desk.',
      isDefault: true,
    },
  });

  const workAddress = await prisma.address.upsert({
    where: { userId_label: { userId: customer.id, label: 'Work' } },
    update: { isDefault: false },
    create: {
      userId: customer.id,
      label: 'Work',
      recipientName: 'Casey Customer',
      phone: '+15550002001',
      line1: '88 Office Park',
      line2: 'Suite 200',
      city: 'Springfield',
      state: 'CA',
      postalCode: '90004',
      countryCode: 'US',
      latitude: 34.0822,
      longitude: -118.2737,
      deliveryNotes: 'Call from the lobby.',
      isDefault: false,
    },
  });

  await prisma.courierProfile.upsert({
    where: { userId: courier.id },
    update: {
      vehicleType: 'Bicycle',
      vehiclePlate: 'BIKE-42',
      isAvailable: true,
      currentLatitude: 34.0522,
      currentLongitude: -118.2437,
    },
    create: {
      userId: courier.id,
      vehicleType: 'Bicycle',
      vehiclePlate: 'BIKE-42',
      isAvailable: true,
      currentLatitude: 34.0522,
      currentLongitude: -118.2437,
    },
  });

  const order = await prisma.order.upsert({
    where: { orderNumber: 'DEMO-1001' },
    update: {
      status: OrderStatus.DELIVERED,
      courierId: courier.id,
      totalAmount: 17.02,
      deliveredAt: new Date(),
    },
    create: {
      orderNumber: 'DEMO-1001',
      customerId: customer.id,
      merchantId: restaurant.id,
      courierId: courier.id,
      deliveryAddressId: deliveryAddress.id,
      deliveryAddressSnapshot: {
        recipientName: deliveryAddress.recipientName,
        line1: deliveryAddress.line1,
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        postalCode: deliveryAddress.postalCode,
        countryCode: deliveryAddress.countryCode,
      },
      status: OrderStatus.DELIVERED,
      currency: 'USD',
      subtotal: 12.99,
      deliveryFee: 2.99,
      serviceFee: 0.5,
      tax: 0.54,
      discount: 0,
      totalAmount: 17.02,
      placedAt: new Date(),
      deliveredAt: new Date(),
      items: {
        create: {
          productId: burger.id,
          productName: burger.name,
          productSku: burger.sku,
          quantity: 1,
          unitPrice: burger.price,
          totalPrice: burger.price,
        },
      },
    },
  });

  const restaurantOfferOrder = await prisma.order.upsert({
    where: { orderNumber: 'DEMO-2001' },
    update: {
      status: OrderStatus.READY_FOR_PICKUP,
      courierId: null,
      deliveryAddressId: deliveryAddress.id,
      deliveredAt: null,
      totalAmount: 17.02,
    },
    create: {
      orderNumber: 'DEMO-2001',
      customerId: customer.id,
      merchantId: restaurant.id,
      deliveryAddressId: deliveryAddress.id,
      deliveryAddressSnapshot: {
        recipientName: deliveryAddress.recipientName,
        line1: deliveryAddress.line1,
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        postalCode: deliveryAddress.postalCode,
        countryCode: deliveryAddress.countryCode,
      },
      status: OrderStatus.READY_FOR_PICKUP,
      currency: 'USD',
      subtotal: 12.99,
      deliveryFee: 2.99,
      serviceFee: 0.5,
      tax: 0.54,
      discount: 0,
      totalAmount: 17.02,
      customerNotes: 'Please include napkins.',
      placedAt: new Date(),
      items: {
        create: {
          productId: burger.id,
          productName: burger.name,
          productSku: burger.sku,
          quantity: 1,
          unitPrice: burger.price,
          totalPrice: burger.price,
        },
      },
    },
  });

  const groceryOfferOrder = await prisma.order.upsert({
    where: { orderNumber: 'DEMO-2002' },
    update: {
      status: OrderStatus.READY_FOR_PICKUP,
      courierId: null,
      deliveryAddressId: workAddress.id,
      deliveredAt: null,
      totalAmount: 6.98,
    },
    create: {
      orderNumber: 'DEMO-2002',
      customerId: customer.id,
      merchantId: grocery.id,
      deliveryAddressId: workAddress.id,
      deliveryAddressSnapshot: {
        recipientName: workAddress.recipientName,
        line1: workAddress.line1,
        line2: workAddress.line2,
        city: workAddress.city,
        state: workAddress.state,
        postalCode: workAddress.postalCode,
        countryCode: workAddress.countryCode,
      },
      status: OrderStatus.READY_FOR_PICKUP,
      currency: 'USD',
      subtotal: 2.49,
      deliveryFee: 3.99,
      serviceFee: 0.3,
      tax: 0.2,
      discount: 0,
      totalAmount: 6.98,
      customerNotes: 'Choose ripe bananas if available.',
      placedAt: new Date(),
      items: {
        create: {
          productId: bananas.id,
          productName: bananas.name,
          productSku: bananas.sku,
          quantity: 1,
          unitPrice: bananas.price,
          totalPrice: bananas.price,
          substitutionAllowed: true,
        },
      },
    },
  });

  const activeOrder = await prisma.order.upsert({
    where: { orderNumber: 'DEMO-2003' },
    update: {
      status: OrderStatus.OUT_FOR_DELIVERY,
      courierId: courier.id,
      deliveryAddressId: deliveryAddress.id,
      deliveredAt: null,
      totalAmount: 17.02,
    },
    create: {
      orderNumber: 'DEMO-2003',
      customerId: customer.id,
      merchantId: restaurant.id,
      courierId: courier.id,
      deliveryAddressId: deliveryAddress.id,
      deliveryAddressSnapshot: {
        recipientName: deliveryAddress.recipientName,
        line1: deliveryAddress.line1,
        city: deliveryAddress.city,
        state: deliveryAddress.state,
        postalCode: deliveryAddress.postalCode,
        countryCode: deliveryAddress.countryCode,
      },
      status: OrderStatus.OUT_FOR_DELIVERY,
      currency: 'USD',
      subtotal: 12.99,
      deliveryFee: 2.99,
      serviceFee: 0.5,
      tax: 0.54,
      discount: 0,
      totalAmount: 17.02,
      customerNotes: 'Leave at the front desk.',
      placedAt: new Date(),
      items: {
        create: {
          productId: burger.id,
          productName: burger.name,
          productSku: burger.sku,
          quantity: 1,
          unitPrice: burger.price,
          totalPrice: burger.price,
        },
      },
    },
  });

  const deliveryTime = new Date();
  const completedDelivery = await prisma.delivery.upsert({
    where: { orderId: order.id },
    update: {
      courierId: courier.id,
      status: DeliveryStatus.DELIVERED,
      earnings: 7.5,
      distanceKm: 3.4,
      etaMinutes: 0,
      pickupNote: 'Ask for the courier shelf by the front desk.',
      dropoffNote: 'Leave at the front desk.',
      acceptedAt: deliveryTime,
      arrivedAt: deliveryTime,
      pickedUpAt: deliveryTime,
      deliveredAt: deliveryTime,
    },
    create: {
      orderId: order.id,
      courierId: courier.id,
      status: DeliveryStatus.DELIVERED,
      earnings: 7.5,
      distanceKm: 3.4,
      etaMinutes: 0,
      pickupNote: 'Ask for the courier shelf by the front desk.',
      dropoffNote: 'Leave at the front desk.',
      acceptedAt: deliveryTime,
      arrivedAt: deliveryTime,
      pickedUpAt: deliveryTime,
      deliveredAt: deliveryTime,
    },
  });

  const restaurantOffer = await prisma.delivery.upsert({
    where: { orderId: restaurantOfferOrder.id },
    update: {
      courierId: null,
      status: DeliveryStatus.OFFERED,
      earnings: 8.4,
      distanceKm: 2.1,
      etaMinutes: 18,
      pickupNote: 'Collect the sealed bag from counter two.',
      dropoffNote: null,
      acceptedAt: null,
      arrivedAt: null,
      pickedUpAt: null,
      deliveredAt: null,
    },
    create: {
      orderId: restaurantOfferOrder.id,
      status: DeliveryStatus.OFFERED,
      earnings: 8.4,
      distanceKm: 2.1,
      etaMinutes: 18,
      pickupNote: 'Collect the sealed bag from counter two.',
    },
  });

  const groceryOffer = await prisma.delivery.upsert({
    where: { orderId: groceryOfferOrder.id },
    update: {
      courierId: null,
      status: DeliveryStatus.OFFERED,
      earnings: 11.6,
      distanceKm: 4.8,
      etaMinutes: 25,
      pickupNote: 'Use the collection point by the produce entrance.',
      dropoffNote: 'Call from the lobby.',
      acceptedAt: null,
      arrivedAt: null,
      pickedUpAt: null,
      deliveredAt: null,
    },
    create: {
      orderId: groceryOfferOrder.id,
      status: DeliveryStatus.OFFERED,
      earnings: 11.6,
      distanceKm: 4.8,
      etaMinutes: 25,
      pickupNote: 'Use the collection point by the produce entrance.',
      dropoffNote: 'Call from the lobby.',
    },
  });

  const activeDelivery = await prisma.delivery.upsert({
    where: { orderId: activeOrder.id },
    update: {
      courierId: courier.id,
      status: DeliveryStatus.PICKED_UP,
      earnings: 9.8,
      distanceKm: 3.4,
      etaMinutes: 11,
      pickupNote: 'Ask for the courier shelf by the front desk.',
      dropoffNote: 'Use the side entrance beside the green gate.',
      acceptedAt: deliveryTime,
      arrivedAt: deliveryTime,
      pickedUpAt: deliveryTime,
      deliveredAt: null,
    },
    create: {
      orderId: activeOrder.id,
      courierId: courier.id,
      status: DeliveryStatus.PICKED_UP,
      earnings: 9.8,
      distanceKm: 3.4,
      etaMinutes: 11,
      pickupNote: 'Ask for the courier shelf by the front desk.',
      dropoffNote: 'Use the side entrance beside the green gate.',
      acceptedAt: deliveryTime,
      arrivedAt: deliveryTime,
      pickedUpAt: deliveryTime,
    },
  });

  await Promise.all([
    prisma.orderStatusHistory.upsert({
      where: { orderId_sequence: { orderId: order.id, sequence: 1 } },
      update: { status: OrderStatus.PLACED, note: 'Demo order placed.' },
      create: {
        orderId: order.id,
        changedById: customer.id,
        sequence: 1,
        status: OrderStatus.PLACED,
        note: 'Demo order placed.',
      },
    }),
    prisma.orderStatusHistory.upsert({
      where: { orderId_sequence: { orderId: order.id, sequence: 2 } },
      update: { status: OrderStatus.DELIVERED, note: 'Demo order delivered.' },
      create: {
        orderId: order.id,
        changedById: courier.id,
        sequence: 2,
        status: OrderStatus.DELIVERED,
        note: 'Demo order delivered.',
      },
    }),
    prisma.payment.upsert({
      where: { externalId: 'pi_demo_1001' },
      update: { status: PaymentStatus.SUCCEEDED, amount: 17.02 },
      create: {
        orderId: order.id,
        provider: PaymentProvider.STRIPE,
        externalId: 'pi_demo_1001',
        status: PaymentStatus.SUCCEEDED,
        amount: 17.02,
        currency: 'USD',
      },
    }),
  ]);

  const seedDeliveryHistory = async (
    deliveryId: string,
    entries: Array<{
      status: DeliveryStatus;
      previousStatus?: DeliveryStatus;
      changedById?: string;
      note: string;
    }>,
  ) => {
    await Promise.all(
      entries.map((entry, index) =>
        prisma.deliveryStatusHistory.upsert({
          where: {
            deliveryId_sequence: { deliveryId, sequence: index + 1 },
          },
          update: {
            previousStatus: entry.previousStatus ?? null,
            status: entry.status,
            changedById: entry.changedById ?? null,
            note: entry.note,
          },
          create: {
            deliveryId,
            sequence: index + 1,
            previousStatus: entry.previousStatus,
            status: entry.status,
            changedById: entry.changedById,
            note: entry.note,
          },
        }),
      ),
    );
  };

  await Promise.all([
    seedDeliveryHistory(completedDelivery.id, [
      {
        status: DeliveryStatus.OFFERED,
        changedById: admin.id,
        note: 'Demo delivery offered.',
      },
      {
        previousStatus: DeliveryStatus.OFFERED,
        status: DeliveryStatus.ACCEPTED,
        changedById: courier.id,
        note: 'Demo delivery accepted.',
      },
      {
        previousStatus: DeliveryStatus.ACCEPTED,
        status: DeliveryStatus.ARRIVED,
        changedById: courier.id,
        note: 'Courier arrived at pickup.',
      },
      {
        previousStatus: DeliveryStatus.ARRIVED,
        status: DeliveryStatus.PICKED_UP,
        changedById: courier.id,
        note: 'Courier collected the order.',
      },
      {
        previousStatus: DeliveryStatus.PICKED_UP,
        status: DeliveryStatus.DELIVERED,
        changedById: courier.id,
        note: 'Demo delivery completed.',
      },
    ]),
    seedDeliveryHistory(restaurantOffer.id, [
      {
        status: DeliveryStatus.OFFERED,
        changedById: admin.id,
        note: 'Restaurant delivery offer available.',
      },
    ]),
    seedDeliveryHistory(groceryOffer.id, [
      {
        status: DeliveryStatus.OFFERED,
        changedById: admin.id,
        note: 'Grocery delivery offer available.',
      },
    ]),
    seedDeliveryHistory(activeDelivery.id, [
      {
        status: DeliveryStatus.OFFERED,
        changedById: admin.id,
        note: 'Demo active delivery offered.',
      },
      {
        previousStatus: DeliveryStatus.OFFERED,
        status: DeliveryStatus.ACCEPTED,
        changedById: courier.id,
        note: 'Courier accepted the delivery.',
      },
      {
        previousStatus: DeliveryStatus.ACCEPTED,
        status: DeliveryStatus.ARRIVED,
        changedById: courier.id,
        note: 'Courier arrived at the merchant.',
      },
      {
        previousStatus: DeliveryStatus.ARRIVED,
        status: DeliveryStatus.PICKED_UP,
        changedById: courier.id,
        note: 'Courier picked up the order.',
      },
    ]),
  ]);

  console.log(
    `Seeded admin ${admin.email}, customer ${customer.email}, merchant ${merchantUser.email}, and courier ${courier.email}.`,
  );
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
