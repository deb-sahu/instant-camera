library instant_camera;

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:instant_camera/camera_manager_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// The CameraWidget class is a stateful widget that provides a camera interface
class InstantCameraWidget extends StatefulWidget {
  /// Camera interface
  /// **Required**
  /// Make sure to add the camera permissions in the AndroidManifest.xml and Info.plist files
  /// Also, add the following in the main.dart file-
  /// ```dart
  /// await CameraManagerService().initializeCameras();
  /// ```
  /// **Optional**
  /// -[bool] showFlashMode: Show flash mode button (default: true)
  /// -[bool] showToggleCamera: Show toggle camera button (default: true)
  /// -[bool] showZoomSlider: Show zoom slider (default: true)
  /// -[bool] showThumbnail: Show thumbnail of the captured image (default: true)
  /// -[int] thumbnailDuration: Duration for which the thumbnail will be displayed in seconds (default: 2)
  /// -[String] imageNamePrefix: Prefix for the image name (default: 'image')
  ///
  /// **Example**
  /// ```dart
  /// import 'package:instant_camera/instant_camera.dart';
  /// InstantCameraWidget(
  /// showFlashMode: true,
  /// showToggleCamera: true,
  /// showZoomSlider: true,
  /// showThumbnail: true
  /// );
  /// ```
  final bool showFlashMode;
  final bool showToggleCamera;
  final bool showZoomSlider;
  final bool showThumbnail;
  final int thumbnailDuration;
  final String? imageNamePrefix;

  const InstantCameraWidget({
    super.key,
    this.showFlashMode = true,
    this.showToggleCamera = true,
    this.showZoomSlider = true,
    this.showThumbnail = true,
    this.thumbnailDuration = 2,
    this.imageNamePrefix,
  });

  @override
  // ignore: library_private_types_in_public_api
  _InstantCameraWidgetState createState() => _InstantCameraWidgetState();
}

