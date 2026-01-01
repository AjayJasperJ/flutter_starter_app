import 'package:dio/dio.dart';
import '../utils/logger_services.dart';

class LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Optional: Log request initiation if needed, but response/error tells the story.
    // Keeping it clean for now, or could log 'Request Started'.
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await LoggerService.logApi(
      '[${response.requestOptions.method}] ${response.requestOptions.path}',
      success: true,
      statusCode: response.statusCode,
      response: response.data,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    await LoggerService.logApi(
      '[${err.requestOptions.method}] ${err.requestOptions.path}',
      success: false,
      statusCode: err.response?.statusCode,
      response: err.message, // Capture error message
    );
    super.onError(err, handler);
  }
}
