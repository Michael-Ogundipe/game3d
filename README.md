# game3d

A new Flutter project.


## Getting Started

**Step 1: Create a new Flutter project:**

```bash
flutter create --empty games3d 
````

Step2: Add the dependency to your pubspec.yaml file:

flutter pub add flame flame_3d

Step 3: Replace the contents of lib/main.dart with the following code:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  await Loader.init();

  runApp(GameWidget(game: CubesGame(), focusNode: FocusNode(skipTraversal: true)));
}

```

The Loader Class

```dart

class Loader {
  Loader._();

  static late Models models;

  static Future<void> init() async {
    models = await Models.load();
  }
}

class Models {
  final Model rogue;
  final Model floor;
  final List<Model> walls;

  Models({
    required this.rogue,
    required this.floor,
    required this.walls,
  });

  static Future<Models> load() async {
    return Models(
      rogue: await ModelParser.parse('objects/rogue.glb'),
      floor: await ModelParser.parse('objects/floor.gltf'),
      walls: [
        await ModelParser.parse('objects/wall_0.gltf'),
        await ModelParser.parse('objects/wall_1.gltf'),
        await ModelParser.parse('objects/wall_2.gltf'),
      ],
    );
  }
}

```

Step 3b: The constants.dart file
Just to keep things tidy and organized. 

```dart
import 'dart:math';

import 'package:flame/components.dart';

const double worldSize = 16.0;
final Vector3 up = Vector3(0, 1, 0);


// Utilities
final _r = Random();

int randomInt(int min, int max) {
  return min + _r.nextInt(max - min);
}

extension Vector3Extensions on Vector3 {
  /// Changes the [length] of the vector to the length provided, without
  /// changing direction.
  ///
  /// If you try to scale the zero (empty) vector, it will remain unchanged, and
  /// no error will be thrown.
  void scaleTo(double newLength) {
    final l = length;
    if (l != 0) {
      scale(newLength.abs() / l);
    }
  }

  Vector3 scaledTo(double newLength) {
    return clone()..scaleTo(newLength);
  }
}
```

Step 4: Add your 3D models to the assets/objects directory.
https://drive.google.com/file/d/1fMBMg8uAyjAdKzwhvY7mNORkcZYCPznI/view?usp=sharing

Step 5: Update your pubspec.yaml to include the assets:

```yaml
  assets:
    - assets/objects/
```

Step 5b: Add the components/
Floor Component 
```dart

import 'package:flame/components.dart' as flame;
import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';

import '../loader.dart';

class Floor extends flame.Component {
  Floor({
    required Vector2 size,
  }) {
    final start = Vector3(
      -size.x / 2 + _floorSegmentSize / 2,
      -_floorHeight,
      -size.y / 2 + _floorSegmentSize / 2,
    );

    for (var x = 0; x < size.x / _floorSegmentSize; x++) {
      for (var y = 0; y < size.y / _floorSegmentSize; y++) {
        final position = start.clone()
          ..x += x * _floorSegmentSize
          ..z += y * _floorSegmentSize;
        add(_FloorSection()..position.setFrom(position));
      }
    }
  }
}

class _FloorSection extends ModelComponent {
  _FloorSection()
      : super(
    position: Vector3.zero(),
    model: Loader.models.floor,
  ) {
    transform.position.setValues(0, -0.5, 0);
  }
}

const double _floorHeight = 0.5;
const double _floorSegmentSize = 4.0;

```

Wall Component

```dart
import 'dart:math';

import 'package:flame/components.dart' as flame;
import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';

import '../constants.dart';
import '../loader.dart';

class Wall extends flame.Component {
  Wall({
    required Vector3 start,
    required Vector3 end,
  }) {
    final direction = end - start;
    final position = start + direction.scaledTo(_wallSegmentSize / 2);
    var totalDistance = direction.length;

    while (totalDistance >= _wallSegmentSize) {
      // rotate the wall to align with the start-end line
      final rotation = Quaternion.axisAngle(
        up,
        atan2(start.z - end.z, start.x - end.x),
      );

      add(
        _WallSection(
          wallIndex: randomInt(0, Loader.models.walls.length),
          position: position,
          rotation: rotation,
        ),
      );

      position.add(direction.scaledTo(_wallSegmentSize));
      totalDistance -= _wallSegmentSize;
    }
  }
}

class _WallSection extends ModelComponent {
  _WallSection({
    required int wallIndex,
    required Vector3 position,
    required Quaternion rotation,
  }) : super(
    position: position,
    rotation: rotation,
    model: Loader.models.walls[wallIndex],
  );
}

const double _wallSegmentSize = 4.0;

```
Player Component

