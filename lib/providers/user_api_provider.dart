import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:tracker/models/user.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class UserApiState {
  final User? user;
  final bool isLoading;
  final String? error;

  UserApiState({this.user, this.isLoading = false, this.error});

  UserApiState copyWith({User? user, bool? isLoading, String? error}) {
    return UserApiState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserApiNotifier extends StateNotifier<UserApiState> {
  final Ref ref;
  UserApiNotifier(this.ref) : super(UserApiState()) {
    fetchUserProfile();
  }

  Future<User?> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'users/get/v1',
        'GET',
      );
      final userData = response['data'] ?? response['user'] ?? response;
      final user = User.fromJson(userData);

      state = state.copyWith(user: user);
      return user;
    } catch (e) {
      Logger().e(e);
      state = state.copyWith(
        error: 'Failed to fetch user profile: ${e.toString()}',
      );
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<User?> updateUserProfile({
    required String name,
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final response = await tokenInterceptor.makeAuthenticatedRequest(
        'users/update/v1',
        'POST',
        body: {'name': name, 'email': email, 'currency': "INR"},
      );
      final userData = response['data'] ?? response['user'] ?? response;
      final user = User.fromJson(userData);
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update user profile:  [31m${e.toString()} [0m',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final userApiProvider = StateNotifierProvider<UserApiNotifier, UserApiState>((
  ref,
) {
  return UserApiNotifier(ref);
});
