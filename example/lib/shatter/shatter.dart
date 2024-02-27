// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid2d/liquid2d.dart' as d;

class Shatter extends StatefulWidget {
  static const route = '/shatter';

  const Shatter({super.key});

  @override
  State<Shatter> createState() => _ShatterState();
}

class _ShatterState extends State<Shatter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: ShatterGame()),
    );
  }
}

class ShatterGame extends FlameGame with LiquidPhysics, SecondaryTapDetector {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 500))
        ..setSleepTimeThreshold(sleepTimeThreshold: .5)
        ..setCollisionSlop(collisionSlop: .5),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);
    world.add(_Box(mid, Vector2(200, 200)));
  }

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    super.onSecondaryTapDown(info);

    var (Shape sh, PointQueryInfo infoQ) = space.pointQueryNearest(
        mouse: info.eventPosition.global, radius: 0, filter: grabFilter);
    if (sh.isExist) {
      var boundingBox = infoQ.shape.getRect();
      var cellSize = max(boundingBox.right - boundingBox.left,
              boundingBox.top - boundingBox.bottom) /
          5;
      if (cellSize > 5) {
        shatterShape(infoQ.shape, cellSize, info.eventPosition.global);
      }
    }
  }

  // shatter
  void shatterShape(Shape shape, double cellSize, Vector2 focus) {
    var bb = shape.getRect();
    int width = (((bb.right - bb.left) / cellSize) + 1).toInt();
    int height = (((bb.top - bb.bottom) / cellSize) + 1).toInt();
    var context =
        (_random.nextInt(4294967296), cellSize, width, height, bb, focus);

    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        var cell = worleyPoint(i, j, context);
        var (double val, _) = shape.pointQuery(point: cell);
        if (val < 0.0) {
          shatterCell(shape, cell, i, j, context);
        }
      }
    }

    for (var element in world.children) {
      if (element is LiquidDynamicBody) {
        if (element.getShape() == shape) {
          world.remove(element);
        }
      }
    }
  }

  void shatterCell(Shape shape, Vector2 cell, int cellI, int cellJ,
      (int, double, int, int, ui.Rect, Vector2) context) {
    var (int _, double _, int width, int height, ui.Rect _, Vector2 _) =
        context;

    var body = shape.getBody();

    var ping = <Vector2>[];
    var pong = <Vector2>[];

    int count = (shape as PolyShape).getCount();
    count =
        (count > _max_vertexes_per_voronoi ? _max_vertexes_per_voronoi : count);

    for (int i = 0; i < count; i++) {
      ping.add(body.localToWorld(shape.getVert(i)));
    }

    for (int i = 0; i < width; i++) {
      for (int j = 0; j < height; j++) {
        var (double val, _) = shape.pointQuery(point: cell);

        if (!(i == cellI && j == cellJ) && val < 0.0) {
          pong = clipCell(shape, cell, i, j, context, ping, count);
          count = pong.length;
          ping = [...pong];
        }
      }
    }

    // CREATE DRAW CREATE DRAW CREATE DRAW

    world.add(_Clip(orishape: shape, clipped: ping));
  }

  List<Vector2> clipCell(
      Shape shape,
      Vector2 center,
      int i,
      int j,
      (int, double, int, int, ui.Rect, Vector2) context,
      List<Vector2> verts,
      int count) {
    var other = worleyPoint(i, j, context);
    var (double val, _) = shape.pointQuery(point: other);

    if (val > 0.0) {
      return verts;
    }

    var n = other - center;
    var dist = n.dot(cpvlerp(center, other, 0.5));
    var clipped = <Vector2>[];

    for (int j = 0, i = count - 1; j < count; i = j, j++) {
      var a = verts[i];
      var a_dist = a.dot(n) - dist;

      if (a_dist <= 0.0) {
        clipped.add(a);
      }

      var b = verts[j];
      var b_dist = b.dot(n) - dist;

      if (a_dist * b_dist < 0.0) {
        var t = (a_dist).abs() / ((a_dist).abs() + (b_dist).abs());

        clipped.add(cpvlerp(a, b, t));
      }
    }

    return clipped;
  }

  Vector2 cpvlerp(Vector2 v1, Vector2 v2, double t) {
    return (v1 * (1.0 - t)) + v2 * t;
  }

  Vector2 worleyPoint(
      int i, int j, (int, double, int, int, ui.Rect, Vector2) context) {
    var (int rand, double size, int width, int height, ui.Rect bb, Vector2 _) =
        context;

    var fv = hashVect(i, j, rand);

    return Vector2(
      cpflerp(bb.left, bb.right, .5) + size * (i + fv.x - width * 0.5),
      cpflerp(bb.bottom, bb.top, 0.5) + size * (j + fv.y - height * 0.5),
    );
  }

  Vector2 hashVect(int x, int y, int seed) {
    var border = 0.05;
    int h = (x * 1640531513 ^ y * 2654435789) + seed;

    return Vector2(
      cpflerp(
          border, 1.0 - border, ((h & 0xFFFF).toDouble() / 0xFFFF.toDouble())),
      cpflerp(border, 1.0 - border,
          (((h >> 16) & 0xFFFF).toDouble() / 0xFFFF.toDouble())),
    );
  }

  double cpflerp(double f1, double f2, double t) {
    return f1 * (1.0 - t) + f2 * t;
  }
}

var _max_vertexes_per_voronoi = 16;

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final Vector2 _size;
  _Box(this._position, this._size) : super(position: _position, size: _size);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: width * height * 1 / 10000,
            moment: Moment.forBox(width * height * 1 / 10000, width, height)))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape:
            d.BoxShape(body: body, width: width, height: height, radius: 0.0))
      ..setFriction(.6);
    return (body, shape);
  }
}

class _Clip extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final PolyShape orishape;
  late Body oriBody;
  final List<Vector2> clipped;

  late Vector2 centroid;
  late double mass;
  late double moment;

  _Clip({required this.orishape, required this.clipped});
  @override
  (Body, Shape) create() {
    oriBody = orishape.getBody();

    centroid = Centeroid.forPoly(clipped);
    mass = Area.forPoly(clipped, 0) * (1.0 / 10000.0);
    var neg = Vector2(-centroid.x, -centroid.y);
    moment = Moment.forPoly(mass, clipped, neg, 0);

    var body = space.addBody(body: Body(mass: mass, moment: moment))
      ..setPosition(pos: centroid)
      ..setVelocity(vel: oriBody.getVelocityAtWorldPoint(point: centroid))
      ..setAngularVelocity(oriBody.getAngularVelocity());

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: clipped,
            transform: Matrix4.identity()
              ..translate(neg.x, neg.y)
              ..transposed(),
            radius: 0))
      ..setFriction(orishape.getFriction());
    return (body, shape);
  }
}
