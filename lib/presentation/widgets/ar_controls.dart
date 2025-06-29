import 'package:flutter/material.dart';

class ARControls extends StatelessWidget {
  final bool isSessionReady;
  final int detectedPlanesCount;
  final bool canPlaceTreasures;
  final bool isHuntInProgress;
  final bool isGameCompleted;
  final bool isLoading;
  final String? currentGameMode;
  final VoidCallback onPlaceTreasure;
  final VoidCallback onSwitchToChildMode;
  final VoidCallback onResetGame;
  final VoidCallback? onShowHelp;

  const ARControls({
    super.key,
    required this.isSessionReady,
    required this.detectedPlanesCount,
    required this.canPlaceTreasures,
    required this.isHuntInProgress,
    required this.isGameCompleted,
    required this.isLoading,
    this.currentGameMode,
    required this.onPlaceTreasure,
    required this.onSwitchToChildMode,
    required this.onResetGame,
    this.onShowHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [_buildStatusBar(), const Spacer(), _buildControlButtons()],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade800.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isSessionReady
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSessionReady ? Colors.lightBlue.shade200 : Colors.orange.shade200,
              ),
              const SizedBox(width: 8),
              Text(
                isSessionReady ? 'ARセッション開始済み' : 'ARセッション準備中...',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.grid_on, color: Colors.lightBlue.shade200),
              const SizedBox(width: 8),
              Text(
                '検出された平面: $detectedPlanesCount',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          if (currentGameMode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  currentGameMode == 'child' ? Icons.child_care : Icons.person,
                  color: currentGameMode == 'child' ? Colors.orange.shade200 : Colors.lightBlue.shade200,
                ),
                const SizedBox(width: 8),
                Text(
                  '現在のモード: ${currentGameMode == 'child' ? '子供モード' : '大人モード'}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
          if (isHuntInProgress) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.search, color: Colors.green.shade200),
                const SizedBox(width: 8),
                const Text(
                  '宝探し中 - 宝箱をタップしてください！',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          
          if (isGameCompleted) ...[
            _buildCompletionMessage(),
            const SizedBox(height: 12),
            _buildResetButton(),
            const SizedBox(height: 12),
          ] else if (isHuntInProgress) ...[
            _buildHuntInProgressMessage(),
            const SizedBox(height: 12),
          ] else if (canPlaceTreasures) ...[
            _buildPlaceTreasureButton(),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: _buildChildModeButton(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResetButton(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHelpButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade600, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.blue.shade700, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'おめでとう！\nすべての宝箱を見つけました！',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHuntInProgressMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.blue, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '宝探し中...\n画面を動かして宝箱を探しましょう！',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceTreasureButton() {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPlaceTreasure,
      icon: const Icon(Icons.card_giftcard),
      label: const Text('宝探しを開始'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onResetGame,
      icon: const Icon(Icons.refresh),
      label: const Text('もう一度遊ぶ'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade400,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildChildModeButton() {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onSwitchToChildMode,
      icon: const Icon(Icons.child_care),
      label: const Text('子供モード'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlue.shade100,
        foregroundColor: Colors.blue.shade800,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildHelpButton() {
    return ElevatedButton.icon(
      onPressed: onShowHelp,
      icon: const Icon(Icons.help_outline),
      label: const Text('使い方'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  static void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('使い方'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎯 基本的な遊び方',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '1. 「宝探しを開始」ボタンを押す\n'
                  '2. スマホを動かして平面を検出\n'
                  '3. 宝箱が自動的に配置される\n'
                  '4. 画面を動かして宝箱を探す\n'
                  '5. 宝箱に近づくと発見できる\n'
                  '6. すべて見つけると完了！',
                ),
                SizedBox(height: 16),
                Text(
                  '👶 子供モードについて',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '• 宝箱の数が少なくなります（3個）\n'
                  '• 発見しやすくなります（範囲2.0m）\n'
                  '• 短時間（5分）で完結します\n'
                  '• 0-1歳のお子さまに最適',
                ),
                SizedBox(height: 16),
                Text(
                  '📱 注意事項',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '• 実機でのみAR機能が動作します\n'
                  '• 明るい場所で使用してください\n'
                  '• 平らな床や机の上で遊んでください\n'
                  '• 子供モードから大人モードへは長押し確認が必要',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
