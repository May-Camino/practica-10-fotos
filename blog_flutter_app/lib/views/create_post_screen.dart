import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePostScreen extends StatefulWidget {
  final String baseUrl;

  const CreatePostScreen({super.key, required this.baseUrl});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // cajitas de texto para que el usuario escriba la info de su nuevo blog
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imgController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isLoading = false;

  // aqui enviamos la nueva publicacion al servidor mediante un POST
  Future<void> _crearPost() async {
    final titulo = _tituloController.text.trim();
    final desc = _descController.text.trim();

    // revisamos que al menos el titulo y la descripcion no vayan vacios
    if (titulo.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('el titulo y la descripcion son obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'titulo': titulo,
          'desc': desc,
          'img': _imgController.text.trim().isEmpty ? null : _imgController.text.trim(),
          'tags': _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim(),
        }),
      );

      if (!mounted) return;

      // si el servidor nos dice que se creo con exito (200 o 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('publicacion creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // nos regresamos a la pantalla anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error al crear post: ${response.body}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error de conexion: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    _imgController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Publicacion'),
        backgroundColor: const Color(0xFF398DBB),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF8FF), Color(0xFFF7FCFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.post_add,
                      size: 44,
                      color: Color(0xFF398DBB),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Nuevo Blog",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF244D68),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // campo para el titulo
                    TextField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Titulo',
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: const Color(0xFFF5FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // campo para la descripcion
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripcion',
                        prefixIcon: const Icon(Icons.description_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // campo opcional para la imagen
                    TextField(
                      controller: _imgController,
                      decoration: InputDecoration(
                        labelText: 'URL de Imagen (opcional)',
                        prefixIcon: const Icon(Icons.image_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // campo opcional para las etiquetas (tags)
                    TextField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Etiquetas / Tags (opcional)',
                        prefixIcon: const Icon(Icons.label_outline),
                        filled: true,
                        fillColor: const Color(0xFFF5FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // boton para guardar la publicacion
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _crearPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF398DBB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Publicar",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}