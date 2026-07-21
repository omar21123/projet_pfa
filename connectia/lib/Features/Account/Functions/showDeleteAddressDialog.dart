import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

void showDeleteAddressDialog(
  BuildContext context, {
  required bool isDefaultBilling,
  required bool isDefaultShipping,
  required VoidCallback onConfirm,
}) {
  final isDefault = isDefaultBilling || isDefaultShipping;

  showProDialog(
    context,
    // DialogType.error pilote le thème rouge par défaut (icône + accent),
    // c'est aussi ce que fait l'exemple officiel du package pour "Delete Account".
    type: DialogType.error,
    // Override explicite pour matcher exactement le rouge de l'app plutôt
    // que le rouge par défaut du package.
    iconColor: AppColors.logout(context),
    iconBackgroundColor: AppColors.logoutBg(context),
    title: 'Supprimer cette adresse',
    description: isDefault
        ? "Cette adresse est définie par défaut. La supprimer retirera ce "
              "statut. Cette action est irréversible."
        : "Cette action est irréversible.",
    buttons: [
      DialogButton(
        text: 'Annuler',
        style: DialogButtonStyle.outlined,
        onPressed: () => Navigator.pop(context),
      ),
      DialogButton(
        text: 'Supprimer',
        isPrimary: true,
        icon: Icons.delete_forever_rounded,
        onPressed: () {
          Navigator.pop(context);
          onConfirm();
        },
      ),
    ],
  );
}
