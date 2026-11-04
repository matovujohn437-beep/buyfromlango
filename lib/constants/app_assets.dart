class AppAssets {
  const AppAssets._();

  static const String appLogo = 'assets/images/app_logo.png';
  static const String splashBackground = 'assets/images/splash_bg.png';
  static const String bannerHarvest = 'assets/images/banner_harvest.jpg';
  static const String bannerCoop = 'assets/images/banner_coop.png';
  static const String bannerMarket = 'assets/images/banner_market.png';
  static const String placeholderAvatar =
      'assets/illustrations/lango_avatar.png';
  static const String listingCrop = 'assets/images/listing_crop.jpg';
  static const String listingLivestock = 'assets/images/listing_livestock.png';
  static const String listingService = 'assets/images/listing_service.png';
  static const String listingJob = 'assets/images/listing_job.jpg';
  static const String listingCoop = 'assets/illustrations/lango_coop.svg';
  static const String illustratedFarmer =
      'assets/illustrations/lango_farmer.svg';

  static String listingImageForCategory(String categoryId) {
    return switch (categoryId.toLowerCase()) {
      'crops' || 'produce' => listingCrop,
      'livestock' => listingLivestock,
      'services' => listingService,
      'supplies' => listingCrop,
      'equipment' || 'machinery' => listingService,
      'jobs' => listingJob,
      'cooperatives' => listingCoop,
      _ => listingCrop,
    };
  }

  static String categoryIconForName(String iconName) {
    return switch (iconName.toLowerCase()) {
      'crops' || 'produce' => iconCrops,
      'livestock' => iconLivestock,
      'supplies' => iconSupplies,
      'equipment' || 'machinery' => iconEquipment,
      'service' || 'services' => iconService,
      'job' => iconJob,
      'coop' => iconCoop,
      _ => iconService,
    };
  }

  static const String onboarding1 = 'assets/illustrations/onboarding_1.png';
  static const String onboarding2 = 'assets/illustrations/onboarding_2.png';
  static const String onboarding3 = 'assets/illustrations/onboarding_3.png';
  static const String emptyListings = 'assets/illustrations/empty_listings.png';
  static const String emptyChat = 'assets/illustrations/empty_chat.png';
  static const String emptyOrders = 'assets/illustrations/empty_orders.png';
  static const String emptySearch = 'assets/illustrations/empty_search.png';
  static const String errorState = 'assets/illustrations/error_state.png';
  static const String offlineState = 'assets/illustrations/offline_state.svg';
  static const String successState = 'assets/illustrations/success_state.png';

  static const String iconCrops = 'assets/icons/crops.svg';
  static const String iconLivestock = 'assets/icons/livestock.svg';
  static const String iconService = 'assets/icons/service.svg';
  static const String iconSupplies = 'assets/icons/supplies.svg';
  static const String iconEquipment = 'assets/icons/equipment.svg';
  static const String iconJob = 'assets/icons/job.svg';
  static const String iconCoop = 'assets/icons/coop.svg';
  static const String iconVerifiedBadge = 'assets/icons/verified_badge.svg';
  static const String iconFeaturedBadge = 'assets/icons/featured_badge.svg';
  static const String iconLocationPin = 'assets/icons/location_pin.svg';
  static const String iconPhoneReveal = 'assets/icons/phone_reveal.svg';
  static const String iconEmptyBox = 'assets/icons/empty_box.svg';
  static const String iconNotification = 'assets/icons/notification.svg';
  static const String iconChat = 'assets/icons/chat.svg';
  static const String iconSearch = 'assets/icons/search.svg';
  static const String iconCamera = 'assets/icons/camera.svg';
  static const String iconMic = 'assets/icons/mic.svg';
  static const String iconVideo = 'assets/icons/video.svg';
  static const String iconEmoji = 'assets/icons/emoji.svg';
  static const String iconShare = 'assets/icons/share.svg';
  static const String iconReply = 'assets/icons/reply.svg';
  static const String iconForward = 'assets/icons/forward.svg';
  static const String iconDelete = 'assets/icons/delete.svg';
  static const String iconBlock = 'assets/icons/block.svg';
  static const String iconReport = 'assets/icons/report.svg';
  static const String iconGoogleLogo = 'assets/icons/google_logo.svg';

  static const String lottieLoading = 'assets/lottie/loading.json';
  static const String lottieSuccess = 'assets/lottie/success.json';
  static const String lottieEmpty = 'assets/lottie/empty.json';
  static const String lottieError = 'assets/lottie/error.json';
}
