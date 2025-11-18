// services/sensor_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import 'auth_service.dart';

class SensorApiService {
  static const String baseUrl = AuthService.baseUrl;
  final AuthService _authService = AuthService();

  // 📊 RÉCUPÉRER TOUS LES CAPTEURS
  Future<Map<String, dynamic>> getAllSensors({int limit = 100}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/capteurs?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<SensorData> sensors = (data['data'] as List)
            .map((item) => SensorData.fromJson(item))
            .toList();

        return {
          'success': true,
          'sensors': sensors,
          'count': data['count'],
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expiré, essayer de le rafraîchir
        final newToken = await _authService.refreshToken();
        if (newToken != null) {
          return getAllSensors(limit: limit); // Réessayer
        }
        return {'success': false, 'message': 'Session expirée'};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // 📍 RÉCUPÉRER UN CAPTEUR SPÉCIFIQUE
  Future<Map<String, dynamic>> getSensorByDevice(String deviceId) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/capteurs/$deviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<SensorData> sensors = (data['data'] as List)
            .map((item) => SensorData.fromJson(item))
            .toList();

        return {
          'success': true,
          'sensors': sensors,
          'device_id': data['device_id'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // 🗑️ SUPPRIMER DES DONNÉES
  Future<Map<String, dynamic>> deleteSensor(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        return {'success': false, 'message': 'Non authentifié'};
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/capteurs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
}