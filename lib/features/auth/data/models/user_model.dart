class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String? vehicleNumber;
  final bool isOnline;
  final String? verificationStatus;
  final bool isVerified;
  final String? dutyStatus;
  final bool twoFactorEnabled;
  final bool requires2fa;
  final String? token;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.vehicleNumber,
    this.isOnline = false,
    this.verificationStatus,
    this.isVerified = false,
    this.dutyStatus,
    this.twoFactorEnabled = false,
    this.requires2fa = false,
    this.token,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? token,
    bool requires2fa = false,
  }) {
    final driverProfile = json['driver_profile'] is Map
        ? json['driver_profile'] as Map<String, dynamic>
        : null;
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['name'] ?? json['full_name'] ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      vehicleNumber:
          driverProfile?['truck_number']?.toString() ??
          json['vehicle_number']?.toString(),
      isOnline: json['is_online'] == true,
      verificationStatus:
          json['verification_status']?.toString() ??
          driverProfile?['verification_status']?.toString() ??
          'pending_setup',
      isVerified: json['is_verified'] == true,
      dutyStatus:
          json['duty_status']?.toString() ??
          driverProfile?['duty_status']?.toString() ??
          'offline',
      twoFactorEnabled: json['two_factor_enabled'] == true,
      requires2fa: requires2fa || json['requires_2fa'] == true,
      token:
          token ??
          json['access_token']?.toString() ??
          json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'vehicle_number': vehicleNumber,
      'is_online': isOnline,
      'verification_status': verificationStatus,
      'is_verified': isVerified,
      'duty_status': dutyStatus,
      'two_factor_enabled': twoFactorEnabled,
      'access_token': token,
    };
  }
}
