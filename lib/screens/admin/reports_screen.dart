import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../supabase_config.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';

final moderationReportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await SupabaseConfig.client
      .from('reports')
      .select()
      .order('created_at', ascending: false)
      .limit(100);
  return (response as List<dynamic>)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Moderation Reports'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 2),
      body: ResponsiveContent(
        maxWidth: 900,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ReportsError(
            message: 'Could not verify moderation access: $error',
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (value) {
            if (user == null || value?.isAdmin != true) {
              return const Center(
                child: Text('You do not have access to moderation reports.'),
              );
            }
            final reports = ref.watch(moderationReportsProvider);
            return reports.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ReportsError(
                message: 'Could not load reports: $error',
                onRetry: () => ref.invalidate(moderationReportsProvider),
              ),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('There are no user reports.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _ReportCard(
                        report: items[index],
                        onUpdated: () =>
                            ref.invalidate(moderationReportsProvider),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onUpdated});

  final Map<String, dynamic> report;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(report['created_at']?.toString() ?? '');
    final status = report['status']?.toString() ?? 'open';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report['reason']?.toString() ?? 'Report',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Update report status',
                  onSelected: (nextStatus) =>
                      _updateStatus(context, nextStatus),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'reviewing', child: Text('Reviewing')),
                    PopupMenuItem(value: 'resolved', child: Text('Resolved')),
                    PopupMenuItem(value: 'dismissed', child: Text('Dismissed')),
                  ],
                  child: Chip(label: Text(status)),
                ),
              ],
            ),
            if (report['details']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(report['details'].toString()),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                if (report['target_listing_id'] != null)
                  'Listing #${report['target_listing_id']}',
                if (report['target_user_id'] != null)
                  'Account ${report['target_user_id']}',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reported by ${report['reporter_id'] ?? 'Unknown'}'
              '${createdAt == null ? '' : ' · ${createdAt.toLocal()}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (report['target_listing_id'] != null &&
                status != 'resolved' &&
                status != 'dismissed') ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _hideReportedListing(context),
                icon: const Icon(Icons.visibility_off_outlined),
                label: const Text('Hide reported listing'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final reportId = report['id'];
    try {
      await SupabaseConfig.client.from('reports').update({
        'status': status,
        'resolved_at': status == 'resolved' || status == 'dismissed'
            ? DateTime.now().toUtc().toIso8601String()
            : null,
      }).eq('id', reportId);
      onUpdated();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update report: $error')),
        );
      }
    }
  }

  Future<void> _hideReportedListing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hide this listing?'),
        content: const Text(
          'The listing will no longer appear in public marketplace results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hide listing'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final listingId = report['target_listing_id'];
      await SupabaseConfig.client
          .from('listings')
          .update({'status': 'removed'})
          .eq('id', listingId)
          .select('id')
          .single();
      await SupabaseConfig.client.from('reports').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', report['id']);
      onUpdated();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not hide listing: $error')),
        );
      }
    }
  }
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.message, required this.onRetry});

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
