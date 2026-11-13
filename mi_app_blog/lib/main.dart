import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final txtCorreo = TextEditingController();
  final txtPassword = TextEditingController();

  String api = "http://127.0.0.1:8000";

  Future<void> login() async {
    try {
      final response = await http.post(
        Uri.parse("$api/Login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mail": txtCorreo.text,
          "password": txtPassword.text,
        }),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenido ${data['nom_usr']}")),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response.body)));
      }
    } catch (e) {
      print(e);
    }
  }

  void abrirRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ice_skating, size: 80, color: Colors.blue),

                    const SizedBox(height: 10),

                    const Text(
                      "Ice Skating Blog",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: txtCorreo,
                      decoration: const InputDecoration(
                        labelText: "Correo",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: txtPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        child: const Text("Iniciar Sesión"),
                      ),
                    ),

                    TextButton(
                      onPressed: abrirRegistro,
                      child: const Text("Crear cuenta"),
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

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final txtNombre = TextEditingController();
  final txtCorreo = TextEditingController();
  final txtPassword = TextEditingController();
  final txtDireccion = TextEditingController();

  String api = "http://127.0.0.1:8000";

  Future<void> registrar() async {
    try {
      final response = await http.post(
        Uri.parse("$api/RegistroUsuario"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nom_usr": txtNombre.text,
          "mail": txtCorreo.text,
          "password": txtPassword.text,
          "dir_usr": txtDireccion.text,
        }),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Usuario registrado")));

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(response.body)));
      }
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: txtNombre,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: txtCorreo,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            TextField(
              controller: txtPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            TextField(
              controller: txtDireccion,
              decoration: const InputDecoration(labelText: "Dirección"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: registrar, child: const Text("Guardar")),
          ],
        ),
      ),
    );
  }
}
