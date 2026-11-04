import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/district.dart';
import '../models/parish.dart';
import '../models/subcounty.dart';
import '../providers/location_provider.dart';
import '../theme.dart';

class ListingLocationFilters extends ConsumerWidget {
  const ListingLocationFilters({
    super.key,
    required this.districtId,
    required this.subcountyId,
    required this.parishId,
    required this.onDistrictChanged,
    required this.onSubcountyChanged,
    required this.onParishChanged,
  });

  final int? districtId;
  final int? subcountyId;
  final int? parishId;
  final ValueChanged<int?> onDistrictChanged;
  final ValueChanged<int?> onSubcountyChanged;
  final ValueChanged<int?> onParishChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districts = ref.watch(districtsProvider);
    final subcounties =
        districtId == null ? null : ref.watch(subcountiesProvider(districtId!));
    final parishes =
        subcountyId == null ? null : ref.watch(parishesProvider(subcountyId!));

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: ExpansionTile(
        visualDensity: const VisualDensity(vertical: -3),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        leading: const Icon(Icons.tune, color: AppColors.primary),
        title: const Text('Filter by location'),
        subtitle: Text(
          parishId != null
              ? 'Ward selected'
              : subcountyId != null
                  ? 'Subcounty selected'
                  : districtId != null
                      ? 'District selected'
                      : 'Choose a district, subcounty, or ward',
        ),
        children: [
          _LocationDropdown<District>(
            key: ValueKey('district-$districtId'),
            label: 'District',
            value: districtId,
            entries: districts,
            idOf: (district) => district.id,
            nameOf: (district) => district.name,
            onChanged: onDistrictChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LocationDropdown<Subcounty>(
            key: ValueKey('subcounty-$districtId-$subcountyId'),
            label: 'Subcounty',
            value: subcountyId,
            entries: subcounties,
            enabled: districtId != null,
            idOf: (subcounty) => subcounty.id,
            nameOf: (subcounty) => subcounty.name,
            onChanged: onSubcountyChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LocationDropdown<Parish>(
            key: ValueKey('ward-$subcountyId-$parishId'),
            label: 'Ward / Parish',
            value: parishId,
            entries: parishes,
            enabled: subcountyId != null,
            idOf: (parish) => parish.id,
            nameOf: (parish) => parish.name,
            onChanged: onParishChanged,
          ),
        ],
      ),
    );
  }
}

class _LocationDropdown<T> extends StatelessWidget {
  const _LocationDropdown({
    super.key,
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
    final currentValue =
        items?.any((item) => idOf(item) == value) == true ? value : null;

    return DropdownButtonFormField<int>(
      initialValue: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        suffixIcon: entries?.isLoading == true
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : entries?.hasError == true
                ? const Icon(Icons.error_outline)
                : null,
        helperText: entries?.hasError == true
            ? 'Could not load options: ${entries?.error}'
            : null,
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Any'),
        ),
        if (items != null)
          for (final item in items)
            DropdownMenuItem<int>(
              value: idOf(item),
              child: Text(nameOf(item)),
            ),
      ],
      onChanged: enabled && entries?.hasError != true ? onChanged : null,
    );
  }
}
