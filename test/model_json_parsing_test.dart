import 'package:buy_from_lango/models/buyer_need.dart';
import 'package:buy_from_lango/models/chat_thread.dart';
import 'package:buy_from_lango/models/listing.dart';
import 'package:buy_from_lango/models/market_price.dart';
import 'package:buy_from_lango/models/message.dart';
import 'package:buy_from_lango/models/notification.dart';
import 'package:buy_from_lango/models/order.dart';
import 'package:buy_from_lango/models/profile.dart';
import 'package:buy_from_lango/models/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ListingModel parses numeric and boolean values stored as strings', () {
    final listing = ListingModel.fromJson({
      'id': '12',
      'user_id': 'user-1',
      'category_id': 'vegetables',
      'title': 'Fresh yam',
      'description': 'Nutrient-rich produce',
      'price_ugx': '350000',
      'is_negotiable': 'true',
      'quantity': '20 sacks',
      'unit': 'Sacks',
      'remaining_quantity': '12.5',
      'sale_status': 'partially_sold',
      'edit_count': 1,
      'district_id': '3',
      'district': {'name': 'Lira'},
      'created_via': 'sms',
      'subcounty_id': '4',
      'parish_id': '5',
      'status': 'active',
      'is_anonymous': 'false',
      'is_featured': 'true',
      'view_count': '8',
      'created_at': '2024-05-04T12:00:00Z',
    });

    expect(listing.id, 12);
    expect(listing.priceUgx, 350000);
    expect(listing.isNegotiable, isTrue);
    expect(listing.isFeatured, isTrue);
    expect(listing.quantity, '20 sacks');
    expect(listing.unit, 'Sacks');
    expect(listing.remainingQuantity, 12.5);
    expect(listing.saleStatus, 'partially_sold');
    expect(listing.isFullySold, isFalse);
    expect(listing.editCount, 1);
    expect(listing.viewCount, 8);
    expect(listing.districtName, 'Lira');
    expect(listing.createdVia, 'sms');
    expect(listing.createdAt, DateTime.utc(2024, 5, 4, 12, 0, 0));
  });

  test('ListingModel recognizes fully sold and legacy sold status values', () {
    final soldListing = ListingModel.fromJson({
      'id': 16,
      'user_id': 'seller-1',
      'category_id': 'crops',
      'title': 'Maize',
      'sale_status': 'fully_sold',
    });
    final legacySoldListing = ListingModel.fromJson({
      'id': 17,
      'user_id': 'seller-1',
      'category_id': 'crops',
      'title': 'Beans',
      'sale_status': 'sold',
    });

    expect(soldListing.isFullySold, isTrue);
    expect(legacySoldListing.isFullySold, isTrue);
  });

  test('ListingModel identifies read-only offline cache entries', () {
    final listing = ListingModel.fromJson({
      'id': 14,
      'user_id': '',
      'category_id': 'produce',
      'title': 'Fresh cassava',
      'is_cached_offline': true,
    });

    expect(listing.isCachedOffline, isTrue);
    expect(listing.userId, isEmpty);
  });

  test('ListingModel reads the first uploaded image from nested media', () {
    final listing = ListingModel.fromJson({
      'id': 15,
      'user_id': 'seller-1',
      'category_id': 'crops',
      'title': 'White maize',
      'listing_media': [
        {
          'media_type': 'video',
          'media_url': 'https://example.com/maize.mp4',
        },
        {
          'media_type': 'image',
          'media_url': 'https://example.com/maize.jpg',
        },
      ],
    });

    expect(listing.imageUrl, 'https://example.com/maize.jpg');
  });

  test('AppNotificationModel parses payload maps and flag values safely', () {
    final notification = AppNotificationModel.fromJson({
      'id': '99',
      'user_id': 'user-2',
      'kind': 'listing',
      'title': 'Offer received',
      'body': 'A buyer reached out.',
      'payload': {'listing_id': '42', 'matched': 'true'},
      'is_read': '1',
      'created_at': '2025-01-01T00:30:00+03:00',
    });

    expect(notification.id, 99);
    expect(notification.isRead, isTrue);
    expect(notification.payload, {'listing_id': '42', 'matched': 'true'});
  });

  test('MessageModel parses reply and forwarded message references', () {
    final message = MessageModel.fromJson({
      'id': 10,
      'thread_id': 4,
      'sender_id': 'user-1',
      'content': 'Forwarded note',
      'media_type': 'text',
      'reply_to': 8,
      'forwarded_from': 6,
    });

    expect(message.replyTo, 8);
    expect(message.forwardedFrom, 6);
  });

  test('BuyerNeedModel parses quantity, price, and public location labels', () {
    final need = BuyerNeedModel.fromJson({
      'id': 3,
      'user_id': 'buyer-1',
      'item_name': 'White maize',
      'quantity': '5',
      'unit': 'Bags',
      'proposed_price_ugx': '120000',
      'contact_person': 'Amina',
      'district_name': 'Lira',
      'subcounty_name': 'Agweng',
      'parish_name': 'Abala',
      'poster_name': 'Amina Okello',
      'poster_avatar_url': 'https://example.com/avatar.png',
      'poster_is_verified': true,
      'poster_account_type': 'cooperative',
      'item_image_url': 'https://example.com/maize.png',
      'category_id': 'crops',
      'created_via': 'ussd',
    });

    expect(need.quantity, 5);
    expect(need.proposedPriceUgx, 120000);
    expect(need.districtName, 'Lira');
    expect(need.subcountyName, 'Agweng');
    expect(need.parishName, 'Abala');
    expect(need.posterName, 'Amina Okello');
    expect(need.posterAvatarUrl, 'https://example.com/avatar.png');
    expect(need.posterIsVerified, isTrue);
    expect(need.posterAccountType, 'cooperative');
    expect(need.itemImageUrl, 'https://example.com/maize.png');
    expect(need.categoryId, 'crops');
    expect(need.createdVia, 'ussd');
  });

  test('ProfileModel maps email, visibility and account type', () {
    final profile = ProfileModel.fromJson({
      'id': 'user-1',
      'email': 'farmer@example.com',
      'account_type': 'cooperative',
      'item_visibility': 'contacts',
      'has_email': true,
    });

    expect(profile.email, 'farmer@example.com');
    expect(profile.toJson()['email'], 'farmer@example.com');
    expect(profile.accountType, 'cooperative');
    expect(profile.itemVisibility, 'contacts');
    expect(profile.isFeaturePhoneUser, isFalse);

    final defaults = ProfileModel.fromJson({
      'id': 'user-2',
      'email': '  ',
    });
    expect(defaults.accountType, 'individual');
    expect(defaults.itemVisibility, 'public');
    expect(defaults.isFeaturePhoneUser, isTrue);
  });

  test('ProfileModel reads public storefront district and member date', () {
    final profile = ProfileModel.fromJson({
      'id': 'seller-1',
      'district_name': 'Lira',
      'created_at': '2024-06-02T00:00:00Z',
    });

    expect(profile.districtName, 'Lira');
    expect(profile.createdAt, DateTime.utc(2024, 6, 2));
  });

  test('MarketPriceModel parses district and price change values', () {
    final price = MarketPriceModel.fromJson({
      'id': 8,
      'district_id': 2,
      'crop_name': 'White maize',
      'district': {'name': 'Lira'},
      'price_per_kg_ugx': '1800',
      'farm_gate_price_ugx': '1500',
      'wholesale_price_ugx': '1800',
      'retail_price_ugx': '2200',
      'price_change_percent': '-3.5',
    });

    expect(price.itemName, 'White maize');
    expect(price.districtName, 'Lira');
    expect(price.marketPriceUgx, 1800);
    expect(price.farmGatePriceUgx, 1500);
    expect(price.wholesalePriceUgx, 1800);
    expect(price.retailPriceUgx, 2200);
    expect(price.priceChangePercent, -3.5);
  });

  test('MarketPriceModel keeps unavailable prices null', () {
    final price = MarketPriceModel.fromJson({
      'id': 8,
      'district_id': 2,
      'crop_name': 'White maize',
      'price_per_kg_ugx': '1800',
    });

    expect(price.marketPriceUgx, 1800);
    expect(price.farmGatePriceUgx, isNull);
    expect(price.wholesalePriceUgx, isNull);
    expect(price.retailPriceUgx, isNull);
  });

  test('ChatThreadModel parses buyer-need conversations without a listing', () {
    final thread = ChatThreadModel.fromJson({
      'id': 12,
      'buyer_need_id': 3,
      'buyer_id': 'seller-1',
      'seller_id': 'buyer-1',
    });

    expect(thread.listingId, isNull);
    expect(thread.buyerNeedId, 3);
  });

  test('OrderModel parses order type, edit count, and revealed phone state',
      () {
    final order = OrderModel.fromJson({
      'id': 8,
      'listing_id': 3,
      'buyer_id': 'buyer-1',
      'seller_id': 'seller-1',
      'type': 'contact_request',
      'status': 'accepted',
      'edit_count': 1,
      'phone_revealed_by_seller': true,
    });

    expect(order.type, 'contact_request');
    expect(order.editCount, 1);
    expect(order.phoneRevealedBySeller, isTrue);
  });

  test('ReviewModel parses rating, comment, and created date', () {
    final review = ReviewModel.fromJson({
      'id': 5,
      'reviewer_id': 'buyer-1',
      'seller_id': 'poster-1',
      'rating': 4,
      'comment': 'Good communication.',
      'created_at': '2025-03-10T08:30:00Z',
    });

    expect(review.id, 5);
    expect(review.reviewerId, 'buyer-1');
    expect(review.sellerId, 'poster-1');
    expect(review.rating, 4);
    expect(review.comment, 'Good communication.');
    expect(review.createdAt, DateTime.utc(2025, 3, 10, 8, 30));
  });
}
