import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';

class DriverReportsScreen extends StatefulWidget {
  const DriverReportsScreen({super.key});

  @override
  State<DriverReportsScreen> createState() => _DriverReportsScreenState();
}

class _DriverReportsScreenState extends State<DriverReportsScreen> {
  int _selectedTimeframe = 0; // 0: Week, 1: Month, 2: Year
  int _selectedBarIndex = 3; // Selected Thursday by default

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  final List<Map<String, dynamic>> _weeklyMilesData = [
    {'day': 'Mon', 'miles': 240.0, 'loads': 2},
    {'day': 'Tue', 'miles': 380.0, 'loads': 3},
    {'day': 'Wed', 'miles': 190.0, 'loads': 1},
    {'day': 'Thu', 'miles': 450.0, 'loads': 3},
    {'day': 'Fri', 'miles': 310.0, 'loads': 2},
    {'day': 'Sat', 'miles': 120.0, 'loads': 1},
    {'day': 'Sun', 'miles': 0.0, 'loads': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final selectedDayData = _weeklyMilesData[_selectedBarIndex];
    final totalMiles = _weeklyMilesData.fold<double>(0.0, (acc, item) => acc + (item['miles'] as double));
    final totalLoads = _weeklyMilesData.fold<int>(0, (acc, item) => acc + (item['loads'] as int));

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 1,
        shadowColor: cardBorder,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Performance Reports',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: textMain),
            ),
            Text(
              'Fleet Analytics & Mileage Graphs',
              style: TextStyle(fontSize: 11, color: textSub),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: primaryColor, size: 20),
            onPressed: () {
              AppToast.success(context, 'Weekly PDF Report exported successfully', icon: Icons.download_done_rounded);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Timeframe Filter Selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildTimeframePill(0, 'This Week'),
                    _buildTimeframePill(1, 'This Month'),
                    _buildTimeframePill(2, 'Quarterly'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Summary KPI Metric Strip
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Distance',
                      value: '${totalMiles.toInt()} mi',
                      subtitle: '+14% vs last week',
                      icon: Icons.alt_route_rounded,
                      iconColor: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Loads Completed',
                      value: '$totalLoads Loads',
                      subtitle: '100% fulfilled',
                      icon: Icons.inventory_2_outlined,
                      iconColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'On-Time Rate',
                      value: '98.4%',
                      subtitle: 'Rank #1 in fleet',
                      icon: Icons.speed_rounded,
                      iconColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Weekly Mileage Bar Graph (Visual Chart)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mileage & Distance Driven',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textMain,
                              ),
                            ),
                            Text(
                              'Daily driven miles comparison',
                              style: TextStyle(fontSize: 11, color: textSub),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${selectedDayData['day']}: ${selectedDayData['miles'].toInt()} mi',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Custom Bar Graph Painter & Interactive Bars
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_weeklyMilesData.length, (index) {
                          final item = _weeklyMilesData[index];
                          final miles = item['miles'] as double;
                          final maxMiles = 450.0;
                          final normalizedHeight = (miles / maxMiles).clamp(0.05, 1.0);
                          final isSelected = _selectedBarIndex == index;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBarIndex = index;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    miles > 0 ? '${miles.toInt()}' : '-',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? primaryColor : textSub,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 18,
                                    height: 85 * normalizedHeight,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isSelected
                                            ? [primaryColor, const Color(0xFFFF8A00)]
                                            : [const Color(0xFFCBD5E1), const Color(0xFFE2E8F0)],
                                      ),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      border: isSelected
                                          ? Border.all(color: primaryColor.withValues(alpha: 0.8), width: 1.5)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['day'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? textMain : textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. On-Time Delivery Ring Graph & Breakdown
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Punctuality & Fulfillment',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Custom Circular Gauge
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(80, 80),
                                painter: _DonutGaugePainter(
                                  progress: 0.984,
                                  trackColor: const Color(0xFFE2E8F0),
                                  progressColor: const Color(0xFF10B981),
                                ),
                              ),
                              const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '98.4%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: textMain,
                                    ),
                                  ),
                                  Text(
                                    'Score',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Legend Breakdown
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LegendRow(color: Color(0xFF10B981), label: '38 On-Time Deliveries (98.4%)'),
                              SizedBox(height: 6),
                              _LegendRow(color: Color(0xFFF59E0B), label: '1 Traffic Detour Delay (1.6%)'),
                              SizedBox(height: 6),
                              _LegendRow(color: Color(0xFFEF4444), label: '0 Missed / Refused Appointments'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 5. Driver Safety & Compliance Score Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Safety & Rig Telematics',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Grade A+ (99/100)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSafetyProgressBar('Speed Limit Compliance', 0.99, '99.2% in green zone'),
                    const SizedBox(height: 8),
                    _buildSafetyProgressBar('Smooth Braking & Cornering', 0.96, '0 sudden deceleration events'),
                    const SizedBox(height: 8),
                    _buildSafetyProgressBar('Idle Fuel Efficiency', 0.94, '1.4% engine idle time'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 6. Export Full PDF Report Button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppToast.success(context, 'Carrier Direct Analytics PDF Report generated', icon: Icons.picture_as_pdf_rounded);
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text(
                    'Export Complete Monthly Driver Report',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textMain,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTimeframePill(int index, String label) {
    final isSelected = _selectedTimeframe == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimeframe = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? textMain : textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: textSub,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyProgressBar(String title, double progress, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textMain),
            ),
            Text(
              detail,
              style: const TextStyle(fontSize: 10, color: textSub),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DonutGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _DonutGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background circle track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc (-90 degrees to sweep)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
