import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class OneWay extends StatefulWidget {
  static const route = '/one-way';

  const OneWay({super.key});

  @override
  State<OneWay> createState() => _OneWayState();
}

class _OneWayState extends State<OneWay> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: OneWayGame()),
    );
  }
}

class OneWayGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space
          ..setIternation(iterations: 10)
          ..setGravity(gravity: Vector2(0, 100));
      },
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));

    world.add(_Segment());
    world.add(_Circle());

    space.addWildcardHandler(type: 1)
      ..preSolve((arbiter, space) {
        if (arbiter.getNormal().dot(Vector2(0, -1)) < 0) {
          return arbiter.ignore();
        }
        return true;
      })
      ..postSolve((arbiter, space) {});
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody, HasGameRef<OneWayGame> {
  var a = Vector2(-160, -100);
  var b = Vector2(160, -100);

  @override
  void create() {
    space.addShape(
        shape: SegmentShape(
            body: space.getStaticBody(),
            a: a.flipY() + Vector2(game.size.x / 2, game.size.y / 2),
            b: b.flipY() + Vector2(game.size.x / 2, game.size.y / 2),
            radius: 10))
      ..setElasticity(1)
      ..setFriction(1)
      ..setCollisionType(1)
      ..setFilter(notGrabbableFilter);
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<OneWayGame> {
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, 15, Vector2.zero())))
      ..setPosition(
          pos: Vector2(0, -200).flipY() +
              Vector2(game.size.x / 2, game.size.y / 2))
      ..setVelocity(vel: Vector2(0, -170));

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: 15, offset: Vector2.zero()))
      ..setElasticity(0)
      ..setFriction(.9)
      ..setCollisionType(2);

    return (body, shape);
  }
}
