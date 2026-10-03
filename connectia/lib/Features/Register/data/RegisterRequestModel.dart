import 'package:connectia/Core/enums/Gender.dart';
import 'package:intl/intl.dart';
class RegisterRequestModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phoneNumber;
  final DateTime? birthDate;
  final Gender? gender;

  const RegisterRequestModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.birthDate,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'birth_date': birthDate != null ? DateFormat('yyyy-MM-dd').format(birthDate!) : null,
      'gender': gender?.value,
      'avatar': null, // TODO: replace with multipart upload once avatar step is built
    };
  }
}