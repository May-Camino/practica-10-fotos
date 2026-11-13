import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class PostDetailScreen extends StatefulWidget {
  final int blogId;
  final String baseUrl;
  final int currentUserId; // aqui recibimos el id del usuario actual

  const PostDetailScreen({
    super.key,
    required this.blogId,
    required this.baseUrl,
    required this.currentUserId, // lo pedimos de forma obligatoria
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _postDetail;
  bool _isLoading = true;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }

  // aqui traemos la informacion detallada del post y sus comentarios
  Future<void> _fetchPostDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/posts/${widget.blogId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _postDetail = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        _showSnackBar('Error al obtener detalle del post');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error de conexión: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // aqui enviamos un comentario nuevo al servidor usando el id real del usuario
  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/comentarios'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'comentario': text,
          'usr_id': widget.currentUserId, // <--- se guarda con el id del usuario que inicio sesion
          'blog_id': widget.blogId,
        }),
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        _showSnackBar('Comentario publicado');
        _fetchPostDetail();
      } else {
        _showSnackBar('No se pudo publicar el comentario');
      }
    } catch (e) {
      _showSnackBar('Error de envío: $e');
    }
  }

  // aqui borramos un comentario propio mandando su id y validando el usuario
  Future<void> _deleteComment(int commentId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${widget.baseUrl}/comentarios/$commentId?usr_id=${widget.currentUserId}',
        ),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Comentario eliminado');
        _fetchPostDetail();
      } else {
        _showSnackBar('No se pudo eliminar el comentario');
      }
    } catch (e) {
      _showSnackBar('Error al eliminar: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _postDetail != null ? _postDetail!['titulo'] : 'Detalle del Blog',
        ),
        backgroundColor: const Color(0xFF398DBB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _postDetail == null
          ? const Center(child: Text('No se pudo cargar el blog'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _postDetail!['titulo'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244D68),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _postDetail!['desc'] ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Divider(height: 30),
                  const Text(
                    "Comentarios",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244D68),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _postDetail!['comentarios'].isEmpty
                        ? const Center(child: Text('Aún no hay comentarios'))
                        : ListView.builder(
                            itemCount: _postDetail!['comentarios'].length,
                            itemBuilder: (context, index) {
                              final item = _postDetail!['comentarios'][index];

                              // comparamos si el comentario lo escribiste tu para habilitar el boton de borrar
                              final bool isMine =
                                  item['usr_id'] == widget.currentUserId;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    item['nom_usr'] ?? 'Anónimo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(item['comentario'] ?? ''),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['fecha'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // si es tuyo, aparece el icono de basura para borrarlo
                                  trailing: isMine
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _deleteComment(item['id_com']);
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _addComment,
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF398DBB),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
