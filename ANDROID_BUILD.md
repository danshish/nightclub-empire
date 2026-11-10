# Android APK export

The game is designed for Android portrait screens and uses Godot's Compatibility renderer.

## Requirements
- Godot 4.3 or newer (matching the project version)
- Godot export templates installed
- Android Studio / Android SDK
- JDK 17

## Configure Godot
1. Open the project in Godot.
2. Open Editor Settings → Export → Android.
3. Set the Android SDK path and Java SDK path.
4. Install the matching export templates from Editor → Manage Export Templates.
5. Open Project → Export, add an Android preset and set the package name to `com.magixdevelopment.nightclubempire`.
6. Set orientation to portrait and configure the app icon when available.
7. Export a debug APK for device testing.

## Device test checklist
- Install and launch on the Moto g17.
- Confirm the whole club scene and all five controls are visible.
- Confirm cash increases while the club is open.
- Close the club and confirm income pauses.
- Buy each affordable upgrade and confirm cash is deducted.
- Save, close, relaunch and confirm progress loads.

This repository currently contains the Godot source project. An APK is not yet built or attached.
