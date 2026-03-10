import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

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
      // Try to launch WhatsApp directly first
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Use the web API which also works with the app installed
        final Uri webUrl = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(message)}',
        );
        // On modern Android/iOS, launching https urls is usually safer
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
