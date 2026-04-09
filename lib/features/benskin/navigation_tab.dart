import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class NavigationTab extends StatelessWidget {
  final bool hasActiveMission;
  final VoidCallback onGoToMissions;
  const NavigationTab({
    super.key,
    this.hasActiveMission = true,
    required this.onGoToMissions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Benskin Express',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 28),
          ),
        ],
      ),
      body: hasActiveMission ? _activeMission(context) : _noMission(),
    );
  }

  Widget _noMission() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_off,
                size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Pas de mission en cours',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: onGoToMissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctaGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Voir les missions',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeMission(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.map, size: 120, color: AppColors.ctaGreen),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.turn_right,
                          color: Colors.white, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DANS 250 MÈTRES',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6)),
                            const SizedBox(height: 2),
                            const Text(
                              'Tournez à droite sur Rue Pau',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:+237699000000');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                    child: const Icon(Icons.phone,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text('MISSION ACTIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '1.2 km',
                    style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text('4 MIN RESTANTS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary.withValues(alpha: 0.9))),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Le Gourmet Camerounais',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const Text('Akwa, Rue des Écoles',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              _progress(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Arrivée confirmée ✓')),
                    );
                  },
                  icon: const Icon(Icons.check, color: Colors.white, size: 28),
                  label: const Text(
                    'ARRIVÉ',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progress() {
    const steps = ['Aller au restaurant', 'Récupérer', 'Livrer'];
    const active = 0;
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == active;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
