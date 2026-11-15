import 'card_model.dart';

class Player {
  final String id;
  final String name;
  int score;
  List<WhiteCard> hand;
  final bool isCpu;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    List<WhiteCard>? hand,
    this.isCpu = false,
  }) : hand = hand ?? [];
}