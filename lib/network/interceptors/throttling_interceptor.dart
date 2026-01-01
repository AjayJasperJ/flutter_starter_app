import 'package:dio/dio.dart';
import '../../dev_tools/features/network_throttling/network_throttling_controller.dart';

class ThrottlingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final profile = NetworkThrottlingController().activeProfile.value;

    if (profile != ThrottlingProfile.none) {
      // Half latency on request
      await Future.delayed(Duration(milliseconds: profile.latencyMs ~/ 2));
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final profile = NetworkThrottlingController().activeProfile.value;

    if (profile != ThrottlingProfile.none) {
      // Half latency on response
      await Future.delayed(Duration(milliseconds: profile.latencyMs ~/ 2));
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final profile = NetworkThrottlingController().activeProfile.value;

    if (profile != ThrottlingProfile.none) {
      await Future.delayed(Duration(milliseconds: profile.latencyMs ~/ 2));
    }

    return handler.next(err);
  }
}
