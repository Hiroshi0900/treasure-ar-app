import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/application/use_cases/integrated_game_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/ar_session_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/treasure_box_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/game_mode_usecase.dart';
import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/entities/game_mode.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/repositories/ar_session_repository.dart';
import 'package:treasure_ar_app/domain/repositories/treasure_box_repository.dart';
import 'package:treasure_ar_app/domain/repositories/game_mode_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';
import 'package:treasure_ar_app/domain/value_objects/game_settings.dart';
import 'package:vector_math/vector_math_64.dart';

// Mock implementations
class MockARSessionRepository implements ARSessionRepository {
  ARSession? _currentSession;

  @override
  Future<ARSession> startSession() async {
    _currentSession = ARSession.create().start().markAsReady();
    return _currentSession!;
  }

  @override
  Future<void> stopSession() async {
    _currentSession = null;
  }

  @override
  Future<ARSession?> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Stream<ARSession> get sessionStream => Stream.empty();

  @override
  Future<void> addPlane(ARPlane plane) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.addPlane(plane);
    }
  }

  @override
  Future<void> updatePlane(ARPlane plane) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.updatePlane(plane);
    }
  }

  @override
  Future<void> removePlane(String planeId) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.removePlane(planeId);
    }
  }
}

class MockTreasureBoxRepository implements TreasureBoxRepository {
  final Map<String, TreasureBox> _treasureBoxes = {};

  @override
  Future<void> save(TreasureBox treasureBox) async {
    _treasureBoxes[treasureBox.id] = treasureBox;
  }

  @override
  Future<TreasureBox?> findById(String id) async {
    return _treasureBoxes[id];
  }

  @override
  Future<List<TreasureBox>> findAll() async {
    return _treasureBoxes.values.toList();
  }

  @override
  Future<List<TreasureBox>> findByArea(Position3D center, double radius) async {
    return _treasureBoxes.values
        .where((box) => box.position.distanceTo(center) <= radius)
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    _treasureBoxes.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _treasureBoxes.clear();
  }
}

class MockGameModeRepository implements GameModeRepository {
  GameMode? _currentMode;
  GameSettings? _adultSettings;
  final List<ModeChangeLog> _changeLogs = [];
  final List<ChildModeAttempt> _childAttempts = [];

  @override
  Future<GameMode?> getCurrentMode() async => _currentMode;

  @override
  Future<void> saveMode(GameMode mode) async {
    _currentMode = mode;
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
    return _childAttempts;
  }

  @override
  Future<void> resetToDefaults() async {
    _currentMode = null;
    _adultSettings = null;
    _changeLogs.clear();
    _childAttempts.clear();
  }

  @override
  Stream<GameMode> get modeChanges => Stream.empty();
}

