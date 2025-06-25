import 'package:baarikierros/models/bar.dart';

class Round {
  final String name;
  final List<Bar> bars;
  final String? description;
  final String? imageUrl;

  Round({
    required this.name,
    required this.bars,
    this.description,
    this.imageUrl,
  });
}
