import 'package:camera/camera.dart';

/// A singleton class that manages the cameras available on the device.
class CameraManagerService {
  /// The list of available cameras on the device.
  List<CameraDescription>? _cameras;

  static final CameraManagerService _instance =
      CameraManagerService._internal();

  factory CameraManagerService() {
    return _instance;
  }

  CameraManagerService._internal();
  
  /// Initializes the available cameras on the device.
  Future<void> initializeCameras() async {
    if (_cameras == null) {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _cameras = [
          const CameraDescription(
            name: '0',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 0,
          ),
        ];
      }
    }
  }
  /// Returns the list of available cameras on the device.
  List<CameraDescription>? getAvailableCameras() {
    return _cameras;
  }
}
