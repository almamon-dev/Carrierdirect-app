import 'package:flutter/material.dart';
import '../../data/models/shipment_item_model.dart';
import 'route_overview_screen.dart';

class InAppNavigationScreen extends StatelessWidget {
  final ShipmentItem shipment;

  const InAppNavigationScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return RouteOverviewScreen(shipment: shipment);
  }
}
