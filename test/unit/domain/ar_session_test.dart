import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/entities/ar_session_state.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('ARSession', () {
    test('should start in NotStarted state', () {
      // Given
      // A new AR session is created
      final session = ARSession.create();

      // When & Then
      // The session should be in NotStarted state with empty planes
      expect(session.state, isA<NotStartedState>());
      expect(session.isReady, isFalse);
      expect(session.detectedPlanes, isEmpty);
    });

    test('should transition to Initializing when started', () {
      // Given
      // A new AR session is created
      final session = ARSession.create();

      // When
      // The session is started
      final initializedSession = session.start();

      // Then
      // The session should be in Initializing state and not ready
      expect(initializedSession.state, isA<InitializingState>());
      expect(initializedSession.isReady, isFalse);
    });

    test('should transition to Ready when initialized', () {
      // Given
      // An AR session is created, started, and marked as ready
      final session = ARSession.create().start().markAsReady();

      // When & Then
      // The session should be in Ready state and ready for use
      expect(session.state, isA<ReadyState>());
      expect(session.isReady, isTrue);
    });

    test('should add detected planes when ready', () {
      // Given
      // An AR session is ready for use
      final session = ARSession.create().start().markAsReady();

      // Given
      // A horizontal AR plane is defined
      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // When
      // The plane is added to the session
      final sessionWithPlane = session.addPlane(plane);

      // Then
      // The session should contain the added plane
      expect(sessionWithPlane.detectedPlanes.length, equals(1));
      expect(sessionWithPlane.detectedPlanes.first.id, equals('plane-1'));
    });

    test('should not add planes when not ready', () {
      // Given
      // A new AR session that is not ready
      final session = ARSession.create();

      // Given
      // A horizontal AR plane is defined
      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // When & Then
      // Adding a plane should throw an InvalidStateException
      expect(
        () => session.addPlane(plane),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test('should update existing plane', () {
      // Given
      // An AR session is ready for use
      final session = ARSession.create().start().markAsReady();

      // Given
      // An original AR plane is defined
      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // Given
      // An updated version of the same plane with different extent
      final updatedPlane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(3, 0, 3),
        type: PlaneType.horizontal,
      );

      // When
      // The plane is added and then updated
      final sessionWithPlane = session
          .addPlane(plane)
          .updatePlane(updatedPlane);

      // Then
      // The session should contain only one plane with updated extent
      expect(sessionWithPlane.detectedPlanes.length, equals(1));
      expect(sessionWithPlane.detectedPlanes.first.extent.x, equals(3));
    });

    test('should remove plane', () {
      // Given
      // An AR session is ready for use
      final session = ARSession.create().start().markAsReady();

      // Given
      // A horizontal AR plane is defined
      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // When
      // The plane is added and then removed
      final sessionWithoutPlane = session
          .addPlane(plane)
          .removePlane('plane-1');

      // Then
      // The session should have no detected planes
      expect(sessionWithoutPlane.detectedPlanes, isEmpty);
    });

    test('should transition to Failed state on error', () {
      // Given
      // An AR session that is initializing
      final session = ARSession.create().start();

      // When
      // The session is marked as failed with an error message
      final failedSession = session.markAsFailed('Camera access denied');

      // Then
      // The session should be in Failed state with the error message
      expect(failedSession.state, isA<FailedState>());
      expect(
        (failedSession.state as FailedState).error,
        equals('Camera access denied'),
      );
    });

    test('should find horizontal planes', () {
      // Given
      // An AR session is ready for use
      final session = ARSession.create().start().markAsReady();

      // Given
      // A horizontal AR plane is defined
      final horizontalPlane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      // Given
      // A vertical AR plane is defined
      final verticalPlane = ARPlane(
        id: 'plane-2',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 2, 0),
        type: PlaneType.vertical,
      );

      // When
      // Both planes are added and horizontal planes are filtered
      final sessionWithPlanes = session
          .addPlane(horizontalPlane)
          .addPlane(verticalPlane);

      final horizontalPlanes = sessionWithPlanes.getPlanesByType(
        PlaneType.horizontal,
      );

      // Then
      // Only the horizontal plane should be returned
      expect(horizontalPlanes.length, equals(1));
      expect(horizontalPlanes.first.id, equals('plane-1'));
    });
  });
}