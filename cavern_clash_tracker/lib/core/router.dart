import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/database.dart';
import '../features/coach_ai/coach_ai_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/nutrition/nutrition_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/routines/routines_screen.dart';
import '../features/settings/settings_page.dart';
import '../features/training/training_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final db = ref.watch(databaseProvider);
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashRoute()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/training', builder: (context, state) => const TrainingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/routines', builder: (context, state) => const RoutinesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/nutrition', builder: (context, state) => const NutritionPage())]),
          StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (context, state) => const SettingsPage())]),
        ],
      ),
      GoRoute(path: '/coach-ai', builder: (context, state) => const CoachAiPage()),
    ],
    redirect: (context, state) async {
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isSplash = state.matchedLocation == '/splash';
      final isCoach = state.matchedLocation == '/coach-ai';
      if (isCoach) return null;
      if (isSplash) {
        final user = await db.userDao.getUser(1);
        if (user == null) {
          return '/onboarding';
        }
        return '/dashboard';
      }
      if (!isOnboarding && !isSplash && !state.matchedLocation.startsWith('/dashboard')) {
        final user = await db.userDao.getUser(1);
        if (user == null) {
          return '/onboarding';
        }
      }
      return null;
    },
  );
  return router;
});

class SplashRoute extends ConsumerWidget {
  const SplashRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Entrenamiento'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Nutrición'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
      appBar: AppBar(
        title: const Text('Cavern Clash Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.go('/coach-ai'),
          ),
        ],
      ),
    );
  }
}
