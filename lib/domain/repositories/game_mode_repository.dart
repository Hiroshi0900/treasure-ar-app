import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

/// ゲームモードの永続化と管理を担当するリポジトリインターフェース
abstract class GameModeRepository {
  /// 現在のゲームモードを取得
  Future<GameMode?> getCurrentMode();

  /// ゲームモードを保存
  Future<void> saveMode(GameMode mode);

  /// 大人モードの設定を保存（子供モード復帰時に使用）
  Future<void> saveAdultSettings(GameSettings settings);

  /// 保存されている大人モードの設定を取得
  Future<GameSettings?> getAdultSettings();

  /// 最後に使用したモードを取得（アプリ起動時の初期状態用）
  Future<GameMode> getLastUsedMode();

  /// ゲームモードの変更履歴を記録（デバッグ・分析用）
  Future<void> logModeChange({
    required GameMode fromMode,
    required GameMode toMode,
    required DateTime timestamp,
    String? reason,
  });

  /// 子供モードでの操作試行回数を記録（安全性分析用）
  Future<void> logChildModeAttempt({
    required String attemptType, // 'settings', 'mode_switch', 'reset' etc.
    required DateTime timestamp,
  });

  /// 子供モードでの操作試行履歴を取得
  Future<List<ChildModeAttempt>> getChildModeAttempts({
    Duration? period, // 指定期間内の履歴取得
  });

  /// 設定をリセット（デフォルト状態に戻す）
  Future<void> resetToDefaults();

  /// ゲームモードの設定変更をストリームで監視
  Stream<GameMode> get modeChanges;
}

/// 子供モードでの操作試行記録
class ChildModeAttempt {
  final String attemptType;
  final DateTime timestamp;
  final String? additionalInfo;

  const ChildModeAttempt({
    required this.attemptType,
    required this.timestamp,
    this.additionalInfo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildModeAttempt &&
          other.attemptType == attemptType &&
          other.timestamp == timestamp &&
          other.additionalInfo == additionalInfo;

  @override
  int get hashCode => Object.hash(attemptType, timestamp, additionalInfo);

  @override
  String toString() =>
      'ChildModeAttempt('
      'type: $attemptType, '
      'time: $timestamp, '
      'info: $additionalInfo)';
}

/// ゲームモード変更記録
class ModeChangeLog {
  final GameMode fromMode;
  final GameMode toMode;
  final DateTime timestamp;
  final String? reason;

  const ModeChangeLog({
    required this.fromMode,
    required this.toMode,
    required this.timestamp,
    this.reason,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModeChangeLog &&
          other.fromMode == fromMode &&
          other.toMode == toMode &&
          other.timestamp == timestamp &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(fromMode, toMode, timestamp, reason);

  @override
  String toString() =>
      'ModeChangeLog('
      'from: ${fromMode.runtimeType}, '
      'to: ${toMode.runtimeType}, '
      'time: $timestamp, '
      'reason: $reason)';
}
