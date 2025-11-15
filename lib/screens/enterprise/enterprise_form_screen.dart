import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../theme/app_theme.dart';

class EnterpriseFormScreen extends StatelessWidget {
  const EnterpriseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController locationController = TextEditingController();
    TextEditingController soilController = TextEditingController();
    TextEditingController cropController = TextEditingController();
    TextEditingController hectaresController = TextEditingController();

    return Theme(
      data: AppTheme.enterpriseTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text("Formulaire Fermier Entreprise")),
        body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: "Localisation",
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: soilController,
              decoration: const InputDecoration(
                labelText: "Type de sol",
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cropController,
              decoration: const InputDecoration(
                labelText: "Type de culture / plante",
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hectaresController,
              decoration: const InputDecoration(
                labelText: "Nombre d'hectares",
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 230,
                child: CustomButton(
                  text: "Générer calendrier d'arrosage",
                  onTap: () {
                    // Ici tu appelleras ton IA ou API météo pour le calendrier
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
