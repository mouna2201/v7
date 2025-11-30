import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import 'dart:developer';

class EnterpriseAddUserScreen extends StatefulWidget {
  final String role; // 'farmer' ou 'superviseur'

  const EnterpriseAddUserScreen({super.key, required this.role});

  @override
  State<EnterpriseAddUserScreen> createState() =>
      _EnterpriseAddUserScreenState();
}

class _EnterpriseAddUserScreenState extends State<EnterpriseAddUserScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _parcelLocation = TextEditingController();
  final _parcelCrops = TextEditingController();
  final _parcelArea = TextEditingController();
  String _soilType = 'sableux';
  bool _loading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _parcelLocation.dispose();
    _parcelCrops.dispose();
    _parcelArea.dispose();
    super.dispose();
  }

  String get userRoleDisplay {
    return widget.role == 'superviseur' ? 'Superviseur' : 'Fermier';
  }

  Future<void> _addUser() async {
    if (!mounted) return;

    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      _showErrorSnackBar('Nom, email et mot de passe sont obligatoires');
      return;
    }

    final location = _parcelLocation.text.trim();
    final cropsText = _parcelCrops.text.trim();
    final areaText = _parcelArea.text.trim();

    if (location.isEmpty || cropsText.isEmpty || areaText.isEmpty) {
      _showErrorSnackBar('Tous les champs de la parcelle sont obligatoires');
      return;
    }

    double? area;
    try {
      area = double.parse(areaText.replaceAll(',', '.'));
      if (area <= 0) throw FormatException('La surface doit être positive');
    } catch (e) {
      _showErrorSnackBar('Veuillez entrer une surface valide (ex: 4.5)');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _authService.register(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        role: widget.role, // Utiliser le rôle passé en paramètre
        updateToken: false,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        throw Exception(result['message']?.toString() ?? 'Erreur lors de la création du compte');
      }

      final token = result['token'] as String?;
      final dynamic apiUser = result['user'];
      String? userId;

      if (apiUser is User) {
        userId = apiUser.id;
      } else if (apiUser is Map) {
        userId = apiUser['id']?.toString() ?? apiUser['_id']?.toString();
      }

      if (token == null || userId == null) {
        throw Exception('Impossible de récupérer les informations du compte créé');
      }

      final cropsList = _parcelCrops.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final ok = await _authService.updateFarmerProfileWithToken(
        token: token,
        parcelLocation: location,
        soilType: _soilType,
        crops: cropsList,
        areaM2: area,
      );

      if (!ok) {
        throw Exception('Erreur lors de la création du profil parcelle');
      }

      if (mounted) {
        _showSuccessSnackBar('$userRoleDisplay et parcelle créés avec succès');
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        User userToReturn;
        if (apiUser is User) {
          userToReturn = apiUser;
        } else if (apiUser is Map<String, dynamic>) {
          userToReturn = User.fromJson(apiUser);
        } else {
          userToReturn = User(
            id: userId,
            email: _email.text.trim(),
            name: _name.text.trim(),
            role: widget.role,
          );
        }
        Navigator.pop(context, userToReturn);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _handleError(e);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleError(dynamic error) {
    if (!mounted) return;
    String errorMessage = 'Erreur: ${error.toString().replaceAll('Exception: ', '')}';
    if (kDebugMode) {
      print('Erreur: $error');
      if (error is Error) print('Stack trace: ${error.stackTrace}');
    }
    _showErrorSnackBar(errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ajouter un $userRoleDisplay'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.15),
                  BlendMode.srcATop,
                ),
                child: Image.asset('assets/images/ferme.png', fit: BoxFit.cover),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouveau $userRoleDisplay',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Ajoutez un $userRoleDisplay pour votre entreprise.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Parcelle du $userRoleDisplay',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _parcelLocation,
                            decoration: const InputDecoration(
                              labelText: 'Localisation / Parcelle',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: Parcelle A, Zone Nord',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _soilType,
                            items: const [
                              DropdownMenuItem(value: 'sableux', child: Text('Sol sableux')),
                              DropdownMenuItem(value: 'argileux', child: Text('Sol argileux')),
                              DropdownMenuItem(value: 'limoneux', child: Text('Sol limoneux')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _soilType = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Type de sol',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _parcelCrops,
                            decoration: const InputDecoration(
                              labelText: 'Cultures (séparées par des virgules)',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: Fraise, Tomate, Salade',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _parcelArea,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Surface (m²)',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: 4.5',
                            ),
                          ),
                          const SizedBox(height: 24),
                          _loading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  text: 'Créer $userRoleDisplay',
                                  onTap: _addUser,
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
