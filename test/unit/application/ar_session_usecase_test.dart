import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/application/use_cases/ar_session_usecase.dart';
import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/entities/ar_session_state.dart';
import 'package:treasure_ar_app/domain/repositories/ar_session_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';
import 'package:vector_math/vector_math_64.dart';

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
  Stream<ARSession> get sessionStream => Stream.value(_currentSession!);

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

void main() {
  group('ARSessionUseCase', () {
    late ARSessionUseCase useCase;
    late MockARSessionRepository repository;

    setUp(() {
      repository = MockARSessionRepository();
      useCase = ARSessionUseCase(repository);
    });

    test('should start AR session successfully', () async {
      // Given (no specific setup needed - using default state)
      
      // When
      final session = await useCase.startSession();

      // Then
      expect(session.isReady, isTrue);
      expect(session.state, isA<ReadyState>());
    });

    test('should get current session', () async {
      // Given
      await useCase.startSession();

      // When
      final currentSession = await useCase.getCurrentSession();

      // Then
      expect(currentSession, isNotNull);
      expect(currentSession!.isReady, isTrue);
    });

    test('should stop session', () async {
      // Given
      await useCase.startSession();
      
      // When
      await useCase.stopSession();

      // Then
      final currentSession = await useCase.getCurrentSession();
      expect(currentSession, isNull);
    });

    test('should add plane to session', () async {
      // Given
      await useCase.startSession();

      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // When
      await useCase.addPlane(plane);

      // Then
      final session = await useCase.getCurrentSession();
      expect(session!.detectedPlanes.length, equals(1));
    });

    test('should find suitable planes for treasure placement', () async {
      // Given
      await useCase.startSession();

      final smallPlane = ARPlane(
        id: 'small-plane',
        center: Vector3(0, 0, 0),
        extent: Vector3(0.1, 0, 0.1), // Too small
        type: PlaneType.horizontal,
      );

      final largePlane = ARPlane(
        id: 'large-plane',
        center: Vector3(1, 0, 1),
        extent: Vector3(1, 0, 1), // Large enough
        type: PlaneType.horizontal,
      );

      final verticalPlane = ARPlane(
        id: 'wall-plane',
        center: Vector3(2, 0, 2),
        extent: Vector3(2, 2, 0), // Vertical plane
        type: PlaneType.vertical,
      );

      await useCase.addPlane(smallPlane);
      await useCase.addPlane(largePlane);
      await useCase.addPlane(verticalPlane);

      // When
      final suitablePlanes = await useCase.getSuitablePlanesForTreasure();

      // Then
      expect(suitablePlanes.length, equals(1));
      expect(suitablePlanes.first.id, equals('large-plane'));
    });

    test('should check if session is ready for treasure placement', () async {
      // Given (no session started initially)
      
      // When & Then (should not be ready without session)
      expect(await useCase.isReadyForTreasurePlacement(), isFalse);

      // Given (session started but no planes)
      await useCase.startSession();
      
      // When & Then (should not be ready without suitable planes)
      expect(await useCase.isReadyForTreasurePlacement(), isFalse);

      // Given (suitable plane added)
      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(1, 0, 1),
        type: PlaneType.horizontal,
      );
      await useCase.addPlane(plane);
      
      // When & Then (should be ready with suitable plane)
      expect(await useCase.isReadyForTreasurePlacement(), isTrue);
    });
  });
}