class _InstantCameraWidgetState extends State<InstantCameraWidget>
    with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;

  FlashMode? _currentFlashMode;
  bool _isRearCameraSelected = true;

  File? capturedImage;
  bool isImageCaptured = false;
  Timer? thumbnailTimer;

  bool _isVideoCameraSelected = false;
  bool _isRecordingInProgress = false;

  final cameras = CameraManagerService().getAvailableCameras();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void initState() {
    super.initState();
    if (cameras?.isNotEmpty == true) {
      onNewCameraSelected(cameras![0]);
    } else {
      CameraManagerService().initializeCameras().then((_) {
        onNewCameraSelected(CameraManagerService().getAvailableCameras()![0]);
      });
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await previousCameraController?.dispose();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      throw UnimplementedError('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }

    cameraController
        .getMaxZoomLevel()
        .then((value) => _maxAvailableZoom = value);
    cameraController
        .getMinZoomLevel()
        .then((value) => _minAvailableZoom = value);
    _currentFlashMode = controller!.value.flashMode;
  }

  Future<void> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      return;
    }
    try {
      XFile file = await cameraController.takePicture();
      setState(() {
        capturedImage = File(file.path);
        isImageCaptured = true;
      });

      thumbnailTimer?.cancel();
      thumbnailTimer = Timer(Duration(seconds: widget.thumbnailDuration), () {
        setState(() {
          capturedImage = null;
          isImageCaptured = false;
        });
      });

      // Get the directory for saving images based on the platform
      Directory directory;
      String fileFormat = 'jpeg';
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        throw UnimplementedError("Platform not supported");
      }

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      String imagePath =
          '${directory.path}/${widget.imageNamePrefix ?? 'image'}${DateTime.now().millisecondsSinceEpoch}.$fileFormat';
      await File(file.path).copy(imagePath);

      // Using gallery_saver to save the image
      GallerySaver.saveImage(imagePath);
    } catch (e) {
      throw UnimplementedError('Error occured while taking picture: $e');
    }
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;
    if (controller!.value.isRecordingVideo) {
      // A recording has already started, do nothing.
      return;
    }
    try {
      await cameraController!.startVideoRecording();
      setState(() {
        _isRecordingInProgress = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording started'),
          ),
        );
      });
    } on CameraException catch (e) {
      throw UnimplementedError("Error starting video recording: $e");
    }
  }

  Future<XFile?> stopVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Recording is already is stopped state
      return null;
    }
    try {
      XFile file = await controller!.stopVideoRecording();
      setState(() {
        _isRecordingInProgress = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording stopped'),
          ),
        );
      });
      return file;
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error stopping video recording: $e');
      }
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // Video recording is not in progress
      return;
    }
    try {
      await controller!.pauseVideoRecording();
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error pausing video recording: $e');
      }
    }
  }

  Future<void> resumeVideoRecording() async {
    if (!controller!.value.isRecordingVideo) {
      // No video recording was in progress
      return;
    }
    try {
      await controller!.resumeVideoRecording();
    } on CameraException catch (e) {
      if (kDebugMode) {
        print('Error resuming video recording: $e');
      }
    }
  }

  Future<void> toggleVideoRecording() async {
    if (_isRecordingInProgress) {
      XFile? rawVideo = await stopVideoRecording();
      File videoFile = File(rawVideo!.path);

      // Get the directory for saving images based on the platform
      Directory directory;
      String fileFormat = 'mp4';
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        throw UnimplementedError("Platform not supported");
      }

      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      // Copy the image to the desired directory
      String videoPath =
          '${directory.path}/video_${DateTime.now().millisecondsSinceEpoch}.$fileFormat';
      await videoFile.copy(videoPath);

      // Save video file code goes here
      GallerySaver.saveVideo(videoPath);
    } else {
      await startVideoRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, elevation: 2.0),
      body: SafeArea(
        minimum: const EdgeInsets.all(1.0),
        child: Stack(
          children: [
            SizedBox(
              height: height,
              width: width,
              child: _isCameraInitialized
                  ? AspectRatio(
                      aspectRatio: isLandscape
                          ? controller!.value.aspectRatio / 0.65
                          : 1 / controller!.value.aspectRatio,
                      child: controller!.buildPreview(),
                    )
                  : const Center(
                      child: Text('Camera Loading...',
                          style: TextStyle(color: Colors.black, fontSize: 20)),
                    ),
            ),
            if (widget.showThumbnail && isImageCaptured)
              Positioned(
                top: height * 0.02,
                left: width * 0.06,
                child: Image.file(
                  capturedImage!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.showFlashMode)
              Positioned(
                bottom: height * 0.08,
                left: width * 0.1,
                child: InkWell(
                  onTap: () async {
                    setState(() {
                      _currentFlashMode = getNextFlashMode(_currentFlashMode!);
                    });
                    await controller!.setFlashMode(_currentFlashMode!);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Colors.black45,
                        size: 60,
                      ),
                      Icon(
                        getFlashIcon(),
                        color: Colors.white,
                        size: 25,
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.showToggleCamera)
              Positioned(
                bottom: height * 0.08,
                right: width * 0.1,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isCameraInitialized = false;
                    });
                    onNewCameraSelected(
                      cameras![_isRearCameraSelected ? 0 : 1],
                    );
                    setState(() {
                      _isRearCameraSelected = !_isRearCameraSelected;
                    });
                  },
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        color: Colors.black45,
                        size: 60,
                      ),
                      Icon(
                        Icons.flip_camera_ios_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.showZoomSlider)
              Positioned(
                bottom: height * 0.22,
                left: width * 0.1,
                width: width * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Slider(
                        value: _currentZoomLevel,
                        min: _minAvailableZoom,
                        max: _maxAvailableZoom,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.white,
                        onChanged: (value) async {
                          setState(() {
                            _currentZoomLevel = value;
                          });
                          await controller!.setZoomLevel(value);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${_currentZoomLevel.toStringAsFixed(1)}x',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: height * 0.025,
              width: width * 0.5,
              left: width * 0.25,
              child: InkWell(
                key: const Key('captureButton'),
                onTap: _isVideoCameraSelected
                    ? () async {
                        await toggleVideoRecording();
                      }
                    : () async {
                        await takePicture();
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: _isVideoCameraSelected
                          ? Colors.white
                          : Colors.white38,
                      size: 80,
                    ),
                    Icon(
                      Icons.circle,
                      color: _isVideoCameraSelected ? Colors.red : Colors.white,
                      size: 65,
                    ),
                    _isVideoCameraSelected && _isRecordingInProgress
                        ? const Icon(
                            Icons.stop_rounded,
                            color: Colors.white,
                            size: 32,
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      right: 4.0,
                    ),
                    child: TextButton(
                      onPressed: _isRecordingInProgress
                          ? null
                          : () {
                              if (_isVideoCameraSelected) {
                                setState(() {
                                  _isVideoCameraSelected = false;
                                });
                              }
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: _isVideoCameraSelected
                            ? Colors.black54
                            : Colors.black,
                        backgroundColor: _isVideoCameraSelected
                            ? Colors.white30
                            : Colors.white,
                      ),
                      child: const Text('IMAGE'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 8.0),
                    child: TextButton(
                      onPressed: () {
                        if (!_isVideoCameraSelected) {
                          setState(() {
                            _isVideoCameraSelected = true;
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _isVideoCameraSelected
                            ? Colors.black
                            : Colors.black54,
                        backgroundColor: _isVideoCameraSelected
                            ? Colors.white
                            : Colors.white30,
                      ),
                      child: const Text('VIDEO'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
      default:
        return Icons.flash_off;
    }
  }

  FlashMode getNextFlashMode(FlashMode currentMode) {
    switch (currentMode) {
      case FlashMode.off:
        return FlashMode.auto;
      case FlashMode.auto:
        return FlashMode.always;
      case FlashMode.always:
        return FlashMode.torch;
      case FlashMode.torch:
        return FlashMode.off;
      default:
        return FlashMode.off;
    }
  }
}
