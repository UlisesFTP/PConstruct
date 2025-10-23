import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:my_app/core/api/api_client.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart'; // <-- ASEGÚRATE DE TENER ESTE IMPORT
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePostModal extends StatefulWidget {
  final VoidCallback onPostCreated;

  // ❌ ELIMINADO: Ya no necesitamos recibir el apiClient aquí.
  // final ApiClient apiClient;

  const CreatePostModal({
    super.key,
    required this.onPostCreated,
    // ❌ ELIMINADO: Se quita del constructor.
    // required this.apiClient,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _mediaUrlController = TextEditingController();

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _youtubeVideoId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  void _handleMediaUrlChanged(String url) {
    setState(() {
      _selectedImageBytes = null;
      _youtubeVideoId = YoutubePlayer.convertUrlToId(url);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _mediaUrlController.clear();
        _youtubeVideoId = null;
        _selectedImageBytes = bytes;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No se seleccionó ninguna imagen o el formato no es compatible.",
          ),
          backgroundColor: Color.fromARGB(255, 34, 34, 33),
        ),
      );
    }
  }

  // ✅ FUNCIÓN CORREGIDA
  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalImageUrl; // Aquí guardaremos la URL final

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      // --- LÓGICA DE SUBIDA ---
      if (_selectedImageBytes != null) {
        // CASO 1: El usuario seleccionó una imagen local

        // 1. Pedir la firma segura al backend
        final signatureData = await apiClient.getUploadSignature();
        final signature = signatureData['signature'];
        final timestamp = signatureData['timestamp'];
        final apiKey =
            signatureData['api_key']; // El backend la envía como 'api_key'

        // 2. Obtenemos el cloud_name
        final cloudName = "dlmpkrzrg"; // <-- TU CLOUD NAME

        // 3. Crear la URL de la API de Cloudinary
        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        );

        // 4. Crear la petición HTTP 'multipart/form-data'
        var request = http.MultipartRequest('POST', uri);

        // 5. Adjuntar los campos de la firma
        request.fields['api_key'] = apiKey;
        request.fields['timestamp'] = timestamp.toString();
        request.fields['signature'] = signature;
        request.fields['folder'] = 'pconstruct_posts';
        request.fields['upload_preset'] = 'ml_default'; // Cloudinary lo pide

        // 6. Adjuntar el archivo
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // Este es el nombre de campo que Cloudinary espera
            _selectedImageBytes!,
            filename:
                'pconstruct_upload_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );

        // 7. Enviar la petición
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          // 8. ¡Éxito! Obtener la URL segura de la respuesta
          final jsonResponse = json.decode(responseBody);
          finalImageUrl = jsonResponse['secure_url'];
        } else {
          // Si la subida a Cloudinary falla
          throw Exception(
            'Error al subir la imagen a Cloudinary: ${responseBody}',
          );
        }
      } else if (_youtubeVideoId != null) {
        // CASO 2: El usuario pegó una URL de YouTube
        finalImageUrl = _mediaUrlController.text;
      } else if (_mediaUrlController.text.isNotEmpty) {
        // CASO 3: El usuario pegó una URL de imagen estática
        finalImageUrl = _mediaUrlController.text;
      }
      // --- FIN LÓGICA DE SUBIDA ---

      // 9. Enviar el post a nuestro backend con la URL final
      await apiClient.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageUrl: finalImageUrl,
      );

      widget.onPostCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la publicación: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // El resto del widget (la UI) se mantiene exactamente igual.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear Nueva Publicación',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) =>
                  value!.isEmpty ? 'El título no puede estar vacío' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenido (texto)'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mediaUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de imagen o YouTube',
              ),
              onChanged: _handleMediaUrlChanged,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text("o", style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Seleccionar Imagen Local'),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImageBytes != null)
              Image.memory(
                _selectedImageBytes!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            if (_youtubeVideoId != null)
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: _youtubeVideoId!,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
                showVideoProgressIndicator: true,
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
