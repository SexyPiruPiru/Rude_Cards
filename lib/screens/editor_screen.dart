import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _whiteController = TextEditingController();
  final TextEditingController _blackController = TextEditingController();
  
  String? _selectedTargetDeckId;

  @override
  void dispose() {
    _whiteController.dispose();
    _blackController.dispose();
    super.dispose();
  }

  void _addLooseCard(GameProvider provider, bool isBlack) {
    final controller = isBlack ? _blackController : _whiteController;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_selectedTargetDeckId != null && _selectedTargetDeckId != 'legacy_custom') {
      provider.addCardToCustomDeck(_selectedTargetDeckId!, text, isBlack);
    } else {
      provider.addLooseCard(text, isBlack);
    }
    controller.clear();
  }

  void _showCreateDeckDialog(BuildContext context, GameProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(provider.t('create_new_deck')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: provider.t('deck_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: provider.t('description')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(provider.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                provider.addCustomDeck(nameController.text, descController.text);
                Navigator.pop(context);
              }
            },
            child: Text(provider.t('create')),
          ),
        ],
      ),
    );
  }

  void _moveCard(GameProvider provider, String cardText, String sourceDeckId, String? targetDeckId, bool isBlack) {
    if (sourceDeckId == (targetDeckId ?? 'legacy_custom')) return;

    if (sourceDeckId == 'legacy_custom') {
      final index = isBlack
          ? provider.customBlackCards.indexWhere((c) => c.text == cardText)
          : provider.customWhiteCards.indexWhere((c) => c.text == cardText);
      if (index != -1) {
        provider.removeLooseCard(index, isBlack);
      }
    } else {
      final deckIndex = provider.customDecks.indexWhere((d) => d.id == sourceDeckId);
      if (deckIndex != -1) {
        final deck = provider.customDecks[deckIndex];
        final index = isBlack
            ? deck.blackCards.indexWhere((c) => c.text == cardText)
            : deck.whiteCards.indexWhere((c) => c.text == cardText);
        if (index != -1) {
          provider.removeCardFromCustomDeck(sourceDeckId, index, isBlack);
        }
      }
    }

    if (targetDeckId == null || targetDeckId == 'legacy_custom') {
      provider.addLooseCard(cardText, isBlack);
    } else {
      provider.addCardToCustomDeck(targetDeckId, cardText, isBlack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (_selectedTargetDeckId != null && !provider.customDecks.any((d) => d.id == _selectedTargetDeckId)) {
      _selectedTargetDeckId = null;
    }
    
    List<Widget> allWhiteTiles = [];
    List<Widget> allBlackTiles = [];

    final deckDropdownItems = [
      DropdownMenuItem<String?>(value: null, child: Text(provider.t('loose_label'), style: const TextStyle(fontSize: 12))),
      ...provider.customDecks.map((d) => DropdownMenuItem<String?>(
            value: d.id,
            child: Text(d.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          )),
    ];

    for (int i = 0; i < provider.customWhiteCards.length; i++) {
      final card = provider.customWhiteCards[i];
      allWhiteTiles.add(_buildCardTile(
        context: context,
        cardText: card.text,
        sourceDeckId: 'legacy_custom',
        isBlack: false,
        deckDropdownItems: deckDropdownItems,
        onDelete: () => provider.removeLooseCard(i, false),
        onMove: (newDeckId) => _moveCard(provider, card.text, 'legacy_custom', newDeckId, false),
      ));
    }

    for (var deck in provider.customDecks) {
      for (int i = 0; i < deck.whiteCards.length; i++) {
        final card = deck.whiteCards[i];
        final currentDeckId = deck.id;
        allWhiteTiles.add(_buildCardTile(
          context: context,
          cardText: card.text,
          sourceDeckId: currentDeckId,
          isBlack: false,
          deckDropdownItems: deckDropdownItems,
          onDelete: () => provider.removeCardFromCustomDeck(currentDeckId, i, false),
          onMove: (newDeckId) => _moveCard(provider, card.text, currentDeckId, newDeckId, false),
        ));
      }
    }

    for (int i = 0; i < provider.customBlackCards.length; i++) {
      final card = provider.customBlackCards[i];
      allBlackTiles.add(_buildCardTile(
        context: context,
        cardText: card.text,
        sourceDeckId: 'legacy_custom',
        isBlack: true,
        deckDropdownItems: deckDropdownItems,
        onDelete: () => provider.removeLooseCard(i, true),
        onMove: (newDeckId) => _moveCard(provider, card.text, 'legacy_custom', newDeckId, true),
      ));
    }

    for (var deck in provider.customDecks) {
      for (int i = 0; i < deck.blackCards.length; i++) {
        final card = deck.blackCards[i];
        final currentDeckId = deck.id;
        allBlackTiles.add(_buildCardTile(
          context: context,
          cardText: card.text,
          sourceDeckId: currentDeckId,
          isBlack: true,
          deckDropdownItems: deckDropdownItems,
          onDelete: () => provider.removeCardFromCustomDeck(currentDeckId, i, true),
          onMove: (newDeckId) => _moveCard(provider, card.text, currentDeckId, newDeckId, true),
        ));
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(provider.t('management_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: provider.t('white_cards')),
              Tab(text: provider.t('black_cards')),
              Tab(text: provider.t('decks')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: CARTE BIANCHE
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTargetDeckId,
                        decoration: InputDecoration(labelText: provider.t('add_to_default_deck')),
                        items: [
                          DropdownMenuItem(value: null, child: Text(provider.t('loose_cards'))),
                          ...provider.customDecks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedTargetDeckId = val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _whiteController,
                              decoration: InputDecoration(
                                hintText: provider.t('hint_white_card'),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addLooseCard(provider, false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: ListView(children: allWhiteTiles)),
              ],
            ),

            // TAB 2: CARTE NERE
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTargetDeckId,
                        decoration: InputDecoration(labelText: provider.t('add_to_default_deck')),
                        items: [
                          DropdownMenuItem(value: null, child: Text(provider.t('loose_cards'))),
                          ...provider.customDecks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedTargetDeckId = val),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _blackController,
                              decoration: InputDecoration(
                                hintText: provider.t('hint_black_card'),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addLooseCard(provider, true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: ListView(children: allBlackTiles)),
              ],
            ),

            // TAB 3: MAZZI
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                          onPressed: () => _showCreateDeckDialog(context, provider),
                          icon: const Icon(Icons.library_add),
                          label: Text(provider.t('new_deck_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                          onPressed: () async {
                            final success = await provider.importDeckFromFile();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? provider.t('deck_imported_success') : provider.t('deck_import_error')),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: Text(provider.t('import_file_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.customDecks.length,
                      itemBuilder: (context, index) {
                        final deck = provider.customDecks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${deck.description}\n${provider.t('black_abbr')}: ${deck.blackCards.length} • ${provider.t('white_abbr')}: ${deck.whiteCards.length}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.amber),
                                  tooltip: provider.t('share_export_tooltip'),
                                  onPressed: () => provider.exportDeckAsFile(deck.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  tooltip: provider.t('delete_deck_tooltip'),
                                  onPressed: () => provider.deleteCustomDeck(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile({
    required BuildContext context,
    required String cardText,
    required String sourceDeckId,
    required bool isBlack,
    required List<DropdownMenuItem<String?>> deckDropdownItems,
    required VoidCallback onDelete,
    required ValueChanged<String?> onMove,
  }) {
    final provider = context.watch<GameProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: sourceDeckId == 'legacy_custom' ? null : sourceDeckId,
                  isExpanded: true,
                  items: deckDropdownItems,
                  onChanged: onMove,
                  style: const TextStyle(fontSize: 12, color: Colors.amber),
                  dropdownColor: Colors.grey.shade900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cardText,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: provider.t('delete_card_tooltip'),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}