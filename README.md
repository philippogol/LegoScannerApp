
# Lego Scanner App

This is an iOS application that uses a camera feed and a TensorFlow Lite model to classify Lego bricks in real time. The app provides visual feedback through a bounding box and displays the classification result along with its confidence level.

## Features

- **Real-Time Camera Feed**: Utilizes the device's camera to process live video frames.
- **TensorFlow Lite Model**: Supports multiple models for Lego brick classification.
- **Interactive UI**: Includes model selection and visual feedback.

## Prerequisites

- macOS with Xcode installed.
- An iOS device or simulator running iOS 14.0 or later.
- A TensorFlow Lite model file (`legocheck-model.tflite`).

## Installation and Setup

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/yourusername/legoscannerapp.git
   cd legoscannerapp
   ```

2. Open the project in Xcode:
   - Locate and open the file `LegoScannerApp.xcworkspace`.

3. Model file setup:
   - Ensure your TensorFlow Lite model file (`legocheck-model.tflite`) is added to the project. Place it in the project directory and include it in the Xcode project via the File Inspector.

4. Permissions:
   - The `info.plist` file is preconfigured with the necessary keys for camera and photo library access. If you need to customize these, check the following keys:
     - **Privacy - Camera Usage Description**: Describes the need for camera access.
     - **Privacy - Photo Library Additions Usage Description**: Describes the need for photo library access.

5. Build and run:
   - Connect a device or start a simulator.
   - Press `Cmd + R` in Xcode to build and launch the app.

## Usage

1. Launch the app on your device or simulator.
2. Select a model from the dropdown menu (if multiple are available).
3. Activate the camera feed to begin live classification.
4. Observe real-time results displayed at the bottom of the screen.

## Notes

- No license is currently applied to this repository.
- Feel free to download, test, and modify the app for personal use.
- Ensure you have granted camera and photo library permissions on your device.

## Download

To get started, simply clone the repository and follow the setup instructions.

```bash
git clone https://github.com/yourusername/legoscannerapp.git
```
