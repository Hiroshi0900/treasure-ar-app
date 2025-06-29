import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:audioplayers/audioplayers.dart';
import 'package:treasure_ar_app/application/use_cases/integrated_game_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/ar_session_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/treasure_box_usecase.dart';
import 'package:treasure_ar_app/application/use_cases/game_mode_usecase.dart';
import 'package:treasure_ar_app/infrastructure/repositories/memory_ar_session_repository.dart';
import 'package:treasure_ar_app/infrastructure/repositories/memory_treasure_box_repository.dart';
import 'package:treasure_ar_app/infrastructure/repositories/memory_game_mode_repository.dart';
import 'package:treasure_ar_app/domain/value_objects/position_3d.dart';
import 'package:treasure_ar_app/domain/entities/treasure_box.dart';

/// ゲーム全体の状態を管理するプロバイダー
class GameProvider extends ChangeNotifier with WidgetsBindingObserver {
  late final IntegratedGameUseCase _integratedGameUseCase;
  late final TreasureBoxUseCase _treasureBoxUseCase;
  late final MemoryARSessionRepository _arRepository;
  late final MemoryTreasureBoxRepository _treasureRepository;
  late final MemoryGameModeRepository _gameModeRepository;

  GameState? _currentGameState;
  String? _errorMessage;
  bool _isLoading = false;
  ARKitController? _arkitController;  // ARKitコントローラー
  final Map<String, ARKitNode> _treasureNodes = {};  // 宝箱のARノードを管理
  final AudioPlayer _audioPlayer = AudioPlayer();  // 音響効果プレイヤー

