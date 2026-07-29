import 'package:go_router/go_router.dart';
import 'package:tracker/screens/onboarding/login_form.dart';
import 'package:tracker/screens/onboarding/signup_form.dart';
import 'package:tracker/screens/transaction/add_transaction_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginForm()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupForm()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(path: '/wallet', builder: (context, state) => const WalletScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/add-transaction',
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
