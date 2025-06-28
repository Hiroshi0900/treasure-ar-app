import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';

class ARCameraView extends StatefulWidget {
  final Function(ARKitController) onControllerCreated;
  final bool enablePlaneDetection;
  final bool enableTapRecognizer;

  const ARCameraView({
    super.key,
    required this.onControllerCreated,
    this.enablePlaneDetection = true,
    this.enableTapRecognizer = true,
  });

  @override
  State<ARCameraView> createState() => _ARCameraViewState();
}

class _ARCameraViewState extends State<ARCameraView> {
  late ARKitController arKitController;

  @override
  Widget build(BuildContext context) {
    return ARKitSceneView(
      onARKitViewCreated: (controller) {
        arKitController = controller;
        widget.onControllerCreated(controller);
      },
      planeDetection: widget.enablePlaneDetection
          ? ARPlaneDetection.horizontalAndVertical
          : ARPlaneDetection.none,
      enableTapRecognizer: widget.enableTapRecognizer,
    );
  }

  @override
  void dispose() {
    arKitController.dispose();
    super.dispose();
  }
}
