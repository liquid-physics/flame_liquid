import 'dart:async';
import 'dart:math';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:liquid/src/liquid.dart' as d;

class ContactGraph extends StatefulWidget {
  static const route = '/contact-graph';

  const ContactGraph({super.key});

  @override
  State<ContactGraph> createState() => _ContactGraphState();
}

class _ContactGraphState extends State<ContactGraph> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: ContactGraphGame()),
    );
  }
}

class ContactGraphGame extends FlameGame with LiquidPhysics {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  var textDesc = '';
  var textDesc1 = '';
  var textDesc2 = '';
  var impulseSum = Vector2.zero();
  var count = 0;
  var magnitudoSum = 0.0;
  var vectorSum = Vector2.zero();
  late Body scaleBody;
  late Body circle;

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 30)
        ..setGravity(gravity: Vector2(0, 300))
        ..setCollisionSlop(collisionSlop: .5)
        ..setSleepTimeThreshold(sleepTimeThreshold: 1),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    var mid = Vector2(size.x / 2, size.y / 2);
    world.add(LiquidDebugDraw(space));
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    scaleBody = space.addBody(body: StaticBody());
    world.add(_Segment(Vector2(-240, -180).flipY() + mid,
        Vector2(-140, -180).flipY() + mid, 4, scaleBody));

    for (var i = 0; i < 5; i++) {
      world.add(_Box(Vector2(0, i * 32 - 220).flipY() + mid, 30, 30));
    }
    var c = _Circle(Vector2(120, -240 + 15 + 5).flipY() + mid, 15);
    await world.add(c);
    circle = c.getBody();
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    impulseSum = Vector2.zero();
    scaleBody.eachArbiter(scale);

    var force = impulseSum.length / timeStep;
    var g = space.getGravity();
    var weight = g.dot(impulseSum) / (g.length2 * timeStep);
    textDesc =
        'Total force: ${force.toStringAsFixed(2)}, Total weight: ${weight.toStringAsFixed(2)}. ';

    count = 0;
    circle.eachArbiter(ball);
    textDesc1 = 'The ball is touching $count shapes.';

    magnitudoSum = 0.0;
    vectorSum = Vector2.zero();
    circle.eachArbiter(estimate);

    double crushForce = (magnitudoSum - vectorSum.length) * timeStep;
    if (crushForce > 10.0) {
      textDesc2 =
          "The ball is being crushed. (f: ${crushForce.toStringAsFixed(2)})";
    } else {
      textDesc2 =
          "The ball is not being crushed. (f: ${crushForce.toStringAsFixed(2)})";
    }
  }

  void scale(Body body, Arbiter arbiter) {
    impulseSum += arbiter.totalImpulse();
  }

  void ball(Body body, Arbiter arbiter) {
    count++;
  }

  void estimate(Body body, Arbiter arbiter) {
    var j = arbiter.totalImpulse();
    magnitudoSum += j.length;
    vectorSum = vectorSum + j;
  }

  TextPaint textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 15.0,
      fontFamily: 'Awesome Font',
    ),
  );
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    textPaint.render(
        canvas, '$textDesc\n$textDesc1\n$textDesc2', Vector2(10, size.y),
        anchor: Anchor.bottomLeft);
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Vector2 posA;
  final Vector2 posB;
  final double radius;
  final Body body;
  _Segment(this.posA, this.posB, this.radius, this.body);
  @override
  void create() {
    space.addShape(
        shape: SegmentShape(body: body, a: posA, b: posB, radius: radius))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
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
        body: Body(mass: 1, moment: Moment.forBox(1, wd, he)))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: wd, height: he, radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.8);

    return (body, shape);
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final double radius;
  _Circle(this.pos, this.radius);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 10.0,
            moment: Moment.forCircle(10.0, 0.0, radius, Vector2.zero())))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(0)
      ..setFriction(.9);

    return (body, shape);
  }
}
