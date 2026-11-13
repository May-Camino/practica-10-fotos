// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class AlumnoForm extends StatefulWidget {
  const AlumnoForm({super.key});

  @override
  State<AlumnoForm> createState() => _AlumnoFormState();
}

class _AlumnoFormState extends State<AlumnoForm> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();

  Future<void> insertarAlumno() async {
    final url = Uri.parse('http://localhost:8000/alumnos');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': _nombreController.text,
        'edad': int.tryParse(_edadController.text),
        'carrera': _carreraController.text,
      }),
    );

    print("Response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final alumnoIns = jsonDecode(response.body);

      final id = alumnoIns['id'];
      final nombre = alumnoIns['nombre'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alumno insertado: $id - $nombre')),
      );

      _nombreController.clear();
      _edadController.clear();
      _carreraController.clear();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error al insertar')));

      print(response.statusCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Insertar Alumno',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _edadController,
                    decoration: const InputDecoration(labelText: 'Edad'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _carreraController,
                    decoration: const InputDecoration(labelText: 'Carrera'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: insertarAlumno,
                    child: const Text('Insertar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/lista');
                    },
                    child: const Text('Ver lista de alumnos'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
