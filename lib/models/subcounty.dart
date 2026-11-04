import 'json_helpers.dart';

class Subcounty {
  const Subcounty({
    required this.id,
    required this.districtId,
    required this.name,
    this.isActive = true,
  });

  final int id;
  final int districtId;
  final String name;
  final bool isActive;

  factory Subcounty.fromJson(Map<String, dynamic> json) {
    return Subcounty(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      districtId: JsonReader.intValue(json, 'district_id', defaultValue: 0) ?? 0,
      name: JsonReader.string(json, 'name'),
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'district_id': districtId,
      'name': name,
      'is_active': isActive,
    };
  }
}
