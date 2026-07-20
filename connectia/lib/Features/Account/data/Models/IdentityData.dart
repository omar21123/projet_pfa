 enum Gender { homme, femme }
 
extension GenderLabel on Gender {
  String get label => this == Gender.homme ? 'Homme' : 'Femme';
}
 
/// Données du formulaire Identité.
class IdentityData {
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final Gender gender;
 
  const IdentityData({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
  });
 
  IdentityData copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    Gender? gender,
  }) {
    return IdentityData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }
}