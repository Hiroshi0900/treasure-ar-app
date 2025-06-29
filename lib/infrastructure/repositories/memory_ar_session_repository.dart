import 'dart:async';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:treasure_ar_app/domain/entities/ar_session.dart';
import 'package:treasure_ar_app/domain/repositories/ar_session_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/ar_plane.dart';

/// メモリベースのARセッションリポジトリ実装
class MemoryARSessionRepository implements ARSessionRepository {
  ARSession? _currentSession;
  final StreamController<ARSession> _sessionController = StreamController<ARSession>.broadcast();
  ARKitController? _arkitController;

  /// ARKitControllerを設定
  void setARKitController(ARKitController controller) {
    _arkitController = controller;
  }

  @override
  Future<ARSession> startSession() async {
    if (_arkitController == null) {
      throw Exception('ARKitController not set. Call setARKitController first.');
    }

    _currentSession = ARSession.create().start().markAsReady();
    _sessionController.add(_currentSession!);
    return _currentSession!;
  }

  @override
  Future<void> stopSession() async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.stop();
      _sessionController.add(_currentSession!);
    }
    _currentSession = null;
  }

  @override
  Future<ARSession?> getCurrentSession() async {
    return _currentSession;
  }

  @override
  Stream<ARSession> get sessionStream => _sessionController.stream;

  @override
  Future<void> addPlane(ARPlane plane) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.addPlane(plane);
      _sessionController.add(_currentSession!);
    }
  }

  @override
  Future<void> updatePlane(ARPlane plane) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.updatePlane(plane);
      _sessionController.add(_currentSession!);
    }
  }

  @override
  Future<void> removePlane(String planeId) async {
    if (_currentSession != null) {
      _currentSession = _currentSession!.removePlane(planeId);
      _sessionController.add(_currentSession!);
    }
  }

  /// ARKitPlaneAnchorを内部ARPlaneに変換
  ARPlane convertARKitPlane(ARKitPlaneAnchor planeAnchor) {
    // ARKitプラグインのバージョンに依存するプロパティを安全に取得
    final planeType = _determinePlaneType(planeAnchor);
    
    return ARPlane(
      id: planeAnchor.identifier,
      type: planeType,
      center: Vector3(
        planeAnchor.transform.getColumn(3).x,
        planeAnchor.transform.getColumn(3).y,
        planeAnchor.transform.getColumn(3).z,
      ),
      extent: Vector3(
        planeAnchor.extent.x,
        0,
        planeAnchor.extent.z,
      ),
    );
  }

  /// プレーンの種類を判定（水平面か垂直面か）
  PlaneType _determinePlaneType(ARKitPlaneAnchor planeAnchor) {
    // ARKitのプレーンは通常、Y軸の値が小さい（床に近い）場合は水平面
    // より確実な判定方法を使用
    final transform = planeAnchor.transform;
    final yPosition = transform.getColumn(3).y;
    
    // 床からの高さが一定値以下なら水平面、それ以外は垂直面として判定
    return yPosition.abs() < 0.5 ? PlaneType.horizontal : PlaneType.vertical;
  }

  void dispose() {
    _sessionController.close();
  }
}