import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../utils/app_strings.dart';

enum TurnPhase {
  passToCzarFirst,
  czarReadingBlack,
  passToPlayer,
  playerChoosing,
  passToCzarAfter,
  czarJudging,
  roundResult,
  gameOver,
}

class GameProvider extends ChangeNotifier {
  static const int cardsPerHand = 8;
  static const String _customDecksKey = 'custom_user_decks';
  static const String _customBlackKey = 'custom_black_cards';
  static const String _customWhiteKey = 'custom_white_cards';
  static const String _languageKey = 'app_language_code';

  final Random _random = Random();

  String _languageCode = 'it';
  String get languageCode => _languageCode;
  String t(String key) => AppStrings.get(_languageCode, key);

  List<CardDeck> _baseDecks = [];
  List<CardDeck> _customDecks = [];
  List<BlackCard> _customBlackCards = [];
  List<WhiteCard> _customWhiteCards = [];
  final Set<String> _selectedDeckIds = {'base'};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Player> _players = [];
  
  // Gestisce il target score: un numero intero positivo, oppure un valore alto/speciale per "Illimitato" (es. 999999)
  int _targetScore = 5;
  bool _isUnlimitedScore = false;
  
  int _czarIndex = 0;
  int _currentChooserIndex = 0;
  TurnPhase _phase = TurnPhase.passToCzarFirst;

  List<BlackCard> _drawBlackPile = [];
  List<WhiteCard> _drawWhitePile = [];
  BlackCard? _currentBlackCard;
  final List<PlayedSubmission> _submissions = [];
  PlayedSubmission? _roundWinner;

  final Map<String, String> _votes = {};
  Map<String, String> get votes => _votes;

  List<CardDeck> get allDecks {
    final list = [..._baseDecks, ..._customDecks];
    if (_customBlackCards.isNotEmpty || _customWhiteCards.isNotEmpty) {
      list.add(
        CardDeck(
          id: 'legacy_custom',
          name: 'Carte Sciolte (Custom)',
          description: 'Carte create senza un mazzo specifico.',
          blackCards: _customBlackCards,
          whiteCards: _customWhiteCards,
          isCustomDeck: true,
        ),
      );
    }
    return list;
  }

  Set<String> get selectedDeckIds => _selectedDeckIds;
  List<CardDeck> get customDecks => _customDecks;
  List<BlackCard> get customBlackCards => _customBlackCards;
  List<WhiteCard> get customWhiteCards => _customWhiteCards;

  List<Player> get players => _players;
  int get targetScore => _targetScore;
  bool get isUnlimitedScore => _isUnlimitedScore;
  Player get currentCzar => _players[_czarIndex];
  Player get currentChooser => _players[_currentChooserIndex];
  TurnPhase get phase => _phase;
  BlackCard? get currentBlackCard => _currentBlackCard;
  List<PlayedSubmission> get submissions => _submissions;
  PlayedSubmission? get roundWinner => _roundWinner;

