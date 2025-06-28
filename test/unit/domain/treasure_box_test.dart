import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box_state.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() {
  group('TreasureBox', () {
    test('should create a hidden treasure box with position', () {
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      expect(treasureBox.id, equals('box1'));
      expect(treasureBox.position, equals(position));
      expect(treasureBox.state, isA<HiddenState>());
    });

    test('should transition from hidden to found state', () {
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      final foundBox = treasureBox.markAsFound();

      expect(foundBox.id, equals('box1'));
      expect(foundBox.position, equals(position));
      expect(foundBox.state, isA<FoundState>());
      expect((foundBox.state as FoundState).foundAt, isNotNull);
    });

    test('should transition from found to opened state', () {
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      final foundBox = treasureBox.markAsFound();
      final openedBox = foundBox.open();

      expect(openedBox.id, equals('box1'));
      expect(openedBox.position, equals(position));
      expect(openedBox.state, isA<OpenedState>());

      final openedState = openedBox.state as OpenedState;
      expect(openedState.foundAt, isNotNull);
      expect(openedState.openedAt, isNotNull);
      expect(openedState.openedAt.isAfter(openedState.foundAt), isTrue);
    });

    test('should not allow opening a hidden treasure box directly', () {
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      expect(
        () => treasureBox.open(),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('should not allow marking an opened box as found', () {
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      final foundBox = treasureBox.markAsFound();
      final openedBox = foundBox.open();

      expect(
        () => openedBox.markAsFound(),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });
  });

  group('Position3D', () {
    test('should create position with vector', () {
      final vector3 = vector.Vector3(1.0, 2.0, 3.0);
      final position = Position3D(vector3);

      expect(position.value, equals(vector3));
      expect(position.x, equals(1.0));
      expect(position.y, equals(2.0));
      expect(position.z, equals(3.0));
    });

    test('should calculate distance between two positions', () {
      final position1 = Position3D(vector.Vector3(0.0, 0.0, 0.0));
      final position2 = Position3D(vector.Vector3(3.0, 4.0, 0.0));

      final distance = position1.distanceTo(position2);

      expect(distance, equals(5.0));
    });

    test('should check if position is within range', () {
      final position1 = Position3D(vector.Vector3(0.0, 0.0, 0.0));
      final position2 = Position3D(vector.Vector3(3.0, 4.0, 0.0));

      expect(position1.isWithinRange(position2, 6.0), isTrue);
      expect(position1.isWithinRange(position2, 4.0), isFalse);
    });
  });
}
