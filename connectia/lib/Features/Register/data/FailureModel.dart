/// Error model for the register endpoint.
///
/// Matches the `422` response:
/// ```json
/// {
///   "message": "The given data was invalid.",
///   "errors": {
///     "email": ["Cet email existe déjà."]
///   }
/// }
/// ```
/// `message` is always present. `errors` only shows up on validation
/// failures (422) — other failures (network, timeout, 500) just carry
/// a `message`.
class RegisterFailureModel {
  final String message;
  final Map<String, List<String>>? errors;

  const RegisterFailureModel({required this.message, this.errors});

  factory RegisterFailureModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? parsedErrors;

    final rawErrors = json['errors'];
    if (rawErrors is Map<String, dynamic>) {
      parsedErrors = rawErrors.map(
        (field, messages) =>
            MapEntry(field, List<String>.from(messages as List? ?? const [])),
      );
    }

    return RegisterFailureModel(
      message: json['message'] as String? ?? 'An unexpected error occurred.',
      errors: parsedErrors,
    );
  }

  /// For non-JSON failures: timeouts, no connection, unexpected exceptions.
  factory RegisterFailureModel.fromException(Object error) {
    return RegisterFailureModel(message: error.toString());
  }

  bool get hasFieldErrors => errors != null && errors!.isNotEmpty;

  /// First validation error message, e.g. "Cet email existe déjà."
  String? get firstError {
    if (!hasFieldErrors) return null;
    final firstList = errors!.values.first;
    return firstList.isNotEmpty ? firstList.first : null;
  }

  /// Errors for one field, e.g. `errorsFor('email')`.
  List<String>? errorsFor(String field) => errors?[field];

  /// What to show the user: first field error if present, else the
  /// top-level message.
  String get displayMessage => firstError ?? message;

  @override
  String toString() => 'FailureModel(message: $message, errors: $errors)';
}
