enum SessionFinalState { completed, failed, cancelled }

class SessionHistoryEntry {
  const SessionHistoryEntry({
    required this.id,
    required this.location,
    required this.startedAt,
    required this.endedAt,
    required this.finalState,
    this.sessionIdentifier,
  });

  factory SessionHistoryEntry.fromJson(Map<String, Object?> json) {
    return SessionHistoryEntry(
      id: json['id'] as String,
      location: json['location'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      finalState: SessionFinalState.values.firstWhere(
        (state) => state.name == json['finalState'],
        orElse: () => SessionFinalState.completed,
      ),
      sessionIdentifier: json['sessionIdentifier'] as String?,
    );
  }

  final String id;
  final String location;
  final DateTime startedAt;
  final DateTime endedAt;
  final SessionFinalState finalState;
  final String? sessionIdentifier;

  Duration get duration => endedAt.difference(startedAt);

  String get stateLabel {
    return switch (finalState) {
      SessionFinalState.completed => 'Completed',
      SessionFinalState.failed => 'Failed',
      SessionFinalState.cancelled => 'Cancelled',
    };
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'location': location,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'finalState': finalState.name,
      'sessionIdentifier': sessionIdentifier,
    };
  }
}
