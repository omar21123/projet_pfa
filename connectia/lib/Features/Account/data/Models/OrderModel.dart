enum OrderStatus { pending, preparing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.shipped:
        return 'Expédiée';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }
}

enum PaymentMethod { card, cashOnDelivery }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.card:
        return 'Carte';
      case PaymentMethod.cashOnDelivery:
        return 'À la livraison';
    }
  }
}

/// Modèle d'une commande pour l'historique.
///
/// Les champs `livreurName`/`trackingNumber`, `estimatedDeliveryDate` et
/// `ville` sont optionnels et mutuellement contextuels : une commande
/// affichera généralement l'un de ces blocs selon son statut (livreur
/// assigné, en cours d'acheminement, ou déjà livrée).
class OrderModel {
  final String id;
  final DateTime createdDate;
  final OrderStatus status;
  final String productName;
  final String productImageUrl;
  final int itemCount;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final String? livreurName;
  final String? trackingNumber;
  final DateTime? estimatedDeliveryDate;
  final String? ville;

  const OrderModel({
    required this.id,
    required this.createdDate,
    required this.status,
    required this.productName,
    required this.productImageUrl,
    required this.itemCount,
    required this.totalPrice,
    required this.paymentMethod,
    this.livreurName,
    this.trackingNumber,
    this.estimatedDeliveryDate,
    this.ville,
  });
}