import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/interceptors/auth_interceptor.dart';

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Channel for FlutterSecureStorage
  const String channelName = 'plugins.it_nomads.com/flutter_secure_storage';
  const MethodChannel channel = MethodChannel(channelName);

  group('AuthInterceptor Tests', () {
    late AuthInterceptor authInterceptor;
    late MockDio mockDio;
    late MockRequestInterceptorHandler requestHandler;

    setUp(() {
      mockDio = MockDio();
      authInterceptor = AuthInterceptor(dio: mockDio);
      requestHandler = MockRequestInterceptorHandler();

      // Reset mock storage using correct API
      // TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      // .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'fake_token'; // Always return a token
        }
        return null;
      });
    });

    tearDown(() {
      channel.setMockMethodCallHandler(null);
    });

    test('Should add Authorization header when token exists', () async {
      final options = RequestOptions(path: '/test');

      // We need to await the handler call because TokenStorage is async
      await authInterceptor.onRequest(options, requestHandler);

      verify(() => requestHandler.next(options)).called(1);
      expect(options.headers['Authorization'], 'Bearer fake_token');
    });

    test('Should NOT add Authorization header if withAuth is false', () async {
      final options = RequestOptions(path: '/test', extra: {'withAuth': false});

      await authInterceptor.onRequest(options, requestHandler);

      verify(() => requestHandler.next(options)).called(1);
      expect(options.headers['Authorization'], isNull);
    });
  });
}
