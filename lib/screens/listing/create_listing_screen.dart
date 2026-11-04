import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../constants/app_assets.dart';
import '../../models/catalog_item.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/listing_provider.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/common/asset_image.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/marketplace_navigation_bar.dart';
import '../../widgets/product_avatar.dart';
import '../../widgets/responsive_layout.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key, this.categoryId, this.listing});

  final String? categoryId;
  final ListingModel? listing;

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

Widget _formSection(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );

String _categoryExamples(String id) => switch (id) {
      'crops' || 'produce' => 'Examples: maize, beans, cassava, vegetables.',
      'livestock' => 'Examples: live animals, eggs, milk, beef and pork.',
      'services' =>
        'Examples: veterinary care, transport, ploughing, irrigation.',
      'supplies' =>
        'Examples: animal drugs, fertilizers, seeds, crop protection.',
      'equipment' =>
        'Examples: tractors, water pumps and sprayers for hire or sale.',
      'jobs' => 'Examples: farm workers, harvest crews, seasonal farm roles.',
      'cooperatives' => 'Examples: farmer groups, cooperatives, memberships.',
      _ => 'Add a clear title, price, quantity and helpful description.',
    };

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _workersNeededController = TextEditingController();
  final _remainingQuantityController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final List<_PendingListingMedia> _media = [];
  String? _categoryId;
  String? _selectedUnit;
  String _saleStatus = 'available';
  ListingModel? _savedListing;
  bool _isNegotiable = true;
  bool _isSubmitting = false;
  bool _isRecordingAudio = false;

  Future<void> _showMediaOptions() async {
    if (_media.length >= 6) {
      _showMessage('You can add up to six media items.');
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Record video'),
              onTap: () => Navigator.pop(context, 'record_video'),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_outlined),
              title: const Text('Record audio note'),
              onTap: () => Navigator.pop(context, 'record_audio'),
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_outlined),
              title: const Text('Choose audio file'),
              onTap: () => Navigator.pop(context, 'audio_file'),
            ),
          ],
        ),
      ),
    );
    try {
      final picker = ImagePicker();
      switch (choice) {
        case 'photo':
        case 'camera':
          final file = await picker.pickImage(
            source:
                choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
            maxWidth: 1920,
            imageQuality: 82,
          );
          if (file != null) {
            await _addPendingMedia(file, 'image', Icons.image_outlined);
          }
          break;
        case 'video':
        case 'record_video':
          final file = await picker.pickVideo(
            source: choice == 'record_video'
                ? ImageSource.camera
                : ImageSource.gallery,
            maxDuration: const Duration(seconds: 60),
          );
          if (file != null) {
            await _addPendingMedia(file, 'video', Icons.videocam_outlined);
          }
          break;
        case 'record_audio':
          if (!await _audioRecorder.hasPermission()) {
            throw StateError(
                'Microphone permission is required to record audio.');
          }
          if (kIsWeb) {
            final fileName =
                'listing-note-${DateTime.now().microsecondsSinceEpoch}.m4a';
            await _audioRecorder.start(const RecordConfig(), path: fileName);
          } else {
            final path =
                '${Directory.systemTemp.path}${Platform.pathSeparator}listing-note-${DateTime.now().microsecondsSinceEpoch}.m4a';
            await _audioRecorder.start(const RecordConfig(), path: path);
          }
          if (mounted) setState(() => _isRecordingAudio = true);
          break;
        case 'audio_file':
          final result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['m4a', 'aac', 'mp3', 'wav', 'webm'],
            withData: true,
          );
          final selected = result?.files.firstOrNull;
          if (selected != null) {
            final bytes = selected.bytes;
            if (bytes == null || bytes.isEmpty) {
              throw StateError('The selected audio file could not be read.');
            }
            await _addPendingMedia(
              XFile.fromData(bytes, name: selected.name),
              'audio',
              Icons.audio_file_outlined,
            );
          }
          break;
        case null:
          break;
      }
    } catch (error) {
      _showMessage('Could not add media: $error');
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecordingAudio = false);
      if (path == null) throw StateError('Audio recording could not be saved.');
      await _addPendingMedia(
        XFile(path, name: 'Voice note.m4a'),
        'audio',
        Icons.graphic_eq_outlined,
      );
    } catch (error) {
      if (mounted) setState(() => _isRecordingAudio = false);
      _showMessage('Could not save audio recording: $error');
    }
  }

  Future<void> _addPendingMedia(
    XFile file,
    String mediaType,
    IconData icon,
  ) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw StateError('The selected file is empty.');
    if (bytes.length > 50 * 1024 * 1024) {
      throw StateError('Media must be smaller than 50 MB.');
    }
    if (!mounted) return;
    if (_media.length >= 6) {
      _showMessage('You can add up to six media items.');
      return;
    }
    setState(() {
      _media.add(
        _PendingListingMedia(
          file: file,
          bytes: bytes,
          mediaType: mediaType,
          icon: icon,
        ),
      );
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    final listing = widget.listing;
    _categoryId = listing?.categoryId ?? widget.categoryId ?? 'crops';
    _titleController.text = listing?.title ?? '';
    _descriptionController.text = listing?.description ?? '';
    _priceController.text = listing?.priceUgx?.toString() ?? '';
    _quantityController.text = listing?.quantity ?? '';
    _workersNeededController.text = listing?.workersNeeded?.toString() ?? '';
    _remainingQuantityController.text =
        listing?.remainingQuantity?.toString() ?? '';
    _selectedUnit = listing?.unit;
    _saleStatus = listing?.saleStatus ?? 'available';
    _isNegotiable = listing?.isNegotiable ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _workersNeededController.dispose();
    _remainingQuantityController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(listingCatalogProvider);
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.listing == null ? 'Create Post' : 'Edit Post',
      ),
      bottomNavigationBar: const MarketplaceNavigationBar(selectedIndex: 1),
      body: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: AssetImageFallback(
                  asset: AppAssets.listingImageForCategory(
                    _categoryId ?? 'produce',
                  ),
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _formSection(
                context,
                title: 'Price and quantity',
                subtitle:
                    'Set a clear price and keep units separate from quantity.',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Share something with local buyers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              catalog.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text(
                  'We could not load listing options. Please try again later.',
                ),
                data: (items) => _categoryDropdown(items),
              ),
              if (_categoryId != null) ...[
                const SizedBox(height: AppSpacing.md),
                _productDropdown(),
              ],
              if (_categoryId != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _categoryExamples(_categoryId!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              if (_isJobsOrServices) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _workersNeededController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _categoryId == 'jobs'
                        ? 'How many workers/positions are needed?'
                        : 'How many workers are needed for this service?',
                    prefixIcon: const Icon(Icons.groups_outlined),
                  ),
                  validator: (value) {
                    if (!_isJobsOrServices) return null;
                    final count = int.tryParse(value?.trim() ?? '');
                    return count == null || count < 1
                        ? 'Enter at least one worker or position.'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _formSection(
                context,
                title: 'Listing details',
                subtitle:
                    'Describe your item clearly so buyers know what to expect.',
                icon: Icons.edit_note_outlined,
              ),
              if (widget.listing != null && widget.listing!.editCount >= 1)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'You can only edit a listing once.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 4000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (UGX)',
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
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'e.g. 50 kg',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _unitDropdown(catalog.valueOrNull ?? const []),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _remainingQuantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Remaining quantity',
                        hintText: 'Optional',
                      ),
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        if (input.isEmpty) return null;
                        final amount = num.tryParse(input);
                        return amount == null || amount < 0
                            ? 'Enter zero or more.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _saleStatus,
                      decoration:
                          const InputDecoration(labelText: 'Sale status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'partially_sold',
                          child: Text('Partially sold'),
                        ),
                        DropdownMenuItem(
                          value: 'fully_sold',
                          child: Text('Fully sold'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _saleStatus = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Price is negotiable'),
                value: _isNegotiable,
                onChanged: (value) => setState(() => _isNegotiable = value),
              ),
              const SizedBox(height: AppSpacing.md),
              _formSection(
                context,
                title: 'Photos, video and audio',
                subtitle:
                    'Add up to six media items. Short clips and voice notes help buyers.',
                icon: Icons.perm_media_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _showMediaOptions,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add media'),
                  ),
                  if (_isRecordingAudio)
                    FilledButton.tonalIcon(
                      onPressed: _stopAudioRecording,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop recording'),
                    ),
                ],
              ),
              if (_media.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _media.length; i++)
                  Card(
                    child: ListTile(
                      leading: Icon(_media[i].icon),
                      title: Text(_media[i].name),
                      subtitle: Text(_media[i].mediaType.toUpperCase()),
                      trailing: IconButton(
                        tooltip: 'Remove media',
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _media.removeAt(i)),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.sm),
              profile.when(
                data: (value) => value?.districtId == null
                    ? const Text(
                        'Add your location in your profile to show it on this post.',
                      )
                    : const Text('Your profile location will be used.'),
                loading: () => const SizedBox.shrink(),
                error: (error, _) =>
                    Text('Could not load your profile: $error'),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSubmitting ||
                        (widget.listing != null &&
                            widget.listing!.editCount >= 1) ||
                        catalog.isLoading ||
                        catalog.hasError ||
                        catalog.valueOrNull?.isNotEmpty != true
                    ? null
                    : () => _submit(profile.valueOrNull),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.listing == null
                        ? 'Publish Post'
                        : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isJobsOrServices =>
      _categoryId == 'jobs' || _categoryId == 'services';

  Widget _categoryDropdown(List<Category> catalog) {
    if (catalog.isEmpty) {
      return const Text('No listing categories are currently available.');
    }
    final selectedId = catalog.any((category) => category.id == _categoryId)
        ? _categoryId
        : catalog.first.id;
    final selected = catalog.firstWhere(
      (category) => category.id == selectedId,
    );
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'Category'),
      items: [
        for (final category in catalog)
          DropdownMenuItem(
            value: category.id,
            child: Row(
              children: [
                SvgPicture.asset(
                  AppAssets.categoryIconForName(category.iconName),
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(category.labelEn),
              ],
            ),
          ),
      ],
      onChanged: (value) => setState(() {
        final nextCategory = catalog.firstWhere(
          (category) => category.id == value,
        );
        if (!nextCategory.catalogItems
            .any((item) => item.name == _titleController.text)) {
          _titleController.clear();
        }
        _categoryId = value;
        final selectedItem = nextCategory.catalogItems
            .where((item) => item.name == _titleController.text)
            .firstOrNull;
        if (selectedItem == null ||
            !selectedItem.itemUnits
                .any((unit) => unit.unitName == _selectedUnit)) {
          _selectedUnit = null;
        }
      }),
      validator: (_) => selected.id.isEmpty ? 'Choose a category.' : null,
    );
  }

  Widget _productDropdown() {
    final category = ref
        .read(listingCatalogProvider)
        .valueOrNull
        ?.where((category) => category.id == _categoryId)
        .firstOrNull;
    final options = category?.catalogItems ?? const <CatalogItem>[];
    final itemNames = options.map((item) => item.name).toList();
    final currentTitle = _titleController.text;
    if (widget.listing?.categoryId == _categoryId &&
        currentTitle.isNotEmpty &&
        !itemNames.contains(currentTitle)) {
      itemNames.add(currentTitle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('product-$_categoryId'),
          initialValue: itemNames.contains(currentTitle) ? currentTitle : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: switch (_categoryId) {
              'livestock' => 'Livestock item',
              'equipment' => 'Equipment item',
              _ => 'Product or service',
            },
          ),
          hint: Text(
            _categoryId == 'livestock'
                ? 'Choose an animal or by-product'
                : 'Choose an item',
          ),
          items: [
            for (final item in itemNames)
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
          onChanged: (value) => setState(() {
            _titleController.text = value ?? '';
            final selectedItem =
                options.where((item) => item.name == value).firstOrNull;
            if (selectedItem == null ||
                !selectedItem.itemUnits
                    .any((unit) => unit.unitName == _selectedUnit)) {
              _selectedUnit = null;
            }
          }),
          validator: (value) => value == null || !itemNames.contains(value)
              ? 'Choose an item.'
              : null,
        ),
        if (currentTitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              ProductAvatar(
                categoryId: _categoryId,
                itemName: currentTitle,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  currentTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _unitDropdown(List<Category> catalog) {
    final category =
        catalog.where((category) => category.id == _categoryId).firstOrNull;
    final item = category?.catalogItems
        .where((item) => item.name == _titleController.text)
        .firstOrNull;
    final options =
        item?.itemUnits.map((unit) => unit.unitName).toList() ?? <String>[];
    if (widget.listing?.categoryId == _categoryId &&
        widget.listing?.title == _titleController.text &&
        widget.listing?.unit != null &&
        !options.contains(widget.listing!.unit)) {
      options.add(widget.listing!.unit!);
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('$_categoryId-${item?.id ?? _titleController.text}'),
      initialValue: options.contains(_selectedUnit) ? _selectedUnit : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Unit'),
      hint: const Text('Choose a unit'),
      items: [
        for (final unit in options)
          DropdownMenuItem(value: unit, child: Text(unit)),
      ],
      onChanged: (value) => setState(() => _selectedUnit = value),
      validator: (value) => value != null && !options.contains(value)
          ? 'Choose a unit that matches this category.'
          : null,
    );
  }

  Future<void> _submit(ProfileModel? profile) async {
    if (widget.listing != null && widget.listing!.editCount >= 1) {
      _showMessage('You can only edit a listing once.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/sign-in');
      return;
    }
    final catalog =
        ref.read(listingCatalogProvider).valueOrNull ?? const <Category>[];
    final selectedCategory =
        catalog.where((category) => category.id == _categoryId).firstOrNull;
    if (selectedCategory == null) return;
    final validCategoryId = selectedCategory.id;
    final selectedItem = selectedCategory.catalogItems
        .where((item) => item.name == _titleController.text)
        .firstOrNull;
    final isUnchangedLegacyItem =
        widget.listing?.categoryId == validCategoryId &&
            widget.listing?.title == _titleController.text;
    if (selectedItem == null && !isUnchangedLegacyItem) {
      _showMessage('Choose an item that matches the selected category.');
      return;
    }
    if (_selectedUnit != null &&
        selectedItem != null &&
        !selectedItem.itemUnits.any((unit) => unit.unitName == _selectedUnit)) {
      _showMessage('Choose a unit that matches the selected category.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'category_id': validCategoryId,
        'created_via': widget.listing?.createdVia ?? 'app',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'price_ugx': _priceController.text.trim().isEmpty
            ? null
            : num.parse(_priceController.text.trim()),
        'is_negotiable': _isNegotiable,
        'quantity': _quantityController.text.trim().isEmpty
            ? null
            : _quantityController.text.trim(),
        'unit': _selectedUnit,
        'workers_needed': _isJobsOrServices
            ? int.parse(_workersNeededController.text.trim())
            : null,
        'service_type': _isJobsOrServices ? _titleController.text.trim() : null,
        'remaining_quantity': _remainingQuantityController.text.trim().isEmpty
            ? null
            : num.parse(_remainingQuantityController.text.trim()),
        'sale_status': _saleStatus,
        'district_id': profile?.districtId ?? widget.listing?.districtId,
        'subcounty_id': profile?.subcountyId ?? widget.listing?.subcountyId,
        'parish_id': profile?.parishId ?? widget.listing?.parishId,
      };
      ListingModel savedListing;
      if (_savedListing != null) {
        savedListing = await ref.read(listingServiceProvider).updateListing(
              _savedListing!.id,
              payload,
            );
      } else if (widget.listing == null) {
        savedListing = await ref.read(listingServiceProvider).createListing({
          'user_id': user.id,
          ...payload,
        });
      } else {
        savedListing = await ref.read(listingServiceProvider).updateListing(
              widget.listing!.id,
              payload,
            );
      }
      _savedListing = savedListing;
      final storage = StorageService();
      for (var index = 0; index < _media.length; index++) {
        final media = _media[index];
        if (media.uploadedUrl == null) {
          final fileName = media.file.name;
          if (fileName.isEmpty || !fileName.contains('.')) {
            throw StateError('The selected media file has no file extension.');
          }
          final extension = fileName.split('.').last.toLowerCase();
          media.uploadedUrl = await storage.uploadListingMedia(
            bytes: media.bytes,
            userId: user.id,
            listingId: savedListing.id.toString(),
            extension: extension,
            mediaType: media.mediaType,
          );
        }
        if (!media.isSaved) {
          await ref.read(listingServiceProvider).addListingMedia(
                listingId: savedListing.id,
                mediaUrl: media.uploadedUrl!,
                mediaType: media.mediaType,
                sortOrder: index,
              );
          media.isSaved = true;
        }
      }
      try {
        await ref.read(listingServiceProvider).clearCachedListings();
      } catch (error) {
        _showMessage(
          'Your listing was saved, but offline listings could not be cleared: $error',
        );
      }
      ref.invalidate(listingMediaProvider(savedListing.id));
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _savedListing == null
                  ? 'Could not publish your post: $error'
                  : 'Your post was saved, but media needs retrying: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _PendingListingMedia {
  _PendingListingMedia({
    required this.file,
    required this.bytes,
    required this.mediaType,
    required this.icon,
  });

  final XFile file;
  final Uint8List bytes;
  final String mediaType;
  final IconData icon;
  String? uploadedUrl;
  bool isSaved = false;

  String get name => file.name.isEmpty ? 'Voice note' : file.name;
}
