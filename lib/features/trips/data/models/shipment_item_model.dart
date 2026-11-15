import 'dart:math' as math;

enum ShipmentFilter { all, inProgress, scheduled, completed, cancelled }

class ShipmentItem {
  final String id;
  final String dbId;
  final String truckId;
  final String originTitle;
  final String originAddress;
  final String originCompany;
  final String pickupDate;
  final String pickupTime;
  final String destTitle;
  final String destAddress;
  final String destCompany;
  final String deliveryDate;
  final String deliveryTime;
  final double distanceKm;
  final String cargoType;
  final String equipmentType;
  final String palletQuantity;
  final String temperature;
  final String cargoManifest;
  final String payloadWeight;
  final String hazmatStatus;
  final ShipmentFilter status;
  final String statusLabel;
  final String rawStatus;
  final String time;
  final String date;
  final String signedBy;
  final String podDate;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String pickupContactName;
  final String pickupContactPhone;
  final String deliveryContactName;
  final String deliveryContactPhone;
  final String vehicleType;
  final String serviceType;
  final String payoutEarnings;
  final String specialInstructions;
  final String dimensions;
  final String estimatedDuration;
  final int? customerId;
  final String customerName;
  final String customerAvatar;
  final int? supplierId;
  final String supplierName;
  final String supplierAvatar;
  final String driverType;
  final String driverName;
  final String driverPhone;
  final String subcontractorCompany;
  final String subcontractorJourneyLeg;

  // Relay & Multi-Driver Attributes
  final bool isRelay;
  final bool isDeliveryOnly;
  final int driverLegNumber;
  final int currentActiveLeg;
  final String hubLocation;
  final Map<String, dynamic>? partnerDriver;
  final Map<String, dynamic>? handover;
  final List<Map<String, dynamic>> relayLegs;
  final String rawMilestoneStatus;
  final String orderStatus;

  const ShipmentItem({
    required this.id,
    this.dbId = '',
    this.truckId = '—',
    required this.originTitle,
    required this.originAddress,
    this.originCompany = '—',
    this.pickupDate = '—',
    this.pickupTime = '—',
    required this.destTitle,
    required this.destAddress,
    this.destCompany = '—',
    this.deliveryDate = '—',
    this.deliveryTime = '—',
    required this.distanceKm,
    required this.cargoType,
    this.equipmentType = 'Pallets',
    this.palletQuantity = '1 Pallet',
    this.temperature = 'Ambient / Standard Dry',
    this.cargoManifest = 'Commercial Freight',
    this.payloadWeight = '—',
    this.hazmatStatus = 'No (Standard Cargo)',
    required this.status,
    required this.statusLabel,
    this.rawStatus = '',
    required this.time,
    required this.date,
    this.signedBy = '',
    this.podDate = '',
    this.originLat = 0.0,
    this.originLng = 0.0,
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.pickupContactName = '—',
    this.pickupContactPhone = '—',
    this.deliveryContactName = '—',
    this.deliveryContactPhone = '—',
    this.vehicleType = '—',
    this.serviceType = '—',
    this.payoutEarnings = '—',
    this.specialInstructions = '—',
    this.dimensions = '—',
    this.estimatedDuration = '',
    this.customerId,
    this.customerName = '',
    this.customerAvatar = '',
    this.supplierId,
    this.supplierName = '',
    this.supplierAvatar = '',
    this.driverType = 'internal',
    this.driverName = '',
    this.driverPhone = '',
    this.subcontractorCompany = '',
    this.subcontractorJourneyLeg = '',
    this.isRelay = false,
    this.isDeliveryOnly = false,
    this.driverLegNumber = 1,
    this.currentActiveLeg = 1,
    this.hubLocation = '',
    this.partnerDriver,
    this.handover,
    this.relayLegs = const [],
    this.rawMilestoneStatus = '',
    this.orderStatus = '',
  });

  bool get isSubcontractor => driverType == 'subcontractor' || subcontractorCompany.isNotEmpty;

  /// Relay Workflow Helpers
  bool get isLeg2 => isRelay && (isDeliveryOnly || driverLegNumber == 2);
  bool get isLeg1 => isRelay && !isLeg2;

  bool get isHandoverPending {
    if (!isRelay) return false;
    final hStatus = handover?['status']?.toString().toLowerCase().trim();
    return hStatus == 'pending' ||
        hStatus == 'pending_acceptance' ||
        rawStatus.toLowerCase() == 'handover_pending';
  }