  GameProvider() {
    _initializeRepositories();
    _initializeUseCases();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeRepositories() {
    _arRepository = MemoryARSessionRepository();
    _treasureRepository = MemoryTreasureBoxRepository();
    _gameModeRepository = MemoryGameModeRepository();
  }

  void _initializeUseCases() {
    final arSessionUseCase = ARSessionUseCase(_arRepository);
    _treasureBoxUseCase = TreasureBoxUseCase(_treasureRepository);
    final gameModeUseCase = GameModeUseCase(_gameModeRepository);

    _integratedGameUseCase = IntegratedGameUseCase(
      arSessionUseCase: arSessionUseCase,
      treasureBoxUseCase: _treasureBoxUseCase,
      gameModeUseCase: gameModeUseCase,
    );
  }

  // Getters
  GameState? get currentGameState => _currentGameState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isARSessionActive => _currentGameState?.isARSessionActive ?? false;
  int get detectedPlanesCount => _currentGameState?.detectedPlanes.length ?? 0;
  bool get canPlaceTreasures => _currentGameState?.status == GameStatus.readyForTreasurePlacement;
  bool get isHuntInProgress => _currentGameState?.status == GameStatus.huntInProgress;
  bool get isGameCompleted => _currentGameState?.status == GameStatus.completed;

  /// ARKitControllerを設定
  void setARKitController(ARKitController controller) {
    _arkitController = controller;
    _arRepository.setARKitController(controller);
    
    // ARKit平面検出のコールバックを設定
    controller.onAddNodeForAnchor = _handleAddAnchor;
    controller.onUpdateNodeForAnchor = _handleUpdateAnchor;
    
    // タップハンドラーを設定
    controller.onNodeTap = _handleNodeTap;
  }

  /// ゲーム初期化
  Future<void> initializeGame() async {
    await _executeWithErrorHandling(() async {
      debugPrint('Initializing game...');
      
      // 初期化時に古い宝箱をクリア
      _removeAllTreasureNodes();
      await _treasureRepository.deleteAll();
      
      _currentGameState = await _integratedGameUseCase.initializeGame();
      
      debugPrint('Game initialized');
    });
  }

  /// ARセッション開始
  Future<void> startARSession() async {
    await _executeWithErrorHandling(() async {
      _currentGameState = await _integratedGameUseCase.startARSession();
    });
  }

  /// 平面検出待機（バックグラウンドで実行）
  void startPlaneDetection() {
    _integratedGameUseCase.waitForPlaneDetection().then((gameState) {
      _currentGameState = gameState;
      notifyListeners();
    }).catchError((error) {
      _setError('平面検出に失敗しました: $error');
    });
  }

  /// 宝箱自動配置
  Future<void> placeTreasuresAutomatically() async {
    await _executeWithErrorHandling(() async {
      debugPrint('Starting treasure placement...');
      
      _currentGameState = await _integratedGameUseCase.placeTreasuresAutomatically();
      debugPrint('Treasures placed in use case, status: ${_currentGameState?.status}');
      
      // AR空間に宝箱の3Dモデルを追加
      if (_currentGameState != null) {
        await _addTreasureNodesToARScene();
        debugPrint('Treasure nodes added to AR scene');
        
        // 宝探しを自動的に開始
        _currentGameState = await _integratedGameUseCase.startTreasureHunt();
        debugPrint('Treasure hunt started, final status: ${_currentGameState?.status}');
        
        // UI更新を即座に通知
        notifyListeners();
      }
    });
  }

  /// 宝探し開始
  Future<void> startTreasureHunt() async {
    await _executeWithErrorHandling(() async {
      _currentGameState = await _integratedGameUseCase.startTreasureHunt();
    });
  }

  /// プレイヤー位置での宝箱発見チェック
  Future<void> checkForTreasureDiscovery(Position3D playerPosition) async {
    if (!isHuntInProgress) return;

    await _executeWithErrorHandling(() async {
      _currentGameState = await _integratedGameUseCase.checkForTreasureDiscovery(playerPosition);
    });
  }

  /// 宝箱開封
  Future<void> openTreasure(String treasureId) async {
    await _executeWithErrorHandling(() async {
      _currentGameState = await _integratedGameUseCase.openTreasure(treasureId);
      
      // ゲーム完了チェック
      _currentGameState = await _integratedGameUseCase.checkGameCompletion();
    });
  }

  /// ゲームリセット
  Future<void> resetGame() async {
    await _executeWithErrorHandling(() async {
      debugPrint('Resetting game...');
      
      // AR空間から宝箱を削除
      _removeAllTreasureNodes();
      
      // リポジトリからも宝箱を完全削除
      await _treasureRepository.deleteAll();
      
      _currentGameState = await _integratedGameUseCase.resetGame();
      
      debugPrint('Game reset completed');
    });
  }

  /// 子供モードに切り替え
  Future<void> switchToChildMode() async {
    await _executeWithErrorHandling(() async {
      debugPrint('Switching to child mode...');
      
      // 現在の状態を確認
      debugPrint('Current game state before switch: ${_currentGameState?.status}');
      debugPrint('Current game mode: ${_currentGameState?.gameMode.state}');
      debugPrint('Hunt in progress: $isHuntInProgress');
      debugPrint('Available treasures: ${_treasureNodes.length}');
      
      // 宝箱が配置されていない場合はまず配置する
      if (_treasureNodes.isEmpty) {
        debugPrint('No treasures placed yet, placing treasures first...');
        await placeTreasuresAutomatically();
      }
      
      // GameModeUseCaseを直接使用して子供モードに切り替え
      final gameModeUseCase = GameModeUseCase(_gameModeRepository);
      final childMode = await gameModeUseCase.switchToChildMode();
      debugPrint('Child mode result: $childMode');
      debugPrint('Child mode state: ${childMode.state}');
      debugPrint('Is child mode: ${childMode.isChildMode}');
      
      // 新しいゲーム状態を作成（必ず子供モードの状態で）
      _currentGameState = _currentGameState!.copyWith(
        gameMode: childMode,
        status: GameStatus.huntInProgress, // 子供モードではすぐに宝探し開始
      );
      
      debugPrint('Game state updated to child mode');
      debugPrint('Final game state mode: ${_currentGameState!.gameMode.state}');
      debugPrint('Final verification - Is child mode: ${_currentGameState!.gameMode.isChildMode}');
      
      // IntegratedGameUseCaseにも子供モードを反映
      await _integratedGameUseCase.setGameMode(childMode);
      debugPrint('UseCase game mode updated');
      
      // 既存の宝箱ノードを更新（タップ可能にする）
      await _updateTreasureNodesForChildMode();
      debugPrint('Treasure nodes updated for child mode');
      
      // 状態を強制的に更新
      notifyListeners();
      debugPrint('Child mode switch completed successfully');
    });
  }

  /// ゲーム統計取得
  Future<GameStatistics?> getGameStatistics() async {
    try {
      return await _integratedGameUseCase.getGameStatistics();
    } catch (error) {
      _setError('統計取得に失敗しました: $error');
      return null;
    }
  }

  /// ARPlaneAnchor追加時のコールバック
  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      final plane = _arRepository.convertARKitPlane(anchor);
      _arRepository.addPlane(plane);
      
      // 平面検出状態の更新
      _updateGameStateFromRepository();
    }
  }

  /// ARPlaneAnchor更新時のコールバック
  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      final plane = _arRepository.convertARKitPlane(anchor);
      _arRepository.updatePlane(plane);
      
      // 平面検出状態の更新
      _updateGameStateFromRepository();
    }
  }

  /// リポジトリからゲーム状態を更新
  Future<void> _updateGameStateFromRepository() async {
    try {
      _currentGameState = await _integratedGameUseCase.getCurrentGameState();
      notifyListeners();
    } catch (error) {
      // エラーは静かに処理（ログ出力のみ）
      debugPrint('Failed to update game state: $error');
    }
  }

  /// エラーハンドリング付きでメソッドを実行
  Future<void> _executeWithErrorHandling(Future<void> Function() operation) async {
    _setLoading(true);
    _clearError();

    try {
      await operation();
    } catch (error, stackTrace) {
      debugPrint('Error in operation: $error');
      debugPrint('Stack trace: $stackTrace');
      
      // 特定のエラーに対する詳細な処理
      if (error.toString().contains('InvalidGameException')) {
        debugPrint('InvalidGameException detected - resetting game state');
        // ゲーム状態をリセット
        _removeAllTreasureNodes();
        await _treasureRepository.deleteAll();
        try {
          _currentGameState = await _integratedGameUseCase.initializeGame();
        } catch (resetError) {
          debugPrint('Failed to reset game state: $resetError');
        }
      }
      
      _setError('操作中にエラーが発生しました: ${error.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// AR空間に宝箱の3Dモデルを追加
  Future<void> _addTreasureNodesToARScene() async {
    if (_arkitController == null) {
      debugPrint('ARKitController is null - cannot add treasure nodes');
      return;
    }
    
    final treasures = await _treasureRepository.findAll();
    debugPrint('Adding ${treasures.length} treasures to AR scene');
    
    for (final treasure in treasures) {
      if (treasure.isHidden) {
        debugPrint('Adding treasure node: ${treasure.id} at position ${treasure.position}');
        _addTreasureNode(treasure);
      }
    }
    
    debugPrint('Total treasure nodes in scene: ${_treasureNodes.length}');
  }

  /// 個別の宝箱ノードを追加
  void _addTreasureNode(TreasureBox treasure) {
    if (_arkitController == null) return;
    
    // 宝箱の3Dモデル（ボックス形状）を作成
    final material = ARKitMaterial(
      diffuse: ARKitMaterialProperty.color(Colors.amber.shade700),
      metalness: ARKitMaterialProperty.value(0.5),
      roughness: ARKitMaterialProperty.value(0.3),
      lightingModelName: ARKitLightingModel.physicallyBased,
    );
    
    // 宝箱のジオメトリ（立方体）
    final box = ARKitBox(
      width: 0.08,  // 8cm (0-1歳児の手に合うサイズ)
      height: 0.08,
      length: 0.08,
      materials: [material],
    );
    
    // 宝箱ノードを作成
    final node = ARKitNode(
      name: treasure.id,
      geometry: box,
      position: vector.Vector3(
        treasure.position.x,
        treasure.position.y + 0.04,  // 箱の半分の高さ分上げる
        treasure.position.z,
      ),
    );
    
    // アニメーション（上下に揺れる）を追加
    _addFloatingAnimation(node);
    
    // 子供モードでのみタップ可能にする視覚的フィードバック
    if (_currentGameState?.gameMode.isChildMode == true) {
      // 光るエフェクトを追加（オプション）
      node.eulerAngles = vector.Vector3(0, 0, 0);
    }
    
    // ARシーンに追加
    _arkitController!.add(node);
    _treasureNodes[treasure.id] = node;
  }

  /// 宝箱に浮遊アニメーションを追加
  void _addFloatingAnimation(ARKitNode node) {
    // 実装は後で追加可能（オプション）
  }

  /// 宝箱タップ時の処理
  void _handleTreasureTap(String treasureId) async {
    if (!isHuntInProgress) return;
    
    // タップフィードバック（即座に視覚的な反応）
    _showTapFeedback(treasureId);
    
    // 子供モードでは簡素化された宝箱処理
    await _handleChildModeTreasure(treasureId);
    
    // エフェクトを表示
    _showTreasureFoundEffect(treasureId);
    
    // ノードを削除
    _removeTreasureNode(treasureId);
  }
  
  /// 子供モード専用の宝箱処理（発見から開封まで一気に）
  Future<void> _handleChildModeTreasure(String treasureId) async {
    await _executeWithErrorHandling(() async {
      debugPrint('Child mode treasure handling for: $treasureId');
      
      // 宝箱を直接取得して状態を更新
      final treasure = await _treasureRepository.findById(treasureId);
      if (treasure == null) {
        debugPrint('Treasure not found: $treasureId');
        return;
      }
      
      // 子供モードでは位置に関係なく発見できる
      try {
        // まず発見状態にする
        await _treasureBoxUseCase.discoverTreasureBox(treasureId, Position3D.fromXYZ(0, 0, 0));
        debugPrint('Treasure discovered: $treasureId');
        
        // 次に開封する
        await _treasureBoxUseCase.openTreasureBox(treasureId);
        debugPrint('Treasure opened: $treasureId');
        
        // ゲーヤ状態を更新
        _currentGameState = await _integratedGameUseCase.checkGameCompletion();
        
      } catch (e) {
        debugPrint('Error in child mode treasure handling: $e');
        // エラーが発生しても直接削除して続行
      }
    });
  }

  /// タップフィードバック（即座の視覚反応）
  void _showTapFeedback(String treasureId) {
    if (_arkitController != null && _treasureNodes.containsKey(treasureId)) {
      final node = _treasureNodes[treasureId]!;
      
      debugPrint('Showing tap feedback for treasure: $treasureId');
      
      // 簡単なスケール変更でフィードバック
      node.scale = vector.Vector3(1.5, 1.5, 1.5);
      
      // 少し待ってから元のサイズに戻す
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_treasureNodes.containsKey(treasureId)) {
          _treasureNodes[treasureId]!.scale = vector.Vector3(1.2, 1.2, 1.2);
        }
      });
    }
  }

  /// 宝箱発見エフェクト
  void _showTreasureFoundEffect(String treasureId) {
    // 音を再生
    _playSound('treasure_found');
    
    debugPrint('宝箱発見！: $treasureId');
  }
  
  /// 音を再生
  Future<void> _playSound(String soundType) async {
    try {
      // 音声ファイルがない場合はシステムサウンドを使用しない
      // 将来的に音声ファイルを追加する際に有効化
      debugPrint('音声再生: $soundType (現在は音声ファイルなし)');
      
      /*
      switch (soundType) {
        case 'treasure_found':
          await _audioPlayer.play(AssetSource('sounds/success.mp3'));
          break;
        case 'tap':
          await _audioPlayer.play(AssetSource('sounds/tap.mp3'));
          break;
      }
      */
    } catch (e) {
      debugPrint('音声再生エラー: $e');
    }
  }

  /// 特定の宝箱ノードを削除
  void _removeTreasureNode(String treasureId) {
    if (_arkitController != null && _treasureNodes.containsKey(treasureId)) {
      _arkitController!.remove(_treasureNodes[treasureId]!.name);
      _treasureNodes.remove(treasureId);
    }
  }

  /// すべての宝箱ノードを削除
  void _removeAllTreasureNodes() {
    if (_arkitController != null) {
      for (final nodeEntry in _treasureNodes.entries) {
        _arkitController!.remove(nodeEntry.value.name);
      }
      _treasureNodes.clear();
    }
  }

  /// ノードタップハンドラー
  void _handleNodeTap(List<String> nodeNames) {
    debugPrint('Node tap detected: $nodeNames');
    debugPrint('Current game mode: ${_currentGameState?.gameMode}');
    debugPrint('Game mode state: ${_currentGameState?.gameMode.state}');
    debugPrint('Hunt in progress: $isHuntInProgress');
    debugPrint('Available treasure nodes: ${_treasureNodes.keys.toList()}');
    
    // 子供モードかどうかの確認を修正
    final isChildMode = _currentGameState?.gameMode.isChildMode ?? false;
    debugPrint('Is child mode: $isChildMode');
    
    if (!isChildMode) {
      debugPrint('Not in child mode - ignoring tap');
      return;
    }
    
    if (!isHuntInProgress) {
      debugPrint('Hunt not in progress - ignoring tap');
      return;
    }
    
    for (final nodeName in nodeNames) {
      if (_treasureNodes.containsKey(nodeName)) {
        debugPrint('Handling treasure tap: $nodeName');
        _handleTreasureTap(nodeName);
        break; // 最初にタップされた宝箱のみ処理
      }
    }
  }

  /// 子供モード用に宝箱ノードを更新
  Future<void> _updateTreasureNodesForChildMode() async {
    // 既存の宝箱の見た目を変更（より目立つように）
    final nodesCopy = Map<String, ARKitNode>.from(_treasureNodes);
    
    for (final entry in nodesCopy.entries) {
      final treasureId = entry.key;
      final node = entry.value;
      
      // 古いノードを削除
      _arkitController!.remove(treasureId);
      
      // より鮮やかな色に変更
      final material = ARKitMaterial(
        diffuse: ARKitMaterialProperty.color(Colors.orange),
        metalness: ARKitMaterialProperty.value(0.7),
        roughness: ARKitMaterialProperty.value(0.2),
        lightingModelName: ARKitLightingModel.physicallyBased,
      );
      
      // 新しいボックスを作成（少し大きめ）
      final box = ARKitBox(
        width: 0.1,  // 10cm (子供モード用に少し大きく)
        height: 0.1,
        length: 0.1,
        materials: [material],
      );
      
      // 新しいノードを作成
      final newNode = ARKitNode(
        name: treasureId,
        geometry: box,
        position: node.position,
      );
      
      // ARシーンに追加
      _arkitController!.add(newNode);
      _treasureNodes[treasureId] = newNode;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    debugPrint('App lifecycle state changed to: $state');
    
    // アプリがバックグラウンドに移行した場合、宝箱をクリア
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      debugPrint('App going to background - clearing treasures');
      _handleAppBackground();
    }
  }

  /// アプリがバックグラウンドに移行した時の処理
  void _handleAppBackground() {
    _removeAllTreasureNodes();
    
    // ゲーム状態もリセット
    _executeWithErrorHandling(() async {
      await _treasureRepository.deleteAll();
      _currentGameState = await _integratedGameUseCase.resetGame();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeAllTreasureNodes();
    _audioPlayer.dispose();
    _arRepository.dispose();
    _gameModeRepository.dispose();
    super.dispose();
  }
}