import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/utils/constants.dart';
import 'package:tracker/providers/auth_token_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Add a small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final authTokenStorage = ref.read(authTokenStorageProvider);
      final authToken = await authTokenStorage.getToken();

      if (mounted) {
        if (authToken != null && authToken.isNotEmpty) {
          // Initialize auth token provider state
          ref.read(authTokenProvider.notifier).state = authToken;
          // User is authenticated, go to home
          context.go('/home');
        } else {
          // No token found, go to onboarding
          context.go('/onboarding');
        }
      }
    } catch (e) {
      // If there's any error, default to onboarding
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: splashGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Text(
              'Artha',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
