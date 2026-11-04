import 'package:buy_from_lango/models/message.dart';
import 'package:buy_from_lango/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message SMS delivery marker is parsed and serialized', () {
    final message = MessageModel.fromJson({
      'id': 12,
      'thread_id': 4,
      'sender_id': 'sender',
      'content': 'Hello',
      'is_sms': true,
    });

    expect(message.isSms, isTrue);
    expect(message.toJson()['is_sms'], isTrue);
  });

  test('profile feature phone flag defaults to false and parses', () {
    final ordinaryProfile = ProfileModel.fromJson({'id': 'ordinary'});
    final featurePhoneProfile = ProfileModel.fromJson({
      'id': 'feature-phone',
      'is_feature_phone': true,
    });

    expect(ordinaryProfile.isFeaturePhone, isFalse);
    expect(featurePhoneProfile.isFeaturePhone, isTrue);
    expect(featurePhoneProfile.isFeaturePhoneUser, isTrue);
  });
}
