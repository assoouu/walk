import 'package:collection/collection.dart';
import 'jpsB_node.dart';

PriorityQueue<JpsBNode> createPriorityQueue() {
  return PriorityQueue((a, b) => a.totalCost.compareTo(b.totalCost));
}
