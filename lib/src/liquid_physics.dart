import 'package:flame/game.dart';
import 'package:flame_liquid/flame_liquid.dart';

mixin LiquidPhysics on FlameGame {
  late Space space;
  Space Function(Space space)? initial;
  bool renderDebug = false;
  static Vector2 defaultGravity = Vector2(0, 100.0);

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
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    space.step(dt: timeStep);
  }

  @override
  void onRemove() {
    space.destroy();
    super.onRemove();
  }
}

  // void physics(Space space) {}

  // @override
  // @mustCallSuper
  // void onMount() {
  //   game
  //   super.onMount();
  //   final game = findGame()! as FlameGame;
  //   if (game.findByKey(const LiquidPhysicsDispatcherKey()) == null) {
  //     final lqPhysics = LiquidPhysicsDispatcher(game);
  //     game.registerKey(const LiquidPhysicsDispatcherKey(), lqPhysics);
  //     game.add(lqPhysics);
  //   }
  // }