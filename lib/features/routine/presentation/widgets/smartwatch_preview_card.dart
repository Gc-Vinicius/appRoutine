import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class SmartwatchPreviewCard extends ConsumerWidget {
  final String title;
  final String body;
  final String time;

  const SmartwatchPreviewCard({
    super.key,
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider.notifier).currentPaletteData;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRÉVIA NO SMARTWATCH (HAYLOU SOLAR NEO)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: palette.primary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: palette.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✓ 100% VISÍVEL NO PULSO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: palette.badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Mockup do Relógio Circular AMOLED
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF101318),
                  border: Border.all(color: const Color(0xFF384050), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 106,
                    height: 106,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF040608), // Display AMOLED profundo
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title.isEmpty ? 'Título da Rotina' : title,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body.isEmpty ? 'Mensagem do alarme' : body,
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: Color(0xFFB0B8C4),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$time • Haylou',
                          style: const TextStyle(
                            fontSize: 6.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Informações do Espelhamento BLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureBullet(palette, 'Sem cortes por reticências (...)'),
                    _buildFeatureBullet(palette, 'Vibração forte com tela apagada'),
                    _buildFeatureBullet(palette, 'Fura o Doze Mode da bateria'),
                    _buildFeatureBullet(palette, 'Texto limpo sem formatação'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullet(dynamic palette, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 12, color: palette.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
