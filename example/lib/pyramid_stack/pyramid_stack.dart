import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart' as lq;
import 'package:example/helper/common.dart';

class PyramidStack extends StatefulWidget {
  static const route = '/pyramid-stack';

  const PyramidStack({super.key});

  @override
  State<PyramidStack> createState() => _PyramidStackState();
}

class _PyramidStackState extends State<PyramidStack> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PyramidStackGame()),
    );
  }
}

class PyramidStackGame extends FlameGame with lq.LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space
          ..setIternation(iterations: 30)
          ..setGravity(gravity: Vector2(0, 100))
          ..setSleepTimeThreshold(sleepTimeThreshold: .5)
          ..setCollisionSlop(collisionSlop: .5);
      },
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    for (int i = 0; i < 14; i++) {
      for (int j = 0; j <= i; j++) {
        world.add(_Box(
          30,
          30,
          Vector2(j * 32 - i * 16 + size.x / 2, -(300 - i * 32 + size.y / 2)),
          Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
        ));
      }
    }
  }
}

class _Box extends PositionComponent
    with lq.LiquidPhysicsComponent, lq.LiquidDynamicBody {
  final Vector2 pos;
  final Color color;
  _Box(double width, double height, this.pos, this.color)
      : super(size: Vector2(width, height));

  @override
  (lq.Body, lq.Shape) create() {
    var body = space.addBody(
        body: lq.Body(mass: 1, moment: lq.Moment.forBox(1, size.x, size.y)))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape:
            lq.BoxShape(body: body, width: width, height: height, radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.8);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero - transform.offset.toOffset(),
            width: width,
            height: height),
        Paint()..color = color);
    canvas.restore();
  }
}
