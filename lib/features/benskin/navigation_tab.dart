import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class NavigationTab extends StatefulWidget {
  final bool hasActiveMission;
  final VoidCallback onGoToMissions;
  const NavigationTab({
    super.key,
    this.hasActiveMission = true,
    required this.onGoToMissions,
  });

  @override
  State<NavigationTab> createState() => _NavigationTabState();
}

class _NavigationTabState extends State<NavigationTab>
    with TickerProviderStateMixin {
  static const _restaurantPhone = '+237699000001';
  static const _clientPhone = '+237699000002';
  static const _clientName = 'Aïcha N.';

  /// 0 = EN ROUTE, 1 = AU RESTAURANT, 2 = EN LIVRAISON, 3 = LIVRÉ
  int _step = 0;
  late final AnimationController _pulseCtrl;
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _advance() {
    HapticFeedback.selectionClick();
    setState(() => _step = (_step + 1).clamp(0, 3));
    if (_step == 3) {
      HapticFeedback.lightImpact();
      _confettiCtrl.play();
    }
  }

  Future<void> _call(String number) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

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
      ),
      body: Stack(
        children: [
          widget.hasActiveMission ? _activeMission(context) : _noMission(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.3,
              colors: const [
                AppColors.primary,
                AppColors.ctaGreen,
                AppColors.gold,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
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
                onPressed: widget.onGoToMissions,
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
          flex: 5,
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
                  child:
                      Icon(Icons.map, size: 120, color: AppColors.ctaGreen),
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
                child: Column(
                  children: [
                    _callFab(
                      icon: Icons.restaurant,
                      color: AppColors.primary,
                      onTap: () => _call(_restaurantPhone),
                    ),
                    const SizedBox(height: 10),
                    _callFab(
                      icon: Icons.person,
                      color: AppColors.secondary,
                      onTap: () => _call(_clientPhone),
                    ),
                  ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(_stepBadge(),
                    style: const TextStyle(
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
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.9))),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Le Gourmet Camerounais',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const Text('Akwa, Rue des Écoles',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              _progress(),
              const SizedBox(height: 14),
              _clientCard(),
              const SizedBox(height: 12),
              _mainActionButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _callFab({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  String _stepBadge() {
    switch (_step) {
      case 0:
        return 'EN ROUTE';
      case 1:
        return 'AU RESTAURANT';
      case 2:
        return 'EN LIVRAISON';
      default:
        return 'LIVRÉ ✓';
    }
  }

  Widget _clientCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_clientName,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(_clientPhone,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _call(_clientPhone),
            icon: const Icon(Icons.phone, color: AppColors.ctaGreen),
            tooltip: 'Appeler le client',
          ),
        ],
      ),
    );
  }

  Widget _mainActionButton() {
    if (_step >= 3) {
      return SizedBox(
        width: double.infinity,
        height: 72,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ctaGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('LIVRAISON TERMINÉE ✓',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1)),
          ),
        ),
      );
    }

    final (label, color, gradient) = switch (_step) {
      0 => (
          'JE SUIS ARRIVÉ',
          AppColors.primary,
          null as Gradient?,
        ),
      1 => (
          "J'AI RÉCUPÉRÉ",
          const Color(0xFF1B4332),
          null as Gradient?,
        ),
      _ => (
          'LIVRÉ !',
          AppColors.primary,
          const LinearGradient(
            colors: [AppColors.primary, AppColors.gold],
          ) as Gradient?,
        ),
    };

    return SizedBox(
      width: double.infinity,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _advance,
          child: Container(
            decoration: BoxDecoration(
              color: gradient == null ? color : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress() {
    const labels = ['EN ROUTE', 'AU RESTAURANT', 'EN LIVRAISON'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isPast = i < _step;
        final isActive = i == _step && _step < 3;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    Color barColor;
                    double opacity = 1;
                    if (isPast) {
                      barColor = AppColors.ctaGreen;
                    } else if (isActive) {
                      barColor = AppColors.primary;
                      opacity = 0.6 + 0.4 * _pulseCtrl.value;
                    } else {
                      barColor = Colors.grey.shade300;
                    }
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPast)
                      const Icon(Icons.check_circle,
                          size: 12, color: AppColors.ctaGreen),
                    if (isPast) const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isPast
                                ? AppColors.ctaGreen
                                : isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
