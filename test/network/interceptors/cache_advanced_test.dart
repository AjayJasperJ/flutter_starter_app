import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/interceptors/cache_interceptor.dart';
import 'package:flutter_starter_app/network/utils/connectivity_service.dart';

class MockBox extends Mock implements Box {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('CacheInterceptor Advanced Tests', () {
    late CacheInterceptor interceptor;
    late MockBox mockBox;
    late MockResponseInterceptorHandler responseHandler;
    late DateTime simulatedTime;

    setUp(() {
      mockBox = MockBox();
      responseHandler = MockResponseInterceptorHandler();
      simulatedTime = DateTime(2023, 1, 1);

      interceptor = CacheInterceptor(mockBox, clock: () => simulatedTime);
    });

    test('Should purge expired cache entries', () async {
      final key = 'https://api.test.com/expired';
      final expiredDate = simulatedTime.subtract(
        CacheInterceptor.maxCacheAge + const Duration(days: 1),
      );

      final expiredEntry = {
        'data': {'foo': 'bar'},
        'timestamp': expiredDate.toIso8601String(),
        'lastAccessed': expiredDate.toIso8601String(),
      };

      when(() => mockBox.isEmpty).thenReturn(false);
      when(() => mockBox.keys).thenReturn([key]);
      when(() => mockBox.get(key)).thenReturn(expiredEntry);

      // Mock deletion
      when(() => mockBox.deleteAll(any())).thenAnswer((_) async => {});

      await interceptor.pruneCache();

      verify(() => mockBox.deleteAll([key])).called(1);
    });

    test('Should perform LRU eviction when limit exceeded', () {
      // Setup box with Max Items + 1
      final currentSize = CacheInterceptor.maxItems + 1;
      when(() => mockBox.length).thenReturn(currentSize);

      final keys = List.generate(currentSize, (i) => 'key_$i');
      when(() => mockBox.keys).thenReturn(keys);

      // Mock access times
      // key_0 time = base (OLDEST)
      // key_1 time = base + 1 min
      for (int i = 0; i < currentSize; i++) {
        when(() => mockBox.get('key_$i')).thenReturn({
          'lastAccessed': simulatedTime
              .add(Duration(minutes: i))
              .toIso8601String(),
        });
      }

      // Mock deletion
      when(() => mockBox.deleteAll(any())).thenAnswer((_) async => {});

      // Mock put for the new response we are saving
      when(() => mockBox.put(any(), any())).thenAnswer((_) async => {});

      final response = Response(
        requestOptions: RequestOptions(path: '/new'),
        statusCode: 200,
      );

      // Trigger Response which calls _performLRU
      interceptor.onResponse(response, responseHandler);

      // Verify eviction of key_0 (the oldest)
      // The code sorts by lastAccessed ASCENDING.
      // key_0 is oldest.
      // It takes keysToRemove = sortedKeys.take(length - max).
      // length = max + 1. So it takes 1 item.
      // verify deleteAll called with ['key_0']
      verify(() => mockBox.deleteAll(['key_0'])).called(1);
    });
  });
}
