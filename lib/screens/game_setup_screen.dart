import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  late final List<TextEditingController> _playerControllers;
  dynamic _targetScore = 5;
  bool _includeGhost = true;
  bool _initializedDefaults = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDefaults) {
      final provider = context.read<GameProvider>();
      _playerControllers = [
        TextEditingController(text: '${provider.t('player_default')} 1'),
        TextEditingController(text: '${provider.t('player_default')} 2'),
        TextEditingController(text: '${provider.t('player_default')} 3'),
      ];
      _initializedDefaults = true;
    }
  }

  @override
  void dispose() {
    for (final c in _playerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer(GameProvider provider) {
    if (_playerControllers.length < 10) {
      setState(() {
        _playerControllers.add(
          TextEditingController(text: '${provider.t('player_default')} ${_playerControllers.length + 1}'),
        );
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  void _handleStartGame(GameProvider provider) {
    final names = _playerControllers.map((c) => c.text).toList();
    final error = provider.startGame(names, _targetScore, _includeGhost);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('setup_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            provider.t('setup_decks'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...provider.allDecks.map((deck) {
            final isSelected = provider.selectedDeckIds.contains(deck.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                activeColor: Colors.white,
                checkColor: Colors.black,
                onChanged: (_) => provider.toggleDeckSelection(deck.id),
                title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${deck.description}\n(${deck.blackCards.length} nere • ${deck.whiteCards.length} bianche)',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
              ),
            );
          }),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.t('setup_target_score'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              DropdownButton<dynamic>(
                value: _targetScore,
                dropdownColor: Colors.black,
                items: [5, 10, 15, 20, provider.t('unlimited')]
                    .map((v) => DropdownMenuItem<dynamic>(
                          value: v,
                          child: Text(
                            v is int ? '$v ${provider.t('score_points')}' : '$v',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _targetScore = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.t('setup_players'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () => _addPlayer(provider),
                icon: const Icon(Icons.person_add),
                label: Text(provider.t('setup_add_player')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_playerControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _playerControllers[index],
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  labelText: '${provider.t('player_default')} ${index + 1}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _playerControllers.length > 2
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removePlayer(index),
                        )
                      : null,
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(provider.t('setup_ghost'), style: const TextStyle(fontWeight: FontWeight.bold)),
            value: _includeGhost,
            activeThumbColor: Colors.white,
            onChanged: (val) => setState(() => _includeGhost = val),
          ),

          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _handleStartGame(provider),
              child: Text(provider.t('setup_start'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}