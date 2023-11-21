import 'package:flame_liquid/flame_liquid.dart';

const int grabbableMaskBit = 1 << 31;
const int allCategories = ~0;
final ShapeFilter notGrabbableFilter = ShapeFilter(
    group: 0, categories: ~grabbableMaskBit, mask: ~grabbableMaskBit);
final ShapeFilter grabFilter =
    ShapeFilter(group: 0, categories: grabbableMaskBit, mask: grabbableMaskBit);
final ShapeFilter shapeFilterAll =
    ShapeFilter(group: 0, categories: allCategories, mask: allCategories);
final ShapeFilter shapeFilterNone =
    ShapeFilter(group: 0, categories: ~allCategories, mask: ~allCategories);