  bool get isHandoverAccepted {
    if (!isRelay) return false;
    final hStatus = handover?['status']?.toString().toLowerCase().trim();
    return currentActiveLeg > 1 ||
        hStatus == 'accepted' ||
        rawStatus.toLowerCase() == 'handover_accepted';
  }

  bool get isLeg1HandoverCompleted {
    if (!isRelay || isDeliveryOnly) return false;
    return isHandoverAccepted ||
        rawStatus.toLowerCase() == 'completed' ||
        rawStatus.toLowerCase() == 'delivered';
  }

  /// Formatted distance string with unit (e.g. "145.5 km") from DB / Google Maps
  String get formattedDistance {
    double d = distanceKm;
    if (d <= 0 &&
        originLat != 0.0 &&
        originLng != 0.0 &&
        destLat != 0.0 &&
        destLng != 0.0) {
      d = _haversineRoadKm(originLat, originLng, destLat, destLng);
    }
    if (d <= 0) {
      return '— km';
    }
    final double rounded = (d * 10).round() / 10.0;
    if (rounded == rounded.truncateToDouble()) {
      return '${rounded.toInt()} km';
    }
    return '${rounded.toStringAsFixed(1)} km';
  }

  static double _haversineRoadKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double straightKm = r * c;
    // Multiply by 1.24 highway road winding factor
    final double roadKm = straightKm * 1.24;
    return ((roadKm * 10).round() / 10.0);
  }

  factory ShipmentItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> safeMap(dynamic val) =>
        (val is Map<String, dynamic>) ? val : (val is Map ? Map<String, dynamic>.from(val) : {});

    final route = safeMap(json['route']);
    final pickup = safeMap(json['pickup']).isNotEmpty ? safeMap(json['pickup']) : safeMap(route['pickup']);
    final delivery = safeMap(json['delivery']).isNotEmpty ? safeMap(json['delivery']) : safeMap(route['delivery']);
    final cargo = safeMap(json['cargo']);
    final tracking = safeMap(json['tracking']);
    final originCoords = safeMap(route['origin_coords']);
    final destCoords = safeMap(route['destination_coords']);
    final driverObj = safeMap(json['driver']);
    final customerObj = safeMap(json['customer']);
    final supplierObj = safeMap(json['supplier']);
    final payout = safeMap(json['payout']);

    final statusStr = (json['status'] ?? '').toString().toLowerCase().trim();
    ShipmentFilter filterStatus = ShipmentFilter.scheduled;
    if (statusStr.contains('transit') ||
        statusStr.contains('progress') ||
        statusStr.contains('picked') ||
        statusStr.contains('arrived') ||
        statusStr == 'active' ||
        statusStr.contains('way')) {
      filterStatus = ShipmentFilter.inProgress;
    } else if (statusStr.contains('deliver') ||
        statusStr.contains('complete') ||
        statusStr.contains('pod') ||
        statusStr.contains('paid') ||
        statusStr.contains('review')) {
      filterStatus = ShipmentFilter.completed;
    } else if (statusStr.contains('cancel') ||
        statusStr.contains('reject') ||
        statusStr.contains('close')) {
      filterStatus = ShipmentFilter.cancelled;
    } else {
      filterStatus = ShipmentFilter.scheduled;
    }

    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      final str = val.toString().replaceAll(',', '').trim();
      if (str.isEmpty) return 0.0;
      final direct = double.tryParse(str);
      if (direct != null) return direct;
      final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(str);
      if (match != null) {
        final parsed = double.tryParse(match.group(0)!) ?? 0.0;
        if (str.toLowerCase().contains('mi')) {
          return ((parsed * 1.60934 * 10).round() / 10.0);
        }
        return parsed;
      }
      return 0.0;
    }

    final String originAddr = json['pickup_address']?.toString() ?? pickup['address']?.toString() ?? '—';
    final String originTitle = json['pickup_city']?.toString() ?? pickup['city']?.toString() ?? pickup['company']?.toString() ?? 'Origin';

    final String destAddr = json['delivery_address']?.toString() ?? delivery['address']?.toString() ?? '—';
    final String destTitle = json['delivery_city']?.toString() ?? delivery['city']?.toString() ?? delivery['company']?.toString() ?? 'Destination';

    // Direct backend fields from DriverShipmentResource + nested fallbacks
    double oLat = toDouble(
      json['pickup_lat'] ??
          pickup['lat'] ??
          pickup['latitude'] ??
          originCoords['lat'] ??
          originCoords['latitude'] ??
          json['origin_lat'],
    );
    double oLng = toDouble(
      json['pickup_lng'] ??
          pickup['lng'] ??
          pickup['lon'] ??
          pickup['longitude'] ??
          originCoords['lng'] ??
          originCoords['lon'] ??
          originCoords['longitude'] ??
          json['origin_lng'],
    );
    double dLat = toDouble(
      json['delivery_lat'] ??
          delivery['lat'] ??
          delivery['latitude'] ??
          destCoords['lat'] ??
          destCoords['latitude'] ??
          json['destination_lat'] ??
          json['dest_lat'],
    );
    double dLng = toDouble(
      json['delivery_lng'] ??
          delivery['lng'] ??
          delivery['lon'] ??
          delivery['longitude'] ??
          destCoords['lng'] ??
          destCoords['lon'] ??
          destCoords['longitude'] ??
          json['destination_lng'] ??
          json['dest_lng'],
    );

    double dist = toDouble(
      json['distance_km'] ??
          route['distance_km'] ??
          json['distance'] ??
          route['distance'] ??
          json['total_distance_km'] ??
          route['total_distance_km'] ??
          json['total_distance'] ??
          route['total_distance'] ??
          json['estimated_distance'] ??
          route['estimated_distance'] ??
          tracking['distance_km'],
    );

    if (dist <= 0.0 &&
        oLat != 0.0 &&
        oLng != 0.0 &&
        dLat != 0.0 &&
        dLng != 0.0) {
      dist = _haversineRoadKm(oLat, oLng, dLat, dLng);
    }

    if (dist > 0.0) {
      dist = (dist * 10).round() / 10.0;
    }

    final String rawDbId = json['id']?.toString() ?? '';
    final String orderNum = json['order_number']?.toString() ?? '';
    final String displayId = orderNum.isNotEmpty
        ? orderNum
        : (rawDbId.isNotEmpty ? rawDbId : 'SHP-${DateTime.now().millisecondsSinceEpoch}');
    final String actualDbId = rawDbId.isNotEmpty ? rawDbId : displayId;

    final String estDuration = route['estimated_duration']?.toString() ??
        json['estimated_duration']?.toString() ??
        json['estimated_time']?.toString() ??
        '';

    final String vehiclePlate = driverObj['vehicle_plate']?.toString() ??
        json['vehicle_plate']?.toString() ??
        json['truck_id']?.toString() ??
        '—';

    final String pDate = pickup['date']?.toString() ??
        json['pickup_date']?.toString().split('T').first ??
        '—';
    final String pTime = (pickup['time'] != null && pickup['time'].toString().isNotEmpty)
        ? pickup['time'].toString()
        : (json['estimated_time']?.toString() ?? '');
    final String dDate = delivery['date']?.toString() ??
        json['delivery_date']?.toString().split('T').first ??
        '—';
    final String dTime = delivery['time']?.toString() ?? '';
    final String createdDate = json['created_at']?.toString().split('T').first ?? '—';

    final String payoutEarningsStr = payout['formatted']?.toString() ??
        (payout['total_amount'] != null ? '€${payout['total_amount']}' : '—');

    final bool isRelay = json['is_relay'] == true ||
        (json['legs'] is List && (json['legs'] as List).length > 1) ||
        (json['relay_legs'] is List && (json['relay_legs'] as List).length > 1);
    final int rawLegNum = int.tryParse(json['driver_leg_number']?.toString() ?? '') ?? 0;
    final bool isDeliveryOnly = json['is_delivery_only'] == true ||
        json['is_delivery_only'] == 1 ||
        json['is_delivery_only'] == '1' ||
        json['is_delivery_only'] == 'true' ||
        rawLegNum == 2;
    final int driverLegNumber = rawLegNum > 0 ? rawLegNum : (isDeliveryOnly ? 2 : 1);
    final int currentActiveLeg =
        int.tryParse(json['current_active_leg']?.toString() ?? '') ?? 1;
    final String hubLocation = json['hub_location']?.toString() ?? '';
    final Map<String, dynamic>? partnerDriver = json['partner_driver'] is Map
        ? Map<String, dynamic>.from(json['partner_driver'] as Map)
        : null;
    final Map<String, dynamic>? handover = json['handover'] is Map
        ? Map<String, dynamic>.from(json['handover'] as Map)
        : null;

    final List<Map<String, dynamic>> relayLegs = [];
    final rawRelayLegs = json['relay_legs'] ?? json['legs'];
    if (rawRelayLegs is List) {
      for (final l in rawRelayLegs) {
        if (l is Map) {
          relayLegs.add(Map<String, dynamic>.from(l));
        }
      }
    }

    return ShipmentItem(
      id: displayId,
      dbId: actualDbId,
      truckId: vehiclePlate.isNotEmpty ? vehiclePlate : '—',
      originTitle: originTitle,
      originAddress: originAddr,
      originCompany: pickup['company']?.toString() ?? json['pickup_company']?.toString() ?? '—',
      pickupDate: pDate,
      pickupTime: pTime,
      destTitle: destTitle,
      destAddress: destAddr,
      destCompany: delivery['company']?.toString() ?? json['delivery_company']?.toString() ?? '—',
      deliveryDate: dDate,
      deliveryTime: dTime,
      distanceKm: dist,
      cargoType: cargo['service_type']?.toString() ?? cargo['pallet_type']?.toString() ?? 'Commercial Freight',
      payloadWeight: cargo['total_weight']?.toString() ?? '—',
      equipmentType: cargo['pallet_type']?.toString() ?? 'Pallets',
      palletQuantity: '${cargo['items_count'] ?? 1} Pallets',
      status: filterStatus,
      statusLabel: json['status_label']?.toString() ?? json['status']?.toString() ?? 'Assigned',
      rawStatus: statusStr,
      time: pTime.isNotEmpty ? pTime : '—',
      date: createdDate != '—' ? createdDate : pDate,
      signedBy: json['receiver_name']?.toString() ?? tracking['receiver_name']?.toString() ?? '',
      podDate: (json['pod_date'] ?? json['delivered_at'])?.toString() ?? '',
      originLat: oLat,
      originLng: oLng,
      destLat: dLat,
      destLng: dLng,
      pickupContactName: pickup['contact_name']?.toString() ?? '',
      pickupContactPhone: pickup['contact_phone']?.toString() ?? '',
      deliveryContactName: delivery['contact_name']?.toString() ?? '',
      deliveryContactPhone: delivery['contact_phone']?.toString() ?? '',
      vehicleType: driverObj['vehicle_type']?.toString() ?? json['vehicle_type']?.toString() ?? '—',
      serviceType: cargo['service_type']?.toString() ?? '—',
      payoutEarnings: payoutEarningsStr,
      specialInstructions: cargo['special_instructions']?.toString() ?? json['special_instructions']?.toString() ?? '',
      dimensions: cargo['dimensions']?.toString() ?? '',
      estimatedDuration: estDuration,
      customerId: int.tryParse((customerObj['id'] ?? json['customer_id'] ?? '').toString()),
      customerName: (customerObj['company_name'] ?? customerObj['name'] ?? '').toString(),
      customerAvatar: (customerObj['avatar'] ?? '').toString(),
      supplierId: int.tryParse((supplierObj['id'] ?? json['supplier_id'] ?? '').toString()),
      supplierName: (supplierObj['company_name'] ?? supplierObj['name'] ?? '').toString(),
      supplierAvatar: (supplierObj['logo'] ?? supplierObj['avatar'] ?? '').toString(),
      driverType: json['driver_type']?.toString() ?? driverObj['driver_type']?.toString() ?? 'internal',
      driverName: json['driver_name']?.toString() ?? driverObj['name']?.toString() ?? driverObj['driver_name']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? driverObj['phone']?.toString() ?? driverObj['driver_phone']?.toString() ?? '',
      subcontractorCompany: json['subcontractor_company']?.toString() ?? driverObj['subcontractor_company']?.toString() ?? '',
      subcontractorJourneyLeg: json['subcontractor_journey_leg']?.toString() ?? driverObj['subcontractor_journey_leg']?.toString() ?? '',
      isRelay: isRelay,
      isDeliveryOnly: isDeliveryOnly,
      driverLegNumber: driverLegNumber,
      currentActiveLeg: currentActiveLeg,
      hubLocation: hubLocation,
      partnerDriver: partnerDriver,
      handover: handover,
      relayLegs: relayLegs,
      rawMilestoneStatus: (json['raw_milestone_status'] ?? '').toString(),
      orderStatus: (json['order_status'] ?? '').toString(),
    );
  }

  ShipmentItem copyWith({
    String? id,
    String? dbId,
    String? truckId,
    String? originTitle,
    String? originAddress,
    String? originCompany,
    String? pickupDate,
    String? pickupTime,
    String? destTitle,
    String? destAddress,
    String? destCompany,
    String? deliveryDate,
    String? deliveryTime,
    double? distanceKm,
    String? cargoType,
    String? equipmentType,
    String? palletQuantity,
    String? temperature,
    String? cargoManifest,
    String? payloadWeight,
    String? hazmatStatus,
    ShipmentFilter? status,
    String? statusLabel,
    String? rawStatus,
    String? time,
    String? date,
    String? signedBy,
    String? podDate,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    String? pickupContactName,
    String? pickupContactPhone,
    String? deliveryContactName,
    String? deliveryContactPhone,
    String? vehicleType,
    String? serviceType,
    String? payoutEarnings,
    String? specialInstructions,
    String? dimensions,
    String? estimatedDuration,
    int? customerId,
    String? customerName,
    String? customerAvatar,
    int? supplierId,
    String? supplierName,
    String? supplierAvatar,
    String? driverType,
    String? driverName,
    String? driverPhone,
    String? subcontractorCompany,
    String? subcontractorJourneyLeg,
    bool? isRelay,
    bool? isDeliveryOnly,
    int? driverLegNumber,
    int? currentActiveLeg,
    String? hubLocation,
    Map<String, dynamic>? partnerDriver,
    Map<String, dynamic>? handover,
    List<Map<String, dynamic>>? relayLegs,
    String? rawMilestoneStatus,
    String? orderStatus,
  }) {
    return ShipmentItem(
      id: id ?? this.id,
      dbId: dbId ?? this.dbId,
      truckId: truckId ?? this.truckId,
      originTitle: originTitle ?? this.originTitle,
      originAddress: originAddress ?? this.originAddress,
      originCompany: originCompany ?? this.originCompany,
      pickupDate: pickupDate ?? this.pickupDate,
      pickupTime: pickupTime ?? this.pickupTime,
      destTitle: destTitle ?? this.destTitle,
      destAddress: destAddress ?? this.destAddress,
      destCompany: destCompany ?? this.destCompany,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      distanceKm: distanceKm ?? this.distanceKm,
      cargoType: cargoType ?? this.cargoType,
      equipmentType: equipmentType ?? this.equipmentType,
      palletQuantity: palletQuantity ?? this.palletQuantity,
      temperature: temperature ?? this.temperature,
      cargoManifest: cargoManifest ?? this.cargoManifest,
      payloadWeight: payloadWeight ?? this.payloadWeight,
      hazmatStatus: hazmatStatus ?? this.hazmatStatus,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      rawStatus: rawStatus ?? this.rawStatus,
      time: time ?? this.time,
      date: date ?? this.date,
      signedBy: signedBy ?? this.signedBy,
      podDate: podDate ?? this.podDate,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      pickupContactName: pickupContactName ?? this.pickupContactName,
      pickupContactPhone: pickupContactPhone ?? this.pickupContactPhone,
      deliveryContactName: deliveryContactName ?? this.deliveryContactName,
      deliveryContactPhone: deliveryContactPhone ?? this.deliveryContactPhone,
      vehicleType: vehicleType ?? this.vehicleType,
      serviceType: serviceType ?? this.serviceType,
      payoutEarnings: payoutEarnings ?? this.payoutEarnings,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      dimensions: dimensions ?? this.dimensions,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierAvatar: supplierAvatar ?? this.supplierAvatar,
      driverType: driverType ?? this.driverType,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      subcontractorCompany: subcontractorCompany ?? this.subcontractorCompany,
      subcontractorJourneyLeg:
          subcontractorJourneyLeg ?? this.subcontractorJourneyLeg,
      isRelay: isRelay ?? this.isRelay,
      isDeliveryOnly: isDeliveryOnly ?? this.isDeliveryOnly,
      driverLegNumber: driverLegNumber ?? this.driverLegNumber,
      currentActiveLeg: currentActiveLeg ?? this.currentActiveLeg,
      hubLocation: hubLocation ?? this.hubLocation,
      partnerDriver: partnerDriver ?? this.partnerDriver,
      handover: handover ?? this.handover,
      relayLegs: relayLegs ?? this.relayLegs,
      rawMilestoneStatus: rawMilestoneStatus ?? this.rawMilestoneStatus,
      orderStatus: orderStatus ?? this.orderStatus,
    );
  }
}
