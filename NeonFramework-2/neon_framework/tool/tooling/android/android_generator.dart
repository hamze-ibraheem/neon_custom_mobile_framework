import 'dart:io';

class AndroidGenerator {
  void generate() {
    final androidDir = Directory('android');

    if (androidDir.existsSync()) {
      stdout.writeln('[WARN] Android project already exists.');
      return;
    }

    stdout.writeln('Generating Android project skeleton...');

    androidDir.createSync(recursive: true);

    _createSettingsGradle();
    _createRootBuildGradle();
    _createAppModule();
  }

  void _createSettingsGradle() {
    File('android/settings.gradle').writeAsStringSync('''
rootProject.name = "neon_app"
include(":app")
''');
  }

  void _createRootBuildGradle() {
    File('android/build.gradle').writeAsStringSync('''
buildscript {
  repositories {
    google()
    mavenCentral()
  }
  dependencies {
    classpath "com.android.tools.build:gradle:8.2.0"
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0"
  }
}

allprojects {
  repositories {
    google()
    mavenCentral()
  }
}
''');
  }

  void _createAppModule() {
    final mainDir = Directory('android/app/src/main/java/com/neon/myapp');
    mainDir.createSync(recursive: true);

    File('android/app/build.gradle').writeAsStringSync('''
plugins {
  id "com.android.application"
  id "kotlin-android"
}

android {
  namespace "com.neon.myapp"
  compileSdk 34

  defaultConfig {
    applicationId "com.neon.myapp"
    minSdk 21
    targetSdk 34
    versionCode 1
    versionName "1.0"
  }
}
''');

    File('android/app/src/main/AndroidManifest.xml').writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application
    android:label="Neon App">
    <activity
      android:name=".MainActivity"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
''');

    File('${mainDir.path}/MainActivity.kt').writeAsStringSync('''
package com.neon.myapp

import android.app.Activity
import android.os.Bundle

class MainActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Neon engine will attach here later
  }
}
''');
  }
}