```dart

import 'dart:math';

import 'package:flame/components.dart' as flame;
import 'package:flame/events.dart';
import 'package:flame/geometry.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter/services.dart';

import '../input_utils.dart';
import '../loader.dart';

class Player extends ModelComponent with flame.HasGameReference, flame.KeyboardHandler, TapCallbacks {
  Player() : super(position: Vector3.zero(), model: Loader.models.rogue) {
    weapon = PlayerWeapon.knife;
  }

  PlayerAction? _action;
  double _actionTimer = 0.0;

  PlayerAction? get action => _action;

  set action(PlayerAction? value) {
    if (_actionTimer != 0.0) {
      return;
    }

    _action = value;
    _actionTimer = value?.timer ?? 0.0;
    stopAnimation();
  }

  late PlayerWeapon _weapon;

  PlayerWeapon get weapon => _weapon;

  set weapon(PlayerWeapon value) {
    _weapon = value;
    _updateWeapon();
  }

  bool _isRunning = false;
  double _deathTimer = 0.0;

  void _updateWeapon() {
    for (final hide in PlayerWeapon.values) {
      hideNodeByName(hide.nodeName);
    }
    hideNodeByName(weapon.nodeName, hidden: false);
  }

  double _lookAngle = 0.0;
  final Vector3 up = Vector3(0, 1, 0);

  double get lookAngle => _lookAngle;

  set lookAngle(double value) {
    _lookAngle = value % tau;
    transform.rotation.setAxisAngle(up, value);
  }

  Vector3 get lookAt => Vector3(sin(_lookAngle), 0.0, cos(_lookAngle));

  final Vector2 _input = Vector2.zero();

  void reset() {
    action = null;
    _deathTimer = 0.0;
    lookAngle = 0.0;
    position.setZero();
    _updateWeapon();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_actionTimer != 0.0) {
      _actionTimer -= dt;
      if (_actionTimer <= 0.0) {
        _actionTimer = 0.0;
        _action = null;
      }
    }

    final isMoving = _handleMovement(dt);
    _updateAnimation(isMoving: isMoving);
  }

  bool _handleMovement(double dt) {
    if (_actionTimer != 0.0) {
      return false;
    }

    lookAngle += -_input.x * _rotationSpeed * dt;

    final speed = _isRunning ? _runningSpeed : _walkingSpeed;
    final movement = lookAt.scaled(-_input.y * speed * dt);

    position.add(movement);
    position.clamp(_worldMin, _worldMax);

    return movement.length2 > 0.0;
  }

  void _updateAnimation({required bool isMoving}) {
    final action = _action;
    if (action != null) {
      switch (action) {
        case PlayerAction.attack:
          playAnimationByIndex(0, resetClock: false);
      }
    } else if (isMoving && _isRunning) {
      playAnimationByName('Running_A', resetClock: false);
    } else if (isMoving) {
      playAnimationByName('Walking_C', resetClock: false);
    } else {
      playAnimationByName('Idle', resetClock: false);
    }
  }

  void die() {
    if (_deathTimer != 0) {
      return;
    }
    _deathTimer = 2.0;
    playAnimationByName('Death_B');
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _isRunning = keysPressed.contains(LogicalKeyboardKey.shiftLeft);
    return readArrowLikeKeysIntoVector2(event, keysPressed, _input);
  }

  @override
  bool containsLocalPoint(flame.Vector2 point) => true;

  @override
  void onTapDown(_) {
    action = PlayerAction.attack;
  }
}

enum PlayerAction {
  attack(timer: 1.0666667222976685);

  final double timer;

  const PlayerAction({required this.timer});
}

enum PlayerWeapon {
  oneHandedCrossbow('1H_Crossbow'),
  twoHandedCrossbow('2H_Crossbow'),
  knife('Knife'),
  throwable('Throwable'),
  offhandKnife('Knife_Offhand');

  final String nodeName;

  const PlayerWeapon(this.nodeName);
}

const double _rotationSpeed = 3.0;
const double _walkingSpeed = 1.85;
const double _runningSpeed = 4.5;

const double _m = 0.75;
double worldSize = 16.0;
final Vector3 _worldMin = Vector3(-worldSize + _m, 0, -worldSize + _m);
final Vector3 _worldMax = Vector3(worldSize - _m, 0, worldSize - _m);

```

