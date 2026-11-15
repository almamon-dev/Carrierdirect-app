import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/file_upload_helper.dart';

class LoadDeliveredModal extends StatefulWidget {
  final Function({
    required String receiverName,
    required String signatureData,
    String? pdfPath,
    String? pdfName,
    String? notes,
  }) onPodSubmitted;

  const LoadDeliveredModal({super.key, required this.onPodSubmitted});

  static void show(
    BuildContext context, {
    required Function(String filePath, String fileName) onPodUploaded,
    Function({
      required String receiverName,
      required String signatureData,
      String? pdfPath,
      String? pdfName,
      String? notes,
    })? onPodFullSubmitted,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return LoadDeliveredModal(
          onPodSubmitted: ({
            required String receiverName,
            required String signatureData,
            String? pdfPath,
            String? pdfName,
            String? notes,
          }) {
            if (onPodFullSubmitted != null) {
              onPodFullSubmitted(
                receiverName: receiverName,
                signatureData: signatureData,
                pdfPath: pdfPath,
                pdfName: pdfName,
                notes: notes,
              );
            }
            onPodUploaded(pdfPath ?? 'signature_only', pdfName ?? 'Signed_POD.pdf');
          },
        );
      },
    );
  }

  @override
  State<LoadDeliveredModal> createState() => _LoadDeliveredModalState();
}

class _LoadDeliveredModalState extends State<LoadDeliveredModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<Offset?> _signaturePoints = [];
  UploadedFileInfo? _attachedPdf;
  bool _signatureError = false;
  bool _isSubmitting = false;

  static const Color primaryOrange = AppColors.primary;
  static const Color darkSlate = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;

  bool get _hasSignature => _signaturePoints.where((p) => p != null).length > 6;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    setState(() {
      _signaturePoints.clear();
      _signatureError = false;
    });
  }

  Future<void> _pickOptionalPdf() async {
    final file = await FileUploadHelper.pickFileOrPhoto(
      context,
      title: 'Attach Signed PDF / BOL / Gate Pass (Optional)',
    );
    if (file != null && mounted) {
      setState(() {
        _attachedPdf = file;
      });
      AppToast.success(context, 'Attached: ${file.name}');
    }
  }

  Future<String?> _renderSignaturePngBase64() async {
    if (_signaturePoints.isEmpty) return null;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 180));

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 180), bgPaint);

      final strokePaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5
        ..isAntiAlias = true;

      for (int i = 0; i < _signaturePoints.length - 1; i++) {
        if (_signaturePoints[i] != null && _signaturePoints[i + 1] != null) {
          canvas.drawLine(
            _signaturePoints[i]!,
            _signaturePoints[i + 1]!,
            strokePaint,
          );
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 180);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  void _handleSubmit() async {
    final isNameValid = _formKey.currentState?.validate() ?? false;
    final hasSig = _hasSignature;

    if (!hasSig) {
      setState(() {
        _signatureError = true;
      });
    }

    if (!isNameValid || !hasSig) {
      if (!isNameValid) {
        AppToast.error(context, 'Please enter the receiver name');
      } else if (!hasSig) {
        AppToast.error(context, 'Receiver signature is required');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final sigBase64 = await _renderSignaturePngBase64();
    final signatureData = sigBase64 ??
        'Signature captured (${_signaturePoints.length} points)';

    if (mounted) {
      Navigator.pop(context);
    }

    widget.onPodSubmitted(
      receiverName: _nameController.text.trim(),
      signatureData: signatureData,
      pdfPath: _attachedPdf?.path,
      pdfName: _attachedPdf?.name,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      AppToast.success(
        context,
        'POD verified & submitted successfully',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proof of Delivery (POD)',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: darkSlate,
                        letterSpacing: -0.2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Capture receiver details & signature to complete delivery.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. RECEIVER NAME
                Row(
                  children: [
                    Text(
                      'Receiver Name',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: darkSlate,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(fontSize: 13, color: darkSlate),
                  decoration: InputDecoration(
                    hintText: 'e.g. John Doe (Supervisor)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: primaryOrange,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Receiver name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 2. SIGNATURE PAD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Receiver Signature',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_hasSignature)
                      GestureDetector(
                        onTap: _clearSignature,
                        child: Text(
                          'Clear',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 115,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _signatureError
                          ? Colors.red
                          : (_hasSignature
                              ? const Color(0xFF10B981)
                              : cardBorder),
                      width: _signatureError || _hasSignature ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Baseline line
                      Positioned(
                        bottom: 22,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),

                      // Drawing canvas
                      GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _signatureError = false;
                            _signaturePoints.add(details.localPosition);
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _signaturePoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _signaturePoints.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: _PodSignaturePainter(_signaturePoints),
                          size: Size.infinite,
                        ),
                      ),

                      // Placeholder hint
                      if (!_hasSignature)
                        IgnorePointer(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sign with finger here',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_signatureError) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Receiver signature is required',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 3. ATTACH DOCUMENT
                Text(
                  'Attach Document (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickOptionalPdf,
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _attachedPdf != null
                            ? const Color(0xFF10B981)
                            : cardBorder,
                        width: _attachedPdf != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _attachedPdf != null
                              ? Icons.picture_as_pdf_rounded
                              : Icons.attach_file_rounded,
                          size: 18,
                          color: _attachedPdf != null
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _attachedPdf != null
                                ? _attachedPdf!.name
                                : 'Upload signed BOL, Gate Pass or photo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _attachedPdf != null
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF94A3B8),
                              fontWeight: _attachedPdf != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_attachedPdf != null)
                          GestureDetector(
                            onTap: () {
                              setState(() => _attachedPdf = null);
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: textMuted,
                            ),
                          )
                        else
                          const Icon(
                            Icons.upload_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 4. NOTES
                Text(
                  'Notes (Optional)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 12.5, color: darkSlate),
                  decoration: InputDecoration(
                    hintText: 'Add any delivery remarks...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(
                        color: primaryOrange,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 18),

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkSlate,
                            side: const BorderSide(color: cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Confirm & Submit POD',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PodSignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _PodSignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PodSignaturePainter oldDelegate) => true;
}
