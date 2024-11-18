import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/common.dart';
import 'package:example/helper/grabber.dart';
import 'package:example/logo_smash/image_data.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:flutter/material.dart';

class LogoSmash extends StatefulWidget {
  static const route = '/logo-smash';

  const LogoSmash({super.key});

  @override
  State<LogoSmash> createState() => _LogoSmashState();
}

class _LogoSmashState extends State<LogoSmash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: LogoSmashGame()),
    );
  }
}

class LogoSmashGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  int imageWidth = 188;
  int imageHeight = 35;
  int imageRowLength = 24;

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 1)
        ..useSpatialHash(dim: 2, count: 10000),
    );

    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;

    for (var x = 0; x < imageWidth; x++) {
      for (var y = 0; y < imageHeight; y++) {
        if (!getPixel(x, y)) continue;

        double xJitter = 0.05 * _random.nextDouble();
        double yJitter = 0.05 * _random.nextDouble();
        world.add(Dot(
          Vector2(2 * (x - imageWidth / 2 + xJitter) + size.x / 2,
              -(2 * (imageHeight / 2 - y + yJitter)) + size.y / 2),
          0.95,
        ));
      }
    }
    world.add(GrabberComponent());
    world.add(Bullet(Vector2(-1000 + size.x / 2, size.y / 2), 8,
        Vector2(400, 0), 1e9, double.infinity));
  }

  bool getPixel(int x, int y) {
    return (imageBitmap[(x >> 3) + y * imageRowLength] >> (~x & 0x7)) & 1 == 0
        ? false
        : true;
  }
}

class Bullet extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final double _radius;
  final Vector2 _velocity;
  final double _mass;
  final double _moment;
  Bullet(
      this._position, this._radius, this._velocity, this._mass, this._moment);

  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: _mass, moment: _moment))
      ..setPosition(pos: _position)
      ..setVelocity(vel: _velocity);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: _radius, offset: Vector2.zero()))
      ..setElasticity(0)
      ..setFriction(0)
      ..setFilter(notGrabbableFilter);
    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawPoints(
        PointMode.points,
        [Offset.zero - transform.offset.toOffset()],
        Paint()
          ..color = Colors.white
          ..strokeWidth = _radius);
    canvas.restore();
  }
}

class Dot extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final double _radius;
  Dot(this._position, this._radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 1, moment: double.infinity))
      ..setPosition(pos: _position);
    var shape = space.addShape(
        shape: CircleShape(body: body, radius: _radius, offset: Vector2.zero()))
      ..setElasticity(0)
      ..setFriction(0);
    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawPoints(
        PointMode.points,
        [Offset.zero - transform.offset.toOffset()],
        Paint()
          ..color = Colors.white
          ..strokeWidth = _radius);
    canvas.restore();
  }
}
