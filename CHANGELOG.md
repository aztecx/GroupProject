# CHANGELOG
## Types of changes
- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features. 
- `Removed` for now removed features. 
- `Fixed` for any bug fixes. 
- `Security` in case of vulnerabilities.

## 14/03/2025
### Added @Jiwei
- Object Search Mode are fully functional.
- <ConvertNV21Image> for another kind of android camera.
- Set a rate limitation to <ConvertImage>.

## 11/03/2025
### Changed @Jiwei
- Optimized <_prepareInput> in yolo_service.dart
- Optimized <_convertYUV420ToImage> in homepage.dart

## 08/03/2025
### Added @Yide
- tts_service.dart
- stt_service.dart

### Added @Jiwei
- Filter for List<detections>
  - only announce the object with highest frequency in the past 5 frames.
- Timer for tts.speak, added a time gap between each announcement.

### Changed @Assem
- Input size is now 320 (was 640)


## 06/03/2025
### Fixed @Yide
- image input for text model
- mode switch

## 05/03/2025
### Added @Yide
- Integrate text recognition with original homepage

### Added @Jiwei
- convertImage to RGB in iOS and Android

### Changed @Jiwei
- Image resized method
- Replace <takePicture> with <ImageStream>

## 04/03/2025
### Fixed @Assem
- label incorrect

## 01/03/2025
### Added @Yide
- Text recognition

### Changed @Yide
- update  yolo_service

### Fixed @Yide
- Two same function: <label> and <_label>

## 10/02/2025 
### Added @Jiwei
- .gitignore created
- Integrated YOLO for object detection
- Loaded the dataset, randomly selecting an image for detection.
- Printed detected object information in the terminal (name, confidence, coordinates)
- Display information of each boxes.
  - Dynamic font size
