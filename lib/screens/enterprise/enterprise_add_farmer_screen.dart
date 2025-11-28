import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';

class EnterpriseAddFarmerScreen extends StatefulWidget {
  const EnterpriseAddFarmerScreen({super.key});

  @override
  State<EnterpriseAddFarmerScreen> createState() =>
      _EnterpriseAddFarmerScreenState();
}

class _EnterpriseAddFarmerScreenState extends State<EnterpriseAddFarmerScreen> {
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

  Future<void> _addFarmer() async {
    if (!mounted) return;

    // Validation des champs obligatoires
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      _showErrorSnackBar('Nom, email et mot de passe sont obligatoires');
      return;
    }

    // Validation des champs de la parcelle
    final location = _parcelLocation.text.trim();
    final cropsText = _parcelCrops.text.trim();
    final areaText = _parcelArea.text.trim();

    if (location.isEmpty || cropsText.isEmpty || areaText.isEmpty) {
      _showErrorSnackBar('Tous les champs de la parcelle sont obligatoires');
      return;
    }

    // Validation du format de la surface
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
      // 1. Création du compte utilisateur
      final result = await _authService.register(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        role: 'farmer',
        updateToken: false, // Ne pas remplacer le token admin
      );

      if (!mounted) return;

      if (result == null || result['success'] != true) {
        throw Exception(result?['message']?.toString() ?? 'Erreur lors de la création du compte');
      }

      // 2. Récupération du token et création du profil parcelle
      final token = result['token'] as String?;
      final dynamic apiUser = result['user'];
      final String? userId = apiUser is Map ? (apiUser['id'] ?? apiUser['_id'])?.toString() : null;

      if (token == null || userId == null) {
        throw Exception('Impossible de récupérer les informations du compte créé');
      }

      // 3. Création du profil parcelle
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

      // Succès
      if (mounted) {
        _showSuccessSnackBar('Fermier et parcelle créés avec succès');

        // Retour à l'écran précédent après un délai
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;

        // On retourne l'utilisateur créé
        if (apiUser is User) {
          Navigator.pop(context, apiUser);
        } else if (apiUser is Map<String, dynamic>) {
          Navigator.pop(context, User.fromJson(apiUser));
        } else {
          Navigator.pop(
            context,
            User(
              id: userId,
              email: _email.text.trim(),
              name: _name.text.trim(),
              role: 'farmer',
            ),
          );
        }
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

    String errorMessage = 'Erreur: ';
    if (error is FormatException) {
      errorMessage += 'Format de données invalide';
    } else {
      errorMessage += error.toString().replaceAll('Exception: ', '');
    }

    if (kDebugMode) {
      print('Erreur: $error');
      if (error is Error) {
        print('Stack trace: ${error.stackTrace}');
      }
    }

    _showErrorSnackBar(errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ajouter un fermier'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Image de fond ferme
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.15),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/ferme.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Contenu du formulaire
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
                      Icons.agriculture,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau fermier',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Ajoutez un fermier pour votre entreprise.',
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
                          'Parcelle du fermier',
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
                          DropdownMenuItem(
                            value: 'sableux',
                            child: Text('Sol sableux'),
                          ),
                          DropdownMenuItem(
                            value: 'argileux',
                            child: Text('Sol argileux'),
                          ),
                          DropdownMenuItem(
                            value: 'limoneux',
                            child: Text('Sol limoneux'),
                          ),
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
                              text: 'Créer fermier',
                              onTap: _addFarmer,
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
