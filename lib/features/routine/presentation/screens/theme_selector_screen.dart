import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/theme_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class ThemeSelectorScreen extends ConsumerWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePalette = ref.watch(themeProvider.notifier).currentPaletteData;

    final allThemes = [
      AppPalettes.carmimPergaminho,
      AppPalettes.taigaNordica,
      AppPalettes.brisaCosteira,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temas & Aparência'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Concluir',
              style: TextStyle(
                color: activePalette.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a identidade visual do aplicativo. As 3 opções possuem contraste otimizado para o display do Haylou Solar Neo.',
              style: TextStyle(fontSize: 11.5, color: activePalette.textMuted),
            ),
            const SizedBox(height: 20),

            // Lista dos 3 Temas
            for (final pal in allThemes)
              ThemeCard(
                palette: pal,
                isSelected: pal.id == activePalette.id,
                onSelect: () {
                  ref.read(themeProvider.notifier).setPaletteById(pal.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text('Tema alterado para "${pal.name}".'),
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Confirmar e Aplicar Tema'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'A preferência de tema é persistida localmente (RF07).',
                style: TextStyle(fontSize: 10, color: activePalette.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
