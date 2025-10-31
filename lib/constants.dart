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