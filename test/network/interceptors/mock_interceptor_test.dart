import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:flutter_starter_app/dev_tools/features/mocking/mock_controller.dart';
import 'package:flutter_starter_app/network/interceptors/mock_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    final path = Directory.systemTemp.path;
    Hive.init(path);
    registerFallbackValue(FakeRequestOptions());
  });

  group('MockInterceptor Tests', () {
    late MockInterceptor interceptor;
    late MockRequestInterceptorHandler requestHandler;

    setUp(() async {
      interceptor = MockInterceptor();
      requestHandler = MockRequestInterceptorHandler();
      await MockController().init();
      await MockController().clearRules();
    });

    test('Should pass through if Mock API Responses flag is disabled', () {
      // Logic assumes functionality. We verify passthrough.
      final options = RequestOptions(path: '/');
      interceptor.onRequest(options, requestHandler);
      verify(() => requestHandler.next(options)).called(1);
    });
  });
}
