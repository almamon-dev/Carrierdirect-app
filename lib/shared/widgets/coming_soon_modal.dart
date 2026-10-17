import 'package:flutter/material.dart';
import '../utils/app_toast.dart';

class ComingSoonModal extends StatefulWidget {
  final String featureName;
  final String description;
  final IconData icon;

  const ComingSoonModal({
    super.key,
    required this.featureName,
    this.description = 'Our engineering team is actively building and testing this feature. It will be available in the upcoming release.',
    this.icon = Icons.rocket_launch_rounded,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureName,
    String? description,
    IconData icon = Icons.rocket_launch_rounded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ComingSoonModal(
        featureName: featureName,
        description: description ?? 'Our engineering team is actively building and testing this feature. It will be available in the upcoming release.',
        icon: icon,
      ),
    );
  }

  @override
  State<ComingSoonModal> createState() => _ComingSoonModalState();
}

class _ComingSoonModalState extends State<ComingSoonModal> {
  bool _notifyMe = true;

  static const Color primaryColor = Color(0xFFFF5722);
  static const Color inputBg = Color(0xFFF0F2F5);
  static const Color inputBorder = Color(0xFFE4E6EB);
  static const Color textMuted = Color(0xFF65676B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCED0D4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Animated Glowing Rocket / Feature Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Icon(widget.icon, size: 36, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 13),
                    SizedBox(width: 5),
                    Text(
                      'COMING SOON',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Feature Name
              Text(
                widget.featureName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF050505),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),

              // Notify Me Toggle Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: inputBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: primaryColor, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notify Me on Launch',
                            style: TextStyle(color: Color(0xFF050505), fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Get an alert when feature is live',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notifyMe,
                      activeThumbColor: primaryColor,
                      onChanged: (val) => setState(() => _notifyMe = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dismiss Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_notifyMe) {
                      AppToast.info(context, "We'll notify you as soon as ${widget.featureName} is ready!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Got It', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
