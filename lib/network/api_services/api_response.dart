import 'api_error.dart';

bool returnableError(ApiError error) {
  return error.code != null &&
      (error.code == 400 || error.code == 401 || error.code == 500 || error.code == 403);
}

class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final bool isSuccess;

  ApiResult.success(this.data) : error = null, isSuccess = true;

  ApiResult.failure(this.error) : data = null, isSuccess = false;

  /// `when()` lets you handle success or failure elegantly
  R when<R>({required R Function(T data) success, required R Function(ApiError error) failure}) {
    if (isSuccess && data != null) {
      return success(data as T);
    } else {
      return failure(error!);
    }
  }

  /// Optional: `maybeWhen` allows partial handling
  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(ApiError error)? failure,
    required R Function() orElse,
  }) {
    if (isSuccess && data != null && success != null) {
      return success(data as T);
    } else if (!isSuccess && error != null && failure != null) {
      return failure(error!);
    } else {
      return orElse();
    }
  }
}
