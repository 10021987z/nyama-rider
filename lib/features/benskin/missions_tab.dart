import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../courses/data/models/course_model.dart';
import '../courses/providers/courses_provider.dart';

// ── Mock fallback ───────────────────────────────────────────────────────────

final _mockMissions = [
  CourseModel(
    id: 'mock-1',
    cookName: 'Le Relais de Sawa',
    cookAddress: 'Akwa',
    deliveryAddress: 'Bonapriso',
    totalXaf: 1200,
    deliveryFeeXaf: 1200,
    items: const [CourseItemModel(name: 'Ndole Royal', quantity: 1)],
    createdAt: DateTime.now(),
    status: 'ready',
    distanceM: 3200,
    estimatedMinutes: 18,
  ),
  CourseModel(
    id: 'mock-2',
    cookName: 'Maison H',
    cookAddress: 'Bonamoussadi',
    deliveryAddress: 'Kotto',
    totalXaf: 850,
    deliveryFeeXaf: 850,
    items: const [CourseItemModel(name: 'Poulet DG', quantity: 1)],
    createdAt: DateTime.now(),
    status: 'ready',
    distanceM: 4800,
    estimatedMinutes: 25,
  ),
  CourseModel(
    id: 'mock-3',
    cookName: 'Tchop et Yamo',
    cookAddress: 'Deido',
    deliveryAddress: 'Multiple',
    totalXaf: 2100,
    deliveryFeeXaf: 2100,
    items: const [
      CourseItemModel(name: 'Eru & Waterfufu', quantity: 1),
      CourseItemModel(name: 'Achu', quantity: 1),
    ],
    createdAt: DateTime.now(),
    status: 'ready',
    distanceM: 6100,
    estimatedMinutes: 30,
  ),
];

class MissionsTab extends ConsumerStatefulWidget {
  const MissionsTab({super.key});

  @override
  ConsumerState<MissionsTab> createState() => _MissionsTabState();
}

class _MissionsTabState extends ConsumerState<MissionsTab>
    with TickerProviderStateMixin {
  bool _online = true;
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
    final apiCourses = ref.watch(availableCoursesProvider);
    final missions = apiCourses.isEmpty ? _mockMissions : apiCourses;
    final totalGain =
        missions.fold<int>(0, (s, c) => s + c.deliveryFeeXaf);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(availableCoursesProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _header(),
              const SizedBox(height: 16),
              _onlineToggle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _earningsCard(totalGain)),
                  const SizedBox(width: 12),
                  Expanded(
                      child:
                          _statCard('MISSIONS', '${missions.length}')),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PROXIMITE IMMEDIATE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _pill('${missions.length} NOUVELLES', AppColors.primary),
                ],
              ),
              const SizedBox(height: 12),
              if (!_online)
                _idleState()
              else
                ...missions.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MissionCard(
                        course: e.value,
                        index: e.key,
                        onAccepted: () => _acceptMission(e.value),
                        onDismissed: () => _dismissMission(e.value),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptMission(CourseModel course) async {
    try {
      final accepted =
          await ref.read(availableCoursesProvider.notifier).accept(course.id);
      if (!mounted) return;
      ref.read(activeCourseProvider.notifier).state = accepted;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ctaGreen,
          content: Text('Mission acceptee !',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Fallback: still set as active for mock
      ref.read(activeCourseProvider.notifier).state = course;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ctaGreen,
          content: Text('Mission acceptee (mode demo)',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    }
  }

  void _dismissMission(CourseModel course) {
    ref.read(availableCoursesProvider.notifier).dismissCourse(course.id);
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
    if (!_online) return _pill('HORS LIGNE', Colors.grey);
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
                Icon(
                    _online
                        ? Icons.radio_button_checked
                        : Icons.power_settings_new,
                    color: Colors.white,
                    size: 36),
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

  Widget _statCard(String label, String value) {
    return Container(
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
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.textPrimary)),
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
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11)),
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
                const Text('Notifications desactivees',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                const Text(
                  "Active les notifications pour etre alerte des qu'une course arrive.",
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
                "Tu seras alerte des qu'une course arrive !",
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
            child: Image.asset('assets/images/logo_nyama.jpg',
                fit: BoxFit.cover),
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
            'Astuce : rapproche-toi des zones chaudes - Akwa, Bonapriso, Deido.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
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
}

// ── Mission Card with swipe ─────────────────────────────────────────────────

class _MissionCard extends StatefulWidget {
  final CourseModel course;
  final int index;
  final VoidCallback? onAccepted;
  final VoidCallback? onDismissed;
  const _MissionCard({
    required this.course,
    this.index = 0,
    this.onAccepted,
    this.onDismissed,
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
  late final AnimationController _acceptCtrl;
  late final AnimationController _flashCtrl;
  bool _accepted = false;

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
    _acceptCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _appearCtrl.forward();
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _appearCtrl.dispose();
    _acceptCtrl.dispose();
    _flashCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAccept(BuildContext context) async {
    if (_accepted) return;
    setState(() => _accepted = true);
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    _flashCtrl.forward();
    widget.onAccepted?.call();
    await Future.delayed(const Duration(milliseconds: 200));
    _acceptCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.course;
    final isExpress = m.deliveryFeeXaf >= 1000;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_glowCtrl, _appearCtrl, _acceptCtrl, _flashCtrl]),
      builder: (context, child) {
        final appear = Curves.easeOutCubic.transform(_appearCtrl.value);
        final glow = isExpress ? 0.25 + 0.45 * _glowCtrl.value : 0.0;
        final accept = Curves.easeInCubic.transform(_acceptCtrl.value);
        return Opacity(
          opacity: appear * (1 - accept),
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - appear) + (-80 * accept)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Container(
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
                  if (_flashCtrl.value > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: AppColors.ctaGreen
                              .withValues(alpha: 0.3 * (1 - _flashCtrl.value)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExpress)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('EXPRESS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ),
          const SizedBox(height: 10),
          Text(
            '${_fmt(m.deliveryFeeXaf)} FCFA',
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
                child: Text(m.cookName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 20, color: AppColors.ctaGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${m.cookAddress ?? "Restaurant"} -> ${m.deliveryAddress}',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(m.distanceLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(width: 16),
              const Icon(Icons.schedule,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(m.estimatedLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final maxDrag = c.maxWidth - _handle - 8;
            final progress =
                maxDrag <= 0 ? 0.0 : (_drag / maxDrag).clamp(0.0, 1.0);
            return GestureDetector(
              onHorizontalDragUpdate: (d) {
                if (_accepted) return;
                setState(() {
                  _drag = (_drag + d.delta.dx).clamp(0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_accepted) return;
                if (_drag > maxDrag * 0.85) {
                  _onAccept(context);
                } else {
                  setState(() => _drag = 0);
                }
              },
              child: Container(
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: AppColors.ctaGreen
                      .withValues(alpha: 0.2 + 0.6 * progress),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4 + _drag + _handle / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.35 + 0.3 * progress),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Center(
                      child: Opacity(
                        opacity: (1 - progress * 1.3).clamp(0.0, 1.0),
                        child: const Text('Glisser pour accepter',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
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
              onPressed: widget.onDismissed,
              child: const Text('Passer',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
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
