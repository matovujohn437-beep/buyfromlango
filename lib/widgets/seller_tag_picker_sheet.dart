import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seller_tag.dart';
import '../theme.dart';

Future<void> showSellerTagPicker({
  required BuildContext context,
  required String title,
  required List<SellerTag> selectedTags,
  required Future<void> Function(List<SellerTag> tags) onSave,
  required VoidCallback onSaved,
}) async {
  final selectedKeys = selectedTags.map((tag) => tag.key).toSet();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _SellerTagPickerSheet(
      title: title,
      initialKeys: selectedKeys,
      onSave: onSave,
    ),
  );
  if (saved == true) {
    onSaved();
  }
}

class _SellerTagPickerSheet extends ConsumerStatefulWidget {
  const _SellerTagPickerSheet({
    required this.title,
    required this.initialKeys,
    required this.onSave,
  });

  final String title;
  final Set<String> initialKeys;
  final Future<void> Function(List<SellerTag> tags) onSave;

  @override
  ConsumerState<_SellerTagPickerSheet> createState() =>
      _SellerTagPickerSheetState();
}

class _SellerTagPickerSheetState extends ConsumerState<_SellerTagPickerSheet> {
  late final Set<String> _selectedKeys = {...widget.initialKeys};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
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
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Choose tags visible only to you.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in SellerTag.all)
                  _TagChoiceChip(
                    tag: tag,
                    selected: _selectedKeys.contains(tag.key),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selectedKeys.add(tag.key);
                      } else {
                        _selectedKeys.remove(tag.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save tags'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final tags = SellerTag.all
          .where((tag) => _selectedKeys.contains(tag.key))
          .toList();
      await widget.onSave(tags);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save tags: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TagChoiceChip extends StatelessWidget {
  const _TagChoiceChip({
    required this.tag,
    required this.selected,
    required this.onSelected,
  });

  final SellerTag tag;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      avatar: Icon(tag.icon, size: 17, color: tag.foregroundColor),
      label: Text(tag.label),
      backgroundColor: tag.backgroundColor,
      selectedColor: tag.backgroundColor,
      checkmarkColor: tag.foregroundColor,
      side: BorderSide(
        color: selected ? tag.foregroundColor : tag.backgroundColor,
      ),
      labelStyle: TextStyle(
        color: tag.foregroundColor,
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class SellerTagPills extends StatelessWidget {
  const SellerTagPills({super.key, required this.tagKeys});

  final List<String> tagKeys;

  @override
  Widget build(BuildContext context) {
    final tags = tagKeys.map(SellerTag.byKey).whereType<SellerTag>().toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final tag in tags)
          Tooltip(
            message: tag.label,
            child: Chip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                tag.icon,
                size: 15,
                color: tag.foregroundColor,
              ),
              label: Text(tag.label),
              backgroundColor: tag.backgroundColor,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: tag.foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
