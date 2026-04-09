import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/benskin/missions_tab.dart';
import 'features/benskin/navigation_tab.dart';
import 'features/benskin/revenue_tab.dart';
import 'features/benskin/profile_tab.dart';

class App extends StatelessWidget {
  App({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const PhoneInputScreen()),
      GoRoute(path: '/phone', builder: (_, __) => const PhoneInputScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) =>
            OtpVerificationScreen(phone: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/home', builder: (_, __) => const MainShell()),
      GoRoute(
          path: '/courses',
          builder: (_, __) => const MainShell(initialIndex: 0)),
      GoRoute(
          path: '/earnings',
          builder: (_, __) => const MainShell(initialIndex: 2)),
      GoRoute(
          path: '/profile',
          builder: (_, __) => const MainShell(initialIndex: 3)),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page introuvable'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Accueil'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Benskin Express',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'CM'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'CM'),
        Locale('fr', 'FR'),
        Locale('en'),
      ],
    );
  }
}

// ── Shell 4 tabs ─────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToTab(int i) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = i);
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goMissions() => _goToTab(0);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const MissionsTab(),
      NavigationTab(hasActiveMission: true, onGoToMissions: _goMissions),
      const RevenueTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageCtrl,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: screens,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: offlineNotifier,
            builder: (_, isOffline, __) {
              if (!isOffline) return const SizedBox.shrink();
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: const Text(
                      'Mode hors-ligne — Le GPS fonctionne toujours',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu, size: 28), label: 'Missions'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions, size: 28), label: 'Navigation'),
          BottomNavigationBarItem(
              icon: Icon(Icons.payments, size: 28), label: 'Revenus'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28), label: 'Profil'),
        ],
      ),
    );
  }
}

// Mission complete overlay helper — can be shown from anywhere.
Future<void> showMissionCompleteOverlay(BuildContext context,
    {int gain = 1250}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 80, color: AppColors.ctaGreen),
            const SizedBox(height: 14),
            Text(
              '+$gain FCFA',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Bien joué Kevin !',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ctaGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Prochaine mission',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
