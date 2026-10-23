import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/theme_provider.dart';

/// Tela para Autenticação (Login/Cadastro) e Gestão de Perfil do Usuário
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers para Login / Cadastro
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Controller para Edição de Perfil
  final _editNameController = TextEditingController();
  File? _selectedImageFile;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _editNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String userId) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
          _isLoading = true;
          _errorMessage = null;
        });

        // Upload imediato para o Supabase Storage
        final publicUrl = await SupabaseService().uploadAvatar(
          userId: userId,
          imageFile: _selectedImageFile!,
        );

        if (publicUrl != null) {
          final profile = ref.read(userProfileProvider).value;
          final currentName = profile?.nome ?? _editNameController.text;
          await SupabaseService().updateProfile(
            userId: userId,
            nome: currentName,
            fotoUrl: publicUrl,
          );
          ref.invalidate(userProfileProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto de perfil atualizada com sucesso!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao enviar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Por favor, preencha todos os campos obrigatórios.';
      });
      return;
    }

    try {
      if (_isSignUp) {
        await SupabaseService().signUp(
          email: email,
          password: password,
          nome: name,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada com sucesso! Sincronização ativada.'),
            ),
          );
        }
      } else {
        await SupabaseService().signIn(
          email: email,
          password: password,
        );
      }

      // Dispara sincronização inicial após login
      ref.read(syncProvider.notifier).triggerSync();
      ref.invalidate(userProfileProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Falha na autenticação: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSaveProfile(String userId) async {
    final newName = _editNameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final profile = ref.read(userProfileProvider).value;
      await SupabaseService().updateProfile(
        userId: userId,
        nome: newName,
        fotoUrl: profile?.fotoUrl,
      );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erro ao salvar perfil: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user != null ? 'Minha Conta' : (_isSignUp ? 'Criar Conta' : 'Entrar no AppRoutine')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: user != null
            ? _buildProfileView(context, palette, user, profileAsync.value)
            : _buildAuthForm(context, palette),
      ),
    );
  }

  Widget _buildProfileView(
    BuildContext context,
    dynamic palette,
    dynamic user,
    UserProfile? profile,
  ) {
    if (_editNameController.text.isEmpty && profile?.nome != null) {
      _editNameController.text = profile!.nome;
    }

    final displayName = profile?.nome ?? user.email ?? 'Usuário';
    final photoUrl = profile?.fotoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        // Avatar Interativo
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: palette.surfaceVariant,
              backgroundImage: _selectedImageFile != null
                  ? FileImage(_selectedImageFile!) as ImageProvider
                  : (photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null),
              child: (_selectedImageFile == null && (photoUrl == null || photoUrl.isEmpty))
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: palette.primary,
                      ),
                    )
                  : null,
            ),
            InkWell(
              onTap: _isLoading ? null : () => _pickImage(user.id as String),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: palette.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Text(
          user.email ?? '',
          style: TextStyle(fontSize: 13, color: palette.textMuted),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        // Campo de Edição do Nome
        TextField(
          controller: _editNameController,
          decoration: InputDecoration(
            labelText: 'Nome de Exibição',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSaveProfile(user.id as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),

        // Botão de Sincronização Manual
        Consumer(
          builder: (context, ref, _) {
            final syncState = ref.watch(syncProvider);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.cloud_sync_outlined, color: palette.primary),
              title: const Text('Sincronizar com Nuvem'),
              subtitle: Text(
                syncState.isSyncing
                    ? 'Sincronizando agora...'
                    : (syncState.lastSyncTime != null
                        ? 'Último sync: ${syncState.lastSyncTime!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                        : 'Toque para sincronizar seus alarmes e hábitos'),
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
              trailing: syncState.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.read(syncProvider.notifier).triggerSync(),
                    ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Botão Desconectar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sair da Conta?'),
                  content: const Text(
                    'Seus alarmes e rotinas continuarão salvos no seu aparelho (offline). Você poderá reconectar quando quiser.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sair', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await SupabaseService().signOut();
                ref.invalidate(currentUserProvider);
                ref.invalidate(userProfileProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Desconectar da Conta', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(BuildContext context, dynamic palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.cloud_outlined, size: 40, color: palette.primary),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _isSignUp ? 'Crie sua Conta' : 'Bem-vindo de Volta',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Sincronize suas rotinas e histórico de hábitos com segurança na nuvem.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: palette.textMuted),
          ),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),

        if (_isSignUp) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nome Completo',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
        ],

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-mail',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Senha (mínimo 6 caracteres)',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isSignUp ? 'Cadastrar e Sincronizar' : 'Entrar',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
                _errorMessage = null;
              });
            },
            child: Text(
              _isSignUp
                  ? 'Já tem uma conta? Entrar'
                  : 'Ainda não tem conta? Cadastre-se',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
