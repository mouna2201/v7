import 'package:flutter/foundation.dart';

class Parcel with ChangeNotifier {
  final String id;
  final String name;
  final double size; // en hectares
  final String location;
  final DateTime createdAt;

  Parcel({
    required this.id,
    required this.name,
    required this.size,
    required this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ParcelProvider with ChangeNotifier {
  final List<Parcel> _parcels = [];

  List<Parcel> get parcels => [..._parcels];

  Future<void> addParcel({
    required String name,
    required double size,
    required String location,
  }) async {
    // En production, vous feriez une requête API ici
    final newParcel = Parcel(
      id: DateTime.now().toString(),
      name: name,
      size: size,
      location: location,
    );
    
    _parcels.add(newParcel);
    notifyListeners();
    
    // Simuler un appel réseau
    await Future.delayed(const Duration(seconds: 1));
  }

  // Ajoutez d'autres méthodes comme updateParcel, deleteParcel, fetchParcels, etc.
}
