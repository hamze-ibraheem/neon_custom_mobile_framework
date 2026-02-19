# Neon Framework - Build Guide

How to build and run the Neon Framework test app on Android and iOS devices.

---

## How the Neon Framework Works

The Neon Framework has two parts that work together:

1. **Dart Backend** - Runs a local HTTP server (on port 8080) that serves the UI as JSON
2. **Native Shell** - An Android or iOS app that fetches the JSON and renders real native UI components

The Dart backend must be running on the same machine (or reachable network) for the native app to work.

---

## Prerequisites

### For Android (APK)
- [Android Studio](https://developer.android.com/studio) (latest stable)
- Android SDK (API 34) - installed via Android Studio SDK Manager
- Java 17 (bundled with Android Studio)
- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)

### For iOS (IPA)
- A Mac computer (required - iOS apps can only be built on macOS)
- [Xcode](https://developer.apple.com/xcode/) (15.0 or higher)
- An Apple Developer Account (free for simulator testing, paid for device/distribution)
- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)

---

## Step 1: Download the Project

Download the entire `neon_framework/` folder from Replit. This contains:

```
neon_framework/
  lib/                    <-- Framework source code
  my_2nd_test_app/        <-- Test app with native shells
    lib/                  <-- Dart app code (screens, widgets)
    android/              <-- Android native project
    NeonApp/              <-- iOS native project (Xcode)
    pubspec.yaml          <-- Dart dependencies
  pubspec.yaml            <-- Framework package definition
```

---

## Step 2: Install Dart Dependencies

Open a terminal and navigate to the test app:

```bash
cd neon_framework/my_2nd_test_app
dart pub get
```

This resolves the framework dependency (which points to `..`, the parent `neon_framework/` folder).

---

## Step 3: Start the Dart Backend

The Dart backend must be running before you launch the native app.

```bash
cd neon_framework/my_2nd_test_app
dart run lib/main.dart
```

You should see output like:

```
Neon app server running on http://localhost:8080
```

Keep this terminal open while using the native app.

---

## Building the Android APK

### Open the Project

1. Open **Android Studio**
2. Click **File > Open**
3. Navigate to `neon_framework/my_2nd_test_app/android/`
4. Click **Open** and wait for Gradle to sync

### Project Details

| Setting          | Value              |
|------------------|--------------------|
| Package name     | `com.neon.myapp`   |
| Min SDK          | 21 (Android 5.0)   |
| Target SDK       | 34 (Android 14)    |
| Kotlin           | 1.9.0              |
| Gradle           | 8.2                |
| AGP              | 8.2.0              |
| Java             | 17                 |

### Run on Emulator or Device

