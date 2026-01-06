import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:flutter_starter_app/dev_tools/features/network_throttling/network_throttling_controller.dart';
import 'package:flutter_starter_app/network/interceptors/throttling_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  setUpAll(() {
    final path = Directory.systemTemp.path;
    Hive.init(path);
  });

  group('ThrottlingInterceptor Tests', () {
    late ThrottlingInterceptor interceptor;
    late MockRequestInterceptorHandler requestHandler;

    setUp(() async {
      interceptor = ThrottlingInterceptor();
      requestHandler = MockRequestInterceptorHandler();
      await NetworkThrottlingController().init();
      await NetworkThrottlingController().setProfile(ThrottlingProfile.none);
    });

    test('Should proceed immediately if profile is none', () async {
      final options = RequestOptions(path: '/test');
      final stopwatch = Stopwatch()..start();

      // onRequest is void/async void. We just call it.
      interceptor.onRequest(options, requestHandler);

      await untilCalled(() => requestHandler.next(options));
      stopwatch.stop();

      verify(() => requestHandler.next(options)).called(1);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be instant
    });

    test('Should delay request if profile has latency', () async {
      await NetworkThrottlingController().setProfile(
        ThrottlingProfile.edge,
      ); // 500ms
      final options = RequestOptions(path: '/test');

      final stopwatch = Stopwatch()..start();
      interceptor.onRequest(options, requestHandler);

      await untilCalled(() => requestHandler.next(options));
      stopwatch.stop();

      verify(() => requestHandler.next(options)).called(1);
      // Half latency for request
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
    });
  });
}
