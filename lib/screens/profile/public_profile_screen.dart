import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../models/review.dart';
import '../../providers/listing_provider.dart';
import '../../providers/review_provider.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(listingSellerProvider(widget.profileId));
    final reviews = ref.watch(sellerReviewsProvider(widget.profileId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Could not load profile: $error'),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('This profile is unavailable.'));
          }
          return _PublicProfileContent(
            profile: user,
            reviews: reviews,
            canReview: currentUserId != user.id,
            onLeaveReview: () => _leaveReview(user),
          );
        },
      ),
    );
  }

  Future<void> _leaveReview(ProfileModel profile) async {
    final reviewerId = Supabase.instance.client.auth.currentUser?.id;
    if (reviewerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review.')),
      );
      if (mounted) context.push('/sign-in');
      return;
    }

    var rating = 5;
    final commentController = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    tooltip: '${index + 1} stars',
                    onPressed: () => setDialogState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'submit'),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (comment != 'submit') {
      commentController.dispose();
      return;
    }

    try {
      await ref.read(reviewServiceProvider).createReview(
            reviewerId: reviewerId,
            sellerId: profile.id,
            rating: rating,
            comment: commentController.text,
          );
      ref.invalidate(sellerReviewsProvider(profile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit review: $error')),
        );
      }
    } finally {
      commentController.dispose();
    }
  }
}

class _PublicProfileContent extends StatelessWidget {
  const _PublicProfileContent({
    required this.profile,
    required this.reviews,
    required this.canReview,
    required this.onLeaveReview,
  });

  final ProfileModel profile;
  final AsyncValue<List<ReviewModel>> reviews;
  final bool canReview;
  final VoidCallback onLeaveReview;

  @override
  Widget build(BuildContext context) {
    final profileName = profile.isAnonymous
        ? 'Anonymous user'
        : profile.fullName?.trim().isNotEmpty == true
            ? profile.fullName!.trim()
            : 'Name not provided';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                ProfileAvatar(
                  imageUrl: profile.isAnonymous ? null : profile.avatarUrl,
                  radius: 42,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(profileName,
                    style: Theme.of(context).textTheme.titleLarge),
                if (profile.isVerified) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: AppColors.success, size: 18),
                      SizedBox(width: AppSpacing.xs),
                      Text('Verified'),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.accountType.toLowerCase() == 'cooperative'
                      ? 'Co-op'
                      : 'Individual',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Chip(
                  avatar: Icon(
                    profile.isFeaturePhoneUser
                        ? Icons.sms_outlined
                        : Icons.smartphone_outlined,
                  ),
                  label: Text(
                    profile.isFeaturePhoneUser ? 'SMS User' : 'App User',
                  ),
                ),
                if (profile.bio?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(profile.bio!.trim(), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Reviews',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            if (canReview)
              FilledButton.tonal(
                onPressed: onLeaveReview,
                child: const Text('Leave a Review'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Could not load reviews: $error'),
          data: (items) {
            if (items.isEmpty) return const Text('No reviews yet.');
            final average =
                items.fold<int>(0, (total, review) => total + review.rating) /
                    items.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${average.toStringAsFixed(1)} · ${items.length} ${items.length == 1 ? 'review' : 'reviews'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((review) => _ReviewCard(review: review)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final submitted = review.createdAt == null
        ? null
        : '${review.createdAt!.year}-${review.createdAt!.month.toString().padLeft(2, '0')}-${review.createdAt!.day.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 18,
                    color: Colors.amber,
                  ),
                ),
                if (submitted != null) ...[
                  const Spacer(),
                  Text(submitted, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
            if (review.comment?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(review.comment!.trim()),
            ],
          ],
        ),
      ),
    );
  }
}
