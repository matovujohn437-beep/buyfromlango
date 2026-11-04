import 'json_helpers.dart';

class Parish {
  const Parish({
    required this.id,
    required this.subcountyId,
    required this.name,
    this.isActive = true,
  });

  final int id;
  final int subcountyId;
  final String name;
  final bool isActive;

  factory Parish.fromJson(Map<String, dynamic> json) {
    return Parish(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      subcountyId: JsonReader.intValue(json, 'subcounty_id', defaultValue: 0) ?? 0,
      name: JsonReader.string(json, 'name'),
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subcounty_id': subcountyId,
      'name': name,
      'is_active': isActive,
    };
  }
}
