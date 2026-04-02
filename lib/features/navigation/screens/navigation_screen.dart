import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../core/utils/sound_service.dart';
import '../../../features/courses/data/models/course_model.dart';
import '../../../features/courses/providers/courses_provider.dart';
import '../../../shared/widgets/swipe_button.dart';
import '../providers/navigation_provider.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final CourseModel? initialCourse;

  const NavigationScreen({
    super.key,
    required this.orderId,
    this.initialCourse,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  CourseModel? _course;
  GoogleMapController? _mapController;
  Position? _riderPosition;
  StreamSubscription<Position>? _positionSub;
  bool _gpsWeak = false;
  bool _showSuccess = false;
  bool _isUpdatingStatus = false;
  int _swipeResetKey = 0;

  // Douala/Akwa par défaut — position centrale si GPS indisponible
  static const LatLng _akwa = LatLng(4.0553, 9.7322);

  @override
  void initState() {
    super.initState();
    _course = widget.initialCourse;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDelivery();
      _startGpsTracking();
    });
  }

  void _initDelivery() {
    final course = _course;
    if (course == null) {
      final active = ref.read(activeCourseProvider);
      if (active != null && active.id == widget.orderId) {
        setState(() => _course = active);
        ref
            .read(activeDeliveryProvider.notifier)
            .startDelivery(active.id, active);
      }
      return;
    }
    ref
        .read(activeDeliveryProvider.notifier)
        .startDelivery(course.id, course);
  }

  Future<void> _startGpsTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _gpsWeak = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _gpsWeak = true);
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      _onPosition,
      onError: (_) {
        if (mounted) setState(() => _gpsWeak = true);
      },
    );
  }

  void _onPosition(Position pos) {
    final repo = ref.read(navigationRepositoryProvider);
    repo.emitLocation(
      lat: pos.latitude,
      lng: pos.longitude,
      heading: pos.heading,
      speed: pos.speed,
    );
    setState(() {
      _riderPosition = pos;
      _gpsWeak = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Status transitions ────────────────────────────────────────────────────

  Future<void> _updateStatus(String status) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      final repo = ref.read(navigationRepositoryProvider);
      await repo.updateDeliveryStatus(widget.orderId, status);
      if (!mounted) return;
      ref.read(activeDeliveryProvider.notifier).advanceStep();
      setState(() => _isUpdatingStatus = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
        _swipeResetKey++;
      });
      _showErrorSnack(e.statusCode == 400
          ? 'Cette étape est déjà validée'
          : 'Erreur, réessayez');
    }
  }

  Future<void> _completeDelivery() async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);

    try {
      final repo = ref.read(navigationRepositoryProvider);
      await repo.updateDeliveryStatus(widget.orderId, 'DELIVERED');
      if (!mounted) return;

      await SoundService.playDeliveredSound();
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
        _showSuccess = true;
      });

      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      ref.read(activeDeliveryProvider.notifier).clear();
      ref.read(activeCourseProvider.notifier).state = null;
      ref.read(availableCoursesProvider.notifier).refresh();

      if (mounted) context.go('/courses');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
        _swipeResetKey++;
      });
      _showErrorSnack(e.statusCode == 400
          ? 'Cette étape est déjà validée'
          : 'Erreur, réessayez');
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 15)),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(activeDeliveryProvider);
    final step = deliveryState?.step ?? DeliveryStep.arrivingRestaurant;
    final course = _course;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Carte plein écran
            Positioned.fill(child: _buildMap(course, step)),

            // 2. Barre de progression + bannière GPS
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProgressBar(step),
                    if (_gpsWeak) _buildGpsBanner(),
                  ],
                ),
              ),
            ),

            // 3. Panneau bas draggable
            DraggableScrollableSheet(
              initialChildSize: 0.32,
              minChildSize: 0.22,
              maxChildSize: 0.55,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      if (course != null)
                        _buildStepContent(course, step)
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Overlay succès
            if (_showSuccess && course != null)
              Positioned.fill(child: _buildSuccessOverlay(course)),
          ],
        ),
      ),
    );
  }

  // ── Carte Google Maps ────────────────────────────────────────────────────

  Widget _buildMap(CourseModel? course, DeliveryStep step) {
    final riderPos = _riderPosition != null
        ? LatLng(_riderPosition!.latitude, _riderPosition!.longitude)
        : _akwa;

    LatLng? destinationPos;
    if (course != null) {
      final isRestaurantPhase = step == DeliveryStep.arrivingRestaurant ||
          step == DeliveryStep.atRestaurant;
      if (isRestaurantPhase) {
        destinationPos = (course.cookLat != null && course.cookLng != null)
            ? LatLng(course.cookLat!, course.cookLng!)
            : _akwa;
      } else {
        if (course.deliveryLat != null && course.deliveryLng != null) {
          destinationPos =
              LatLng(course.deliveryLat!, course.deliveryLng!);
        }
      }
    }

    final isRestaurantPhase = step == DeliveryStep.arrivingRestaurant ||
        step == DeliveryStep.atRestaurant;

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('rider'),
        position: riderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Vous'),
      ),
      if (destinationPos != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destinationPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isRestaurantPhase
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: isRestaurantPhase
                ? (course?.cookName ?? 'Restaurant')
                : 'Client',
          ),
        ),
    };

    final Set<Polyline> polylines = {
      if (destinationPos != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points: [riderPos, destinationPos],
          color: const Color(0xFF1B4332),
          width: 5,
        ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: riderPos, zoom: 15),
      onMapCreated: (controller) => _mapController = controller,
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  // ── Barre de progression ─────────────────────────────────────────────────

  Widget _buildProgressBar(DeliveryStep step) {
    const labels = ['Restaurant', 'Récupéré', 'Client', 'Livré'];
    final steps = DeliveryStep.values;
    final currentIndex = steps.indexOf(step);

    return Container(
      color: Colors.white,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepBefore = i ~/ 2;
            final passed = stepBefore < currentIndex;
            return Expanded(
              child: Container(
                height: 3,
                color: passed
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final passed = stepIndex < currentIndex;
          final active = stepIndex == currentIndex;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 28 : 24,
                height: active ? 28 : 24,
                decoration: BoxDecoration(
                  color: passed || active
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: passed
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : active
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                  color: passed || active
                      ? AppColors.primary
                      : Colors.grey.shade400,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildGpsBanner() {
    return Container(
      color: const Color(0xFFFFD600),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Row(
        children: [
          Text('📡', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text(
            'Signal GPS faible',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenu du panneau selon l'étape ─────────────────────────────────────

  Widget _buildStepContent(CourseModel course, DeliveryStep step) {
    switch (step) {
      case DeliveryStep.arrivingRestaurant:
        return _buildStep1(course);
      case DeliveryStep.atRestaurant:
        return _buildStep2(course);
      case DeliveryStep.deliveringToClient:
        return _buildStep3(course);
      case DeliveryStep.atClient:
        return _buildStep4(course);
    }
  }

  // ── Étape 1 — En route vers le restaurant ───────────────────────────────

  Widget _buildStep1(CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🍽️ Allez chez ${course.cookName}',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (course.cookAddress != null) ...[
          const SizedBox(height: 4),
          Text(
            course.cookAddress!,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        if (course.cookPhone != null)
          OutlinedButton.icon(
            onPressed: () => _callPhone(course.cookPhone!),
            icon: const Text('📞', style: TextStyle(fontSize: 16)),
            label: const Text('Appeler la cuisinière'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateStatus('ARRIVED_RESTAURANT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navBlue,
              disabledBackgroundColor:
                  AppColors.navBlue.withValues(alpha: 0.5),
            ),
            child: _isUpdatingStatus
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3)
                : const Text(
                    'JE SUIS ARRIVÉ AU RESTAURANT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Étape 2 — Au restaurant (récupération) ───────────────────────────────

  Widget _buildStep2(CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Vérifiez la commande',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...course.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${item.quantity}x ${item.name}',
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textPrimary),
            ),
          ),
        ),
        if (course.clientNote != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💬 ${course.clientNote!}',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '#${course.shortId}',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (course.cookPhone != null)
          OutlinedButton.icon(
            onPressed: () => _callPhone(course.cookPhone!),
            icon: const Text('📞', style: TextStyle(fontSize: 16)),
            label: const Text('Appeler la cuisinière'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        const SizedBox(height: 16),
        SwipeButton(
          key: ValueKey(_swipeResetKey),
          label: "J'AI RÉCUPÉRÉ LA COMMANDE →",
          color: AppColors.primary,
          enabled: !_isUpdatingStatus,
          onConfirmed: () => _updateStatus('PICKED_UP'),
        ),
      ],
    );
  }

  // ── Étape 3 — En route vers le client ───────────────────────────────────

  Widget _buildStep3(CourseModel course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏍️ En route vers le client',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          course.deliveryAddress,
          style: const TextStyle(
              fontSize: 16, color: AppColors.textPrimary),
        ),
        if (course.landmark != null) ...[
          const SizedBox(height: 4),
          Text(
            '📍 ${course.landmark!}',
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 12),
        if (course.clientPhone != null)
          OutlinedButton.icon(
            onPressed: () => _callPhone(course.clientPhone!),
            icon: const Text('📞', style: TextStyle(fontSize: 16)),
            label: const Text('Appeler le client'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton(
            onPressed: _isUpdatingStatus
                ? null
                : () => _updateStatus('ARRIVED_CLIENT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navBlue,
              disabledBackgroundColor:
                  AppColors.navBlue.withValues(alpha: 0.5),
            ),
            child: _isUpdatingStatus
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3)
                : const Text(
                    'JE SUIS ARRIVÉ CHEZ LE CLIENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Étape 4 — Remise au client ───────────────────────────────────────────

  Widget _buildStep4(CourseModel course) {
    final isCash = course.paymentMethod == 'CASH';
    final totalAmount = course.totalXaf + course.deliveryFeeXaf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📦 Remettez la commande',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (isCash)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '💵 Encaissez ${totalAmount.toFcfa()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.error,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '✅ Déjà payé par Mobile Money',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        SwipeButton(
          key: ValueKey(_swipeResetKey),
          label: 'COMMANDE LIVRÉE ✅ →',
          color: AppColors.secondary,
          enabled: !_isUpdatingStatus,
          onConfirmed: _completeDelivery,
        ),
      ],
    );
  }

  // ── Overlay succès ────────────────────────────────────────────────────────

  Widget _buildSuccessOverlay(CourseModel course) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Bien joué !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${course.deliveryFeeXaf.toFcfa()}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
