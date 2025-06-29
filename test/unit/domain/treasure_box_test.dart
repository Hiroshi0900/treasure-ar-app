import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box_state.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() {
  group('TreasureBox', () {
    test('should create a hidden treasure box with position', () {
      // Given
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      
      // When
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      // Then
      expect(treasureBox.id, equals('box1'));
      expect(treasureBox.position, equals(position));
      expect(treasureBox.state, isA<HiddenState>());
    });

    test('should transition from hidden to found state', () {
      // Given
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      // When
      final foundBox = treasureBox.markAsFound();

      // Then
      expect(foundBox.id, equals('box1'));
      expect(foundBox.position, equals(position));
      expect(foundBox.state, isA<FoundState>());
      expect((foundBox.state as FoundState).foundAt, isNotNull);
    });

    test('should transition from found to opened state', () {
      // Given
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);
      final foundBox = treasureBox.markAsFound();

      // When
      final openedBox = foundBox.open();

      // Then
      expect(openedBox.id, equals('box1'));
      expect(openedBox.position, equals(position));
      expect(openedBox.state, isA<OpenedState>());

      final openedState = openedBox.state as OpenedState;
      expect(openedState.foundAt, isNotNull);
      expect(openedState.openedAt, isNotNull);
      expect(openedState.openedAt.isAfter(openedState.foundAt), isTrue);
    });

    test('should not allow opening a hidden treasure box directly', () {
      // Given
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);

      // When & Then
      expect(
        () => treasureBox.open(),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('should not allow marking an opened box as found', () {
      // Given
      final position = Position3D(vector.Vector3(1.0, 0.0, -2.0));
      final treasureBox = TreasureBox.hidden(id: 'box1', position: position);
      final foundBox = treasureBox.markAsFound();
      final openedBox = foundBox.open();

      // When & Then
      expect(
        () => openedBox.markAsFound(),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });
  });

  group('Position3D', () {
    test('should create position with vector', () {
      // Given
      final vector3 = vector.Vector3(1.0, 2.0, 3.0);
      
      // When
      final position = Position3D(vector3);

      // Then
      expect(position.value, equals(vector3));
      expect(position.x, equals(1.0));
      expect(position.y, equals(2.0));
      expect(position.z, equals(3.0));
    });

    test('should calculate distance between two positions', () {
      // Given
      final position1 = Position3D(vector.Vector3(0.0, 0.0, 0.0));
      final position2 = Position3D(vector.Vector3(3.0, 4.0, 0.0));

      // When
      final distance = position1.distanceTo(position2);

      // Then
      expect(distance, equals(5.0));
    });

    test('should check if position is within range', () {
      // Given
      final position1 = Position3D(vector.Vector3(0.0, 0.0, 0.0));
      final position2 = Position3D(vector.Vector3(3.0, 4.0, 0.0));

      // When & Then
      expect(position1.isWithinRange(position2, 6.0), isTrue);
      expect(position1.isWithinRange(position2, 4.0), isFalse);
    });
  });
}
