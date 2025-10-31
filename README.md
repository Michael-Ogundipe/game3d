# game3d

A new Flutter project.


## Getting Started

Step 1: Add the dependency to your pubspec.yaml file:

flutter pub add flame flame_3d

In main.dart

```dart
void main() {
  final game = FlameGame();
  runApp(GameWidget(game: game));
}

```

// Talk about Flutter GPU

// Enable using Impeller by adding the following key to /macos/Runner/Info.plist:

```xml
 <key>FLTEnableImpeller</key>
    <true/>
    <key>FLTEnableFlutterGPU</key>
    <true/>
```