  Player? get gameWinner {
    if (_isUnlimitedScore) return null; // Se è illimitato, la partita non finisce per punteggio automatico
    try {
      return _players.firstWhere((p) => p.score >= _targetScore);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    notifyListeners();
  }

  Future<void> initDecks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await rootBundle.loadString('assets/cards_it.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final decksList = data['decks'] as List<dynamic>;

      _baseDecks = decksList.map((d) {
        final id = d['id'] as String;
        final blacks = (d['black_cards'] as List<dynamic>)
            .map((t) => BlackCard(text: t.toString(), deckId: id))
            .toList();
        final whites = (d['white_cards'] as List<dynamic>)
            .map((t) => WhiteCard(text: t.toString(), deckId: id))
            .toList();

        return CardDeck(
          id: id,
          name: d['name'] as String,
          description: d['description'] as String? ?? '',
          blackCards: blacks,
          whiteCards: whites,
        );
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      _languageCode = prefs.getString(_languageKey) ?? 'it';
      
      final savedDecks = prefs.getStringList(_customDecksKey) ?? [];
      _customDecks = savedDecks.map((e) => CardDeck.fromJson(json.decode(e))).toList();

      final savedBlack = prefs.getStringList(_customBlackKey) ?? [];
      final savedWhite = prefs.getStringList(_customWhiteKey) ?? [];
      _customBlackCards = savedBlack.map((e) => BlackCard.fromJson(json.decode(e))).toList();
      _customWhiteCards = savedWhite.map((e) => WhiteCard.fromJson(json.decode(e))).toList();

      for (var d in _baseDecks) {
        _selectedDeckIds.add(d.id);
      }
      for (var d in _customDecks) {
        _selectedDeckIds.add(d.id);
      }
    } catch (e) {
      debugPrint('Errore caricamento mazzi: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleDeckSelection(String deckId) {
    if (_selectedDeckIds.contains(deckId)) {
      if (_selectedDeckIds.length > 1) {
        _selectedDeckIds.remove(deckId);
      }
    } else {
      _selectedDeckIds.add(deckId);
    }
    notifyListeners();
  }

  Future<void> addCustomDeck(String name, String description) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final newDeck = CardDeck(
      id: 'custom_deck_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      description: description.trim(),
      blackCards: [],
      whiteCards: [],
      isCustomDeck: true,
    );
    _customDecks.add(newDeck);
    _selectedDeckIds.add(newDeck.id);
    await _saveCustomDecks();
    notifyListeners();
  }

  Future<void> deleteCustomDeck(int index) async {
    final deck = _customDecks[index];
    _selectedDeckIds.remove(deck.id);
    _customDecks.removeAt(index);
    await _saveCustomDecks();
    notifyListeners();
  }

  // --- ESPORTAZIONE FILE JSON ---
  Future<void> exportDeckAsFile(String deckId) async {
    final deck = _customDecks.firstWhere((d) => d.id == deckId, orElse: () => throw Exception('Mazzo non trovato'));
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(deck.toJson());
    final shareText = t('share_deck_msg').replaceAll('{name}', deck.name);

    if (kIsWeb) {
      final fileData = utf8.encode(jsonString);
      final xFile = XFile.fromData(fileData, name: '${deck.name.replaceAll(' ', '_')}.json', mimeType: 'application/json');
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: shareText);
    } else {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${deck.name.replaceAll(' ', '_')}.json');
      await file.writeAsString(jsonString);

      final xFile = XFile(file.path);
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: shareText);
    }
  }

  // --- IMPORTAZIONE FILE JSON ---
  Future<bool> importDeckFromFile() async {
    try {
      List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return false;
        jsonString = utf8.decode(bytes);
      } else {
        final path = result.files.single.path;
        if (path == null) return false;
        final file = File(path);
        jsonString = await file.readAsString();
      }

      final Map<String, dynamic> data = json.decode(jsonString);
      final importedDeck = CardDeck.fromJson(data);

      final newDeck = CardDeck(
        id: 'custom_deck_${DateTime.now().millisecondsSinceEpoch}',
        name: '${importedDeck.name} (Importato)',
        description: importedDeck.description,
        blackCards: importedDeck.blackCards,
        whiteCards: importedDeck.whiteCards,
        isCustomDeck: true,
      );

      _customDecks.add(newDeck);
      _selectedDeckIds.add(newDeck.id);
      await _saveCustomDecks();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Errore importazione file mazzo: $e');
      return false;
    }
  }

  Future<void> addCardToCustomDeck(String deckId, String text, bool isBlack) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    final deckIndex = _customDecks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _customDecks[deckIndex];
    List<BlackCard> updatedBlacks = List.from(deck.blackCards);
    List<WhiteCard> updatedWhites = List.from(deck.whiteCards);

    if (isBlack) {
      updatedBlacks.add(BlackCard(text: cleanText, deckId: deck.id, isCustom: true));
    } else {
      updatedWhites.add(WhiteCard(text: cleanText, deckId: deck.id, isCustom: true));
    }

    _customDecks[deckIndex] = CardDeck(
      id: deck.id,
      name: deck.name,
      description: deck.description,
      blackCards: updatedBlacks,
      whiteCards: updatedWhites,
      isCustomDeck: true,
    );

