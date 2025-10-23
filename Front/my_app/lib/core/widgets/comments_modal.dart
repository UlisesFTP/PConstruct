import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/comment.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsModal extends StatefulWidget {
  final int postId;

  const CommentsModal({super.key, required this.postId});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() {
    // Carga los comentarios usando el ApiClient del Provider
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    _commentsFuture = apiClient.getComments(widget.postId);
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      await apiClient.postComment(widget.postId, _commentController.text);

      _commentController.clear(); // Limpia el campo de texto
      // Vuelve a cargar los comentarios para mostrar el nuevo
      setState(() {
        _loadComments();
      });
    } catch (e) {
      // Manejar error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar comentario: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding para el teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7, // 70% de la pantalla
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Título del Modal ---
            Text(
              'Comentarios',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(height: 24),

            // --- Lista de Comentarios ---
            Expanded(
              child: FutureBuilder<List<Comment>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No hay comentarios.'));
                  }

                  final comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ), // (Usar avatar real en el futuro)
                        ),
                        title: Text(
                          comment.authorUsername ?? 'Usuario ${comment.userId}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(comment.content),
                        trailing: Text(
                          timeago.format(comment.createdAt, locale: 'es_short'),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // --- Campo para Escribir Comentario ---
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.send),
                  onPressed: _postComment,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
