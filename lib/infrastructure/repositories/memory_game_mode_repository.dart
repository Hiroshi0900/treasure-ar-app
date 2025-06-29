import 'dart:async';
import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/repositories/game_mode_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

/// メモリベースのゲームモードリポジトリ実装
class MemoryGameModeRepository implements GameModeRepository {
  GameMode? _currentMode;
  GameSettings? _adultSettings;
  final List<ModeChangeLog> _changeLogs = [];
  final List<ChildModeAttempt> _childAttempts = [];
  final StreamController<GameMode> _modeController = StreamController<GameMode>.broadcast();

  @override
  Future<GameMode?> getCurrentMode() async => _currentMode;

  @override
  Future<void> saveMode(GameMode mode) async {
    _currentMode = mode;
    _modeController.add(mode);
  }

  @override
  Future<void> saveAdultSettings(GameSettings settings) async {
    _adultSettings = settings;
  }

  @override
  Future<GameSettings?> getAdultSettings() async => _adultSettings;

  @override
  Future<GameMode> getLastUsedMode() async {
    return _currentMode ?? GameMode.adult();
  }

  @override
  Future<void> logModeChange({
    required GameMode fromMode,
    required GameMode toMode,
    required DateTime timestamp,
    String? reason,
  }) async {
    _changeLogs.add(
      ModeChangeLog(
        fromMode: fromMode,
        toMode: toMode,
        timestamp: timestamp,
        reason: reason,
      ),
    );
  }

  @override
  Future<void> logChildModeAttempt({
    required String attemptType,
    required DateTime timestamp,
  }) async {
    _childAttempts.add(
      ChildModeAttempt(attemptType: attemptType, timestamp: timestamp),
    );
  }

  @override
  Future<List<ChildModeAttempt>> getChildModeAttempts({
    Duration? period,
  }) async {
    if (period == null) return _childAttempts;

    final cutoffTime = DateTime.now().subtract(period);
    return _childAttempts
        .where((attempt) => attempt.timestamp.isAfter(cutoffTime))
        .toList();
  }

  @override
  Future<void> resetToDefaults() async {
    _currentMode = null;
    _adultSettings = null;
    _changeLogs.clear();
    _childAttempts.clear();
  }

  @override
  Stream<GameMode> get modeChanges => _modeController.stream;

  void dispose() {
    _modeController.close();
  }
}