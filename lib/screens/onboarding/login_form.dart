import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tracker/providers/login_provider.dart';
import 'package:tracker/utils/constants.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginForm();
}

class _LoginForm extends ConsumerState<LoginForm> {
  // Means hide password, true means hide, false means show.
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(loginFormProvider);
    final formNotifier = ref.read(loginFormProvider.notifier);

    return Scaffold(
      backgroundColor: blackColor,
      appBar: AppBar(
        backgroundColor: darkGreenColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () {
            context.go("/onboarding");
          },
        ),
        title: Text(
          'Login Into Artha',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      "Sign In",
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Hi! Welcome Back, you've been missed.",
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                onChanged: formNotifier.setEmail,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: whiteColor),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter Email',
                  labelStyle: TextStyle(color: whiteColor),
                  hintStyle: TextStyle(color: whiteColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: whiteColor.withAlpha(200)),
                  ),
                  iconColor: whiteColor,
                  errorText: form.emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: formNotifier.setPassword,
                obscureText: _obscurePassword,
                style: TextStyle(color: whiteColor),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  labelStyle: TextStyle(color: whiteColor),
                  hintStyle: TextStyle(color: whiteColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: whiteColor.withAlpha(200)),
                  ),
                  iconColor: whiteColor,
                  suffixIconColor: whiteColor,
                  errorText: form.passwordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _togglePasswordVisibility,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: form.isLoading
                      ? null
                      : () {
                          formNotifier.submit(context, ref);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreenColor,
                    foregroundColor: whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: form.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't Have Account? ",
                    style: TextStyle(color: lightGrayColor, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go("/signup");
                    },
                    child: Text(
                      'Create account',
                      style: TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