1. Make sure the Dart backend is running (Step 3)
2. In Android Studio, select a device/emulator from the toolbar
3. Click the **Run** button (green play icon)
4. The app will connect to `http://10.0.2.2:8080` (Android emulator's alias for host localhost)

### Build a Debug APK

From the terminal:

```bash
cd neon_framework/my_2nd_test_app/android
./gradlew assembleDebug
```

The APK will be at:
```
android/app/build/outputs/apk/debug/app-debug.apk
```

### Build a Release APK

For a release build, you need to set up signing. Create a keystore first:

```bash
keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key
```

Then add signing config to `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            storeFile file('my-release-key.jks')
            storePassword 'your-password'
            keyAlias 'my-key'
            keyPassword 'your-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
        }
    }
}
```

Then build:

```bash
./gradlew assembleRelease
```

The signed APK will be at:
```
android/app/build/outputs/apk/release/app-release.apk
```

### Important: Server URL for Physical Devices

The Android app connects to `http://10.0.2.2:8080` by default, which only works on the Android Emulator. For a physical device on the same Wi-Fi network:

1. Open `android/app/src/main/kotlin/com/neon/myapp/MainActivity.kt`
2. Find the server URL (look for `10.0.2.2` or `127.0.0.1`)
3. Replace it with your computer's local IP address (e.g., `http://192.168.1.100:8080`)
4. Your computer's firewall must allow connections on port 8080

---

## Building the iOS App (IPA)

### Open the Project

1. Open **Xcode**
2. Click **File > Open**
3. Navigate to `neon_framework/my_2nd_test_app/NeonApp/NeonApp.xcodeproj`
4. Click **Open**

### Project Details

| Setting              | Value                      |
|----------------------|----------------------------|
| Bundle Identifier    | Set in Xcode project       |
| Deployment Target    | iOS 15.0+                  |
| Language             | Swift (UIKit)              |
| Storyboard           | Main.storyboard            |

### Run on Simulator

1. Make sure the Dart backend is running (Step 3)
2. In Xcode, select a simulator from the device dropdown (e.g., "iPhone 15")
3. Click the **Run** button (play icon) or press Cmd+R
4. The app connects to `http://127.0.0.1:8080` - this works on the simulator because it shares the Mac's network

### Run on Physical Device

For a physical iPhone/iPad:

1. In Xcode, go to **Signing & Capabilities**
2. Select your **Team** (Apple Developer account)
3. Xcode will automatically create a provisioning profile
4. Connect your device via USB
5. Update the server URL in `ViewController.swift`:
   - Find `http://127.0.0.1:8080`
   - Replace with your Mac's local IP (e.g., `http://192.168.1.100:8080`)
6. Click **Run**

### Build an Archive (for IPA distribution)

1. In Xcode, select **Product > Archive**
2. Once the archive completes, the Organizer window opens
3. Click **Distribute App**
4. Choose your distribution method:
   - **App Store Connect** - for App Store submission
   - **Ad Hoc** - for testing on specific devices
   - **Development** - for development testing
5. Follow the prompts to export the IPA file

### App Transport Security

The iOS app is configured to allow local networking (HTTP to localhost). This is set in `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

For production, you should use HTTPS and update this setting accordingly.

---

## Project Structure Reference

### Dart App Code (`my_2nd_test_app/lib/`)

```
lib/
  main.dart              <-- Entry point, AppLauncher widget
  app.dart               <-- Sample app with transpiled widgets
  state_test.dart        <-- State management tests
  screens/
    showcase.dart        <-- ShowcaseApp with 8-tab navigation
    home_screen.dart     <-- Dashboard screen
    navigation_screen.dart  <-- Interaction & navigation demos
    containment_screen.dart <-- Cards, dialogs, bottom sheets
    input_screen.dart    <-- Text fields, search bars
```

### Android Native (`my_2nd_test_app/android/`)

```
android/
  app/
    build.gradle                          <-- App-level build config
    src/main/
      AndroidManifest.xml                 <-- App permissions & config
      kotlin/com/neon/myapp/
        MainActivity.kt                  <-- Native widget renderer
  build.gradle                            <-- Project-level build config
  settings.gradle                         <-- Project settings
  gradle/wrapper/                         <-- Gradle wrapper (v8.2)
  gradlew                                 <-- Gradle wrapper script
```

### iOS Native (`my_2nd_test_app/NeonApp/`)

```
NeonApp/
  NeonApp.xcodeproj/                      <-- Xcode project file
  NeonApp/
    AppDelegate.swift                     <-- App lifecycle
    SceneDelegate.swift                   <-- Scene lifecycle
    ViewController.swift                  <-- Native widget renderer (1400+ lines)
    Info.plist                            <-- App configuration
    Assets.xcassets/                      <-- App icons & colors
    Base.lproj/
      Main.storyboard                    <-- UI storyboard
      LaunchScreen.storyboard             <-- Launch screen
```

---

## Troubleshooting

### "Connection refused" or blank screen
- Make sure the Dart backend is running (`dart run lib/main.dart`)
- Check the server URL matches your setup (localhost for emulator/simulator, IP for physical devices)

### Android: Gradle sync fails
- Make sure Android SDK 34 is installed (Android Studio > SDK Manager)
- Make sure Java 17 is configured (Android Studio > Settings > Build Tools > Gradle > JDK)

### iOS: Signing errors
- Go to Signing & Capabilities in Xcode and select your development team
- For free accounts, you may need to change the bundle identifier to something unique

### Android: cleartext HTTP blocked
- The AndroidManifest.xml already includes `android:usesCleartextTraffic="true"` to allow HTTP connections to the Dart backend

### iOS: Network request fails
- The Info.plist already includes `NSAllowsLocalNetworking` to allow local HTTP connections
- For physical devices, make sure both the phone and computer are on the same Wi-Fi network

---

## Quick Reference Commands

```bash
# Install Dart dependencies
cd neon_framework/my_2nd_test_app && dart pub get

# Start the Dart backend
cd neon_framework/my_2nd_test_app && dart run lib/main.dart

# Build Android debug APK
cd neon_framework/my_2nd_test_app/android && ./gradlew assembleDebug

# Build Android release APK
cd neon_framework/my_2nd_test_app/android && ./gradlew assembleRelease

# Clean Android build
cd neon_framework/my_2nd_test_app/android && ./gradlew clean

# iOS: Open in Xcode
open neon_framework/my_2nd_test_app/NeonApp/NeonApp.xcodeproj
```
