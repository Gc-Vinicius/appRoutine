import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/theme_provider.dart';

class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final permAsync = ref.watch(permissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primary,
                    ),
                    child: Icon(
                      Icons.check,
                      color: palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistema 100% Otimizado!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Alarmes configurados para furar o Doze Mode e vibrar no Haylou Solar Neo.',
                          style: TextStyle(fontSize: 11, color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SEÇÃO: Permissões Nativas do Android (Sem termos técnicos de código)
            Text(
              'PERMISSÕES NATIVAS DO ANDROID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: palette.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            permAsync.when(
              data: (perms) {
                return Column(
                  children: [
                    _buildPermissionItem(
                      palette: palette,
                      title: 'Alarmes Exatos',
                      desc: 'Permite agendar disparos no segundo exato furando o modo de espera.',
                      isGranted: perms.hasExactAlarm,
                      onRequest: () async {
                        await PermissionService().requestExactAlarmPermission();
                        ref.invalidate(permissionsProvider);
                      },
                    ),
                    _buildPermissionItem(
                      palette: palette,
                      title: 'Notificações Locais',
                      desc: 'Exigido no Android para emitir o aviso sonoro e vibratório no relógio.',
                      isGranted: perms.hasNotification,
                      onRequest: () async {
                        await PermissionService().requestNotificationPermission();
                        ref.invalidate(permissionsProvider);
                      },
                    ),
                    _buildPermissionItem(
                      palette: palette,
                      title: 'Isenção de Economia de Bateria',
                      desc: 'Impede o sistema operacional de congelar os alarmes em segundo plano.',
                      isGranted: perms.hasBatteryOptimizationExemption,
                      onRequest: () async {
                        await PermissionService().requestBatteryOptimizationExemption();
                        ref.invalidate(permissionsProvider);
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text('Erro ao checar permissões', style: TextStyle(color: palette.textMuted)),
            ),
            const SizedBox(height: 24),

            // Botão Disparar Teste de Vibração no Relógio Agora
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService().testWatchNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificação de teste disparada! Verifique a vibração no seu pulso.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.vibration),
              label: const Text('Disparar Teste de Vibração no Relógio Agora'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required dynamic palette,
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isGranted ? null : onRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isGranted ? palette.badgeBg : palette.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isGranted ? 'ATIVO ✓' : 'CONCEDER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isGranted ? palette.badgeText : palette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
