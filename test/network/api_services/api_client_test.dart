import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_starter_app/network/api_services/api_client.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDio mockDio;
  late ApiClient apiClient;

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  setUp(() {
    mockDio = MockDio();

    when(
      () => mockDio.options,
    ).thenReturn(BaseOptions(baseUrl: 'https://api.test.com/'));
    when(() => mockDio.interceptors).thenReturn(Interceptors());

    apiClient = ApiClient.test(dio: mockDio);
  });

  group('ApiClient Tests', () {
    test('GET request returns success', () async {
      // Use Map directly. ApiClient handles Map or String.
      // In test env, passing String fails in Isolate parsing sometimes.
      final mockData = {'id': 1, 'name': 'Test'};
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: mockData,
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

      final result = await apiClient.get('/test');

      expect(result.isSuccess, true);
      expect(result.data?.data, isA<Map>());
      expect(result.data?.data['name'], 'Test');
    });

    test('GET request handles errors', () async {
      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/error'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/error'),
            statusCode: 404,
            data: 'Not Found',
          ),
        ),
      );

      final result = await apiClient.get('/error');

      expect(result.isSuccess, false);
      expect(result.error?.type, ApiErrorType.notFound);
    });

    test('POST request sends data and returns success', () async {
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/post'),
        data: {'status': 'ok'},
        statusCode: 201,
      );

      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await apiClient.post('/post', body: {'key': 'value'});

      expect(result.isSuccess, true);
      expect(result.data?.statusCode, 201);
    });

    test('PUT request sends data and returns success', () async {
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/put'),
        data: {'updated': true},
        statusCode: 200,
      );

      when(
        () => mockDio.put(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await apiClient.put('/put', body: {'id': 1});

      expect(result.isSuccess, true);
    });

    test('DELETE request returns success', () async {
      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/delete'),
        data: {}, // Map empty
        statusCode: 200,
      );

      when(
        () => mockDio.delete(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final result = await apiClient.delete('/delete');

      expect(result.isSuccess, true);
    });
  });
}