void main() {
  group('IntegratedGameUseCase', () {
    late IntegratedGameUseCase useCase;
    late MockARSessionRepository mockARRepo;
    late MockTreasureBoxRepository mockTreasureRepo;
    late MockGameModeRepository mockGameModeRepo;
    late ARSessionUseCase arSessionUseCase;
    late TreasureBoxUseCase treasureBoxUseCase;
    late GameModeUseCase gameModeUseCase;

    setUp(() {
      mockARRepo = MockARSessionRepository();
      mockTreasureRepo = MockTreasureBoxRepository();
      mockGameModeRepo = MockGameModeRepository();

      arSessionUseCase = ARSessionUseCase(mockARRepo);
      treasureBoxUseCase = TreasureBoxUseCase(mockTreasureRepo);
      gameModeUseCase = GameModeUseCase(mockGameModeRepo);

      useCase = IntegratedGameUseCase(
        arSessionUseCase: arSessionUseCase,
        treasureBoxUseCase: treasureBoxUseCase,
        gameModeUseCase: gameModeUseCase,
      );
    });

    group('initializeGame', () {
      test('should initialize game with default adult mode', () async {
        // Given (no specific setup needed - using default state)
        
        // When
        final gameState = await useCase.initializeGame();

        // Then
        expect(gameState.gameMode.isAdultMode, isTrue);
        expect(gameState.isARSessionActive, isFalse);
        expect(gameState.placedTreasures, isEmpty);
        expect(gameState.status, equals(GameStatus.initialized));
      });

      test('should restore previous game mode on initialization', () async {
        // Given
        await mockGameModeRepo.saveMode(GameMode.child());

        // When
        final gameState = await useCase.initializeGame();

        // Then
        expect(gameState.gameMode.isChildMode, isTrue);
      });
    });

    group('startARSession', () {
      test('should start AR session successfully', () async {
        // Given
        await useCase.initializeGame();

        // When
        final gameState = await useCase.startARSession();

        // Then
        expect(gameState.isARSessionActive, isTrue);
        expect(gameState.status, equals(GameStatus.arSessionActive));
      });

      test('should throw exception if game not initialized', () async {
        // Given (no initialization - testing error case)
        
        // When & Then
        expect(
          () => useCase.startARSession(),
          throwsA(isA<GameNotInitializedException>()),
        );
      });
    });

    group('waitForPlaneDetection', () {
      test('should wait until suitable planes are detected', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(2.0, 0, 2.0),
        );
        await mockARRepo.addPlane(plane);

        // When
        final gameState = await useCase.waitForPlaneDetection();

        // Then
        expect(gameState.detectedPlanes, hasLength(1));
        expect(gameState.status, equals(GameStatus.readyForTreasurePlacement));
      });

      test('should timeout if no suitable planes detected', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();

        // When & Then
        expect(
          () => useCase.waitForPlaneDetection(
            timeout: const Duration(milliseconds: 100),
          ),
          throwsA(isA<PlaneDetectionTimeoutException>()),
        );
      });
    });

    group('placeTreasuresAutomatically', () {
      test('should place treasures based on game mode settings', () async {
        // Given: game is initialized with AR session and suitable planes are available
        await useCase.initializeGame();
        await useCase.startARSession();

        // Add suitable planes
        final plane1 = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(3.0, 0, 3.0),
        );
        final plane2 = ARPlane(
          id: 'plane2',
          type: PlaneType.horizontal,
          center: Vector3(2, 0, 2),
          extent: Vector3(2.0, 0, 2.0),
        );
        await mockARRepo.addPlane(plane1);
        await mockARRepo.addPlane(plane2);
        await useCase.waitForPlaneDetection();

        // When: treasures are placed automatically
        final gameState = await useCase.placeTreasuresAutomatically();

        // Then: correct number of treasures should be placed and game status updated
        expect(
          gameState.placedTreasures,
          hasLength(5),
        ); // Default adult mode count
        expect(gameState.status, equals(GameStatus.treasuresPlaced));

        // And: all treasures are hidden initially
        for (final treasure in gameState.placedTreasures) {
          expect(treasure.isHidden, isTrue);
        }
      });

      test('should place fewer treasures in child mode', () async {
        // Given: child mode is configured and game is initialized with suitable plane
        await mockGameModeRepo.saveMode(GameMode.child());
        await useCase.initializeGame();
        await useCase.startARSession();

        // Add suitable plane
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();

        // When: treasures are placed automatically
        final gameState = await useCase.placeTreasuresAutomatically();

        // Then: fewer treasures should be placed according to child mode
        expect(gameState.placedTreasures, hasLength(3)); // Child mode count
      });

      test('should throw exception if no suitable planes available', () async {
        // Given: game is initialized with AR session but no planes are available
        await useCase.initializeGame();
        await useCase.startARSession();

        // When/Then: attempting to place treasures automatically should throw exception
        expect(
          () => useCase.placeTreasuresAutomatically(),
          throwsA(isA<InvalidGameStateException>()),
        );
      });
    });

    group('startTreasureHunt', () {
      test('should start treasure hunt when treasures are placed', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();

        // When
        final gameState = await useCase.startTreasureHunt();

        // Then
        expect(gameState.status, equals(GameStatus.huntInProgress));
        expect(gameState.huntStartTime, isNotNull);
      });
    });

    group('checkForTreasureDiscovery', () {
      test('should discover treasure when player is close enough', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();
        await useCase.startTreasureHunt();

        // Get first treasure position
        final gameState = await useCase.getCurrentGameState();
        final firstTreasure = gameState.placedTreasures.first;
        final playerPosition = Position3D.fromXYZ(
          firstTreasure.position.x + 0.5, // Close enough
          firstTreasure.position.y,
          firstTreasure.position.z,
        );

        // When
        final updatedState = await useCase.checkForTreasureDiscovery(
          playerPosition,
        );

        // Then
        expect(
          updatedState.discoveredTreasures.length,
          greaterThanOrEqualTo(1),
        );
        expect(
          updatedState.discoveredTreasures.every((t) => t.isFound),
          isTrue,
        );
      });

      test('should not discover treasure when player is too far', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();
        await useCase.startTreasureHunt();

        // Player position far from treasures
        final playerPosition = Position3D.fromXYZ(100, 0, 100);

        // When
        final updatedState = await useCase.checkForTreasureDiscovery(
          playerPosition,
        );

        // Then
        expect(updatedState.discoveredTreasures, isEmpty);
      });
    });

    group('openTreasure', () {
      test('should open discovered treasure', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();
        await useCase.startTreasureHunt();

        // Discover a treasure
        final gameState = await useCase.getCurrentGameState();
        final firstTreasure = gameState.placedTreasures.first;
        final playerPosition = Position3D.fromXYZ(
          firstTreasure.position.x + 0.5,
          firstTreasure.position.y,
          firstTreasure.position.z,
        );
        await useCase.checkForTreasureDiscovery(playerPosition);

        // When
        final updatedState = await useCase.openTreasure(firstTreasure.id);

        // Then
        expect(updatedState.openedTreasures, hasLength(1));
        expect(updatedState.openedTreasures.first.isOpened, isTrue);
      });

      test(
        'should throw exception when trying to open hidden treasure',
        () async {
          // Given
          await useCase.initializeGame();
          await useCase.startARSession();
          final plane = ARPlane(
            id: 'plane1',
            type: PlaneType.horizontal,
            center: Vector3(0, 0, 0),
            extent: Vector3(5.0, 0, 5.0),
          );
          await mockARRepo.addPlane(plane);
          await useCase.waitForPlaneDetection();
          await useCase.placeTreasuresAutomatically();
          await useCase.startTreasureHunt();

          final gameState = await useCase.getCurrentGameState();
          final firstTreasure = gameState.placedTreasures.first;

          // When & Then
          expect(
            () => useCase.openTreasure(firstTreasure.id),
            throwsA(isA<InvalidStateTransitionException>()),
          );
        },
      );
    });

    group('checkGameCompletion', () {
      test('should complete game when all treasures are opened', () async {
        // Given
        await mockGameModeRepo.saveMode(
          GameMode.child(),
        ); // Use child mode for fewer treasures
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(10.0, 0, 10.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();
        await useCase.startTreasureHunt();

        // Open all treasures
        final gameState = await useCase.getCurrentGameState();
        for (final treasure in gameState.placedTreasures) {
          final playerPosition = Position3D.fromXYZ(
            treasure.position.x + 0.5,
            treasure.position.y,
            treasure.position.z,
          );
          await useCase.checkForTreasureDiscovery(playerPosition);
          await useCase.openTreasure(treasure.id);
        }

        // When
        final finalState = await useCase.checkGameCompletion();

        // Then
        expect(finalState.status, equals(GameStatus.completed));
        expect(finalState.completionTime, isNotNull);
        expect(finalState.isAllTreasuresFound, isTrue);
      });
    });

    group('resetGame', () {
      test('should reset game to initial state', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();

        // When
        final resetState = await useCase.resetGame();

        // Then
        expect(resetState.status, equals(GameStatus.initialized));
        expect(resetState.placedTreasures, isEmpty);
        expect(resetState.discoveredTreasures, isEmpty);
        expect(resetState.openedTreasures, isEmpty);
        expect(resetState.isARSessionActive, isFalse);
      });

      test(
        'should throw exception when trying to reset in child mode',
        () async {
          // Given
          await mockGameModeRepo.saveMode(GameMode.child());
          await useCase.initializeGame();

          // When & Then
          expect(
            () => useCase.resetGame(),
            throwsA(isA<UnauthorizedSettingsChangeException>()),
          );
        },
      );
    });

    group('getGameStatistics', () {
      test('should return correct game statistics', () async {
        // Given
        await useCase.initializeGame();
        await useCase.startARSession();
        final plane = ARPlane(
          id: 'plane1',
          type: PlaneType.horizontal,
          center: Vector3(0, 0, 0),
          extent: Vector3(5.0, 0, 5.0),
        );
        await mockARRepo.addPlane(plane);
        await useCase.waitForPlaneDetection();
        await useCase.placeTreasuresAutomatically();
        await useCase.startTreasureHunt();

        // Discover one treasure
        final gameState = await useCase.getCurrentGameState();
        final firstTreasure = gameState.placedTreasures.first;
        final playerPosition = Position3D.fromXYZ(
          firstTreasure.position.x + 0.5,
          firstTreasure.position.y,
          firstTreasure.position.z,
        );
        await useCase.checkForTreasureDiscovery(playerPosition);

        // When
        final stats = await useCase.getGameStatistics();

        // Then
        expect(stats.totalTreasures, equals(5)); // Adult mode default
        expect(stats.discoveredTreasures, greaterThanOrEqualTo(1));
        expect(stats.openedTreasures, equals(0));
        expect(
          stats.completionPercentage,
          greaterThanOrEqualTo(20.0),
        ); // At least 1/5 = 20%
        expect(stats.isCompleted, isFalse);
      });
    });
  });
}
