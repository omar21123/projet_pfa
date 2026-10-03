import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Account/data/AddressRepo.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── States ───────────────────────────────────────────────────
abstract class AddressesState {}

class AddressesInitial extends AddressesState {}

class AddressesLoading extends AddressesState {}

class AddressesLoaded extends AddressesState {
  final List<AddressModel> addresses;
  AddressesLoaded({required this.addresses});
}

class AddressesError extends AddressesState {
  final String message;
  AddressesError({required this.message});
}

class AddressSaving extends AddressesState {}

class AddressDeleted extends AddressesState {
  final List<AddressModel> addresses;
  AddressDeleted({required this.addresses});
}

// ── Cubit ────────────────────────────────────────────────────
class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit() : super(AddressesInitial());

  List<AddressModel> _addresses = [];
  List<AddressModel> get addresses => _addresses;

  Future<void> fetchAddresses() async {
    emit(AddressesLoading());
    final result = await locator<AddressRepo>().getAddresses();
    result.fold(
      (failure) => emit(AddressesError(message: failure.displayMessage)),
      (addresses) {
        _addresses = addresses;
        emit(AddressesLoaded(addresses: addresses));
      },
    );
  }

  Future<bool> addAddress(AddressModel address) async {
    emit(AddressSaving());
    final result = await locator<AddressRepo>().addAddress(address: address);
    return result.fold(
      (failure) {
        emit(AddressesLoaded(addresses: _addresses));
        return false;
      },
      (_) {
        fetchAddresses();
        return true;
      },
    );
  }

  Future<void> deleteAddress(int addressId) async {
    final result = await locator<AddressRepo>().deleteAddress(addressId: addressId);
    result.fold(
      (failure) => emit(AddressesError(message: failure.displayMessage)),
      (_) {
        _addresses.removeWhere((a) => a.id == addressId);
        emit(AddressDeleted(addresses: List.from(_addresses)));
      },
    );
  }

  Future<void> setDefaultShipping(int addressId) async {
    final result = await locator<AddressRepo>().setDefaultShipping(addressId: addressId);
    result.fold(
      (failure) => emit(AddressesError(message: failure.displayMessage)),
      (_) => fetchAddresses(),
    );
  }

  Future<void> setDefaultBilling(int addressId) async {
    final result = await locator<AddressRepo>().setDefaultBilling(addressId: addressId);
    result.fold(
      (failure) => emit(AddressesError(message: failure.displayMessage)),
      (_) => fetchAddresses(),
    );
  }
}
