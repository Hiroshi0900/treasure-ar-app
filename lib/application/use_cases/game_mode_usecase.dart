import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/repositories/game_mode_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

/// ゲームモード管理のユースケース
class GameModeUseCase {
  final GameModeRepository _repository;

  GameModeUseCase(this._repository);

  /// アプリ初期化時のゲームモード取得
  Future<GameMode> initialize() async {
    return await _repository.getLastUsedMode();
  }

  /// 子供モードに切り替え
  Future<GameMode> switchToChildMode() async {
    final currentMode = await _repository.getCurrentMode();

    // 既に子供モードの場合はそのまま返す
    if (currentMode?.isChildMode == true) {
      return currentMode!;
    }

    // 現在の大人モード設定を保存
    if (currentMode?.isAdultMode == true) {
      await _repository.saveAdultSettings(currentMode!.settings);
    }

    // 子供モードに切り替え
    final childMode = (currentMode ?? GameMode.adult()).switchToChild();
    await _repository.saveMode(childMode);

    // モード変更をログ記録
    await _repository.logModeChange(
      fromMode: currentMode ?? GameMode.adult(),
      toMode: childMode,
      timestamp: DateTime.now(),
      reason: 'switched_to_child',
    );

    return childMode;
  }

  /// 大人モードに切り替え（制限なし）
  Future<GameMode> switchToAdultMode() async {
    final currentMode = await _repository.getCurrentMode();

    // 子供モードからの直接切り替えは禁止
    if (currentMode?.isChildMode == true) {
      // 不正試行をログ記録
      await _repository.logChildModeAttempt(
        attemptType: 'unauthorized_mode_switch',
        timestamp: DateTime.now(),
      );

      throw UnauthorizedModeSwitchException(
        'Cannot switch to adult mode from child mode without long press confirmation',
      );
    }

    // 既に大人モードの場合はそのまま返す
    if (currentMode?.isAdultMode == true) {
      return currentMode!;
    }

    // 大人モードに切り替え（通常はここには来ない）
    final adultMode = GameMode.adult();
    await _repository.saveMode(adultMode);
    return adultMode;
  }

  /// ロングプレス確認付きで大人モードに切り替え
  Future<GameMode> switchToAdultModeWithLongPress() async {
    final currentMode = await _repository.getCurrentMode();

    // 保存されている大人モード設定を復元
    final savedAdultSettings = await _repository.getAdultSettings();
    final adultMode = savedAdultSettings != null
        ? GameMode.adult(settings: savedAdultSettings)
        : GameMode.adult();

    await _repository.saveMode(adultMode);

    // モード変更をログ記録
    if (currentMode != null) {
      await _repository.logModeChange(
        fromMode: currentMode,
        toMode: adultMode,
        timestamp: DateTime.now(),
        reason: 'switched_to_adult_with_long_press',
      );
    }

    return adultMode;
  }

  /// ゲーム設定を更新
  Future<GameMode> updateSettings(GameSettings newSettings) async {
    final currentMode = await _repository.getCurrentMode();

    // 子供モードでの設定変更は禁止
    if (currentMode?.isChildMode == true) {
      // 不正試行をログ記録
      await _repository.logChildModeAttempt(
        attemptType: 'unauthorized_settings_change',
        timestamp: DateTime.now(),
      );

      throw UnauthorizedSettingsChangeException(
        'Cannot change settings in child mode',
      );
    }

    // 大人モードでの設定更新
    final updatedMode = (currentMode ?? GameMode.adult()).updateSettings(
      newSettings,
    );
    await _repository.saveMode(updatedMode);
    await _repository.saveAdultSettings(newSettings);

    return updatedMode;
  }

  /// 現在のゲームモードを取得
  Future<GameMode?> getCurrentMode() async {
    return await _repository.getCurrentMode();
  }

  /// 特定機能へのアクセス権限チェック
  Future<bool> canAccessFeature(GameFeature feature) async {
    final currentMode = await _repository.getCurrentMode();

    if (currentMode == null) return true; // デフォルトは許可

    switch (feature) {
      case GameFeature.settings:
        return currentMode.canAccessSettings;
      case GameFeature.reset:
        return currentMode.canResetGame;
      case GameFeature.modeSwitch:
        return currentMode.canChangeMode;
      case GameFeature.play:
        return true; // ゲームプレイは常に許可
    }
  }

  /// 子供モードのセキュリティレポート取得
  Future<ChildModeSecurityReport> getChildModeSecurityReport({
    Duration period = const Duration(hours: 24),
  }) async {
    final attempts = await _repository.getChildModeAttempts(period: period);

    return ChildModeSecurityReport(
      totalAttempts: attempts.length,
      recentAttempts: attempts,
      period: period,
      isSecurityConcern: attempts.length > 5, // 5回を超えると警告
    );
  }

  /// デフォルト設定にリセット
  Future<GameMode> resetToDefaults() async {
    await _repository.resetToDefaults();

    // リセット後はデフォルトモードを返すが、保存はしない
    // 次回初期化時にgetLastUsedModeでデフォルトが返される
    return GameMode.adult();
  }

  /// ゲームモード変更のストリーム取得
  Stream<GameMode> get modeChanges => _repository.modeChanges;
}

/// ゲーム機能の種類
enum GameFeature { settings, reset, modeSwitch, play }

/// 子供モードセキュリティレポート
class ChildModeSecurityReport {
  final int totalAttempts;
  final List<ChildModeAttempt> recentAttempts;
  final Duration period;
  final bool isSecurityConcern;

  const ChildModeSecurityReport({
    required this.totalAttempts,
    required this.recentAttempts,
    required this.period,
    required this.isSecurityConcern,
  });

  @override
  String toString() =>
      'ChildModeSecurityReport('
      'attempts: $totalAttempts, '
      'period: ${period.inHours}h, '
      'concern: $isSecurityConcern)';
}
