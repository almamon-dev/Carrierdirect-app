import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:driver_app/features/trips/presentation/screens/trips_screen.dart';
import 'package:driver_app/features/trips/presentation/screens/shipment_details_screen.dart';

void main() {
  testWidgets('Test TripsScreen rendering', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TripsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(TripsScreen), findsOneWidget);
  });

  testWidgets('Test ShipmentDetailsScreen rendering', (
    WidgetTester tester,
  ) async {
    const dummy = ShipmentItem(
      id: 'SHP-9982',
      originTitle: 'Milan Central Hub',
      originAddress: 'Via Monte Napoleone, 8, Milan',
      destTitle: 'Lyon Cargo Depot',
      destAddress: '45 Rue de la République, Lyon',
      distanceKm: 450.0,
      cargoType: 'Standard Freight',
      status: ShipmentFilter.inProgress,
      statusLabel: 'In Transit',
      time: '09:30 AM',
      date: 'Today',
      originLat: 45.4642,
      originLng: 9.1900,
      destLat: 45.7640,
      destLng: 4.8357,
    );

    await tester.pumpWidget(
      const MaterialApp(home: ShipmentDetailsScreen(shipment: dummy)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShipmentDetailsScreen), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Route'), findsOneWidget);
    expect(find.text('Chat'), findsNothing);

    // Switch to Route tab
    await tester.tap(find.text('Route'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Switch back to Overview tab
    await tester.tap(find.text('Overview'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'Test SettingsScreen renders Push Notifications, Change Password (no Current Password), and Account & Session',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('App Settings & Security'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Security & Driver Authentication'), findsOneWidget);
      expect(find.text('Change App Password'), findsOneWidget);
      expect(find.text('Account & Session'), findsOneWidget);
      expect(find.text('Log Out of CarrierDirect'), findsOneWidget);

      // 2FA (deferred for future) & removed items must not exist
      expect(find.text('Two-Factor Authentication (2FA)'), findsNothing);
      expect(find.text('Biometric Lock (Face ID / Fingerprint)'), findsNothing);
      expect(find.text('Smart Route & Navigation Engine'), findsNothing);

      // Tap Change App Password -> verify New Password & Confirm New Password only (no Current Password)
      await tester.tap(find.text('Change App Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Current Password'), findsNothing);
    },
  );

  testWidgets('Test 6 activity steps with awaiting customer approval', (
    WidgetTester tester,
  ) async {
    const deliveredShipment = ShipmentItem(
      id: 'SHP-1002',
      originTitle: 'Origin Hub',
      originAddress: 'Origin St',
      destTitle: 'Dest Point',
      destAddress: 'Dest Rd',
      distanceKm: 25.0,
      cargoType: 'Standard Freight',
      status: ShipmentFilter.completed,
      statusLabel: 'Delivered',
      rawStatus: 'delivered',
      time: '08:00 AM',
      date: '22 Oct 2026',
      signedBy: 'John Doe',
      podDate: '2026-10-22T19:25:00Z',
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: deliveredShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Order Confirmed'), findsOneWidget);
    expect(find.text('Collection Driver Assigned'), findsOneWidget);
    expect(find.text('Goods Picked Up'), findsOneWidget);
    expect(find.text('In Transit to Final Destination'), findsOneWidget);
    expect(find.text('Delivered & POD Submitted'), findsWidgets);
    expect(find.text('POD Review & Approval'), findsOneWidget);
    expect(find.text('Awaiting Customer'), findsWidgets);
  });

  testWidgets('Test Order Completed when customer approved', (
    WidgetTester tester,
  ) async {
    const completedShipment = ShipmentItem(
      id: 'SHP-1003',
      originTitle: 'Origin Hub',
      originAddress: 'Origin St',
      destTitle: 'Dest Point',
      destAddress: 'Dest Rd',
      distanceKm: 25.0,
      cargoType: 'Standard Freight',
      status: ShipmentFilter.completed,
      statusLabel: 'Completed',
      rawStatus: 'completed',
      time: '08:00 AM',
      date: '22 Oct 2026',
      signedBy: 'John Doe',
      podDate: '2026-10-22T19:25:00Z',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: completedShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('POD Review & Approval'), findsWidgets);
  });

  testWidgets('Test Multi-Driver Relay corridor for Leg 1 Driver with OTP', (
    WidgetTester tester,
  ) async {
    const relayLeg1Shipment = ShipmentItem(
      id: 'ORD-2026-10006',
      originTitle: 'Milan Logistics Hub',
      originAddress: 'Via Milan 10',
      destTitle: 'Paris Cargo Terminal',
      destAddress: 'Rue Paris 25',
      distanceKm: 850.0,
      cargoType: 'Industrial Machinery',
      status: ShipmentFilter.inProgress,
      statusLabel: 'Handover Pending',
      rawStatus: 'handover_pending',
      time: '10:00 AM',
      date: 'Today',
      isRelay: true,
      isDeliveryOnly: false,
      driverLegNumber: 1,
      currentActiveLeg: 1,
      hubLocation: 'Lyon Relay Hub',
      partnerDriver: {
        'driver_name': 'Marco Rossi',
        'driver_phone': '+33 6 12 34 56 78',
      },
      handover: {
        'status': 'pending',
        'otp_code': '849201',
      },
      relayLegs: [
        {
          'leg_number': 1,
          'journey_leg': 'Milan ➔ Lyon',
          'status': 'handover_pending',
          'driver_name': 'You (Driver 1)',
        },
        {
          'leg_number': 2,
          'journey_leg': 'Lyon ➔ Paris',
          'status': 'assigned',
          'driver_name': 'Marco Rossi',
        }
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: relayLeg1Shipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shipment Timeline'), findsOneWidget);
    expect(find.text('Delivery Driver Assigned'), findsOneWidget);
    expect(find.text('Relay Partner: Marco Rossi'), findsOneWidget);
    expect(find.text('849201'), findsOneWidget);
    expect(find.text('View Handover OTP & Cargo'), findsWidgets);
  });

  testWidgets('Test Multi-Driver Relay for Leg 2 Driver ready to accept cargo', (
    WidgetTester tester,
  ) async {
    const relayLeg2Shipment = ShipmentItem(
      id: 'ORD-2026-10006',
      originTitle: 'Milan Logistics Hub',
      originAddress: 'Via Milan 10',
      destTitle: 'Paris Cargo Terminal',
      destAddress: 'Rue Paris 25',
      distanceKm: 850.0,
      cargoType: 'Industrial Machinery',
      status: ShipmentFilter.scheduled,
      statusLabel: 'Handover Ready at Hub',
      rawStatus: 'handover_pending',
      time: '10:00 AM',
      date: 'Today',
      isRelay: true,
      isDeliveryOnly: true,
      driverLegNumber: 2,
      currentActiveLeg: 1,
      hubLocation: 'Lyon Relay Hub',
      partnerDriver: {
        'driver_name': 'Jean Dupont',
        'driver_phone': '+33 6 98 76 54 32',
      },
      handover: {
        'status': 'pending',
      },
      relayLegs: [
        {
          'leg_number': 1,
          'journey_leg': 'Milan ➔ Lyon',
          'status': 'handover_pending',
          'driver_name': 'Jean Dupont',
        },
        {
          'leg_number': 2,
          'journey_leg': 'Lyon ➔ Paris',
          'status': 'assigned',
          'driver_name': 'You (Driver 2)',
        }
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: relayLeg2Shipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Shipment Timeline'), findsOneWidget);
    expect(find.text('Delivery Driver Assigned'), findsOneWidget);
    expect(find.text('Accept Cargo from Driver 1'), findsWidgets);
  });

  testWidgets('Test Single Driver at delivery displays Upload POD action', (
    WidgetTester tester,
  ) async {
    const atDeliveryShipment = ShipmentItem(
      id: 'SHP-7721',
      originTitle: 'Berlin Central',
      originAddress: 'Alexanderplatz 1',
      destTitle: 'Hamburg Harbor',
      destAddress: 'Hafenstr 5',
      distanceKm: 280.0,
      cargoType: 'Electronics',
      status: ShipmentFilter.inProgress,
      statusLabel: 'At Delivery',
      rawStatus: 'at_delivery',
      time: '02:00 PM',
      date: 'Today',
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: atDeliveryShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Complete Delivery & Upload POD'), findsOneWidget);
  });

  testWidgets('Test Relay Leg 2 Driver in transit displays active milestone and arrive action', (
    WidgetTester tester,
  ) async {
    const relayLeg2InTransitShipment = ShipmentItem(
      id: 'ORD-2026-10006',
      originTitle: 'Milan Logistics Hub',
      originAddress: 'Via Milan 10',
      destTitle: 'Paris Cargo Terminal',
      destAddress: 'Rue Paris 25',
      distanceKm: 850.0,
      cargoType: 'Industrial Machinery',
      status: ShipmentFilter.inProgress,
      statusLabel: 'In Transit',
      rawStatus: 'in_transit',
      time: '10:00 AM',
      date: 'Today',
      isRelay: true,
      isDeliveryOnly: true,
      driverLegNumber: 2,
      currentActiveLeg: 2,
      hubLocation: 'Lyon Relay Hub',
      handover: {
        'status': 'accepted',
        'accepted_at': '2026-11-15T10:30:00Z',
      },
      relayLegs: [
        {
          'leg_number': 1,
          'journey_leg': 'Milan ➔ Lyon',
          'status': 'completed',
          'driver_name': 'Jean Dupont',
        },
        {
          'leg_number': 2,
          'journey_leg': 'Lyon ➔ Paris',
          'status': 'in_transit',
          'driver_name': 'You (Driver 2)',
        }
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: relayLeg2InTransitShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('In Transit to Final Destination'), findsOneWidget);
    expect(find.text('Slide to arrive at Destination'), findsOneWidget);
  });

  testWidgets('Test Relay Leg 2 Driver at delivery displays transit done and POD button', (
    WidgetTester tester,
  ) async {
    const relayLeg2AtDeliveryShipment = ShipmentItem(
      id: 'ORD-2026-10006',
      originTitle: 'Milan Logistics Hub',
      originAddress: 'Via Milan 10',
      destTitle: 'Paris Cargo Terminal',
      destAddress: 'Rue Paris 25',
      distanceKm: 850.0,
      cargoType: 'Industrial Machinery',
      status: ShipmentFilter.inProgress,
      statusLabel: 'At Delivery',
      rawStatus: 'at_delivery',
      time: '10:00 AM',
      date: 'Today',
      isRelay: true,
      isDeliveryOnly: true,
      driverLegNumber: 2,
      currentActiveLeg: 2,
      hubLocation: 'Lyon Relay Hub',
      handover: {
        'status': 'accepted',
        'accepted_at': '2026-11-15T10:30:00Z',
      },
      relayLegs: [
        {
          'leg_number': 1,
          'journey_leg': 'Milan ➔ Lyon',
          'status': 'completed',
          'driver_name': 'Jean Dupont',
        },
        {
          'leg_number': 2,
          'journey_leg': 'Lyon ➔ Paris',
          'status': 'at_delivery',
          'driver_name': 'You (Driver 2)',
        }
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: relayLeg2AtDeliveryShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('In Transit to Final Destination'), findsOneWidget);
    expect(find.text('Delivered & POD Submitted'), findsOneWidget);
    expect(find.text('Complete Delivery & Upload POD'), findsOneWidget);
  });

  testWidgets('Test Leg 1 Driver viewing relay order when Leg 2 is at delivery shows Arrived, not completed', (
    WidgetTester tester,
  ) async {
    const relayLeg1ViewerShipment = ShipmentItem(
      id: 'ORD-2026-10006',
      originTitle: 'Dhaka',
      originAddress: 'Tejgaon, Dhaka',
      destTitle: 'Chittagong',
      destAddress: 'Agrabad, Chittagong',
      distanceKm: 250.0,
      cargoType: 'Euro Pallets (EPAL-1)',
      status: ShipmentFilter.inProgress,
      statusLabel: 'At Delivery',
      rawStatus: 'at_delivery',
      rawMilestoneStatus: 'at_delivery',
      orderStatus: 'in_transit',
      time: '10:00 AM',
      date: 'Today',
      isRelay: true,
      isDeliveryOnly: false,
      driverLegNumber: 1,
      currentActiveLeg: 2,
      hubLocation: 'Intermediate Hub',
      partnerDriver: {
        'driver_name': 'Sean Murphy',
        'driver_phone': '+880 17 0000 0000',
      },
      handover: {
        'status': 'accepted',
        'accepted_at': '2026-11-16T00:33:00Z',
      },
      relayLegs: [
        {
          'leg_number': 1,
          'journey_leg': 'Dhaka ➔ Intermediate Hub',
          'status': 'completed',
          'driver_name': 'Aidan Moroney',
        },
        {
          'leg_number': 2,
          'journey_leg': 'Intermediate Hub ➔ Chittagong',
          'status': 'at_delivery',
          'driver_name': 'Sean Murphy',
        }
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ShipmentDetailsScreen(shipment: relayLeg1ViewerShipment),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Leg 1 completion action banner
    expect(find.text('Collection Completed • Handed Over'), findsOneWidget);
    // Verify Step 8 is active with Arrived text
    expect(find.text('Delivered & POD Submitted'), findsOneWidget);
    expect(find.text('Arrived'), findsOneWidget);
    expect(find.text('Sean Murphy arrived at Chittagong; unloading cargo and obtaining consignee signature.'), findsOneWidget);
    // Verify Step 9 is Pending
    expect(find.text('POD Review & Approval'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
  });
}

