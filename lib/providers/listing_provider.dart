import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/listing.dart';
import '../models/profile.dart';
import '../services/listing_service.dart';

final listingServiceProvider =
    Provider<ListingService>((ref) => ListingService());

final featuredListingsProvider = FutureProvider<List<ListingModel>>((ref) {
  return ref.watch(listingServiceProvider).getFeaturedListings();
});

final listingsProvider = FutureProvider<List<ListingModel>>((ref) {
  return ref
      .watch(listingServiceProvider)
      .getListings()
      .then((result) => result.listings);
});

final listingDetailProvider =
    FutureProvider.family<ListingModel, int>((ref, listingId) {
  return ref.watch(listingServiceProvider).getListingById(listingId);
});

final listingMediaProvider =
    FutureProvider.family<List<ListingMediaModel>, int>((ref, listingId) {
  return ref.watch(listingServiceProvider).getListingMedia(listingId);
});

final listingSellerProvider =
    FutureProvider.family<ProfileModel?, String>((ref, userId) {
  return ref.watch(listingServiceProvider).getSellerProfile(userId);
});

final sellerCatalogProfileProvider =
    FutureProvider.autoDispose.family<ProfileModel?, String>((ref, userId) {
  return ref.watch(listingServiceProvider).getSellerCatalogProfile(userId);
});

final sellerCatalogListingsProvider =
    FutureProvider.autoDispose.family<List<ListingModel>, String>(
  (ref, userId) {
    return ref.watch(listingServiceProvider).getSellerCatalogListings(userId);
  },
);

final profileListingsProvider =
    FutureProvider.autoDispose.family<List<ListingModel>, String>(
  (ref, userId) {
    return ref.watch(listingServiceProvider).getMyActiveListings(userId);
  },
);

class ListingFeedState {
  const ListingFeedState({
    this.listings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isShowingCachedData = false,
    this.categoryId,
    this.searchQuery = '',
    this.districtId,
    this.subcountyId,
    this.parishId,
    this.error,
  });

  final List<ListingModel> listings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isShowingCachedData;
  final String? categoryId;
  final String searchQuery;
  final int? districtId;
  final int? subcountyId;
  final int? parishId;
  final Object? error;

  List<ListingModel> get filteredListings {
    return listings;
  }

  ListingFeedState copyWith({
    List<ListingModel>? listings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isShowingCachedData,
    String? categoryId,
    bool clearCategory = false,
    String? searchQuery,
    int? districtId,
    bool clearDistrict = false,
    int? subcountyId,
    bool clearSubcounty = false,
    int? parishId,
    bool clearParish = false,
    Object? error,
    bool clearError = false,
  }) {
    return ListingFeedState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isShowingCachedData: isShowingCachedData ?? this.isShowingCachedData,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      districtId: clearDistrict ? null : districtId ?? this.districtId,
      subcountyId: clearSubcounty ? null : subcountyId ?? this.subcountyId,
      parishId: clearParish ? null : parishId ?? this.parishId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ListingFeedController extends StateNotifier<ListingFeedState> {
  ListingFeedController(this._service, {String? categoryId})
      : super(ListingFeedState(categoryId: categoryId)) {
    loadNextPage();
  }

  static const int _pageSize = 20;
  final ListingService _service;
  int _offset = 0;
  int _generation = 0;
  bool _requestInFlight = false;
  Timer? _searchDebounce;

  void setCategory(String? categoryId) {
    if (state.categoryId == categoryId) return;
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
    refresh();
  }

  void setLocationFilters({
    int? districtId,
    bool clearDistrict = false,
    int? subcountyId,
    bool clearSubcounty = false,
    int? parishId,
    bool clearParish = false,
  }) {
    final nextDistrictId =
        clearDistrict ? null : districtId ?? state.districtId;
    final nextSubcountyId =
        clearSubcounty ? null : subcountyId ?? state.subcountyId;
    final nextParishId = clearParish ? null : parishId ?? state.parishId;
    if (nextDistrictId == state.districtId &&
        nextSubcountyId == state.subcountyId &&
        nextParishId == state.parishId) {
      return;
    }
    state = state.copyWith(
      districtId: districtId,
      clearDistrict: clearDistrict,
      subcountyId: subcountyId,
      clearSubcounty: clearSubcounty,
      parishId: parishId,
      clearParish: clearParish,
    );
    refresh();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), refresh);
  }

  void cancelPendingSearch() {
    _searchDebounce?.cancel();
  }

  Future<void> refresh() async {
    _generation++;
    _offset = 0;
    state = state.copyWith(
      listings: const [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      isShowingCachedData: false,
      clearError: true,
    );
    await _loadPage(_generation);
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || _requestInFlight) return;
    state = state.copyWith(
      isLoading: state.listings.isEmpty,
      isLoadingMore: state.listings.isNotEmpty,
      clearError: true,
    );
    await _loadPage(_generation);
  }

  Future<void> _loadPage(int generation) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final categoryId = state.categoryId;
    final searchQuery = state.searchQuery;
    final districtId = state.districtId;
    final subcountyId = state.subcountyId;
    final parishId = state.parishId;
    try {
      final page = await _service.getListings(
        limit: _pageSize,
        offset: _offset,
        categoryId: categoryId,
        searchQuery: searchQuery,
        districtId: districtId,
        subcountyId: subcountyId,
        parishId: parishId,
      );
      if (generation != _generation || !mounted) return;
      _offset += page.listings.length;
      state = state.copyWith(
        listings: [...state.listings, ...page.listings],
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.listings.length == _pageSize,
        isShowingCachedData: page.isFromCache,
        clearError: true,
      );
    } catch (error) {
      if (generation != _generation || !mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    } finally {
      _requestInFlight = false;
      if (mounted && generation != _generation) {
        loadNextPage();
      }
    }
  }
}

final listingFeedProvider =
    StateNotifierProvider<ListingFeedController, ListingFeedState>((ref) {
  final controller = ListingFeedController(ref.watch(listingServiceProvider));
  ref.onDispose(controller.cancelPendingSearch);
  return controller;
});

final categoryListingFeedProvider = StateNotifierProvider.family<
    ListingFeedController, ListingFeedState, String>((ref, categoryId) {
  final controller = ListingFeedController(
    ref.watch(listingServiceProvider),
    categoryId: categoryId,
  );
  ref.onDispose(controller.cancelPendingSearch);
  return controller;
});
