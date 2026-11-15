import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';

class UploadedFileInfo {
  final String name;
  final String? path;
  final int? sizeBytes;
  final bool isImage;

  const UploadedFileInfo({
    required this.name,
    this.path,
    this.sizeBytes,
    this.isImage = true,
  });
}

enum UploadSource { camera, gallery, pdfFile }

class FileUploadHelper {
  static const Color primaryColor = AppColors.primary;
  static const Color inputBg = AppColors.surface;
  static const Color inputBorder = AppColors.border;
  static const Color textMain = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;

  static Future<UploadedFileInfo?> pickFileOrPhoto(
    BuildContext context, {
    String title = 'Upload Document / Photo',
  }) async {
    final UploadSource? selectedSource =
        await showModalBottomSheet<UploadSource?>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCED0D4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Option 1: Camera
                      _buildSourceOption(
                        icon: Icons.camera_alt_rounded,
                        iconColor: const Color(0xFF0284C7),
                        title: 'Take Photo with Camera',
                        subtitle: 'Capture clear picture using device camera',
                        onTap: () => Navigator.pop(ctx, UploadSource.camera),
                      ),
                      const Divider(color: inputBorder, height: 1, indent: 64),

                      // Option 2: Gallery
                      _buildSourceOption(
                        icon: Icons.photo_library_rounded,
                        iconColor: const Color(0xFF059669),
                        title: 'Choose from Photo Gallery',
                        subtitle: 'Select existing photo from gallery',
                        onTap: () => Navigator.pop(ctx, UploadSource.gallery),
                      ),
                      const Divider(color: inputBorder, height: 1, indent: 64),

                      // Option 3: PDF / Files
                      _buildSourceOption(
                        icon: Icons.description_rounded,
                        iconColor: primaryColor,
                        title: 'Browse PDF & Document Files',
                        subtitle: 'Upload PDF compliance certificate or scan',
                        onTap: () => Navigator.pop(ctx, UploadSource.pdfFile),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );

    if (selectedSource == null) return null;

    try {
      if (selectedSource == UploadSource.camera) {
        final picker = ImagePicker();
        final photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo != null) {
          return UploadedFileInfo(
            name: photo.name,
            path: photo.path,
            isImage: true,
          );
        }
      } else if (selectedSource == UploadSource.gallery) {
        final picker = ImagePicker();
        final photo = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (photo != null) {
          return UploadedFileInfo(
            name: photo.name,
            path: photo.path,
            isImage: true,
          );
        }
      } else if (selectedSource == UploadSource.pdfFile) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          return UploadedFileInfo(
            name: file.name,
            path: file.path,
            sizeBytes: file.size,
            isImage: file.extension?.toLowerCase() != 'pdf',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  static Widget _buildSourceOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Color(0xFF8A8D91),
            ),
          ],
        ),
      ),
    );
  }
}
