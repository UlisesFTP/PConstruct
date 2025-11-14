import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/posts.dart';
import 'package:provider/provider.dart';

class EditPostModal extends StatefulWidget {
  final Post post;
  final VoidCallback onPostUpdated;

  const EditPostModal({
    super.key,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  State<EditPostModal> createState() => _EditPostModalState();
}

class _EditPostModalState extends State<EditPostModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellenamos los campos con los datos del post
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);

    try {
      await apiClient.updatePost(
        widget.post.id,
        _titleController.text,
        _contentController.text,
      );

      widget.onPostUpdated(); // Llama al callback para refrescar
      Navigator.of(context).pop(); // Cierra el modal

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post actualizado con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Editar Publicación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'El título no puede estar vacío'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenido'),
              maxLines: 5,
              validator: (value) => (value == null || value.isEmpty)
                  ? 'El contenido no puede estar vacío'
                  : null,
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
                    : const Text('Actualizar'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
