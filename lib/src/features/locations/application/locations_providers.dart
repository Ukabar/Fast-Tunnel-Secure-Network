import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planned_locations_repository.dart';
import '../domain/planned_location.dart';

final plannedLocationsRepositoryProvider = Provider<PlannedLocationsRepository>(
  (ref) {
    return const StaticPlannedLocationsRepository();
  },
);

final plannedLocationsProvider = Provider<List<PlannedLocation>>((ref) {
  return ref.watch(plannedLocationsRepositoryProvider).list();
});
