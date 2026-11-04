import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_assets.dart';
import '../../constants/listing_units.dart';
import '../../constants/product_catalog.dart';
import '../../models/category.dart';
import '../../models/district.dart';
import '../../models/parish.dart';
import '../../models/profile.dart';
import '../../models/subcounty.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buyer_need_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/responsive_layout.dart';

class CreateBuyerNeedScreen extends ConsumerStatefulWidget {
  const CreateBuyerNeedScreen({super.key});

  @override
  ConsumerState<CreateBuyerNeedScreen> createState() =>
      _CreateBuyerNeedScreenState();
}

class _CreateBuyerNeedScreenState extends ConsumerState<CreateBuyerNeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  XFile? _itemImage;
  Uint8List? _itemImageBytes;

  int? _districtId;
  int? _subcountyId;
  int? _parishId;
  String? _categoryId = 'crops';
  String? _selectedItem;
  String? _selectedUnit;
  String? _initializedProfile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(currentProfileProvider);
    final districts = ref.watch(districtsProvider);
    final categories = ref.watch(categoriesProvider);
    final profileValue = profile.valueOrNull;
    if (profileValue != null && _initializedProfile != profileValue.id) {
      _initializeFromProfile(profileValue);
    }
    final subcounties = _districtId == null
        ? null
        : ref.watch(subcountiesProvider(_districtId!));
    final parishes = _subcountyId == null
        ? null
        : ref.watch(parishesProvider(_subcountyId!));

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to post a buyer demand.')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Post a Buyer Demand',
      ),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 3),
      body: ResponsiveContent(
        maxWidth: 720,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Tell local sellers what you need.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'We could not load product categories. Please try again later.',
                ),
                data: _categoryDropdown,
              ),
              const SizedBox(height: AppSpacing.md),
              _productDropdown(),
              const SizedBox(height: AppSpacing.md),
              _itemPhotoPicker(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'e.g. 5',
                      ),
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        final number = num.tryParse(input);
                        if (number == null || number <= 0) {
                          return 'Enter a quantity above zero.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: _unitDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Proposed price (UGX)',
                  hintText: 'Optional',
                ),
                validator: (value) {
                  final input = value?.trim() ?? '';
                  if (input.isEmpty) return null;
                  final price = num.tryParse(input);
                  return price == null || price < 0
                      ? 'Enter a valid price.'
                      : null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Additional details',
                  hintText: 'Quality, delivery date, or other requirements',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Contact details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              profile.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'We could not load your saved profile details. Enter '
                  'your contact details below.',
                ),
                data: (_) => const SizedBox.shrink(),
              ),
              TextFormField(
                controller: _contactController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Contact person'),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Enter a contact person.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+256 7XX XXX XXX',
                ),
                validator: (value) {
                  final phone = value?.replaceAll(RegExp(r'[\s()-]'), '') ?? '';
                  return RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)
                      ? null
                      : 'Enter a valid phone number.';
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Collection location',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.sm),
              _LocationDropdown<Parish>(
                label: 'Ward / Parish',
                value: _parishId,
                entries: parishes,
                enabled: _subcountyId != null,
                idOf: (item) => item.id,
                nameOf: (item) => item.name,
                onChanged: (value) => setState(() => _parishId = value),
              ),
              if (_districtId == null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Choose a district so nearby sellers can find your demand.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publish buyer demand'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryDropdown(List<Category> categories) {
    if (categories.isEmpty) {
      return const Text('No product categories are currently available.');
    }
    final selectedId = categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : categories.first.id;
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        for (final category in categories)
          DropdownMenuItem(
            value: category.id,
            child: Text(category.labelEn),
          ),
      ],
      onChanged: (value) => setState(() {
        _categoryId = value;
        if (!productItemsForCategory(value).contains(_selectedItem)) {
          _selectedItem = null;
        }
        if (!listingUnitsForCategory(value).contains(_selectedUnit)) {
          _selectedUnit = null;
        }
      }),
      validator: (_) => selectedId == null ? 'Choose a category.' : null,
    );
  }

  Widget _productDropdown() {
    final items = productItemsForCategory(_categoryId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('demand-item-$_categoryId'),
          initialValue: items.contains(_selectedItem) ? _selectedItem : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Product or service'),
          hint: const Text('Choose an item'),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    ProductAvatar(
                      categoryId: _categoryId,
                      itemName: item,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedItem = value),
          validator: (value) => value == null || !items.contains(value)
              ? 'Choose an item.'
              : null,
        ),
        if (_selectedItem != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ProductAvatar(
                categoryId: _categoryId,
                itemName: _selectedItem,
                imageBytes: _itemImageBytes,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _selectedItem!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _unitDropdown() {
    final items = listingUnitsForCategory(_categoryId);
    return DropdownButtonFormField<String>(
      key: ValueKey('demand-unit-$_categoryId'),
      initialValue: items.contains(_selectedUnit) ? _selectedUnit : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Unit'),
      hint: const Text('Optional'),
      items: [
        for (final unit in items)
          DropdownMenuItem(value: unit, child: Text(unit)),
      ],
      onChanged: (value) => setState(() => _selectedUnit = value),
    );
  }

  Widget _itemPhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 190,
            child: _itemImageBytes == null
                ? Image.asset(
                    AppAssets.listingCrop,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.image_outlined, size: 48),
                    ),
                  )
                : Image.memory(
                    _itemImageBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.image_outlined, size: 48),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _pickItemPhoto(takePhoto: true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _pickItemPhoto(takePhoto: false),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Choose from Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickItemPhoto({required bool takePhoto}) async {
    try {
      final photo = await ImagePicker().pickImage(
        source: !kIsWeb && takePhoto ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (photo == null) return;
      final extension = photo.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        throw const FormatException('Choose a JPG, PNG, or WebP photo.');
      }
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) throw StateError('The selected photo is empty.');
      if (bytes.length > 10 * 1024 * 1024) {
        throw StateError('Choose a photo smaller than 10 MB.');
      }
      if (mounted) {
        setState(() {
          _itemImage = photo;
          _itemImageBytes = bytes;
        });
      }
    } catch (error) {
      if (mounted) {
        final message = switch (error) {
          FormatException(:final message) => message,
          StateError(:final message) => message,
          _ => 'We could not select the photo. Please try again.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _initializeFromProfile(ProfileModel profile) {
    _initializedProfile = profile.id;
    _contactController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';
    _districtId = profile.districtId;
    _subcountyId = profile.subcountyId;
    _parishId = profile.parishId;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    if (_categoryId == null ||
        !categories.any((category) => category.id == _categoryId) ||
        !productItemsForCategory(_categoryId).contains(_selectedItem)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a product category and item.')),
      );
      return;
    }
    if (_districtId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a collection district.')),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/sign-in');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(buyerNeedServiceProvider).createNeed(
        {
          'user_id': user.id,
          'category_id': _categoryId,
          'created_via': 'app',
          'item_name': _selectedItem!,
          'quantity': _quantityController.text.trim().isEmpty
              ? null
              : num.parse(_quantityController.text.trim()),
          'unit': _selectedUnit,
          'proposed_price_ugx': _priceController.text.trim().isEmpty
              ? null
              : num.parse(_priceController.text.trim()),
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'contact_person': _contactController.text.trim(),
          'contact_phone': _phoneController.text.trim(),
          'district_id': _districtId,
          'subcounty_id': _subcountyId,
          'parish_id': _parishId,
        },
        itemImage: _itemImageBytes,
        imageExtension: _itemImage?.name.split('.').last.toLowerCase(),
      );
      if (mounted) context.pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not publish your buyer demand. Check your connection '
              'and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        suffixIcon: entries?.isLoading == true
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Choose'),
        ),
        if (items != null)
          for (final item in items)
            DropdownMenuItem(
              value: idOf(item),
              child: Text(nameOf(item)),
            ),
      ],
      onChanged: enabled && entries?.hasError != true ? onChanged : null,
    );
  }
}
