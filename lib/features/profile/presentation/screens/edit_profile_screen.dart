import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/file_upload_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController = TextEditingController(text: 'Driver Captain');
  late final TextEditingController _phoneController = TextEditingController(text: '5552348901');
  late final TextEditingController _emailController = TextEditingController(text: 'amon193p@gmail.com');
  late final TextEditingController _addressController = TextEditingController(text: '742 Evergreen Terrace, Dallas, TX 75201');
  late final TextEditingController _cdlController = TextEditingController(text: 'TX-CDL-89420-A');
  late final TextEditingController _dotMedController = TextEditingController(text: 'DOT-MED-993841');
  late final TextEditingController _insuranceController = TextEditingController(text: 'INS-POL-49201');
  late final TextEditingController _emergencyController = TextEditingController(text: 'Sarah Jenkins • +1 555-019-3344');

  String _selectedCountryFlag = '🇺🇸';
  String _selectedCountryCode = '+1';

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;
  static const Color inputBg = Colors.white;
  static const Color inputBorder = AppColors.border;
  static const Color textLabel = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cdlController.dispose();
    _dotMedController.dispose();
    _insuranceController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      AppToast.success(context, 'Profile and driver credentials updated successfully!');
      Navigator.of(context).pop();
    }
  }

  // Official Country Picker Bottom Sheet Modal
  void _openCountryPickerModal(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.80,
        backgroundColor: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        textStyle: const TextStyle(color: textMain, fontSize: 14),
        searchTextStyle: const TextStyle(color: textMain, fontSize: 14),
        inputDecoration: InputDecoration(
          hintText: 'Search country name or code...',
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: textMuted, size: 20),
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountryFlag = country.flagEmoji;
          _selectedCountryCode = '+${country.phoneCode}';
        });
      },
    );
  }

  // Document Viewer Preview Modal
  void _openDocumentPreviewModal({
    required String title,
    required String docNumber,
    required String expiry,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                    child: Row(
                      children: [
                        Icon(icon, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: inputBorder, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title.toUpperCase(),
                                    style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const Row(
                                    children: [
                                      Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                                      SizedBox(width: 4),
                                      Text(
                                        'VERIFIED',
                                        style: TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: inputBorder, height: 1),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('HOLDER', style: TextStyle(color: textMuted, fontSize: 10.5)),
                                      SizedBox(height: 2),
                                      Text('Driver Captain', style: TextStyle(color: textMain, fontSize: 13.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('NUMBER', style: TextStyle(color: textMuted, fontSize: 10.5)),
                                      SizedBox(height: 2),
                                      Text(docNumber, style: const TextStyle(color: textMain, fontSize: 13.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ISSUING AUTH', style: TextStyle(color: textMuted, fontSize: 10.5)),
                                      SizedBox(height: 2),
                                      Text('Texas DOT / FMCSA', style: TextStyle(color: textMain, fontSize: 12.5)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('EXPIRES', style: TextStyle(color: textMuted, fontSize: 10.5)),
                                      SizedBox(height: 2),
                                      Text(expiry, style: const TextStyle(color: Color(0xFF059669), fontSize: 12.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);
                              final file = await FileUploadHelper.pickFileOrPhoto(
                                context,
                                title: 'Upload / Replace $title',
                              );
                              if (file != null) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Document updated: ${file.name}')),
                                );
                              }
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 16, color: primaryColor),
                            label: const Text(
                              'Upload / Replace Document',
                              style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: primaryColor, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 14.0),
                          child: Icon(Icons.arrow_back, size: 22, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6.0),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar Editor with Camera Button and Verified Driver Header
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withValues(alpha: 0.12),
                                    border: Border.all(color: primaryColor, width: 2.5),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(43),
                                    child: Image.asset(
                                      'assets/images/driver_avatar.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.person_rounded, size: 50, color: primaryColor),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Camera Edit Button
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final file = await FileUploadHelper.pickFileOrPhoto(
                                        context,
                                        title: 'Update Profile Photo',
                                      );
                                      if (file != null) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Profile photo updated: ${file.name}')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Driver Captain',
                                  style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'CarrierDirect ID: #DRV-84920 • Level 1 Verified Driver',
                              style: TextStyle(color: textMuted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Personal Details
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildCustomInputField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number with Country Code Picker
                      _buildPhoneFieldWithPicker(context),
                      const SizedBox(height: 16),

                      _buildCustomInputField(
                        label: 'Email Address',
                        hintText: 'Enter email address',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _buildCustomInputField(
                        label: 'Home / Base Address',
                        hintText: 'Enter base address',
                        controller: _addressController,
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 26),

                      // Section 2: License & Compliance Documents
                      const Text(
                        'License & Compliance Details',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildCustomInputField(
                        label: 'Commercial Driver License (CDL-A)',
                        hintText: 'e.g. TX-CDL-89420-A',
                        controller: _cdlController,
                        icon: Icons.badge_outlined,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Color(0xFF0284C7), size: 20),
                          tooltip: 'View Document',
                          onPressed: () {
                            _openDocumentPreviewModal(
                              title: 'CDL-A Driver License',
                              docNumber: _cdlController.text,
                              expiry: 'October 2028',
                              icon: Icons.badge_outlined,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildCustomInputField(
                        label: 'DOT Medical Certificate',
                        hintText: 'e.g. DOT-MED-993841',
                        controller: _dotMedController,
                        icon: Icons.medical_services_outlined,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Color(0xFF0284C7), size: 20),
                          tooltip: 'View Document',
                          onPressed: () {
                            _openDocumentPreviewModal(
                              title: 'DOT Medical Certificate',
                              docNumber: _dotMedController.text,
                              expiry: 'October 2026',
                              icon: Icons.medical_services_outlined,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildCustomInputField(
                        label: 'Commercial Carrier Insurance',
                        hintText: 'e.g. INS-POL-49201',
                        controller: _insuranceController,
                        icon: Icons.shield_outlined,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility_outlined, color: Color(0xFF0284C7), size: 20),
                          tooltip: 'View Document',
                          onPressed: () {
                            _openDocumentPreviewModal(
                              title: 'Carrier Insurance Policy',
                              docNumber: _insuranceController.text,
                              expiry: 'December 2026',
                              icon: Icons.shield_outlined,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildCustomInputField(
                        label: 'Emergency Contact',
                        hintText: 'Name & Phone number',
                        controller: _emergencyController,
                        icon: Icons.contact_emergency_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Bottom Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Field with white card fill and light border
  Widget _buildCustomInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textLabel,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w500),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: textMuted, fontSize: 13.5),
            filled: true,
            fillColor: inputBg,
            prefixIcon: Icon(icon, color: primaryColor, size: 18),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Phone Number Field with country_picker modal
  Widget _buildPhoneFieldWithPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textLabel,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inputBorder, width: 1),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openCountryPickerModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountryFlag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountryCode,
                        style: const TextStyle(
                          color: textMain,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textMuted),
                    ],
                  ),
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: inputBorder,
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w500),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13.5),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
