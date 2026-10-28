import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Modelo simples para representar o perfil público do usuário
class UserProfile {
  final String id;
  final String nome;
  final String? fotoUrl;

  const UserProfile({
    required this.id,
    required this.nome,
    this.fotoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      nome: (map['nome'] as String?) ?? 'Usuário',
      fotoUrl: map['foto_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'foto_url': fotoUrl,
    };
  }
}

/// Serviço de integração e autenticação com o Supabase
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Inicializa o Supabase com resiliência a falhas de rede e ambiente offline
  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabasePublishableKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Inicializado com sucesso.');
    } catch (e) {
      _initialized = false;
      debugPrint('[SupabaseService] Falha ao inicializar (modo offline ativado): $e');
    }
  }

  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Carrega o perfil complementar do usuário da tabela `usuarios`
  Future<UserProfile?> loadUserProfile(String userId) async {
    final c = client;
    if (c == null) return null;
    try {
      final res = await c
          .from('usuarios')
          .select('id, nome, foto_url')
          .eq('id', userId)
          .maybeSingle();
      if (res != null) {
        return UserProfile.fromMap(res);
      }
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] Erro ao carregar perfil: $e');
      return null;
    }
  }

  /// Cadastro com e-mail, senha e nome
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String nome,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase não inicializado ou offline');
    return await c.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nome': nome.trim()},
    );
  }

  /// Login com e-mail e senha
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase não inicializado ou offline');
    return await c.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Desconectar conta
  Future<void> signOut() async {
    final c = client;
    if (c != null) {
      await c.auth.signOut();
    }
  }

  /// Atualiza nome e/ou foto na tabela `usuarios`
  Future<void> updateProfile({
    required String userId,
    required String nome,
    String? fotoUrl,
  }) async {
    final c = client;
    if (c == null) return;
    try {
      await c.from('usuarios').upsert({
        'id': userId,
        'nome': nome.trim(),
        'foto_url': fotoUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseService] Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  /// Faz upload da foto para o bucket `avatars` no Supabase Storage
  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final c = client;
    if (c == null) return null;
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await imageFile.readAsBytes();

      await c.storage.from(SupabaseConfig.avatarsBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final publicUrl = c.storage.from(SupabaseConfig.avatarsBucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] Erro no upload de avatar: $e');
      rethrow;
    }
  }
}
