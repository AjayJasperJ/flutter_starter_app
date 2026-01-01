import 'package:dio/dio.dart';

class PerformanceInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _checkPerformance(response, response.requestOptions, response.statusCode);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _checkPerformance(err.response, err.requestOptions, err.response?.statusCode);
    super.onError(err, handler);
  }

  void _checkPerformance(Response? response, RequestOptions options, int? statusCode) {
    // Logging disabled to reduce console noise
  }
}
