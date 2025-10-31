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
