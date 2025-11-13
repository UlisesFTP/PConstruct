import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;
  ChatMessage(this.role, this.content);
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class BuildsChatApi {
  final String baseUrl;
  BuildsChatApi(this.baseUrl);

  Future<String> send(List<ChatMessage> history, String message) async {
    final uri = Uri.parse('$baseUrl/api/v1/builds/chat');
    http.Response res;

    try {
      res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // opcional: si tu gateway usa el header para timeout
          'X-Forward-Timeout': '30',
        },
        body: jsonEncode({
          'history': history.map((m) => m.toJson()).toList(),
          'message': message,
        }),
      );
    } catch (e) {
      // Error de red (no llegó a 200/500)
      return 'No pude conectar con el servicio en este momento.';
    }

    if (res.statusCode != 200) {
      // Solo aquí lanzamos, para que la UI muestre la burbuja de error
      throw Exception('chat_error ${res.statusCode}');
    }

    final body = res.body;
    if (body.isEmpty) {
      // 200 pero vacío
      return 'La respuesta llegó vacía. Intenta con más detalles (resolución/preset/FPS objetivo).';
    }

    // Intento 1: JSON con {"message": "..."}
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (data is String) {
        return data; // texto JSON-quoted
      }
      // Cualquier otra estructura: devuélvela como texto
      return body;
    } catch (_) {
      // No era JSON válido: devuelvo texto plano tal cual
      return body;
    }
  }
}
