import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';

void main() {
  group('ApiError Tests', () {
    test(
      'Should detect network error from DioExceptionType.connectionError',
      () {
        final dioError = DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        );
        final apiError = ErrorHandler.handle(dioError);
        expect(apiError.type, ApiErrorType.network);
        expect(apiError.message, contains('No internet connection'));
      },
    );

    test('Should detect timeout error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      final apiError = ErrorHandler.handle(dioError);
      expect(apiError.type, ApiErrorType.timeout);
      expect(apiError.message, contains('Request timed out'));
    });

    test('Should handle Bad Request (400) from response', () {
      final response = Response(
        requestOptions: RequestOptions(),
        statusCode: 400,
        data: {'message': 'Invalid input'},
      );
      final dioError = DioException(
        requestOptions: RequestOptions(),
        response: response,
        type: DioExceptionType.badResponse,
      );
      final apiError = ErrorHandler.handle(dioError);
      expect(apiError.type, ApiErrorType.badRequest);
      expect(apiError.message, 'Invalid input');
    });

    test(
      'Should fallback to status message if no server message is provided',
      () {
        final response = Response(
          requestOptions: RequestOptions(),
          statusCode: 500,
          data: {},
        );
        final dioError = DioException(
          requestOptions: RequestOptions(),
          response: response,
          type: DioExceptionType.badResponse,
        );
        final apiError = ErrorHandler.handle(dioError);
        expect(apiError.type, ApiErrorType.server);
        expect(apiError.message, 'Internal Server Error');
      },
    );

    test('Should handle structured legacy errors (ApiResponseModel)', () {
      final response = Response(
        requestOptions: RequestOptions(),
        statusCode: 400,
        data: {
          'status': 'error',
          'message': 'Structured Error',
          'errors': {'email': 'Invalid email'},
          'data': '',
        },
      );
      final apiError = ErrorHandler.parseResponse(response);
      expect(apiError.message, 'Structured Error');
      expect(apiError.response?.errors.toString(), 'Invalid email');
    });

    test('Should handle SocketException as Network Error', () {
      final dioError = DioException(
        requestOptions: RequestOptions(),
        error: const SocketException('No internet'),
        type: DioExceptionType.unknown,
      );
      final apiError = ErrorHandler.handle(dioError);
      expect(apiError.type, ApiErrorType.network);
    });
  });
}
