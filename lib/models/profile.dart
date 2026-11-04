import 'json_helpers.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.hasEmail,
    this.role = 'both',
    this.accountType = 'individual',
    this.itemVisibility = 'public',
    this.districtId,
    this.subcountyId,
    this.parishId,
    this.isAnonymous = false,
    this.isVerified = false,
    this.isAdmin = false,
    this.avatarUrl,
    this.bio,
    this.districtName,
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final bool? hasEmail;
  final String role;
  final String accountType;
  final String itemVisibility;
  final int? districtId;
  final int? subcountyId;
  final int? parishId;
  final bool isAnonymous;
  final bool isVerified;
  final bool isAdmin;
  final String? avatarUrl;
  final String? bio;
  final String? districtName;
  final DateTime? createdAt;

  bool get isFeaturePhoneUser =>
      email != null ? email!.trim().isEmpty : !(hasEmail ?? false);

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: JsonReader.string(json, 'id'),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      hasEmail: json.containsKey('has_email')
          ? JsonReader.boolValue(json, 'has_email')
          : null,
      role: JsonReader.string(json, 'role', defaultValue: 'both'),
      accountType: JsonReader.string(
        json,
        'account_type',
        defaultValue: 'individual',
      ),
      itemVisibility: JsonReader.string(
        json,
        'item_visibility',
        defaultValue: 'public',
      ),
      districtId: JsonReader.intValue(json, 'district_id'),
      subcountyId: JsonReader.intValue(json, 'subcounty_id'),
      parishId: JsonReader.intValue(json, 'parish_id'),
      isAnonymous: JsonReader.boolValue(json, 'is_anonymous'),
      isVerified: JsonReader.boolValue(json, 'is_verified'),
      isAdmin: JsonReader.boolValue(json, 'is_admin'),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      districtName: (json['district'] as Map?)?['name']?.toString() ??
          json['district_name']?.toString(),
      createdAt: JsonReader.dateTime(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'account_type': accountType,
      'item_visibility': itemVisibility,
      'district_id': districtId,
      'subcounty_id': subcountyId,
      'parish_id': parishId,
      'is_anonymous': isAnonymous,
      'is_verified': isVerified,
      'is_admin': isAdmin,
      'avatar_url': avatarUrl,
      'bio': bio,
      'district_name': districtName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
