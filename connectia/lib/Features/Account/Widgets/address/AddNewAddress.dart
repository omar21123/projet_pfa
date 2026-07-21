import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter/material.dart';

/// Page "Ajouter une adresse". Champs requis = colonnes NOT NULL de la
/// table Addresses (fullName, country, city, addressLine1).
class Addnewaddress extends StatefulWidget {
  final Future<void> Function(AddressModel newAddress) onSave;

  const Addnewaddress({super.key, required this.onSave});

  @override
  State<Addnewaddress> createState() => _AddnewaddressState();
}

class _AddnewaddressState extends State<Addnewaddress> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();

  bool _isDefaultBilling = false;
  bool _isDefaultShipping = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newAddress = AddressModel(
      fullName: _fullNameController.text.trim(),
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
      isDefaultBilling: _isDefaultBilling,
      isDefaultShipping: _isDefaultShipping,
    );

    try {
      await widget.onSave(newAddress);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background(context),
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.primaryText(context)),
              title: Text(
                'Nouvelle adresse',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList.list(
                children: [
                  _field(
                    context,
                    label: 'Nom complet',
                    controller: _fullNameController,
                    required: true,
                    errorText: 'Le nom complet est requis.',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Pays',
                    controller: _countryController,
                    required: true,
                    errorText: 'Le pays est requis.',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Région',
                    controller: _regionController,
                    required: false,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Ville',
                    controller: _cityController,
                    required: true,
                    errorText: 'La ville est requise.',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Code postal',
                    controller: _postalCodeController,
                    required: false,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Adresse (ligne 1)',
                    controller: _addressLine1Controller,
                    required: true,
                    errorText: "L'adresse est requise.",
                  ),
                  const SizedBox(height: 18),
                  _field(
                    context,
                    label: 'Adresse (ligne 2)',
                    controller: _addressLine2Controller,
                    required: false,
                  ),
                  const SizedBox(height: 28),
                  Divider(
                    color: AppColors.secondary(context).withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  _defaultSwitch(
                    context,
                    label: 'Définir comme adresse de facturation par défaut',
                    value: _isDefaultBilling,
                    onChanged: (v) => setState(() => _isDefaultBilling = v),
                  ),
                  const SizedBox(height: 8),
                  _defaultSwitch(
                    context,
                    label: 'Définir comme adresse de livraison par défaut',
                    value: _isDefaultShipping,
                    onChanged: (v) => setState(() => _isDefaultShipping = v),
                  ),
                  const SizedBox(height: 32),
                  _buildSaveButton(context),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool required,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
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
          style: TextStyle(color: AppColors.primaryText(context), fontSize: 16),
          validator: required
              ? (value) =>
                    (value == null || value.trim().isEmpty) ? errorText : null
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
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
              borderSide: BorderSide(
                color: AppColors.logout(context),
                width: 1.5,
              ),
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

  Widget _defaultSwitch(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppColors.primary(context),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.secondary(
            context,
          ).withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary(context),
          foregroundColor: AppColors.onPrimary(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          disabledBackgroundColor: AppColors.secondary(
            context,
          ).withValues(alpha: 0.3),
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
            : const Text(
                "Enregistrer l'adresse",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
      ),
    );
  }
}
