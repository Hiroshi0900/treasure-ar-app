sealed class TreasureBoxState {}

class HiddenState extends TreasureBoxState {
  HiddenState();
}

class FoundState extends TreasureBoxState {
  final DateTime foundAt;

  FoundState({required this.foundAt});
}

class OpenedState extends TreasureBoxState {
  final DateTime foundAt;
  final DateTime openedAt;

  OpenedState({required this.foundAt, required this.openedAt});
}
