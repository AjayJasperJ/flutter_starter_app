import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/api_services/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late ApiClient apiClient;

  setUpAll(() {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  setUp(() {
    mockDio = MockDio();
    when(
      () => mockDio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://api.test.com/'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());

    // Create fresh instance for every test
    apiClient = ApiClient.test(dio: mockDio);
  });

  test('Concurrent requests to same endpoint should be deduplicated', () async {
    final response = Response(
      requestOptions: RequestOptions(path: '/dedup'),
      data: {'key': 'value'},
      statusCode: 200,
    );

    // Simulate network delay
    when(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
      ),
    ).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return response;
    });

    final future1 = apiClient.get('/dedup');
    final future2 = apiClient.get('/dedup');

    final results = await Future.wait([future1, future2]);

    expect(results[0].isSuccess, true);
    expect(results[1].isSuccess, true);

    // Verify Dio was called EXACTLY ONCE
    verify(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
      ),
    ).called(1);
  });

  test('Sequential requests should NOT be deduplicated', () async {
    final response = Response(
      requestOptions: RequestOptions(path: '/seq'),
      data: {'key': 'value'},
      statusCode: 200,
    );

    when(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
      ),
    ).thenAnswer((_) async => response);

    await apiClient.get('/seq');
    await apiClient.get('/seq');

    verify(
      () => mockDio.get(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        onReceiveProgress: any(named: 'onReceiveProgress'),
      ),
    ).called(2);
  });
}
