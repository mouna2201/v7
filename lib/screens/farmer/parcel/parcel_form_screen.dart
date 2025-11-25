import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/parcel_provider.dart';

class ParcelFormScreen extends StatefulWidget {
  const ParcelFormScreen({super.key});

  @override
  State<ParcelFormScreen> createState() => _ParcelFormScreenState();
}

class _ParcelFormScreenState extends State<ParcelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parcelNameController = TextEditingController();
  final _parcelSizeController = TextEditingController();
  final _parcelLocationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<ParcelProvider>(context, listen: false).addParcel(
        name: _parcelNameController.text.trim(),
        size: double.parse(_parcelSizeController.text.trim()),
        location: _parcelLocationController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parcelle enregistrée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        // Revenir à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _parcelNameController.dispose();
    _parcelSizeController.dispose();
    _parcelLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une parcelle'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Informations sur la parcelle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Nom de la parcelle
              TextFormField(
                controller: _parcelNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la parcelle',
                  prefixIcon: Icon(Icons.landscape),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom pour la parcelle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Taille de la parcelle
              TextFormField(
                controller: _parcelSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Superficie (en hectares)',
                  prefixIcon: Icon(Icons.square_foot),
                  border: OutlineInputBorder(),
                  suffixText: 'ha',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la superficie';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Localisation
              TextFormField(
                controller: _parcelLocationController,
                decoration: const InputDecoration(
                  labelText: 'Localisation',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer la localisation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              
              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enregistrer la parcelle',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
