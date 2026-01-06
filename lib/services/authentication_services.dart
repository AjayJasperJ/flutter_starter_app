import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter_starter_app/data/token_storage.dart';
import 'package:flutter_starter_app/network/api_services/api_client.dart';
import 'package:flutter_starter_app/core/constants/uri_manager.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';
import 'package:flutter_starter_app/network/api_services/api_response.dart';
import 'package:flutter_starter_app/models/api_response_model.dart';
import 'package:flutter_starter_app/screens/auth/model/authentication_models.dart';
import 'package:flutter_starter_app/screens/auth/model/login_model.dart';
import 'package:flutter_starter_app/screens/profile/model/change_password_model.dart';
import 'package:flutter_starter_app/screens/profile/model/profile_model.dart';

class AuthenticationServices {
  static Future<ApiResult<ProfileResponseModel>> getProfile({
    CancelToken? cancelToken,
    bool resetSingleFetch = false,
  }) async {
    final ApiClient client = ApiClient();
    final result = await client.get(
      UriManager.profile,
      withAuth: true,
      cancelToken: cancelToken,
      singleFetch: true,
      resetSingleFetch: resetSingleFetch,
      staleWhileRevalidate: false,
    );
    return result.when(
      success: (res) {
        try {
          ApiClient.authguard(res.statusCode);
          final data = ProfileResponseModel.fromJson(res.data);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            ApiError(message: "Data parsing failed", type: ApiErrorType.parsing),
          );
        }
      },
      failure: (error) => ApiResult.failure(error),
    );
  }

  static Future<ApiResult<LoginResponseModel>> login(
    LoginRequestModel userCredentials, {
    CancelToken? cancelToken,
  }) async {
    final ApiClient service = ApiClient();
    debugPrint(
      {
        'identifier': userCredentials.identifier.trim(),
        'password': userCredentials.password.trim(),
        'portal': userCredentials.protal,
      }.toString(),
    );

    final result = await service.post(
      UriManager.login,
      body: {
        'identifier': userCredentials.identifier.trim(),
        'password': userCredentials.password.trim(),
        'portal': userCredentials.protal,
        'device': 'app',
      },
      isOfflineSync: false,
      cancelToken: cancelToken,
      withAuth: false,
    );

    return result.when(
      success: (res) {
        try {
          ApiClient.authguard(res.statusCode);
          final data = LoginResponseModel.fromJson(res.data);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            ApiError(message: "Data parsing failed", type: ApiErrorType.parsing),
          );
        }
      },
      failure: (error) => ApiResult.failure(error),
    );
  }

  static Future<ApiResult<ApiResponseModel>> firstLoginPasswordUpdate(
    //configured
    UserUpdatePasswordRequest userCredentials, {
    CancelToken? cancelToken,
  }) async {
    final ApiClient service = ApiClient();
    final result = await service.post(
      UriManager.resetFirstLogin,
      body: {
        'identifier': userCredentials.identifier.trim(),
        'current_password': userCredentials.currentPassword.trim(),
        'new_password': userCredentials.newPassword.trim(),
        'confirm_password': userCredentials.confirmNewPassword.trim(),
      },
      withAuth: true,
      isOfflineSync: false,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (res) {
        try {
          ApiClient.authguard(res.statusCode);
          final data = returnModel(res.data);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            ApiError(message: "Data parsing failed", type: ApiErrorType.parsing),
          );
        }
      },
      failure: (error) => ApiResult.failure(error),
    );
  }

  static Future<ApiResult<ApiResponseModel>> changePassword(
    //configured
    ChangePasswordRequest credentials, {
    CancelToken? cancelToken,
  }) async {
    final ApiClient service = ApiClient();
    final result = await service.post(
      UriManager.changePassword,
      body: {
        'current_password': credentials.currentPassword.trim(),
        'new_password': credentials.newPassword.trim(),
        'confirm_password': credentials.confirmNewPassword.trim(),
      },
      withAuth: true,
      isOfflineSync: false,
      cancelToken: cancelToken,
    );
    return result.when(
      success: (res) {
        try {
          ApiClient.authguard(res.statusCode);
          final data = ApiResponseModel.fromJson(res.data);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            ApiError(message: "Data parsing failed", type: ApiErrorType.parsing),
          );
        }
      },
      failure: (error) => ApiResult.failure(error),
    );
  }

  static Future<ApiResult<LoginTokens>> postRefreshToken({CancelToken? cancelToken}) async {
    final ApiClient service = ApiClient();

    final refreshToken = await TokenStorage.getRefreshToken();

    final result = await service.post(
      UriManager.refreshToken,
      body: {'refresh_token': refreshToken, 'device': 'app'},
      isOfflineSync: false,
      cancelToken: cancelToken,
      withAuth: false,
      headers: {'Content-Type': 'application/json'},
    );

    return result.when(
      success: (res) {
        try {
          final data = LoginTokens.fromJson(res.data);
          TokenStorage.saveToken(data.accessToken, data.refreshToken);
          return ApiResult.success(data);
        } catch (e) {
          return ApiResult.failure(
            ApiError(message: "Data parsing failed", type: ApiErrorType.parsing),
          );
        }
      },
      failure: (error) {
        debugPrint(error.message.toString());
        return ApiResult.failure(error);
      },
    );
  }
}
