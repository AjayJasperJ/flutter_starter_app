import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';
import 'package:flutter_starter_app/network/api_services/api_response.dart';

void main() {
  group('ApiResult Tests', () {
    test('ApiResult.success should hold data and denote success', () {
      final result = ApiResult.success('Test Data');
      expect(result.isSuccess, true);
      expect(result.data, 'Test Data');
      expect(result.error, null);
    });

    test('ApiResult.failure should hold error and denote failure', () {
      final error = ApiError(message: 'Fail', type: ApiErrorType.unknown);
      final result = ApiResult.failure(error);
      expect(result.isSuccess, false);
      expect(result.data, null);
      expect(result.error, error);
    });

    test('when() should execute success callback for success result', () {
      final result = ApiResult.success(42);
      final output = result.when(
        success: (data) => 'Success: $data',
        failure: (error) => 'Error',
      );
      expect(output, 'Success: 42');
    });

    test('when() should execute failure callback for failure result', () {
      final result = ApiResult.failure(
        ApiError(message: 'Oops', type: ApiErrorType.server),
      );
      final output = result.when(
        success: (data) => 'Success',
        failure: (error) => 'Failure: ${error.message}',
      );
      expect(output, 'Failure: Oops');
    });

    test('maybeWhen() should use orElse when not matching', () {
      final result = ApiResult.success('Ok');
      final output = result.maybeWhen(
        failure: (e) => 'Fail',
        orElse: () => 'Default',
      );
      expect(output, 'Default');
    });

    test('returnableError should identify basic error codes', () {
      expect(
        returnableError(
          ApiError(message: '', type: ApiErrorType.badRequest, code: 400),
        ),
        true,
      );
      expect(
        returnableError(
          ApiError(message: '', type: ApiErrorType.unauthorized, code: 401),
        ),
        true,
      );
      expect(
        returnableError(
          ApiError(message: '', type: ApiErrorType.server, code: 500),
        ),
        true,
      );
      expect(
        returnableError(
          ApiError(message: '', type: ApiErrorType.notFound, code: 404),
        ),
        false,
      ); // 404 is not in the explicit list in api_response.dart
    });
  });
}
