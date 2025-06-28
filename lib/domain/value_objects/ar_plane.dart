import 'package:vector_math/vector_math_64.dart';

enum PlaneType { horizontal, vertical }

class ARPlane {
  final String id;
  final Vector3 center;
  final Vector3 extent;
  final PlaneType type;

  const ARPlane({
    required this.id,
    required this.center,
    required this.extent,
    required this.type,
  });

  double get area {
    return extent.x * extent.z;
  }

  bool get isLargeEnough {
    return area >= 0.2; // 20cm x 20cm minimum
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ARPlane &&
        other.id == id &&
        other.center == center &&
        other.extent == extent &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, center, extent, type);
  }

  @override
  String toString() {
    return 'ARPlane(id: $id, center: $center, extent: $extent, type: $type)';
  }
}
