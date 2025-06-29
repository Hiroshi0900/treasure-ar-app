import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:treasure_ar_app/presentation/widgets/ar_controls.dart';
import 'package:treasure_ar_app/presentation/providers/game_provider.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  ARKitController? arKitController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().initializeGame();
    });
  }

  @override
  void dispose() {
    arKitController?.dispose();
    super.dispose();
  }

  void onARKitViewCreated(ARKitController controller) {
    arKitController = controller;
    
    final gameProvider = context.read<GameProvider>();
    gameProvider.setARKitController(controller);
    
    // ARセッション開始
    gameProvider.startARSession().then((_) {
      // 平面検出開始
      gameProvider.startPlaneDetection();
    });
  }


  void _placeTreasureBox() async {
    final gameProvider = context.read<GameProvider>();
    
    try {
      await gameProvider.placeTreasuresAutomatically();
      // placeTreasuresAutomatically 内で既に startTreasureHunt() が呼ばれているので重複呼び出しを防ぐ
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('宝探しを開始しました！')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR宝探し'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          if (gameProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(gameProvider.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

          return Stack(
            children: [
              ARKitSceneView(
                onARKitViewCreated: onARKitViewCreated,
                planeDetection: ARPlaneDetection.horizontalAndVertical,
                enableTapRecognizer: true,
              ),
              ARControls(
                isSessionReady: gameProvider.isARSessionActive,
                detectedPlanesCount: gameProvider.detectedPlanesCount,
                canPlaceTreasures: gameProvider.canPlaceTreasures,
                isHuntInProgress: gameProvider.isHuntInProgress,
                isGameCompleted: gameProvider.isGameCompleted,
                isLoading: gameProvider.isLoading,
                currentGameMode: gameProvider.currentGameState?.gameMode.isChildMode == true ? 'child' : 'adult',
                onPlaceTreasure: _placeTreasureBox,
                onSwitchToChildMode: () => gameProvider.switchToChildMode(),
                onResetGame: () => gameProvider.resetGame(),
                onShowHelp: () => ARControls.showHelpDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
