import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/repositories/treasure_box_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

/// メモリベースの宝箱リポジトリ実装
class MemoryTreasureBoxRepository implements TreasureBoxRepository {
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