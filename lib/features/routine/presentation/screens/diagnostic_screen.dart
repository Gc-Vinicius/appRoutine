import '../../../../core/providers/auth_provider.dart';
import 'auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../../domain/routine_model.dart';
import 'alarm_ringing_screen.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/theme_provider.dart';

class DiagnosticScreen extends ConsumerWidget {
  final bool isEmbedded;

  const DiagnosticScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final permAsync = ref.watch(permissionsProvider);
    final alarmSettings = ref.watch(alarmSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        automaticallyImplyLeading: !isEmbedded,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCloudAccountCard(context, ref, palette),

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
                      color: palette.onPrimary,
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

            // SEÇÃO: EXPERIÊNCIA DE DESPERTAR & SONECA (MOBILE)
            Text(
              'EXPERIÊNCIA DE DESPERTAR & SONECA (MOBILE)',
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
                  // Switch Volume Crescente (Fade-in 30s)
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Volume Crescente (Fade-in)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Inicia suave no volume mínimo e aumenta gradualmente ao longo de 30 segundos até o volume máximo.',
                        style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      ),
                      value: alarmSettings.crescendoVolume,
                      activeTrackColor: palette.primary,
                      onChanged: (val) {
                        ref.read(alarmSettingsProvider.notifier).toggleCrescendoVolume(val);
                      },
                    ),
                  ),
                  Divider(color: palette.border, height: 24),

                  // Duração da Soneca
                  Text(
                    'Duração da Soneca (Snooze)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tempo até o alarme disparar novamente após pressionar o botão de adiar.',
                    style: TextStyle(fontSize: 11, color: palette.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [5, 10, 15].map((mins) {
                      final isSelected = alarmSettings.snoozeDurationMinutes == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text('$mins min${mins == 10 ? ' (Padrão)' : ''}'),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(alarmSettingsProvider.notifier).updateSnoozeDuration(mins);
                          },
                          selectedColor: palette.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? palette.onPrimary : palette.textPrimary,
                          ),
                          backgroundColor: palette.surfaceVariant,
                          side: BorderSide(
                            color: isSelected ? palette.primary : palette.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Divider(color: palette.border, height: 24),

                  // Limite de Sonecas
                  Text(
                    'Limite Máximo de Sonecas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Impede atrasos limitando quantas vezes o alarme pode ser adiado consecutivamente.',
                    style: TextStyle(fontSize: 11, color: palette.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [1, 2, 3, 5].map((count) {
                      final isSelected = alarmSettings.maxSnoozeCount == count;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text('${count}x${count == 3 ? ' (Padrão)' : ''}'),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(alarmSettingsProvider.notifier).updateMaxSnoozeCount(count);
                          },
                          selectedColor: palette.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? palette.onPrimary : palette.textPrimary,
                          ),
                          backgroundColor: palette.surfaceVariant,
                          side: BorderSide(
                            color: isSelected ? palette.primary : palette.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Botão Testar Tela Cheia de Alarme Tocando
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlarmRingingScreen(
                              routine: RoutineModel(
                                id: 99999,
                                title: 'Despertar Matinal ☀️',
                                body: 'Hora de levantar e iniciar o seu dia com foco e energia!',
                                type: RoutineType.recurring,
                                category: RoutineCategory.general,
                                customCategoryName: 'Manhã',
                                customCategoryEmoji: '🌅',
                                hour: DateTime.now().hour,
                                minute: DateTime.now().minute,
                                weekdays: [1, 2, 3, 4, 5],
                                isActive: true,
                                createdAt: DateTime.now(),
                              ),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: palette.primary),
                        foregroundColor: palette.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.fullscreen_rounded, size: 20),
                      label: const Text(
                        'Testar Tela Cheia de Alarme Tocando',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                    _buildPermissionItem(
                      palette: palette,
                      title: 'Tela Cheia sobre Bloqueio (Android 14+)',
                      desc: 'Permite abrir automaticamente a tela cheia do alarme por cima do bloqueio.',
                      isGranted: true,
                      onRequest: () async {
                        await PermissionService().requestFullScreenIntentPermission();
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
            const SizedBox(height: 10),

            // Botão Consultar Fila de Alarmes no Android
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final list = await NotificationService().getPendingNotifications();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Fila de Alarmes no Android (${list.length})'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: list.isEmpty
                              ? const Text('Nenhum alarme pendente agendado no sistema operacional no momento.')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    leading: const Icon(Icons.alarm, size: 20),
                                    title: Text(list[i].title ?? 'Sem título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text(list[i].body ?? '', style: const TextStyle(fontSize: 11)),
                                  ),
                                ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Verificar Fila de Alarmes no Android'),
              ),
            ),
            const SizedBox(height: 32),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isGranted ? Colors.green : Colors.orangeAccent,
            size: 24,
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isGranted)
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              child: const Text('Ativar', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildCloudAccountCard(
    BuildContext context,
    WidgetRef ref,
    dynamic palette,
  ) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final syncState = ref.watch(syncProvider);

    if (user == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                color: palette.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.cloud_outlined,
                color: palette.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup na Nuvem (Supabase)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Modo local ativo. Entre para sincronizar rotinas e hábitos.',
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Entrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final profile = profileAsync.value;
    final displayName = profile?.nome ?? user.email ?? 'Usuário';
    final photoUrl = profile?.fotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: palette.surfaceVariant,
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      user.email ?? '',
                      style: TextStyle(fontSize: 11, color: palette.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sincronizar dados agora',
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.sync, color: palette.primary),
                onPressed: syncState.isSyncing
                    ? null
                    : () async {
                        final res = await ref.read(syncProvider.notifier).triggerSync();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              ),
              IconButton(
                tooltip: 'Gerenciar Conta',
                icon: Icon(Icons.settings_outlined, color: palette.textMuted),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              ),
            ],
          ),
          if (syncState.lastSyncTime != null || syncState.lastMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  size: 14,
                  color: palette.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    syncState.lastSyncTime != null
                        ? 'Sincronizado às ${syncState.lastSyncTime!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                        : (syncState.lastMessage ?? ''),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: palette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}