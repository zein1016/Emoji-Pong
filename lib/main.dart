import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: GameWidget(game: MyGame()),
      ),
    ),
  );
}

class MyGame extends FlameGame with HasCollisionDetection, HasTappables, HasDraggables {
  late Ball ball;
  late Paddle playerPaddle;
  late Paddle enemyPaddle;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set up the player's paddle
    playerPaddle = Paddle(
      position: Vector2(50, size.y / 2),
      size: Vector2(20, 100),
      isPlayerControlled: true,
    );
    add(playerPaddle);

    // Set up the enemy's paddle (AI controlled)
    enemyPaddle = Paddle(
      position: Vector2(size.x - 70, size.y / 2),
      size: Vector2(20, 100),
      isPlayerControlled: false,
    );
    add(enemyPaddle);

    // Set up the ball
    ball = Ball(
      position: size / 2,
      radius: 10,
    );
    add(ball);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Simple AI to follow the ball
    enemyPaddle.position.y = ball.position.y;
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    // Restart game or other interactions
  }
}

class Paddle extends RectangleComponent with CollisionCallbacks, HasGameRef<MyGame>, Draggable {
  final bool isPlayerControlled;
  static const double speed = 300;

  Paddle({
    required Vector2 position,
    required Vector2 size,
    required this.isPlayerControlled,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // AI-controlled paddle
    if (!isPlayerControlled) {
      // The AI simply follows the ball
      position.y = ball.position.y;
    }
  }

  @override
  bool onDragUpdate(int pointerId, DragUpdateInfo event) {
    if (isPlayerControlled) {
      // Move the paddle based on the drag
      position.y += event.delta.game.y;
      // Keep the paddle within the screen bounds
      position.y = position.y.clamp(size.y / 2, gameRef.size.y - size.y / 2);
    }
    return true;
  }
}

class Ball extends CircleComponent with CollisionCallbacks, HasGameRef<MyGame> {
  Vector2 velocity = Vector2(300, 300);

  Ball({
    required Vector2 position,
    required double radius,
  }) : super(
          position: position,
          radius: radius,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;

    // Bounce off top and bottom
    if (position.y <= radius || position.y >= gameRef.size.y - radius) {
      velocity.y = -velocity.y;
    }

    // Reset ball if it goes out on the sides
    if (position.x <= 0 || position.x >= gameRef.size.x) {
      resetBall();
    }
  }

  void resetBall() {
    position = gameRef.size / 2;
    velocity = Vector2(300, 300)..rotate(Random().nextDouble() * pi / 2 - pi / 4);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Paddle) {
      velocity.x = -velocity.x;
      // Add some variation based on where it hit the paddle
      double relativeIntersectY = (other.position.y - position.y);
      double normalizedRelativeIntersectionY = (relativeIntersectY / (other.size.y / 2));
      double bounceAngle = normalizedRelativeIntersectionY * pi / 4;
      velocity.y = velocity.length * sin(bounceAngle);
      velocity.x = velocity.x.abs() * (position.x > gameRef.size.x / 2 ? -1 : 1);
    }
  }
}
