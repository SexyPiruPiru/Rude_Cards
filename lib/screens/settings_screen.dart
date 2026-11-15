import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.t('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Versione App
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(provider.t('app_version')),
            subtitle: const Text('1.0.0+1 (Rude Cards)'),
          ),
          const Divider(),
          
          // Sezione QR Code & Download
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(provider.t('settings_qr_title')),
            subtitle: Text(provider.t('settings_qr_desc')),
            trailing: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(provider.t('qr_code_btn')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2, size: 120),
                        const SizedBox(height: 16),
                        Text(
                          provider.t('settings_qr_desc'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(provider.t('qr_code_btn')),
            ),
          ),
          const Divider(),

          // Sezione Mazzi Aggiuntivi
          ListTile(
            leading: const Icon(Icons.style),
            title: Text(provider.t('settings_decks_title')),
            subtitle: Text(provider.t('settings_decks_desc')),
            trailing: ElevatedButton.icon(
              onPressed: () {
                // Qui potrai inserire il link che mi fornirai successivamente
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.t('settings_decks_desc')),
                  ),
                );
              },
              icon: const Icon(Icons.style),
              label: Text(provider.t('download_decks_btn')),
            ),
          ),
        ],
      ),
    );
  }
}