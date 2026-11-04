import 'json_helpers.dart';

class District {
  const District({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final int id;
  final String name;
  final bool isActive;

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      name: JsonReader.string(json, 'name'),
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
    };
  }
}
