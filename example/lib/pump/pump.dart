import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/services/keyboard_key.g.dart';

class Pump extends StatefulWidget {
  static const route = '/pump';

  const Pump({super.key});

  @override
  State<Pump> createState() => _PumpState();
}

class _PumpState extends State<Pump> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PumpGame()),
    );
  }
}

class PumpGame extends FlameGame with LiquidPhysics, KeyboardEvents {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  late SimpleMotor motor;
  double x = 0;
  double y = 0;
  var _bb = <_Ball>[];
  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space..setGravity(gravity: Vector2(0, 600)),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(LiquidDebugDraw(space));
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    var staticBody = space.getStaticBody();
    var offset = Vector2(size.x / 2, size.y / 2);

    world.addAll([
      _Segment(
        staticBody,
        (Vector2(-256, 16)..flipY()) + offset,
        (Vector2(-256, 300)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-256, 16)..flipY()) + offset,
        (Vector2(-192, 0)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-192, 0)..flipY()) + offset,
        (Vector2(-192, -64)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-128, -64)..flipY()) + offset,
        (Vector2(-128, 144)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-192, 80)..flipY()) + offset,
        (Vector2(-192, 176)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-192, 176)..flipY()) + offset,
        (Vector2(-128, 240)..flipY()) + offset,
        2,
      ),
      _Segment(
        staticBody,
        (Vector2(-128, 144)..flipY()) + offset,
        (Vector2(192, 64)..flipY()) + offset,
        2,
      ),
    ]);

    _bb = <_Ball>[
      for (int i = 0; i < 5; i++)
        _Ball(Vector2(-224.0 + i, 80.0 + 64 * i).flipY() + offset, 30)
    ];
    await world.addAll(_bb);
    var plunger = _Plunger();
    await world.add(plunger);

    var grs = _Gear(Vector2(-160, -160).flipY() + offset, 80, -pi / 2);
    var grb = _Gear(Vector2(80, -160).flipY() + offset, 160, pi / 2);
    await world.addAll([grs, grb]);
    space.addConstraint(
        constraint: PivotJoint(
            a: staticBody,
            b: grs.getBody(),
            anchorA: Vector2(-160, -160).flipY() + offset,
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: PivotJoint(
            a: staticBody,
            b: grb.getBody(),
            anchorA: Vector2(80, -160).flipY() + offset,
            anchorB: Vector2.zero()));

    space.addConstraint(
        constraint: PinJoint(
            a: grs.getBody(),
            b: plunger.getBody(),
            anchorA: Vector2(-80, 0),
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: GearJoint(
            a: grs.getBody(), b: grb.getBody(), phase: -pi / 2, ratio: -2));
    var feeder = _Feeder();
    await world.add(feeder);

    space.addConstraint(
        constraint: PivotJoint(
            a: staticBody,
            b: feeder.getBody(),
            anchorA: Vector2(-224, -300).flipY() + offset,
            anchorB: Vector2(0, 332 / 2)));
    var anch =
        feeder.getBody().worldToLocal(Vector2(-224, -160).flipY() + offset);
    space.addConstraint(
        constraint: PinJoint(
            a: feeder.getBody(),
            b: grs.getBody(),
            anchorA: anch,
            anchorB: Vector2(0, 80)));
    motor = space.addConstraint(
        constraint: SimpleMotor(a: staticBody, b: grb.getBody(), rate: 1));
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    double coef = (2.0 + y) / 3.0;
    double rate = x * 30.0 * coef;
    motor.setRate(rate);
    motor.setMaxForce(rate > 0 || rate < 0 ? 1000000.0 : 0);
    for (int i = 0; i < 5; i++) {
      Vector2 po = _bb[i].getBody().getPosition();

      if (po.x > 320.0 + (size.x / 2)) {
        _bb[i].getBody().setVelocity(vel: Vector2.zero());
        _bb[i].getBody().setPosition(
            pos: Vector2(-224.0, 200.0).flipY() +
                Vector2(size.x / 2, size.y / 2));
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
      RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;
    final isKeyUp = event is RawKeyUpEvent;

    if (isKeyDown) {
      if (keysPressed.contains(LogicalKeyboardKey.bracketLeft)) x = -1;
      if (keysPressed.contains(LogicalKeyboardKey.bracketRight)) x = 1;
      return KeyEventResult.handled;
    }
    if (isKeyUp) {
      if (keysPressed.contains(LogicalKeyboardKey.bracketLeft) ||
          keysPressed.contains(LogicalKeyboardKey.bracketRight)) x = 0;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Body body;
  final Vector2 posA;
  final Vector2 posB;
  final double radius;
  _Segment(this.body, this.posA, this.posB, this.radius);
  @override
  void create() {
    space.addShape(
        shape: SegmentShape(
            body: space.getStaticBody(), a: posA, b: posB, radius: radius))
      ..setElasticity(0)
      ..setFriction(.5)
      ..setFilter(notGrabbableFilter);
  }
}

class _Ball extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double radius;
  _Ball(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(.5)
      ..setFriction(1);

    return (body, shape);
  }
}

class _Plunger extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<PumpGame> {
  static final _plunger = <Vector2>[
    Vector2(-30, -80).flipY(),
    Vector2(-30, 80).flipY(),
    Vector2(30, 64).flipY(),
    Vector2(30, -80).flipY(),
  ];

  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 1, moment: double.infinity))
      ..setPosition(
          pos: Vector2(-160, -80).flipY() +
              Vector2(game.size.x / 2, game.size.y / 2));

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: _plunger,
            transform: Matrix4.identity(),
            radius: 0))
      ..setElasticity(1)
      ..setFriction(.5)
      ..setFilter(ShapeFilter(group: 0, categories: 1, mask: 1));
    return (body, shape);
  }
}

class _Gear extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final double radius;
  final Vector2 pos;
  final double ang;
  _Gear(this.pos, this.radius, this.ang);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, radius, 0, Vector2.zero())))
      ..setPosition(pos: pos)
      ..setAngle(ang);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setFilter(shapeFilterNone);

    return (body, shape);
  }
}

class _Feeder extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<PumpGame> {
  static double bottom = -300;
  static double top = 32;
  static double len = top - bottom;
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1,
            moment: Moment.forSegment(
                1, Vector2(-224, bottom), Vector2(-224, top), 0)))
      ..setPosition(
          pos: Vector2(-224, (bottom + top) / 2).flipY() +
              Vector2(game.size.x / 2, game.size.y / 2));
    var shape = space.addShape(
        shape: SegmentShape(
            body: body,
            a: Vector2(0, len / 2),
            b: Vector2(0, -len / 2),
            radius: 20))
      ..setFilter(grabFilter);

    return (body, shape);
  }
}
