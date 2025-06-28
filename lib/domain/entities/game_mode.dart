import 'package:treasure_ar_app/domain/entities/game_mode_state.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';

/// ゲームモードを管理するエンティティ
class GameMode {
  final GameModeState state;
  final GameSettings settings;
  final GameSettings? _originalAdultSettings; // 大人モード復帰時の設定保存用

  const GameMode._({
    required this.state,
    required this.settings,
    GameSettings? originalAdultSettings,
  }) : _originalAdultSettings = originalAdultSettings;

  /// 大人モードを作成
  factory GameMode.adult({GameSettings? settings}) {
    final adultSettings = settings ?? GameSettings.defaultAdult();
    return GameMode._(
      state: const AdultModeState(),
      settings: adultSettings,
      originalAdultSettings: adultSettings,
    );
  }

  /// 子供モードを作成
  factory GameMode.child({GameSettings? settings}) {
    final childSettings = settings ?? GameSettings.defaultChild();
    return GameMode._(state: const ChildModeState(), settings: childSettings);
  }

  /// 大人モードかどうか
  bool get isAdultMode => state is AdultModeState;

  /// 子供モードかどうか
  bool get isChildMode => state is ChildModeState;

  /// 設定へのアクセス可能性
  bool get canAccessSettings => isAdultMode;

  /// ゲームリセット可能性
  bool get canResetGame => isAdultMode;

  /// モード変更可能性
  bool get canChangeMode => isAdultMode;

  /// 高度なUI機能の利用可能性
  bool get hasAdvancedUI => isAdultMode;

  /// 子供モードに切り替え
  GameMode switchToChild() {
    if (isChildMode) return this;

    return GameMode._(
      state: const ChildModeState(),
      settings: settings.toChildFriendly(),
      originalAdultSettings: _originalAdultSettings ?? settings,
    );
  }

  /// 大人モードに切り替え（子供モードからは制限あり）
  GameMode switchToAdult() {
    if (isAdultMode) return this;

    // 子供モードからの直接切り替えは禁止
    throw UnauthorizedModeSwitchException(
      'Cannot switch to adult mode from child mode without long press confirmation',
    );
  }

  /// ロングプレス確認付きで大人モードに切り替え
  GameMode switchToAdultWithLongPress() {
    if (isAdultMode) return this;

    // 元の大人モード設定を復元、なければデフォルト
    final adultSettings = _originalAdultSettings ?? GameSettings.defaultAdult();

    return GameMode._(
      state: const AdultModeState(),
      settings: adultSettings,
      originalAdultSettings: adultSettings,
    );
  }

  /// 設定を更新（大人モードのみ）
  GameMode updateSettings(GameSettings newSettings) {
    if (!canAccessSettings) {
      throw UnauthorizedSettingsChangeException(
        'Cannot change settings in child mode',
      );
    }

    return GameMode._(
      state: state,
      settings: newSettings,
      originalAdultSettings: newSettings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameMode && other.state == state && other.settings == settings;

  @override
  int get hashCode => Object.hash(state, settings);

  @override
  String toString() =>
      'GameMode('
      'state: $state, '
      'settings: $settings)';
}

/// 不正なモード切り替えの例外
class UnauthorizedModeSwitchException implements Exception {
  final String message;

  UnauthorizedModeSwitchException(this.message);

  @override
  String toString() => 'UnauthorizedModeSwitchException: $message';
}

/// 不正な設定変更の例外
class UnauthorizedSettingsChangeException implements Exception {
  final String message;

  UnauthorizedSettingsChangeException(this.message);

  @override
  String toString() => 'UnauthorizedSettingsChangeException: $message';
}
