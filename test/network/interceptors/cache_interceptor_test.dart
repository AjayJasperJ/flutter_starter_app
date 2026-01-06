import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/interceptors/cache_interceptor.dart';

class MockBox extends Mock implements Box {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

void main() {
  group('CacheInterceptor Tests', () {
    late CacheInterceptor cacheInterceptor;
    late MockBox mockBox;
    late MockRequestInterceptorHandler requestHandler;
    // late MockResponseInterceptorHandler responseHandler;

    setUp(() {
      mockBox = MockBox();
      cacheInterceptor = CacheInterceptor(mockBox);
      requestHandler = MockRequestInterceptorHandler();
      // responseHandler = MockResponseInterceptorHandler();
    });

    test('Should skip non-GET requests', () {
      final options = RequestOptions(path: '/post', method: 'POST');
      cacheInterceptor.onRequest(options, requestHandler);
      verify(() => requestHandler.next(options)).called(1);
      verifyZeroInteractions(mockBox);
    });

    // Testing network connectivity logic requires mocking ConnectivityService singleton or its platform channel.
    // We assume online -> next(options)
    // We assume offline -> check cache
  });
}
