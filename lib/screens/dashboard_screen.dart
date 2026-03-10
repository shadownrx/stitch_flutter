import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../models/teacher.dart';
import '../models/course.dart';
import '../models/institution.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  Teacher? _teacher;
  Institution? _selectedInstitution;
  Course? _selectedCourse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacher();
  }

  Future<void> _fetchTeacher() async {
    final user = _auth.currentUser;
    print('Starting _fetchTeacher for user: ${user?.uid}');
    if (user != null) {
      try {
        Teacher? teacher = await _db.getTeacher(user.uid);
        print('Initial getTeacher result: ${teacher?.name}');

        // Auto-create teacher if not exists
        if (teacher == null) {
          print('Teacher profile not found, creating new profile...');
          teacher = await _db.createTeacher(
            user.uid,
            user.displayName ?? 'Docente',
            user.email ?? '',
            photoUrl: user.photoURL,
          );
          print('Profile created successfully: ${teacher?.id}');
        }

        if (mounted) {
          setState(() {
            _teacher = teacher;
            _loading = false;
          });

          // Load institutions and default courses
          if (teacher != null && teacher.institutionIds.isNotEmpty) {
            print('Loading institutions for ids: ${teacher.institutionIds}');
            final institution = await _db.getInstitution(
              teacher.institutionIds.first,
            );
            if (mounted) {
              setState(() {
                _selectedInstitution = institution;
              });

              if (institution != null) {
                final courses = await _db.getCourses(teacher.id);
                // Filter courses for the selected institution
                final filteredCourses = courses
                    .where((c) => c.institutionId == institution.id)
                    .toList();
                print(
                  'Found ${filteredCourses.length} courses for institution',
                );
                if (filteredCourses.isNotEmpty && mounted) {
                  setState(() {
                    _selectedCourse = filteredCourses.first;
                  });
                }
              }
            }
          } else {
            print('Teacher has no institutionIds linked.');
          }
        }
      } catch (e) {
        print('CRITICAL ERROR in _fetchTeacher: $e');
        if (mounted) setState(() => _loading = false);
      }
    } else {
      print('Current user is NULL in _fetchTeacher');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authUser = Provider.of<auth.User?>(context);
    // Use Firestore name first, then Google account name, then fallback
    final displayName =
        (_teacher?.name.isNotEmpty == true && _teacher?.name != 'Docente')
        ? _teacher!.name
        : (authUser?.displayName?.isNotEmpty == true
              ? authUser!.displayName!
              : 'Docente');
    final firstName = displayName.split(' ')[0];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildSidebar(context, displayName, authUser),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                [
                      _buildTopBar(displayName, firstName),
                      _buildInstitutionCard(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, $firstName!',
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestiona tus clases para hoy.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      _buildActionGrid(context),
                      _buildUpcomingClasses(context, authUser),
                      const SizedBox(height: 32),
                    ]
                    .animate(interval: 50.ms)
                    .fade(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    String displayName,
    auth.User? authUser,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final photoUrl = _teacher?.photoUrl ?? authUser?.photoURL;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prof. $displayName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    authUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nav Items
            _buildDrawerItem(
              context,
              Icons.home_outlined,
              'Inicio',
              () => Navigator.pop(context),
            ),
            _buildDrawerItem(context, Icons.how_to_reg, 'Pase de Lista', () {
              Navigator.pop(context);
              if (_selectedCourse != null) {
                Navigator.pushNamed(
                  context,
                  '/roll_call',
                  arguments: _selectedCourse,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecciona un curso primero')),
                );
              }
            }),
            _buildDrawerItem(
              context,
              Icons.assignment_outlined,
              'Carga de Notas',
              () {
                Navigator.pop(context);
                if (_selectedCourse != null) {
                  Navigator.pushNamed(
                    context,
                    '/grades',
                    arguments: _selectedCourse,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un curso primero'),
                    ),
                  );
                }
              },
            ),
            _buildDrawerItem(
              context,
              Icons.menu_book_outlined,
              'Plan de Clase',
              () {
                Navigator.pop(context);
                if (_selectedCourse != null) {
                  Navigator.pushNamed(
                    context,
                    '/class_plan',
                    arguments: _selectedCourse,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un curso primero'),
                    ),
                  );
                }
              },
            ),
            _buildDrawerItem(
              context,
              Icons.playlist_add_check_circle_outlined,
              'Actividades',
              () {
                Navigator.pop(context);
                if (_selectedCourse != null) {
                  Navigator.pushNamed(
                    context,
                    '/activities',
                    arguments: _selectedCourse,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un curso primero'),
                    ),
                  );
                }
              },
            ),
            _buildDrawerItem(context, Icons.people_outline, 'Alumnos', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/student_list');
            }),
            _buildDrawerItem(context, Icons.settings_outlined, 'Ajustes', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            }),
            const Spacer(),
            const Divider(),
            // Dark mode toggle
            ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.primaryBlue,
              ),
              title: Text(isDark ? 'Modo Oscuro' : 'Modo Claro'),
              trailing: Switch(
                value: isDark,
                onChanged: (_) => themeService.toggleTheme(),
                activeThumbColor: AppTheme.primaryBlue,
              ),
            ),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Salir',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await authService.signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  Widget _buildTopBar(String displayName, String firstName) {
    final authUser = Provider.of<auth.User?>(context);
    final photoUrl = _teacher?.photoUrl ?? authUser?.photoURL;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Hamburger menu
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: Icon(
                Icons.menu,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar with graceful fallback
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentBlue,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prof. $firstName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Text(
                'Activo',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Institución badge
          if (_selectedInstitution != null)
            GestureDetector(
              onTap: () => _showInstitutionSelector(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        _selectedInstitution!.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstitutionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'INSTITUCIÓN ACTUAL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showInstitutionSelector(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedInstitution?.name ?? 'Selecciona Escuela',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                // Scroll to course list or show a quick selector
                // For now, let's just make the whole row clickable
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURSO SELECCIONADO',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedCourse?.name ?? 'Selecciona un curso',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showQuickCourseSelector(context),
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Cambiar',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstitutionSelector(BuildContext context) {
    if (_teacher == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StreamBuilder<List<Institution>>(
          stream: _db.streamInstitutions(_teacher!.institutionIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();

            final institutions = snapshot.data!;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Institución',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (institutions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No tienes instituciones vinculadas.'),
                    )
                  else
                    ...institutions.map(
                      (inst) => ListTile(
                        leading: const Icon(
                          Icons.school,
                          color: AppTheme.primaryBlue,
                        ),
                        title: Text(
                          inst.name,
                          style: TextStyle(
                            fontWeight: _selectedInstitution?.id == inst.id
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: _selectedInstitution?.id == inst.id
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryBlue,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedInstitution = inst;
                            _selectedCourse = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  const Divider(height: 32),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppTheme.primaryBlue),
                    ),
                    title: const Text(
                      'Añadir Escuela',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddInstitutionDialog(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickCourseSelector(BuildContext context) {
    if (_teacher == null || _selectedInstitution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una institución primero'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StreamBuilder<List<Course>>(
          stream: _db.streamCourses(
            _teacher!.id,
            institutionId: _selectedInstitution!.id,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();

            final courses = snapshot.data!;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Curso',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (courses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No hay cursos en esta institución.'),
                    ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ...courses.map(
                          (course) => ListTile(
                            leading: const Icon(
                              Icons.class_,
                              color: AppTheme.primaryBlue,
                            ),
                            title: Text(
                              course.name,
                              style: TextStyle(
                                fontWeight: _selectedCourse?.id == course.id
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(course.room ?? 'Sin aula'),
                            trailing: _selectedCourse?.id == course.id
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryBlue,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCourse = course;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const Divider(height: 32),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          title: const Text(
                            'Añadir Nuevo Curso',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showAddCourseDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddInstitutionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final joinIdController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DefaultTabController(
            length: 2,
            child: AlertDialog(
              title: const Text('Añadir Institución'),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TabBar(
                      labelColor: AppTheme.primaryBlue,
                      unselectedLabelColor: AppTheme.textSecondary,
                      tabs: [
                        Tab(text: 'Crear'),
                        Tab(text: 'Unirse'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isProcessing)
                      const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: TabBarView(
                          children: [
                            // Create Tab
                            Column(
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre de la Escuela',
                                    hintText: 'Ej. Colegio San Juan',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: addressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dirección (Opcional)',
                                  ),
                                ),
                              ],
                            ),
                            // Join Tab
                            Column(
                              children: [
                                TextField(
                                  controller: joinIdController,
                                  decoration: const InputDecoration(
                                    labelText: 'ID de la Institución',
                                    hintText: 'Pega el código aquí',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Pide el ID al administrador de tu institución para unirte.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final int tabIndex = DefaultTabController.of(
                              context,
                            ).index;
                            String? errorMessage;

                            setDialogState(() => isProcessing = true);

                            try {
                              if (tabIndex == 0) {
                                // Create
                                if (nameController.text.trim().isEmpty) {
                                  errorMessage = 'El nombre es obligatorio';
                                } else if (_teacher == null) {
                                  errorMessage = 'Error: Perfil no cargado';
                                } else {
                                  final id = await _db.createInstitution(
                                    _teacher!.id,
                                    nameController.text.trim(),
                                    addressController.text.trim().isEmpty
                                        ? null
                                        : addressController.text.trim(),
                                  );
                                  if (id == null)
                                    errorMessage = 'Error al crear la escuela';
                                }
                              } else {
                                // Join
                                if (joinIdController.text.trim().isEmpty) {
                                  errorMessage = 'El ID es obligatorio';
                                } else if (_teacher == null) {
                                  errorMessage = 'Error: Perfil no cargado';
                                } else {
                                  final success = await _db.joinInstitution(
                                    _teacher!.id,
                                    joinIdController.text.trim(),
                                  );
                                  if (!success)
                                    errorMessage =
                                        'ID no encontrado o inválido';
                                }
                              }
                            } catch (e) {
                              errorMessage = 'Error inesperado: $e';
                            }

                            if (mounted) {
                              if (errorMessage == null) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Éxito! Institución vinculada.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchTeacher();
                              } else {
                                setDialogState(() => isProcessing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    if (_selectedInstitution == null || _teacher == null) return;

    final nameController = TextEditingController();
    final roomController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Crear Nuevo Curso'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Curso',
                    hintText: 'Ej. Matemática 1°A',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Aula / Salón (Opcional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;

                        setDialogState(() => isProcessing = true);

                        final id = await _db.createCourse(
                          _teacher!.id,
                          _selectedInstitution!.id,
                          nameController.text.trim(),
                          room: roomController.text.trim().isEmpty
                              ? null
                              : roomController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          if (id != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Curso creado con éxito'),
                              ),
                            );
                            _fetchTeacher();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al crear el curso'),
                              ),
                            );
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    // Only unique actions — Actividades and Alumnos are accessible from the sidebar
    final actions = [
      _ActionItem(
        Icons.how_to_reg,
        'Pase de Lista',
        const Color(0xFFE0E7FF),
        AppTheme.primaryBlue,
        '/roll_call',
      ),
      _ActionItem(
        Icons.assignment_outlined,
        'Carga de Notas',
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        '/grades',
      ),
      _ActionItem(
        Icons.menu_book_outlined,
        'Plan de Clase',
        const Color(0xFFFAF5FF),
        const Color(0xFF9333EA),
        '/class_plan',
      ),
      _ActionItem(
        Icons.playlist_add_check_circle_outlined,
        'Actividades',
        const Color(0xFFECFDF5),
        AppTheme.successGreen,
        '/activities',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          return Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    if (item.route == '/roll_call' ||
                        item.route == '/grades' ||
                        item.route == '/activities' ||
                        item.route == '/class_plan') {
                      if (_selectedCourse != null) {
                        Navigator.pushNamed(
                          context,
                          item.route,
                          arguments: _selectedCourse,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor selecciona un curso primero',
                            ),
                          ),
                        );
                      }
                    } else {
                      Navigator.pushNamed(context, item.route);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.bgColor.withOpacity(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 0.2
                                  : 1.0,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fade(delay: (100 * index).ms)
              .scale(
                delay: (100 * index).ms,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
        },
      ),
    );
  }

  Widget _buildUpcomingClasses(BuildContext context, auth.User? authUser) {
    if (_loading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mis Cursos', style: Theme.of(context).textTheme.titleLarge),
              if (_selectedInstitution != null)
                TextButton.icon(
                  onPressed: () => _showAddCourseDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Course>>(
            stream: _db.streamCourses(
              _teacher?.id ?? authUser?.uid ?? '',
              institutionId: _selectedInstitution?.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No tienes cursos asignados.'));
              }

              final courses = snapshot.data!;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCourse = course;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Curso seleccionado: ${course.name}',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: _buildClassCard(
                          course.name,
                          'Activo',
                          course.room ?? 'Sin aula',
                          _selectedCourse?.id == course.id
                              ? AppTheme.primaryBlue
                              : AppTheme.successGreen,
                          isSelected: _selectedCourse?.id == course.id,
                        ),
                      )
                      .animate()
                      .fade(delay: (100 * index).ms)
                      .slideX(
                        begin: 0.1,
                        end: 0,
                        delay: (100 * index).ms,
                        curve: Curves.easeOut,
                      );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    String title,
    String time,
    String details,
    Color statusColor, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue
              : (Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade100
                    : Colors.grey.shade800),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.backgroundLight
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String title;
  final Color bgColor;
  final Color iconColor;
  final String route;

  _ActionItem(this.icon, this.title, this.bgColor, this.iconColor, this.route);
}
