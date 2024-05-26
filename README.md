## instant_camera

**instant_camera** is a Flutter package designed to simplify the process of capturing pictures and videos using the device's built-in camera interface. It aims to provide a straightforward and customizable solution for taking media content without the complexity often associated with default camera plugins.

### Features

- **Simple Integration**: Easily integrate camera functionality into your Flutter app with minimal setup.
- **Customizable Interface**: Customize styles, text, background colors, and more to match your app's design theme.
- **Gallery Integration**: Automatically saves captured images and videos to the device's gallery by default.
- **Responsive Design**: Responsive layout design ensures compatibility across various screen sizes.
- **User-Friendly**: Provides a user-friendly interface for capturing media content with intuitive controls.


## Usage

### Installation

To use **instant_camera** in your Flutter project, add it to your `pubspec.yaml` file:

```yaml
dependencies:
  instant_camera: ^1.0.0  # Use the latest version
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

## Getting Started
Explore the various customization options and features provided by **instant_camera** to enhance your camera interface and user experience.

For more details, check out the documentation for comprehensive usage instructions and examples.

## Feedback and Contributions
I welcome feedback, suggestions, and contributions to improve **instant_camera**. Feel free to open issues, submit pull requests, or reach out to me with your ideas and feedback through LinkedIn - https://www.linkedin.com/in/adarshh7/.


