# speaksightgroup

A new Flutter project.

## Installation Instructions for Mentors

To run this app on your device, please follow these steps:

### 1. Environment Setup

```bash
# Install Flutter SDK
# For macOS
brew install flutter

# For Windows (using Chocolatey)
choco install flutter

# For Linux
sudo snap install flutter --classic

# Verify installation
flutter doctor
```

### 2. Clone the Repository <main> branch

```bash
git clone https://github.com/aztecx/GroupProject.git
cd speaksightGroup
```

### 3. Get Dependencies

```bash
flutter pub get
```

### 4. Run on Your Device

#### For Android

1. Enable Developer Options and USB Debugging on your Android device:
   - Go to Settings > About Phone > Tap "Build Number" 7 times
   - Return to Settings > Developer Options > Enable "USB Debugging"

2. Connect your Android device via USB and allow USB debugging when prompted.

3. Verify your device is recognized:
```bash
flutter devices
```

4. Run the app:
```bash
flutter run
```

#### For iOS

1. Install Xcode (macOS only):
```bash
xcode-select --install
```

2. Install CocoaPods:
```bash
sudo gem install cocoapods
```

3. Connect your iOS device via USB.

4. Trust your computer on your iOS device when prompted.

5. Open iOS folder in Xcode:
```bash
open ios/Runner.xcworkspace
```

6. In Xcode:
   - Select your device from the device dropdown
   - Sign in with your Apple ID in Xcode > Preferences > Accounts
   - Update bundle identifier in project settings if needed
   - Click the Run button or use Command+R

Alternatively, after setup is complete, you can run directly from command line:
```bash
flutter run
```

**Note:** Detailed instructions on how to use the app are provided within the app itself.

## See [Flutter tutorial](https://docs.flutter.dev/get-started/install) for more detail 
