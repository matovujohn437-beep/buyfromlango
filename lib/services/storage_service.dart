import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<String> uploadListingMedia({
    required Uint8List bytes,
    required String userId,
    required String listingId,
    required String extension,
    required String mediaType,
  }) async {
    if (!const {'image', 'video', 'audio'}.contains(mediaType)) {
      throw ArgumentError.value(mediaType, 'mediaType');
    }
    final safeExtension = extension.toLowerCase();
    final isImage =
        const {'jpg', 'jpeg', 'png', 'webp'}.contains(safeExtension);
    final isVideo = const {'mp4', 'mov', 'webm'}.contains(safeExtension) &&
        !(safeExtension == 'webm' && mediaType == 'audio');
    final isAudio =
        const {'m4a', 'aac', 'mp3', 'wav'}.contains(safeExtension) ||
            (safeExtension == 'webm' && mediaType == 'audio');
    if ((mediaType == 'image' && !isImage) ||
        (mediaType == 'video' && !isVideo) ||
        (mediaType == 'audio' && !isAudio)) {
      throw ArgumentError(
        'The .$safeExtension file does not match media type "$mediaType".',
      );
    }
    final contentType = switch (safeExtension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => mediaType == 'audio' ? 'audio/webm' : 'video/webm',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      _ =>
        throw ArgumentError.value(extension, 'extension', 'Unsupported media'),
    };
    final path =
        '$userId/$listingId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    final bucket = _client.storage.from('listing-media');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return bucket.getPublicUrl(path);
  }

  Future<String> uploadBuyerNeedImage({
    required Uint8List bytes,
    required String userId,
    required String extension,
  }) async {
    final safeExtension = extension.toLowerCase();
    final contentType = switch (safeExtension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => throw ArgumentError.value(
          extension,
          'extension',
          'Unsupported image format',
        ),
    };
    final path =
        '$userId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    final bucket = _client.storage.from('buyer-need-images');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return bucket.getPublicUrl(path);
  }

  Future<void> removeBuyerNeedImage(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    const marker = '/storage/v1/object/public/buyer-need-images/';
    final pathStart = uri.path.indexOf(marker);
    if (pathStart < 0) {
      throw const FormatException('The buyer-need image URL is invalid.');
    }
    final path =
        Uri.decodeComponent(uri.path.substring(pathStart + marker.length));
    await _client.storage.from('buyer-need-images').remove([path]);
  }
}
