import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/listing_provider.dart';
import 'create_listing_screen.dart';

class EditListingScreen extends ConsumerWidget {
  const EditListingScreen({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingDetailProvider(listingId));
    return listing.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit listing')),
        body: Center(child: Text('Could not load listing: $error')),
      ),
      data: (value) => CreateListingScreen(listing: value),
    );
  }
}
