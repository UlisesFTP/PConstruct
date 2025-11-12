import 'package:flutter/foundation.dart'; // Para kDebugMode

// Coincide con el schema BuildComponentRead de Pydantic
class BuildComponent {
  final String id;
  // --- ¡CORRECCIÓN AQUÍ! ---
  final int componentId; // ID del servicio de componentes (era String)
  // --- FIN DE LA CORRECCIÓN ---
  final String category;
  final String name;
  final String? imageUrl;
  final double priceAtBuildTime;

  BuildComponent({
    required this.id,
    required this.componentId,
    required this.category,
    required this.name,
    this.imageUrl,
    required this.priceAtBuildTime,
  });

  factory BuildComponent.fromJson(Map<String, dynamic> json) {
    return BuildComponent(
      id: json['id'] as String,
      // --- ¡CORRECCIÓN AQUÍ! ---
      componentId: json['component_id'] as int, // Parsear como int (era String)
      // --- FIN DE LA CORRECCIÓN ---
      category: json['category'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      priceAtBuildTime: (json['price_at_build_time'] as num).toDouble(),
    );
  }
}

// Coincide con el schema BuildSummary de Pydantic
// (Esta clase no tenía el error, se mantiene igual)
class BuildSummary {
  final String id;
  final String name;
  final String? imageUrl;
  final String userName;
  final double totalPrice;
  final DateTime createdAt;
  final bool isPublic;
  final String? cpuName;
  final String? gpuName;
  final String? ramName;

  BuildSummary({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.userName,
    required this.totalPrice,
    required this.createdAt,
    required this.isPublic,
    this.cpuName,
    this.gpuName,
    this.ramName,
  });

  factory BuildSummary.fromJson(Map<String, dynamic> json) {
    try {
      return BuildSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String?,
        userName: json['user_name'] as String,
        totalPrice: (json['total_price'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
        isPublic: json['is_public'] as bool,
        cpuName: json['cpu_name'] as String?,
        gpuName: json['gpu_name'] as String?,
        ramName: json['ram_name'] as String?,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al parsear BuildSummary: $e');
        print('JSON con error: $json');
      }
      rethrow;
    }
  }
}

// Coincide con el schema BuildRead de Pydantic
// (Esta clase no tenía el error, se mantiene igual)
class BuildRead {
  final String id;
  final String name;
  final String? description;
  final String useType; // "Gaming", "Edición", etc.
  final String? imageUrl;
  final bool isPublic;
  final String userId;
  final String userName;
  final double totalPrice;
  final DateTime createdAt;
  final List<BuildComponent> components;

  BuildRead({
    required this.id,
    required this.name,
    this.description,
    required this.useType,
    this.imageUrl,
    required this.isPublic,
    required this.userId,
    required this.userName,
    required this.totalPrice,
    required this.createdAt,
    required this.components,
  });

  factory BuildRead.fromJson(Map<String, dynamic> json) {
    try {
      var componentsList = (json['components'] as List)
          .map((compJson) => BuildComponent.fromJson(compJson))
          .toList();

      return BuildRead(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        useType: json['use_type'] as String,
        imageUrl: json['image_url'] as String?,
        isPublic: json['is_public'] as bool,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String,
        totalPrice: (json['total_price'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
        components: componentsList,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al parsear BuildRead: $e');
        print('JSON con error: $json');
      }
      rethrow;
    }
  }
}

// Coincide con el schema BuildComponentCreate de Pydantic
class BuildComponentCreate {
  // --- ¡CORRECCIÓN AQUÍ! ---
  final int componentId; // Era String
  // --- FIN DE LA CORRECCIÓN ---
  final String category;
  final String name;
  final String? imageUrl;
  final double priceAtBuildTime;

  BuildComponentCreate({
    required this.componentId,
    required this.category,
    required this.name,
    this.imageUrl,
    required this.priceAtBuildTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'component_id': componentId, // Esto ahora es un 'int'
      'category': category,
      'name': name,
      'image_url': imageUrl,
      'price_at_build_time': priceAtBuildTime,
    };
  }
}

// Coincide con el schema BuildCreate de Pydantic
// (Esta clase no tenía el error, se mantiene igual)
class BuildCreate {
  final String name;
  final String? description;
  final String useType; // "Gaming", "Edición", etc.
  final String? imageUrl;
  final bool isPublic;
  final List<BuildComponentCreate> components;

  BuildCreate({
    required this.name,
    this.description,
    required this.useType,
    this.imageUrl,
    required this.isPublic,
    required this.components,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'use_type': useType,
      'image_url': imageUrl,
      'is_public': isPublic,
      'components': components.map((c) => c.toJson()).toList(),
    };
  }
}

// Modelo para la respuesta de /check-compatibility
// (Esta clase no tenía el error, se mantiene igual)
class CompatibilityResponse {
  final bool compatible;
  final String reason;

  CompatibilityResponse({required this.compatible, required this.reason});

  factory CompatibilityResponse.fromJson(Map<String, dynamic> json) {
    return CompatibilityResponse(
      compatible: json['compatible'] as bool,
      reason: json['reason'] as String,
    );
  }
}
