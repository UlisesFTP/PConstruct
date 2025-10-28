// lib/models/component.dart

class Component {
  final int id;
  final String name;
  final String categoria;
  final String marca;
  final String uso;
  final double price;
  final List<String> stores;
  final String? imageUrl; // <-- NUEVO CAMPO AÑADIDO

  Component({
    required this.id,
    required this.name,
    required this.categoria,
    required this.marca,
    required this.uso,
    required this.price,
    required this.stores,
    this.imageUrl, // <-- AÑADIDO AL CONSTRUCTOR
  });

  // TODO: Añadir un factory constructor .fromJson() cuando tengamos el endpoint
}
