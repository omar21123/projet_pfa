import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Features/Account/Functions/showDeleteAddressDialog.dart';
import 'package:connectia/Features/Account/Widgets/address/AddAddressButton.dart';
import 'package:connectia/Features/Account/Widgets/address/AddAddressPage.dart';
import 'package:connectia/Features/Account/Widgets/address/AddressAppBar.dart';
import 'package:connectia/Features/Account/Widgets/address/AddressCard.dart';
import 'package:connectia/Features/Account/data/AddressesCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class Addressesview extends StatefulWidget {
  const Addressesview({super.key});

  @override
  State<Addressesview> createState() => _AddressesviewState();
}

class _AddressesviewState extends State<Addressesview> {
  @override
  void initState() {
    super.initState();
    context.read<AddressesCubit>().fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: BlocBuilder<AddressesCubit, AddressesState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              Addressappbar(
                onTap: () {},
              ),
              if (state is AddressesLoading)
                SliverToBoxAdapter(child: _buildShimmer())
              else if (state is AddressesError)
                SliverToBoxAdapter(child: _buildError(state.message))
              else if (state is AddressesLoaded ||
                  state is AddressDeleted)
                _buildAddressList(
                  state is AddressesLoaded
                      ? state.addresses
                      : (state as AddressDeleted).addresses,
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          );
        },
      ),
      floatingActionButton: AddAddressButton(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AddressesCubit>(),
                child: const AddAddressPage(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressList(List addresses) {
    if (addresses.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmpty());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 100),
      sliver: SliverList.builder(
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return Padding(
            padding: const EdgeInsets.only(left: 5, right: 5, top: 2, bottom: 10),
            child: GestureDetector(
              onTap: () {
                if (address.id != null) {
                  CustomNavigator.navigateToAddressDetailPage(address.id!);
                }
              },
              child: AddressCard(
              address: address,
              onSetDefaultBilling: () {
                if (address.id != null) {
                  context.read<AddressesCubit>().setDefaultBilling(address.id!);
                }
              },
              onSetDefaultShipping: () {
                if (address.id != null) {
                  context.read<AddressesCubit>().setDefaultShipping(address.id!);
                }
              },
              onEdit: () {},
              onDelete: () {
                showDeleteAddressDialog(
                  context,
                  isDefaultBilling: address.isDefaultBilling,
                  isDefaultShipping: address.isDefaultShipping,
                  onConfirm: () {
                    if (address.id != null) {
                      context.read<AddressesCubit>().deleteAddress(address.id!);
                    }
                  },
                );
              },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.secondary(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune adresse enregistrée',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primaryText(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une adresse pour vos livraisons.',
              style: TextStyle(
                color: AppColors.secondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 16, 5, 16),
        child: Column(
          children: List.generate(
            3,
            (_) => Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AddressesCubit>().fetchAddresses();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
