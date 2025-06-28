/// ゲームモードの状態を型安全に表現するsealed class
sealed class GameModeState {
  const GameModeState();
}

/// 大人モードの状態
class AdultModeState extends GameModeState {
  const AdultModeState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AdultModeState;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AdultModeState()';
}

/// 子供モードの状態
class ChildModeState extends GameModeState {
  /// 終了にロングプレスが必要
  final bool requiresLongPressToExit;

  /// UI簡素化フラグ
  final bool hasSimplifiedUI;

  /// ヒント自動表示
  final bool autoShowHints;

  /// 誤操作防止
  final bool preventAccidentalActions;

  const ChildModeState({
    this.requiresLongPressToExit = true,
    this.hasSimplifiedUI = true,
    this.autoShowHints = true,
    this.preventAccidentalActions = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildModeState &&
          other.requiresLongPressToExit == requiresLongPressToExit &&
          other.hasSimplifiedUI == hasSimplifiedUI &&
          other.autoShowHints == autoShowHints &&
          other.preventAccidentalActions == preventAccidentalActions;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    requiresLongPressToExit,
    hasSimplifiedUI,
    autoShowHints,
    preventAccidentalActions,
  );

  @override
  String toString() =>
      'ChildModeState('
      'requiresLongPressToExit: $requiresLongPressToExit, '
      'hasSimplifiedUI: $hasSimplifiedUI, '
      'autoShowHints: $autoShowHints, '
      'preventAccidentalActions: $preventAccidentalActions)';
}
