import 'package:treasure_ar_app/domain/entities/treasure_box.dart';
import 'package:treasure_ar_app/domain/repositories/treasure_box_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';

class TreasureBoxUseCase {
  final TreasureBoxRepository _repository;
  static const double _discoveryRange = 1.0; // 1メートル以内で発見可能

  TreasureBoxUseCase(this._repository);

  /// 指定された位置に宝箱を配置する
  Future<TreasureBox> placeTreasureBox(Position3D position) async {
    final treasureBox = TreasureBox.create(position: position);
    await _repository.save(treasureBox);
    return treasureBox;
  }

  /// IDで宝箱を検索する
  Future<TreasureBox?> findTreasureBox(String id) async {
    return await _repository.findById(id);
  }

  /// プレイヤーの位置で宝箱を発見する
  /// 発見範囲内にある場合のみ成功
  Future<TreasureBox?> discoverTreasureBox(
    String treasureBoxId,
    Position3D playerPosition,
  ) async {
    final treasureBox = await _repository.findById(treasureBoxId);

    if (treasureBox == null) {
      throw TreasureBoxNotFoundException(
        'Treasure box not found: $treasureBoxId',
      );
    }

    final distance = treasureBox.position.distanceTo(playerPosition);
    if (distance > _discoveryRange) {
      throw TreasureBoxTooFarException(
        'Treasure box is too far away: ${distance.toStringAsFixed(2)}m (max: ${_discoveryRange}m)',
      );
    }

    final discoveredBox = treasureBox.markAsFound();
    await _repository.save(discoveredBox);
    return discoveredBox;
  }

  /// 宝箱を開く
  Future<TreasureBox?> openTreasureBox(String treasureBoxId) async {
    final treasureBox = await _repository.findById(treasureBoxId);

    if (treasureBox == null) {
      throw TreasureBoxNotFoundException(
        'Treasure box not found: $treasureBoxId',
      );
    }

    final openedBox = treasureBox.open();
    await _repository.save(openedBox);
    return openedBox;
  }

  /// 指定されたエリア内の宝箱を取得する
  Future<List<TreasureBox>> getTreasureBoxesInArea(
    Position3D center,
    double radius,
  ) async {
    return await _repository.findByArea(center, radius);
  }

  /// すべての宝箱を取得する
  Future<List<TreasureBox>> getAllTreasureBoxes() async {
    return await _repository.findAll();
  }

  /// すべての宝箱を削除する
  Future<void> removeAllTreasureBoxes() async {
    await _repository.deleteAll();
  }

  /// 隠されている（未発見の）宝箱のみを取得する
  Future<List<TreasureBox>> getHiddenTreasureBoxes() async {
    final allBoxes = await _repository.findAll();
    return allBoxes.where((box) => box.isHidden).toList();
  }

  /// 発見済みの宝箱のみを取得する
  Future<List<TreasureBox>> getFoundTreasureBoxes() async {
    final allBoxes = await _repository.findAll();
    return allBoxes.where((box) => box.isFound).toList();
  }

  /// 開封済みの宝箱のみを取得する
  Future<List<TreasureBox>> getOpenedTreasureBoxes() async {
    final allBoxes = await _repository.findAll();
    return allBoxes.where((box) => box.isOpened).toList();
  }

  /// プレイヤーの近くの宝箱を検索する（発見可能範囲内）
  Future<List<TreasureBox>> getNearbyTreasureBoxes(
    Position3D playerPosition,
  ) async {
    return await getTreasureBoxesInArea(playerPosition, _discoveryRange);
  }

  /// 発見可能な範囲を取得する
  double get discoveryRange => _discoveryRange;
}

/// 宝箱が見つからない場合の例外
class TreasureBoxNotFoundException implements Exception {
  final String message;

  TreasureBoxNotFoundException(this.message);

  @override
  String toString() => 'TreasureBoxNotFoundException: $message';
}

/// 宝箱が発見範囲外にある場合の例外
class TreasureBoxTooFarException implements Exception {
  final String message;

  TreasureBoxTooFarException(this.message);

  @override
  String toString() => 'TreasureBoxTooFarException: $message';
}
