class ListingDetailRouteData {
  const ListingDetailRouteData({
    this.primaryImageUrl,
    required this.heroTag,
  });

  final String? primaryImageUrl;
  final String heroTag;
}

String listingHeroTag(int listingId) => 'listing-image-$listingId';
