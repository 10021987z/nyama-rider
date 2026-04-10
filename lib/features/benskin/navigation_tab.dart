import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../courses/data/models/course_model.dart';
import '../courses/providers/courses_provider.dart';
import '../navigation/providers/navigation_provider.dart';
import '../sos/sos_screen.dart';
import '../sos/sos_service.dart';

class NavigationTab extends ConsumerStatefulWidget {
  final bool hasActiveMission;
  final VoidCallback onGoToMissions;
  const NavigationTab({
    super.key,
    this.hasActiveMission = true,
    required this.onGoToMissions,
  });

  @override
  ConsumerState<NavigationTab> createState() => _NavigationTabState();
}

class _NavigationTabState extends ConsumerState<NavigationTab>
    with TickerProviderStateMixin {
  /// 0 = EN ROUTE, 1 = AU RESTAURANT, 2 = EN LIVRAISON, 3 = LIVRÉ
  int _step = 0;
  late final AnimationController _pulseCtrl;
  late final ConfettiController _confettiCtrl;

  // ── Google Maps ──────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng? _riderPosition;
  StreamSubscription<Position>? _positionSub;
  final bool _useRealMap = true; // falls back to simulated if GoogleMap fails

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 2));
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _riderPosition = LatLng(pos.latitude, pos.longitude));

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _riderPosition = LatLng(pos.latitude, pos.longitude));
      });
    } catch (_) {
      // GPS unavailable — keep null position
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Advance step + call API for delivery status update
  Future<void> _advance() async {
    HapticFeedback.selectionClick();
    final course = ref.read(activeCourseProvider);
    final navRepo = ref.read(navigationRepositoryProvider);

    // Map step → API status
    String? apiStatus;
    switch (_step) {
      case 0:
        apiStatus = 'ARRIVED';
        break;
      case 1:
        apiStatus = 'PICKED_UP';
        break;
      case 2:
        apiStatus = 'DELIVERED';
        break;
    }

    // Call API if we have an active course
    if (course != null && apiStatus != null) {
      try {
        await navRepo.updateDeliveryStatus(course.id, apiStatus);
      } catch (_) {
        // Continue even if API fails — offline-first
      }
    }

    setState(() => _step = (_step + 1).clamp(0, 3));
    if (_step == 3) {
      HapticFeedback.lightImpact();
      _confettiCtrl.play();
      // Clear active course after delivery
      ref.read(activeCourseProvider.notifier).state = null;
    }
  }

  Future<void> _call(String number) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _triggerSos() async {
    final ok = await confirmSos(context);
    if (!ok || !mounted) return;
    final alert = await SosService.instance.trigger();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SosSentScreen(alert: alert)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(activeCourseProvider);
    final hasActive = course != null;

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
          hasActive ? _activeMission(context, course) : _noMission(),
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

  Widget _activeMission(BuildContext context, CourseModel course) {
    final restaurantPhone = course.cookPhone ?? '+237699000001';
    final clientPhone = course.clientPhone ?? '+237699000002';
    final clientName = course.deliveryAddress;
    final cookName = course.cookName;
    final cookAddress = course.cookAddress ?? 'Adresse inconnue';
    final distance = course.distanceLabel;
    final eta = course.estimatedMinutes != null
        ? '${course.estimatedMinutes} MIN RESTANTS'
        : '— MIN';

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: _useRealMap
              ? _googleMapWidget(course, restaurantPhone, clientPhone)
              : _WazeMap(
                  pulseCtrl: _pulseCtrl,
                  onCallRestaurant: () => _call(restaurantPhone),
                  onCallClient: () => _call(clientPhone),
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
                  Text(
                    distance,
                    style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Text(eta,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.9))),
                ],
              ),
              const SizedBox(height: 6),
              Text(cookName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              Text(cookAddress,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              _progress(),
              const SizedBox(height: 14),
              _clientCard(clientName, clientPhone),
              const SizedBox(height: 12),
              _actionRow(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Google Map widget ──────────────────────────────────────────────────────

  Widget _googleMapWidget(CourseModel course, String restaurantPhone, String clientPhone) {
    final cookLat = course.cookLat;
    final cookLng = course.cookLng;
    final delivLat = course.deliveryLat;
    final delivLng = course.deliveryLng;

    // Default center: Douala
    final defaultCenter = LatLng(4.0511, 9.7679);
    final center = _riderPosition ??
        (cookLat != null && cookLng != null
            ? LatLng(cookLat, cookLng)
            : defaultCenter);

    // Markers
    final markers = <Marker>{};
    if (cookLat != null && cookLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('restaurant'),
        position: LatLng(cookLat, cookLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: course.cookName),
      ));
    }
    if (delivLat != null && delivLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('client'),
        position: LatLng(delivLat, delivLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: course.deliveryAddress),
      ));
    }
    if (_riderPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Ma position'),
      ));
    }

    // Polyline between points
    final polylinePoints = <LatLng>[];
    if (_riderPosition != null) polylinePoints.add(_riderPosition!);
    if (cookLat != null && cookLng != null) {
      polylinePoints.add(LatLng(cookLat, cookLng));
    }
    if (delivLat != null && delivLng != null) {
      polylinePoints.add(LatLng(delivLat, delivLng));
    }

    final polylines = <Polyline>{};
    if (polylinePoints.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: AppColors.primary,
        width: 4,
      ));
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 14),
          markers: markers,
          polylines: polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitBounds(markers);
          },
        ),
        // FABs d'appel
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              _callFab(
                  icon: Icons.restaurant,
                  color: AppColors.primary,
                  onTap: () => _call(restaurantPhone)),
              const SizedBox(height: 10),
              _callFab(
                  icon: Icons.person,
                  color: AppColors.secondary,
                  onTap: () => _call(clientPhone)),
              const SizedBox(height: 10),
              _callFab(
                  icon: Icons.my_location,
                  color: Colors.blue,
                  onTap: _centerOnRider),
            ],
          ),
        ),
      ],
    );
  }

  void _fitBounds(Set<Marker> markers) {
    if (_mapController == null || markers.length < 2) return;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      60,
    ));
  }

  void _centerOnRider() {
    if (_mapController == null || _riderPosition == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_riderPosition!, 16),
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
        width: 52,
        height: 52,
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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        // Bouton SOS
        GestureDetector(
          onTap: _triggerSos,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8413C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8413C).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 26),
                Text('SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _mainActionButton()),
      ],
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

  Widget _clientCard(String clientName, String clientPhone) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(clientPhone,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _call(clientPhone),
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
                    fontSize: 18,
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
                  fontSize: 18,
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

// ─────────────────────────────────────────────────────────────────────────────
// Carte style Waze (fallback si GoogleMap non dispo)
// ─────────────────────────────────────────────────────────────────────────────

class _WazeMap extends StatelessWidget {
  final AnimationController pulseCtrl;
  final VoidCallback onCallRestaurant;
  final VoidCallback onCallClient;
  const _WazeMap({
    required this.pulseCtrl,
    required this.onCallRestaurant,
    required this.onCallClient,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _StreetGridPainter()),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _RoutePainter()),
        ),
        const Positioned(
          top: 60,
          right: 40,
          child: _MapMarker(color: AppColors.primary, icon: Icons.restaurant),
        ),
        const Positioned(
          top: 90,
          left: 50,
          child: _MapMarker(color: AppColors.ctaGreen, icon: Icons.home),
        ),
        Positioned(
          bottom: 90,
          left: 80,
          child: AnimatedBuilder(
            animation: pulseCtrl,
            builder: (context, _) {
              return SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40 * (0.7 + 0.3 * pulseCtrl.value),
                      height: 40 * (0.7 + 0.3 * pulseCtrl.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue
                            .withValues(alpha: 0.25 * (1 - pulseCtrl.value)),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
                  onTap: onCallRestaurant),
              const SizedBox(height: 10),
              _callFab(
                  icon: Icons.person,
                  color: AppColors.secondary,
                  onTap: onCallClient),
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
        width: 52,
        height: 52,
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
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MapMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x44000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _StreetGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD).withValues(alpha: 0.6)
      ..strokeWidth = 2;

    const hSpacing = 60.0;
    for (double y = hSpacing; y < size.height; y += hSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    const vSpacing = 70.0;
    for (double x = vSpacing; x < size.width; x += vSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final start = Offset(40, size.height - 80);
    final end = Offset(size.width - 50, 80);
    const dashLen = 14.0;
    const gap = 8.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final mag = math.sqrt(dx * dx + dy * dy);
    if (mag == 0) return;
    final ux = dx / mag;
    final uy = dy / mag;
    double traveled = 0;
    while (traveled < mag) {
      final p1 = Offset(start.dx + ux * traveled, start.dy + uy * traveled);
      final nextLen = math.min(traveled + dashLen, mag);
      final p2 = Offset(start.dx + ux * nextLen, start.dy + uy * nextLen);
      canvas.drawLine(p1, p2, paint);
      traveled += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
