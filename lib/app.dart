import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/phone_input_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/courses/screens/courses_screen.dart';
import 'features/courses/data/models/course_model.dart';
import 'features/navigation/screens/navigation_screen.dart';
import 'features/earnings/screens/earnings_screen.dart';
import 'features/profile/screens/profile_screen.dart';

class App extends StatelessWidget {
  App({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const MainShell(initialIndex: 0),
      ),
      GoRoute(
        path: '/earnings',
        builder: (context, state) => const MainShell(initialIndex: 1),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const MainShell(initialIndex: 2),
      ),
      GoRoute(
        path: '/navigation/:orderId',
        builder: (context, state) => NavigationScreen(
          orderId: state.pathParameters['orderId']!,
          initialCourse: state.extra as CourseModel?,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Page introuvable'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/courses'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 56)),
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
      title: 'NYAMA Rider',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'CM'),
      supportedLocales: const [
        Locale('fr', 'CM'),
        Locale('fr', 'FR'),
      ],
    );
  }
}

// ── Shell principal — 3 onglets ───────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  static const _screens = [
    CoursesScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // ── Offline banner ─────────────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: offlineNotifier,
            builder: (_, isOffline, _) {
              if (!isOffline) return const SizedBox.shrink();
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: const Text(
                      '📡 Hors connexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.motorcycle_outlined, size: 28),
            activeIcon: Icon(Icons.motorcycle, size: 28),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
            activeIcon: Icon(Icons.account_balance_wallet, size: 28),
            label: 'Gains',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
