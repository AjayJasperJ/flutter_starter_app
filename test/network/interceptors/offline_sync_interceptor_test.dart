import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/interceptors/offline_sync_interceptor.dart';
import 'package:flutter_starter_app/network/services/background_sync_service.dart';

class MockDio extends Mock implements Dio {}

class MockBox extends Mock implements Box {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response {}

class MockBackgroundSyncService extends Mock implements BackgroundSyncService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
  });

  group('OfflineSyncInterceptor Tests', () {
    late OfflineSyncInterceptor interceptor;
    late MockDio mockDio;
    late MockBox mockBox;
    late MockErrorInterceptorHandler errorHandler;
    late MockBackgroundSyncService mockSyncService;

    setUp(() {
      mockDio = MockDio();
      mockBox = MockBox();
      interceptor = OfflineSyncInterceptor(dio: mockDio, queueBox: mockBox);
      errorHandler = MockErrorInterceptorHandler();
      mockSyncService = MockBackgroundSyncService();

      BackgroundSyncService.mockInstance = mockSyncService;
    });

    tearDown(() {
      BackgroundSyncService.mockInstance = null;
    });

    test('Should queue POST request on network error', () async {
      final options = RequestOptions(path: '/submit', method: 'POST');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );

      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.add(any())).thenAnswer((_) async => 0);

      // Mock scheduleSyncTask to do nothing (or verify it called)
      // scheduleSyncTask returns void
      // We don't need to stub void methods in mocktail if we don't verify or if they are loose?
      // Strict mocks require stubbing. Assuming default loose behavior for unit tests?
      // Mocktail mocks are strict by default? No, they return null for nullable, but throw for non-nullable return types.
      // Void methods return null effectively?
      // Actually mocktail void methods don't need stubbing unless verification fails.

      interceptor.onError(error, errorHandler);

      await untilCalled(() => errorHandler.resolve(any()));

      verify(() => mockBox.add(any())).called(1);
      verify(() => errorHandler.resolve(any())).called(1);
      verify(() => mockSyncService.scheduleSyncTask()).called(1);
    });
  });
}
