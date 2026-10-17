import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import '../../../../services/location_service.dart';
import '../../../../services/place_autocomplete_service.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/file_upload_helper.dart';

class DocumentVerificationModal extends StatefulWidget {
  final VoidCallback onVerificationComplete;

  const DocumentVerificationModal({
    super.key,
    required this.onVerificationComplete,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onVerificationComplete}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DocumentVerificationModal(
        onVerificationComplete: onVerificationComplete,
      ),
    );
  }

  @override
  State<DocumentVerificationModal> createState() => _DocumentVerificationModalState();
}

class _DocumentVerificationModalState extends State<DocumentVerificationModal> {
  int _currentStep = 1; // 1: Personal Info, 2: Driver Details, 3: Documents & Submit

  // Color Tokens
  static const Color primaryOrange = Color(0xFFFF4A1F);
  static const Color primaryOrangeLight = Color(0xFFFFF7ED);
  static const Color primaryOrangeBorder = Color(0xFFFFEDD5);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF059669);

  // --- Step 1: Personal Information ---
  UploadedFileInfo? _avatarFile;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  Country _selectedCountry = countries.firstWhere(
    (c) => c.code == 'BD',
    orElse: () => countries.first,
  );
  bool _isCountryDropdownOpen = false;
  final _countrySearchController = TextEditingController();
  final _countryScrollController = ScrollController();
  final _locationController = TextEditingController();
  bool _isDetectingLocation = false;
  final FocusNode _locationFocusNode = FocusNode();
  List<PlaceSuggestion> _locationSuggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _locationDebounceTimer;

  // --- Step 2: Driver Details ---
  static const List<String> driverModeOptions = [
    'Company Driver',
    'Owner Operator',
    'Independent Contractor',
    'Fleet Driver',
  ];
  String? _driverMode;

  static const List<String> licenseClassOptions = [
    'Class A CDL',
    'Class B CDL',
    'Class C CDL',
    'Class D',
    'Class E',
  ];
  String? _licenseClass;

  static const List<String> experienceOptions = [
    'Less than 1 year',
    '1-2 years',
    '3-5 years',
    '5-10 years',
    '10+ years',
  ];
  String? _experienceYears;

  final _endorsementsController = TextEditingController();
  final _vehicleTypesController = TextEditingController();

  // --- Step 3: Verification Documents ---
  UploadedFileInfo? _licenseFrontFile;
  UploadedFileInfo? _licenseBackFile;
  UploadedFileInfo? _medicalCardFile;
  UploadedFileInfo? _insuranceFile;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _countrySearchController.dispose();
    _countryScrollController.dispose();
    _locationDebounceTimer?.cancel();
    _locationFocusNode.dispose();
    _locationController.dispose();
    _endorsementsController.dispose();
    _vehicleTypesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validation
    if (_currentStep == 1) {
      if (_fullNameController.text.trim().isEmpty) {
        AppToast.error(context, 'Please enter your full name');
        return;
      }
      if (_phoneController.text.trim().isEmpty) {
        AppToast.error(context, 'Please enter your phone number');
        return;
      }
      if (_locationController.text.trim().isEmpty) {
        AppToast.error(context, 'Please enter your current location');
        return;
      }
      setState(() {
        _isCountryDropdownOpen = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if (_driverMode == null || _driverMode!.isEmpty) {
        AppToast.error(context, 'Please select your driver mode');
        return;
      }
      if (_licenseClass == null || _licenseClass!.isEmpty) {
        AppToast.error(context, 'Please select your license class');
        return;
      }
      if (_experienceYears == null || _experienceYears!.isEmpty) {
        AppToast.error(context, 'Please select your years of experience');
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      _submitAllDocuments();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _submitAllDocuments() async {
    setState(() => _isSubmitting = true);
    debugPrint('Submitting driver profile: ${_fullNameController.text}, phone: +${_selectedCountry.dialCode}${_phoneController.text}, location: ${_locationController.text}');
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      widget.onVerificationComplete();
      AppToast.success(
        context,
        'Compliance verification submitted successfully! All driver features unlocked.',
        icon: Icons.verified_rounded,
      );
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _locationController.text = 'Dallas, TX, United States (GPS Verified)';
          _locationSuggestions = [];
          _isLoadingSuggestions = false;
        });
        AppToast.success(
          context,
          'Current GPS location detected',
          icon: Icons.my_location_rounded,
        );
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isDetectingLocation = false);
    }
  }

  void _onLocationChanged(String query) {
    _locationDebounceTimer?.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      if (_locationSuggestions.isNotEmpty || _isLoadingSuggestions) {
        setState(() {
          _locationSuggestions = [];
          _isLoadingSuggestions = false;
        });
      }
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    // Call Google Maps Places API directly on typing
    _locationDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      final results = await PlaceAutocompleteService().searchPlaces(clean);
      if (mounted && clean == _locationController.text.trim()) {
        setState(() {
          _locationSuggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  Widget _buildCountryCodeDropdown() {
    final query = _countrySearchController.text.trim().toLowerCase();
    final filtered = countries.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.dialCode.contains(query) ||
          c.code.toLowerCase().contains(query);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: slate200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Input Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: slate200, width: 0.8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 16, color: slate400),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _countrySearchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: slate900, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Search country',
                      hintStyle: const TextStyle(color: slate400, fontSize: 12),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: slate200, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: slate200, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        borderSide: const BorderSide(color: primaryOrange, width: 1.2),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isCountryDropdownOpen = false),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: slate500),
                ),
              ],
            ),
          ),

          // Scrollable List with light blue selection and scrollbar
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: RawScrollbar(
              controller: _countryScrollController,
              thumbVisibility: true,
              thumbColor: const Color(0xFFCBD5E1),
              radius: const Radius.circular(2),
              thickness: 3.5,
              child: ListView.builder(
                controller: _countryScrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = item.code == _selectedCountry.code;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCountry = item;
                        _isCountryDropdownOpen = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEBF5FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        children: [
                          Text(item.flag, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '+${item.dialCode}',
                              style: const TextStyle(
                                color: slate900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: isSelected ? slate900 : slate700,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final file = await FileUploadHelper.pickFileOrPhoto(
      context,
      title: 'Upload Profile Photo',
    );
    if (file != null) {
      setState(() => _avatarFile = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxModalHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Drag Handle Pill
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),

            // 3-Step Horizontal Stepper (Personal Info -> Driver Details -> Documents & Submit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildStepper(),
            ),
            const SizedBox(height: 12),
            const Divider(color: slate200, height: 1),

            // Dynamic Step Form Body (Scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 14.0,
                  bottom: bottomInset + 12.0,
                ),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Footer Action Bar (without top border line)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: _buildFooterButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Horizontal Stepper ---
  Widget _buildStepper() {
    return Row(
      children: [
        Flexible(child: _buildStepperItem(step: 1, title: 'Personal Info')),
        _buildStepperConnector(isDone: _currentStep > 1),
        Flexible(child: _buildStepperItem(step: 2, title: 'Driver Details')),
        _buildStepperConnector(isDone: _currentStep > 2),
        Flexible(child: _buildStepperItem(step: 3, title: 'Documents')),
      ],
    );
  }

  Widget _buildStepperItem({required int step, required String title}) {
    final isDone = _currentStep > step;
    final isActive = _currentStep == step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? successGreen
                : isActive
                    ? primaryOrange
                    : Colors.white,
            border: Border.all(
              color: isDone
                  ? successGreen
                  : isActive
                      ? primaryOrange
                      : slate400,
              width: 1.4,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : slate500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive
                  ? primaryOrange
                  : isDone
                      ? slate700
                      : slate400,
              fontSize: 11,
              fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepperConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone ? successGreen : slate200,
      ),
    );
  }

  // --- Current Step Selector ---
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Personal();
      case 2:
        return _buildStep2Experience();
      case 3:
        return _buildStep3Documents();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // STEP 1: Personal Information
  // =========================================================================
  Widget _buildStep1Personal() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildStepHeader(
          icon: Icons.person_outline,
          title: 'Personal Information',
          subtitle: 'Provide your basic contact information and profile details.',
        ),
        const SizedBox(height: 16),

        // Profile Image Section (matches user screenshot)
        _buildFieldLabel(label: 'Profile Image'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with camera badge
            GestureDetector(
              onTap: _pickProfilePhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slate100,
                      border: Border.all(color: slate200, width: 1.5),
                    ),
                    child: ClipOval(
                      child: _avatarFile != null && _avatarFile!.path != null
                          ? Image.file(
                              File(_avatarFile!.path!),
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(Icons.person_rounded, size: 36, color: slate400),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: slate200, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt_rounded, size: 12, color: slate700),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Vertical divider
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: slate200,
            ),

            // Upload Photo Button & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickProfilePhoto,
                  icon: const Icon(Icons.file_upload_outlined, size: 15, color: slate700),
                  label: Text(
                    _avatarFile != null ? 'Change Photo' : 'Upload Photo',
                    style: const TextStyle(
                      color: slate900,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: slate200, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG (Max 5MB)',
                  style: TextStyle(
                    color: slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Full Name Field
        _buildFieldLabel(label: 'Full Name', isRequired: true),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _fullNameController,
          hintText: 'Enter your full name',
          keyboardType: TextInputType.name,
        ),
        const SizedBox(height: 14),

        // Phone Number Field with Country Code Dropdown (powered by intl_phone_field dataset)
        _buildFieldLabel(label: 'Phone Number', isRequired: true),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Standalone Country Code Box (matching previous UI design)
            InkWell(
              onTap: () {
                setState(() => _isCountryDropdownOpen = !_isCountryDropdownOpen);
              },
              borderRadius: BorderRadius.circular(5.0),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    color: _isCountryDropdownOpen ? primaryOrange : slate200,
                    width: _isCountryDropdownOpen ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedCountry.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '+${_selectedCountry.dialCode}',
                      style: const TextStyle(color: slate900, fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isCountryDropdownOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: slate500,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Standalone Phone Number Input Box
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: slate900, fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: const TextStyle(color: slate400, fontSize: 12.5),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: const BorderSide(color: slate200, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: const BorderSide(color: primaryOrange, width: 1.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Country Code Dropdown Menu (Preview matching previous sleek UI)
        if (_isCountryDropdownOpen) ...[
          const SizedBox(height: 6),
          _buildCountryCodeDropdown(),
        ],
        const SizedBox(height: 14),

        // Current Location with Google Map Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel(label: 'Current Location', isRequired: true),
            InkWell(
              onTap: _isDetectingLocation ? null : _detectCurrentLocation,
              borderRadius: BorderRadius.circular(5.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDetectingLocation)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryOrange),
                    )
                  else
                    const Icon(Icons.location_on, size: 12, color: primaryOrange),
                  const SizedBox(width: 3),
                  const Text(
                    'Google Map',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _locationController,
          focusNode: _locationFocusNode,
          onChanged: _onLocationChanged,
          hintText: 'Search city, state, country or address...',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 16, color: slate400),
          suffixIcon: _isLoadingSuggestions
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrange),
                  ),
                )
              : _locationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: slate400),
                      onPressed: () {
                        setState(() {
                          _locationController.clear();
                          _locationSuggestions = [];
                          _isLoadingSuggestions = false;
                        });
                      },
                    )
                  : null,
          keyboardType: TextInputType.streetAddress,
        ),
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildLocationSuggestionsDropdown(),
        ],
      ],
    );
  }

  Widget _buildLocationSuggestionsDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: slate200, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Google Places Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5.0)),
              border: Border(bottom: BorderSide(color: slate200, width: 0.8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.travel_explore_rounded, size: 14, color: primaryOrange),
                const SizedBox(width: 6),
                const Text(
                  'Google Maps Suggestions',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: slate600,
                    letterSpacing: -0.1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _locationSuggestions = [];
                    });
                  },
                  child: const Icon(Icons.close_rounded, size: 14, color: slate400),
                ),
              ],
            ),
          ),
          // Suggestions List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final place = _locationSuggestions[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _locationController.text = place.fullAddress;
                      _locationSuggestions = [];
                      _isLoadingSuggestions = false;
                    });
                    _locationFocusNode.unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1EB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.mainText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: slate900,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (place.secondaryText.isNotEmpty) ...[
                                const SizedBox(height: 1.5),
                                Text(
                                  place.secondaryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: slate500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 13,
                          color: slate400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // STEP 2: Driver Experience & License Details
  // =========================================================================
  Widget _buildStep2Experience() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildStepHeader(
          icon: Icons.local_shipping_outlined,
          title: 'Driver Experience & License Details',
          subtitle: 'Specify your driving qualifications, CDL class, and experience.',
        ),
        const SizedBox(height: 16),

        // Driver Mode Dropdown (matches user screenshot)
        _buildFieldLabel(label: 'Driver Mode', isRequired: true),
        const SizedBox(height: 5),
        _CustomMinimalDropdown(
          value: _driverMode,
          hint: 'Select driver mode',
          items: driverModeOptions,
          onChanged: (val) => setState(() => _driverMode = val),
        ),
        const SizedBox(height: 14),

        // License Class Dropdown (matches user screenshot)
        _buildFieldLabel(label: 'License Class', isRequired: true),
        const SizedBox(height: 5),
        _CustomMinimalDropdown(
          value: _licenseClass,
          hint: 'Select license class',
          items: licenseClassOptions,
          onChanged: (val) => setState(() => _licenseClass = val),
        ),
        const SizedBox(height: 14),

        // Years of Driving Experience Dropdown
        _buildFieldLabel(label: 'Years of Driving Experience', isRequired: true),
        const SizedBox(height: 5),
        _CustomMinimalDropdown(
          value: _experienceYears,
          hint: 'Select years',
          items: experienceOptions,
          onChanged: (val) => setState(() => _experienceYears = val),
        ),
        const SizedBox(height: 14),

        // Endorsements (Optional)
        _buildFieldLabel(label: 'Endorsements (Optional)'),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _endorsementsController,
          hintText: 'e.g. Tanker (N), HazMat (H), Doubles (T)',
        ),
        const SizedBox(height: 14),

        // Vehicle Types Experienced With (Optional)
        _buildFieldLabel(label: 'Vehicle Types Experienced With (Optional)'),
        const SizedBox(height: 5),
        _buildTextField(
          controller: _vehicleTypesController,
          hintText: 'e.g. Semi-trailer, Flatbed, Box truck',
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 3: Upload Verification Documents
  // =========================================================================
  Widget _buildStep3Documents() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildStepHeader(
          icon: Icons.file_present_outlined,
          title: 'Upload Verification Documents',
          subtitle: 'Please upload the required documents below. Make sure all documents are clear, readable and not expired.',
        ),
        const SizedBox(height: 16),

        // Document Cards Grid (2x2 on mobile)
        Row(
          children: [
            Expanded(
              child: _buildDocumentUploadCard(
                title: 'Driving License (Front)',
                subtitle: 'Upload front side of license',
                icon: Icons.badge_outlined,
                iconColor: primaryOrange,
                iconBg: primaryOrangeLight,
                isRequired: true,
                file: _licenseFrontFile,
                uploadSubtitle: 'JPG, PNG or PDF',
                onPick: () async {
                  final f = await FileUploadHelper.pickFileOrPhoto(context, title: 'Upload License Front Side');
                  if (f != null) setState(() => _licenseFrontFile = f);
                },
                onRemove: () => setState(() => _licenseFrontFile = null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDocumentUploadCard(
                title: 'Driving License (Back)',
                subtitle: 'Upload back side of license',
                icon: Icons.badge_outlined,
                iconColor: primaryOrange,
                iconBg: primaryOrangeLight,
                isRequired: true,
                file: _licenseBackFile,
                uploadSubtitle: 'JPG, PNG or PDF',
                onPick: () async {
                  final f = await FileUploadHelper.pickFileOrPhoto(context, title: 'Upload License Back Side');
                  if (f != null) setState(() => _licenseBackFile = f);
                },
                onRemove: () => setState(() => _licenseBackFile = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildDocumentUploadCard(
                title: 'Medical Certificate',
                subtitle: 'DOT medical card if available',
                icon: Icons.medical_services_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                badge: 'Optional',
                file: _medicalCardFile,
                uploadSubtitle: 'DOT Card / PDF',
                onPick: () async {
                  final f = await FileUploadHelper.pickFileOrPhoto(context, title: 'Upload Medical Certificate');
                  if (f != null) setState(() => _medicalCardFile = f);
                },
                onRemove: () => setState(() => _medicalCardFile = null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDocumentUploadCard(
                title: 'Insurance Document',
                subtitle: 'Insurance policy coverage',
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                badge: 'Optional',
                file: _insuranceFile,
                uploadSubtitle: 'Insurance PDF',
                onPick: () async {
                  final f = await FileUploadHelper.pickFileOrPhoto(context, title: 'Upload Insurance Document');
                  if (f != null) setState(() => _insuranceFile = f);
                },
                onRemove: () => setState(() => _insuranceFile = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Informational Blue Note (matches web exactly)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Driving license (front and back) is required. Medical certificate and insurance document are optional and can also be uploaded later in your profile settings.',
                  style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Document Upload Card with 5px radius and clean dashed dropzone ---
  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool isRequired = false,
    String? badge,
    required UploadedFileInfo? file,
    required String uploadSubtitle,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final hasFile = file != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: hasFile ? successGreen.withValues(alpha: 0.6) : slate200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Center(
                  child: Icon(icon, size: 13, color: iconColor),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: slate900,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isRequired)
                          const Text(' *', style: TextStyle(color: primaryOrange, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: slate100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(color: slate500, fontSize: 8, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Upload Box or Preview
          if (hasFile)
            Container(
              height: 72,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 22, color: successGreen),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0),
                          child: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: slate900, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: slate700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: onPick,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: slate400.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  radius: 5.0,
                ),
                child: Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: slate50,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 18, color: slate400),
                      const SizedBox(height: 3),
                      const Text(
                        'Upload File',
                        style: TextStyle(color: slate700, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        uploadSubtitle,
                        style: const TextStyle(color: slate400, fontSize: 8.5),
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

  // --- Step Header Block (matches web style) ---
  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primaryOrangeLight,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: primaryOrangeBorder),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: primaryOrange),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: slate900,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: slate500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Reusable Input Label with Red Asterisk ---
  Widget _buildFieldLabel({required String label, bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: slate700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // --- Minimal TextField with 5px radius ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: slate900, fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: slate400, fontSize: 12.5),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: const BorderSide(color: slate200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: const BorderSide(color: primaryOrange, width: 1.4),
        ),
      ),
    );
  }



  // --- Footer Buttons (5px radius) ---
  Widget _buildFooterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 1) ...[
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: _previousStep,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: slate700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Back',
                style: TextStyle(color: slate700, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (_currentStep == 1) ...[
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: slate600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: slate600, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        SizedBox(
          height: 38,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentStep < 3 ? 'Next' : 'Submit for Verification',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      if (_currentStep < 3) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// --- Custom Painter for Minimal Dashed Box (5px radius) ---
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.radius = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 4.0;
    const double gap = 3.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dash < metric.length) ? dash : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

// =============================================================================
// Helper Models & Minimal Dropdown Widget (Matching Web / Design Aesthetic)
// =============================================================================



class _CustomMinimalDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _CustomMinimalDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_CustomMinimalDropdown> createState() => _CustomMinimalDropdownState();
}

class _CustomMinimalDropdownState extends State<_CustomMinimalDropdown> {
  bool _isOpen = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color slate900 = Color(0xFF0F172A);
    const Color slate700 = Color(0xFF334155);
    const Color slate500 = Color(0xFF64748B);
    const Color slate400 = Color(0xFF94A3B8);
    const Color slate200 = Color(0xFFE2E8F0);
    const Color softBlue = Color(0xFFEBF5FF);

    if (!_isOpen) {
      return InkWell(
        onTap: () => setState(() => _isOpen = true),
        borderRadius: BorderRadius.circular(5.0),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.value ?? widget.hint,
                  style: TextStyle(
                    color: widget.value != null ? slate900 : slate400,
                    fontSize: 12.5,
                    fontWeight: widget.value != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: slate500,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: slate200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row (showing hint and chevron down, exactly matching screenshot)
          InkWell(
            onTap: () => setState(() => _isOpen = false),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5.0)),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: slate200, width: 0.8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.hint,
                      style: const TextStyle(
                        color: slate400,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: slate500,
                  ),
                ],
              ),
            ),
          ),

          // Scrollable dropdown options with soft-blue highlight and sleek scrollbar
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: RawScrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thumbColor: const Color(0xFFCBD5E1),
              radius: const Radius.circular(2),
              thickness: 3.5,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.all(4),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected = item == widget.value;

                  return InkWell(
                    onTap: () {
                      widget.onChanged(item);
                      setState(() => _isOpen = false);
                    },
                    borderRadius: BorderRadius.circular(4.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? softBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isSelected ? slate900 : slate700,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

