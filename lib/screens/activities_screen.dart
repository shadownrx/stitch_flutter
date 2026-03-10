import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/course.dart';
import '../models/activity.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActivitiesScreen extends StatefulWidget {
  final Course course;
  const ActivitiesScreen({super.key, required this.course});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final DatabaseService _db = DatabaseService();
  String _selectedType = 'Todos';

  static const _types = ['Todos', 'Tareas', 'Exámenes', 'Proyectos'];

  void _showAddActivityDialog(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedType = 'Tarea';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 7));
    bool isProcessing = false;

    const typeOptions = ['Tarea', 'Examen', 'Proyecto'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.playlist_add_check_circle_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nueva Actividad',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Título'),
                        TextField(
                          controller: titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco(
                            'Ej: Resolución de ecuaciones',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Descripción / Subtítulo'),
                        TextField(
                          controller: subtitleController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _inputDeco(
                            'Detalles adicionales de la actividad...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Tipo de Actividad'),
                        Row(
                          children: typeOptions.map((type) {
                            final isSelected = selectedType == type;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      setSheetState(() => selectedType = type),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryBlue
                                          : AppTheme.accentBlue.withOpacity(
                                              0.4,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      type,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Fecha de Entrega'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDeadline,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDeadline = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final title = titleController.text.trim();
                                  if (title.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'El título es obligatorio',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setSheetState(() => isProcessing = true);
                                  final id = await _db.createActivity(
                                    courseId: widget.course.id,
                                    title: title,
                                    subtitle: subtitleController.text.trim(),
                                    type: selectedType,
                                    deadline: selectedDeadline,
                                  );
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          id != null
                                              ? 'Actividad creada con éxito'
                                              : 'Error al crear la actividad',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isProcessing ? 'Guardando...' : 'Guardar Actividad',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          children: [
            const Text(
              'Actividades',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.course.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivityDialog(context),
        backgroundColor: AppTheme.successGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Actividad'),
      ),
      body: Column(
        children: [
          // Tabs filter
          Container(
            color: Theme.of(context).cardTheme.color,
            child: Row(
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<List<Activity>>(
              stream: _db.streamActivities(widget.course.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allActivities = snapshot.data ?? [];
                final filtered = allActivities.where((a) {
                  if (_selectedType == 'Todos') return true;
                  if (_selectedType == 'Tareas') return a.type == 'Tarea';
                  if (_selectedType == 'Exámenes') return a.type == 'Examen';
                  if (_selectedType == 'Proyectos') return a.type == 'Proyecto';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.playlist_add_check_circle_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay actividades',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presioná "Nueva Actividad" para agregar',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final activity = filtered[index];
                    return _ActivityCard(activity: activity, isDark: isDark)
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
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isDark;

  const _ActivityCard({required this.activity, required this.isDark});

  Color _typeColor(String type) {
    switch (type) {
      case 'Examen':
        return const Color(0xFFEA580C);
      case 'Proyecto':
        return const Color(0xFF9333EA);
      default:
        return AppTheme.primaryBlue;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'Examen':
        return const Color(0xFFFFF7ED);
      case 'Proyecto':
        return const Color(0xFFFAF5FF);
      default:
        return const Color(0xFFE0E7FF);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Examen':
        return Icons.quiz_outlined;
      case 'Proyecto':
        return Icons.account_tree_outlined;
      default:
        return Icons.book_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'URGENTE':
        return AppTheme.warningOrange;
      case 'COMPLETADO':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(activity.type);
    final bg = _typeBg(activity.type);
    final statusColor = _statusColor(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.2) : bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(activity.type), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity.subtitle.isNotEmpty)
                      Text(
                        activity.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Entrega: ${activity.deadline.day}/${activity.deadline.month}/${activity.deadline.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.15) : bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activity.type,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (activity.totalCount > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: activity.totalCount > 0
                  ? activity.completedCount / activity.totalCount
                  : 0,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
