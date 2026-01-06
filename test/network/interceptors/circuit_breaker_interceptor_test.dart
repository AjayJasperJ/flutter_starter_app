import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/interceptors/circuit_breaker_interceptor.dart';
import 'package:flutter_starter_app/network/network_constants.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeDioException extends Fake implements DioException {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeRequestOptions());
  });

  group('CircuitBreakerInterceptor Tests', () {
    late CircuitBreakerInterceptor circuitBreaker;
    late MockRequestInterceptorHandler requestHandler;
    late MockErrorInterceptorHandler errorHandler;

    setUp(() {
      circuitBreaker = CircuitBreakerInterceptor();
      requestHandler = MockRequestInterceptorHandler();
      errorHandler = MockErrorInterceptorHandler();
    });

    test('Should allow requests when closed/fresh', () {
      final options = RequestOptions(path: '/test');
      circuitBreaker.onRequest(options, requestHandler);
      verify(() => requestHandler.next(options)).called(1);
    });

    test('Should open circuit after threshold failures', () {
      final options = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );

      // Simulate threshold failures
      for (int i = 0; i < NetworkConstants.circuitBreakerThreshold; i++) {
        circuitBreaker.onError(error, errorHandler);
      }

      // Next request should be blocked
      circuitBreaker.onRequest(options, requestHandler);

      // Using any() for DioException might be needed if reject takes DioException
      // Check reject signature: reject(DioException err, [bool completed = false])
      verify(() => requestHandler.reject(any(), any())).called(1);
    });

    test('Should fail client errors without increasing count', () {
      final options = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 400),
        type: DioExceptionType.badResponse,
      );

      circuitBreaker.onError(error, errorHandler);
      verify(() => errorHandler.next(error)).called(1);
    });
  });
}
