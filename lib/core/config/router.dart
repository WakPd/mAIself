import "package:go_router/go_router.dart";

import "../../features/auth/presentation/screens/login_screen.dart";
import "../../features/auth/presentation/screens/profile_setup_screen.dart";
import "../../features/auth/presentation/screens/register_screen.dart";
import "../../features/dashboard/presentation/screens/home_screen.dart";
import "../../features/history/presentation/screens/history_screen.dart";
import "../../features/scan/presentation/screens/result_screen.dart";
import "../../features/scan/presentation/screens/scan_screen.dart";
import "../../features/sport/presentation/screens/sport_screen.dart";

final GoRouter appRouter = GoRouter(
  initialLocation: "/login",
  routes: <GoRoute>[
    GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
    GoRoute(path: "/register", builder: (context, state) => const RegisterScreen()),
    GoRoute(path: "/profile-setup", builder: (context, state) => const ProfileSetupScreen()),
    GoRoute(path: "/home", builder: (context, state) => const HomeScreen()),
    GoRoute(path: "/scan", builder: (context, state) => const ScanScreen()),
    GoRoute(path: "/result", builder: (context, state) => const ResultScreen()),
    GoRoute(path: "/sport", builder: (context, state) => const SportScreen()),
    GoRoute(path: "/history", builder: (context, state) => const HistoryScreen()),
  ],
);
