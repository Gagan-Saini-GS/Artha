import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/providers/auth_token_provider.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class LogoutState {
  final bool isLoggingOut;
  final String? error;

  LogoutState({this.isLoggingOut = false, this.error});

  LogoutState copyWith({bool? isLoggingOut, String? error}) {
    return LogoutState(
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      error: error,
    );
  }
}

class LogoutNotifier extends StateNotifier<LogoutState> {
  final Ref ref;
  LogoutNotifier(this.ref) : super(LogoutState());

  Future<void> logout(BuildContext context) async {
    state = state.copyWith(isLoggingOut: true, error: null);

    try {
      final authTokenStorage = ref.read(authTokenStorageProvider);
      final refreshToken = await authTokenStorage.getRefreshToken();

      if (refreshToken != null) {
        // Create API service without auth token for logout call
        // Call logout API
        final tokenInterceptor = ref.read(tokenInterceptorProvider);
        await tokenInterceptor.makeStandardRequest(
          'auth/logout/v1',
          'POST',
          body: {'refreshToken': refreshToken},
        );
      }

      // Clear all tokens from storage
      await authTokenStorage.clearAllTokens();

      // Clear auth token from provider
      ref.read(authTokenProvider.notifier).state = null;

      state = state.copyWith(isLoggingOut: false);

      // Navigate to onboarding screen
      if (context.mounted) {
        context.go("/onboarding");
      }
    } catch (e) {
      // Even if logout API fails, clear local tokens
      final authTokenStorage = ref.read(authTokenStorageProvider);
      await authTokenStorage.clearAllTokens();
      ref.read(authTokenProvider.notifier).state = null;

      state = state.copyWith(
        isLoggingOut: false,
        error: 'Logout failed: ${e.toString()}',
      );

      // Navigate to onboarding screen even if API call failed
      if (context.mounted) {
        context.go("/onboarding");
      }
    } finally {
      state = state.copyWith(isLoggingOut: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final logoutProvider = StateNotifierProvider<LogoutNotifier, LogoutState>((
  ref,
) {
  return LogoutNotifier(ref);
});
