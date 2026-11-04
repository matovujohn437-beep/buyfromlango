import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/countries.dart' show countries;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../utils/ugandan_phone_number.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _needsPhone = true;
  bool _isProfileLoading = true;

  String _phoneNumber = '';
  String? _selectedDistrict;
  String? _selectedSubcounty;
  String? _selectedParish;
  String _selectedRole = 'both';

  // Lists to hold the cascading data
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _subcounties = [];
  List<Map<String, dynamic>> _parishes = [];

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
    _fetchPhoneRequirement();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchPhoneRequirement() async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('phone')
          .eq('id', _supabase.auth.currentUser!.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _needsPhone = (profile?['phone'] as String?)?.isNotEmpty != true;
        _isProfileLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _needsPhone = true;
        _isProfileLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load your profile: $error')),
      );
    }
  }

  Future<void> _fetchDistricts() async {
    try {
      final data = await _supabase
          .from('districts')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _districts = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      _showLocationError('Could not load districts: $error');
    }
  }

  Future<void> _fetchSubcounties(String districtId) async {
    setState(() {
      _subcounties = [];
      _parishes = [];
      _selectedSubcounty = null;
      _selectedParish = null;
    });
    try {
      final data = await _supabase
          .from('subcounties')
          .select('id, name')
          .eq('district_id', districtId)
          .eq('is_active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _subcounties = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      _showLocationError('Could not load subcounties: $error');
    }
  }

  Future<void> _fetchParishes(String subcountyId) async {
    setState(() {
      _parishes = [];
      _selectedParish = null;
    });
    try {
      final data = await _supabase
          .from('parishes')
          .select('id, name')
          .eq('subcounty_id', subcountyId)
          .eq('is_active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _parishes = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      _showLocationError('Could not load parishes: $error');
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveProfile() async {
    if (_selectedDistrict == null || _selectedSubcounty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select your district and subcounty.')),
      );
      return;
    }
    final normalizedPhone =
        _needsPhone ? normalizeUgandanPhoneNumber(_phoneNumber) : null;
    if (_needsPhone && normalizedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid Ugandan phone number, such as +256700000000.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;

      if (_needsPhone) {
        await ref.read(authServiceProvider).savePhoneForCurrentUser(
              phone: normalizedPhone!,
            );
      }
      await _supabase.from('profiles').update({
        'district_id': int.parse(_selectedDistrict!),
        'subcounty_id': int.parse(_selectedSubcounty!),
        if (_selectedParish != null) 'parish_id': int.parse(_selectedParish!),
        'role': _selectedRole,
      }).eq('id', userId);

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        final message = switch (e) {
          PhoneAlreadyRegisteredException() =>
            PhoneAlreadyRegisteredException.message,
          FormatException() => e.message,
          _ => 'Error saving profile: $e',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProfileLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading:
            false, // Prevents going back without finishing
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Buy From Lango!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Just a few more details to get started.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_needsPhone) ...[
                IntlPhoneField(
                  controller: _phoneController,
                  initialCountryCode: 'UG',
                  countries: countries
                      .where((country) => country.code == 'UG')
                      .toList(),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    hintText: '7XX XXX XXX',
                  ),
                  onChanged: (phone) => _phoneNumber = phone.completeNumber,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // District Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'District',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                initialValue: _selectedDistrict,
                items: _districts
                    .map((d) => DropdownMenuItem(
                          value: d['id'].toString(),
                          child: Text(d['name']),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedDistrict = val);
                  if (val != null) _fetchSubcounties(val);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Subcounty Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subcounty',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                initialValue: _selectedSubcounty,
                items: _subcounties
                    .map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text(s['name']),
                        ))
                    .toList(),
                onChanged: _selectedDistrict == null
                    ? null
                    : (val) {
                        setState(() => _selectedSubcounty = val);
                        if (val != null) _fetchParishes(val);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Parish is optional; district and subcounty complete the location.
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Parish / Ward (optional)',
                  prefixIcon: Icon(Icons.holiday_village_outlined),
                ),
                initialValue: _selectedParish,
                items: _parishes
                    .map((p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text(p['name']),
                        ))
                    .toList(),
                onChanged: _selectedSubcounty == null
                    ? null
                    : (val) {
                        setState(() => _selectedParish = val);
                      },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Role Selection
              Text('I want to:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'seller', label: Text('Sell')),
                  ButtonSegment(value: 'buyer', label: Text('Buy')),
                  ButtonSegment(value: 'both', label: Text('Both')),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedRole = newSelection.first);
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
