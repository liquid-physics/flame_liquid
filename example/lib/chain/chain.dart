import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Chain extends StatefulWidget {
  static const route = '/chain';

  const Chain({super.key});

  @override
  State<Chain> createState() => _ChainState();
}

class _ChainState extends State<Chain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: ChainGame()),
    );
  }
}

class ChainGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 100))
        ..setSleepTimeThreshold(sleepTimeThreshold: .5),
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));
    var mid = Vector2(size.x / 2, size.y / 2);

    var width = 20;
    var height = 30;
    var staticBody = space.getStaticBody();

    var spacing = width * 0.3;
    for (var i = 0; i < 8; i++) {
      Body? prev;
      for (var j = 0; j < 10; j++) {
        var pos = Vector2(40 * (i - (8 - 1) / 2.0),
                    240 - (j + 0.5) * height - (j + 1) * spacing)
                .flipY() +
            mid;
        var bd = _Box(pos);
        await world.add(bd);
        var breakingForce = 80000.0;
        if (prev == null) {
          space.addConstraint(
              constraint: SlideJoint(
                  a: bd.getBody(),
                  b: staticBody,
                  anchorA: Vector2(0, height / 2).flipY(),
                  anchorB: Vector2(pos.x, 240).flipY() + Vector2(0, mid.y),
                  min: 0,
                  max: spacing))
            ..setMaxForce(breakingForce)
            ..setCollideBody(false)
            ..setPostSolveFunc(breakableJointPostSolve);
        } else {
          space.addConstraint(
              constraint: SlideJoint(
                  a: bd.getBody(),
                  b: prev,
                  anchorA: Vector2(0, height / 2).flipY(),
                  anchorB: Vector2(0, -height / 2).flipY(),
                  min: 0,
                  max: spacing))
            ..setMaxForce(breakingForce)
            ..setCollideBody(false)
            ..setPostSolveFunc(breakableJointPostSolve);
        }

        prev = bd.getBody();
      }
    }

    world.add(_Circle(Vector2(0, -240 + 15 + 5).flipY() + mid, 15));
  }

  void breakableJointPostSolve(Constraint constraint, Space space) {
    double dt = space.getCurrentTimeStep();

    // Convert the impulse to a force by dividing it by the timestep.
    double force = constraint.getImpulse() / dt;
    double maxForce = constraint.getMaxForce();
    //print('$force, $maxForce');

    // If the force is almost as big as the joint's max force, break it.
    if (force > 0.9 * maxForce) {
      space.addPostStepCallback<Constraint>(
          constraint, breakablejointPostStepRemove);
    }
  }

  void breakablejointPostStepRemove(Space space, Constraint constraint) {
    space.removeConstraint(constraint: constraint);
    constraint.destroy();
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final double wd = 20;
  final double he = 30;
  static const double mass = 1;
  final Vector2 pos;

  _Box(this.pos);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: mass, moment: Moment.forBox(mass, wd, he)))
      ..setPosition(pos: pos);
    var shape = space.addShape(
        shape: SegmentShape(
            body: body,
            a: Vector2(0, (he - wd) / 2.0),
            b: Vector2(0, (wd - he) / 2.0),
            radius: wd / 2.0))
      ..setFriction(.8);

    return (body, shape);
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double radius;
  _Circle(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: pos)
      ..setVelocity(vel: Vector2(0, -300));

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(0)
      ..setFriction(.9);
    return (body, shape);
  }
}
