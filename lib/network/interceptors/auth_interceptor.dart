import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// External dependency
// Internal imports
import '../../../services/authentication_services.dart';
import '../../data/token_storage.dart';
import '../api_services/api_client.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;

  AuthInterceptor({required this.dio});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool withAuth = options.extra['withAuth'] ?? true;

    if (withAuth) {
      try {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final bool withAuth = err.requestOptions.extra['withAuth'] ?? true;

    if (err.response?.statusCode == 401 && withAuth) {
      try {
        debugPrint(
          "[AuthInterceptor] 401 Detected on ${err.requestOptions.path}. Attempting refresh...",
        );
        final result = await AuthenticationServices.postRefreshToken();

        return result.when(
          success: (tokens) async {
            debugPrint(
              "[AuthInterceptor] Refresh successful. Retrying original request...",
            );
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

            final clonedRequest = await dio.request(
              options.path,
              options: Options(
                method: options.method,
                headers: options.headers,
                extra: options.extra,
                contentType: options.contentType,
                responseType: options.responseType,
              ),
              data: options.data,
              queryParameters: options.queryParameters,
            );

            return handler.resolve(clonedRequest);
          },
          failure: (error) async {
            debugPrint(
              "[AuthInterceptor] Refresh failed: ${error.message}. Triggering logout.",
            );
            await ApiClient.authguard(401);
            return handler.next(err);
          },
        );
      } catch (e) {
        debugPrint(
          "[AuthInterceptor] Exception during refresh: $e. Triggering logout.",
        );
        await ApiClient.authguard(401);
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
