import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smart_response.dart';
import '../providers/seller_tools_provider.dart';
import '../theme.dart';

Future<void> showSmartResponsesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required ValueChanged<String> onSelected,
  bool manage = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SmartResponsesSheet(
      userId: userId,
      onSelected: onSelected,
      manage: manage,
    ),
  );
}

class SmartResponsesSheet extends ConsumerWidget {
  const SmartResponsesSheet({
    super.key,
    required this.userId,
    this.onSelected,
    this.manage = false,
  });

  final String userId;
  final ValueChanged<String>? onSelected;
  final bool manage;

  static const _suggestedResponses = [
    SmartResponseModel(
      id: -1,
      title: 'Welcome',
      content: 'Hello! Thanks for reaching out. How can I help you today?',
    ),
    SmartResponseModel(
      id: -2,
      title: 'Availability',
      content: 'Thanks for your interest. Let me confirm availability for you.',
    ),
    SmartResponseModel(
      id: -3,
      title: 'Arrange a visit',
      content: 'You are welcome to visit. What day and time works for you?',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(smartResponsesProvider(userId));
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    manage ? 'Your Smart Responses' : 'Smart Responses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (manage)
                  IconButton.filledTonal(
                    tooltip: 'Add a response',
                    onPressed: () => _editResponse(context, ref),
                    icon: const Icon(Icons.add),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            responses.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Could not load Smart Responses: $error'),
              ),
              data: (items) {
                final visibleResponses =
                    manage ? items : [...items, ..._suggestedResponses];
                return visibleResponses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'You haven’t created any Smart Responses yet. '
                              'Add one to make common messages easier to send.',
                              textAlign: TextAlign.center,
                            ),
                            if (manage) ...[
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => _editResponse(context, ref),
                                icon: const Icon(Icons.add),
                                label: const Text('Add New'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxListHeight),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: visibleResponses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => _ResponseCard(
                            response: visibleResponses[index],
                            manage: manage,
                            onSelected: onSelected,
                            onEdit: () => _editResponse(
                              context,
                              ref,
                              response: visibleResponses[index],
                            ),
                            onDelete: () => _deleteResponse(
                              context,
                              ref,
                              visibleResponses[index],
                            ),
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editResponse(
    BuildContext context,
    WidgetRef ref, {
    SmartResponseModel? response,
  }) async {
    final titleController = TextEditingController(text: response?.title);
    final contentController = TextEditingController(text: response?.content);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(response == null ? 'Add a response' : 'Edit response'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Short title'),
                validator: (value) =>
                    value?.trim().isNotEmpty == true ? null : 'Enter a title.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: contentController,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Message to send'),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : 'Enter a message.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ref.read(sellerToolsServiceProvider).saveSmartResponse(
              userId: userId,
              id: response?.id,
              title: titleController.text,
              content: contentController.text,
            );
        ref.invalidate(smartResponsesProvider(userId));
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save response: $error')),
          );
        }
      }
    }
    titleController.dispose();
    contentController.dispose();
  }

  Future<void> _deleteResponse(
    BuildContext context,
    WidgetRef ref,
    SmartResponseModel response,
  ) async {
    try {
      await ref.read(sellerToolsServiceProvider).deleteSmartResponse(
            userId: userId,
            id: response.id,
          );
      ref.invalidate(smartResponsesProvider(userId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete response: $error')),
        );
      }
    }
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.manage,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final SmartResponseModel response;
  final bool manage;
  final ValueChanged<String>? onSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceVariant,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: manage
            ? onEdit
            : () {
                onSelected?.call(response.content);
                Navigator.pop(context);
              },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.primaryDark,
                child: Icon(Icons.chat_bubble_outline_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      response.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (manage) ...[
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ] else ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.north_west_rounded, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
