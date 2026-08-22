// Future-only tunnel abstraction.
//
// This file is intentionally not wired into the current production navigation.
// Version 1.0 uses user-triggered network diagnostics only and does not expose
// simulated tunnel states in the normal app flow.

import 'dart:async';
import 'dart:math';

import '../../locations/domain/planned_location.dart';

enum TunnelStatus {
  idle,
  preparing,
  connecting,
  connected,
  disconnecting,
  disconnected,
  cancelled,
  failed,
}

class TunnelReadiness {
  const TunnelReadiness({required this.status, required this.message});

  final TunnelStatus status;
  final String message;
}

class TunnelSession {
  const TunnelSession({
    required this.id,
    required this.startedAt,
    required this.locationId,
    required this.country,
    required this.city,
    required this.qualityLabel,
  });

  final String id;
  final DateTime startedAt;
  final String locationId;
  final String country;
  final String city;
  final String qualityLabel;
}

class TunnelState {
  const TunnelState({
    required this.status,
    required this.message,
    required this.prepareDelay,
    required this.connectDelay,
    required this.disconnectDelay,
    required this.failureSimulationEnabled,
    required this.randomFailuresEnabled,
    this.session,
    this.lastError,
  });

  factory TunnelState.initial() {
    return const TunnelState(
      status: TunnelStatus.idle,
      message: 'Choose a location and start a session.',
      prepareDelay: Duration(seconds: 1),
      connectDelay: Duration(seconds: 2),
      disconnectDelay: Duration(seconds: 1),
      failureSimulationEnabled: false,
      randomFailuresEnabled: false,
    );
  }

  final TunnelStatus status;
  final String message;
  final Duration prepareDelay;
  final Duration connectDelay;
  final Duration disconnectDelay;
  final bool failureSimulationEnabled;
  final bool randomFailuresEnabled;
  final TunnelSession? session;
  final String? lastError;

  bool get isBusy =>
      status == TunnelStatus.preparing ||
      status == TunnelStatus.connecting ||
      status == TunnelStatus.disconnecting;

  bool get canCancel =>
      status == TunnelStatus.preparing || status == TunnelStatus.connecting;

  bool get hasDemoSession =>
      status == TunnelStatus.connected && session != null;

  String get displayStatus {
    return switch (status) {
      TunnelStatus.idle => 'Not Connected',
      TunnelStatus.preparing => 'Preparing',
      TunnelStatus.connecting => 'Connecting',
      TunnelStatus.connected => 'Session Active',
      TunnelStatus.disconnecting => 'Disconnecting',
      TunnelStatus.disconnected => 'Not Connected',
      TunnelStatus.cancelled => 'Connection Cancelled',
      TunnelStatus.failed => 'Connection Failed',
    };
  }

