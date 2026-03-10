import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  Teacher? _teacher;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacher();
  }

  Future<void> _fetchTeacher() async {
    final user = Provider.of<auth.User?>(context, listen: false);
    if (user != null) {
      final teacher = await _db.getTeacher(user.uid);
      if (mounted) {
        setState(() {
          _teacher = teacher;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<auth.User?>(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    final displayName = _teacher?.name ?? authUser?.displayName ?? 'Docente';
    final email = _teacher?.email ?? authUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _teacher?.photoUrl ??
                    authUser?.photoURL ??
                    'https://via.placeholder.com/150',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(email, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),

            // Settings List
            _buildSettingItem(Icons.settings_outlined, 'Ajustes App', () {
              Navigator.pushNamed(context, '/settings');
            }),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton(
              onPressed: () async {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey.shade100
              : Colors.grey.shade800,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
