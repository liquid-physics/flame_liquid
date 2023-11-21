import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid/src/liquid.dart' as d;

class Joint extends StatefulWidget {
  static const route = '/joint';

  const Joint({super.key});

  @override
  State<Joint> createState() => _JointState();
}

class _JointState extends State<Joint> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: JointGame()),
    );
  }
}

class JointGame extends FlameGame with LiquidPhysics {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space
          ..setIternation(iterations: 10)
          ..setGravity(gravity: Vector2(0, 100))
          ..setSleepTimeThreshold(sleepTimeThreshold: .5);
      },
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));
    var staticBody = space.getStaticBody();

    var mid = Vector2(size.x / 2, size.y / 2);

    world.addAll([
      _Segment(
          radius: 2,
          posA: Vector2(-320, 240).flipY() + mid,
          posB: Vector2(320, 240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-320, 120).flipY() + mid,
          posB: Vector2(320, 120).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-320, 0).flipY() + mid,
          posB: Vector2(320, 0).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-320, -120).flipY() + mid,
          posB: Vector2(320, -120).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-320, -240).flipY() + mid,
          posB: Vector2(320, -240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-320, -240).flipY() + mid,
          posB: Vector2(-320, 240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(-160, -240).flipY() + mid,
          posB: Vector2(-160, 240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(0, -240).flipY() + mid,
          posB: Vector2(0, 240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(160, -240).flipY() + mid,
          posB: Vector2(160, 240).flipY() + mid,
          staticBody: staticBody),
      _Segment(
          radius: 2,
          posA: Vector2(320, -240).flipY() + mid,
          posB: Vector2(320, 240).flipY() + mid,
          staticBody: staticBody),
    ]);

    var posA = Vector2(50, 60).flipY();
    var posB = Vector2(110, 60).flipY();
    var boxoffset = Vector2(-320, -240).flipY() + mid;
    var bd1 = _Circle(posA + boxoffset, 15);
    var bd2 = _Circle(posB + boxoffset, 15);
    await world.addAll([bd1, bd2]);
    space.addConstraint(
        constraint: PinJoint(
            a: bd1.getBody(),
            b: bd2.getBody(),
            anchorA: Vector2(15, 0),
            anchorB: Vector2(-15, 0)));

    boxoffset = Vector2(-160, -240).flipY() + mid;
    bd1 = _Circle(posA + boxoffset, 15);
    bd2 = _Circle(posB + boxoffset, 15);
    await world.addAll([bd1, bd2]);
    space.addConstraint(
        constraint: SlideJoint(
            a: bd1.getBody(),
            b: bd2.getBody(),
            anchorA: Vector2(15, 0),
            anchorB: Vector2(-15, 0),
            min: 20,
            max: 40));

    boxoffset = Vector2(0, -240).flipY() + mid;
    bd1 = _Circle(posA + boxoffset, 15);
    bd2 = _Circle(posB + boxoffset, 15);
    await world.addAll([bd1, bd2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bd1.getBody(),
            b: bd2.getBody(),
            anchorA: Vector2(30, 0),
            anchorB: Vector2(-30, 0)));

    boxoffset = Vector2(160, -240).flipY() + mid;
    bd1 = _Circle(posA + boxoffset, 15);
    bd2 = _Circle(posB + boxoffset, 15);
    await world.addAll([bd1, bd2]);
    space.addConstraint(
        constraint: GrooveJoint(
            a: bd1.getBody(),
            b: bd2.getBody(),
            grooveA: Vector2(30, 30),
            grooveB: Vector2(30, -30),
            anchorB: Vector2(-30, 0)));

    boxoffset = Vector2(-320, -120).flipY() + mid;
    bd1 = _Circle(posA + boxoffset, 15);
    bd2 = _Circle(posB + boxoffset, 15);
    await world.addAll([bd1, bd2]);
    space.addConstraint(
        constraint: DampedSpring(
            a: bd1.getBody(),
            b: bd2.getBody(),
            anchorA: Vector2(15, 0),
            anchorB: Vector2(-15, 0),
            restLength: 20,
            stiffness: 5,
            damping: .5));

    boxoffset = Vector2(-160, -120).flipY() + mid;
    var bdb1 = _Bar(
      pos: posA + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    var bdb2 = _Bar(
      pos: posB + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    await world.addAll([bdb1, bdb2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb1.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posA + boxoffset));
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb2.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posB + boxoffset));
    space.addConstraint(
        constraint: DampedRotarySpring(
            a: bdb1.getBody(),
            b: bdb2.getBody(),
            restAngle: 0,
            stiffness: 3000,
            damping: 60));

    boxoffset = Vector2(0, -120).flipY() + mid;
    bdb1 = _Bar(
      pos: posA + boxoffset,
      radius: 5,
      posA: Vector2(0, -15).flipY(),
      posB: Vector2(0, 15).flipY(),
    );
    bdb2 = _Bar(
      pos: posB + boxoffset,
      radius: 5,
      posA: Vector2(0, -15).flipY(),
      posB: Vector2(0, 15).flipY(),
    );
    await world.addAll([bdb1, bdb2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb1.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 15),
            anchorB: posA + boxoffset));
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb2.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 15),
            anchorB: posB + boxoffset));
    space.addConstraint(
        constraint: RotaryLimitJoint(
            a: bdb1.getBody(), b: bdb2.getBody(), min: -pi / 2, max: pi / 2));

    boxoffset = Vector2(160, -120).flipY() + mid;
    bdb1 = _Bar(
      pos: posA + boxoffset,
      radius: 5,
      posA: Vector2(0, -15).flipY(),
      posB: Vector2(0, 15).flipY(),
    );
    bdb2 = _Bar(
      pos: posB + boxoffset,
      radius: 5,
      posA: Vector2(0, -15).flipY(),
      posB: Vector2(0, 15).flipY(),
    );
    await world.addAll([bdb1, bdb2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb1.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 15),
            anchorB: posA + boxoffset));
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb2.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 15),
            anchorB: posB + boxoffset));
    space.addConstraint(
        constraint: RatchetJoint(
            a: bdb1.getBody(), b: bdb2.getBody(), phase: 0, ratchet: pi / 2));

    boxoffset = Vector2(-320, 0).flipY() + mid;
    bdb1 = _Bar(
      pos: posA + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    bdb2 = _Bar(
      pos: posB + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    await world.addAll([bdb1, bdb2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb1.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posA + boxoffset));
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb2.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posB + boxoffset));
    space.addConstraint(
        constraint: GearJoint(
            a: bdb1.getBody(), b: bdb2.getBody(), phase: 0, ratio: 2));

    boxoffset = Vector2(-160, 0).flipY() + mid;
    bdb1 = _Bar(
      pos: posA + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    bdb2 = _Bar(
      pos: posB + boxoffset,
      radius: 5,
      posA: Vector2(0, -30).flipY(),
      posB: Vector2(0, 30).flipY(),
    );
    await world.addAll([bdb1, bdb2]);
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb1.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posA + boxoffset));
    space.addConstraint(
        constraint: PivotJoint(
            a: bdb2.getBody(),
            b: staticBody,
            anchorA: Vector2(0, 0),
            anchorB: posB + boxoffset));
    space.addConstraint(
        constraint:
            SimpleMotor(a: bdb1.getBody(), b: bdb2.getBody(), rate: pi));

    boxoffset = Vector2(0, 0).flipY() + mid;
    var w1 = _Wheel(posA + boxoffset, 15);
    var w2 = _Wheel(posB + boxoffset, 15);
    var chs = _Chassis(
        pos: Vector2(80, 100).flipY() + boxoffset,
        posA: Vector2(-40, 0).flipY(),
        posB: Vector2(40, 0).flipY());
    await world.addAll([w1, w2, chs]);
    space.addConstraint(
        constraint: GrooveJoint(
            a: chs.getBody(),
            b: w1.getBody(),
            grooveA: Vector2(-30, -10).flipY(),
            grooveB: Vector2(-30, -40).flipY(),
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: GrooveJoint(
            a: chs.getBody(),
            b: w2.getBody(),
            grooveA: Vector2(30, -10).flipY(),
            grooveB: Vector2(30, -40).flipY(),
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: DampedSpring(
            a: chs.getBody(),
            b: w1.getBody(),
            anchorA: Vector2(-30, 0),
            anchorB: Vector2.zero(),
            restLength: 50,
            stiffness: 20,
            damping: 10));
    space.addConstraint(
        constraint: DampedSpring(
            a: chs.getBody(),
            b: w2.getBody(),
            anchorA: Vector2(30, 0),
            anchorB: Vector2.zero(),
            restLength: 50,
            stiffness: 20,
            damping: 10));
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<JointGame> {
  final Vector2 pos;
  final double radius;
  _Circle(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1.0,
            moment: Moment.forCircle(1.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(.5)
      ..setFriction(1);

    return (body, shape);
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Body staticBody;
  final Vector2 posA;
  final Vector2 posB;
  final double radius;
  _Segment(
      {required this.staticBody,
      required this.posA,
      required this.posB,
      required this.radius});
  @override
  void create() {
    space.addShape(
        shape: SegmentShape(body: staticBody, a: posA, b: posB, radius: radius))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }
}

class _Bar extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final Vector2 posA;
  final Vector2 posB;
  final double radius;
  _Bar(
      {required this.pos,
      required this.posA,
      required this.posB,
      required this.radius});
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: 2, moment: Moment.forSegment(2, posA, posB, radius)))
      ..setPosition(pos: pos);
    var shape = space.addShape(
        shape: SegmentShape(body: body, a: posA, b: posB, radius: radius))
      ..setElasticity(0)
      ..setFriction(.7)
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));

    return (body, shape);
  }
}

class _Wheel extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double radius;

  _Wheel(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1.0,
            moment: Moment.forCircle(1.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(.5)
      ..setFriction(1)
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));

    return (body, shape);
  }
}

class _Chassis extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final Vector2 posA;
  final Vector2 posB;
  _Chassis({required this.pos, required this.posA, required this.posB});
  var mass = 5.0;
  var wd = 80.0;
  var he = 30.0;
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: 2, moment: Moment.forBox(2, wd, he)))
      ..setPosition(pos: pos);
    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0))
      ..setElasticity(0)
      ..setFriction(.7)
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));

    return (body, shape);
  }
}
