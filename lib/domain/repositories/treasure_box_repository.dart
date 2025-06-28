import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

abstract class TreasureBoxRepository {
  Future<void> save(TreasureBox treasureBox);

  Future<TreasureBox?> findById(String id);

  Future<List<TreasureBox>> findAll();

  Future<List<TreasureBox>> findByArea(Position3D center, double radius);

  Future<void> delete(String id);

  Future<void> deleteAll();
}
