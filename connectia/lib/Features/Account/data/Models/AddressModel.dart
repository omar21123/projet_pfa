class AddressModel {
  final int? id;
  final String fullName;
  final String? phone;
  final String country;
  final String? region;
  final String city;
  final String? postalCode;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefaultBilling;
  final bool isDefaultShipping;

  const AddressModel({
    this.id,
    required this.fullName,
    this.phone,
    required this.country,
    this.region,
    required this.city,
    this.postalCode,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isDefaultBilling = false,
    this.isDefaultShipping = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: (json['AddressID'] ?? json['id']) as int?,
      fullName: (json['FullName'] ?? json['full_name']) as String? ?? '',
      phone: (json['Phone'] ?? json['phone']) as String?,
      country: (json['Country'] ?? json['country']) as String? ?? '',
      region: (json['Region'] ?? json['region']) as String?,
      city: (json['City'] ?? json['city']) as String? ?? '',
      postalCode: (json['PostalCode'] ?? json['postal_code']) as String?,
      addressLine1: (json['AddressLine1'] ?? json['address_line1']) as String? ?? '',
      addressLine2: (json['AddressLine2'] ?? json['address_line2']) as String?,
      landmark: (json['Landmark'] ?? json['landmark']) as String?,
      latitude: (json['Latitude'] ?? json['latitude'] as num?)?.toDouble(),
      longitude: (json['Longitude'] ?? json['longitude'] as num?)?.toDouble(),
      isDefaultShipping: (json['IsDefaultShipping'] ?? json['is_default_shipping']) as bool? ?? false,
      isDefaultBilling: (json['IsDefaultBilling'] ?? json['is_default_billing']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'country': country,
      if (region != null && region!.isNotEmpty) 'region': region,
      'city': city,
      if (postalCode != null && postalCode!.isNotEmpty) 'postal_code': postalCode,
      'address_line1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'address_line2': addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_default_shipping': isDefaultShipping,
    };
  }

  AddressModel copyWith({
    int? id,
    String? fullName,
    String? phone,
    String? country,
    String? region,
    String? city,
    String? postalCode,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isDefaultBilling,
    bool? isDefaultShipping,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefaultBilling: isDefaultBilling ?? this.isDefaultBilling,
      isDefaultShipping: isDefaultShipping ?? this.isDefaultShipping,
    );
  }
}
