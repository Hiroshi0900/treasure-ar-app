import 'dart:math';

import 'package:treasure_ar_app/application/use_cases/ar_session_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/treasure_box_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/game_mode_usecase.dart';
import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

/// 全体的なゲームフローを管理する統合ユースケース
class IntegratedGameUseCase {
  final ARSessionUseCase _arSessionUseCase;
  final TreasureBoxUseCase _treasureBoxUseCase;
  final GameModeUseCase _gameModeUseCase;

  GameState? _currentGameState;

  IntegratedGameUseCase({
    required ARSessionUseCase arSessionUseCase,
    required TreasureBoxUseCase treasureBoxUseCase,
    required GameModeUseCase gameModeUseCase,
  }) : _arSessionUseCase = arSessionUseCase,
       _treasureBoxUseCase = treasureBoxUseCase,
       _gameModeUseCase = gameModeUseCase;

  /// ゲーム初期化
  Future<GameState> initializeGame() async {
    final gameMode = await _gameModeUseCase.initialize();

    _currentGameState = GameState(
      gameMode: gameMode,
      status: GameStatus.initialized,
      isARSessionActive: false,
      placedTreasures: [],
      discoveredTreasures: [],
      openedTreasures: [],
      detectedPlanes: [],
    );

    return _currentGameState!;
  }

  /// ARセッション開始
  Future<GameState> startARSession() async {
    if (_currentGameState == null) {
      throw GameNotInitializedException('Game must be initialized first');
    }

    await _arSessionUseCase.startSession();

    _currentGameState = _currentGameState!.copyWith(
      isARSessionActive: true,
      status: GameStatus.arSessionActive,
    );

    return _currentGameState!;
  }

