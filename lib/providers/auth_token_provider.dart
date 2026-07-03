import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/storage/auth_token_storage.dart';

// A simple provider for your storage class
final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

final authTokenProvider = StateProvider<String?>((ref) => null);
