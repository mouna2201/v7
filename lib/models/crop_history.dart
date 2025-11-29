// models/crop_history.dart
class CropHistoryRecord {
  final String id;
  final String userId;
  final String location;
  final String cropType;
  final double area; // en m²
  final String soilType;
  final double waterAmount; // en litres
  final DateTime createdAt;

  CropHistoryRecord({
    required this.id,
    required this.userId,
    required this.location,
    required this.cropType,
    required this.area,
    required this.soilType,
    required this.waterAmount,
    required this.createdAt,
  });

  factory CropHistoryRecord.fromJson(Map<String, dynamic> json) {
    // Gestion de la date avec plusieurs formats possibles
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Erreur parsing date string: $dateValue');
          return DateTime.now();
        }
      }
      
      if (dateValue is int) {
        // Si c'est un timestamp en millisecondes
        if (dateValue > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(dateValue);
        } else {
          // Si c'est un timestamp en secondes
          return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
        }
      }
      
      if (dateValue is Map) {
        // Format MongoDB/Mongoose avec $date
        if (dateValue['\$date'] != null) {
          return parseDate(dateValue['\$date']);
        }
      }
      
      return DateTime.now();
    }

    return CropHistoryRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      cropType: (json['cropType'] ?? json['crop'] ?? '').toString(),
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      soilType: (json['soilType'] ?? '').toString(),
      waterAmount: (json['waterAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'location': location,
      'cropType': cropType,
      'area': area,
      'soilType': soilType,
      'waterAmount': waterAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
