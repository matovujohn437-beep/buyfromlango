import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Orders'),
        bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 2),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/sign-in'),
            child: const Text('Sign in to view orders'),
          ),
        ),
      );
    }

    final orders = ref.watch(ordersProvider(user.id));
    return Scaffold(
      appBar: const CustomAppBar(title: 'Orders & Offers'),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 2),
      body: ResponsiveContent(
        maxWidth: 900,
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text('Could not load your orders: $error'),
          ),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text('Offers and orders will appear here.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) => _OrderCard(
                    order: items[index],
                    userId: user.id,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.userId});

  final OrderModel order;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeller = order.sellerId == userId;
    final profile = ref.watch(currentProfileProvider);
    final listing = ref.watch(listingDetailProvider(order.listingId));
    final shouldShowSmsStatus = order.status == 'accepted' &&
        ((isSeller && order.type != 'contact_request') ||
            (!isSeller && order.phoneRevealedBySeller));
    final smsStatus = shouldShowSmsStatus
        ? ref.watch(sellerPhoneSmsStatusProvider(order.id))
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: listing.when(
                    data: (item) => Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    loading: () => Text(
                      'Listing #${order.listingId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    error: (_, __) => Text(
                      'Listing #${order.listingId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                _OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              switch (order.type) {
                'contact_request' => 'Contact request',
                'order' => 'Buy now order',
                _ => 'Offer',
              },
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (order.type == 'contact_request')
              Text(
                isSeller
                    ? order.phoneRevealedBySeller
                        ? 'Your phone number has been shared with the buyer.'
                        : 'The buyer requested your contact details. Your phone number stays private until you accept.'
                    : order.phoneRevealedBySeller
                        ? 'The seller shared their phone number with you.'
                        : 'Your request was sent. The seller’s phone number stays private until they accept.',
              )
            else
              Text(
                '${isSeller ? 'Buyer offer' : 'Your offer'}: '
                '${order.agreedPriceUgx == null ? 'Price negotiable' : 'UGX ${order.agreedPriceUgx!.toStringAsFixed(0)}'}'
                '${order.agreedQuantity?.trim().isNotEmpty == true ? ' · ${order.agreedQuantity}' : ''}',
              ),
            if (order.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(order.notes!),
            ],
            if (smsStatus != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                smsStatus.when(
                  data: (status) => switch (status) {
                    'sent' => 'Seller contact SMS sent to the buyer.',
                    'queued' ||
                    'processing' =>
                      'Seller contact SMS is being sent.',
                    'failed' => 'SMS delivery failed. You can retry.',
                    _ => 'Contact details remain private until sent by SMS.',
                  },
                  loading: () =>
                      'Contact details remain private until sent by SMS.',
                  error: (_, __) => 'Could not load SMS delivery status.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (isSeller &&
                    order.type == 'contact_request' &&
                    order.status == 'negotiating')
                  FilledButton.icon(
                    onPressed: order.editCount >= 1
                        ? null
                        : () => _acceptContactRequest(context, ref, order),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Accept & Reveal Phone'),
                  ),
                if (isSeller &&
                    order.type != 'contact_request' &&
                    (order.status == 'negotiating' ||
                        order.status == 'agreed')) ...[
                  FilledButton.tonal(
                    onPressed: order.editCount >= 1
                        ? null
                        : () => _changeStatus(
                              context,
                              ref,
                              order,
                              'accepted',
                            ),
                    child: const Text('Accept'),
                  ),
                  OutlinedButton(
                    onPressed: order.editCount >= 1
                        ? null
                        : () => _changeStatus(
                              context,
                              ref,
                              order,
                              'declined',
                            ),
                    child: const Text('Decline'),
                  ),
                  if (order.type == 'offer')
                    OutlinedButton.icon(
                      onPressed: order.editCount >= 1
                          ? null
                          : () => _counterOffer(context, ref, order),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Counter-offer'),
                    ),
                ],
                if (isSeller &&
                    order.status == 'accepted' &&
                    order.type != 'contact_request')
                  FilledButton.icon(
                    onPressed: smsStatus?.valueOrNull == 'sent'
                        ? null
                        : () => _requestPhoneSms(context, ref, order.id),
                    icon: const Icon(Icons.sms_outlined),
                    label: Text(
                      smsStatus?.valueOrNull == 'sent'
                          ? 'Number sent by SMS'
                          : 'Send number by SMS',
                    ),
                  ),
                if (!isSeller &&
                    order.type != 'contact_request' &&
                    order.status == 'negotiating')
                  OutlinedButton(
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      order,
                      'cancelled',
                    ),
                    child: const Text('Cancel offer'),
                  ),
                if (!isSeller &&
                    order.type == 'offer' &&
                    order.editCount > 0 &&
                    order.status == 'negotiating')
                  FilledButton.tonal(
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      order,
                      'accepted',
                    ),
                    child: const Text('Accept counter-offer'),
                  ),
                if (!isSeller &&
                    order.type == 'contact_request' &&
                    order.status == 'accepted' &&
                    order.phoneRevealedBySeller) ...[
                  FilledButton.tonalIcon(
                    onPressed: () => _showRevealedPhone(context, ref, order.id),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('View seller contact'),
                  ),
                  if (profile.valueOrNull?.isFeaturePhoneUser == true)
                    OutlinedButton.icon(
                      onPressed: smsStatus?.valueOrNull == 'sent'
                          ? null
                          : () => _requestPhoneSms(context, ref, order.id),
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(
                        smsStatus?.valueOrNull == 'sent'
                            ? 'Number sent by SMS'
                            : 'Send number by SMS',
                      ),
                    ),
                ],
                if (!isSeller && order.status == 'accepted')
                  FilledButton.tonal(
                    onPressed: () => _changeStatus(
                      context,
                      ref,
                      order,
                      'completed',
                    ),
                    child: const Text('Mark completed'),
                  ),
                if (isSeller &&
                    order.editCount >= 1 &&
                    (order.status == 'negotiating' || order.status == 'agreed'))
                  const Text('This order has already been updated once.'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String status,
  ) async {
    if (order.sellerId == userId) {
      final confirmed = await _confirmSellerUpdate(context);
      if (confirmed != true) return;
    }
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(order.id, status);
      ref.invalidate(ordersProvider(userId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update offer: $error')),
        );
      }
    }
  }

  Future<bool?> _confirmSellerUpdate(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm order update'),
        content: const Text(
          'You can only update an order once. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _counterOffer(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final values = await showDialog<(num, String?)>(
      context: context,
      builder: (dialogContext) => _CounterOfferDialog(order: order),
    );
    if (values == null || !context.mounted) return;
    if (await _confirmSellerUpdate(context) != true) return;
    try {
      await ref.read(orderServiceProvider).updateOrderTerms(
            orderId: order.id,
            priceUgx: values.$1,
            quantity: values.$2,
          );
      ref.invalidate(ordersProvider(userId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send counter-offer: $error')),
        );
      }
    }
  }

  Future<void> _acceptContactRequest(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    if (await _confirmSellerUpdate(context) != true) return;
    try {
      await ref.read(orderServiceProvider).acceptContactRequest(order.id);
      ref.invalidate(ordersProvider(userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number shared with the buyer.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reveal phone number: $error')),
        );
      }
    }
  }

  Future<void> _showRevealedPhone(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    try {
      final phone =
          await ref.read(orderServiceProvider).getRevealedSellerPhone(orderId);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Seller contact'),
          content: SelectableText(phone),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load seller contact: $error')),
        );
      }
    }
  }

  Future<void> _requestPhoneSms(
    BuildContext context,
    WidgetRef ref,
    int orderId,
  ) async {
    try {
      await ref.read(orderServiceProvider).requestSellerPhoneSms(orderId);
      ref.invalidate(sellerPhoneSmsStatusProvider(orderId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller contact will be sent by SMS after delivery.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not request SMS delivery: $error')),
        );
      }
    }
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status[0].toUpperCase() + status.substring(1)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CounterOfferDialog extends StatefulWidget {
  const _CounterOfferDialog({required this.order});

  final OrderModel order;

  @override
  State<_CounterOfferDialog> createState() => _CounterOfferDialogState();
}

class _CounterOfferDialogState extends State<_CounterOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.order.agreedPriceUgx?.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.order.agreedQuantity ?? '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Counter-offer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (UGX)'),
              validator: (value) {
                final price = num.tryParse(value?.trim() ?? '');
                return price == null || price <= 0
                    ? 'Enter a price greater than zero.'
                    : null;
              },
            ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              (
                num.parse(_priceController.text.trim()),
                _quantityController.text.trim().isEmpty
                    ? null
                    : _quantityController.text.trim(),
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
