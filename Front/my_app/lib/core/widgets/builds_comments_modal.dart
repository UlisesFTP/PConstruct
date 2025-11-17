import 'package:flutter/material.dart';
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/models/build_comment.dart'; // <-- CAMBIO
import 'package:my_app/models/user_info.dart'; // <-- CAMBIO
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class BuildsCommentsModal extends StatefulWidget {
  final String buildId; // <-- CAMBIO: int postId a String buildId
  final bool canComment;

  const BuildsCommentsModal({
    super.key,
    required this.buildId, // <-- CAMBIO
    this.canComment = true,
  });

  @override
  State<BuildsCommentsModal> createState() => _BuildsCommentsModalState();
}

class _BuildsCommentsModalState extends State<BuildsCommentsModal> {
  List<BuildComment>? _comments;
  Future<void>? _loadCommentsFuture;
  // --- FIN CAMBIO ---
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    // Guardamos el Future en una variable para el FutureBuilder
    _loadCommentsFuture = _loadComments();
  }

  Future<void> _loadComments() async {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    try {
      // Obtenemos los comentarios y los guardamos en la lista local
      final commentsList = await apiClient.getBuildComments(widget.buildId);
      if (mounted) {
        setState(() {
          _comments = commentsList;
        });
      }
    } catch (e) {
      // Si falla la carga inicial, lo guardamos para mostrar en el builder
      if (mounted) {
        setState(() {
          _comments = null; // Para que el builder muestre error
        });
      }
      // Relanzamos para que el FutureBuilder lo atrape
      rethrow;
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;
    if (_isPosting) return;
    _isPosting = true;
    setState(() {});

    try {
      final apiClient = Provider.of<ApiClient>(context, listen: false);

      // --- INICIO DE CAMBIO ---
      // 1. Enviamos el comentario y ESPERAMOS la respuesta
      final newComment = await apiClient.postBuildComment(
        widget.buildId,
        _commentController.text,
      );

      _commentController.clear();

      // 2. Añadimos el nuevo comentario (devuelto por la API) a la lista local
      setState(() {
        _comments?.add(newComment);
      });
      // --- FIN DE CAMBIO ---
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al enviar comentario: $e')));
    } finally {
      _isPosting = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Comentarios de la Build', // <-- CAMBIO
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(height: 24),

            Expanded(
              child: FutureBuilder<void>(
                future: _loadCommentsFuture, // <-- Usa el Future inicial
                builder: (context, snapshot) {
                  // 1. Manejar la carga inicial
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. Manejar el error de carga inicial
                  if (snapshot.hasError || _comments == null) {
                    return Center(
                      child: Text(
                        'Error al cargar comentarios: ${snapshot.error}',
                      ),
                    );
                  }

                  // 3. Manejar lista vacía (después de cargar)
                  if (_comments!.isEmpty) {
                    return const Center(child: Text('No hay comentarios.'));
                  }

                  // 4. Mostrar la lista local
                  final comments = _comments!; // <-- Usa la lista local
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      // final bool hasAvatar = comment.user.avatarUrl != null; // <-- BuildComment no tiene avatar aún

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color.fromARGB(
                            255,
                            200,
                            74,
                            74,
                          ),
                          // TODO: Añadir avatar cuando el backend lo envíe
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: Color.fromARGB(179, 0, 0, 0),
                          ),
                        ),
                        title: Text(
                          comment.user.userUsername ?? 'Usuario', // <-- CAMBIO
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          comment.content,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          timeago.format(comment.createdAt, locale: 'es_short'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // --- Campo para Escribir Comentario ---
            if (widget.canComment) ...[
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
          ],
        ),
      ),
    );
  }
}
