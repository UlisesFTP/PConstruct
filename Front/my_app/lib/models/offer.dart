// lib/models/offer.dart

class Offer {
  final int id;
  final String store;
  final double price; // Lo convertiremos de Decimal/String a double
  final String link;
  final DateTime lastUpdated;

  Offer({
    required this.id,
    required this.store,
    required this.price,
    required this.link,
    required this.lastUpdated,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as int,
      store: json['store'] as String,
      // El JSON envía 'price' como String (o num), lo convertimos a double
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      link: json['link'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}
