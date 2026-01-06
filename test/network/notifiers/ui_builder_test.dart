import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';
import 'package:flutter_starter_app/network/api_services/state_response.dart';
import 'package:flutter_starter_app/network/notifiers/ui_builder.dart';

void main() {
  group('UiBuilder Widget Tests', () {
    testWidgets('Shows loading widget when state is loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UiBuilder<String>(
            response: StateResponse.loading(),
            onSuccess: (data) => const Text('Success'),
            onLoading: () => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('Shows success widget with data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UiBuilder<String>(
            response: StateResponse.success('Hello'),
            onSuccess: (data) => Text('Success: $data'),
          ),
        ),
      );

      expect(find.text('Success: Hello'), findsOneWidget);
    });

    testWidgets('Shows default failure widget when onFailure is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UiBuilder<String>(
            response: StateResponse.failure(
              ApiError(
                message: 'Something went wrong',
                type: ApiErrorType.unknown,
              ),
            ),
            onSuccess: (_) => const SizedBox(),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.byType(ElevatedButton),
        findsNothing,
      ); // No retry button by default unless onRetry passed
    });

    testWidgets('Shows retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: UiBuilder<String>(
            response: StateResponse.failure(
              ApiError(message: 'Fail', type: ApiErrorType.unknown),
            ),
            onSuccess: (_) => const SizedBox(),
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('Shows refreshing state (overlay)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UiBuilder<String>(
            response: StateResponse.refreshing('Old Data'),
            onSuccess: (data) => Text('Data: $data'),
          ),
        ),
      );

      expect(find.text('Data: Old Data'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
