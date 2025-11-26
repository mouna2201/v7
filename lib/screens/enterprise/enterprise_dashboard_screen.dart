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
    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de bord Admin'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () async {
                await _authService.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const EnterpriseRoleScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header animé
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 16),
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'Dashboard entreprise',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gérez vos fermiers avec une vue claire et animée.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Carte de contrôle avec bouton animé
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.9 + 0.1 * value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fermiers enregistrés',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_farmers.length}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Bouton principal avec légère animation au tap
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.9 + value * 0.1,
                                child: child,
                              );
                            },
                            child: CustomButton(
                              text: 'Ajouter un fermier',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EnterpriseAddFarmerScreen(),
                                  ),
                                );

                                if (result is User) {
                                  setState(() {
                                    _farmers.add(result);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Liste animée
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _farmers.isEmpty
                                ? Center(
                                    key: const ValueKey('empty-state'),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.agriculture,
                                          size: 64,
                                          color: Colors.white30,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Aucun fermier pour le moment',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Ajoutez votre premier fermier avec le bouton ci-dessus.',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    key: const ValueKey('farmers-list'),
                                    itemCount: _farmers.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final farmer = _farmers[index];
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: 1),
                                        duration: Duration(
                                            milliseconds: 300 + index * 60),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset:
                                                  Offset(0, (1 - value) * 12),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: InkWell(
                                          onTap: () async {
                                            // Depuis l'admin, ouvrir le même plan que le superviseur :
                                            // thème bleu et données de parcelle réelles du fermier.
                                            Map<String, dynamic>? profile;
                                            try {
                                              profile = await _authService
                                                  .fetchFarmerProfileById(
                                                      farmer.id);
                                            } catch (_) {
                                              profile = null;
                                            }

                                            final location =
                                                (profile?['parcelLocation']
                                                        as String?)
                                                    ?.trim();
                                            final soilType =
                                                (profile?['soilType']
                                                        as String?)
                                                    ?.trim();
                                            final cropsDynamic =
                                                profile?['crops'];
                                            final areaNum =
                                                profile?['areaM2'] as num?;

                                            List<String> crops = [];
                                            if (cropsDynamic is List) {
                                              crops = cropsDynamic
                                                  .whereType<String>()
                                                  .toList();
                                            } else if (cropsDynamic
                                                is String) {
                                              crops = cropsDynamic
                                                  .split(',')
                                                  .map((e) => e.trim())
                                                  .where((e) => e.isNotEmpty)
                                                  .toList();
                                            }

                                            if (location == null ||
                                                location.isEmpty ||
                                                soilType == null ||
                                                soilType.isEmpty ||
                                                crops.isEmpty ||
                                                areaNum == null) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      "Aucune parcelle configurée pour ce fermier. Définissez-la d'abord dans l'ajout/édition."),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            if (!context.mounted) return;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => IrrigationPlanScreen(
                                                  location: location,
                                                  soilType: soilType,
                                                  cropTypes: crops,
                                                  areaM2: areaNum.toDouble(),
                                                  isSupervisor: true,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.06),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.08),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 40,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFF22C55E),
                                                        Color(0xFF16A34A),
                                                      ],
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        farmer.name,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        farmer.email,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Modifier',
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.white70,
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        final updatedFarmer =
                                                            await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                EnterpriseEditFarmerScreen(
                                                              farmer: farmer,
                                                            ),
                                                          ),
                                                        );

                                                        if (updatedFarmer
                                                            is User) {
                                                          setState(() {
                                                            _farmers[index] =
                                                                updatedFarmer;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Supprimer',
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      onPressed: () async {
                                                        final confirm =
                                                            await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Supprimer le fermier ?'),
                                                              content: Text(
                                                                'Voulez-vous vraiment supprimer ${farmer.name} ? Cette action est irréversible.',
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          ctx,
                                                                          false),
                                                                  child: const Text(
                                                                      'Annuler'),
                                                                ),
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          ctx,
                                                                          true),
                                                                  child: const Text(
                                                                    'Supprimer',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .redAccent),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );

                                                        if (confirm != true) {
                                                          return;
                                                        }

                                                        final success =
                                                            await _authService
                                                                .deleteUser(
                                                                    farmer.id);
                                                        if (!mounted) return;

                                                        if (success) {
                                                          setState(() {
                                                            _farmers.removeAt(
                                                                index);
                                                          });
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Fermier supprimé'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Erreur lors de la suppression'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
