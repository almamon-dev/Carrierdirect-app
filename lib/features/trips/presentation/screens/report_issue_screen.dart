import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/widgets/wave_processing_indicator.dart';

class ReportIssueScreen extends StatefulWidget {
  final String shipmentId;
  final String originTitle;
  final String destTitle;

  const ReportIssueScreen({
    super.key,
    required this.shipmentId,
    required this.originTitle,
    required this.destTitle,
  });

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final TextEditingController _notesController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _selectedPriority = 'High (Immediate)';
  bool _isDetentionClaim = true;
  bool _isSubmitting = false;
  File? _attachedPhoto;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = AppColors.border;
  static const Color textSub = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  // Real Logistics & Fleet Incident Categories
  final List<Map<String, dynamic>> _issueCategories = [
    {
      'id': 'DOCK_DETENTION',
      'title': 'Dock Detention (>2 Hours Delay)',
      'subtitle': 'Waiting for bay assignment, lumper crew, or forklift unloader',
      'icon': Icons.hourglass_top_rounded,
      'color': Color(0xFFD97706),
      'presets': ['Bay 4 Blocked by Inbound Rig', 'Lumpers Not Available', 'Forklift Breakdown at Dock', 'Stuck in Staging Yard > 2.5 hrs'],
    },
    {
      'id': 'CARGO_DAMAGE',
      'title': 'Cargo Damage & Pallet Seal Tamper',
      'subtitle': 'Crushed cartons, broken trailer bolt seal, shifting freight',
      'icon': Icons.inventory_2_outlined,
      'color': Color(0xFFEF4444),
      'presets': ['Pallet #3 Crushed in Corner', 'Trailer Bolt Seal #9921 Broken', 'Wet Goods Water Leakage', 'Temperature Sensor Alert (-12°C)'],
    },
    {
      'id': 'RIG_BREAKDOWN',
      'title': 'Rig Breakdown & Mechanical Issue',
      'subtitle': 'Flat tire, air brake pressure drop, reefer cooling malfunction',
      'icon': Icons.build_circle_outlined,
      'color': Color(0xFFDC2626),
      'presets': ['Steer Tire Puncture on I-95', 'Reefer Unit Error Code #04', 'Air Brake Pressure Leak', 'Engine Check Light & Loss of Power'],
    },
    {
      'id': 'ROUTE_ROADBLOCK',
      'title': 'Highway Detour & Severe Weather',
      'subtitle': 'Bridge height restriction, road closure, snow storm barrier',
      'icon': Icons.alt_route_rounded,
      'color': Color(0xFF0284C7),
      'presets': ['I-95 North Exit 14 Closed for Detour', 'Severe Blizzard Warning Route Bypass', 'Low Clearance Bridge (< 13ft 6in)'],
    },
    {
      'id': 'GATE_REFUSAL',
      'title': 'Facility Gate Refusal / Closed Door',
      'subtitle': 'Gate pass rejected, receiver missed appointment, dock shut',
      'icon': Icons.door_front_door_outlined,
      'color': Color(0xFF9333EA),
      'presets': ['Gate Security Refused Entry', 'Receiver Shift Ended Early', 'Consignee Manager Unreachable by Phone'],
    },
    {
      'id': 'BOL_DISCREPANCY',
      'title': 'BOL & Paperwork Discrepancy',
      'subtitle': 'Shipper signature missing, piece count mismatch, wrong PO#',
      'icon': Icons.description_outlined,
      'color': Color(0xFF059669),
      'presets': ['Shipper Refused to Sign BOL', 'Piece Count Mismatch (-4 Cases)', 'Missing Purchase Order #PO-8821 on Paperwork'],
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _attachedPhoto = File(picked.path);
        });
        AppToast.success(context, 'Incident photo attached', icon: Icons.camera_alt_rounded);
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not access device camera');
    }
  }

  void _addPresetText(String preset) {
    if (_notesController.text.isEmpty) {
      _notesController.text = preset;
    } else {
      _notesController.text += ' • $preset';
    }
    _notesController.selection = TextSelection.fromPosition(
      TextPosition(offset: _notesController.text.length),
    );
    setState(() {});
  }

  void _submitIssue() async {
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 1100));

    if (mounted) {
      setState(() => _isSubmitting = false);
      final selectedCat = _issueCategories[_selectedCategoryIndex];
      final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      Navigator.pop(context);
      AppToast.success(
        context,
        'Incident Ticket #$ticketId (${selectedCat['title']}) dispatched to Dispatch HQ!',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = _issueCategories[_selectedCategoryIndex];
    final presets = currentCat['presets'] as List<String>;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Logistics Incident',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: textMain),
            ),
            Text(
              'Load #${widget.shipmentId} • 24/7 Dispatch Desk',
              style: const TextStyle(fontSize: 11, color: textSub),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Rig & Active Shipment Context Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded, color: primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Freightliner Cascadia #TRK-104',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: const Text(
                            '53ft Reefer Unit',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: cardBorder, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked_rounded, color: Color(0xFFEA580C), size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.originTitle.isNotEmpty ? widget.originTitle : 'ABC Warehouse Logistics',
                            style: const TextStyle(fontSize: 11.5, color: textMain, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: textSub, size: 12),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 13),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.destTitle.isNotEmpty ? widget.destTitle : 'Starlight Supermarket Central',
                            style: const TextStyle(fontSize: 11.5, color: textMain, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Incident Category Title
              const Text(
                'Select Incident Category',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textMain),
              ),
              const SizedBox(height: 8),

              // Category Selector List
              ...List.generate(_issueCategories.length, (index) {
                final cat = _issueCategories[index];
                final isSelected = _selectedCategoryIndex == index;
                final color = cat['color'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? primaryColor : cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat['icon'] as IconData, color: color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? textMain : textMain.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 1.5),
                              Text(
                                cat['subtitle'] as String,
                                style: const TextStyle(fontSize: 10.5, color: textSub),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? primaryColor : textSub,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),

              // 3. Quick Tap Reason Presets (No typing needed while on road!)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Incident Presets (1-Tap)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
                  ),
                  const Text(
                    'Tap to add',
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets.map((preset) {
                  return InkWell(
                    onTap: () => _addPresetText(preset),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 12, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 3),
                          Text(
                            preset,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 4. Priority / Urgency Level
              const Text(
                'Incident Urgency Priority',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildPriorityChip('Low (Notice)', const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  _buildPriorityChip('Medium (Delay)', const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  _buildPriorityChip('High (Immediate)', const Color(0xFFEF4444)),
                ],
              ),

              const SizedBox(height: 14),

              // 5. Driver Description & Notes
              const Text(
                'Driver Incident Details & Notes',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13, color: textMain),
                  decoration: const InputDecoration(
                    hintText: 'Enter dock gate #, breakdown milestone, or incident explanation...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 6. Photo Proof / Attachment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attach Photo Proof (Damage / Gate / Rig)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
                  ),
                  if (_attachedPhoto != null)
                    GestureDetector(
                      onTap: () => setState(() => _attachedPhoto = null),
                      child: const Text('Remove', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_attachedPhoto != null)
                Container(
                  width: double.infinity,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                    image: DecorationImage(image: FileImage(_attachedPhoto!), fit: BoxFit.cover),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 15),
                        label: const Text('Take Photo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMain,
                          side: const BorderSide(color: cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 15),
                        label: const Text('Gallery', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMain,
                          side: const BorderSide(color: cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // 7. Detention Pay Reimbursement Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detention Billing Claim (>2 Hours)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textMain),
                          ),
                          Text(
                            'Auto-log arrival timestamp for customer detention compensation',
                            style: TextStyle(fontSize: 10.5, color: textSub),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isDetentionClaim,
                      activeThumbColor: primaryColor,
                      activeTrackColor: primaryColor.withValues(alpha: 0.35),
                      onChanged: (val) => setState(() => _isDetentionClaim = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 8. Submit Incident Report Button (with wave processing)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const WaveProcessingIndicator(
                          color: Colors.white,
                          barCount: 4,
                          maxHeight: 16,
                          minHeight: 5,
                          barWidth: 3.2,
                          barSpacing: 3.0,
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Submit Incident to Dispatch HQ',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
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

  Widget _buildPriorityChip(String label, Color color) {
    final isSelected = _selectedPriority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
