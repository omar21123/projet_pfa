import 'package:connectia/Core/enums/EnEnvironment.dart';

class ApiEnvironment {
  static Environment current = Environment.staging;

  static String get baseUrl {
    switch (current) {
      case Environment.dev:
        return 'https://api-dev.example.com'; // TODO: replace
      case Environment.staging:
        return 'https://api.staging.datchstore.com/api';
      case Environment.prod:
        return 'https://api.example.com'; // TODO: replace
    }
  }
}
