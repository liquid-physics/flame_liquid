import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_liquid/flame_liquid.dart';

mixin LiquidDynamicBody on LiquidPhysicsComponent {
  late Body _body;
  late Shape _shape;
  late Space space;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    var gm = findGame();
    if (gm is LiquidPhysics) {
      space = gm.space;
    }

    var (bd, sh) = create();
    _body = bd;
    _shape = sh;
  }

  Body getBody() => _body;
  Shape getShape() => _shape;

  (Body, Shape) create();

  @override
  void update(double dt) {
    super.update(dt);
    if (_body.isExist) {
      transform.position = _body.getPosition();
      transform.angle = _body.getAngle();
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    var (Shape sh, _) = space.pointQueryNearest(
        mouse: absolutePositionOf(point), radius: 0, filter: grabFilter);

    if (sh.isExist) {
      return true;
    }
    return false;
  }

  @override
  void onRemove() {
    super.onRemove();
    space.removeShape(shape: _shape);
    space.removeBody(body: _body);
    _shape.destroy();
    _body.destroy();
  }
}
mixin LiquidKinematicBody on LiquidPhysicsComponent {
  late Space space;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    var gm = findGame();
    if (gm is LiquidPhysics) {
      space = gm.space;
    }
    create();
  }

  void create();
}
mixin LiquidStaticBody on LiquidPhysicsComponent {
  late Space space;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    var gm = findGame();
    if (gm is LiquidPhysics) {
      space = gm.space;
    }

    create();
  }

  void create();
}
