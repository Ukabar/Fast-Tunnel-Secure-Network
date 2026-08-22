import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../history/application/history_providers.dart';
import '../../history/domain/session_history_entry.dart';
import '../../settings/application/settings_providers.dart';
import '../data/network_test_service.dart';
import '../domain/network_test_models.dart';

final networkTestServiceProvider = Provider<NetworkTestService>((ref) {
  return const NetworkTestService();
});

final networkTestControllerProvider =
    AsyncNotifierProvider<NetworkTestController, NetworkTestProgress>(
      NetworkTestController.new,
    );

class NetworkTestController extends AsyncNotifier<NetworkTestProgress> {
  var _operationToken = 0;

  @override
  Future<NetworkTestProgress> build() async {
    return const NetworkTestProgress.idle();
  }

  Future<void> start() async {
    final current = state.maybeWhen(data: (value) => value, orElse: () => null);
    if (current?.isRunning ?? false) return;

    final token = ++_operationToken;
    final settings = await ref.read(settingsControllerProvider.future);
    final service = ref.read(networkTestServiceProvider);

    try {
      state = const AsyncData(
        NetworkTestProgress(phase: NetworkTestPhase.preparing),
      );
      final result = await service.run(
        accuracy: settings.testAccuracy,
        isCancelled: () => token != _operationToken,
        onProgress: (progress) {
          if (token == _operationToken) state = AsyncData(progress);
        },
      );
      if (token != _operationToken) return;
      await ref
          .read(sessionHistoryControllerProvider.notifier)
          .save(SessionHistoryEntry.fromResult(result));
      if (token != _operationToken) return;
      if (kDebugMode) {
        debugPrint('[TEST] Network test result saved: ${result.id}');
      }
      state = AsyncData(
        NetworkTestProgress(
          phase: NetworkTestPhase.completed,
          result: result,
          message: 'Test completed',
        ),
      );
    } on NetworkTestCancelledException {
      if (token == _operationToken) {
        state = const AsyncData(
          NetworkTestProgress(
            phase: NetworkTestPhase.cancelled,
            message: 'Test cancelled',
          ),
        );
      }
    } on Object {
      if (token == _operationToken) {
        state = const AsyncData(
          NetworkTestProgress(
            phase: NetworkTestPhase.failed,
            message: 'The network test could not be completed.',
          ),
        );
      }
    }
  }

  void cancel() {
    _operationToken++;
    state = const AsyncData(
      NetworkTestProgress(
        phase: NetworkTestPhase.cancelled,
        message: 'Test cancelled',
      ),
    );
  }
}
