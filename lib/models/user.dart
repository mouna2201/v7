// models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'farmer', 'enterprise', 'admin'

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'farmer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
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
