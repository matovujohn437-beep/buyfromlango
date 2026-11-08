import 'package:buy_from_lango/models/chat_thread.dart';
import 'package:buy_from_lango/models/message.dart';
import 'package:buy_from_lango/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat thread parses participant-specific archive and delete state', () {
    final thread = ChatThreadModel.fromJson({
      'id': 12,
      'buyer_id': 'buyer',
      'seller_id': 'seller',
      'buyer_archived_at': '2026-10-14T12:00:00Z',
      'seller_deleted_at': '2026-10-15T12:00:00Z',
    });

    expect(thread.isArchivedFor('buyer'), isTrue);
    expect(thread.isArchivedFor('seller'), isFalse);
    expect(thread.sellerDeletedAt, DateTime.utc(2026, 10, 15, 12));
  });

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
