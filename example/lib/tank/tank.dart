import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid/src/liquid.dart' as d;

class Tank extends StatefulWidget {
  static const route = '/tank';

  const Tank({super.key});

  @override
  State<Tank> createState() => _TankState();
}

class _TankState extends State<Tank> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: TankGame()),
    );
  }
}

class TankGame extends FlameGame with LiquidPhysics, MouseMovementDetector {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 10)
        ..setSleepTimeThreshold(sleepTimeThreshold: .5),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(LiquidDebugDraw(space));
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    var mid = Vector2(size.x / 2, size.y / 2);
    var staticBody = space.getStaticBody();
    var rad = Vector2(20, 20).length;

    for (var i = 0; i < 50; i++) {
      var bd = _Box(
          wd: 20,
          he: 20,
          mass: 1,
          pos: Vector2(_random.nextDouble() * (640 - 2 * rad) - (320 - rad),
                      _random.nextDouble() * (480 - 2 * rad) - (240 - rad))
                  .flipY() +
              mid);
      await world.add(bd);
      space.addConstraint(
          constraint: PivotJoint(
              a: staticBody,
              b: bd.getBody(),
              anchorA: Vector2.zero(),
              anchorB: Vector2.zero()))
        ..setMaxBias(0)
        ..setMaxForce(1000);
      space.addConstraint(
          constraint:
              GearJoint(a: staticBody, b: bd.getBody(), phase: 0, ratio: 1))
        ..setMaxBias(0)
        ..setMaxForce(5000);
    }

    tankBody = space.addBody(body: KinematicBody());
    bs = _Box(
        wd: 30,
        he: 30,
        mass: 10,
        pos: Vector2(_random.nextDouble() * (640 - 2 * rad) - (320 - rad),
                    _random.nextDouble() * (480 - 2 * rad) - (240 - rad))
                .flipY() +
            mid);

    await world.add(bs);
    space.addConstraint(
        constraint: PivotJoint(
            a: tankBody,
            b: bs.getBody(),
            anchorA: Vector2.zero(),
            anchorB: Vector2.zero()))
      ..setMaxBias(0)
      ..setMaxForce(10000);
    space.addConstraint(
        constraint: GearJoint(a: tankBody, b: bs.getBody(), phase: 0, ratio: 1))
      ..setErrorBias(0)
      ..setMaxBias(1.2)
      ..setMaxForce(50000);
  }

  late Body tankBody;
  late _Box bs;
  var mouse = Vector2.zero();
  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    var delta = mouse - bs.getBody().getPosition();
    var turn = toAngle(unRotate(bs.getBody().getRotation(), delta));
    tankBody.setAngle(bs.getBody().getAngle() - turn);
    if (isNear(mouse, bs.getBody().getPosition(), 30)) {
      tankBody.setVelocity(vel: Vector2.zero());
    } else {
      var direction = delta.dot(bs.getBody().getRotation()) > 0 ? 1.0 : -1.0;
      tankBody.setVelocity(
          vel: rotate(bs.getBody().getRotation(), Vector2(30 * direction, 0)));
    }
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    mouse = info.eventPosition.game;
  }

  Vector2 unRotate(Vector2 v1, Vector2 v2) {
    return Vector2(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y);
  }

  Vector2 rotate(Vector2 v1, Vector2 v2) {
    return Vector2(v1.x * v2.x - v1.y * v2.y, v1.x * v2.y + v1.y * v2.x);
  }

  double toAngle(Vector2 v) {
    return atan2(v.y, v.x);
  }

  bool isNear(Vector2 a, Vector2 b, double distance) =>
      (a - b).length2 < distance * distance;
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double wd;
  final double he;
  final double mass;
  _Box(
      {required this.pos,
      required this.wd,
      required this.he,
      required this.mass});

  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: mass, moment: Moment.forBox(2, wd, he)))
      ..setPosition(pos: pos);
    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0))
      ..setElasticity(0)
      ..setFriction(.7);

    return (body, shape);
  }
}
