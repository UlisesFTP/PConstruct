import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/core/api/api_client.dart';

class ProfilePictureModal extends StatefulWidget {
  final ApiClient apiClient; // Recibe el ApiClient

  const ProfilePictureModal({super.key, required this.apiClient});

  @override
  State<ProfilePictureModal> createState() => _ProfilePictureModalState();
}

class _ProfilePictureModalState extends State<ProfilePictureModal> {
  bool _isLoading = false;
  String? _imageUrl; // La URL de Cloudinary
  Uint8List? _imageBytes; // La imagen en memoria para la vista previa

  // --- FUNCIÓN DE SUBIDA CORREGIDA (BASADA EN create_post_modal.dart) ---
  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Seleccionar imagen
      final ImagePicker picker = ImagePicker();
      final XFile? imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      // Si el usuario cancela, comprueba si sigue montado
      if (imageFile == null) {
        if (mounted) {
          // <-- Comprobación de seguridad
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final bytes = await imageFile.readAsBytes();
      // Comprueba si sigue montado DESPUÉS del 'await'
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });

      // 2. Obtener firma (await)
      final signatureData = await widget.apiClient.getProfileUploadSignature();
      if (!mounted) return; // <-- Comprobación de seguridad

      final String signature = signatureData['signature'];
      final int timestamp = signatureData['timestamp'];
      final String apiKey = signatureData['api_key'];

      final String cloudName = 'dlmpkrzrg';
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // 3. Crear la petición
      final request = http.MultipartRequest('POST', url);
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.fields['folder'] = 'pconstruct_avatars';
      request.fields['upload_preset'] = 'ml_default'; // El campo que faltaba
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: imageFile.name),
      );

      // 6. Enviar la petición (await)
      final response = await request.send();
      if (!mounted) return; // <-- Comprobación de seguridad

      final responseBody = await response.stream.bytesToString();
      if (!mounted) return; // <-- Comprobación de seguridad

      if (response.statusCode == 200) {
        // 7. Éxito
        final responseData = jsonDecode(responseBody);
        setState(() {
          _imageUrl = responseData['secure_url'];
          _isLoading = false;
        });
      } else {
        throw Exception('Error al subir a Cloudinary: ${responseBody}');
      }
    } catch (e) {
      print("Error al subir imagen: $e");

      // --- LA CORRECCIÓN MÁS IMPORTANTE ---
      // Comprueba si el widget sigue montado ANTES de llamar a setState/Scaffold
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la imagen. Inténtalo de nuevo.'),
          ),
        );
      }
      // --- FIN DE LA CORRECCIÓN ---
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Foto de Perfil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // --- Vista previa circular ---
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF2A2A2A),
            backgroundImage: _imageBytes != null
                ? MemoryImage(_imageBytes!)
                : null,
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF00C5A0))
                : (_imageBytes == null)
                ? const Icon(Icons.person, size: 60, color: Color(0xFFA0A0A0))
                : null,
          ),
          const SizedBox(height: 24),

          // --- Botón de Subir ---
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickAndUploadImage,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _imageUrl == null ? 'Seleccionar Foto' : 'Cambiar Foto',
            ),
          ),
          const SizedBox(height: 16),

          // --- Botón de Guardar ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC7384D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => Navigator.of(context).pop(_imageUrl),
            child: const Text('Guardar y Continuar'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
