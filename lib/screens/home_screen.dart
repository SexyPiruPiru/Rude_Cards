import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'credits_screen.dart';
import 'editor_screen.dart';
import 'game_setup_screen.dart';
import 'settings_screen.dart';
import 'rules_screen.dart'; // (o il percorso corretto, es. import '../screens/rules_screen.dart';)

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: PopupMenuButton<String>(
              initialValue: provider.languageCode,
              onSelected: (String code) => provider.setLanguage(code),
              color: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: Colors.white, width: 1),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      provider.languageCode.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) => const [
                PopupMenuItem(value: 'it', child: Text('🇮🇹  ITALIANO', style: TextStyle(fontWeight: FontWeight.bold))),
                PopupMenuItem(value: 'en', child: Text('🇬🇧  ENGLISH', style: TextStyle(fontWeight: FontWeight.bold))),
                PopupMenuItem(value: 'es', child: Text('🇪🇸  ESPAÑOL', style: TextStyle(fontWeight: FontWeight.bold))),
                PopupMenuItem(value: 'pt', child: Text('🇵🇹  PORTUGUÊS', style: TextStyle(fontWeight: FontWeight.bold))),
                PopupMenuItem(value: 'de', child: Text('🇩🇪  DEUTSCH', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo personalizzato (Assicurati di avere l'immagine in assets/icon/app_icon.png)
                Center(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.style, size: 80, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RUDE\nCARDS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.t('subtitle').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey, 
                    fontSize: 13, 
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 56),

                // Pulsante GIOCA
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameSetupScreen()),
                      );
                    },
                    child: Text(
                      provider.t('play'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pulsante AGGIUNGI CARTE
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditorScreen()),
                      );
                    },
                    child: Text(
                      provider.t('add_cards'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pulsante IMPOSTAZIONI
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: Text(
                      provider.t('settings'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Pulsante REGOLE DEL GIOCO
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white38, width: 1.5),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RulesScreen()),
                      );
                    },
                    child: Text(
                      provider.t('rules_btn'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pulsante CREDITS E INFO
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreditsScreen()),
                      );
                    },
                    child: Text(
                      provider.t('credits_btn'), // Mostrerà "CREDITS E INFO" tradotto
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}