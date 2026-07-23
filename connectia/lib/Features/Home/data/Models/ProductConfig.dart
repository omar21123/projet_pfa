/// Une option de configuration produit (ex: Taille -> [S, M, L]).
class ProductConfig {
  final String name;
  final List<String> options;

  const ProductConfig({required this.name, required this.options});

  factory ProductConfig.fromJson(Map<String, dynamic> json) {
    return ProductConfig(
      name: json['Name'] as String,
      options: List<String>.from(json['Options'] as List),
    );
  }
}

/// Moyens de paiement acceptés pour un produit.
enum PaymentMethod { cod, online }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cod:
        return 'Paiement à la livraison';
      case PaymentMethod.online:
        return 'Paiement en ligne';
    }
  }

  // Icônes assignées dans PaymentMethodBadges (dépend de Flutter, pas
  // importé ici pour garder ce fichier pur Dart/portable).
}