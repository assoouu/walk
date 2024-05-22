import 'dart:math';
import 'package:collection/collection.dart';
import 'jpsB_collision.dart';
import 'jpsB_node.dart';
import 'jpsB_heap.dart';

int heuristic(Point<int> point, Point<int> goal) {
  return (point.x - goal.x).abs() + (point.y - goal.y).abs();
}

Point<int>? jump(Point<int> point, Point<int> direction, List<List<int>> grid, Point<int> goal) {
  int x = point.x + direction.x;
  int y = point.y + direction.y;

  if (x < 0 || x >= grid.length || y < 0 || y >= grid[0].length || !isWalkable(Point(x, y), grid)) {
    return null;
  }

  if (isGoal(Point(x, y), goal)) {
    return Point(x, y);
  }

  if ((direction.x != 0 && direction.y != 0) &&
      (isWalkable(Point(x - direction.x, y), grid) && !isWalkable(Point(x - direction.x, y + direction.y), grid) ||
          isWalkable(Point(x, y - direction.y), grid) && !isWalkable(Point(x + direction.x, y - direction.y), grid))) {
    return Point(x, y);
  } else if (direction.x != 0) {
    if ((isWalkable(Point(x, y + 1), grid) && !isWalkable(Point(x - direction.x, y + 1), grid)) ||
        (isWalkable(Point(x, y - 1), grid) && !isWalkable(Point(x - direction.x, y - 1), grid))) {
      return Point(x, y);
    }
  } else if (direction.y != 0) {
    if ((isWalkable(Point(x + 1, y), grid) && !isWalkable(Point(x + 1, y - direction.y), grid)) ||
        (isWalkable(Point(x - 1, y), grid) && !isWalkable(Point(x - 1, y - direction.y), grid))) {
      return Point(x, y);
    }
  }

  return jump(Point(x, y), direction, grid, goal);
}

List<Point<int>> findNeighbors(Point<int> point, List<List<int>> grid, Point<int> goal) {
  List<Point<int>> neighbors = [];
  List<Point<int>> directions = [Point(1, 0), Point(0, 1), Point(-1, 0), Point(0, -1)];
  for (var dir in directions) {
    var newPoint = move(point, dir);
    if (isWalkable(newPoint, grid)) {
      var jumpPoint = jump(newPoint, dir, grid, goal);
      if (jumpPoint != null) {
        neighbors.add(jumpPoint);
      }
    }
  }
  return neighbors;
}

List<Point<int>> jpsB(Point<int> start, Point<int> goal, List<List<int>> grid) {
  PriorityQueue<JpsBNode> openList = createPriorityQueue();
  openList.add(JpsBNode(start.x, start.y, cost: 0, heuristic: heuristic(start, goal), priority: 0));
  Map<Point<int>, JpsBNode?> cameFrom = {};
  Map<Point<int>, int> costSoFar = {start: 0};

  while (openList.isNotEmpty) {
    var current = openList.removeFirst();
    var currentPoint = Point(current.x, current.y);

    if (currentPoint == goal) {
      return reconstructPath(cameFrom, start, goal);
    }

    for (var neighbor in findNeighbors(currentPoint, grid, goal)) {
      int newCost = costSoFar[currentPoint]! + heuristic(currentPoint, neighbor);
      if (!costSoFar.containsKey(neighbor) || newCost < costSoFar[neighbor]!) {
        costSoFar[neighbor] = newCost;
        int priority = newCost + heuristic(neighbor, goal);
        openList.add(JpsBNode(neighbor.x, neighbor.y, cost: newCost, heuristic: heuristic(neighbor, goal), priority: priority));
        cameFrom[neighbor] = current;
      }
    }
  }
  return [];
}

List<Point<int>> reconstructPath(Map<Point<int>, JpsBNode?> cameFrom, Point<int> start, Point<int> goal) {
  var current = goal;
  List<Point<int>> path = [];
  while (current != start) {
    path.add(current);
    current = Point(cameFrom[current]!.x, cameFrom[current]!.y);
  }
  path.add(start);
  return path.reversed.toList();
}
