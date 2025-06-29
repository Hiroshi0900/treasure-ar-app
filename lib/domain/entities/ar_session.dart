import 'package:treasure_ar_app/domain/entities/ar_session_state.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';

class ARSession {
  final String id;
  final ARSessionState state;
  final List<ARPlane> detectedPlanes;

  const ARSession._({
    required this.id,
    required this.state,
    required this.detectedPlanes,
  });

  factory ARSession.create() {
    return ARSession._(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      state: NotStartedState(),
      detectedPlanes: [],
    );
  }

  bool get isReady => state is ReadyState;

  ARSession start() {
    if (state is! NotStartedState) {
      throw InvalidStateException(
        'Cannot start session from ${state.runtimeType}',
      );
    }

    return ARSession._(
      id: id,
      state: InitializingState(),
      detectedPlanes: detectedPlanes,
    );
  }

  ARSession markAsReady() {
    if (state is! InitializingState) {
      throw InvalidStateException(
        'Cannot mark as ready from ${state.runtimeType}',
      );
    }

    return ARSession._(
      id: id,
      state: ReadyState(),
      detectedPlanes: detectedPlanes,
    );
  }

  ARSession markAsFailed(String error) {
    return ARSession._(
      id: id,
      state: FailedState(error),
      detectedPlanes: detectedPlanes,
    );
  }

  ARSession stop() {
    return ARSession._(
      id: id,
      state: NotStartedState(),
      detectedPlanes: [],
    );
  }

  ARSession addPlane(ARPlane plane) {
    if (!isReady) {
      throw InvalidStateException('Cannot add plane when session is not ready');
    }

    final updatedPlanes = List<ARPlane>.from(detectedPlanes);

    // Replace if plane with same ID exists, otherwise add
    final existingIndex = updatedPlanes.indexWhere((p) => p.id == plane.id);
    if (existingIndex >= 0) {
      updatedPlanes[existingIndex] = plane;
    } else {
      updatedPlanes.add(plane);
    }

    return ARSession._(id: id, state: state, detectedPlanes: updatedPlanes);
  }

  ARSession updatePlane(ARPlane plane) {
    if (!isReady) {
      throw InvalidStateException(
        'Cannot update plane when session is not ready',
      );
    }

    return addPlane(plane);
  }

  ARSession removePlane(String planeId) {
    if (!isReady) {
      throw InvalidStateException(
        'Cannot remove plane when session is not ready',
      );
    }

    final updatedPlanes = detectedPlanes.where((p) => p.id != planeId).toList();

    return ARSession._(id: id, state: state, detectedPlanes: updatedPlanes);
  }

  List<ARPlane> getPlanesByType(PlaneType type) {
    return detectedPlanes.where((plane) => plane.type == type).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ARSession &&
        other.id == id &&
        other.state.runtimeType == state.runtimeType &&
        other.detectedPlanes.length == detectedPlanes.length;
  }

  @override
  int get hashCode {
    return Object.hash(id, state.runtimeType, detectedPlanes.length);
  }

  @override
  String toString() {
    return 'ARSession(id: $id, state: ${state.runtimeType}, planes: ${detectedPlanes.length})';
  }
}
