import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../dev_tools/features/mocking/mock_controller.dart';
import '../../dev_tools/features/feature_flags/feature_flag_controller.dart';

class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Check if global mocking flag is enabled
    if (!FeatureFlagController().isEnabled('Mock API Responses')) {
      return handler.next(options);
    }

    // 2. Search for a matching enabled rule
    final rules = MockController().rules.value;
    final matchingRule = rules.firstWhere(
      (rule) {
        if (!rule.isEnabled) return false;

        // Match method
        if (rule.method != 'ANY' && rule.method != options.method) {
          return false;
        }

        // Match path/pattern
        final path = options.path;
        bool pathMatches = false;
        if (rule.useRegex) {
          try {
            pathMatches = RegExp(rule.pathPattern).hasMatch(path);
          } catch (e) {
            debugPrint('[MockInterceptor] Invalid Regex Pattern: ${rule.pathPattern}');
          }
        } else {
          pathMatches = path == rule.pathPattern || path.startsWith(rule.pathPattern);
        }

        if (!pathMatches) return false;

        // Match Request Body (Optional)
        if (rule.requestBodyPattern.isNotEmpty) {
          final body = options.data?.toString() ?? '';
          if (rule.useRegex) {
            try {
              if (!RegExp(rule.requestBodyPattern).hasMatch(body)) {
                return false;
              }
            } catch (e) {
              debugPrint('[MockInterceptor] Invalid Body Regex: ${rule.requestBodyPattern}');
              return false;
            }
          } else {
            if (!body.contains(rule.requestBodyPattern)) {
              return false;
            }
          }
        }

        return true;
      },
      orElse: () =>
          MockRule(id: '', pathPattern: '', method: '', responseBody: '', isEnabled: false),
    );

    if (matchingRule.id.isNotEmpty) {
      debugPrint(
        '[MockInterceptor] MOCK MATCH FOUND: ${matchingRule.pathPattern} -> ${matchingRule.statusCode}',
      );

      return handler.resolve(
        Response(
          requestOptions: options,
          data: matchingRule.responseBody,
          statusCode: matchingRule.statusCode,
          statusMessage: 'OK (MOCKED)',
          extra: Map.from(options.extra)..['isMocked'] = true,
        ),
      );
    }

    return handler.next(options);
  }
}