  TunnelState copyWith({
    TunnelStatus? status,
    String? message,
    Duration? prepareDelay,
    Duration? connectDelay,
    Duration? disconnectDelay,
    bool? failureSimulationEnabled,
    bool? randomFailuresEnabled,
    TunnelSession? session,
    bool clearSession = false,
    String? lastError,
    bool clearError = false,
  }) {
    return TunnelState(
      status: status ?? this.status,
      message: message ?? this.message,
      prepareDelay: prepareDelay ?? this.prepareDelay,
      connectDelay: connectDelay ?? this.connectDelay,
      disconnectDelay: disconnectDelay ?? this.disconnectDelay,
      failureSimulationEnabled:
          failureSimulationEnabled ?? this.failureSimulationEnabled,
      randomFailuresEnabled:
          randomFailuresEnabled ?? this.randomFailuresEnabled,
      session: clearSession ? null : session ?? this.session,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

abstract interface class TunnelService {
  TunnelState get current;

  Stream<TunnelState> watch();

  Future<TunnelReadiness> readiness();

  Future<void> connect(PlannedLocation location);

  Future<void> disconnect();

  Future<void> cancel();

  Future<void> retry(PlannedLocation location);

  Future<void> setFailureSimulationEnabled(bool enabled);

  Future<void> setRandomFailuresEnabled(bool enabled);

  Future<void> setDelays({
    Duration? prepareDelay,
    Duration? connectDelay,
    Duration? disconnectDelay,
  });

  Future<void> reset();
}

class MockTunnelService implements TunnelService {
  MockTunnelService({Random? random}) : _random = random ?? Random();

  final Random _random;
  final _controller = StreamController<TunnelState>.broadcast();
  var _state = TunnelState.initial();
  var _operationToken = 0;

  @override
  TunnelState get current => _state;

  @override
  Stream<TunnelState> watch() async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<TunnelReadiness> readiness() async {
    return TunnelReadiness(status: _state.status, message: _state.message);
  }

  @override
  Future<void> connect(PlannedLocation location) async {
    if (_state.hasDemoSession || _state.isBusy) {
      return;
    }

    final token = ++_operationToken;
    _emit(
      _state.copyWith(
        status: TunnelStatus.preparing,
        message: 'Preparing your selected location.',
        clearSession: true,
        clearError: true,
      ),
    );
    await _delay(_state.prepareDelay);
    if (token != _operationToken) return;

    if (_shouldFail()) {
      _fail('Connection failed during preparation.');
      return;
    }

    _emit(
      _state.copyWith(
        status: TunnelStatus.connecting,
        message: 'Connecting to ${location.city}, ${location.country}.',
      ),
    );
    await _delay(_state.connectDelay);
    if (token != _operationToken) return;

    if (_shouldFail()) {
      _fail('Connection failed while starting the session.');
      return;
    }

    final startedAt = DateTime.now();
    _emit(
      _state.copyWith(
        status: TunnelStatus.connected,
        message: 'Connected to ${location.city}, ${location.country}.',
        session: TunnelSession(
          id: _sessionId(startedAt),
          startedAt: startedAt,
          locationId: location.id,
          country: location.country,
          city: location.city,
          qualityLabel: _qualityLabel(),
        ),
        clearError: true,
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    if (!_state.hasDemoSession || _state.status == TunnelStatus.disconnecting) {
      return;
    }
    final token = ++_operationToken;
    _emit(
      _state.copyWith(
        status: TunnelStatus.disconnecting,
        message: 'Disconnecting from ${_state.session?.city ?? 'location'}.',
      ),
    );
    await _delay(_state.disconnectDelay);
    if (token != _operationToken) return;

    _emit(
      _state.copyWith(
        status: TunnelStatus.disconnected,
        message: 'Choose a location and start a session.',
        clearSession: true,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    if (!_state.canCancel) {
      return;
    }
    _operationToken++;
    _emit(
      _state.copyWith(
        status: TunnelStatus.cancelled,
        message: 'Connection flow cancelled.',
        clearSession: true,
      ),
    );
  }

  @override
  Future<void> retry(PlannedLocation location) async {
    if (_state.status != TunnelStatus.failed &&
        _state.status != TunnelStatus.cancelled &&
        _state.status != TunnelStatus.disconnected) {
      return;
    }
    await connect(location);
  }

  @override
  Future<void> setFailureSimulationEnabled(bool enabled) async {
    _emit(_state.copyWith(failureSimulationEnabled: enabled));
  }

  @override
  Future<void> setRandomFailuresEnabled(bool enabled) async {
    _emit(_state.copyWith(randomFailuresEnabled: enabled));
  }

  @override
  Future<void> setDelays({
    Duration? prepareDelay,
    Duration? connectDelay,
    Duration? disconnectDelay,
  }) async {
    _emit(
      _state.copyWith(
        prepareDelay: prepareDelay,
        connectDelay: connectDelay,
        disconnectDelay: disconnectDelay,
      ),
    );
  }

  @override
  Future<void> reset() async {
    _operationToken++;
    _emit(TunnelState.initial());
  }

  void _fail(String message) {
    _operationToken++;
    _emit(
      _state.copyWith(
        status: TunnelStatus.failed,
        message: message,
        lastError: message,
        clearSession: true,
      ),
    );
  }

  bool _shouldFail() {
    if (_state.failureSimulationEnabled) {
      return true;
    }
    return _state.randomFailuresEnabled && _random.nextInt(100) < 25;
  }

  String _qualityLabel() {
    return switch (_random.nextInt(3)) {
      0 => 'Excellent',
      1 => 'Good',
      _ => 'Variable',
    };
  }

  String _sessionId(DateTime startedAt) {
    return 'FT-${startedAt.millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
  }

  Future<void> _delay(Duration duration) {
    if (duration == Duration.zero) {
      return Future<void>.value();
    }
    return Future<void>.delayed(duration);
  }

  void _emit(TunnelState state) {
    _state = state;
    _controller.add(_state);
  }
}
