import 'package:treasure_ar_app/domain/entities/treasure_box_state.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

class TreasureBox {
  final String id;
  final Position3D position;
  final TreasureBoxState state;

  TreasureBox._({
    required this.id,
    required this.position,
    required this.state,
  });

  factory TreasureBox.hidden({
    required String id,
    required Position3D position,
  }) {
    return TreasureBox._(id: id, position: position, state: HiddenState());
  }

  factory TreasureBox.create({required Position3D position}) {
    return TreasureBox._(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      position: position,
      state: HiddenState(),
    );
  }

  TreasureBox markAsFound() {
    switch (state) {
      case HiddenState():
        return TreasureBox._(
          id: id,
          position: position,
          state: FoundState(foundAt: DateTime.now()),
        );
      case FoundState():
      case OpenedState():
        throw InvalidStateTransitionException(
          'Cannot mark as found from ${state.runtimeType}',
        );
    }
  }

  TreasureBox open() {
    switch (state) {
      case HiddenState():
        throw InvalidStateTransitionException(
          'Cannot open directly from hidden state. Must be found first.',
        );
      case FoundState(foundAt: final foundAt):
        return TreasureBox._(
          id: id,
          position: position,
          state: OpenedState(foundAt: foundAt, openedAt: DateTime.now()),
        );
      case OpenedState():
        throw InvalidStateTransitionException('Treasure box is already opened');
    }
  }

  bool get isHidden => state is HiddenState;
  bool get isFound => state is FoundState;
  bool get isOpened => state is OpenedState;
}

class InvalidStateTransitionException implements Exception {
  final String message;

  InvalidStateTransitionException(this.message);

  @override
  String toString() => 'InvalidStateTransitionException: $message';
}
