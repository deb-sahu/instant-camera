import 'package:flutter/material.dart';
import 'package:instant_camera/camera_manager_service.dart';
import 'package:instant_camera/instant_camera_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CameraManagerService().initializeCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My Camera App',
      debugShowCheckedModeBanner: false,
      home: MyCameraScreen(),
    );
  }
}

class MyCameraScreen extends StatelessWidget {
  const MyCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Screen'),
      ),
      body: const Center(
        child: InstantCameraWidget(), // This is the camera widget
      ),
    );
  }
}
