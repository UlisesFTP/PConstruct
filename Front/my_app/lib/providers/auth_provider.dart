import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVO
import 'dart:convert'; // <-- NUEVO (Para guardar el usuario)

// Un modelo simple para el usuario
class User {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  User({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl, // <-- AÑADIR ESTA LÍNEA
    };
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = true; // <-- NUEVO: Empezamos en estado de carga

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading; // <-- NUEVO: Getter

  // NUEVO: El constructor ahora intenta cargar al usuario automáticamente
  AuthProvider() {
    _tryAutoLogin();
  }

  // NUEVO: Método que se ejecuta al iniciar la app
  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // Si no hay token, no estamos logueados.
    if (!prefs.containsKey('token')) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Si hay un token, lo cargamos
    _token = prefs.getString('token');

    // Cargamos los datos del usuario (guardados como string JSON)
    final userDataString = prefs.getString('user');
    if (userDataString != null) {
      _user = User.fromJson(jsonDecode(userDataString));
    }

    _isLoading = false;
    notifyListeners();
  }

  // MODIFICADO: Ahora es 'async' y guarda en SharedPreferences
  Future<void> login(Map<String, dynamic> loginResponse) async {
    print('--- RECIBIDO EN AUTH_PROVIDER (JSON crudo) ---');
    // Usamos jsonEncode para imprimirlo de forma legible
    print(jsonEncode(loginResponse));
    // --------------------------------------------------

    _token = loginResponse['access_token'];
    _user = User.fromJson(loginResponse['user']);

    print('--- VALOR PARSEADO EN EL OBJETO User ---');
    print('User ID: ${_user?.id}');
    print('Username: ${_user?.username}');
    print('Avatar URL: ${_user?.avatarUrl}');
    print('--------------------------------------');
    // ------------------------------------

    // Guardamos en el dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    // Guardamos el usuario como un string JSON
    await prefs.setString('user', jsonEncode(loginResponse['user']));

    notifyListeners();
  }

  // MODIFICADO: Ahora es 'async' y limpia SharedPreferences
  Future<void> logout() async {
    _token = null;
    _user = null;

    // Limpiamos el dispositivo
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }
}
