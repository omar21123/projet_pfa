/// Modèle "Adresse".
class AddressModel {
  final String fullName;
  final String country;
  final String? region;
  final String city;
  final String? postalCode;
  final String addressLine1;
  final String? addressLine2;
  final bool isDefaultBilling;
  final bool isDefaultShipping;

  const AddressModel({
    required this.fullName,
    required this.country,
    this.region,
    required this.city,
    this.postalCode,
    required this.addressLine1,
    this.addressLine2,
    required this.isDefaultBilling,
    required this.isDefaultShipping,
  });

  AddressModel copyWith({
    String? fullName,
    String? country,
    String? region,
    String? city,
    String? postalCode,
    String? addressLine1,
    String? addressLine2,
    bool? isDefaultBilling,
    bool? isDefaultShipping,
  }) {
    return AddressModel(
      fullName: fullName ?? this.fullName,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      isDefaultBilling: isDefaultBilling ?? this.isDefaultBilling,
      isDefaultShipping: isDefaultShipping ?? this.isDefaultShipping,
    );
  }
}