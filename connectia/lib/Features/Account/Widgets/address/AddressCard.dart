import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter/material.dart';

/// Carte d'adresse : infos + statut par défaut (facturation / livraison).
class AddressCard extends StatelessWidget {
  final AddressModel address;
  final VoidCallback onSetDefaultBilling;
  final VoidCallback onSetDefaultShipping;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.onSetDefaultBilling,
    required this.onSetDefaultShipping,
    required this.onEdit,
    required this.onDelete,
  });

  String get _addressText {
    final line2 = address.addressLine2;
    return line2 == null || line2.trim().isEmpty
        ? address.addressLine1
        : '${address.addressLine1}, $line2';
  }

  String get _cityLineText {
    final postal = address.postalCode;
    final head = [
      if (postal != null && postal.trim().isNotEmpty) postal,
      address.city,
    ].join(' ');
    final region = address.region;
    final tail = [
      if (region != null && region.trim().isNotEmpty) region,
      address.country,
    ].join(', ');
    return '$head, $tail';
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = address.isDefaultBilling || address.isDefaultShipping;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted
              ? AppColors.primary(context)
              : AppColors.secondary(context).withValues(alpha: 0.2),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // IconButton(
              //   onPressed: onEdit,
              //   icon: Icon(Icons.edit_outlined, color: AppColors.secondary(context)),
              //   visualDensity: VisualDensity.compact,
              // ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.logout(context),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _addressText,
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _cityLineText,
            style: TextStyle(
              color: AppColors.secondary(context),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Divider(
            color: AppColors.secondary(context).withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 16),
          _DefaultStatusRow(
            isDefault: address.isDefaultBilling,
            defaultLabel: 'Adresse de facturation par défaut',
            actionLabel: 'Définir comme facturation',
            actionColor: AppColors.neutral(context),
            actionBackgroundColor: AppColors.neutralBg(context),
            onTap: onSetDefaultBilling,
          ),
          const SizedBox(height: 12),
          _DefaultStatusRow(
            isDefault: address.isDefaultShipping,
            defaultLabel: 'Adresse de livraison par défaut',
            actionLabel: 'Définir comme livraison',
            actionColor: AppColors.primary(context),
            actionBackgroundColor: AppColors.accent20(context),
            onTap: onSetDefaultShipping,
          ),
        ],
      ),
    );
  }
}

class _DefaultStatusRow extends StatelessWidget {
  final bool isDefault;
  final String defaultLabel;
  final String actionLabel;
  final Color actionColor;
  final Color actionBackgroundColor;
  final VoidCallback onTap;

  const _DefaultStatusRow({
    required this.isDefault,
    required this.defaultLabel,
    required this.actionLabel,
    required this.actionColor,
    required this.actionBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isDefault) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.successColor(context),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            defaultLabel,
            style: TextStyle(
              color: AppColors.successColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: actionBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          actionLabel,
          style: TextStyle(
            color: actionColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
