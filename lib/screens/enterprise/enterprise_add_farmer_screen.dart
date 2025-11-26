import 'package:flutter/material.dart';
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

  Future<void> _addFarmer() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom, email et mot de passe sont obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_parcelLocation.text.trim().isEmpty ||
        _parcelCrops.text.trim().isEmpty ||
        _parcelArea.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les informations de parcelle sont obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      role: 'farmer', // création d'un compte fermier
      updateToken:
          false, // ne pas remplacer le token admin courant quand on crée un fermier
    );
    setState(() => _loading = false);

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Erreur inscription'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tenter de créer le profil parcelle pour ce nouveau fermier à partir des champs saisis
    final token = result['token'] as String?;
    final dynamic apiUser = result['user'];

    if (token != null) {
      double? area;
      try {
        area = double.parse(_parcelArea.text.replaceAll(',', '.'));
      } catch (_) {
        area = null;
      }

      if (area != null) {
        final ok = await _authService.updateFarmerProfileWithToken(
          token: token,
          parcelLocation: _parcelLocation.text.trim(),
          soilType: _soilType,
          crops: _parcelCrops.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          areaM2: area,
        );

        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Fermier créé, mais erreur lors de l’enregistrement de la parcelle'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fermier et parcelle ajoutés !'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // On s'assure de toujours renvoyer un objet User au tableau de bord
    if (apiUser is User) {
      Navigator.pop(context, apiUser);
    } else if (apiUser is Map<String, dynamic>) {
      Navigator.pop(context, User.fromJson(apiUser));
    } else {
      Navigator.pop(
        context,
        User(
          id: '',
          email: _email.text,
          name: _name.text,
          role: 'farmer',
        ),
      );
    }
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
        body: SingleChildScrollView(
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
                        "Ajoutez un fermier pour votre entreprise.",
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
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        decoration:
                            const InputDecoration(labelText: 'Mot de passe'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Parcelle du superviseur',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _parcelLocation,
                        decoration: const InputDecoration(
                          labelText: 'Localisation / Parcelle',
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
                          setState(() {
                            _soilType = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Type de sol',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _parcelCrops,
                        decoration: const InputDecoration(
                          labelText: 'Cultures (séparées par des virgules)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _parcelArea,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Surface (m²)',
                        ),
                      ),
                      const SizedBox(height: 20),
                      _loading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Créer fermier', onTap: _addFarmer),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
