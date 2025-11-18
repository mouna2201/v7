// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  // ⚠️ CHANGEZ CETTE URL SELON VOTRE ENVIRONNEMENT
  static const String baseUrl = 'http://localhost:3000/api'; // Émulateur Android
  // static const String baseUrl = 'http://192.168.1.X:3000/api'; // Téléphone physique

  // Stockage simple en mémoire pour le token (remplace flutter_secure_storage côté démo)
  static String? _inMemoryToken;

  // 📝 INSCRIPTION
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'farmer', // 'farmer', 'enterprise', 'admin'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _inMemoryToken = data['token'];

        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur inscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // 🔐 CONNEXION
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _inMemoryToken = data['token'];

        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Identifiants incorrects',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // ✅ VÉRIFIER LE TOKEN
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'Aucun token trouvé'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': User.fromJson(data['user']),
        };
      } else {
        await logout();
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur vérification: $e'};
    }
  }

  // 🔄 RAFRAÎCHIR LE TOKEN
  Future<String?> refreshToken() async {
    try {
      final token = await getToken();

      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/users/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        _inMemoryToken = newToken;
        return newToken;
      }

      return null;
    } catch (e) {
      print('Erreur refresh token: $e');
      return null;
    }
  }

  // 📱 MÉTHODES UTILITAIRES
  Future<String?> getToken() async {
    return _inMemoryToken;
  }

  Future<void> logout() async {
    _inMemoryToken = null;
  }

  Future<bool> isLoggedIn() async {
    return _inMemoryToken != null;
  }
}
