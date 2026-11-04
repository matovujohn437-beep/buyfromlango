import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/district.dart';
import '../../models/listing.dart';
import '../../models/parish.dart';
import '../../models/profile.dart';
import '../../models/seller_tag.dart';
import '../../models/subcounty.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/seller_tools_provider.dart';
import '../../supabase_config.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/seller_tag_picker_sheet.dart';
import '../../widgets/smart_responses_sheet.dart';

final profileDashboardStatsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, userId) async {
  final client = SupabaseConfig.client;
  final userOrdersFilter = 'buyer_id.eq.$userId,seller_id.eq.$userId';
  final counts = await Future.wait<int>([
    client.from('listings').count(CountOption.exact).eq('user_id', userId),
    client
        .from('orders')
        .count(CountOption.exact)
        .eq('status', 'negotiating')
        .or(userOrdersFilter),
    client.from('orders').count(CountOption.exact).or(userOrdersFilter),
  ]);

  return {
    'listings': counts[0],
    'offers': counts[1],
    'orders': counts[2],
  };
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'My Profile'),
        bottomNavigationBar: MarketplaceNavigationBar(selectedIndex: 2),
        body: Center(child: Text('Sign in to view your profile.')),
      );
    }

    final profile = ref.watch(currentProfileProvider);
    final stats = ref.watch(profileDashboardStatsProvider(user.id));
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Profile'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 2),
      body: ResponsiveContent(
        maxWidth: 900,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileError(
            message: 'Could not load your profile: $error',
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (value) => _ProfileContent(
            userId: user.id,
            userEmail: user.email,
            profile: value ?? ProfileModel(id: user.id),
            stats: stats,
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({
    required this.userId,
    required this.userEmail,
    required this.profile,
    required this.stats,
  });

  final String userId;
  final String? userEmail;
  final ProfileModel profile;
  final AsyncValue<Map<String, int>> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = profile.fullName?.trim();
    final displayName = name == null || name.isEmpty ? 'Name not set' : name;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      ProfileAvatar(imageUrl: profile.avatarUrl, radius: 48),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final saved = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _EditProfileSheet(
                              userId: userId,
                              profile: profile,
                            ),
                          );
                          if (saved == true) {
                            ref.invalidate(currentProfileProvider);
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Chip(
                        label: Text(
                          profile.accountType == 'cooperative'
                              ? 'Co-op'
                              : 'Individual',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const _VerifiedBadge(),
                      ],
                      if (profile.bio?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(profile.bio!, textAlign: TextAlign.center),
                      ],
                      if (profile.phone?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(profile.phone!),
                      ],
                      if (userEmail != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          userEmail!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Your activity',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              stats.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _ProfileError(
                  message: 'Could not load your activity: $error',
                  onRetry: () =>
                      ref.invalidate(profileDashboardStatsProvider(userId)),
                ),
                data: (values) => LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth < ResponsiveBreakpoints.compact
                            ? 2
                            : 3;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.92,
                      children: [
                        _ActivityCard(
                          icon: Icons.inventory_2_outlined,
                          label: 'Listings',
                          count: values['listings'] ?? 0,
                        ),
                        _ActivityCard(
                          icon: Icons.local_offer_outlined,
                          label: 'Offers',
                          count: values['offers'] ?? 0,
                        ),
                        _ActivityCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'Orders',
                          count: values['orders'] ?? 0,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => showSmartResponsesSheet(
                  context: context,
                  ref: ref,
                  userId: userId,
                  manage: true,
                  onSelected: (_) {},
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Smart Responses'),
              ),
              const SizedBox(height: AppSpacing.md),
              _MyListingsSection(userId: userId),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/orders');
                  if (context.mounted) {
                    ref.invalidate(profileDashboardStatsProvider(userId));
                  }
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View orders & offers'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _editItemVisibility(context, ref),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Privacy Settings'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Who can see your items: ${_visibilityLabel(profile.itemVisibility)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              if (profile.isAdmin) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin/reports'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Review user reports'),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/sign-in');
                  } catch (error) {
                    if (context.mounted) {
                      if (ref.read(authServiceProvider).currentUser == null) {
                        context.go('/sign-in');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(authServiceProvider).currentUser == null
                                ? 'You were signed out, but Google sign-out failed: $error'
                                : 'Could not sign out: $error',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Sign Out'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _visibilityLabel(String visibility) => switch (visibility) {
        'contacts' => 'Contacts only',
        'private' => 'Private',
        _ => 'Public',
      };

  Future<void> _editItemVisibility(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Who can see your items?'),
        children: [
          for (final (value, label, description) in const [
            ('public', 'Public', 'Anyone can see your items.'),
            (
              'contacts',
              'Contacts only',
              'People you have chatted with can see your items.',
            ),
            ('private', 'Private', 'Only you can see your items.'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(description),
                trailing: profile.itemVisibility == value
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == profile.itemVisibility) return;
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'item_visibility': selected}).eq('id', userId);
      ref.invalidate(listingFeedProvider);
      ref.invalidate(currentProfileProvider);
      try {
        await ref.read(listingServiceProvider).clearCachedListings();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Privacy settings were saved, but cached listings could not be cleared: $error',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update privacy settings: $error')),
        );
      }
    }
  }
}

class _MyListingsSection extends ConsumerWidget {
  const _MyListingsSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(profileListingsProvider(userId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('My Listings', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        listings.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _ProfileError(
            message: 'Could not load your listings: $error',
            onRetry: () => ref.invalidate(profileListingsProvider(userId)),
          ),
          data: (items) => items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text('You have no active listings.'),
                )
              : Column(
                  children: [
                    for (final listing in items)
                      _MyListingTile(
                        listing: listing,
                        userId: userId,
                        onChanged: () {
                          ref
                            ..invalidate(profileListingsProvider(userId))
                            ..invalidate(profileDashboardStatsProvider(userId))
                            ..invalidate(listingFeedProvider)
                            ..invalidate(listingsProvider)
                            ..invalidate(listingDetailProvider(listing.id));
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MyListingTile extends ConsumerWidget {
  const _MyListingTile({
    required this.listing,
    required this.userId,
    required this.onChanged,
  });

  final ListingModel listing;
  final String userId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagKeys = ref.watch(listingTagKeysProvider((userId, listing.id)));
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title:
            Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.priceUgx == null
                  ? 'Price negotiable'
                  : 'UGX ${listing.priceUgx!.toStringAsFixed(0)}'
                      '${listing.quantity == null ? '' : ' · ${listing.quantity}'}'
                      '${listing.unit == null ? '' : ' ${listing.unit}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            tagKeys.when(
              loading: () => const SizedBox.shrink(),
              error: (error, _) => Text(
                'Tags unavailable',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
              ),
              data: (keys) => SellerTagPills(tagKeys: keys),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Listing actions',
          onSelected: (action) async {
            switch (action) {
              case 'edit':
                final updated = await context.push<bool>(
                  '/listing/${listing.id}/edit',
                );
                if (updated == true) onChanged();
              case 'delete':
                await _confirmDelete(context, ref);
              case 'privacy':
                await _updatePrivacy(context, ref);
              case 'tags':
                await _manageTags(context, ref);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'tags',
              child: ListTile(
                leading: Icon(Icons.sell_outlined),
                title: Text('Manage tags'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'privacy',
              child: ListTile(
                leading: Icon(Icons.visibility_outlined),
                title: Text('Privacy'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/listing/${listing.id}'),
      ),
    );
  }

  Future<void> _manageTags(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(sellerToolsServiceProvider);
      final keys = await service.getListingTagKeys(
        userId: userId,
        listingId: listing.id,
      );
      if (!context.mounted) return;
      await showSellerTagPicker(
        context: context,
        title: 'Tag this listing',
        selectedTags: keys.map(SellerTag.byKey).whereType<SellerTag>().toList(),
        onSave: (tags) => service.setListingTags(
          listingId: listing.id,
          tags: tags,
        ),
        onSaved: () => ref.invalidate(
          listingTagKeysProvider((userId, listing.id)),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load listing tags: $error')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text(
          'Warning: You can only delete a listing once. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await ref.read(listingServiceProvider).removeListing(listing.id);
      onChanged();
      try {
        await ref.read(listingServiceProvider).clearCachedListings();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Listing deleted, but offline listings could not be cleared: $error',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete listing: $error')),
        );
      }
    }
  }

  Future<void> _updatePrivacy(BuildContext context, WidgetRef ref) async {
    final privacy = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Listing privacy'),
        children: [
          RadioGroup<String>(
            groupValue: listing.privacy,
            onChanged: (selected) => Navigator.pop(context, selected),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (value, label) in const [
                  ('public', 'Public'),
                  ('contacts', 'Contacts Only'),
                  ('private', 'Private'),
                ])
                  RadioListTile<String>(
                    value: value,
                    title: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (privacy == null || privacy == listing.privacy) return;
    try {
      await ref
          .read(listingServiceProvider)
          .updateListing(listing.id, {'privacy': privacy});
      onChanged();
      try {
        await ref.read(listingServiceProvider).clearCachedListings();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Privacy was saved, but offline listings could not be cleared: $error',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update listing privacy: $error')),
        );
      }
    }
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.userId, required this.profile});

  final String userId;
  final ProfileModel profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  int? _districtId;
  int? _subcountyId;
  int? _parishId;
  Uint8List? _avatarBytes;
  String? _avatarExtension;
  bool _isSaving = false;
  late String _accountType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _bioController = TextEditingController(text: widget.profile.bio);
    _accountType = widget.profile.accountType;
    _districtId = widget.profile.districtId;
    _subcountyId = widget.profile.subcountyId;
    _parishId = widget.profile.parishId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districts = ref.watch(districtsProvider);
    final subcounties = _districtId == null
        ? null
        : ref.watch(subcountiesProvider(_districtId!));
    final parishes = _subcountyId == null
        ? null
        : ref.watch(parishesProvider(_subcountyId!));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          bottomInset + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit profile',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      if (_avatarBytes != null)
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: MemoryImage(_avatarBytes!),
                        )
                      else
                        ProfileAvatar(
                            imageUrl: widget.profile.avatarUrl, radius: 46),
                      IconButton.filled(
                        tooltip: 'Change profile photo',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accentDark,
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          elevation: 4,
                        ),
                        onPressed: _isSaving ? null : _pickAvatar,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) =>
                      value?.trim().isEmpty ?? true ? 'Enter your name.' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) {
                    final phone =
                        value?.replaceAll(RegExp(r'[\s()-]'), '') ?? '';
                    return phone.isEmpty ||
                            RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)
                        ? null
                        : 'Enter a valid phone number.';
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'About you'),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _accountType,
                  decoration: const InputDecoration(labelText: 'Account type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'individual',
                      child: Text('Individual'),
                    ),
                    DropdownMenuItem(
                      value: 'cooperative',
                      child: Text('Co-op'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _accountType = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _LocationDropdown<District>(
                  label: 'District',
                  value: _districtId,
                  entries: districts,
                  idOf: (item) => item.id,
                  nameOf: (item) => item.name,
                  onChanged: (value) => setState(() {
                    _districtId = value;
                    _subcountyId = null;
                    _parishId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _LocationDropdown<Subcounty>(
                  label: 'Subcounty',
                  value: _subcountyId,
                  entries: subcounties,
                  enabled: _districtId != null,
                  idOf: (item) => item.id,
                  nameOf: (item) => item.name,
                  onChanged: (value) => setState(() {
                    _subcountyId = value;
                    _parishId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                _LocationDropdown<Parish>(
                  label: 'Parish',
                  value: _parishId,
                  entries: parishes,
                  enabled: _subcountyId != null,
                  idOf: (item) => item.id,
                  nameOf: (item) => item.name,
                  onChanged: (value) => setState(() => _parishId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        throw const FormatException('Choose a JPG, PNG, or WebP image.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 5 MB.');
      }
      if (mounted) {
        setState(() {
          _avatarBytes = bytes;
          _avatarExtension = extension;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select profile photo: $error')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      var avatarUrl = widget.profile.avatarUrl;
      if (_avatarBytes != null && _avatarExtension != null) {
        final storage = SupabaseConfig.client.storage.from('profile-avatars');
        final path =
            '${widget.userId}/${DateTime.now().microsecondsSinceEpoch}.$_avatarExtension';
        await storage.uploadBinary(
          path,
          _avatarBytes!,
          fileOptions: FileOptions(
            contentType: switch (_avatarExtension) {
              'png' => 'image/png',
              'webp' => 'image/webp',
              _ => 'image/jpeg',
            },
          ),
        );
        avatarUrl = storage.getPublicUrl(path);
      }

      final fullName = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      await SupabaseConfig.client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'account_type': _accountType,
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'avatar_url': avatarUrl,
        'district_id': _districtId,
        'subcounty_id': _subcountyId,
        'parish_id': _parishId,
      }).eq('id', widget.userId);

      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'phone': phone,
            'avatar_url': avatarUrl
          },
        ),
      );
      ref.invalidate(currentProfileProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update your profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _LocationDropdown<T> extends StatelessWidget {
  const _LocationDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.idOf,
    required this.nameOf,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final int? value;
  final AsyncValue<List<T>>? entries;
  final int Function(T item) idOf;
  final String Function(T item) nameOf;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final items = entries?.valueOrNull;
    final selected =
        items?.any((item) => idOf(item) == value) == true ? value : null;
    return DropdownButtonFormField<int>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        errorText:
            entries?.hasError == true ? 'Could not load $label options.' : null,
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Choose')),
        if (items != null)
          for (final item in items)
            DropdownMenuItem<int>(value: idOf(item), child: Text(nameOf(item))),
      ],
      onChanged: enabled && entries?.hasError != true ? onChanged : null,
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Verified',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
