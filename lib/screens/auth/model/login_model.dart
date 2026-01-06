class LoginResponseModel {
  final String status;
  final String message;
  final LoginTokens tokens;
  final LoginData data;

  const LoginResponseModel({
    required this.status,
    required this.message,
    required this.tokens,
    required this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      tokens: json['tokens'] != null ? LoginTokens.fromJson(json['tokens']) : LoginTokens.empty,
      data: json['data'] != null ? LoginData.fromJson(json['data']) : LoginData.empty,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'tokens': tokens.toJson(),
    'data': data.toJson(),
  };

  static const LoginResponseModel empty = LoginResponseModel(
    status: '',
    message: '',
    tokens: LoginTokens.empty,
    data: LoginData.empty,
  );
}

class LoginTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const LoginTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory LoginTokens.fromJson(Map<String, dynamic> json) {
    return LoginTokens(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
  };

  static const LoginTokens empty = LoginTokens(accessToken: '', refreshToken: '', tokenType: '');
}

class LoginData {
  final String id;
  final String userId;
  final String email;

  const LoginData({required this.id, required this.userId, required this.email});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'user_id': userId, 'email': email};

  static const LoginData empty = LoginData(id: '', userId: '', email: '');
}

class LoginRequestModel {
  final String identifier;
  final String password;
  final String protal;

  const LoginRequestModel({required this.identifier, required this.password, required this.protal});
}
