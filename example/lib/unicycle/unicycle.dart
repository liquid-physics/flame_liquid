// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid/src/liquid.dart' as d;

class Unicycle extends StatefulWidget {
  static const route = '/unicycle';

  const Unicycle({super.key});

  @override
  State<Unicycle> createState() => _UnicycleState();
}

class _UnicycleState extends State<Unicycle> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: UnicycleGame()),
    );
  }
}

class UnicycleGame extends FlameGame with LiquidPhysics, MouseMovementDetector {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  var mouse = Vector2.zero();
  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 500)),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);

    world.add(_Box(Vector2(200, -100).flipY() + mid, Vector2(100, 20)));

    var bd = _Body(Vector2(0.0, -160 + 30).flipY() + mid);
    await world.add(bd);
    var wheel = _Circle(Vector2(0, -160).flipY() + mid, 20);
    await world.add(wheel);

    var anchorA = bd.getBody().worldToLocal(wheel.getBody().getPosition());

    var groove_a = anchorA + Vector2(0.0, 30.0);
    var groove_b = anchorA + Vector2(0.0, -10.0);
    space.addConstraint(
        constraint: GrooveJoint(
            a: bd.getBody(),
            b: wheel.getBody(),
            grooveA: groove_a,
            grooveB: groove_b,
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: DampedSpring(
            a: bd.getBody(),
            b: wheel.getBody(),
            anchorA: anchorA,
            anchorB: Vector2.zero(),
            restLength: 0,
            stiffness: 6.0e2,
            damping: 30));
    var balance_sin = 0.0;

    space
        .addConstraint(
            constraint:
                SimpleMotor(a: wheel.getBody(), b: bd.getBody(), rate: 0))
        .setPreSolveFunc((constraint, space) {
      var dt = space.getCurrentTimeStep();

      var target_x = mouse.x;

      var max_v = 500.0;
      var target_v = clampDouble(
          bias_coef(0.5, dt / 1.2) *
              (target_x - bd.getBody().getPosition().x) /
              dt,
          -max_v,
          max_v);
      var error_v = (target_v - bd.getBody().getVelocity().x);
      var target_sin = -(3.0e-3 * bias_coef(0.1, dt) * error_v / dt);

      var max_sin = sin(0.6);
      balance_sin = clampDouble(
          -balance_sin - 6.0e-5 * bias_coef(0.2, dt) * error_v / dt,
          -max_sin,
          max_sin);
      var target_a =
          asin(clampDouble(-target_sin + balance_sin, -max_sin, max_sin));
      var angular_diff = asin(bd
          .getBody()
          .getRotation()
          .cross(Vector2(cos(target_a), sin(target_a))));
      var target_w = bias_coef(0.1, dt / 0.4) * (angular_diff) / dt;

      var max_rate = 50.0;
      var rate = clampDouble(
          wheel.getBody().getAngularVelocity() +
              bd.getBody().getAngularVelocity() -
              target_w,
          -max_rate,
          max_rate);
      (constraint as SimpleMotor)
        ..setRate(clampDouble(rate, -max_rate, max_rate))
        ..setMaxForce(8.0e4);
    });
  }

  double bias_coef(double errorBias, double dt) {
    return 1.0 - pow(errorBias, dt);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    mouse = info.eventPosition.global;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawLine(Offset(mouse.x, 0), Offset(mouse.x, size.y),
        Paint()..color = Colors.redAccent);
    canvas.restore();
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final Vector2 _size;
  _Box(this._position, this._size) : super(position: _position, size: _size);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: 3, moment: Moment.forBox(3, width, height)))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape:
            d.BoxShape(body: body, width: width, height: height, radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.7);

    return (body, shape);
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final double _radius;
  _Circle(this._position, this._radius)
      : super(
          position: _position,
        );

  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1.0,
            moment: Moment.forCircle(1.0, 0.0, _radius, Vector2.zero())))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: _radius, offset: Vector2.zero()))
      ..setFriction(.7)
      ..setFilter(ShapeFilter(
          group: 1, mask: allCategories, categories: allCategories));

    return (body, shape);
  }
}

class _Body extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;

  _Body(this._position) : super(position: _position);
  @override
  (Body, Shape) create() {
    var cogOffset = -30.0;
    var bb1 =
        Rect.fromLBRT(-5.0, 0.0 - cogOffset, 5.0, cogOffset * 1.2 - cogOffset);
    var bb2 = Rect.fromLBRT(-25.0, bb1.top, 25.0, bb1.top + 10.0);
    var mass = 3.0;
    var moment = Moment.forBox(
            mass, (bb1.right - bb1.left).abs(), (bb1.bottom - bb1.top).abs()) +
        Moment.forBox(
            mass, (bb2.right - bb2.left).abs(), (bb2.bottom - bb2.top).abs());
    var body = space.addBody(body: Body(mass: mass, moment: moment))
      ..setPosition(pos: position);

    space.addShape(
        shape: d.BoxShape.fromRect(body: body, rect: bb1, radius: 0.0))
      ..setFriction(1)
      ..setFilter(ShapeFilter(
          group: 1, mask: allCategories, categories: allCategories));

    var shape = space.addShape(
        shape: d.BoxShape.fromRect(body: body, rect: bb2, radius: 0.0))
      ..setFriction(1)
      ..setFilter(ShapeFilter(
          group: 1, mask: allCategories, categories: allCategories));

    return (body, shape);
  }
}
