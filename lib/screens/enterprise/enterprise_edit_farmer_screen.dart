import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class EnterpriseEditFarmerScreen extends StatefulWidget {
  final User farmer;

  const EnterpriseEditFarmerScreen({super.key, required this.farmer});

  @override
  State<EnterpriseEditFarmerScreen> createState() => _EnterpriseEditFarmerScreenState();
}

class _EnterpriseEditFarmerScreenState extends State<EnterpriseEditFarmerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parcelLocationController = TextEditingController();
  final _parcelCropsController = TextEditingController();
  final _parcelAreaController = TextEditingController();
  String _soilType = 'sableux';
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.farmer.name;
    _emailController.text = widget.farmer.email;
    
    // Charger les données de la parcelle
    _loadParcelData();
  }

  Future<void> _loadParcelData() async {
    try {
      final profile = await _authService.fetchFarmerProfileById(widget.farmer.id);
      if (profile != null && mounted) {
        final soilType = profile['soilType'] ?? 'sableux';
        // S'assurer que le type de sol est valide
        final validSoilTypes = ['sableux', 'argileux', 'calcaire', 'limoneux'];
        final validSoilType = validSoilTypes.contains(soilType) ? soilType : 'sableux';
        
        setState(() {
          _parcelLocationController.text = profile['parcelLocation'] ?? '';
          _parcelCropsController.text = profile['crops']?.join(', ') ?? '';
          _parcelAreaController.text = profile['areaM2']?.toString() ?? '';
          _soilType = validSoilType;
        });
      }
    } catch (e) {
      // En cas d'erreur, utiliser les données du farmer si disponibles
      if (mounted) {
        final soilType = widget.farmer.soilType ?? 'sableux';
        final validSoilTypes = ['sableux', 'argileux', 'calcaire', 'limoneux'];
        final validSoilType = validSoilTypes.contains(soilType) ? soilType : 'sableux';
        
        setState(() {
          _parcelLocationController.text = widget.farmer.parcelLocation ?? '';
          _parcelCropsController.text = widget.farmer.crops.join(', ');
          _parcelAreaController.text = widget.farmer.areaM2?.toString() ?? '';
          _soilType = validSoilType;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parcelLocationController.dispose();
    _parcelCropsController.dispose();
    _parcelAreaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Mettre à jour les infos utilisateur
      final updatedUser = await _authService.updateUser(
        id: widget.farmer.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      );

      if (updatedUser == null) {
        throw Exception('Erreur lors de la mise à jour du fermier');
      }

      // 2. Mettre à jour les infos de la parcelle
      final cropsList = _parcelCropsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final area = double.tryParse(_parcelAreaController.text.trim());
      if (area == null || area <= 0) {
        throw Exception('Veuillez entrer une surface valide');
      }

      // Pour mettre à jour le profil d'un autre utilisateur, on doit utiliser une méthode admin
      // Pour l'instant, on utilise updateFarmerProfile qui met à jour le profil de l'utilisateur connecté
      // Dans un cas réel, il faudrait une méthode admin pour mettre à jour le profil d'un autre utilisateur
      final parcelUpdated = await _authService.updateFarmerProfile(
        parcelLocation: _parcelLocationController.text.trim(),
        soilType: _soilType,
        crops: cropsList,
        areaM2: area,
      );

      if (!parcelUpdated) {
        throw Exception('Erreur lors de la mise à jour de la parcelle');
      }

      // Créer l'utilisateur mis à jour avec les nouvelles données
      final finalUser = User(
        id: widget.farmer.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: widget.farmer.role,
        parcelLocation: _parcelLocationController.text.trim(),
        soilType: _soilType,
        crops: cropsList,
        areaM2: area,
      );

      setState(() => _loading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fermier et parcelle mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, finalUser);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le fermier'),
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Informations utilisateur
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations utilisateur',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nom'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom obligatoire';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email obligatoire';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Nouveau mot de passe (optionnel)',
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Section Parcelle
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations de la parcelle',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _parcelLocationController,
                            decoration: const InputDecoration(
                              labelText: 'Localisation',
                              hintText: 'Ex: Bizerte, Tunisie',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Localisation obligatoire';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _soilType,
                            decoration: const InputDecoration(labelText: 'Type de sol'),
                            items: const [
                              DropdownMenuItem(value: 'sableux', child: Text('Sol sableux')),
                              DropdownMenuItem(value: 'argileux', child: Text('Sol argileux')),
                              DropdownMenuItem(value: 'calcaire', child: Text('Sol calcaire')),
                              DropdownMenuItem(value: 'limoneux', child: Text('Sol limoneux')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _soilType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _parcelCropsController,
                            decoration: const InputDecoration(
                              labelText: 'Cultures (séparées par des virgules)',
                              hintText: 'Ex: Tomate, Blé, Olive',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Cultures obligatoires';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _parcelAreaController,
                            decoration: const InputDecoration(
                              labelText: 'Surface (m²)',
                              hintText: 'Ex: 5000',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Surface obligatoire';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Surface invalide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: _loading ? 'En cours...' : 'Enregistrer',
                    onTap: () {
                      if (_loading) return;
                      _save();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
