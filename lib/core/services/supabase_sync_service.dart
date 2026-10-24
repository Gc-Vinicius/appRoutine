import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'supabase_service.dart';
import '../../features/routine/domain/routine_model.dart';

/// Resultado de uma operação de sincronização
class SyncResult {
  final bool success;
  final String message;
  final int routinesSynced;
  final int checkinsSynced;

  const SyncResult({
    required this.success,
    required this.message,
    this.routinesSynced = 0,
    this.checkinsSynced = 0,
  });
}

/// Serviço de Sincronização em Nuvem (Local-First Cloud Sync)
class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Executa o ciclo de sincronização completo Local-First
  Future<SyncResult> syncAll() async {
    final supabase = SupabaseService();
    final client = supabase.client;
    final user = supabase.currentUser;

    if (client == null || user == null) {
      return const SyncResult(
        success: false,
        message: 'Usuário não conectado ou Supabase offline.',
      );
    }

    if (_isSyncing) {
      return const SyncResult(
        success: false,
        message: 'Sincronização já em andamento.',
      );
    }

    _isSyncing = true;
    int routinesCount = 0;
    int checkinsCount = 0;

    try {
      final userId = user.id;

      // 1. Sincronizar Rotinas / Alarmes
      final localRoutines = await LocalStorageService.loadRoutines() ?? [];
      if (localRoutines.isNotEmpty) {
        final List<Map<String, dynamic>> routinesPayload = localRoutines.map((r) {
          final nowIso = DateTime.now().toUtc().toIso8601String();
          return {
            'id': r.id ?? DateTime.now().millisecondsSinceEpoch,
            'user_id': userId,
            'title': r.title,
            'body': r.body,
            'type': r.type.name,
            'category': r.category.name,
            'custom_category_name': r.customCategoryName,
            'custom_category_emoji': r.customCategoryEmoji,
            'hour': r.hour,
            'minute': r.minute,
            'weekdays': r.weekdays,
            'interval_minutes': r.intervalMinutes,
            'window_start_hour': r.windowStartHour,
            'window_end_hour': r.windowEndHour,
            'punctual_date': r.punctualDate?.toUtc().toIso8601String(),
            'skipped_until': r.skippedUntil?.toUtc().toIso8601String(),
            'is_alarm': r.isAlarm,
            'is_active': r.isActive,
            'created_at': r.createdAt.toUtc().toIso8601String(),
            'updated_at': nowIso,
          };
        }).toList();

        await client.from('rotinas').upsert(
              routinesPayload,
              onConflict: 'user_id,id',
            );
        routinesCount = localRoutines.length;
      }

      // Buscar rotinas da nuvem e atualizar localmente se houver novas
      final remoteRoutinesData = await client
          .from('rotinas')
          .select()
          .eq('user_id', userId);

      if (remoteRoutinesData.isNotEmpty) {
        final List<RoutineModel> mergedRoutines = [];
        for (final row in remoteRoutinesData) {
          try {
            final routineType = RoutineType.values.firstWhere(
              (e) => e.name == row['type'],
              orElse: () => RoutineType.recurring,
            );
            final category = RoutineCategory.values.firstWhere(
              (e) => e.name == row['category'],
              orElse: () => RoutineCategory.general,
            );
            final weekdaysList = (row['weekdays'] as List<dynamic>?)
                    ?.map((w) => w as int)
                    .toList() ??
                const <int>[];

            mergedRoutines.add(
              RoutineModel(
                id: (row['id'] as num).toInt(),
                title: row['title'] as String,
                body: (row['body'] as String?) ?? '',
                type: routineType,
                category: category,
                customCategoryName: row['custom_category_name'] as String?,
                customCategoryEmoji: row['custom_category_emoji'] as String?,
                hour: row['hour'] as int,
                minute: row['minute'] as int,
                weekdays: weekdaysList,
                intervalMinutes: row['interval_minutes'] as int?,
                windowStartHour: row['window_start_hour'] as int?,
                windowEndHour: row['window_end_hour'] as int?,
                punctualDate: row['punctual_date'] != null
                    ? DateTime.parse(row['punctual_date'] as String)
                    : null,
                skippedUntil: row['skipped_until'] != null
                    ? DateTime.parse(row['skipped_until'] as String)
                    : null,
                isAlarm: (row['is_alarm'] as bool?) ?? true,
                isActive: (row['is_active'] as bool?) ?? true,
                createdAt: DateTime.parse(row['created_at'] as String),
              ),
            );
          } catch (e) {
            debugPrint('[SupabaseSync] Erro ao parsear rotina remota: $e');
          }
        }

        if (mergedRoutines.isNotEmpty) {
          await LocalStorageService.saveRoutines(mergedRoutines);
        }
      }

      // 2. Sincronizar Check-ins de Hábitos
      final localCheckins = await LocalStorageService.loadCheckins();
      if (localCheckins.isNotEmpty) {
        final checkinsPayload = localCheckins.map((c) {
          final dateStr =
              '${c.date.year.toString().padLeft(4, '0')}-${c.date.month.toString().padLeft(2, '0')}-${c.date.day.toString().padLeft(2, '0')}';
          return {
            'user_id': userId,
            'routine_id': c.routineId,
            'checkin_date': dateStr,
            'completed_at': c.completedAt.toUtc().toIso8601String(),
            'is_completed': c.isCompleted,
          };
        }).toList();

        await client.from('habit_checkins').upsert(
              checkinsPayload,
              onConflict: 'user_id,routine_id,checkin_date',
            );
        checkinsCount = localCheckins.length;
      }

      // 3. Sincronizar Categorias Customizadas
      final localCategories = await LocalStorageService.loadCategories();
      final customCategories = localCategories.where((c) => !c.isDefault).toList();
      if (customCategories.isNotEmpty) {
        final categoriesPayload = customCategories.map((cat) {
          return {
            'user_id': userId,
            'id': cat.id,
            'name': cat.name,
            'icon_name': cat.emoji,
            'color_value': 0,
          };
        }).toList();

        await client.from('categorias').upsert(
              categoriesPayload,
              onConflict: 'user_id,id',
            );
      }

      // 4. Sincronizar Preferências e Alarm Settings
      final alarmSettings = await LocalStorageService.loadAlarmSettings();
      final savedTheme = await LocalStorageService.loadSavedTheme();
      await client.from('configuracoes_usuario').upsert({
        'user_id': userId,
        'theme_id': savedTheme.name,
        'alarm_settings': alarmSettings.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      _lastSyncTime = DateTime.now();
      return SyncResult(
        success: true,
        message: 'Dados sincronizados com sucesso!',
        routinesSynced: routinesCount,
        checkinsSynced: checkinsCount,
      );
    } catch (e) {
      debugPrint('[SupabaseSyncService] Erro ao sincronizar: $e');
      return SyncResult(
        success: false,
        message: 'Erro na sincronização: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }
}
