// ignore_for_file: unused_field

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

class BallFall extends StatefulWidget {
  static const route = '/';

  const BallFall({super.key});

  @override
  State<BallFall> createState() => _BallFallState();
}

class _BallFallState extends State<BallFall> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: BallFallGame()),
    );
  }
}

class BallFallGame extends FlameGame with LiquidPhysics {
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics();
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    for (int i = 0; i < 1; i++) {
      for (int j = 0; j <= i; j++) {
        world.add(Ball(
            Vector2(
              j * 32 - i * 16 + size.x / 2,
              size.y / 2 - i * 32,
            ),
            30));
      }
    }
  }

  @override
  void fixedUpdate(double timeStep) {}
}

class Dot extends PositionComponent {
  final Vector2 _position;
  final double radius;
  Dot(this._position, this.radius)
      : super(position: _position, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Colors.red);
    canvas.drawLine(
        Offset.zero,
        Offset(radius - 1, 0),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1);
    canvas.restore();
  }
}

class Ball extends PositionComponent
    with TapCallbacks, LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  Ball(this._position, this.radius)
      : super(
            position: _position,
            size: Vector2.all(radius * 2),
            anchor: Anchor.center);
  final double radius;

  @override
  bool get debugMode => true;

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    add(Dot(size / 2, 15));
  }

  @override
  void onTapDown(TapDownEvent event) {}

  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: position);

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
