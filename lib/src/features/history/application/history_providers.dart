import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';
import '../data/session_history_repository.dart';
import '../domain/session_history_entry.dart';

final sessionHistoryRepositoryProvider =
    FutureProvider<SessionHistoryRepository>((ref) async {
      final preferences = await ref.watch(sharedPreferencesProvider.future);
      return SharedPreferencesSessionHistoryRepository(preferences);
    });

final sessionHistoryControllerProvider =
    AsyncNotifierProvider<SessionHistoryController, List<SessionHistoryEntry>>(
      SessionHistoryController.new,
    );

class SessionHistoryController
    extends AsyncNotifier<List<SessionHistoryEntry>> {
  @override
  Future<List<SessionHistoryEntry>> build() async {
    return ref
        .watch(sessionHistoryRepositoryProvider.future)
        .then((repo) => repo.load());
  }

  Future<void> save(SessionHistoryEntry entry) async {
    final repo = await ref.read(sessionHistoryRepositoryProvider.future);
    await repo.save(entry);
    state = AsyncData(await repo.load());
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(sessionHistoryRepositoryProvider.future);
    await repo.delete(id);
    state = AsyncData(await repo.load());
  }

  Future<void> clear() async {
    final repo = await ref.read(sessionHistoryRepositoryProvider.future);
    await repo.clear();
    state = const AsyncData([]);
  }
}
