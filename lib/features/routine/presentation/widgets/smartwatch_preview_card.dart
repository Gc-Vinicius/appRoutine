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
    final palette = ref.watch(currentPaletteProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRÉVIA NO SMARTWATCH (HAYLOU SOLAR NEO)',
                style: TextStyle(
                  fontSize: 10.5,
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
                  '✓ VISÍVEL NO PULSO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: palette.badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mockup Centralizado do Relógio Circular AMOLED
          Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF101318),
                border: Border.all(color: const Color(0xFF384050), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 122,
                  height: 122,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF040608), // Display AMOLED profundo
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.isEmpty ? 'Título da Rotina' : title,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body.isEmpty ? 'Mensagem do alarme' : body,
                        style: const TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFFB0B8C4),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$time • Haylou',
                        style: const TextStyle(
                          fontSize: 7.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Informações de Espelhamento Centralizadas
          Center(
            child: Text(
              'Espelhamento em tempo real • Sem cortes no pulso',
              style: TextStyle(fontSize: 11, color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
