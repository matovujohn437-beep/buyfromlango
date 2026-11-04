class JsonReader {
  const JsonReader._();

  static String string(
    Map<String, dynamic> json,
    String key, {
    String defaultValue = '',
  }) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    return value.toString();
  }

  static int? intValue(
    Map<String, dynamic> json,
    String key, {
    int? defaultValue,
  }) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static num? numValue(
    Map<String, dynamic> json,
    String key, {
    num? defaultValue,
  }) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString()) ?? defaultValue;
  }

  static bool boolValue(
    Map<String, dynamic> json,
    String key, {
    bool defaultValue = false,
  }) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();
    switch (normalized) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'null':
      case '':
        return false;
      default:
        return defaultValue;
    }
  }

  static DateTime? dateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic>? map(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
