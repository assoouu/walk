import 'dart:math';

bool isWalkable(Point<int> point, List<List<int>> grid) {
  int x = point.x;
  int y = point.y;
  return x >= 0 && x < grid.length && y >= 0 && y < grid[0].length && grid[x][y] == 0;
}

bool isGoal(Point<int> point, Point<int> goal) {
  return point == goal;
}

Point<int> move(Point<int> point, Point<int> direction) {
  return Point(point.x + direction.x, point.y + direction.y);
}
