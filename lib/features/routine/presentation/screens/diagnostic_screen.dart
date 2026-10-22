import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../../../../core/services/local_storage_service.dart';
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
                          'Sistema de Alarmes & Wearable',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Configure as permissões para o alarme furar o Doze Mode e vibrar no seu pulso.',
                          style: TextStyle(fontSize: 11, color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SEÇÃO: Permissões Nativas do Android
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
                      title: 'Alarmes Exatos (Alarmes & Lembretes)',
                      desc: 'Permite ao Android despertar e tocar no segundo exato configurado.',
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

            // SEÇÃO: TESTES DE DISPARO
            Text(
              'TESTES DE DISPARO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: palette.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Botão Disparar Teste de Vibração Imediato
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService().testWatchNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificação de teste imediata disparada! Verifique o relógio.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.vibration),
                label: const Text('Disparar Teste Imediato no Relógio'),
              ),
            ),
            const SizedBox(height: 10),

            // Botão Testar Alarme Agendado (em 10 segundos)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService().testScheduledNotificationInSeconds(seconds: 10);
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Alarme Agendado! ⏰'),
                        content: const Text(
                          'Disparo agendado para daqui a 10 segundos.\n\nBloqueie a tela do celular agora para testar o despertar em segundo plano e a vibração no smartwatch!',
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK, Vou Bloquear a Tela'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.alarm_on_outlined),
                label: const Text('Testar Alarme Agendado (em 10 segundos)'),
              ),
            ),
            const SizedBox(height: 28),

            // SEÇÃO: BACKUP E RESTAURAÇÃO LOCAL (100% OFFLINE)
            Text(
              'BACKUP & RESTAURAÇÃO LOCAL (OFFLINE)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: palette.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seus dados nunca saem do seu aparelho. Você pode exportar todas as suas rotinas cadastradas para um arquivo/cópia JSON e restaurá-las a qualquer momento.',
                    style: TextStyle(fontSize: 11.5, color: palette.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportBackupDialog(context, palette),
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text('Exportar Backup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _importBackupDialog(context, ref, palette),
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          label: const Text('Restaurar Backup'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            onTap: onRequest,
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

  Future<void> _exportBackupDialog(BuildContext context, dynamic palette) async {
    final jsonStr = await LocalStorageService.exportBackupJson();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Backup JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copie o texto JSON abaixo para salvar seus alarmes e rotinas em um local seguro:',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fechar', style: TextStyle(color: palette.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup JSON copiado para a área de transferência!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar JSON'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackupDialog(BuildContext context, WidgetRef ref, dynamic palette) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Backup JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cole aqui o código JSON do backup que deseja restaurar no aplicativo:',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 7,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  hintText: '{\n  "app": "appRoutine",\n  "routines": [...]\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, cole o JSON do backup.')),
                );
                return;
              }

              try {
                final count = await LocalStorageService.importBackupJson(text);
                await ref.read(routineListProvider.notifier).reloadFromStorage();
                ref.invalidate(currentPaletteProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sucesso! $count rotinas restauradas.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao restaurar: Formato JSON inválido ($e)')),
                  );
                }
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Restaurar Agora'),
          ),
        ],
      ),
    );
  }
}