  /// 平面検出待機
  Future<GameState> waitForPlaneDetection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_currentGameState?.status != GameStatus.arSessionActive) {
      throw InvalidGameStateException('AR session must be active');
    }

    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      final suitablePlanes = await _arSessionUseCase
          .getSuitablePlanesForTreasure();

      if (suitablePlanes.isNotEmpty) {
        _currentGameState = _currentGameState!.copyWith(
          detectedPlanes: suitablePlanes,
          status: GameStatus.readyForTreasurePlacement,
        );
        return _currentGameState!;
      }

      // Wait a bit before checking again
      await Future.delayed(const Duration(milliseconds: 500));
    }

    throw PlaneDetectionTimeoutException(
      'No suitable planes detected within timeout',
    );
  }

  /// 自動宝箱配置
  Future<GameState> placeTreasuresAutomatically() async {
    if (_currentGameState?.status != GameStatus.readyForTreasurePlacement) {
      throw InvalidGameStateException(
        'Game must be ready for treasure placement',
      );
    }

    final suitablePlanes = await _arSessionUseCase
        .getSuitablePlanesForTreasure();
    if (suitablePlanes.isEmpty) {
      throw InsufficientPlanesException(
        'No suitable planes available for treasure placement',
      );
    }

    final treasureCount = _currentGameState!.gameMode.settings.treasureCount;
    final placedTreasures = <TreasureBox>[];

    for (int i = 0; i < treasureCount; i++) {
      final position = _generateRandomPosition(suitablePlanes);
      final treasure = await _treasureBoxUseCase.placeTreasureBox(position);
      placedTreasures.add(treasure);
    }

    _currentGameState = _currentGameState!.copyWith(
      placedTreasures: placedTreasures,
      status: GameStatus.treasuresPlaced,
    );

    return _currentGameState!;
  }

  /// 宝探し開始
  Future<GameState> startTreasureHunt() async {
    if (_currentGameState?.status != GameStatus.treasuresPlaced) {
      throw InvalidGameStateException('Treasures must be placed first');
    }

    _currentGameState = _currentGameState!.copyWith(
      status: GameStatus.huntInProgress,
      huntStartTime: DateTime.now(),
    );

    return _currentGameState!;
  }

  /// 宝箱発見チェック
  Future<GameState> checkForTreasureDiscovery(Position3D playerPosition) async {
    if (_currentGameState?.status != GameStatus.huntInProgress) {
      throw InvalidGameStateException('Hunt must be in progress');
    }

    final discoveryRange = _currentGameState!.gameMode.settings.discoveryRange;
    final nearbyTreasures = await _treasureBoxUseCase.getTreasureBoxesInArea(
      playerPosition,
      discoveryRange,
    );

    final newlyDiscovered = <TreasureBox>[];
    final allDiscovered = List<TreasureBox>.from(
      _currentGameState!.discoveredTreasures,
    );

    for (final treasure in nearbyTreasures) {
      if (treasure.isHidden && !allDiscovered.any((t) => t.id == treasure.id)) {
        try {
          final discoveredTreasure = await _treasureBoxUseCase
              .discoverTreasureBox(treasure.id, playerPosition);
          if (discoveredTreasure != null) {
            newlyDiscovered.add(discoveredTreasure);
            allDiscovered.add(discoveredTreasure);
          }
        } catch (e) {
          // Treasure might be too far or already discovered
          continue;
        }
      }
    }

    if (newlyDiscovered.isNotEmpty) {
      _currentGameState = _currentGameState!.copyWith(
        discoveredTreasures: allDiscovered,
      );
    }

    return _currentGameState!;
  }

  /// 宝箱開封
  Future<GameState> openTreasure(String treasureId) async {
    if (_currentGameState?.status != GameStatus.huntInProgress) {
      throw InvalidGameStateException('Hunt must be in progress');
    }

    final openedTreasure = await _treasureBoxUseCase.openTreasureBox(
      treasureId,
    );
    if (openedTreasure != null) {
      final allOpened = List<TreasureBox>.from(
        _currentGameState!.openedTreasures,
      );
      allOpened.add(openedTreasure);

      _currentGameState = _currentGameState!.copyWith(
        openedTreasures: allOpened,
      );
    }

    return _currentGameState!;
  }

  /// ゲーム完了チェック
  Future<GameState> checkGameCompletion() async {
    if (_currentGameState == null) {
      throw GameNotInitializedException('Game not initialized');
    }

    final isCompleted =
        _currentGameState!.openedTreasures.length ==
        _currentGameState!.placedTreasures.length;

    if (isCompleted && _currentGameState!.status != GameStatus.completed) {
      _currentGameState = _currentGameState!.copyWith(
        status: GameStatus.completed,
        completionTime: DateTime.now(),
      );
    }

    return _currentGameState!;
  }

  /// ゲームリセット
  Future<GameState> resetGame() async {
    final canReset = await _gameModeUseCase.canAccessFeature(GameFeature.reset);
    if (!canReset) {
      throw UnauthorizedSettingsChangeException(
        'Cannot reset game in child mode',
      );
    }

    // Clear all treasures
    await _treasureBoxUseCase.removeAllTreasureBoxes();

    // Stop AR session
    await _arSessionUseCase.stopSession();

    // Reset to initialized state
    final gameMode =
        await _gameModeUseCase.getCurrentMode() ?? GameMode.adult();
    _currentGameState = GameState(
      gameMode: gameMode,
      status: GameStatus.initialized,
      isARSessionActive: false,
      placedTreasures: [],
      discoveredTreasures: [],
      openedTreasures: [],
      detectedPlanes: [],
    );

    return _currentGameState!;
  }

  /// 現在のゲーム状態取得
  Future<GameState> getCurrentGameState() async {
    if (_currentGameState == null) {
      return await initializeGame();
    }
    return _currentGameState!;
  }

  /// ゲーム統計取得
  Future<GameStatistics> getGameStatistics() async {
    if (_currentGameState == null) {
      throw GameNotInitializedException('Game not initialized');
    }

    final totalTreasures = _currentGameState!.placedTreasures.length;
    final discoveredCount = _currentGameState!.discoveredTreasures.length;
    final openedCount = _currentGameState!.openedTreasures.length;

    final completionPercentage = totalTreasures > 0
        ? (discoveredCount / totalTreasures) * 100.0
        : 0.0;

    final playTime = _currentGameState!.huntStartTime != null
        ? DateTime.now().difference(_currentGameState!.huntStartTime!)
        : Duration.zero;

    return GameStatistics(
      totalTreasures: totalTreasures,
      discoveredTreasures: discoveredCount,
      openedTreasures: openedCount,
      completionPercentage: completionPercentage,
      playTime: playTime,
      isCompleted: _currentGameState!.status == GameStatus.completed,
    );
  }

  /// ゲームモードを設定
  Future<void> setGameMode(GameMode gameMode) async {
    if (_currentGameState != null) {
      _currentGameState = _currentGameState!.copyWith(gameMode: gameMode);
    }
  }

  /// 適切な平面からランダムな位置を生成
  Position3D _generateRandomPosition(List<ARPlane> planes) {
    final random = Random();
    final plane = planes[random.nextInt(planes.length)];

    // 平面の範囲内でランダムな位置を生成
    final offsetX =
        (random.nextDouble() - 0.5) * plane.extent.x * 0.8; // 80%の範囲を使用
    final offsetZ = (random.nextDouble() - 0.5) * plane.extent.z * 0.8;

    return Position3D.fromXYZ(
      plane.center.x + offsetX,
      plane.center.y,
      plane.center.z + offsetZ,
    );
  }
}

