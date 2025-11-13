import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/api/builds_chat_api.dart';

class BuildsChatSheet extends StatefulWidget {
  final BuildsChatApi api;
  const BuildsChatSheet({super.key, required this.api});
  @override
  State<BuildsChatSheet> createState() => _BuildsChatSheetState();
}

class _BuildsChatSheetState extends State<BuildsChatSheet> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  bool _loading = false;

  Future<void> _send() async {
    const String kApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ); // <-- pon aquí tu gateway

    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage('user', text));
      _loading = true;
      _input.clear();
    });

    try {
      final uri = Uri.parse('$kApiBaseUrl/api/v1/builds/chat');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Forward-Timeout': '30',
        },
        body: jsonEncode({
          'history': _messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'message': text,
        }),
      );

      String reply;
      if (res.statusCode != 200) {
        reply = 'Error ${res.statusCode}.';
      } else {
        final body = res.body.trim();
        if (body.isEmpty) {
          reply = 'La respuesta llegó vacía.';
        } else {
          try {
            final data = jsonDecode(body);
            if (data is Map && data['message'] != null) {
              reply = data['message'].toString();
            } else if (data is String) {
              reply = data;
            } else {
              reply = body;
            }
          } catch (_) {
            reply = body; // texto plano o markdown
          }
        }
      }

      setState(() {
        _messages.add(ChatMessage('assistant', reply));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('assistant', 'Error de red: $e'));
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final bg = const Color.fromARGB(255, 27, 27, 30);
    final bubbleAssistant = const Color(0xFF2A2B31);
    final bubbleUser = const Color(0xFFC7384D);

    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, controller) {
                  return Column(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Yarbis',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isUser = m.role == 'user';
                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.8,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? bubbleUser
                                        : bubbleAssistant,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(
                                        isUser ? 14 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isUser ? 4 : 14,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    m.content,
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.92),
                                      fontSize: 14,
                                      height: 1.28,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _input,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white70,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText:
                                      "Pregunta sobre requisitos, rendimiento o compatibilidad",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2A2B31),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _loading ? null : _send,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
