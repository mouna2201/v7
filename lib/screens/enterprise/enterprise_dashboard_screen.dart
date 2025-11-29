import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'enterprise_add_farmer_screen.dart';
import 'enterprise_edit_farmer_screen.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'enterprise_role_screen.dart';
import '../farmer/irrigation_plan_screen.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  final AuthService _authService = AuthService();
  List<User> _farmers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    final farmers = await _authService.fetchFarmers();
    setState(() {
      _farmers = farmers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text(
          "Dashboard Entreprise",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const EnterpriseRoleScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Image de fond ferme
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/images/ferme.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Contenu principal du dashboard
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bienvenue 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Gérez vos fermiers facilement.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 22),

                // ------------------------------------
                //        CARD STATS PRINCIPALE
                // ------------------------------------
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB339F3),
                        Color(0xFFFF8C3B),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT SIDE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Fermiers enregistrés",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_farmers.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // BUTTON AJOUTER
                      CustomButton(
                        text: "Ajouter",
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const EnterpriseAddFarmerScreen()),
                          );
                          if (result is User) {
                            setState(() {
                              _farmers.add(result);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------
                //        LISTE FERMERS
                // ------------------------------------
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.purpleAccent,
                          ),
                        )
                      : _farmers.isEmpty
                          ? const Center(
                              child: Text(
                                "Aucun fermier pour le moment.",
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _farmers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 18),
                              itemBuilder: (context, index) {
                                return _buildFarmerCard(
                                    context, _farmers[index], index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // --------------------- FARMER CARD (IMPROVED) -----------------------
  // --------------------------------------------------------------------
  Widget _buildFarmerCard(BuildContext context, User farmer, int index) {
    return GestureDetector(
      onTap: () => _openFarmerParcel(context, farmer),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1C1F2E),
              Color(0xFF151827),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.deepPurple),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    farmer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // EDIT
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.purpleAccent),
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EnterpriseEditFarmerScreen(farmer: farmer),
                      ),
                    );
                    if (updated is User) {
                      setState(() {
                        _farmers[index] = updated;
                      });
                    }
                  },
                ),

                // DELETE
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1D1F2A),
                          title: const Text("Supprimer ?",
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                            "Voulez-vous vraiment supprimer ${farmer.name} ?",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Annuler",
                                    style: TextStyle(color: Colors.white))),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Supprimer",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirm != true) return;

                    await _authService.deleteUser(farmer.id);

                    setState(() {
                      _farmers.removeAt(index);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              farmer.email,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  //         OPEN IRRIGATION PLAN
  // --------------------------------------------------------------------
  Future<void> _openFarmerParcel(BuildContext context, User farmer) async {
    // Vérifier d'abord si on a toutes les données nécessaires
    if (farmer.parcelLocation != null &&
        farmer.soilType != null &&
        farmer.crops.isNotEmpty &&
        farmer.areaM2 != null) {
      _navigateToIrrigationScreen(
        context,
        farmer.parcelLocation!,
        farmer.soilType!,
        farmer.crops,
        farmer.areaM2!,
        farmerName: farmer.name,
        farmerAddress:
            farmer.email, // Utiliser l'email comme adresse pour l'instant
      );
      return;
    }

    // Sinon, essayer de récupérer les données manquantes
    try {
      final profile = await _authService.fetchFarmerProfileById(farmer.id);
      if (profile != null) {
        final updatedFarmer = User.fromJson(profile);
        _navigateToIrrigationScreen(
          context,
          updatedFarmer.parcelLocation ?? 'Bizerte',
          updatedFarmer.soilType ?? 'sableux',
          updatedFarmer.crops.isNotEmpty ? updatedFarmer.crops : ['Fraise'],
          updatedFarmer.areaM2 ?? 4.0,
          farmerName: updatedFarmer.name,
          farmerAddress: updatedFarmer.email,
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération du profil: $e');
      }
    }

    // Si échec, utiliser les valeurs par défaut
    _navigateToIrrigationScreen(
      context,
      'Bizerte',
      'sableux',
      ['Fraise'],
      4.0,
      farmerName: farmer.name,
      farmerAddress: farmer.email,
    );
  }

  void _navigateToIrrigationScreen(
    BuildContext context,
    String location,
    String soilType,
    List<String> cropTypes,
    double areaM2, {
    String? farmerName,
    String? farmerAddress,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IrrigationPlanScreen(
          location: location,
          soilType: soilType,
          cropTypes: cropTypes,
          areaM2: areaM2,
          isSupervisor: true,
          farmerName: farmerName,
          farmerAddress: farmerAddress,
        ),
      ),
    );
  }
}
