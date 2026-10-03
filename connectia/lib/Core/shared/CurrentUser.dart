import 'package:connectia/Core/shared/Models/UserModel.dart';

class CurrentUser {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get displayName => _user?.displayName;
  String? get publicId => _user?.publicId;

  void set(UserModel user) => _user = user;
  void clear() => _user = null;
}
