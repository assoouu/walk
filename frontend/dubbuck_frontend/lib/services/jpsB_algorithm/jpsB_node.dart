class JpsBNode {
  final int x;
  final int y;
  final int cost;
  final int heuristic;
  final int priority;
  JpsBNode? parent;

  JpsBNode(this.x, this.y, {this.cost = 0, this.heuristic = 0, this.priority = 0, this.parent});

  int get totalCost => cost + heuristic;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is JpsBNode && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
