import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/course.dart';
import '../models/class_plan.dart';
import '../services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ClassPlanScreen extends StatefulWidget {
  final Course course;
  const ClassPlanScreen({super.key, required this.course});

  @override
  State<ClassPlanScreen> createState() => _ClassPlanScreenState();
}

class _ClassPlanScreenState extends State<ClassPlanScreen> {
  final DatabaseService _db = DatabaseService();

  Future<void> _sharePlan(BuildContext context, ClassPlan plan) async {
    try {
      final String message =
          'Plan de Clase: ${plan.title}\nMateria: ${plan.subject}\n'
          'Fecha: ${plan.date.day}/${plan.date.month}/${plan.date.year}\n'
          'Estado: ${plan.status}\n\n'
          'Descripción: ${plan.description}'
          '${plan.objectives.isNotEmpty ? '\n\nObjetivos:\n${plan.objectives.map((o) => '• $o').join('\n')}' : ''}';

      final Uri whatsappUrl = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        final Uri webUrl = Uri.parse(
          'https://wa.me/?text=${Uri.encodeComponent(message)}',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al compartir: $e')));
      }
    }
  }

  void _showAddPlanDialog(BuildContext context) {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    final objectiveController = TextEditingController();
    final List<String> objectives = [];
    DateTime selectedDate = DateTime.now();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
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
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nuevo Plan de Clase',
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
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Título del Plan'),
                        TextField(
                          controller: titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('Ej: Introducción al Álgebra'),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Materia'),
                        TextField(
                          controller: subjectController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDeco('Ej: Matemáticas'),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Descripción'),
                        TextField(
                          controller: descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 6,
                          decoration: _inputDeco(
                            'Descripción general de la clase...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FormLabel('Fecha'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
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
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FormLabel('Objetivos de Aprendizaje'),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: objectiveController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _inputDeco(
                                  'Agregar un objetivo...',
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    setSheetState(() {
                                      objectives.add(val.trim());
                                      objectiveController.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () {
                                if (objectiveController.text
                                    .trim()
                                    .isNotEmpty) {
                                  setSheetState(() {
                                    objectives.add(
                                      objectiveController.text.trim(),
                                    );
                                    objectiveController.clear();
                                  });
                                }
                              },
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (objectives.isNotEmpty)
                          ...objectives.asMap().entries.map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setSheetState(
                                      () => objectives.removeAt(entry.key),
                                    ),
                                    icon: const Icon(Icons.close, size: 16),
                                    color: AppTheme.textSecondary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                                  final subject = subjectController.text.trim();
                                  final description = descriptionController.text
                                      .trim();

                                  if (title.isEmpty || subject.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'El título y la materia son obligatorios',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isProcessing = true);
                                  final id = await _db.createClassPlan(
                                    courseId: widget.course.id,
                                    title: title,
                                    subject: subject,
                                    description: description,
                                    date: selectedDate,
                                    objectives: List.from(objectives),
                                  );
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          id != null
                                              ? 'Plan creado con éxito'
                                              : 'Error al crear el plan',
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
                            isProcessing ? 'Guardando...' : 'Guardar Plan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
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

  void _showDeleteConfirmation(BuildContext context, ClassPlan plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: Text('¿Estás seguro de que quieres eliminar "${plan.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _db.deleteClassPlan(widget.course.id, plan.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
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
              'Plan de Clase',
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
        onPressed: () => _showAddPlanDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Plan'),
      ),
      body: StreamBuilder<List<ClassPlan>>(
        stream: _db.streamClassPlans(widget.course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay planes de clase',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presioná "Nuevo Plan" para comenzar',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _PlanCard(
                    plan: plan,
                    isDark: isDark,
                    onShare: () => _sharePlan(context, plan),
                    onTap: () => _showPlanDetail(context, plan),
                    onToggleStatus: () {
                      final newStatus = plan.status == 'PENDIENTE'
                          ? 'COMPLETADO'
                          : 'PENDIENTE';
                      _db.updateClassPlanStatus(
                        widget.course.id,
                        plan.id,
                        newStatus,
                      );
                    },
                    onDelete: () => _showDeleteConfirmation(context, plan),
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
    );
  }

  void _showPlanDetail(BuildContext context, ClassPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton.outlined(
                            onPressed: () {
                              Navigator.pop(context);
                              _sharePlan(context, plan);
                            },
                            icon: const Icon(Icons.share_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${plan.subject} • ${plan.date.day}/${plan.date.month}/${plan.date.year}',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: plan.status == 'COMPLETADO'
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              plan.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: plan.status == 'COMPLETADO'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (plan.description.isNotEmpty) ...[
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (plan.objectives.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.blur_on,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Objetivos de Aprendizaje',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...plan.objectives.map(
                          (obj) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryBlue,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    obj,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ClassPlan plan;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onShare,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = plan.status == 'COMPLETADO';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
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
                    color: isCompleted
                        ? Colors.green.shade50
                        : AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.menu_book_outlined,
                    color: isCompleted ? Colors.green : AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? AppTheme.textSecondary : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        plan.subject,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'status') onToggleStatus();
                    if (val == 'share') onShare();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.pending_actions
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCompleted
                                ? 'Marcar como Pendiente'
                                : 'Marcar como Completado',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text('Compartir por WhatsApp'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.more_vert, color: Colors.grey.shade400),
                ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                plan.description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
                  '${plan.date.day}/${plan.date.month}/${plan.date.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (plan.objectives.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.blur_on,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.objectives.length} objetivo${plan.objectives.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    plan.status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
