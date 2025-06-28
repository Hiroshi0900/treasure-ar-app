import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:treasure_ar_app/presentation/widgets/ar_controls.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  ARKitController? arKitController;
  bool isSessionReady = false;
  int detectedPlanesCount = 0;

  @override
  void dispose() {
    arKitController?.dispose();
    super.dispose();
  }

  void onARKitViewCreated(ARKitController controller) {
    arKitController = controller;
    arKitController?.onAddNodeForAnchor = _handleAddAnchor;
    arKitController?.onUpdateNodeForAnchor = _handleUpdateAnchor;

    setState(() {
      isSessionReady = true;
    });
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      _addPlane(anchor);
      setState(() {
        detectedPlanesCount++;
      });
    }
  }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitPlaneAnchor) {
      _updatePlane(anchor);
    }
  }

  void _addPlane(ARKitPlaneAnchor planeAnchor) {
    final planeGeometry = ARKitPlane(
      width: planeAnchor.extent.x,
      height: planeAnchor.extent.z,
    );

    final planeNode = ARKitNode(geometry: planeGeometry);

    arKitController?.add(planeNode, parentNodeName: planeAnchor.nodeName);
  }

  void _updatePlane(ARKitPlaneAnchor planeAnchor) {
    // プレーンの更新処理（必要に応じて実装）
  }

  void _placeTreasureBox() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('宝箱を配置しました！')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR宝探し'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            planeDetection: ARPlaneDetection.horizontalAndVertical,
            enableTapRecognizer: true,
          ),
          ARControls(
            isSessionReady: isSessionReady,
            detectedPlanesCount: detectedPlanesCount,
            onPlaceTreasure: _placeTreasureBox,
          ),
        ],
      ),
    );
  }
}
