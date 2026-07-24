class BrandModel {
  final String name;
  final String logoUrl;
  final String website;
  final String description;
  final String countryName;
  final bool isVerified;

  const BrandModel({
    required this.name,
    required this.logoUrl,
    required this.website,
    required this.description,
    required this.countryName,
    required this.isVerified,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      name: json['Name'] as String,
      logoUrl: json['LogoURL'] as String,
      website: json['Website'] as String,
      description: json['Description'] as String,
      countryName: json['CountryName'] as String,
      isVerified: json['IsVerified'] as bool,
    );
  }
}
