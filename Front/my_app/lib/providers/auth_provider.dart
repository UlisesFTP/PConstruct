import 'package:flutter/material.dart';
// Importa tu modelo de Usuario si lo tienes en un archivo separado
// import 'package:my_app/models/user.dart';

// Un modelo simple para el usuario
class User {
  final int id;
  final String username;
  final String email;
  // Añade más campos si los necesitas
  User({required this.id, required this.username, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'], // O 'id' dependiendo de tu respuesta final
      username: json['username'],
      email: json['email'],
    );
  }
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  void login(Map<String, dynamic> loginResponse) {
    _token = loginResponse['access_token'];
    _user = User.fromJson(loginResponse['user']);
    // Notifica a todos los widgets que están "escuchando" que el estado ha cambiado.
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
