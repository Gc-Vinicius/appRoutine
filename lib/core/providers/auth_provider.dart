import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/supabase_sync_service.dart';

/// Provider que emite as alterações de autenticação do usuário
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final supabase = SupabaseService();
  return supabase.authStateChanges ?? const Stream.empty();
});

/// Provider do usuário autenticado atual
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return SupabaseService().currentUser;
});

/// Provider do perfil complementar do usuário (tabela `usuarios`)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return await SupabaseService().loadUserProfile(user.id);
});

/// Estado da Sincronização
class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? lastMessage;
  final bool? lastSuccess;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastMessage,
    this.lastSuccess,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? lastMessage,
    bool? lastSuccess,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  Future<SyncResult> triggerSync() async {
    state = state.copyWith(isSyncing: true, lastMessage: 'Sincronizando...');
    final result = await SupabaseSyncService().syncAll();
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: SupabaseSyncService().lastSyncTime,
      lastMessage: result.message,
      lastSuccess: result.success,
    );
    return result;
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
