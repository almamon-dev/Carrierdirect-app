import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';

class BolPaperworkScreen extends StatelessWidget {
  final String shipmentId;
  final String originTitle;
  final String destTitle;

  const BolPaperworkScreen({
    super.key,
    required this.shipmentId,
    required this.originTitle,
    required this.destTitle,
  });

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        shadowColor: cardBorder,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: textMain,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Bill of Lading (BOL)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
            Text(
              'Official Electronic Freight Manifest',
              style: TextStyle(fontSize: 11, color: textSub),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: textMain, size: 20),
            onPressed: () =>
                AppToast.success(context, 'BOL Link copied to clipboard'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BOL Document Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILL OF LADING',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textMain,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'DOC #: BOL-88902-US',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFF059669),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Signed & Valid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: cardBorder, height: 24),
                    _buildRow('Load Reference ID:', shipmentId),
                    _buildRow('Carrier Name:', 'Apex Transport Logistics Inc.'),
                    _buildRow(
                      'Driver / CDL-A:',
                      'Mike Icorse (CDL #FL-889421)',
                    ),
                    _buildRow(
                      'Trailer / Tractor:',
                      'Semi-Truck #TR-402 (Reefer 53ft)',
                    ),
                    _buildRow('Security Seal #:', 'SEAL-88902-VERIFIED'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Route & Stops Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Origin & Destination Route',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warehouse_rounded,
                            size: 16,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Shipper (Pickup)',
                                style: TextStyle(fontSize: 11, color: textSub),
                              ),
                              Text(
                                originTitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textMain,
                                ),
                              ),
                              const Text(
                                'Bay 4, Port Logistics Park • Loaded 09:05 AM',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14, top: 4, bottom: 4),
                      child: SizedBox(
                        height: 14,
                        child: VerticalDivider(
                          color: cardBorder,
                          thickness: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 16,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consignee (Delivery)',
                                style: TextStyle(fontSize: 11, color: textSub),
                              ),
                              Text(
                                destTitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textMain,
                                ),
                              ),
                              const Text(
                                'Dock 12, 742 Evergreen Terrace • ETA 04:30 PM',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Cargo Manifest Table Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cargo & Item Manifest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildManifestRow(
                      'Item Description',
                      'Qty',
                      'Weight',
                      isHeader: true,
                    ),
                    const Divider(color: cardBorder, height: 12),
                    _buildManifestRow(
                      'Refrigerated Dairy & Milk Crates',
                      '14 Pallets',
                      '12,400 lbs',
                    ),
                    _buildManifestRow(
                      'Frozen Bakery Products',
                      '6 Pallets',
                      '6,000 lbs',
                    ),
                    const Divider(color: cardBorder, height: 12),
                    _buildRow('Total Cargo Weight:', '18,400 lbs (9.2 Tons)'),
                    _buildRow('Reefer Temperature:', '-18°C Controlled'),
                    _buildRow('Hazmat Status:', 'Non-Hazardous Goods (Clean)'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Digital Signatures Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Electronic Signatures & Stamps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shipper Agent:',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: textSub,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'David Miller',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                ),
                                Text(
                                  '✓ Signed 09:05 AM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cardBorder),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver Signature:',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: textSub,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mike Icorse',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: textMain,
                                  ),
                                ),
                                Text(
                                  '✓ Verified Digital POD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Download Official PDF Button (Compact)
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppToast.success(
                      context,
                      'BOL Document PDF downloaded to device',
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Download Official BOL (PDF)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: textSub)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestRow(
    String desc,
    String qty,
    String weight, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      fontSize: isHeader ? 11.5 : 12.5,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? textSub : textMain,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(desc, style: style)),
          Expanded(
            flex: 2,
            child: Text(qty, style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(weight, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
