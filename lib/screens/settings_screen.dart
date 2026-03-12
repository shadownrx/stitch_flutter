import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final imageUrl = await _db.uploadProfileImage(user.uid, File(image.path));

      if (imageUrl != null) {
        await _db.updateTeacherProfile(user.uid, photoUrl: imageUrl);
        await user.updatePhotoURL(imageUrl);
        if (mounted) {
          setState(() {}); // Refresh to show new image
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _editName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tu nombre completo'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await _db.updateTeacherProfile(user.uid, name: newName);
                  await user.updateDisplayName(newName);
                  await user.reload(); // Force local refresh

                  if (mounted) {
                    setState(() {}); // Refresh UI
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nombre actualizado')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = themeService.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: isDark
                          ? AppTheme.primaryBlue.withOpacity(0.2)
                          : AppTheme.accentBlue,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Text(
                              (user?.displayName != null &&
                                      user!.displayName!.isNotEmpty)
                                  ? user.displayName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            )
                          : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _changeProfilePicture,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _editName,
                      icon: const Icon(Icons.edit, size: 18),
                      color: AppTheme.primaryBlue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionHeader('Apariencia'),
          _buildSettingCard(
            context,
            'Modo Oscuro',
            'Cambia el tema de la aplicación',
            Icons.dark_mode_outlined,
            trailing: Switch(
              value: themeService.isDarkMode,
              onChanged: (value) => themeService.toggleTheme(),
              activeThumbColor: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notificaciones'),
          _buildSettingCard(
            context,
            'Alertas de Alumnos',
            'IA detectando riesgos de faltas',
            Icons.notification_important_outlined,
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeThumbColor: AppTheme.primaryBlue,
            ),
          ),
          _buildSettingCard(
            context,
            'Mensajes de Chat',
            'Avisos de colegas docentes',
            Icons.chat_outlined,
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeThumbColor: AppTheme.primaryBlue,
            ),
          ),
          _buildSettingCard(
            context,
            'Recordatorios',
            'Planificación y carga de notas',
            Icons.event_note_outlined,
            trailing: Switch(
              value: false,
              onChanged: (v) {},
              activeThumbColor: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Interacción'),
          _buildSettingCard(
            context,
            'Compartir con Colegas',
            'Envía Escolaris a otros docentes',
            Icons.share_outlined,
            onTap: () => _shareApp(context),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('General'),
          _buildSettingCard(
            context,
            'Acerca de Escolaris',
            'Versión 1.0.0',
            Icons.info_outline,
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 32),
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _showLogoutConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.light
                    ? Colors.red.shade50
                    : Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const String message =
        '¡Hola! Te recomiendo Escolaris, la app definitiva para gestionar tus clases y alumnos de forma eficiente. Descárgala aquí: https://escolaris.app';
    final Uri whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        final Uri webUrl = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(message)}',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Escolaris',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.school,
        size: 40,
        color: AppTheme.primaryBlue,
      ),
      children: [
        const Text(
          'Escolaris es una plataforma diseñada para facilitar la labor docente, permitiendo la gestión integral de cursos, alumnos y calificaciones en un solo lugar.',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.primaryBlue.withOpacity(0.2)
                : AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
