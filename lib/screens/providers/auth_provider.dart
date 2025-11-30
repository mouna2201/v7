// screens/providers/auth_provider.dart (ou presentation/providers/)
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  
  // Vérifier le rôle
  bool get isFarmer => _user?.role == 'farmer';
  bool get isEnterprise => _user?.role == 'enterprise';

  // 🔐 CONNEXION
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // 📝 INSCRIPTION
  Future<bool> register(String name, String email, String password, {String role = 'farmer'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  // ✅ VÉRIFIER L'AUTHENTIFICATION
  Future<void> checkAuth() async {
    final result = await _authService.verifyToken();
    
    if (result['success']) {
      _user = result['user'];
    } else {
      _user = null;
    }
    
    notifyListeners();
  }

  // 🚪 DÉCONNEXION
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  // 🔄 RAFRAÎCHIR LE TOKEN
  Future<void> refreshToken() async {
    await _authService.refreshToken();
  }
}