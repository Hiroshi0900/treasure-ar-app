import 'package:flutter_test/flutter_test.dart';
import 'package:treasure_ar_app/application/use_cases/treasure_box_usecase.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box_state.dart';
import 'package:treasure_ar_app/domain/repositories/treasure_box_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

class MockTreasureBoxRepository implements TreasureBoxRepository {
  final Map<String, TreasureBox> _treasureBoxes = {};

  @override
  Future<void> save(TreasureBox treasureBox) async {
    _treasureBoxes[treasureBox.id] = treasureBox;
  }

  @override
  Future<TreasureBox?> findById(String id) async {
    return _treasureBoxes[id];
  }

  @override
  Future<List<TreasureBox>> findAll() async {
    return _treasureBoxes.values.toList();
  }

  @override
  Future<List<TreasureBox>> findByArea(Position3D center, double radius) async {
    return _treasureBoxes.values
        .where((box) => box.position.distanceTo(center) <= radius)
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    _treasureBoxes.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _treasureBoxes.clear();
  }
}

void main() {
  group('TreasureBoxUseCase', () {
    late TreasureBoxUseCase useCase;
    late MockTreasureBoxRepository mockRepository;

    setUp(() {
      mockRepository = MockTreasureBoxRepository();
      useCase = TreasureBoxUseCase(mockRepository);
    });

    group('placeTreasureBox', () {
      test(
        'should create and save a new treasure box at given position',
        () async {
          // Given
          final position = Position3D.fromXYZ(1.0, 0.0, 2.0);

          // When
          final treasureBox = await useCase.placeTreasureBox(position);

          // Then
          expect(treasureBox.position, equals(position));
          expect(treasureBox.isHidden, isTrue);
          expect(treasureBox.id, isNotEmpty);

          // Verify it was saved
          final saved = await mockRepository.findById(treasureBox.id);
          expect(saved, isNotNull);
          expect(saved!.id, equals(treasureBox.id));
        },
      );

      test('should create treasure boxes with unique IDs', () async {
        // Given
        final position1 = Position3D.fromXYZ(1.0, 0.0, 2.0);
        final position2 = Position3D.fromXYZ(2.0, 0.0, 3.0);

        // When
        final box1 = await useCase.placeTreasureBox(position1);
        final box2 = await useCase.placeTreasureBox(position2);

        // Then
        expect(box1.id, isNot(equals(box2.id)));
      });
    });

    group('findTreasureBox', () {
      test('should return treasure box when found by ID', () async {
        // Given
        final position = Position3D.fromXYZ(1.0, 0.0, 2.0);
        final originalBox = await useCase.placeTreasureBox(position);

        // When
        final foundBox = await useCase.findTreasureBox(originalBox.id);

        // Then
        expect(foundBox, isNotNull);
        expect(foundBox!.id, equals(originalBox.id));
        expect(foundBox.position, equals(position));
      });

      test('should return null when treasure box not found', () async {
        // Given (no treasure boxes exist - using default state)
        
        // When
        final foundBox = await useCase.findTreasureBox('non-existent-id');

        // Then
        expect(foundBox, isNull);
      });
    });

    group('discoverTreasureBox', () {
      test(
        'should mark treasure box as found when within discovery range',
        () async {
          // Given
          final treasurePosition = Position3D.fromXYZ(1.0, 0.0, 1.0);
          final playerPosition = Position3D.fromXYZ(1.0, 0.0, 1.5); // 0.5m away
          final treasureBox = await useCase.placeTreasureBox(treasurePosition);

          // When
          final discoveredBox = await useCase.discoverTreasureBox(
            treasureBox.id,
            playerPosition,
          );

          // Then
          expect(discoveredBox, isNotNull);
          expect(discoveredBox!.isFound, isTrue);
          expect(discoveredBox.state, isA<FoundState>());

          // Verify it was saved with updated state
          final saved = await mockRepository.findById(treasureBox.id);
          expect(saved!.isFound, isTrue);
        },
      );

      test(
        'should throw exception when treasure box is too far away',
        () async {
          // Given
          final treasurePosition = Position3D.fromXYZ(1.0, 0.0, 1.0);
          final playerPosition = Position3D.fromXYZ(1.0, 0.0, 5.0); // 4.0m away
          final treasureBox = await useCase.placeTreasureBox(treasurePosition);

          // When & Then
          expect(
            () => useCase.discoverTreasureBox(treasureBox.id, playerPosition),
            throwsA(isA<TreasureBoxTooFarException>()),
          );
        },
      );

      test('should throw exception when treasure box does not exist', () async {
        // Given
        final playerPosition = Position3D.fromXYZ(1.0, 0.0, 1.0);

        // When & Then
        expect(
          () => useCase.discoverTreasureBox('non-existent-id', playerPosition),
          throwsA(isA<TreasureBoxNotFoundException>()),
        );
      });

      test(
        'should throw exception when treasure box is already found',
        () async {
          // Given
          final treasurePosition = Position3D.fromXYZ(1.0, 0.0, 1.0);
          final playerPosition = Position3D.fromXYZ(1.0, 0.0, 1.1);
          final treasureBox = await useCase.placeTreasureBox(treasurePosition);

          // First discovery
          await useCase.discoverTreasureBox(treasureBox.id, playerPosition);

          // When & Then
          expect(
            () => useCase.discoverTreasureBox(treasureBox.id, playerPosition),
            throwsA(isA<InvalidStateTransitionException>()),
          );
        },
      );
    });

    group('openTreasureBox', () {
      test('should open treasure box when it is found', () async {
        // Given
        final treasurePosition = Position3D.fromXYZ(1.0, 0.0, 1.0);
        final playerPosition = Position3D.fromXYZ(1.0, 0.0, 1.1);
        final treasureBox = await useCase.placeTreasureBox(treasurePosition);
        await useCase.discoverTreasureBox(treasureBox.id, playerPosition);

        // When
        final openedBox = await useCase.openTreasureBox(treasureBox.id);

        // Then
        expect(openedBox, isNotNull);
        expect(openedBox!.isOpened, isTrue);
        expect(openedBox.state, isA<OpenedState>());

        // Verify it was saved with updated state
        final saved = await mockRepository.findById(treasureBox.id);
        expect(saved!.isOpened, isTrue);
      });

      test('should throw exception when treasure box does not exist', () async {
        // Given (no treasure boxes exist - using default state)
        
        // When & Then
        expect(
          () => useCase.openTreasureBox('non-existent-id'),
          throwsA(isA<TreasureBoxNotFoundException>()),
        );
      });

      test(
        'should throw exception when treasure box is not found yet',
        () async {
          // Given
          final treasurePosition = Position3D.fromXYZ(1.0, 0.0, 1.0);
          final treasureBox = await useCase.placeTreasureBox(treasurePosition);

          // When & Then
          expect(
            () => useCase.openTreasureBox(treasureBox.id),
            throwsA(isA<InvalidStateTransitionException>()),
          );
        },
      );
    });

    group('getTreasureBoxesInArea', () {
      test('should return treasure boxes within specified radius', () async {
        // Given
        final center = Position3D.fromXYZ(0.0, 0.0, 0.0);
        final radius = 2.0;

        // Place treasure boxes at different distances
        await useCase.placeTreasureBox(
          Position3D.fromXYZ(1.0, 0.0, 0.0),
        ); // 1.0m away
        await useCase.placeTreasureBox(
          Position3D.fromXYZ(0.0, 0.0, 1.5),
        ); // 1.5m away
        await useCase.placeTreasureBox(
          Position3D.fromXYZ(0.0, 0.0, 3.0),
        ); // 3.0m away (outside)

        // When
        final treasuresInArea = await useCase.getTreasureBoxesInArea(
          center,
          radius,
        );

        // Then
        expect(treasuresInArea, hasLength(2));
        for (final treasure in treasuresInArea) {
          expect(
            treasure.position.distanceTo(center),
            lessThanOrEqualTo(radius),
          );
        }
      });

      test('should return empty list when no treasure boxes in area', () async {
        // Given
        final center = Position3D.fromXYZ(0.0, 0.0, 0.0);
        final radius = 1.0;

        // Place treasure box outside radius
        await useCase.placeTreasureBox(Position3D.fromXYZ(5.0, 0.0, 0.0));

        // When
        final treasuresInArea = await useCase.getTreasureBoxesInArea(
          center,
          radius,
        );

        // Then
        expect(treasuresInArea, isEmpty);
      });
    });

    group('getAllTreasureBoxes', () {
      test('should return all placed treasure boxes', () async {
        // Given
        await useCase.placeTreasureBox(Position3D.fromXYZ(1.0, 0.0, 1.0));
        await useCase.placeTreasureBox(Position3D.fromXYZ(2.0, 0.0, 2.0));
        await useCase.placeTreasureBox(Position3D.fromXYZ(3.0, 0.0, 3.0));

        // When
        final allTreasures = await useCase.getAllTreasureBoxes();

        // Then
        expect(allTreasures, hasLength(3));
      });

      test('should return empty list when no treasure boxes exist', () async {
        // Given (no treasure boxes exist - using default state)
        
        // When
        final allTreasures = await useCase.getAllTreasureBoxes();

        // Then
        expect(allTreasures, isEmpty);
      });
    });

    group('removeAllTreasureBoxes', () {
      test('should remove all treasure boxes', () async {
        // Given
        await useCase.placeTreasureBox(Position3D.fromXYZ(1.0, 0.0, 1.0));
        await useCase.placeTreasureBox(Position3D.fromXYZ(2.0, 0.0, 2.0));

        // When
        await useCase.removeAllTreasureBoxes();

        // Then
        final allTreasures = await useCase.getAllTreasureBoxes();
        expect(allTreasures, isEmpty);
      });
    });

    group('getHiddenTreasureBoxes', () {
      test('should return only hidden treasure boxes', () async {
        // Given
        final position1 = Position3D.fromXYZ(1.0, 0.0, 1.0);
        final position2 = Position3D.fromXYZ(2.0, 0.0, 2.0);
        final position3 = Position3D.fromXYZ(3.0, 0.0, 3.0);
        final playerPosition = Position3D.fromXYZ(1.0, 0.0, 1.1);

        final box1 = await useCase.placeTreasureBox(position1);
        final box2 = await useCase.placeTreasureBox(position2);
        await useCase.placeTreasureBox(position3);

        // Discover box1, open box2
        await useCase.discoverTreasureBox(box1.id, playerPosition);
        await useCase.discoverTreasureBox(
          box2.id,
          Position3D.fromXYZ(2.0, 0.0, 2.1),
        );
        await useCase.openTreasureBox(box2.id);

        // When
        final hiddenBoxes = await useCase.getHiddenTreasureBoxes();

        // Then
        expect(hiddenBoxes, hasLength(1));
        expect(hiddenBoxes.first.isHidden, isTrue);
      });
    });
  });
}
