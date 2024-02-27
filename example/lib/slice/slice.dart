// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid2d/liquid2d.dart' as d;

class Slice extends StatefulWidget {
  static const route = '/slice';

  const Slice({super.key});

  @override
  State<Slice> createState() => _SliceState();
}

class _SliceState extends State<Slice> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: SliceGame()),
    );
  }
}

class SliceGame extends FlameGame with LiquidPhysics, DragCallbacks {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  var start = Vector2.zero(), end = Vector2.zero();
  bool isSlicing = false;

  // dragy
  Vector2 mouse = Vector2.zero();
  PivotJoint? mouseJoint;
  Body mouseBody = KinematicBody();

  @override
  bool containsLocalPoint(Vector2 point) {
    super.containsLocalPoint(point);
    return true;
  }

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
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);
    await world.add(_Box(mid, Vector2(200, 300)));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    start = event.localPosition;
    isSlicing = true;

    var (Shape sh, PointQueryInfo pq) = space.pointQueryNearest(
        mouse: event.localPosition, radius: 0, filter: grabFilter);

    if (sh.isExist) {
      if (sh.getBody().getMass() < double.infinity) {
        isSlicing = false;
        Vector2 nearest = (pq.distance > 0 ? pq.point : event.localPosition);

        var body = sh.getBody();
        mouseJoint = PivotJoint(
            a: mouseBody,
            b: body,
            anchorA: Vector2.zero(),
            anchorB: body.worldToLocal(nearest))
          ..maxForce = 50000
          ..errorBias = pow(1 - .15, 60).toDouble();

        space.addConstraint(constraint: mouseJoint!);
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    end = event.localPosition;
    mouse = event.localPosition;
    event.continuePropagation;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (isSlicing) {
      space.segmentQuery(
        start: start,
        end: end,
        radius: 0,
        filter: grabFilter,
        queryFunc: slice,
      );
    }
    isSlicing = false;
    if (mouseJoint != null) {
      space.removeConstraint(constraint: mouseJoint!);
      mouseJoint!.destroy();
    }
  }

  void slice(Shape shape, Vector2 point, Vector2 normal, double alpha) {
    // Check that the slice was complete by checking that the endpoints aren't in the sliced shape.
    var (distA, _) = shape.pointQuery(point: start);
    var (distB, _) = shape.pointQuery(point: end);
    if (distA > 0.0 && distB > 0.0) {
      // Can't modify the space during a query.
      // Must make a post-step callback to do the actual slicing.
      space.addPostStepCallback<Shape>(shape, slicePost);
    }
  }

  void slicePost(Space space, Shape shape) async {
    // Clipping plane normal and distance.
    var subs = end - start;
    var n = Vector2(-subs.y, subs.x)..normalize();
    var dist = start.dot(n);

    await world
        .add(_BoxClip(orishape: shape as PolyShape, normal: n, dist: dist));
    await world.add(_BoxClip(
        orishape: shape as PolyShape, normal: n..negate(), dist: -dist));

    for (var element in world.children) {
      if (element is LiquidDynamicBody) {
        if (element.getShape() == shape) {
          world.remove(element);
        }
      }
    }
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    var newPoint = Vector2(lerpDouble(mouseBody.p.x, mouse.x, 1) ?? 0,
        lerpDouble(mouseBody.p.y, mouse.y, 1) ?? 0);
    mouseBody.v = (newPoint - mouseBody.p) * 60;
    mouseBody.p = newPoint;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    if (isSlicing) {
      canvas.drawLine(start.toOffset(), end.toOffset(),
          Paint()..color = Colors.greenAccent);
    }
    canvas.restore();
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final Vector2 _size;
  _Box(this._position, this._size) : super(position: _position, size: _size);

  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1 / 10000 * width * height,
            moment: Moment.forBox(1 / 10000 * width * height, width, height)))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape:
            d.BoxShape(body: body, width: width, height: height, radius: 0.0))
      ..setFriction(.6);

    return (body, shape);
  }
}

class _BoxClip extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final PolyShape orishape;
  final Vector2 normal;
  final double dist;
  late Body oriBody;
  late List<Vector2> clipped;

  late Vector2 centroid;
  late double mass;
  late double moment;

  late Matrix4 cenNeg;
  _BoxClip({
    required this.orishape,
    required this.normal,
    required this.dist,
  });
  Vector2 cpvlerp(Vector2 v1, Vector2 v2, double t) {
    return (v1 * (1.0 - t)) + v2 * t;
  }

  @override
  (Body, Shape) create() {
    oriBody = orishape.getBody();

    int count = orishape.getCount();
    clipped = <Vector2>[];

    for (int i = 0, j = count - 1; i < count; j = i, i++) {
      var a = oriBody.localToWorld(orishape.getVert(j));
      var a_dist = a.dot(normal) - dist;

      if (a_dist < 0.0) {
        clipped.add(a);
      }

      var b = oriBody.localToWorld(orishape.getVert(i));
      var b_dist = b.dot(normal) - dist;

      if (a_dist * b_dist < 0.0) {
        var t = a_dist.abs() / (a_dist.abs() + b_dist.abs());
        clipped.add(cpvlerp(a, b, t));
      }
    }
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
