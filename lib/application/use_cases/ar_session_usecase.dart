import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/repositories/ar_session_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';

class ARSessionUseCase {
  final ARSessionRepository _repository;

  ARSessionUseCase(this._repository);

  Future<ARSession> startSession() async {
    return await _repository.startSession();
  }

  Future<void> stopSession() async {
    await _repository.stopSession();
  }

  Future<ARSession?> getCurrentSession() async {
    return await _repository.getCurrentSession();
  }

  Stream<ARSession> get sessionStream => _repository.sessionStream;

  Future<void> addPlane(ARPlane plane) async {
    await _repository.addPlane(plane);
  }

  Future<void> updatePlane(ARPlane plane) async {
    await _repository.updatePlane(plane);
  }

  Future<void> removePlane(String planeId) async {
    await _repository.removePlane(planeId);
  }

  Future<List<ARPlane>> getSuitablePlanesForTreasure() async {
    final session = await getCurrentSession();
    if (session == null || !session.isReady) {
      return [];
    }

    return session
        .getPlanesByType(PlaneType.horizontal)
        .where((plane) => plane.isLargeEnough)
        .toList();
  }

  Future<bool> isReadyForTreasurePlacement() async {
    final suitablePlanes = await getSuitablePlanesForTreasure();
    return suitablePlanes.isNotEmpty;
  }

  Future<List<ARPlane>> getHorizontalPlanes() async {
    final session = await getCurrentSession();
    if (session == null) {
      return [];
    }
    return session.getPlanesByType(PlaneType.horizontal);
  }

  Future<List<ARPlane>> getVerticalPlanes() async {
    final session = await getCurrentSession();
    if (session == null) {
      return [];
    }
    return session.getPlanesByType(PlaneType.vertical);
  }
}
