import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_3d/components.dart';
import 'package:flutter/material.dart';
import 'package:flame_3d/camera.dart' hide ThirdPersonCamera;

import 'components/floor.dart';
import 'components/player.dart';
import 'components/wall.dart';
import 'loader.dart';
import 'third_person_camera.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Loader.init();

  runApp(GameWidget(game: CubesGame(), focusNode: FocusNode(skipTraversal: true)));
}

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
