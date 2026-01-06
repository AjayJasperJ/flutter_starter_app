import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';
import 'package:flutter_starter_app/network/api_services/state_response.dart';
import 'package:flutter_starter_app/network/notifiers/update_notifier.dart';

void main() {
  group('updateNotifier Tests', () {
    testWidgets('Triggers onSuccess callback', (tester) async {
      bool successCalled = false;
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));

      await updateNotifier<String>(
        context,
        response: StateResponse.success('Yay'),
        onSuccess: (data) async {
          successCalled = true;
          expect(data, 'Yay');
        },
      );

      expect(successCalled, true);
    });

    testWidgets('Triggers onFailure callback', (tester) async {
      bool failureCalled = false;
      await tester.pumpWidget(Container());
      final context = tester.element(find.byType(Container));

      await updateNotifier<String>(
        context,
        response: StateResponse.failure(
          ApiError(message: 'Nay', type: ApiErrorType.unknown),
        ),
        onFailure: (error) async {
          failureCalled = true;
          expect(error.message, 'Nay');
        },
      );

      expect(failureCalled, true);
    });
  });
}
