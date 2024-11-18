import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Tumble extends StatefulWidget {
  static const route = '/tumble';

  const Tumble({super.key});

  @override
  State<Tumble> createState() => _TumbleState();
}

class _TumbleState extends State<Tumble> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: TumbleGame()),
    );
  }
}

class TumbleGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  // ignore: unnecessary_overrides
  bool get renderDebug => super.renderDebug;

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space..setGravity(gravity: Vector2(0, 600));
      },
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    var mid = Vector2(size.x / 2, size.y / 2);
    Body kinematicBody = space.addBody(
        body: KinematicBody()..setPosition(pos: mid))
      ..setAngularVelocity(.4);
    var a = Vector2(-200, -200);
    var b = Vector2(-200, 200);
    var c = Vector2(200, 200);
    var d = Vector2(200, -200);

    world.addAll([
      _Terrain(kinematicBody, a, b, mid),
      _Terrain(kinematicBody, b, c, mid),
      _Terrain(kinematicBody, c, d, mid),
      _Terrain(kinematicBody, d, a, mid),
    ]);
    for (var i = 0; i < 10; i++) {
      world.add(Circle(Vector2.zero() + mid, 20));
    }
  }
}

class _Terrain extends PositionComponent
    with LiquidPhysicsComponent, LiquidKinematicBody {
  final Body body;
  final Vector2 a;
  final Vector2 b;
  final Vector2 mid;
  _Terrain(this.body, this.a, this.b, this.mid) : super(position: mid);
  @override
  void create() {
    space.addShape(shape: SegmentShape(body: body, a: a, b: b, radius: 0))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    rotate(canvas: canvas, cx: 0, cy: 0, angle: body.getAngle());
    canvas.drawLine(
        Offset(a.x, a.y) - transform.offset.toOffset(),
        Offset(b.x, b.y) - transform.offset.toOffset(),
        Paint()
          ..color = Colors.white
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1);
    canvas.restore();
  }

  void rotate(
      {required Canvas canvas,
      required double cx,
      required double cy,
      required double angle}) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
  }
}

class Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  Circle(this._position, this.radius)
      : super(
          size: Vector2.all(radius * 2),
        );
  final double radius;

  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: _position);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(.5)
      ..setFriction(1);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawCircle(Offset.zero - transform.offset.toOffset(), radius,
        Paint()..color = Colors.purple);
    canvas.drawLine(
        Offset.zero - transform.offset.toOffset(),
        Offset(radius - 1, 0) - transform.offset.toOffset(),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1);
    canvas.restore();
  }
}
