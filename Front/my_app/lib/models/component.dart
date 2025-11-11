// lib/models/component.dart
import 'package:my_app/models/offer.dart';
import 'package:my_app/models/component_review.dart';

// 1. Modelo para la Card (de GET /api/v1/components/)
// Coincide con el schema 'ComponentCard' de FastAPI
class ComponentCard {
  final int id;
  final String name;
  final String category;
  final String? brand;
  final String? imageUrl;
  final double? price; // Precio de la mejor oferta
  final String? store; // Tienda de la mejor oferta
  final String? link; // Link de la mejor oferta

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

  factory ComponentCard.fromJson(Map<String, dynamic> json) {
    return ComponentCard(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      // El JSON envía 'price' como String (o num), lo convertimos a double
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString())
          : null,
      store: json['store'] as String?,
      link: json['link'] as String?,
    );
  }
}

// 2. Modelo para la página de Detalle (de GET /api/v1/components/{id})
// Coincide con el schema 'ComponentDetail' de FastAPI
class ComponentDetail {
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
