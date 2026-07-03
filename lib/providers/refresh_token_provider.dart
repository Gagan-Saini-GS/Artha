import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/providers/auth_token_provider.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class RefreshTokenState {
  final bool isRefreshing;
  final String? error;

  RefreshTokenState({this.isRefreshing = false, this.error});

  RefreshTokenState copyWith({bool? isRefreshing, String? error}) {
    return RefreshTokenState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

class RefreshTokenNotifier extends StateNotifier<RefreshTokenState> {
  final Ref ref;
  RefreshTokenNotifier(this.ref) : super(RefreshTokenState());

  Future<bool> refreshToken() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final authTokenStorage = ref.read(authTokenStorageProvider);
      final refreshToken = await authTokenStorage.getRefreshToken();

      if (refreshToken == null) {
        state = state.copyWith(
          isRefreshing: false,
          error: 'No refresh token available',
        );
        return false;
      }

      // Create API service without auth token for refresh call

      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final response = await tokenInterceptor.makeStandardRequest(
        'auth/refresh/v1',
        'POST',
        body: {'refreshToken': refreshToken},
      );

      final newAccessToken = response['data']['accessToken'] as String?;

      if (newAccessToken != null) {
        // Save the new access token
        await authTokenStorage.saveToken(newAccessToken);

        // Update the auth token provider
        ref.read(authTokenProvider.notifier).state = newAccessToken;

        state = state.copyWith(isRefreshing: false);
        return true;
      } else {
        state = state.copyWith(
          isRefreshing: false,
          error: 'Failed to refresh token',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Token refresh failed: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final refreshTokenProvider =
    StateNotifierProvider<RefreshTokenNotifier, RefreshTokenState>((ref) {
      return RefreshTokenNotifier(ref);
    });
