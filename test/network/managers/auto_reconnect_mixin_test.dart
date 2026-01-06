import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_app/network/managers/auto_reconnect_mixin.dart';
import 'package:flutter_starter_app/network/api_services/state_response.dart';
import 'package:flutter_starter_app/network/api_services/api_error.dart';

class TestReconnectNotifier extends ChangeNotifier with AutoReconnectMixin {
  bool reconnected = false;
  bool _shouldRetry = true;

  @override
  void onReconnect() {
    reconnected = true;
  }

  @override
  bool get shouldRetry => _shouldRetry;

  void setShouldRetry(bool val) {
    _shouldRetry = val;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutoReconnectMixin Tests', () {
    late TestReconnectNotifier notifier;

    setUp(() {
      notifier = TestReconnectNotifier();
    });

    test('regularRetry checks state errors', () {
      expect(notifier.regularRetry(null, null), false);

      final errorState = StateResponse.failure(
        ApiError(message: "fail", type: ApiErrorType.unknown),
      );
      expect(notifier.regularRetry(errorState, null), true);
    });
  });
}
