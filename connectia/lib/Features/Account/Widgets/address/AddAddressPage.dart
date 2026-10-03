import 'dart:async';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/data/AddressesCubit.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mapController = MapController();

  // ── Map state ──
  LatLng? _selectedLatLng;
  bool _isLocating = false;
  String? _locationError;

  // ── Manual form ──
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController(text: 'Maroc');
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _isDefaultShipping = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  // ── Location ──
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Services de localisation désactivés. Activez-le dans les paramètres.';
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _locationError = 'Permission de localisation refusée';
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Permission refusée définitivement. Activez-la dans les paramètres.';
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLatLng = latLng;
        _isLocating = false;
      });
      _mapController.move(latLng, 16);
    } catch (e) {
      setState(() {
        _locationError = 'Erreur: ${e.toString()}';
        _isLocating = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_tabController.index == 0) {
      // Map mode — location is enough
      if (_selectedLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un point sur la carte')),
        );
        return;
      }
      // Navigate to manual form pre-filled, or save with location only
      _showMapSaveDialog();
      return;
    }

    // Manual mode
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final address = AddressModel(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      country: _countryController.text.trim(),
      region: _regionController.text.trim().isEmpty
          ? null
          : _regionController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim().isEmpty
          ? null
          : _postalCodeController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      latitude: _selectedLatLng?.latitude,
      longitude: _selectedLatLng?.longitude,
      isDefaultShipping: _isDefaultShipping,
    );

    final success = await context.read<AddressesCubit>().addAddress(address);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  void _showMapSaveDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.secondary(ctx).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Compléter l\'adresse',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText(ctx),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedLatLng?.latitude.toStringAsFixed(5)}, ${_selectedLatLng?.longitude.toStringAsFixed(5)}',
                style: TextStyle(
                  color: AppColors.secondary(ctx),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _miniField(ctx, 'Nom complet', nameCtrl),
              const SizedBox(height: 12),
              _miniField(ctx, 'Adresse', addressCtrl),
              const SizedBox(height: 12),
              _miniField(ctx, 'Ville', cityCtrl),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.secondary(ctx).withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: AppColors.primaryText(ctx)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            addressCtrl.text.trim().isEmpty ||
                            cityCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Nom, adresse et ville requis'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        final address = AddressModel(
                          fullName: nameCtrl.text.trim(),
                          country: 'Maroc',
                          city: cityCtrl.text.trim(),
                          addressLine1: addressCtrl.text.trim(),
                          latitude: _selectedLatLng?.latitude,
                          longitude: _selectedLatLng?.longitude,
                          isDefaultShipping: _isDefaultShipping,
                        );
                        setState(() => _isSaving = true);
                        final success = await context
                            .read<AddressesCubit>()
                            .addAddress(address);
                        if (mounted) {
                          setState(() => _isSaving = false);
                          if (success) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(ctx),
                        foregroundColor: AppColors.onPrimary(ctx),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniField(
    BuildContext ctx,
    String label,
    TextEditingController ctrl,
  ) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: AppColors.primaryText(ctx), fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        hintText: label,
        hintStyle: TextStyle(color: AppColors.secondary(ctx)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: AppColors.softBg(ctx),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: Column(
        children: [
          // ── Header ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primaryText(context),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Nouvelle adresse',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab bar ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary(context),
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.onPrimary(context),
              unselectedLabelColor: AppColors.secondary(context),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Carte (Recommandé)'),
                Tab(text: 'Manuel'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Content ──
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tabController.index == 0 ? _buildMapTab() : _buildManualTab(),
            ),
          ),

          // ── Save button ──
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.onPrimary(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: AppColors.secondary(context)
                        .withValues(alpha: 0.3),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary(context),
                          ),
                        )
                      : Text(
                          _tabController.index == 0
                              ? 'Utiliser cette position'
                              : "Enregistrer l'adresse",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MAP TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildMapTab() {
    return Column(
      key: const ValueKey('map'),
      children: [
        // ── Location button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location,
                          size: 18, color: AppColors.primary(context)),
                  label: Text(
                    _isLocating
                        ? 'Localisation...'
                        : 'Ma position actuelle',
                    style: TextStyle(
                      color: AppColors.primary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              _locationError!,
              style: TextStyle(color: AppColors.logout(context), fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),

        // ── Map ──
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLatLng ?? const LatLng(33.5731, -7.5898),
              initialZoom: 13,
              onTap: (tapPosition, latLng) {
                setState(() => _selectedLatLng = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.connectia.app',
              ),
              if (_selectedLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLatLng!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // ── Coordinates display ──
        if (_selectedLatLng != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppColors.surface(context),
            child: Row(
              children: [
                Icon(Icons.location_on,
                    size: 16, color: AppColors.primary(context)),
                const SizedBox(width: 8),
                Text(
                  '${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    color: AppColors.secondary(context),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MANUAL TAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildManualTab() {
    return SingleChildScrollView(
      key: const ValueKey('manual'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field('Nom complet', _fullNameController, required: true),
            const SizedBox(height: 14),
            _field('Téléphone', _phoneController,
                required: false, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _field('Pays', _countryController, required: true),
            const SizedBox(height: 14),
            _field('Région', _regionController),
            const SizedBox(height: 14),
            _field('Ville', _cityController, required: true),
            const SizedBox(height: 14),
            _field('Code postal', _postalCodeController,
                required: false, keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _field('Adresse (ligne 1)', _addressLine1Controller, required: true),
            const SizedBox(height: 14),
            _field('Adresse (ligne 2)', _addressLine2Controller),
            const SizedBox(height: 14),
            _field('Repère / Point de repère', _landmarkController),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Adresse de livraison par défaut',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _isDefaultShipping,
                  onChanged: (v) => setState(() => _isDefaultShipping = v),
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary(context),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.secondary(context)
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 13,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: AppColors.logout(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontSize: 15,
          ),
          validator: required
              ? (v) =>
                    (v == null || v.trim().isEmpty) ? errorText ?? 'Requis' : null
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppColors.surface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.logout(context)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.logout(context), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary(context),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
