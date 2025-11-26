// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  // ⚠️ CHANGEZ CETTE URL SELON VOTRE ENVIRONNEMENT
  static const String baseUrl =
      'http://localhost:3000/api'; // Émulateur Android
  // static const String baseUrl = 'http://192.168.1.X:3000/api'; // Téléphone physique

  // Stockage simple en mémoire pour le token (remplace flutter_secure_storage côté démo)
  static String? _inMemoryToken;

  // 📝 INSCRIPTION
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'farmer', // 'farmer', 'enterprise', 'admin'
    bool updateToken = true, // si false, on ne remplace pas le token courant
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
        if (updateToken) {
          _inMemoryToken = data['token'];
        }

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

  // 👨‍🌾 RÉCUPÉRER LA LISTE DES FERMIERS
  Future<List<User>> fetchFarmers() async {
    try {
      final token = await getToken();

      final response = await http.get(
        // ⚠️ Adapter cette route à ton backend réel si nécessaire
        Uri.parse('$baseUrl/users?role=farmer'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((e) => User.fromJson(e))
              .toList();
        }
        if (data is Map<String, dynamic> && data['users'] is List) {
          final list = data['users'] as List;
          return list
              .whereType<Map<String, dynamic>>()
              .map((e) => User.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Erreur fetchFarmers: $e');
      return [];
    }
  }

  // 👨‍🌾 PROFIL DU FERMIER (FORMULAIRE PARCELLE)
  Future<Map<String, dynamic>?> fetchFarmerProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      return null;
    } catch (e) {
      print('Erreur fetchFarmerProfile: $e');
      return null;
    }
  }

  // 👨‍🌾 PROFIL D'UN FERMIER PAR ID (pour l'admin)
  Future<Map<String, dynamic>?> fetchFarmerProfileById(String farmerId) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      // Ajuste l'URL si ta route backend est différente
      final response = await http.get(
        Uri.parse('$baseUrl/farmer/profile/$farmerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      return null;
    } catch (e) {
      print('Erreur fetchFarmerProfileById: $e');
      return null;
    }
  }

  Future<bool> updateFarmerProfile({
    required String parcelLocation,
    required String soilType,
    required List<String> crops,
    required double areaM2,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'parcelLocation': parcelLocation,
          'soilType': soilType,
          'crops': crops,
          'areaM2': areaM2,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur updateFarmerProfile: $e');
      return false;
    }
  }

  // 👨‍🌾 Créer / mettre à jour le profil parcelle pour un utilisateur spécifique
  // Utilisé par l'admin après la création d'un compte fermier, en passant le token du fermier.
  Future<bool> updateFarmerProfileWithToken({
    required String token,
    required String parcelLocation,
    required String soilType,
    required List<String> crops,
    required double areaM2,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/farmer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'parcelLocation': parcelLocation,
          'soilType': soilType,
          'crops': crops,
          'areaM2': areaM2,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur updateFarmerProfileWithToken: $e');
      return false;
    }
  }

  // 👤 METTRE À JOUR UN UTILISATEUR (ADMIN)
  Future<User?> updateUser({
    required String id,
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final token = await getToken();

      final body = <String, dynamic>{
        'name': name,
        'email': email,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
          return User.fromJson(data['user'] as Map<String, dynamic>);
        }
        if (data is Map<String, dynamic>) {
          return User.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print('Erreur updateUser: $e');
      return null;
    }
  }

  // 🗑️ SUPPRIMER UN UTILISATEUR (ADMIN)
  Future<bool> deleteUser(String id) async {
    try {
      final token = await getToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erreur deleteUser: $e');
      return false;
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