    await _saveCustomDecks();
    notifyListeners();
  }

  Future<void> removeCardFromCustomDeck(String deckId, int cardIndex, bool isBlack) async {
    final deckIndex = _customDecks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _customDecks[deckIndex];
    List<BlackCard> updatedBlacks = List.from(deck.blackCards);
    List<WhiteCard> updatedWhites = List.from(deck.whiteCards);

    if (isBlack) {
      updatedBlacks.removeAt(cardIndex);
    } else {
      updatedWhites.removeAt(cardIndex);
    }

    _customDecks[deckIndex] = CardDeck(
      id: deck.id,
      name: deck.name,
      description: deck.description,
      blackCards: updatedBlacks,
      whiteCards: updatedWhites,
      isCustomDeck: true,
    );

    await _saveCustomDecks();
    notifyListeners();
  }

  Future<void> addLooseCard(String text, bool isBlack) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (isBlack) {
      _customBlackCards.add(BlackCard(text: clean, deckId: 'legacy_custom', isCustom: true));
    } else {
      _customWhiteCards.add(WhiteCard(text: clean, deckId: 'legacy_custom', isCustom: true));
    }
    _selectedDeckIds.add('legacy_custom');
    await _saveLooseCards();
    notifyListeners();
  }

  Future<void> removeLooseCard(int index, bool isBlack) async {
    if (isBlack) {
      _customBlackCards.removeAt(index);
    } else {
      _customWhiteCards.removeAt(index);
    }
    await _saveLooseCards();
    notifyListeners();
  }

  Future<void> _saveCustomDecks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customDecksKey,
      _customDecks.map((d) => json.encode(d.toJson())).toList(),
    );
  }

  Future<void> _saveLooseCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customBlackKey,
      _customBlackCards.map((c) => json.encode(c.toJson())).toList(),
    );
    await prefs.setStringList(
      _customWhiteKey,
      _customWhiteCards.map((c) => json.encode(c.toJson())).toList(),
    );
  }

  // Modificato per accettare dinamicamente il target score (es. 5, 10, 15, 20 o una stringa/segnale per 'Illimitato')
  String? startGame(List<String> playerNames, dynamic targetScoreParam, bool includeGhost) {
    final validNames = playerNames.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    if (validNames.length + (includeGhost ? 1 : 0) < 3) {
      return 'Servono almeno 3 giocatori in totale (inclusi eventuali bot)!';
    }

    final activeDecks = allDecks.where((d) => _selectedDeckIds.contains(d.id)).toList();
    final combinedBlacks = activeDecks.expand((d) => d.blackCards).toList();
    final combinedWhites = activeDecks.expand((d) => d.whiteCards).toList();

    if (combinedBlacks.isEmpty) {
      return 'I mazzi selezionati non contengono carte nere!';
    }
    final totalPlayersCount = validNames.length + (includeGhost ? 1 : 0);
    if (combinedWhites.length < totalPlayersCount * cardsPerHand) {
      return 'Carte bianche insufficienti. Seleziona più mazzi!';
    }

    // Gestione del punteggio target (Supporta sia interi che la stringa 'Illimitato')
    if (targetScoreParam is String && targetScoreParam.toLowerCase() == 'illimitato') {
      _isUnlimitedScore = true;
      _targetScore = 999999;
    } else if (targetScoreParam is int) {
      _isUnlimitedScore = false;
      _targetScore = targetScoreParam;
    } else {
      _isUnlimitedScore = false;
      _targetScore = int.tryParse(targetScoreParam.toString()) ?? 5;
    }

    _drawBlackPile = List.from(combinedBlacks)..shuffle(_random);
    _drawWhitePile = List.from(combinedWhites)..shuffle(_random);

    _players = List.generate(validNames.length, (i) {
      return Player(
        id: 'p_$i',
        name: validNames[i],
        hand: _drawWhiteCards(cardsPerHand),
      );
    });

    if (includeGhost) {
      _players.add(
        Player(
          id: 'ghost_cpu',
          name: '👻 Fantasma',
          hand: _drawWhiteCards(cardsPerHand),
          isCpu: true,
        ),
      );
    }

    _czarIndex = 0;
    _startNewRound();
    return null;
  }

  List<WhiteCard> _drawWhiteCards(int count) {
    final drawn = <WhiteCard>[];
    for (int i = 0; i < count; i++) {
      if (_drawWhitePile.isEmpty) {
        final activeDecks = allDecks.where((d) => _selectedDeckIds.contains(d.id));
        _drawWhitePile = activeDecks.expand((d) => d.whiteCards).toList()..shuffle(_random);
      }
      drawn.add(_drawWhitePile.removeLast());
    }
    return drawn;
  }

  void _startNewRound() {
    _submissions.clear();
    _roundWinner = null;
    _votes.clear();

    if (_drawBlackPile.isEmpty) {
      final activeDecks = allDecks.where((d) => _selectedDeckIds.contains(d.id));
      _drawBlackPile = activeDecks.expand((d) => d.blackCards).toList()..shuffle(_random);
    }
    _currentBlackCard = _drawBlackPile.removeLast();

    _phase = TurnPhase.passToCzarFirst;
    notifyListeners();
  }

  void confirmCzarReadBlack() {
    if (_phase == TurnPhase.passToCzarFirst) {
      _phase = TurnPhase.czarReadingBlack;
      notifyListeners();
    }
  }

  void startChoosersPhase() {
    _currentChooserIndex = (_czarIndex + 1) % _players.length;
    _proceedToNextChooser();
  }

  void _proceedToNextChooser() {
    if (_currentChooserIndex == _czarIndex) {
      _currentChooserIndex = (_currentChooserIndex + 1) % _players.length;
    }

    if (_submissions.length >= _players.length - 1) {
      _submissions.shuffle(_random);
      _phase = TurnPhase.passToCzarAfter;
      notifyListeners();
      return;
    }

    final player = currentChooser;
    if (player.isCpu) {
      final randomCard = player.hand[_random.nextInt(player.hand.length)];
      player.hand.remove(randomCard);
      player.hand.addAll(_drawWhiteCards(1));

      _submissions.add(
        PlayedSubmission(
          playerId: player.id,
          playerName: player.name,
          card: randomCard,
        ),
      );

      _currentChooserIndex = (_currentChooserIndex + 1) % _players.length;
      _proceedToNextChooser();
    } else {
      _phase = TurnPhase.passToPlayer;
      notifyListeners();
    }
  }

  void confirmPlayerReady() {
    if (_phase == TurnPhase.passToPlayer) {
      _phase = TurnPhase.playerChoosing;
      notifyListeners();
    }
  }

  void submitWhiteCard(WhiteCard card) {
    final player = currentChooser;
    player.hand.remove(card);
    player.hand.addAll(_drawWhiteCards(1));

    _submissions.add(
      PlayedSubmission(
        playerId: player.id,
        playerName: player.name,
        card: card,
      ),
    );

    _currentChooserIndex = (_currentChooserIndex + 1) % _players.length;
    _proceedToNextChooser();
  }

  void confirmCzarReadyAfter() {
    if (_phase == TurnPhase.passToCzarAfter) {
      _phase = TurnPhase.czarJudging;
      notifyListeners();
    }
  }

  void selectRoundWinner(PlayedSubmission winningSubmission) {
    _finalizeRoundWinner(winningSubmission);
  }

  void castVote(Player votingPlayer, PlayedSubmission submission) {
    _votes[votingPlayer.id] = submission.card.text;
    notifyListeners();
  }

  void tallyGhostVotes() {
    if (_submissions.isEmpty) return;

    final Map<String, int> voteCounts = {};
    for (var sub in _submissions) {
      voteCounts[sub.card.text] = 0;
    }

    _votes.forEach((playerId, cardText) {
      if (voteCounts.containsKey(cardText)) {
        voteCounts[cardText] = voteCounts[cardText]! + 1;
      }
    });

    int maxVotes = -1;
    voteCounts.forEach((cardText, count) {
      if (count > maxVotes) {
        maxVotes = count;
      }
    });

    final tiedSubmissions = _submissions.where((sub) {
      return (voteCounts[sub.card.text] ?? 0) == maxVotes;
    }).toList();

    final winningSub = tiedSubmissions[_random.nextInt(tiedSubmissions.length)];

    _finalizeRoundWinner(winningSub);
  }

  void _finalizeRoundWinner(PlayedSubmission winningSubmission) {
    _roundWinner = winningSubmission;
    final winnerPlayer = _players.firstWhere((p) => p.id == winningSubmission.playerId);
    winnerPlayer.score += 1;

    _czarIndex = _players.indexWhere((p) => p.id == winnerPlayer.id);

    if (!_isUnlimitedScore && winnerPlayer.score >= _targetScore) {
      _phase = TurnPhase.gameOver;
    } else {
      _phase = TurnPhase.roundResult;
    }
    notifyListeners();
  }

  void nextRound() {
    _startNewRound();
  }
}

extension on List<PlatformFile> {
  get files => null;
}

class FilePickerResult {
}