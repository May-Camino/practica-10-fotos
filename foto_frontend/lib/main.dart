import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const Practica10App());
}

class Practica10App extends StatelessWidget {
  const Practica10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subir Foto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SubirFotoScreen(),
    );
  }
}

class SubirFotoScreen extends StatefulWidget {
  const SubirFotoScreen({super.key});

  @override
  State<SubirFotoScreen> createState() => _SubirFotoScreenState();
}

class _SubirFotoScreenState extends State<SubirFotoScreen> {
  // En Flutter Web o misma red usa http://localhost:8000 o http://TU_IP_LOCAL:8000
  // En emulador Android usa http://10.0.2.2:8000
  static const String apiBaseUrl = 'http://localhost:8000';

  final TextEditingController _descripcionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;
  bool _subiendo = false;

  Future<void> _tomarFoto() async {
    // En Web a veces no hay cámara física; si falla o quieres probar rápido,
    // puedes cambiar ImageSource.camera por ImageSource.gallery
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _imagenSeleccionada = foto;
        _imagenBytes = bytes;
      });
    }
  }

  Future<void> _subirFoto() async {
    final descripcion = _descripcionController.text.trim();

    if (_imagenSeleccionada == null || _imagenBytes == null) {
      _mostrarMensaje('Primero selecciona una foto.');
      return;
    }

    if (descripcion.isEmpty) {
      _mostrarMensaje('Escribe una descripción.');
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      final uri = Uri.parse('$apiBaseUrl/fotos');
      final request = http.MultipartRequest('POST', uri)
        ..fields['descripcion'] = descripcion
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            _imagenBytes!,
            filename: _imagenSeleccionada!.name,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _mostrarMensaje(data['msg']?.toString() ?? 'Foto subida correctamente');
        setState(() {
          _imagenSeleccionada = null;
          _imagenBytes = null;
          _descripcionController.clear();
        });
      } else {
        _mostrarMensaje('Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _subiendo = false;
        });
      }
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Foto'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imagenBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imagenBytes!,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No hay imagen seleccionada',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 28),
            Center(
              child: ElevatedButton(
                onPressed: _subiendo ? null : _tomarFoto,
                child: const Text('Tomar Foto'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: _subiendo ? null : _subirFoto,
                child: _subiendo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subir a API'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
