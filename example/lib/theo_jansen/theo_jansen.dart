// ignore_for_file: library_private_types_in_public_api

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
import 'package:flutter/services.dart';

class TheoJansen extends StatefulWidget {
  static const route = '/theo-jansen';

  const TheoJansen({super.key});

  @override
  State<TheoJansen> createState() => _TheoJansenState();
}

class _TheoJansenState extends State<TheoJansen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: TheoJansenGame()),
    );
  }
}

class TheoJansenGame extends FlameGame with LiquidPhysics, KeyboardEvents {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  var mid = Vector2.zero();
  late SimpleMotor motor;

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 20)
        ..setGravity(gravity: Vector2(0, 500)),
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    mid = Vector2(size.x / 2, size.y / 2);
    var chassis = _Chassis();
    await world.add(chassis);
    var cranks = _Cranks(13);
    await world.add(cranks);
    space.addConstraint(
        constraint: PivotJoint(
            a: chassis.getBody(),
            b: cranks.getBody(),
            anchorA: Vector2.zero(),
            anchorB: Vector2.zero()));

    var side = 30.0;
    var offsetX = 30.0;

    for (var i = 0; i < 2; i++) {
      createLeg(
          chassis,
          cranks,
          offsetX,
          side,
          Vector2(cos(2 * i + 0 / 2 * pi), sin(2 * i + 0 / 2 * pi)).flipY() *
              13);
      createLeg(
          chassis,
          cranks,
          -offsetX,
          side,
          Vector2(cos(2 * i + 1 / 2 * pi), sin(2 * i + 1 / 2 * pi)).flipY() *
              13);
    }
    motor = space.addConstraint(
        constraint:
            SimpleMotor(a: chassis.getBody(), b: cranks.getBody(), rate: 6));
  }

  void createLeg(_Chassis chassis, _Cranks cranks, double offsetX, double side,
      Vector2 anchor) async {
    var upperLeg = _UpperLeg(chassis.getBody(), offsetX, side);
    var lowerLeg = _LowerLeg(offsetX, side);
    await world.addAll([upperLeg, lowerLeg]);

    space.addConstraint(
        constraint: PinJoint(
            a: chassis.getBody(),
            b: lowerLeg.getBody(),
            anchorA: Vector2(offsetX, 0),
            anchorB: Vector2.zero()));
    space.addConstraint(
        constraint: GearJoint(
            a: upperLeg.getBody(), b: lowerLeg.getBody(), phase: 0, ratio: 1));

    var diag = sqrt(side * side + offsetX * offsetX);
    (space.addConstraint(
            constraint: PinJoint(
                a: cranks.getBody(),
                b: upperLeg.getBody(),
                anchorA: anchor,
                anchorB: Vector2(0, side).flipY())))
        .setDist(diag);
    (space.addConstraint(
            constraint: PinJoint(
                a: cranks.getBody(),
                b: lowerLeg.getBody(),
                anchorA: anchor,
                anchorB: Vector2.zero())))
        .setDist(diag);
  }

  var x = 0;
  var y = 0;

  @override
  void fixedUpdate(double timeStep) {
    double coef = (2.0 + y) / 3.0;
    double rate = x * 10.0 * coef;
    motor.setRate(rate);
    motor.setMaxForce(rate > 0 || rate < 0 ? 1000000.0 : 0);
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;
    final isKeyUp = event is KeyUpEvent;

    if (isKeyDown) {
      if (keysPressed.contains(LogicalKeyboardKey.bracketLeft)) x = 1;
      if (keysPressed.contains(LogicalKeyboardKey.bracketRight)) x = -1;
    }
    if (isKeyUp) {
      x = 0;
    }
    return KeyEventResult.ignored;
  }
}

class _Chassis extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<TheoJansenGame> {
  Vector2 a = Vector2(-30, 0);
  Vector2 b = Vector2(30, 0);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: 2, moment: Moment.forSegment(2, a, b, 0)))
      ..setPosition(pos: game.mid);
    var shape = space.addShape(
        shape: SegmentShape(body: body, a: a, b: b, radius: 3))
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));

    return (body, shape);
  }
}

class _Cranks extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<TheoJansenGame> {
  final double radius;
  _Cranks(this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1.0,
            moment: Moment.forCircle(1.0, radius, 0, Vector2.zero())))
      ..setPosition(pos: game.mid);
    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));
    return (body, shape);
  }
}

class _UpperLeg extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<TheoJansenGame> {
  var a = Vector2.zero();
  var b = Vector2.zero();
  var legMass = 1.0;
  var radius = 3.0;

  final Body chassis;
  final double offsetX;
  final double side;
  _UpperLeg(this.chassis, this.offsetX, this.side) {
    b = Vector2(0, side).flipY();
  }
  @override
  (Body, Shape) create() {
    var upperLeg = space.addBody(
        body: Body(mass: legMass, moment: Moment.forSegment(legMass, a, b, 0)))
      ..setPosition(pos: Vector2(offsetX, 0) + game.mid);
    var shape = space.addShape(
        shape: SegmentShape(body: upperLeg, a: a, b: b, radius: radius))
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));
    space.addConstraint(
        constraint: PivotJoint(
            a: chassis,
            b: upperLeg,
            anchorA: Vector2(offsetX, 0),
            anchorB: Vector2.zero()));
    return (upperLeg, shape);
  }
}

class _LowerLeg extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<TheoJansenGame> {
  var a = Vector2.zero();
  var b = Vector2.zero();
  var legMass = 1.0;
  var radius = 3.0;
  final double side;
  final double offsetX;

  _LowerLeg(this.offsetX, this.side) {
    b = Vector2(0, -1 * side).flipY();
  }
  @override
  (Body, Shape) create() {
    var lowerLeg = space.addBody(
        body: Body(mass: legMass, moment: Moment.forSegment(legMass, a, b, 0)))
      ..setPosition(pos: Vector2(offsetX, -side).flipY() + game.mid);
    var shape = space.addShape(
        shape: SegmentShape(body: lowerLeg, a: a, b: b, radius: radius))
      ..setFilter(ShapeFilter(
          group: 1, categories: allCategories, mask: allCategories));

    // shoes
    shape = space.addShape(
        shape: CircleShape(body: lowerLeg, radius: radius * 2, offset: b))
      ..setFilter(
          ShapeFilter(group: 1, categories: allCategories, mask: allCategories))
      ..setElasticity(0)
      ..setFriction(1);

    return (lowerLeg, shape);
  }
}
