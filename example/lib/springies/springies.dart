import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Springies extends StatefulWidget {
  static const route = '/springies';

  const Springies({super.key});

  @override
  State<Springies> createState() => _SpringiesState();
}

class _SpringiesState extends State<Springies> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: SpringiesGame()),
    );
  }
}

class SpringiesGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space,
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));

    var offset = Vector2(size.x / 2, size.y / 2);

    var sh1 = _Bar(Vector2(-240, 160) + offset, Vector2(-160, 80) + offset, 1);
    var sh2 = _Bar(Vector2(-160, 80) + offset, Vector2(-80, 160) + offset, 1);
    var sh3 = _Bar(Vector2(0, 160) + offset, Vector2(80, 0) + offset, 0);
    var sh4 = _Bar(Vector2(160, 160) + offset, Vector2(240, 160) + offset, 0);
    var sh5 = _Bar(Vector2(-240, 0) + offset, Vector2(-160, -80) + offset, 2);
    var sh6 = _Bar(Vector2(-160, -80) + offset, Vector2(-80, 0) + offset, 2);
    var sh7 = _Bar(Vector2(-80, 0) + offset, Vector2(0, 0) + offset, 2);
    var sh8 = _Bar(Vector2(0, -80) + offset, Vector2(80, -80) + offset, 0);
    var sh9 = _Bar(Vector2(240, 80) + offset, Vector2(160, 0) + offset, 3);
    var sh10 = _Bar(Vector2(160, 0) + offset, Vector2(240, -80) + offset, 3);
    var sh11 =
        _Bar(Vector2(-240, -80) + offset, Vector2(-160, -160) + offset, 4);
    var sh12 =
        _Bar(Vector2(-160, -160) + offset, Vector2(-80, -160) + offset, 4);
    var sh13 = _Bar(Vector2(0, -160) + offset, Vector2(80, -160) + offset, 0);
    var sh14 =
        _Bar(Vector2(160, -160) + offset, Vector2(240, -160) + offset, 0);

    await world.addAll([
      sh1,
      sh2,
      sh3,
      sh4,
      sh5,
      sh6,
      sh7,
      sh8,
      sh9,
      sh10,
      sh11,
      sh12,
      sh13,
      sh14
    ]);

    space.addConstraint(
        constraint: PivotJoint(
            a: sh1.getBody(),
            b: sh2.getBody(),
            anchorA: Vector2(40, -40),
            anchorB: Vector2(-40, -40)));
    space.addConstraint(
        constraint: PivotJoint(
            a: sh5.getBody(),
            b: sh6.getBody(),
            anchorA: Vector2(40, -40),
            anchorB: Vector2(-40, -40)));
    space.addConstraint(
        constraint: PivotJoint(
            a: sh6.getBody(),
            b: sh7.getBody(),
            anchorA: Vector2(40, 40),
            anchorB: Vector2(-40, 0)));
    space.addConstraint(
        constraint: PivotJoint(
            a: sh9.getBody(),
            b: sh10.getBody(),
            anchorA: Vector2(-40, -40),
            anchorB: Vector2(-40, 40)));
    space.addConstraint(
        constraint: PivotJoint(
            a: sh11.getBody(),
            b: sh12.getBody(),
            anchorA: Vector2(40, -40),
            anchorB: Vector2(-40, 0)));
    var staticBody = space.getStaticBody();
    addSpring(staticBody, sh1.getBody(), 0, 100, .5,
        Vector2(-320, 240) + offset, Vector2(-40, 40));
    addSpring(staticBody, sh1.getBody(), 0, 100, .5, Vector2(-320, 80) + offset,
        Vector2(-40, 40));
    addSpring(staticBody, sh1.getBody(), 0, 100, .5,
        Vector2(-160, 240) + offset, Vector2(-40, 40));
    addSpring(staticBody, sh2.getBody(), 0, 100, .5,
        Vector2(-160, 240) + offset, Vector2(40, 40));
    addSpring(staticBody, sh2.getBody(), 0, 100, .5, Vector2(0, 240) + offset,
        Vector2(40, 40));
    addSpring(staticBody, sh3.getBody(), 0, 100, .5, Vector2(80, 240) + offset,
        Vector2(-40, 80));
    addSpring(staticBody, sh4.getBody(), 0, 100, .5, Vector2(80, 240) + offset,
        Vector2(-40, 0));
    addSpring(staticBody, sh4.getBody(), 0, 100, .5, Vector2(320, 240) + offset,
        Vector2(40, 0));
    addSpring(staticBody, sh5.getBody(), 0, 100, .5, Vector2(-320, 80) + offset,
        Vector2(-40, 40));
    addSpring(staticBody, sh9.getBody(), 0, 100, .5, Vector2(320, 80) + offset,
        Vector2(40, 40));
    addSpring(staticBody, sh10.getBody(), 0, 100, .5, Vector2(320, 0) + offset,
        Vector2(40, -40));
    addSpring(staticBody, sh10.getBody(), 0, 100, .5,
        Vector2(320, -160) + offset, Vector2(40, -40));
    addSpring(staticBody, sh11.getBody(), 0, 100, .5,
        Vector2(-320, -160) + offset, Vector2(-40, 40));
    addSpring(staticBody, sh12.getBody(), 0, 100, .5,
        Vector2(-240, -240) + offset, Vector2(-40, 0));
    addSpring(staticBody, sh12.getBody(), 0, 100, .5, Vector2(0, -240) + offset,
        Vector2(40, 0));
    addSpring(staticBody, sh13.getBody(), 0, 100, .5, Vector2(0, -240) + offset,
        Vector2(-40, 0));
    addSpring(staticBody, sh13.getBody(), 0, 100, .5,
        Vector2(80, -240) + offset, Vector2(40, 0));
    addSpring(staticBody, sh14.getBody(), 0, 100, .5,
        Vector2(80, -240) + offset, Vector2(-40, 0));
    addSpring(staticBody, sh14.getBody(), 0, 100, .5,
        Vector2(240, -240) + offset, Vector2(40, 0));
    addSpring(staticBody, sh14.getBody(), 0, 100, .5,
        Vector2(320, -160) + offset, Vector2(40, 0));
    addSpring(sh1.getBody(), sh5.getBody(), 0, 100, .5, Vector2(40, -40),
        Vector2(-40, 40));
    addSpring(sh1.getBody(), sh6.getBody(), 0, 100, .5, Vector2(40, -40),
        Vector2(40, 40));
    addSpring(sh2.getBody(), sh3.getBody(), 0, 100, .5, Vector2(40, 40),
        Vector2(-40, 80));
    addSpring(sh3.getBody(), sh4.getBody(), 0, 100, .5, Vector2(-40, 80),
        Vector2(-40, 0));
    addSpring(sh3.getBody(), sh4.getBody(), 0, 100, .5, Vector2(40, -80),
        Vector2(-40, 0));
    addSpring(sh3.getBody(), sh7.getBody(), 0, 100, .5, Vector2(40, -80),
        Vector2(40, 0));
    addSpring(sh3.getBody(), sh7.getBody(), 0, 100, .5, Vector2(-40, 80),
        Vector2(-40, 0));
    addSpring(sh3.getBody(), sh8.getBody(), 0, 100, .5, Vector2(40, -80),
        Vector2(40, 0));
    addSpring(sh3.getBody(), sh9.getBody(), 0, 100, .5, Vector2(40, -80),
        Vector2(-40, -40));
    addSpring(sh4.getBody(), sh9.getBody(), 0, 100, .5, Vector2(40, 0),
        Vector2(40, 40));
    addSpring(sh5.getBody(), sh11.getBody(), 0, 100, .5, Vector2(-40, 40),
        Vector2(-40, 40));
    addSpring(sh5.getBody(), sh11.getBody(), 0, 100, .5, Vector2(40, -40),
        Vector2(40, -40));
    addSpring(sh7.getBody(), sh8.getBody(), 0, 100, .5, Vector2(40, 0),
        Vector2(-40, 0));
    addSpring(sh8.getBody(), sh12.getBody(), 0, 100, .5, Vector2(-40, 0),
        Vector2(40, 0));
    addSpring(sh8.getBody(), sh13.getBody(), 0, 100, .5, Vector2(-40, 0),
        Vector2(-40, 0));
    addSpring(sh8.getBody(), sh13.getBody(), 0, 100, .5, Vector2(40, 0),
        Vector2(40, 0));
    addSpring(sh8.getBody(), sh14.getBody(), 0, 100, .5, Vector2(40, 0),
        Vector2(-40, 0));
    addSpring(sh10.getBody(), sh14.getBody(), 0, 100, .5, Vector2(40, -40),
        Vector2(-40, 0));
    addSpring(sh10.getBody(), sh14.getBody(), 0, 100, .5, Vector2(40, -40),
        Vector2(-40, 0));
  }

  void addSpring(Body a, Body b, double restLength, double stiff, double damp,
      Vector2 anchorA, Vector2 anchorB) {
    var constraint = DampedSpring(
        a: a,
        b: b,
        anchorA: anchorA,
        anchorB: anchorB,
        restLength: restLength,
        stiffness: stiff,
        damping: damp)
      ..setSpringForceFunc((constraint, dist) {
        var clamp = 20.0;
        var dk = clampDouble(constraint.getRestLength() - dist, -clamp, clamp) *
            constraint.getStiffness();
        return dk;
      });

    space.addConstraint(constraint: constraint);
  }
}

class _Bar extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 a;
  final Vector2 b;
  late Vector2 mid;
  final int group;

  _Bar(this.a, this.b, this.group);

  @override
  (Body, Shape) create() {
    mid = (a + b) * 1 / 2;
    var length = (b - a).length;
    var mass = length / 160;
    var body = space.addBody(
        body: Body(mass: mass, moment: mass * length * length / 12))
      ..setPosition(pos: mid);

    var shape = space.addShape(
        shape: SegmentShape(body: body, a: a - mid, b: b - mid, radius: 10))
      ..setFilter(ShapeFilter(
          group: group, categories: allCategories, mask: allCategories));

    return (body, shape);
  }
}