Step 5c: Add the input_utils.dart file
This is a utility to read keyboard input to move the player

```dart
import 'package:flame_3d/core.dart';
import 'package:flutter/services.dart';

bool readArrowLikeKeysIntoVector2(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
    Vector2 vector, {
      LogicalKeyboardKey up = LogicalKeyboardKey.keyW,
      LogicalKeyboardKey down = LogicalKeyboardKey.keyS,
      LogicalKeyboardKey left = LogicalKeyboardKey.keyA,
      LogicalKeyboardKey right = LogicalKeyboardKey.keyD,
    }) {
  final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
  if (event.logicalKey == up) {
    if (isDown) {
      vector.y = -1;
    } else if (keysPressed.contains(down)) {
      vector.y = 1;
    } else {
      vector.y = 0;
    }
    return false;
  } else if (event.logicalKey == down) {
    if (isDown) {
      vector.y = 1;
    } else if (keysPressed.contains(up)) {
      vector.y = -1;
    } else {
      vector.y = 0;
    }
    return false;
  } else if (event.logicalKey == left) {
    if (isDown) {
      vector.x = -1;
    } else if (keysPressed.contains(right)) {
      vector.x = 1;
    } else {
      vector.x = 0;
    }
    return false;
  } else if (event.logicalKey == right) {
    if (isDown) {
      vector.x = 1;
    } else if (keysPressed.contains(left)) {
      vector.x = -1;
    } else {
      vector.x = 0;
    }
    return false;
  }
  return true;
}

```

Step 6: Adding the Game class in main.dart

```dart


class CubesGame extends FlameGame<CubesWorld> with HasKeyboardHandlerComponents {
  CubesGame()
      : super(
    world: CubesWorld(),
    camera: ThirdPersonCamera(),

  );

  @override
  FutureOr<void> onLoad() async {
    await world.initGame();
  }
}

class CubesWorld extends World3D with TapCallbacks {
  CubesWorld() : super(clearColor: const Color(0xFF000000));

  @override
  FlameGame get game => findParent<FlameGame>()!;

  final Player player = Player();

  FutureOr<void> initGame() async {
    player.reset();
    await addAll([player, LightComponent.ambient(intensity: 600.0),
      // floor and walls
      Floor(
        size: Vector2.all(2 * worldSize),
      ),
      Wall(
        start: Vector3(worldSize, 0, -worldSize),
        end: Vector3(worldSize, 0, worldSize),
      ),
      Wall(
        start: Vector3(-worldSize, 0, worldSize),
        end: Vector3(worldSize, 0, worldSize),
      ),
    ]);
  }

  void resetGame() {
    removeWhere((e) => true);
  }
}


```

Step 7: Add the thrid person camera class

```dart
import 'package:flame/components.dart';
import 'package:flame_3d/camera.dart';
import 'package:game3d/main.dart';
import 'components/player.dart';

class ThirdPersonCamera extends CameraComponent3D
    with HasGameReference<CubesGame> {
  ThirdPersonCamera()
      : super(
    fovY: 75.0,
    position: Vector3(-18, 6, -18),
    up: Vector3(0.8, 1, 0.8),
    target: Vector3(0, 0, 0),
  );

  Player get player => game.world.player;

  @override
  void update(double dt) {
    super.update(dt);

    final targetOffset = player.position + _positionOffset;
    final targetLookAt = player.position + player.lookAt;

    position += (targetOffset - position) * _cameraLinearSpeed * dt;
    target += (targetLookAt - target) * _cameraRotationSpeed * dt;
  }
}

final Vector3 _positionOffset = Vector3(-4, 6, -4);
const double _cameraRotationSpeed = 6.0;
const double _cameraLinearSpeed = 12.0;


```