/// Represents the authenticated user.
///
/// Built from the `201` register/login response:
/// ```json
/// {
///   "message": "Compte créé avec succès.",
///   "access_token": "...",
///   "Refresh_token": "...",
///   "displayName": "Mohammed Bourass",
///   "verify_email": false,
///   "verify_phone": false,
///   "public_id": "550e8400-e29b-41d4-a716-446655440000"
/// }
/// ```
/// `unreadNotifications` isn't part of that response — it's not returned
/// by register/login, so it always starts at 0 and gets updated later
/// (e.g. from a `/me` or `/notifications` endpoint or a socket event).
class UserModel {
  final String publicId;
  final String displayName;
  final bool verifyEmail;
  final bool verifyPhone;
  final int unreadNotifications;

  const UserModel({
    required this.publicId,
    required this.displayName,
    required this.verifyEmail,
    required this.verifyPhone,
    this.unreadNotifications = 0,
  });

  /// Use this right after register/login — those responses never include
  /// notification counts, so it's forced to 0 explicitly.
  factory UserModel.fromAuthResponse(Map<String, dynamic> json) {
    return UserModel(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      verifyEmail: json['verify_email'] as bool? ?? false,
      verifyPhone: json['verify_phone'] as bool? ?? false,
      unreadNotifications: 0,
    );
  }

  /// Use this for endpoints that DO return notification counts
  /// (e.g. GET /me), where the key might be present.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      verifyEmail: json['verify_email'] as bool? ?? false,
      verifyPhone: json['verify_phone'] as bool? ?? false,
      unreadNotifications: json['unread_notifications'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'public_id': publicId,
        'displayName': displayName,
        'verify_email': verifyEmail,
        'verify_phone': verifyPhone,
        'unread_notifications': unreadNotifications,
      };

  UserModel copyWith({
    String? publicId,
    String? displayName,
    bool? verifyEmail,
    bool? verifyPhone,
    int? unreadNotifications,
  }) {
    return UserModel(
      publicId: publicId ?? this.publicId,
      displayName: displayName ?? this.displayName,
      verifyEmail: verifyEmail ?? this.verifyEmail,
      verifyPhone: verifyPhone ?? this.verifyPhone,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
    );
  }

  @override
  String toString() =>
      'UserModel(publicId: $publicId, displayName: $displayName, '
      'verifyEmail: $verifyEmail, verifyPhone: $verifyPhone, '
      'unreadNotifications: $unreadNotifications)';
}