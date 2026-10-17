import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../chat/data/models/chat_channel_model.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/widgets/chat_channels_modal.dart';
import '../widgets/in_app_google_map_view.dart';
import 'live_tracking_screen.dart';
import 'trips_screen.dart';

class ShipmentDetailsScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const ShipmentDetailsScreen({
    super.key,
    required this.shipment,
  });

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AnimationController? _shimmerController;
  Animation<double>? _shimmerAnimation;

  static const Color primaryOrange = Color(0xFFFF5722);
  static const Color successGreen = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorderColor = Color(0xFFE2E8F0);
  static const Color pageBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _initShimmer();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _initShimmer() {
    if (_shimmerController == null) {
      _shimmerController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
      _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOutSine),
      );
    }
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  Future<void> _simulateRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 750));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildShimmerBox({
    double? width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    _initShimmer();
    final anim = _shimmerAnimation;
    if (anim == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: borderRadius ?? BorderRadius.circular(6.0),
        ),
      );
    }
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final val = anim.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: borderRadius ?? BorderRadius.circular(6.0),
            gradient: LinearGradient(
              begin: Alignment(val - 1.0, 0),
              end: Alignment(val + 1.0, 0),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }

  Widget _buildSkeletonBody() {
    return ListView(
      key: const ValueKey('skeleton_loader'),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        // Skeleton Card 1: Route & Map
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    _buildShimmerBox(width: 10, height: 10, borderRadius: BorderRadius.circular(5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(width: 170, height: 14),
                          const SizedBox(height: 6),
                          _buildShimmerBox(width: 95, height: 10),
                        ],
                      ),
                    ),
                    _buildShimmerBox(width: 88, height: 26, borderRadius: BorderRadius.circular(6)),
                  ],
                ),
              ),

              // Best route active banner skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: _buildShimmerBox(width: double.infinity, height: 30, borderRadius: BorderRadius.circular(4)),
              ),

              // Google Map skeleton box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: _buildShimmerBox(width: double.infinity, height: 180, borderRadius: BorderRadius.circular(8)),
              ),

              // 4 Milestones Stepper skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    return Column(
                      children: [
                        _buildShimmerBox(width: 20, height: 20, borderRadius: BorderRadius.circular(10)),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 50, height: 10),
                        const SizedBox(height: 4),
                        _buildShimmerBox(width: 36, height: 8),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Skeleton Card 2: Current Status
        _buildSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 120, height: 14),
                  _buildShimmerBox(width: 80, height: 22, borderRadius: BorderRadius.circular(4)),
                ],
              ),
              const SizedBox(height: 12),
              _buildShimmerBox(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              _buildShimmerBox(width: 180, height: 12),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Skeleton Card 3: Pickup & Delivery Details
        _buildSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 140, height: 14),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 14, height: 14, borderRadius: BorderRadius.circular(7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 130, height: 12),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: double.infinity, height: 10),
                        const SizedBox(height: 4),
                        _buildShimmerBox(width: 100, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 14, height: 14, borderRadius: BorderRadius.circular(7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 130, height: 12),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: double.infinity, height: 10),
                        const SizedBox(height: 4),
                        _buildShimmerBox(width: 100, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Skeleton Card 4: Cargo & Equipment
        _buildSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 140, height: 14),
              const SizedBox(height: 14),
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 45, height: 10),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 65, height: 12),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Skeleton Card 5: Proof of Delivery (POD)
        _buildSkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerBox(width: 150, height: 14),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildShimmerBox(width: 54, height: 54, borderRadius: BorderRadius.circular(6)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 110, height: 12),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 160, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Stepper milestones
  final List<Map<String, String>> _stepperSteps = const [
    {'title': 'Assigned', 'time': 'Oct 17, 08:41'},
    {'title': 'Pickup', 'time': 'Oct 17, 09:45'},
    {'title': 'In Transit', 'time': 'Oct 17, 08:45'},
    {'title': 'Completed', 'time': 'Oct 17, 09:51'},
  ];

  // Route points: Dhaka Airport to Gazipur strictly adhering to Dhaka-Mymensingh Hwy (N3)
  final List<LatLng> _routePoints = const [
    LatLng(23.8510, 90.4070), // Dhaka Airport Cargo Terminal
    LatLng(23.8540, 90.4040), // Airport road connector
    LatLng(23.8585, 90.4018), // Kawla roundabout
    LatLng(23.8645, 90.3999), // Jasimuddin Avenue (Uttara Sec 1/3)
    LatLng(23.8717, 90.4004), // Rajlakshmi / Sector 3-4
    LatLng(23.8760, 90.4006), // Azampur / Sector 7
    LatLng(23.8805, 90.4009), // House Building / Sector 9
    LatLng(23.8870, 90.4010), // Sector 10 Crossing
    LatLng(23.8925, 90.4019), // Abdullahpur
    LatLng(23.8970, 90.3989), // Tongi Bridge (River Turag)
    LatLng(23.9030, 90.3990), // Tongi Bazar
    LatLng(23.9090, 90.3995), // Station Road Tongi
    LatLng(23.9160, 90.4015), // Mill Gate / Gazipura
    LatLng(23.9248, 90.4042), // Cherag Ali Market
    LatLng(23.9325, 90.4078), // College Gate, Tongi
    LatLng(23.9405, 90.4110), // Hossain Market
    LatLng(23.9550, 90.4180), // Board Bazar (IUT)
    LatLng(23.9680, 90.4215), // Bangladesh Open University
    LatLng(23.9820, 90.4240), // Taragach, Gazipur
    LatLng(23.9910, 90.4250), // Chandana Chowrasta South Approach
    LatLng(23.9980, 90.4260), // Chandana Chowrasta, Gazipur
  ];

  void _copyLoadId() {
    Clipboard.setData(ClipboardData(text: widget.shipment.id));
    AppToast.success(context, 'Load ID copied: ${widget.shipment.id}', icon: Icons.content_copy_rounded);
  }

  Future<void> _openExternalGoogleMaps() async {
    final origin = '${widget.shipment.originLat},${widget.shipment.originLng}';
    final destination = '${widget.shipment.destLat},${widget.shipment.destLng}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) AppToast.info(context, 'Opening map location...');
      }
    } catch (_) {
      if (mounted) AppToast.info(context, 'Could not open map app.');
    }
  }

  void _viewPodPhoto() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: successGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Proof of Delivery (POD)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkSlate),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Real Interactive Photo Preview (Pinch to Zoom enabled)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFF0F172A),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo with Zoom & Pan
                      InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 3.5,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=800&q=80',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: CircularProgressIndicator(color: primaryOrange, strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF1E293B),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Delivery Cargo & BOL Photo',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Signed by: ${widget.shipment.signedBy}',
                                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Overlay: Zoom Hint
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pinch_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Pinch to Zoom',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Overlay: Verified Seal
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: successGreen.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED POD',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Geostamp bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: primaryOrange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${widget.shipment.destTitle} • ${widget.shipment.podDate}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10.5),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Metadata card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Receiver Signer:', style: TextStyle(color: textMuted, fontSize: 11.5)),
                        Text(widget.shipment.signedBy, style: const TextStyle(color: darkSlate, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Timestamp:', style: TextStyle(color: textMuted, fontSize: 11.5)),
                        Text(widget.shipment.podDate, style: const TextStyle(color: darkSlate, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CarrierDirect ID:', style: TextStyle(color: textMuted, fontSize: 11.5)),
                        Text('#${widget.shipment.id}', style: const TextStyle(color: primaryOrange, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkSlate,
                        side: const BorderSide(color: cardBorderColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: () {
                        AppToast.success(context, 'POD Photo & BOL document downloaded successfully!');
                      },
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar (Back Arrow, ORD-NIBE-10001, TRK-10001, Completed Badge, 3-dots)
            _buildTopAppBar(),

            // 2. Secondary Sub-Nav (Live Tracking, Copy Load ID, Chat)
            _buildSubNavBar(),

            // 3. Scrollable Cards Body (Animated with Shimmer Skeleton)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? _buildSkeletonBody()
                    : RefreshIndicator(
                        onRefresh: _simulateRefresh,
                        color: primaryOrange,
                        child: ListView(
                          key: const ValueKey('loaded_cards_body'),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                          children: [
                            // Card 1: Route Header, Google Map, and 4-Stage Horizontal Stepper
                            _buildRouteAndMapCard(),
                            const SizedBox(height: 12),

                            // Card 2: Current Status
                            _buildCurrentStatusCard(),
                            const SizedBox(height: 12),

                            // Card 3: Pickup & Delivery Details
                            _buildPickupDeliveryCard(),
                            const SizedBox(height: 12),

                            // Card 4: Cargo & Equipment (4 Columns)
                            _buildCargoEquipmentCard(),
                            const SizedBox(height: 12),

                            // Card 5: Proof of Delivery (POD)
                            _buildProofOfDeliveryCard(),
                            const SizedBox(height: 12),

                            // Card 6: Recent Activity Log
                            _buildRecentActivityCard(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
              ),
            ),

            // 4. Fixed Bottom Action Buttons Bar (Live Tracking & Completed)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Top App Bar
  // ---------------------------------------------------------------------------
  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: cardBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: Icon(Icons.arrow_back, color: darkSlate, size: 22),
            ),
          ),

          // Clean Screen Title
          const Expanded(
            child: Text(
              'Shipment Details',
              style: TextStyle(
                color: darkSlate,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 12, color: successGreen),
                const SizedBox(width: 3),
                Text(
                  widget.shipment.statusLabel,
                  style: const TextStyle(color: successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 3-dots Menu
          GestureDetector(
            onTap: () {
              AppToast.info(context, 'Load Options: #${widget.shipment.id}');
            },
            child: const Icon(Icons.more_vert_rounded, color: darkSlate, size: 22),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Secondary Sub-Nav Bar (Live Tracking, Copy Load ID, Chat)
  // ---------------------------------------------------------------------------
  Widget _buildSubNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: cardBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          // 1. GPS Navigation
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LiveTrackingScreen(shipment: widget.shipment)),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation_rounded, size: 15, color: primaryOrange),
                    SizedBox(width: 6),
                    Text(
                      'GPS Navigation',
                      style: TextStyle(color: primaryOrange, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 20, color: cardBorderColor),

          // 2. Load ID with Copy
          Expanded(
            child: InkWell(
              onTap: _copyLoadId,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.content_copy_outlined, size: 13, color: textMuted),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.shipment.id,
                        style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 20, color: cardBorderColor),

          // 3. Chat
          Expanded(
            child: InkWell(
              onTap: () => ChatChannelsModal.show(context, shipment: widget.shipment),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 14, color: textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Chat',
                      style: TextStyle(color: textMuted, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 1: Route Header, Google Map, and 4-Stage Stepper
  // ---------------------------------------------------------------------------
  Widget _buildRouteAndMapCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside Map Card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.shipment.originTitle} ➔ ${widget.shipment.destTitle}',
                              style: const TextStyle(
                                color: darkSlate,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${widget.shipment.truckId} • ${widget.shipment.distanceKm} km • ${widget.shipment.distanceKm > 100 ? '~3h 00m' : '~40m'}',
                              style: const TextStyle(color: textMuted, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Open in Maps Button (with maps icon)
                GestureDetector(
                  onTap: _openExternalGoogleMaps,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'Open in Maps',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Best Route Recommended Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              border: Border(
                top: BorderSide(color: Color(0xFFDCFCE7)),
                bottom: BorderSide(color: Color(0xFFDCFCE7)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Best Route Active: Via Dhaka-Mymensingh Hwy N3 (Saves 18m • Fastest Corridor)',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FASTEST',
                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Google Map Container
          SizedBox(
            height: 180,
            width: double.infinity,
            child: InAppGoogleMapView(
              origin: LatLng(widget.shipment.originLat, widget.shipment.originLng),
              destination: LatLng(widget.shipment.destLat, widget.shipment.destLng),
              originTitle: widget.shipment.originTitle,
              destinationTitle: widget.shipment.destTitle,
              customRoutePoints: _routePoints,
              customZoom: 11.5,
              isInteractive: true,
            ),
          ),

          // Stepper: 4 Milestones
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              children: [
                Row(
                  children: List.generate(_stepperSteps.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      // Connecting green bar
                      return Expanded(
                        child: Container(
                          height: 2.5,
                          color: const Color(0xFF10B981),
                        ),
                      );
                    } else {
                      // Circle with checkmark
                      return Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                        child: const Center(
                          child: Icon(Icons.check, size: 13, color: Colors.white),
                        ),
                      );
                    }
                  }),
                ),
                const SizedBox(height: 8),

                // Titles & Dates
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _stepperSteps.map((step) {
                    return Expanded(
                      child: Column(
                        children: [
                          Text(
                            step['title']!,
                            style: const TextStyle(
                              color: darkSlate,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            step['time']!,
                            style: const TextStyle(
                              color: textMuted,
                              fontSize: 9.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 2: Current Status
  // ---------------------------------------------------------------------------
  Widget _buildCurrentStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Checkmark + Current Status + Completed badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: successGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Current Status',
                    style: TextStyle(color: darkSlate, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 11, color: successGreen),
                    const SizedBox(width: 3),
                    Text(
                      widget.shipment.statusLabel,
                      style: const TextStyle(color: successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content: Orange Truck Icon + Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: primaryOrange, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipment Approved & Completed',
                      style: TextStyle(color: darkSlate, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Customer has approved the Proof of Delivery (POD). Settlement finalized.',
                      style: TextStyle(color: textMuted, fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 3: Pickup & Delivery Details (Key-Value layout with chat & date badges)
  // ---------------------------------------------------------------------------
  Widget _buildPickupDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: primaryOrange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pickup & Delivery Details',
                    style: TextStyle(color: darkSlate, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Location Intel',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          // Facility 1: Pickup Shipper Facility
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF0284C7), size: 8),
                  SizedBox(width: 6),
                  Text(
                    'Pickup Shipper Facility',
                    style: TextStyle(color: Color(0xFF0284C7), fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '📅 ${widget.shipment.pickupDate}',
                style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow('Company', widget.shipment.originCompany),
          const SizedBox(height: 4),
          _buildKeyValueRow('Address', widget.shipment.originAddress),
          const SizedBox(height: 4),
          _buildKeyValueRow('Pickup Time', widget.shipment.pickupTime),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ChatScreen.openForShipment(
                  context,
                  shipment: widget.shipment,
                  initialChannelType: ChatChannelType.supplierWarehouse,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF0284C7)),
                    SizedBox(width: 5),
                    Text('Chat Shipper', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          // Facility 2: Delivery Consignee (Final)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, color: primaryOrange, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'Delivery Consignee (Final)',
                    style: TextStyle(color: primaryOrange, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '📅 ${widget.shipment.deliveryDate}',
                style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow('Company', widget.shipment.destCompany),
          const SizedBox(height: 4),
          _buildKeyValueRow('Address', widget.shipment.destAddress),
          const SizedBox(height: 4),
          _buildKeyValueRow('Delivery Time', widget.shipment.deliveryTime, isHighlight: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ChatScreen.openForShipment(
                  context,
                  shipment: widget.shipment,
                  initialChannelType: ChatChannelType.customerConsignee,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 12, color: primaryOrange),
                    SizedBox(width: 5),
                    Text('Chat Consignee', style: TextStyle(fontSize: 11, color: primaryOrange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 4: Cargo Manifest & Equipment Specs (Key-Value table like previous design)
  // ---------------------------------------------------------------------------
  Widget _buildCargoEquipmentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: primaryOrange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cargo Manifest & Equipment Specs',
                        style: TextStyle(color: darkSlate, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Standard Dry Freight',
                  style: TextStyle(color: successGreen, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          _buildKeyValueRow('Equipment Type', widget.shipment.equipmentType),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Pallet Quantity', widget.shipment.palletQuantity),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Temperature', widget.shipment.temperature),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Cargo Manifest', widget.shipment.cargoManifest),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Payload Weight', widget.shipment.payloadWeight, isBoldValue: true),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Route Distance', '${widget.shipment.distanceKm} km (03:00 PM - 03:00 PM)'),
          const Divider(color: cardBorderColor, height: 16),
          _buildKeyValueRow('Hazmat Status', widget.shipment.hazmatStatus),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card 5: Proof of Delivery (POD) Sign-Off & Driver Compliance
  // ---------------------------------------------------------------------------
  Widget _buildProofOfDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, color: primaryOrange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Proof of Delivery (POD) Sign-Off',
                    style: TextStyle(color: darkSlate, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 11, color: successGreen),
                    SizedBox(width: 3),
                    Text(
                      'Verified',
                      style: TextStyle(color: successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          _buildKeyValueRow('Signed By', widget.shipment.signedBy, isBoldValue: true),
          const SizedBox(height: 6),
          _buildKeyValueRow('Time & Date', widget.shipment.podDate),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          // Signed Paper BOL / Cargo Photo Item (Fully Clickable Card)
          Material(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              onTap: _viewPodPhoto,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: const Icon(Icons.photo_library_outlined, color: primaryOrange, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed Paper BOL / Cargo Photo',
                            style: TextStyle(color: darkSlate, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Tap to view verified delivery proof',
                            style: TextStyle(color: textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 13, color: primaryOrange),
                          SizedBox(width: 4),
                          Text(
                            'View Photo',
                            style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 10),

          // Driver Compliance row
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: successGreen, size: 15),
              SizedBox(width: 6),
              Text(
                'Driver Compliance:',
                style: TextStyle(color: textMuted, fontSize: 11.5),
              ),
              SizedBox(width: 5),
              Text(
                'Verified Active',
                style: TextStyle(color: successGreen, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper: Key-Value Row with aligned colon (:)
  // ---------------------------------------------------------------------------
  Widget _buildKeyValueRow(String label, String value, {bool isHighlight = false, bool isBoldValue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: textMuted, fontSize: 11.5),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isHighlight ? successGreen : darkSlate,
              fontSize: 11.5,
              fontWeight: isHighlight || isBoldValue ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card 6: Recent Activity Log
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivityCard() {
    final List<Map<String, String>> activities = const [
      {'title': 'Order Confirmed', 'time': 'Oct 17, 2026, 08:34 AM'},
      {'title': 'Driver Assigned', 'time': 'Oct 17, 2026, 08:41 AM'},
      {'title': 'Goods Picked Up', 'time': 'Oct 17, 2026, 09:45 AM'},
      {'title': 'In Transit', 'time': 'Oct 17, 2026, 08:45 AM'},
      {'title': 'Delivery Approved & Completed', 'time': 'Oct 17, 2026, 09:51 AM'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, color: primaryOrange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: TextStyle(color: darkSlate, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'All Complete',
                style: TextStyle(color: primaryOrange, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: cardBorderColor, height: 1),
          const SizedBox(height: 12),

          // Events
          ...activities.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == activities.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF10B981),
                      ),
                      child: const Center(
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 22,
                        color: const Color(0xFFA7F3D0),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(color: darkSlate, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item['time']!,
                          style: const TextStyle(color: textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Fixed Bottom Action Buttons Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildShimmerBox(height: 46, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildShimmerBox(height: 46, borderRadius: BorderRadius.circular(8)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: cardBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          // GPS Navigation (Outlined orange)
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LiveTrackingScreen(shipment: widget.shipment)),
                  );
                },
                icon: const Icon(Icons.navigation_rounded, size: 16, color: primaryOrange),
                label: const Text(
                  'GPS Navigation',
                  style: TextStyle(color: primaryOrange, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryOrange, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Completed (Solid green)
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppToast.success(context, 'Shipment #${widget.shipment.id} is finalized & completed.');
                },
                icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Completed',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
