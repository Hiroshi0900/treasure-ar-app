import 'package:vector_math/vector_math_64.dart' as vector;

class Position3D {
  final vector.Vector3 value;

  Position3D(this.value);

  double get x => value.x;
  double get y => value.y;
  double get z => value.z;

  double distanceTo(Position3D other) {
    return value.distanceTo(other.value);
  }

  bool isWithinRange(Position3D other, double maxDistance) {
    return distanceTo(other) <= maxDistance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position3D &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Position3D(x: $x, y: $y, z: $z)';
}
