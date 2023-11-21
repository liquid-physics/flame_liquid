import 'package:example/helper/routes.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

AppBar appBar(BuildContext context) => AppBar(
      title: Text(routes.entries.elementAt(index % routes.length).value.$2),
      actions: [
        IconButton(
            onPressed: () {
              prev();
              Navigator.of(context).pushReplacementNamed(
                  routes.entries.elementAt(index % routes.length).key);
            },
            icon: const Icon(Icons.arrow_back)),
        const SizedBox(
          width: 10,
        ),
        IconButton(
            onPressed: () {
              next();
              Navigator.of(context).pushReplacementNamed(
                  routes.entries.elementAt(index % routes.length).key);
            },
            icon: const Icon(Icons.arrow_forward)),
      ],
    );

class Called {
  static int count = 0;
}

extension FF on Vector2 {
  Vector2 flipY() {
    return this..multiply(Vector2(1, -1));
  }
}
