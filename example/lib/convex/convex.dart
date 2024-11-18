// ignore_for_file: unused_field, library_private_types_in_public_api

import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Convex extends StatefulWidget {
  static const route = '/convex';

  const Convex({super.key});

  @override
  State<Convex> createState() => _ConvexState();
}

class _ConvexState extends State<Convex> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: ConvexGame()),
    );
  }
}

class ConvexGame extends FlameGame
    with LiquidPhysics, SecondaryTapDetector, DragCallbacks {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  late _Box box;
  bool isRightClick = false;
  var mouse = Vector2.zero();
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
    //world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);
    box = _Box(mid, Vector2(50, 70));
    await world.add(box);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    mouse = event.localPosition;
    isRightClick = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    mouse = event.localStartPosition;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isRightClick = false;
  }

  @override
  void fixedUpdate(double timeStep) {
    var tolerance = 2.0;
    var shape = box.shapeT as PolyShape;
    if (isRightClick && shape.pointQuery(point: mouse).$1 > tolerance) {
      var body = shape.getBody();
      var count = shape.getCount();
      var verts = <Vector2>[];
      for (var i = 0; i < count; i++) {
        verts.add(shape.getVert(i));
      }

      verts.add(body.worldToLocal(mouse));
      var hullC = quickHull(verts, tolerance);
      var centroid = Centeroid.forPoly(hullC.$2);

      var neg = Vector2(-centroid.x, -centroid.y);

      // Recalculate the body properties to match the updated shape.
      var mass = (Area.forPoly(verts, 0) * 1 / 10000).abs();
      body.setMass(mass);
      body.setMoment(Moment.forPoly(mass, verts, neg, 0));
      body.setPosition(pos: body.localToWorld(centroid));
      //print('$mouse $isRightClick $mass $verts');

      // Use the setter function from chipmunk_unsafe.h.
      // You could also remove and recreate the shape if you wanted.
      space.removeShape(shape: shape);
      box.poly = verts;
      //box.centroid = centroid;
      box.shapeT = space.addShape(
          shape: PolyShape(
              body: body,
              vert: verts,
              transform: Matrix4.identity()
                ..translate(neg.x, neg.y)
                ..transposed(),
              radius: 0))
        ..setFriction(.6);
    }
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final Vector2 _size;
  late List<Vector2> poly;
  late Shape shapeT;
  _Box(this._position, this._size) : super(position: _position, size: _size);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: width * height * 1 / 10000,
            moment: Moment.forBox(width * height * 1 / 10000, width, height)))
      ..setPosition(pos: position);
    poly = [
      Vector2(-width / 2, height / 2),
      Vector2(width / 2, height / 2),
      Vector2(width / 2, -height / 2),
      Vector2(-width / 2, -height / 2)
    ];
    var shape = shapeT = space.addShape(
        shape: PolyShape(
            body: body, vert: poly, transform: Matrix4.identity(), radius: 0))
      ..setFriction(.6);

    return (body, shape);
  }
}
