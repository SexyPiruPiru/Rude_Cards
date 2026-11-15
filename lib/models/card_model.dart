class BlackCard {
  final String text;
  final String deckId;
  final bool isCustom;

  BlackCard({
    required this.text,
    required this.deckId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'deckId': deckId,
        'isCustom': isCustom,
      };

  factory BlackCard.fromJson(Map<String, dynamic> json) => BlackCard(
        text: json['text'] as String,
        deckId: json['deckId'] as String? ?? 'custom',
        isCustom: json['isCustom'] as bool? ?? true,
      );
}

class WhiteCard {
  final String text;
  final String deckId;
  final bool isCustom;

  WhiteCard({
    required this.text,
    required this.deckId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'deckId': deckId,
        'isCustom': isCustom,
      };

  factory WhiteCard.fromJson(Map<String, dynamic> json) => WhiteCard(
        text: json['text'] as String,
        deckId: json['deckId'] as String? ?? 'custom',
        isCustom: json['isCustom'] as bool? ?? true,
      );
}

class CardDeck {
  final String id;
  final String name;
  final String description;
  final List<BlackCard> blackCards;
  final List<WhiteCard> whiteCards;
  final bool isCustomDeck;

  CardDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.blackCards,
    required this.whiteCards,
    this.isCustomDeck = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'blackCards': blackCards.map((c) => c.toJson()).toList(),
        'whiteCards': whiteCards.map((c) => c.toJson()).toList(),
        'isCustomDeck': isCustomDeck,
      };

  factory CardDeck.fromJson(Map<String, dynamic> json) => CardDeck(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        blackCards: (json['blackCards'] as List<dynamic>? ?? [])
            .map((c) => BlackCard.fromJson(c))
            .toList(),
        whiteCards: (json['whiteCards'] as List<dynamic>? ?? [])
            .map((c) => WhiteCard.fromJson(c))
            .toList(),
        isCustomDeck: json['isCustomDeck'] as bool? ?? true,
      );
}

class PlayedSubmission {
  final String playerId;
  final String playerName;
  final WhiteCard card;

  PlayedSubmission({
    required this.playerId,
    required this.playerName,
    required this.card,
  });
}