// models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'farmer', 'enterprise', 'admin'
  final String? parcelLocation;
  final String? soilType;
  final List<String> crops;
  final double? areaM2;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.parcelLocation,
    this.soilType,
    List<String>? crops,
    this.areaM2,
  }) : crops = crops ?? [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'farmer',
      parcelLocation: json['parcelLocation']?.toString(),
      soilType: json['soilType']?.toString(),
      crops: json['crops'] is List 
          ? List<String>.from(json['crops'].map((e) => e.toString()))
          : (json['crops'] is String ? [json['crops'] as String] : []),
      areaM2: json['areaM2']?.toDouble() ?? 
             (json['area']?.toDouble() ?? 
              (json['surface'] is String ? double.tryParse(json['surface']) : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'parcelLocation': parcelLocation,
      'soilType': soilType,
      'crops': crops,
      'areaM2': areaM2,
    };
  }

  // Méthodes utilitaires
  bool get isFarmer => role == 'farmer';
  bool get isEnterprise => role == 'enterprise';
  bool get isAdmin => role == 'admin';
}





/*class UserModel {
  final String id;       // simple id
  final String name;
  final String email;
  final String password; // stocké en clair ici (demo). Pour prod -> hasher.
  final String role;     // "farmer" or "enterprise" or "enterprise_farmer"

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        role: json['role'] as String,
      );
}*/
