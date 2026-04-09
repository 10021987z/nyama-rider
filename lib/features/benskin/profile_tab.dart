import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  File? _avatar;

  Future<void> _pickAvatar() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null) setState(() => _avatar = File(x.path));
    } catch (_) {}
  }

  Future<void> _scanDocument(String label) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera);
      if (x != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$label enregistré ✓'),
              backgroundColor: AppColors.ctaGreen),
        );
      }
    } catch (_) {}
  }

  Future<void> _inviteFriend() async {
    await Share.share(
      "Viens livrer avec Benskin Express ! Télécharge l'app et inscris-toi avec mon code RIDER_KEVIN_237 pour un bonus de bienvenue.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Benskin Express',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 28),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: _avatar != null
                              ? Image.file(_avatar!, fit: BoxFit.cover)
                              : Image.asset('assets/images/logo_nyama.jpg',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('Livreur Confirmé',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
                const SizedBox(height: 12),
                const Text('Kevin',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 28)),
                const Text('Membre depuis Janvier 2023',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: _StatCard(label: 'COURSES', value: '156')),
              SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'NOTE', value: '4.9')),
              SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'SUCCÈS', value: '98%')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Statistiques de la semaine',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _Gauge(
                  value: 0.95,
                  label: 'Acceptation',
                  display: '95%',
                  color: AppColors.ctaGreen,
                ),
                _Gauge(
                  value: 0.73,
                  label: 'Temps moyen',
                  display: '22 min',
                  color: AppColors.primary,
                ),
                _Gauge(
                  value: 0.98,
                  label: 'Satisfaction',
                  display: '4.9/5',
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Véhicule de service',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.two_wheeler,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Honda CB 125',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LT-452-XY',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ctaGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Assuré',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanDocument('Permis'),
                  icon: const Icon(Icons.document_scanner,
                      color: AppColors.primary),
                  label: const Text('Permis',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scanDocument('Assurance'),
                  icon: const Icon(Icons.document_scanner,
                      color: AppColors.primary),
                  label: const Text('Assurance',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _menuItem(Icons.person_add, 'Inviter un ami livreur', _inviteFriend),
          _menuItem(Icons.history, 'Historique complet',
              () => _snack(context, 'Historique bientôt disponible')),
          _menuItem(Icons.two_wheeler, 'Paramètres du véhicule',
              () => _snack(context, 'Paramètres véhicule bientôt')),
          _menuItem(Icons.help_outline, 'Aide & Support', () async {
            final uri = Uri.parse('https://wa.me/237699000000');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }),
          _menuItem(Icons.logout, 'Déconnexion', () {
            context.go('/phone');
          }, danger: true),
          const SizedBox(height: 20),
          const Center(
            child: Text('Version 1.0 • Benskin Express',
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label,
            style:
                TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color)),
        trailing: Icon(Icons.chevron_right, color: color.withValues(alpha: 0.4)),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final double value;
  final String label;
  final String display;
  final Color color;
  const _Gauge({
    required this.value,
    required this.label,
    required this.display,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(display,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
