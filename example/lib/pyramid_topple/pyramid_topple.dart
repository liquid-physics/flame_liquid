import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart' as lq;
import 'package:example/helper/common.dart';

class PyramidTopple extends StatefulWidget {
  static const route = '/pyramid-topple';

  const PyramidTopple({super.key});

  @override
  State<PyramidTopple> createState() => _PyramidToppleState();
}

class _PyramidToppleState extends State<PyramidTopple> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PyramidToppleGame()),
    );
  }
}

class PyramidToppleGame extends FlameGame with lq.LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  @override
  bool get renderDebug => false;

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space
          ..setIternation(iterations: 30)
          ..setGravity(gravity: Vector2(0, 300))
          ..setSleepTimeThreshold(sleepTimeThreshold: 0.5)
          ..setCollisionSlop(collisionSlop: 0.5);
      },
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    int n = 12;
    double width = 4;
    double height = 30;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < (n - i); j++) {
        var offset = Vector2((j - (n - 1 - i) * 0.5) * 1.5 * height,
                (i + 0.5) * (height + 2 * width) - width) +
            Vector2(size.x / 2, -size.y);

        world.add(_Domino(offset, false));
        world.add(_Domino(offset + Vector2(0, (width + height) / 2), true));

        if (j == 0) {
          world.add(_Domino(
              offset + Vector2(.5 * (width - height), height + width), false));
        }

        if (j != n - i - 1) {
          world.add(_Domino(
              offset + Vector2(height * .75, (height + 3 * width) / 2), true));
        } else {
          world.add(_Domino(
              offset + Vector2(.5 * (height - width), height + width), false));
        }
      }
    }
  }
}

class _Domino extends PositionComponent
    with lq.LiquidPhysicsComponent, lq.LiquidDynamicBody {
  final bool flipped;
  final Vector2 pos;
  static double wd = 4;
  static double he = 30;
  _Domino(this.pos, this.flipped);

  @override
  (lq.Body, lq.Shape) create() {
    var body = space.addBody(
        body: lq.Body(mass: 1, moment: lq.Moment.forBox(1, wd, he)))
      ..setPosition(pos: Vector2(pos.x, -pos.y));
    var shape = space.addShape(
        shape: flipped
            ? lq.BoxShape(body: body, height: wd, width: he, radius: 0)
            : lq.BoxShape(
                body: body, width: wd - .5 * 2, height: he, radius: .5))
      ..setElasticity(0)
      ..setFriction(.6);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero - transform.offset.toOffset(),
            width: flipped ? he : wd,
            height: flipped ? wd - .5 * 2 : he),
        Paint()..color = Colors.blueAccent);

    canvas.restore();
  }
}
