import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/data/Models/IdentityData.dart';
import 'package:flutter/material.dart';

/// Widget "Identité" : prend des données initiales et remonte chaque
/// modification via `onChanged`.
class IdentitySection extends StatefulWidget {
  final IdentityData initialData;
  final ValueChanged<IdentityData> onChanged;

  const IdentitySection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends State<IdentitySection> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late IdentityData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _firstNameController = TextEditingController(text: _data.firstName);
    _lastNameController = TextEditingController(text: _data.lastName);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _emit(IdentityData newData) {
    setState(() => _data = newData);
    widget.onChanged(newData);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _data.birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _emit(_data.copyWith(birthDate: picked));
    }
  }

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<Gender>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Gender.values
              .map(
                (g) => ListTile(
                  title: Text(
                    g.label,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: g == _data.gender ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: g == _data.gender
                      ? Icon(Icons.check, color: AppColors.primary(context))
                      : null,
                  onTap: () => Navigator.pop(context, g),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      _emit(_data.copyWith(gender: selected));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softBg(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            context,
            label: 'Prénom',
            controller: _firstNameController,
            onChanged: (value) => _emit(_data.copyWith(firstName: value)),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            context,
            label: 'Nom',
            controller: _lastNameController,
            onChanged: (value) => _emit(_data.copyWith(lastName: value)),
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            context,
            label: 'Date de naissance',
            value: _formatDate(_data.birthDate),
            onTap: _pickBirthDate,
          ),
          const SizedBox(height: 20),
          _buildGenderField(context),
        ],
      ),
    );
  }



  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.primaryText(context), fontSize: 17),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.secondary(context).withValues(alpha: 0.25)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.secondary(context).withValues(alpha: 0.25)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary(context), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.secondary(context).withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(color: AppColors.primaryText(context), fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genre',
          style: TextStyle(color: AppColors.secondary(context), fontSize: 13),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickGender,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _data.gender.label,
              style: TextStyle(
                color: AppColors.onPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}