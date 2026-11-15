import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int? _selectedCardIndex;
  int? _launchingCardIndex;

  Future<bool?> _showExitConfirmation(BuildContext context, GameProvider provider) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.white, width: 2),
        ),
        title: Text(
          provider.t('dialog_exit_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Text(
          provider.t('dialog_exit_body'),
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(provider.t('dialog_cancel'), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(provider.t('dialog_exit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (provider.phase == TurnPhase.gameOver) {
      return const GameOverScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool? exitConfirmed = await _showExitConfirmation(context, provider);
        if (exitConfirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              final bool? exitConfirmed = await _showExitConfirmation(context, provider);
              if (exitConfirmed == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            'TARGET: ${provider.targetScore}',
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 15, color: Colors.white),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(38),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.white24, width: 1),
                  bottom: BorderSide(color: Colors.white24, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: provider.players.map((p) {
                    final isJudge = p.id == provider.currentCzar.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${isJudge ? "👑 " : ""}${p.name}: ${p.score}',
                        style: TextStyle(
                          color: isJudge ? Colors.white : Colors.grey.shade500,
                          fontWeight: isJudge ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        body: _buildPhaseBody(context, provider),
      ),
    );
  }

  /// Widget della Carta Nera verticale stile Minimal Raw & Brutal
  Widget _buildBlackCardWidget(String text, {double width = 260, double height = 340}) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const Row(
            children: [
              Icon(Icons.style, size: 16, color: Colors.white54),
              SizedBox(width: 6),
              Text(
                'RUDE CARDS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper per costruire il ventaglio interattivo con Stack
  Widget _buildCardFanStack({
    required int itemCount,
    required String Function(int index) getCardText,
    required Function(int index) onTapCard,
    required Function(int index) onSwipeUpCard,
  }) {
    const double cardWidth = 150.0;
    const double spacing = 108.0;
    final double totalWidth = cardWidth + (itemCount - 1) * spacing + 48.0;

    return ClipRect(
      clipBehavior: Clip.none,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SizedBox(
          width: totalWidth,
          height: 250,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < itemCount; i++)
                if (i != _selectedCardIndex)
                  _buildSingleFanCard(
                    index: i,
                    text: getCardText(i),
                    isSelected: false,
                    isLaunching: _launchingCardIndex == i,
                    onTap: () => onTapCard(i),
                    onVerticalDragUpdate: (details) {},
                  ),
              if (_selectedCardIndex != null && _selectedCardIndex! < itemCount)
                _buildSingleFanCard(
                  index: _selectedCardIndex!,
                  text: getCardText(_selectedCardIndex!),
                  isSelected: true,
                  isLaunching: _launchingCardIndex == _selectedCardIndex!,
                  onTap: () => onTapCard(_selectedCardIndex!),
                  onVerticalDragUpdate: (details) {
                    if (_launchingCardIndex == null && details.delta.dy < -5) {
                      setState(() {
                        _launchingCardIndex = _selectedCardIndex;
                      });
                      onSwipeUpCard(_selectedCardIndex!);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleFanCard({
    required int index,
    required String text,
    required bool isSelected,
    required bool isLaunching,
    required VoidCallback onTap,
    required GestureDragUpdateCallback onVerticalDragUpdate,
  }) {
    final double leftPosition = index * 108.0;
    final double angle = (index % 2 == 0 ? -0.04 : 0.04);

    return Positioned(
      left: leftPosition,
      bottom: 10,
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragUpdate: onVerticalDragUpdate,
        child: AnimatedContainer(
          duration: Duration(milliseconds: isLaunching ? 250 : 200),
          curve: isLaunching ? Curves.easeIn : Curves.easeOutBack,
          transform: Matrix4.identity()
            // ignore: deprecated_member_use
            ..translate(
              0.0,
              isLaunching ? -500.0 : (isSelected ? -55.0 : 0.0),
            )
            ..rotateZ(isSelected && !isLaunching ? 0.0 : angle)
            // ignore: deprecated_member_use
            ..scale(isSelected && !isLaunching ? 1.12 : 1.0),
          transformAlignment: Alignment.bottomCenter,
          width: 150,
          height: 210,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.black,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? Colors.amber.withValues(alpha: 0.3) : Colors.black87,
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(-3, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const Text(
                'RUDE CARDS',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseBody(BuildContext context, GameProvider provider) {
    switch (provider.phase) {
      case TurnPhase.passToCzarFirst:
        return _buildPassScreen(
          label: provider.t('phase_judge_turn'),
          playerName: provider.currentCzar.name,
          subtitle: provider.t('phase_judge_pass_subtitle'),
          buttonText: provider.t('btn_ready'),
          onPressed: () {
            setState(() {
              _selectedCardIndex = null;
              _launchingCardIndex = null;
            });
            provider.confirmCzarReadBlack();
          },
        );

      case TurnPhase.czarReadingBlack:
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  provider.t('black_card_label'),
                  style: const TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
                _buildBlackCardWidget(provider.currentBlackCard?.text ?? ''),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => provider.startChoosersPhase(),
                    child: Text(
                      provider.t('btn_start_choosing'),
                      style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case TurnPhase.passToPlayer:
        return _buildPassScreen(
          label: provider.t('phase_choice_turn'),
          playerName: provider.currentChooser.name,
          subtitle: provider.t('phase_choice_pass_subtitle'),
          buttonText: provider.t('btn_ready'),
          onPressed: () {
            setState(() {
              _selectedCardIndex = null;
              _launchingCardIndex = null;
            });
            provider.confirmPlayerReady();
          },
        );

      case TurnPhase.playerChoosing:
        final player = provider.currentChooser;
        final hand = player.hand;

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                '${provider.t('turn_of')} ${player.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                flex: 5,
                child: Center(
                  child: _buildBlackCardWidget(
                    provider.currentBlackCard?.text ?? '',
                    width: 235,
                    height: 280,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _selectedCardIndex != null
                      ? provider.t('swipe_up_hint')
                      : provider.t('tap_card_hint'),
                  style: TextStyle(
                    color: _selectedCardIndex != null ? Colors.amber : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              Expanded(
                flex: 4,
                child: _buildCardFanStack(
                  itemCount: hand.length,
                  getCardText: (i) => hand[i].text,
                  onTapCard: (i) {
                    setState(() {
                      _selectedCardIndex = _selectedCardIndex == i ? null : i;
                    });
                  },
                  onSwipeUpCard: (i) {
                    final chosen = hand[i];
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) {
                        setState(() {
                          _selectedCardIndex = null;
                          _launchingCardIndex = null;
                        });
                        provider.submitWhiteCard(chosen);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );

      case TurnPhase.passToCzarAfter:
        return _buildPassScreen(
          label: provider.t('all_cards_played'),
          playerName: '${provider.t('judge_label')}: ${provider.currentCzar.name}',
          subtitle: provider.t('judge_pass_subtitle'),
          buttonText: provider.t('btn_read_answers'),
          onPressed: () {
            setState(() {
              _selectedCardIndex = null;
              _launchingCardIndex = null;
            });
            provider.confirmCzarReadyAfter();
          },
        );

      case TurnPhase.czarJudging:
        final subs = provider.submissions;
        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                provider.t('judge_choose_best'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                flex: 5,
                child: Center(
                  child: _buildBlackCardWidget(
                    provider.currentBlackCard?.text ?? '',
                    width: 235,
                    height: 280,
                  ),
                ),
              ),

              Expanded(
                flex: 4,
                child: _buildCardFanStack(
                  itemCount: subs.length,
                  getCardText: (i) => subs[i].card.text,
                  onTapCard: (i) {
                    setState(() {
                      _selectedCardIndex = _selectedCardIndex == i ? null : i;
                    });
                  },
                  onSwipeUpCard: (i) {
                    final chosenSub = subs[i];
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) {
                        setState(() {
                          _selectedCardIndex = null;
                          _launchingCardIndex = null;
                        });
                        provider.selectRoundWinner(chosenSub);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );

      case TurnPhase.roundResult:
        final winner = provider.roundWinner;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(provider.t('round_winner_label'), style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  (winner?.playerName ?? '').toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 240,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    winner?.card.text ?? '',
                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () => provider.nextRound(),
                    child: Text(provider.t('btn_next_round'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
  }

  Widget _buildPassScreen({
    required String label,
    required String playerName,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text(
              playerName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: onPressed,
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final winner = provider.gameWinner;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              Text(provider.t('game_over_label'), style: const TextStyle(color: Colors.grey, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                (winner?.name ?? '').toUpperCase(),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(provider.t('game_over_subtitle'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(provider.t('btn_back_home'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}