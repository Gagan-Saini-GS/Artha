import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/providers/auth_token_provider.dart';
import 'package:tracker/providers/token_interceptor_provider.dart';

class LoginFormState {
  final String email;
  final String password;
  final bool isLoading;
  final String? emailError;
  final String? passwordError;

  LoginFormState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.emailError,
    this.passwordError,
  });

  LoginFormState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? emailError,
    String? passwordError,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      emailError: emailError,
      passwordError: passwordError,
    );
  }
}

class LoginFormNotifier extends StateNotifier<LoginFormState> {
  final Ref ref;
  LoginFormNotifier(this.ref) : super(LoginFormState());

  void setEmail(String email) {
    state = state.copyWith(email: email, emailError: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, passwordError: null);
  }

  bool _validate() {
    bool isValid = true;

    if (!_isValidEmail(state.email)) {
      state = state.copyWith(emailError: 'Enter a valid email');
      isValid = false;
    }

    if (state.password.length < 6) {
      state = state.copyWith(
        passwordError: 'Password must be at least 6 characters',
      );
      isValid = false;
    }

    return isValid;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4} $');
    return emailRegex.hasMatch(email);
  }

  Future<void> submit(BuildContext context, WidgetRef ref) async {
    if (!_validate() && !mounted) return;

    state = state.copyWith(
      isLoading: true,
      emailError: null,
      passwordError: null,
    );

    try {
      final authTokenStorage = ref.read(authTokenStorageProvider);

      final tokenInterceptor = ref.read(tokenInterceptorProvider);
      final response = await tokenInterceptor.makeStandardRequest(
        'auth/login/v1',
        'POST',
        body: {'email': state.email, 'password': state.password},
      );
      // Extract access token and refresh token from response
      final accessToken = response['data']['accessToken'] as String?;
      final refreshToken = response['data']['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await authTokenStorage.saveToken(accessToken);
        await authTokenStorage.saveRefreshToken(refreshToken);
        ref.read(authTokenProvider.notifier).state = accessToken;
        if (mounted) {
          context.go("/home");
        }
      } else {
        state = state.copyWith(
          emailError: 'Login failed',
          passwordError: 'Invalid credentials',
        );
      }
    } catch (e) {
      state = state.copyWith(
        emailError: 'Login failed',
        passwordError: 'Invalid credentials',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
      return LoginFormNotifier(ref);
    });
