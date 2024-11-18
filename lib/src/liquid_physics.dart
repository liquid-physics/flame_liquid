import 'package:flame/game.dart';
import 'package:flame_liquid/flame_liquid.dart';

mixin LiquidPhysics on FlameGame {
  late Space space;
  Space Function(Space space)? initial;
  bool renderDebug = false;
  static Vector2 defaultGravity = Vector2(0, 100.0);
  double accuTime = 0;
  double timeStep = 1.0 / 180.0;
  List<void Function(double timeStep)?> setFixedUpdate = [];

  void initializePhysics({Space Function(Space space)? initial}) {
    if (initial == null) {
      space = Space()
        ..setGravity(gravity: defaultGravity)
        ..setIternation(iterations: 30)
        ..setSleepTimeThreshold(sleepTimeThreshold: .5)
        ..setCollisionSlop(collisionSlop: .5);
    } else {
      space = initial.call(Space());
    }
    setFixedUpdate.add(fixedUpdate);
  }

  @override
  void update(double dt) {
    super.update(dt);
    accuTime += dt;
    while (accuTime >= timeStep) {
      if (setFixedUpdate.isNotEmpty) {
        space.step(dt: timeStep);
        for (var element in setFixedUpdate) {
          element?.call(timeStep);
        }
      }
      accuTime -= timeStep;
    }
  }

  void fixedUpdate(double timeStep) {}

  @override
  void onRemove() {
    space.destroy();
    super.onRemove();
  }
}
