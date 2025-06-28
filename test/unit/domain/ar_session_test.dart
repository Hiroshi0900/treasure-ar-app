import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/entities/ar_session_state.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('ARSession', () {
    test('should start in NotStarted state', () {
      final session = ARSession.create();

      expect(session.state, isA<NotStartedState>());
      expect(session.isReady, isFalse);
      expect(session.detectedPlanes, isEmpty);
    });

    test('should transition to Initializing when started', () {
      final session = ARSession.create();

      final initializedSession = session.start();

      expect(initializedSession.state, isA<InitializingState>());
      expect(initializedSession.isReady, isFalse);
    });

    test('should transition to Ready when initialized', () {
      final session = ARSession.create().start().markAsReady();

      expect(session.state, isA<ReadyState>());
      expect(session.isReady, isTrue);
    });

    test('should add detected planes when ready', () {
      final session = ARSession.create().start().markAsReady();

      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      final sessionWithPlane = session.addPlane(plane);

      expect(sessionWithPlane.detectedPlanes.length, equals(1));
      expect(sessionWithPlane.detectedPlanes.first.id, equals('plane-1'));
    });

    test('should not add planes when not ready', () {
      final session = ARSession.create();

      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      expect(
        () => session.addPlane(plane),
        throwsA(isA<InvalidStateException>()),
      );
    });

    test('should update existing plane', () {
      final session = ARSession.create().start().markAsReady();

      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      final updatedPlane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(3, 0, 3),
        type: PlaneType.horizontal,
      );

      final sessionWithPlane = session
          .addPlane(plane)
          .updatePlane(updatedPlane);

      expect(sessionWithPlane.detectedPlanes.length, equals(1));
      expect(sessionWithPlane.detectedPlanes.first.extent.x, equals(3));
    });

    test('should remove plane', () {
      final session = ARSession.create().start().markAsReady();

      final plane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      final sessionWithoutPlane = session
          .addPlane(plane)
          .removePlane('plane-1');

      expect(sessionWithoutPlane.detectedPlanes, isEmpty);
    });

    test('should transition to Failed state on error', () {
      final session = ARSession.create().start();

      final failedSession = session.markAsFailed('Camera access denied');

      expect(failedSession.state, isA<FailedState>());
      expect(
        (failedSession.state as FailedState).error,
        equals('Camera access denied'),
      );
    });

    test('should find horizontal planes', () {
      final session = ARSession.create().start().markAsReady();

      final horizontalPlane = ARPlane(
        id: 'plane-1',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 0, 2),
        type: PlaneType.horizontal,
      );

      final verticalPlane = ARPlane(
        id: 'plane-2',
        center: Vector3(0, 0, 0),
        extent: Vector3(2, 2, 0),
        type: PlaneType.vertical,
      );

      final sessionWithPlanes = session
          .addPlane(horizontalPlane)
          .addPlane(verticalPlane);

      final horizontalPlanes = sessionWithPlanes.getPlanesByType(
        PlaneType.horizontal,
      );

      expect(horizontalPlanes.length, equals(1));
      expect(horizontalPlanes.first.id, equals('plane-1'));
    });
  });
}
