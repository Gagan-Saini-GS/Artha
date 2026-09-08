import 'package:tracker/api/api_service.dart';
import 'package:tracker/storage/auth_token_storage.dart';

class TokenInterceptor {
  final AuthTokenStorage _authTokenStorage;
  final String _baseUrl;
  bool _isRefreshing = false;

  TokenInterceptor({
    required AuthTokenStorage authTokenStorage,
    required String baseUrl,
  }) : _authTokenStorage = authTokenStorage,
       _baseUrl = baseUrl;

  Future<dynamic> makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      // First attempt with current token
      final token = await _authTokenStorage.getToken();
      final apiService = ApiService(baseUrl: _baseUrl, authToken: token);

      final response = await _makeRequest(
        apiService,
        endpoint,
        method,
        body,
        queryParams: queryParams,
      );
      return response;
    } catch (e) {
      // If first attempt fails with 401, try to refresh token
      if (e.toString().contains('401')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with new token
          final newToken = await _authTokenStorage.getToken();
          final apiService = ApiService(baseUrl: _baseUrl, authToken: newToken);

          return await _makeRequest(
            apiService,
            endpoint,
            method,
            body,
            queryParams: queryParams,
          );
        } else {
          // Refresh failed, throw the original error
          rethrow;
        }
      } else {
        // Other error, re-throw
        rethrow;
      }
    }
  }

  Future<dynamic> makeStandardRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      // First attempt with current token
      final apiService = ApiService(baseUrl: _baseUrl);

      final response = await _makeRequest(
        apiService,
        endpoint,
        method,
        body,
        queryParams: queryParams,
      );
      return response;
    } catch (e) {
      // If first attempt fails with 401, try to refresh token
      if (e.toString().contains('401')) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry with new token
          final apiService = ApiService(baseUrl: _baseUrl);

          return await _makeRequest(
            apiService,
            endpoint,
            method,
            body,
            queryParams: queryParams,
          );
        } else {
          // Refresh failed, throw the original error
          rethrow;
        }
      } else {
        // Other error, re-throw
        rethrow;
      }
    }
  }

  Future<dynamic> _makeRequest(
    ApiService apiService,
    String endpoint,
    String method,
    Map<String, dynamic>? body, {
    Map<String, String>? queryParams,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await apiService.get(endpoint, queryParams: queryParams);
      case 'POST':
        return await apiService.post(endpoint, body ?? {});
      case 'PATCH':
        return await apiService.patch(endpoint, body ?? {});
      case 'DELETE':
        return await apiService.delete(endpoint, body ?? {});
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      while (_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return await _authTokenStorage.getToken() != null;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _authTokenStorage.getRefreshToken();

      if (refreshToken == null) {
        _isRefreshing = false;
        return false;
      }

      final apiService = ApiService(baseUrl: _baseUrl);

      final response = await apiService.post('auth/refresh', {
        'refreshToken': refreshToken,
      });

      final newAccessToken = response['data']['accessToken'] as String?;

      if (newAccessToken != null) {
        await _authTokenStorage.saveToken(newAccessToken);
        _isRefreshing = false;
        return true;
      } else {
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      _isRefreshing = false;
      return false;
    }
  }
}
