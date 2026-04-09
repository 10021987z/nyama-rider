import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';

class MissionMock {
  final String restaurant;
  final String type; // express / standard / grouped
  final int gain;
  final String pickup;
  final String dropoff;
  final double km;
  final int etaMin;
  final int groupCount;
  const MissionMock({
    required this.restaurant,
    required this.type,
    required this.gain,
    required this.pickup,
    required this.dropoff,
    required this.km,
    required this.etaMin,
    this.groupCount = 0,
  });
}

const _missions = <MissionMock>[
  MissionMock(
    restaurant: 'Le Relais de Sawa',
    type: 'express',
    gain: 1200,
    pickup: 'Akwa',
    dropoff: 'Bonapriso',
    km: 3.2,
    etaMin: 18,
  ),
  MissionMock(
    restaurant: 'Maison H',
    type: 'standard',
    gain: 850,
    pickup: 'Bonamoussadi',
    dropoff: 'Kotto',
    km: 4.8,
    etaMin: 25,
  ),
  MissionMock(
    restaurant: 'Tchop et Yamo',
    type: 'grouped',
    gain: 2100,
    pickup: 'Deido',
    dropoff: 'Multiple',
    km: 6.1,
    etaMin: 30,
    groupCount: 2,
  ),
];

class MissionsTab extends StatefulWidget {
  const MissionsTab({super.key});

  @override
  State<MissionsTab> createState() => _MissionsTabState();
}

class _MissionsTabState extends State<MissionsTab>
    with TickerProviderStateMixin {
  bool _online = true;
  int _todayEarnings = 8450;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _header(),
            const SizedBox(height: 16),
            _onlineToggle(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _earningsCard(_todayEarnings)),
                const SizedBox(width: 12),
                Expanded(child: _statCard('MISSIONS', '12')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'PROXIMITÉ IMMÉDIATE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                _pill('3 NOUVELLES', AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            if (!_online)
              _idleState()
            else
              ..._missions.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _MissionCard(
                      mission: e.value,
                      index: e.key,
                      onAccepted: () {
                        setState(() => _todayEarnings += e.value.gain);
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Missions disponibles',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ),
        _livePill(),
        const SizedBox(width: 6),
        IconButton(
          onPressed: () => _showNotificationsSheet(context),
          icon: const Icon(Icons.notifications_outlined,
              color: AppColors.textPrimary, size: 26),
          tooltip: 'Notifications',
        ),
        const CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.ctaGreen,
          child: Text('K',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
        ),
      ],
    );
  }

  Widget _livePill() {
    if (!_online) {
      return _pill('HORS LIGNE', Colors.grey);
    }
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.ctaGreen,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.5 + 0.5 * t),
                ),
              ),
              const SizedBox(width: 6),
              const Text('EN LIGNE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _onlineToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _online = !_online);
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          final glow = _online ? 0.3 + 0.4 * _pulseCtrl.value : 0.0;
          return Container(
            height: 84,
            decoration: BoxDecoration(
              color:
                  _online ? const Color(0xFF22C55E) : Colors.grey.shade500,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _online
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E)
                            .withValues(alpha: glow),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Icon(_online ? Icons.radio_button_checked : Icons.power_settings_new,
                    color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _online ? 'EN LIGNE' : 'HORS LIGNE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        _online
                            ? 'Les courses peuvent arriver'
                            : 'Tape pour passer en ligne',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _earningsCard(int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AUJOURD'HUI",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${_fmtMoney(v)} FCFA',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _statCard(String label, String value, {bool isMoney = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: isMoney ? 'SpaceMono' : null,
              fontWeight: FontWeight.w800,
              fontSize: isMoney ? 20 : 24,
              color: isMoney ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  Future<void> _showNotificationsSheet(BuildContext context) async {
    final status = await Permission.notification.status;
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        if (status.isDenied || status.isPermanentlyDenied) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off,
                    size: 56, color: AppColors.textSecondary),
                const SizedBox(height: 14),
                const Text('Notifications désactivées',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                const Text(
                  "Active les notifications pour être alerté dès qu'une course arrive.",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await openAppSettings();
                    },
                    child: const Text('Activer les notifications',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none,
                  size: 56, color: AppColors.textSecondary),
              SizedBox(height: 14),
              Text('Aucune notification',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              SizedBox(height: 8),
              Text(
                "Tu seras alerté dès qu'une course arrive !",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _idleState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          padding: const EdgeInsets.all(18),
          child: ClipOval(
            child: Image.asset('assets/images/logo_nyama.jpg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "En attente d'une mission...",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Astuce : rapproche-toi des zones chaudes — Akwa, Bonapriso, Deido.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'RIDER_IDLE_237',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatefulWidget {
  final MissionMock mission;
  final int index;
  final VoidCallback? onAccepted;
  const _MissionCard({
    required this.mission,
    this.index = 0,
    this.onAccepted,
  });

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard>
    with TickerProviderStateMixin {
  double _drag = 0;
  static const double _trackHeight = 72;
  static const double _handle = 64;

  late final AnimationController _glowCtrl;
  late final AnimationController _appearCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _appearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _appearCtrl.forward();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _appearCtrl.dispose();
    super.dispose();
  }

  String _etaString(int minutes) {
    final now = DateTime.now().add(Duration(minutes: minutes));
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final typeInfo = switch (m.type) {
      'express' => ('EXPRESS +500 FCFA', AppColors.primary),
      'grouped' => ('GROUPÉE (${m.groupCount})', AppColors.ctaGreen),
      _ => ('STANDARD', Colors.grey.shade600),
    };

    final isExpress = m.type == 'express';
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _appearCtrl]),
      builder: (context, child) {
        final appear = Curves.easeOutCubic.transform(_appearCtrl.value);
        final glow = isExpress ? 0.25 + 0.45 * _glowCtrl.value : 0.0;
        return Opacity(
          opacity: appear,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - appear)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isExpress
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: [
                  const BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 3)),
                  if (isExpress)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glow),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: typeInfo.$2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(typeInfo.$1,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ),
          const SizedBox(height: 10),
          Text(
            '${_fmt(m.gain)} FCFA',
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.restaurant,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: AppColors.ctaGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${m.pickup} → ${m.dropoff}',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('${m.km} km',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('${m.etaMin} min',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time_filled,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Arrivée estimée : ${_etaString(m.etaMin)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final maxDrag = c.maxWidth - _handle - 8;
            return GestureDetector(
              onHorizontalDragUpdate: (d) {
                setState(() {
                  _drag = (_drag + d.delta.dx).clamp(0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_drag > maxDrag * 0.85) {
                  HapticFeedback.heavyImpact();
                  SystemSound.play(SystemSoundType.click);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.ctaGreen,
                      content: Text('Mission acceptée — ${m.restaurant}'),
                    ),
                  );
                  widget.onAccepted?.call();
                }
                setState(() => _drag = 0);
              },
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: AppColors.ctaGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        'Glisser pour accepter',
                        style: TextStyle(
                            color: AppColors.ctaGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                    Positioned(
                      left: 4 + _drag,
                      top: 4,
                      child: Container(
                        width: _handle,
                        height: _handle,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Passer',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
