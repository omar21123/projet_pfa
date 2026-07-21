import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Functions/showDeleteAddressDialog.dart';
import 'package:connectia/Features/Account/Widgets/address/AddressAppBar.dart';
import 'package:connectia/Features/Account/Widgets/address/AddressCard.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter/material.dart';
import 'package:pro_dialog/pro_dialog.dart';

class Addressesview extends StatelessWidget {
  const Addressesview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: CustomScrollView(
        slivers: [
          Addressappbar(
            onTap: () {
              print('Clicked Addressappbar');
            },
          ),
          SliverList.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 2,
                  bottom: 10,
                ),
                child: AddressCard(
                  address: AddressModel(
                    fullName: 'Julien Dupont',
                    country: 'France',
                    region: null,
                    city: 'Paris',
                    postalCode: '75002',
                    addressLine1: '15 Rue de la Paix',
                    addressLine2: 'Appartement 4B, 2ème étage',
                    isDefaultBilling: index % 2 == 1,
                    isDefaultShipping: index % 2 == 0,
                  ),
                  onSetDefaultBilling: () {},
                  onSetDefaultShipping: () {},
                  onEdit: () {},
                  onDelete: () {
                    showDeleteAddressDialog(
                      context,
                      isDefaultBilling: index % 2 == 1,
                      isDefaultShipping: index % 2 == 0,
                      onConfirm: () {},
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
