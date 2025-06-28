import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/repositories/treasure_box_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';
import 'package:vector_math/vector_math_64.dart';

class MockTreasureBoxRepository implements TreasureBoxRepository {
  final Map<String, TreasureBox> _storage = {};

  @override
  Future<void> save(TreasureBox treasureBox) async {
    _storage[treasureBox.id] = treasureBox;
  }

  @override
  Future<TreasureBox?> findById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<TreasureBox>> findAll() async {
    return _storage.values.toList();
  }

  @override
  Future<List<TreasureBox>> findByArea(Position3D center, double radius) async {
    return _storage.values
        .where((box) => box.position.isWithinRange(center, radius))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}

void main() {
  group('TreasureBoxRepository', () {
    late TreasureBoxRepository repository;

    setUp(() {
      repository = MockTreasureBoxRepository();
    });

    test('should save and retrieve a treasure box by id', () async {
      final treasureBox = TreasureBox.create(
        position: Position3D(Vector3(1, 2, 3)),
      );

      await repository.save(treasureBox);
      final retrieved = await repository.findById(treasureBox.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(treasureBox.id));
      expect(retrieved.position, equals(treasureBox.position));
    });

    test('should return null when treasure box not found', () async {
      final result = await repository.findById('non-existent-id');
      expect(result, isNull);
    });

    test('should retrieve all treasure boxes', () async {
      final box1 = TreasureBox.hidden(id: 'box1', position: Position3D(Vector3(1, 0, 0)));
      final box2 = TreasureBox.hidden(id: 'box2', position: Position3D(Vector3(2, 0, 0)));
      final box3 = TreasureBox.hidden(id: 'box3', position: Position3D(Vector3(3, 0, 0)));

      await repository.save(box1);
      await repository.save(box2);
      await repository.save(box3);

      final allBoxes = await repository.findAll();

      expect(allBoxes.length, equals(3));
      expect(
        allBoxes.map((b) => b.id),
        containsAll([box1.id, box2.id, box3.id]),
      );
    });

    test('should find treasure boxes within a specific area', () async {
      final centerPosition = Position3D(Vector3(0, 0, 0));

      final nearBox1 = TreasureBox.hidden(
        id: 'near1',
        position: Position3D(Vector3(1, 0, 0)),
      );
      final nearBox2 = TreasureBox.hidden(
        id: 'near2',
        position: Position3D(Vector3(0, 1, 0)),
      );
      final farBox = TreasureBox.hidden(
        id: 'far1',
        position: Position3D(Vector3(10, 0, 0)),
      );

      await repository.save(nearBox1);
      await repository.save(nearBox2);
      await repository.save(farBox);

      final nearbyBoxes = await repository.findByArea(centerPosition, 2.0);

      expect(nearbyBoxes.length, equals(2));
      expect(
        nearbyBoxes.map((b) => b.id),
        containsAll([nearBox1.id, nearBox2.id]),
      );
      expect(nearbyBoxes.map((b) => b.id), isNot(contains(farBox.id)));
    });

    test('should update existing treasure box', () async {
      final treasureBox = TreasureBox.create(
        position: Position3D(Vector3(1, 2, 3)),
      );

      await repository.save(treasureBox);

      final foundBox = treasureBox.markAsFound();
      await repository.save(foundBox);

      final retrieved = await repository.findById(treasureBox.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.isFound, isTrue);
    });

    test('should delete a treasure box by id', () async {
      final treasureBox = TreasureBox.create(
        position: Position3D(Vector3(1, 2, 3)),
      );

      await repository.save(treasureBox);
      await repository.delete(treasureBox.id);

      final result = await repository.findById(treasureBox.id);
      expect(result, isNull);
    });

    test('should delete all treasure boxes', () async {
      final box1 = TreasureBox.hidden(id: 'del1', position: Position3D(Vector3(1, 0, 0)));
      final box2 = TreasureBox.hidden(id: 'del2', position: Position3D(Vector3(2, 0, 0)));

      await repository.save(box1);
      await repository.save(box2);

      await repository.deleteAll();

      final allBoxes = await repository.findAll();
      expect(allBoxes, isEmpty);
    });

    test('should handle empty area search', () async {
      final centerPosition = Position3D(Vector3(0, 0, 0));
      final nearbyBoxes = await repository.findByArea(centerPosition, 1.0);

      expect(nearbyBoxes, isEmpty);
    });
  });
}
