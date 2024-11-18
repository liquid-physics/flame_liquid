// ignore_for_file: unused_field, non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';
import 'package:flutter/services.dart';
import 'package:liquid2d/liquid2d.dart' as d;

class Player extends StatefulWidget {
  static const route = '/player';

  const Player({super.key});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PlayerGame()),
    );
  }
}

class PlayerGame extends FlameGame with LiquidPhysics, KeyboardEvents {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
        initial: (space) => space
          ..setIternation(iterations: 10)
          ..setGravity(
            gravity: Vector2(0, 2000),
          ));
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);

    world.addAll([
      for (var i = 0; i < 5; i++)
        for (var j = 0; j < 3; j++)
          _Box(Vector2(100 + j * 60, -200 + i * 60).flipY() + mid,
              Vector2(50, 50))
    ]);

    world.add(_Player(Vector2(0, -200).flipY() + mid, Vector2(30, 55)));
  }

  int keyx = 0, keyy = 0;
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is KeyDownEvent;
    final isKeyUp = event is KeyUpEvent;

    if (isKeyDown) {
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) keyy = -1;
      if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) keyx = -1;
      if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) keyx = 1;
    }
    if (isKeyUp) {
      keyx = 0;
      keyy = 0;
    }
    return KeyEventResult.ignored;
  }
}

class _Box extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final Vector2 _size;
  _Box(this._position, this._size) : super(position: _position, size: _size);

  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 4, moment: double.infinity))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape:
            d.BoxShape(body: body, width: width, height: height, radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.7);
    return (body, shape);
  }
}

class _Player extends PositionComponent
    with
        LiquidPhysicsComponent,
        LiquidDynamicBody,
        HasGameRef<PlayerGame>,
        LiquidFixedUpdate {
  final Vector2 _position;
  final Vector2 _size;
  _Player(this._position, this._size) : super(position: _position, size: _size);
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: 1, moment: double.infinity))
      ..setPosition(pos: position)
      ..setVelocity(vel: Vector2(0, -500))
      ..setVelocityUpdateFunc(velocityFunc);
    var shape = space.addShape(
        shape: d.BoxShape(body: body, width: width, height: height, radius: 10))
      ..setFriction(0)
      ..setElasticity(0)
      ..setCollisionType(1);
    return (body, shape);
  }

  var lastJumpState = false;
  var jumpStated = false;
  var grounded = false;
  var remainingBoost = 0.0;
  @override
  void fixedUpdate(double timeStep) {
    jumpStated = (game.keyy < 0.0);

    // If the jump key was just pressed this frame, jump!
    if (jumpStated && !lastJumpState && grounded) {
      double jump_v = sqrt(2.0 * 50 * 900);
      getBody().setVelocity(vel: getBody().getVelocity() + Vector2(0, -jump_v));

      remainingBoost = 1000 / -jump_v;
    }

    remainingBoost += timeStep;
    lastJumpState = jumpStated;
  }

  void velocityFunc(Body body, Vector2 gravity, double damping, double dt) {
    bool jumpState = (game.keyy < 0.0);

    // Grab the grounding normal from last frame
    var groundNormal = Vector2.zero();
    getBody().eachArbiter(
      (body, arbiter) {
        var n = arbiter.getNormal()..negate();
        if (n.y < groundNormal.y) {
          groundNormal = n;
        }
      },
    );

    grounded = (groundNormal.y < 0.0);
    //print(groundNormal.y);
    if (groundNormal.y > 0.0) remainingBoost = 0.0;

    // // Do a normal-ish update
    bool boost = (jumpState && remainingBoost < 0.0);
    var g = (boost ? Vector2.zero() : gravity);
    //print('${remainingBoost} $boost');
    body.updateVelocity(gravity: g, damping: damping, dt: dt);

    // Target horizontal speed for air/ground control
    double target_vx = 500.0 * game.keyx;

    // Update the surface velocity and friction
    // Note that the "feet" move in the opposite direction of the player.
    var surface_v = Vector2(-target_vx, 0.0);
    getShape().setSurfaceVelocity(surface_v);
    getShape().setFriction(grounded ? 500 / 0.1 / 2000 : 0.0);

    // Apply air control if not grounded
    if (!grounded) {
      // Smoothly accelerate the velocity
      getBody().setVelocity(
          vel: Vector2(
              lerpConst(getBody().getVelocity().x, target_vx, 500 / 0.25 * dt),
              getBody().getVelocity().y));
    }
    body.setVelocity(
        vel: Vector2(body.getVelocity().x,
            clampDouble(body.getVelocity().y, -900, double.infinity)));
  }

  double lerpConst(double f1, double f2, double d) {
    return f1 + clampDouble(f2 - f1, -d, d);
  }
}
