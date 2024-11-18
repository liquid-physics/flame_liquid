// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid2d/liquid2d.dart' as d;

class Buoyancy extends StatefulWidget {
  static const route = '/buoyancy';

  const Buoyancy({super.key});

  @override
  State<Buoyancy> createState() => _BuoyancyState();
}

class _BuoyancyState extends State<Buoyancy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: BuoyancyGame()),
    );
  }
}

class BuoyancyGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  var centroid = Vector2.zero();
  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 500))
        ..setSleepTimeThreshold(sleepTimeThreshold: .5)
        ..setCollisionSlop(collisionSlop: .5),
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var staticBody = space.getStaticBody();
    var mid = Vector2(size.x / 2, size.y / 2);
    var rb = Rect.fromLBRT(-300, 200, 100, 0).translate(mid.x, mid.y);

    world.addAll([
      _Segment(
          radius: 5,
          posA: Vector2(rb.left, rb.bottom),
          posB: Vector2(rb.left, rb.top),
          staticBody: staticBody),
      _Segment(
          radius: 5,
          posA: Vector2(rb.right, rb.bottom),
          posB: Vector2(rb.right, rb.top),
          staticBody: staticBody),
      _Segment(
          radius: 5,
          posA: Vector2(rb.left, rb.bottom),
          posB: Vector2(rb.right, rb.bottom),
          staticBody: staticBody),
      _Water(radius: 0, rect: rb, staticBody: staticBody),
      _Box(Vector2(-50, 0).flipY() + mid, 200, 50),
      _Box(Vector2(-200, 0).flipY() + mid, 40, 80)
    ]);

    space.addCollisionHandler(aType: 1, bType: 0).preSolve((arbiter, space) {
      var (Shape water, Shape poly) = arbiter.getShapes();
      var body = poly.getBody();
      var level = water.getRect().bottom;
      var count = (poly as d.BoxShape).getCount();
      var clipped = <Vector2>[];

      for (int i = 0, j = count - 1; i < count; j = i, i++) {
        Vector2 a = body.localToWorld(poly.getVert(j));
        Vector2 b = body.localToWorld(poly.getVert(i));

        //print('$a $b $level');

        if (a.y > level) {
          clipped.add(a);
        }

        double a_level = level - a.y;
        double b_level = level - b.y;

        if (a_level * b_level < 0.0) {
          double t = a_level.abs() / (a_level.abs() + b_level.abs());
          clipped.add(Vector2(
              lerpDouble(a.x, b.x, t) ?? 0, lerpDouble(a.y, b.y, t) ?? 0));
        }
      }
      double clippedArea = Area.forPoly(clipped, 0);
      double displacedMass = clippedArea * .00014;
      centroid = Centeroid.forPoly(clipped);
      //print(centroid);
      double dt = space.getCurrentTimeStep();
      Vector2 g = space.getGravity();

      // Apply the buoyancy force as an impulse.
      body.applyImpulseAtWorldPoint(
          impulse: g * -displacedMass * dt, point: centroid);

      // Apply linear damping for the fluid drag.
      Vector2 v_centroid = body.getVelocityAtWorldPoint(point: centroid);
      double rcn =
          (centroid - body.getPosition() - mid).cross(v_centroid.normalized());

      double k = 1.0 / body.getMass() + rcn * rcn / body.getMoment();

      double damping = clippedArea * 2.0 * .00014;
      double v_coef = exp(-damping * dt * k); // linear drag
      body.applyImpulseAtWorldPoint(
          impulse: ((v_centroid * v_coef) - v_centroid) * 1 / k,
          point: centroid);

      Vector2 cog = body.localToWorld(body.getCenterOfGravity());
      double w_damping =
          Moment.forPoly(2.0 * .00014 * clippedArea, clipped, cog..negate(), 0);
      body.setAngularVelocity(
          body.getAngularVelocity() * exp(-w_damping * dt / body.getMoment()));
      return true;
    });
  }

  TextPaint textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 8.0,
      fontFamily: 'Awesome Font',
    ),
  );
  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    var si = 50.0;
    for (var i = 0; i < size.y / si; i++) {
      canvas.drawLine(Offset(0, i * si), Offset(size.x, i * si),
          Paint()..color = Colors.white);
      textPaint.render(canvas, '${i * si}', Vector2(10, i * si),
          anchor: Anchor.centerLeft);
    }
    for (var i = 0; i < size.x / si; i++) {
      canvas.drawLine(Offset(i * si, 0), Offset(i * si, size.y),
          Paint()..color = Colors.white);
      textPaint.render(canvas, '${i * si}', Vector2(i * si, 10),
          anchor: Anchor.centerLeft);
    }

    canvas.drawCircle(centroid.toOffset(), 5, Paint()..color = Colors.red);
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Vector2 posA;
  final Vector2 posB;
  final double radius;
  final Body staticBody;

  _Segment(
      {required this.posA,
      required this.posB,
      required this.radius,
      required this.staticBody});

  @override
  void create() {
    space.addShape(
        shape: SegmentShape(body: staticBody, a: posA, b: posB, radius: radius))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }
}

class _Water extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final ui.Rect rect;
  final double radius;
  final Body staticBody;

  _Water({required this.rect, required this.radius, required this.staticBody});

  @override
  void create() {
    space.addShape(
        shape:
            d.BoxShape.fromRect(body: staticBody, rect: rect, radius: radius))
      ..setSensor(true)
      ..setCollisionType(1);
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
        body: Body(
            mass: .00014 * .3 * wd * he,
            moment: Moment.forBox(.00014 * .3 * wd * he, wd, he)))
      ..setPosition(pos: pos)
      ..setVelocity(vel: Vector2(0, 100))
      ..setAngularVelocity(-1);

    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0.0))
      ..setFriction(.8);

    return (body, shape);
  }
}
