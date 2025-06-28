import 'package:flutter/material.dart';

class ARControls extends StatelessWidget {
  final bool isSessionReady;
  final int detectedPlanesCount;
  final VoidCallback onPlaceTreasure;

  const ARControls({
    super.key,
    required this.isSessionReady,
    required this.detectedPlanesCount,
    required this.onPlaceTreasure,
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
        color: Colors.black54,
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
                color: isSessionReady ? Colors.green : Colors.orange,
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
              const Icon(Icons.grid_on, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '検出された平面: $detectedPlanesCount',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
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
          if (detectedPlanesCount > 0) ...[
            ElevatedButton.icon(
              onPressed: onPlaceTreasure,
              icon: const Icon(Icons.card_giftcard),
              label: const Text('宝箱を配置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: () {
              // TODO: ヘルプ画面を表示
            },
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
          ),
        ],
      ),
    );
  }
}
