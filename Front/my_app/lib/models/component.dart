// lib/models/component.dart
import 'package:my_app/models/offer.dart';
import 'package:my_app/models/component_review.dart';

// 1. Modelo para la Card (de GET /api/v1/components/)
class ComponentCard {
  final int id;
  final String name;
  final String category;
  final String? brand;
  final String? imageUrl;
  final double? price;
  final String? store;
  final String? link;

  ComponentCard({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.imageUrl,
    this.price,
    this.store,
    this.link,
  });

  // --- ¡FÁBRICA CORREGIDA Y ROBUSTA! ---
  factory ComponentCard.fromJson(Map<String, dynamic> json) {
    return ComponentCard(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,

      // Maneja Decimal/String/int/double
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString())
          : null,

      store: json['store'] as String?,

      // Maneja HttpUrl/String
      link: (json['link'] != null)
          ? json['link']
                .toString() // <-- ¡AÑADIR .toString()!
          : null,
    );
  }
  // --- FIN DE LA CORRECCIÓN ---
}

// 2. Modelo para la página de Detalle
class ComponentDetail {
  // ... (El resto de la clase ComponentDetail se mantiene igual) ...
  final int id;
  final String name;
  final String category;
  final String? brand;
  final String? imageUrl;
  final String? description;
  final double? averageRating;
  final int reviewCount;
  final List<Offer> offers;
  final List<ComponentReview> reviews;

  ComponentDetail({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.imageUrl,
    this.description,
    this.averageRating,
    required this.reviewCount,
    required this.offers,
    required this.reviews,
  });

  factory ComponentDetail.fromJson(Map<String, dynamic> json) {
    var offersList = (json['offers'] as List<dynamic>)
        .map((offerJson) => Offer.fromJson(offerJson as Map<String, dynamic>))
        .toList();

    var reviewsList = (json['reviews'] as List<dynamic>)
        .map(
          (reviewJson) =>
              ComponentReview.fromJson(reviewJson as Map<String, dynamic>),
        )
        .toList();

    return ComponentDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      averageRating: (json['average_rating'] != null)
          ? double.tryParse(json['average_rating'].toString())
          : null,
      reviewCount: json['review_count'] as int,
      offers: offersList,
      reviews: reviewsList,
    );
  }
}
