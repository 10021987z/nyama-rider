import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';

Future<void> showVehicleSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => const _VehicleSettingsSheet(),
  );
}

class _VehicleSettingsSheet extends StatefulWidget {
  const _VehicleSettingsSheet();

  @override
  State<_VehicleSettingsSheet> createState() => _VehicleSettingsSheetState();
}

class _VehicleSettingsSheetState extends State<_VehicleSettingsSheet> {
  String _type = 'Moto';
  final _modelCtrl = TextEditingController(text: 'Honda CB 125');
  final _plateCtrl = TextEditingController(text: 'LT-452-XY');
  final _colorCtrl = TextEditingController(text: 'Noir');

  final Map<String, bool> _docVerified = {
    'Permis de conduire': true,
    'Carte grise': false,
    'Assurance': true,
  };

  @override
  void dispose() {
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan(String docLabel) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera);
      if (x != null && mounted) {
        setState(() => _docVerified[docLabel] = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ctaGreen,
            content: Text('$docLabel enregistré ✓'),
          ),
        );
      }
    } catch (_) {}
  }

  void _save() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ctaGreen,
        content: Text('Véhicule mis à jour !',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Mon véhicule',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('INFOS VÉHICULE',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            const Text('Type',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _typeChip('Moto', Icons.two_wheeler),
                const SizedBox(width: 8),
                _typeChip('Vélo', Icons.pedal_bike),
                const SizedBox(width: 8),
                _typeChip('Voiture', Icons.directions_car),
              ],
            ),
            const SizedBox(height: 14),
            _field('Marque & Modèle', _modelCtrl),
            const SizedBox(height: 10),
            _field('Plaque d\'immatriculation', _plateCtrl),
            const SizedBox(height: 10),
            _field('Couleur', _colorCtrl),
            const SizedBox(height: 20),
            const Text('DOCUMENTS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            _docCard('Permis de conduire'),
            const SizedBox(height: 10),
            _docCard('Carte grise'),
            const SizedBox(height: 10),
            _docCard('Assurance', expiry: 'Expire le 15/12/2026'),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Enregistrer les modifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, IconData icon) {
    final selected = _type == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.primary : Colors.grey.shade300,
                width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _docCard(String label, {String? expiry}) {
    final verified = _docVerified[label] ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      verified ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: verified
                          ? AppColors.ctaGreen
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'Vérifié' : 'À fournir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: verified
                            ? AppColors.ctaGreen
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (expiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(expiry,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _scan(label),
            icon: const Icon(Icons.document_scanner,
                color: AppColors.primary, size: 18),
            label: const Text('Scanner',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
