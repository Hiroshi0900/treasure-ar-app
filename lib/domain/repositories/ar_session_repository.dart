import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';

abstract class ARSessionRepository {
  Future<ARSession> startSession();

  Future<void> stopSession();

  Future<ARSession?> getCurrentSession();

  Stream<ARSession> get sessionStream;

  Future<void> addPlane(ARPlane plane);

  Future<void> updatePlane(ARPlane plane);

  Future<void> removePlane(String planeId);
}
