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
import 'package:liquid2d/liquid2d.dart' as d;

class Crane extends StatefulWidget {
  static const route = '/crane';

  const Crane({super.key});

  @override
  State<Crane> createState() => _CraneState();
}

class _CraneState extends State<Crane> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: CraneGame()),
    );
  }
}

class CraneGame extends FlameGame
    with LiquidPhysics, MouseMovementDetector, SecondaryTapDetector {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  Constraint? hookJoint;
  late PivotJoint pv;
  late SlideJoint slide;
  var mouse = Vector2.zero();
  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 100))
        ..setDamping(damping: .8),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;
    var mid = Vector2(size.x / 2, size.y / 2);
    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));
    var staticBody = space.getStaticBody();

    var dolly = _Dolly(Vector2(0, 100).flipY() + mid, 30, 30);
    await world.add(dolly);
    space.addConstraint(
        constraint: GrooveJoint(
            a: staticBody,
            b: dolly.getBody(),
            grooveA: Vector2(-250, 100).flipY() + mid,
            grooveB: Vector2(250, 100).flipY() + mid,
            anchorB: Vector2.zero()));
    pv = space.addConstraint(
        constraint: PivotJoint(
            a: staticBody,
            b: dolly.getBody(),
            anchorA: Vector2.zero(),
            anchorB: dolly.getBody().getPosition().flipY() - mid))
      ..setMaxForce(10000)
      ..setMaxBias(100);

    var hook = _Hook(Vector2(0, 50).flipY() + mid, 10);
    await world.add(hook);

    slide = space.addConstraint(
        constraint: SlideJoint(
            a: dolly.getBody(),
            b: hook.getBody(),
            anchorA: Vector2.zero(),
            anchorB: Vector2.zero(),
            min: 0,
            max: double.infinity))
      ..setMaxForce(30000)
      ..setMaxBias(60);

    var box = _Box(Vector2(200, -200).flipY() + mid, 50, 50);
    await world.add((box));

    space.addCollisionHandler(aType: 1, bType: 2).begin((arbiter, space) {
      if (hookJoint == null) {
        var (Body a, Body b) = arbiter.getBodies();

        space.addPostStepCallback<Space>(space, (space, liquidType) {
          hookJoint = space.addConstraint(
              constraint: PivotJoint(
                  a: a,
                  b: b,
                  anchorA: a.worldToLocal(a.getPosition()),
                  anchorB: b.worldToLocal(a.getPosition())));
        });
      }

      return true; // return value is ignored for sensor callbacks anyway
    });
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    mouse = info.eventPosition.widget;
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    pv.setAnchorA(Vector2(mouse.x, 100).flipY());
    slide.setMax(max(-200 + mouse.y, 50));
  }

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    super.onSecondaryTapDown(info);
    if (hookJoint != null) {
      space.removeConstraint(constraint: hookJoint!);
      hookJoint!.destroy();
      hookJoint = null;
    }
  }
}

class _Dolly extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final double wd;
  final double he;
  final Vector2 pos;

  _Dolly(this.pos, this.wd, this.he);

  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 10, moment: double.infinity))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.8);

    return (body, shape);
  }
}

class _Hook extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double radius;

  _Hook(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 1.0, moment: double.infinity))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setCollisionType(1)
      ..setSensor(true);

    return (body, shape);
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final double wd;
  final double he;
  final Vector2 pos;

  _Box(this.pos, this.wd, this.he);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: 30, moment: Moment.forBox(30, wd, he)))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0.0))
      ..setElasticity(0)
      ..setCollisionType(2);

    return (body, shape);
  }
}
