# instant_camera

**instant_camera** is a Flutter package designed to simplify the process of capturing pictures and videos using the device's built-in camera interface. It aims to provide a straightforward and customizable solution for taking media content without the complexity often associated with default camera plugins.


## Features

- **Simple Integration**: Easily integrate camera functionality into your Flutter app with minimal setup.
- **Customizable Interface**: Customize styles and features like Zoom Slider, Icon for Flash, Image Thumbnail and more to match your app's design theme.
- **Gallery Integration**: Automatically saves captured images and videos to the device's gallery by default.
- **Responsive Design**: Responsive layout design ensures compatibility across various screen sizes.
- **User-Friendly**: Provides a user-friendly interface for capturing media content with intuitive controls.


## Demo

<img src="https://github.com/deb-sahu/instant_camera/assets/117360930/4cb17f75-2172-48f3-a9c2-292305fcd78b" width="350">

<img src="https://github.com/deb-sahu/instant_camera/assets/117360930/10381cb6-22e7-4124-87f2-6f703ee1598d" width="350">


## Usage

### Installation

To use **instant_camera** in your Flutter project, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  instant_camera: ^0.0.4  # Use the latest version
```

### Import

```dart
import 'package:flutter/material.dart';
import 'package:instant_camera/instant_camera_widget.dart';
```

### Basic Usage
To use the **instant_camera** package, simply integrate the `InstantCameraWidget` into your app's UI. Here's a basic example:

#### main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CameraManagerService().initializeCameras(); // Add this to initialize your device cameras
  runApp(const MyApp());
}
```

#### my_camera_screen.dart (Your implemenation file)
```dart
import 'package:flutter/material.dart';
import 'package:instant_camera/instant_camera_widget.dart';

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
```

## Configuration

### Android

#### AndroidManifest.xml
Make sure to add the following permission for accessing the camera:

```xml
<!-- Permission for accessing `camera` -->
<uses-permission android:name="android.permission.CAMERA"/>
```

#### build.gradle
Set the `minSdkVersion` to at least 21 in your `build.gradle` file:

```groovy
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 21
        ...
    }
    ...
}
```

### iOS

#### Info.plist
Add the following keys to your `Info.plist` file to request permission for camera usage and access to photo library:

```xml
<key>NSCameraPortraitEffectEnabled</key>
<true/>
<key>NSCameraUsageDescription</key>
<string>Required for clicking pictures</string>
<key>NSMicrophoneUsageDescription</key>
<string>Required for saving screen captures</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Required for saving photos</string>
<key>UIFileSharingEnabled</key>
<true/>
```

These instructions will guide users on how to configure their Android and iOS projects appropriately to use the **instant_camera** package.


## Getting Started
Explore the various customization options and features provided by **instant_camera** to enhance your camera interface and user experience.

For more details, check out the documentation for comprehensive usage instructions and examples.

## Feedback and Contributions
I welcome feedback, suggestions, and contributions to improve **instant_camera**. Feel free to open issues, submit pull requests, or reach out to me with your ideas and feedback.

Let's connect on linkedIn - https://www.linkedin.com/in/adarshh7/