/// ゲーム状態
class GameState {
  final GameMode gameMode;
  final GameStatus status;
  final bool isARSessionActive;
  final List<TreasureBox> placedTreasures;
  final List<TreasureBox> discoveredTreasures;
  final List<TreasureBox> openedTreasures;
  final List<ARPlane> detectedPlanes;
  final DateTime? huntStartTime;
  final DateTime? completionTime;

  const GameState({
    required this.gameMode,
    required this.status,
    required this.isARSessionActive,
    required this.placedTreasures,
    required this.discoveredTreasures,
    required this.openedTreasures,
    required this.detectedPlanes,
    this.huntStartTime,
    this.completionTime,
  });

  bool get isAllTreasuresFound =>
      openedTreasures.length == placedTreasures.length;

  GameState copyWith({
    GameMode? gameMode,
    GameStatus? status,
    bool? isARSessionActive,
    List<TreasureBox>? placedTreasures,
    List<TreasureBox>? discoveredTreasures,
    List<TreasureBox>? openedTreasures,
    List<ARPlane>? detectedPlanes,
    DateTime? huntStartTime,
    DateTime? completionTime,
  }) {
    return GameState(
      gameMode: gameMode ?? this.gameMode,
      status: status ?? this.status,
      isARSessionActive: isARSessionActive ?? this.isARSessionActive,
      placedTreasures: placedTreasures ?? this.placedTreasures,
      discoveredTreasures: discoveredTreasures ?? this.discoveredTreasures,
      openedTreasures: openedTreasures ?? this.openedTreasures,
      detectedPlanes: detectedPlanes ?? this.detectedPlanes,
      huntStartTime: huntStartTime ?? this.huntStartTime,
      completionTime: completionTime ?? this.completionTime,
    );
  }
}

/// ゲーム状態の種類
enum GameStatus {
  initialized,
  arSessionActive,
  readyForTreasurePlacement,
  treasuresPlaced,
  huntInProgress,
  completed,
}

/// ゲーム統計
class GameStatistics {
  final int totalTreasures;
  final int discoveredTreasures;
  final int openedTreasures;
  final double completionPercentage;
  final Duration playTime;
  final bool isCompleted;

  const GameStatistics({
    required this.totalTreasures,
    required this.discoveredTreasures,
    required this.openedTreasures,
    required this.completionPercentage,
    required this.playTime,
    required this.isCompleted,
  });
}

/// ゲーム関連例外
class GameNotInitializedException implements Exception {
  final String message;
  GameNotInitializedException(this.message);
  @override
  String toString() => 'GameNotInitializedException: $message';
}

class InvalidGameStateException implements Exception {
  final String message;
  InvalidGameStateException(this.message);
  @override
  String toString() => 'InvalidGameStateException: $message';
}

class PlaneDetectionTimeoutException implements Exception {
  final String message;
  PlaneDetectionTimeoutException(this.message);
  @override
  String toString() => 'PlaneDetectionTimeoutException: $message';
}

class InsufficientPlanesException implements Exception {
  final String message;
  InsufficientPlanesException(this.message);
  @override
  String toString() => 'InsufficientPlanesException: $message';
}
