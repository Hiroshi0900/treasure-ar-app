/// ゲーム設定を表現する値オブジェクト
class GameSettings {
  /// 宝箱の数（1-20個）
  final int treasureCount;

  /// ゲーム制限時間（1分-60分）
  final Duration gameTimeLimit;

  /// 発見可能範囲（0.5m-10m）
  final double discoveryRange;

  /// ヒント表示フラグ
  final bool showHints;

  /// 音声再生フラグ
  final bool playSounds;

  GameSettings({
    required this.treasureCount,
    required this.gameTimeLimit,
    required this.discoveryRange,
    required this.showHints,
    required this.playSounds,
  }) {
    _validateSettings();
  }

  /// 大人モード用のデフォルト設定
  factory GameSettings.defaultAdult() {
    return GameSettings(
      treasureCount: 5,
      gameTimeLimit: const Duration(minutes: 10),
      discoveryRange: 1.0,
      showHints: true,
      playSounds: true,
    );
  }

  /// 子供モード用のデフォルト設定
  factory GameSettings.defaultChild() {
    return GameSettings(
      treasureCount: 3, // 少なめ
      gameTimeLimit: const Duration(minutes: 5), // 短め
      discoveryRange: 2.0, // 広め
      showHints: true, // 必須
      playSounds: true, // 必須
    );
  }

  /// 設定値の妥当性を検証
  void _validateSettings() {
    // 宝箱数の検証
    if (treasureCount < 1 || treasureCount > 20) {
      throw InvalidGameSettingsException(
        'Treasure count must be between 1 and 20, got: $treasureCount',
      );
    }

    // 制限時間の検証
    if (gameTimeLimit < const Duration(minutes: 1) ||
        gameTimeLimit > const Duration(minutes: 60)) {
      throw InvalidGameSettingsException(
        'Game time limit must be between 1 and 60 minutes, got: ${gameTimeLimit.inMinutes} minutes',
      );
    }

    // 発見範囲の検証
    if (discoveryRange < 0.5 || discoveryRange > 10.0) {
      throw InvalidGameSettingsException(
        'Discovery range must be between 0.5 and 10.0 meters, got: $discoveryRange',
      );
    }
  }

  /// 子供モード向けに設定を調整
  GameSettings toChildFriendly() {
    return GameSettings(
      treasureCount: treasureCount > 3 ? 3 : treasureCount, // 最大3個に制限
      gameTimeLimit: gameTimeLimit > const Duration(minutes: 8)
          ? const Duration(minutes: 5)
          : gameTimeLimit, // 最大8分に制限
      discoveryRange: discoveryRange < 1.5 ? 2.0 : discoveryRange, // 最小1.5mに拡張
      showHints: true, // 常に有効
      playSounds: true, // 常に有効
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettings &&
          other.treasureCount == treasureCount &&
          other.gameTimeLimit == gameTimeLimit &&
          other.discoveryRange == discoveryRange &&
          other.showHints == showHints &&
          other.playSounds == playSounds;

  @override
  int get hashCode => Object.hash(
    treasureCount,
    gameTimeLimit,
    discoveryRange,
    showHints,
    playSounds,
  );

  @override
  String toString() =>
      'GameSettings('
      'treasureCount: $treasureCount, '
      'gameTimeLimit: ${gameTimeLimit.inMinutes}min, '
      'discoveryRange: ${discoveryRange}m, '
      'showHints: $showHints, '
      'playSounds: $playSounds)';
}

/// ゲーム設定が無効な場合の例外
class InvalidGameSettingsException implements Exception {
  final String message;

  InvalidGameSettingsException(this.message);

  @override
  String toString() => 'InvalidGameSettingsException: $message';
}
