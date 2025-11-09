// lib/models/pricing.dart
import 'dart:convert';

class PriceOffer {
  final String name;
  final double price;
  final String link;
  final String store;

  PriceOffer({
    required this.name,
    required this.price,
    required this.link,
    required this.store,
  });

  factory PriceOffer.fromMap(Map<String, dynamic> m) => PriceOffer(
    name: (m['name'] ?? '').toString(),
    price: (m['price'] is num)
        ? (m['price'] as num).toDouble()
        : double.tryParse('${m['price']}') ?? 0.0,
    link: (m['link'] ?? '').toString(),
    store: (m['store'] ?? '').toString(),
  );
}

typedef PricingResult = Map<String, List<PriceOffer>>;

PricingResult parsePricing(dynamic jsonBody) {
  final Map<String, dynamic> root = (jsonBody is String)
      ? json.decode(jsonBody) as Map<String, dynamic>
      : (jsonBody as Map<String, dynamic>);
  final out = <String, List<PriceOffer>>{};
  for (final entry in root.entries) {
    final list = (entry.value as List?) ?? const [];
    out[entry.key] = list
        .map((e) => PriceOffer.fromMap(e as Map<String, dynamic>))
        .toList();
  }
  return out;
}
