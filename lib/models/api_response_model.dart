import 'dart:convert';

class ApiResponseModel {
  final String status;
  final String message;
  final Errors errors;
  final String data;

  ApiResponseModel({
    required this.status,
    required this.message,
    required this.errors,
    required this.data,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      errors: json['errors'] != null
          ? Errors.fromJson(json['errors'])
          : Errors.empty(),
      data: json['data']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'errors': errors.toJson(),
    'data': data,
  };

  @override
  String toString() =>
      'ApiResponseModel(status: $status, message: $message, errors: $errors, data: $data)';
}

class Errors {
  final Map<String, dynamic> allErrors;

  Errors({required this.allErrors});

  factory Errors.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return Errors(allErrors: json);
    }
    return Errors.empty();
  }

  factory Errors.empty() => Errors(allErrors: {});

  Map<String, dynamic> toJson() => allErrors;

  @override
  String toString() {
    if (allErrors.isEmpty) return '';

    final List<String> messages = [];
    allErrors.forEach((key, value) {
      if (value is List) {
        messages.add(value.join(', '));
      } else {
        messages.add(value.toString());
      }
    });
    return messages.join('\n');
  }
}

ApiResponseModel returnModel(String jsondata) {
  final decoded = jsonDecode(jsondata);
  return ApiResponseModel.fromJson(decoded);
}
