import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/recurring_expense.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recurringProvider.notifier).loadRecurring();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recurringAsync = ref.watch(recurringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Recurrentes'),
        actions: [
            TextButton.icon(
            onPressed: _isGenerating ? null : () async {
              setState(() => _isGenerating = true);
              final now = DateTime.now();
              await ref.read(recurringProvider.notifier).generate(now.month, now.year);
              if (mounted) setState(() => _isGenerating = false);
            },
            icon: _isGenerating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check, size: 18),
            label: const Text('Generar este mes'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Sin gastos recurrentes', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega servicios como Agua, Luz, Internet\ny se generarán automáticamente cada mes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: list.length,
            itemBuilder: (_, i) => _RecurringCard(
              recurring: list[i],
              onDelete: () => ref.read(recurringProvider.notifier).deleteRecurring(list[i].id),
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: _RecurringForm(
          onSuccess: () => ref.read(recurringProvider.notifier).loadRecurring(),
        ),
      ),
    );
  }
}

class _RecurringCard extends StatefulWidget {
  final RecurringExpense recurring;
  final VoidCallback onDelete;

  const _RecurringCard({required this.recurring, required this.onDelete});

  @override
  State<_RecurringCard> createState() => _RecurringCardState();
}

class _RecurringCardState extends State<_RecurringCard> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(int.parse(
                    (widget.recurring.categoryColor ?? '#78909C').replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.repeat, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recurring.description.isNotEmpty ? widget.recurring.description : (widget.recurring.categoryName ?? ''),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Día ${widget.recurring.preferredDay} · ${widget.recurring.categoryName ?? ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              currency.format(widget.recurring.amount),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
              onPressed: _isDeleting ? null : () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Eliminar?'),
                    content: Text('Se eliminará "${widget.recurring.description.isNotEmpty ? widget.recurring.description : (widget.recurring.categoryName ?? '')}"'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() => _isDeleting = true);
                          widget.onDelete();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringForm extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _RecurringForm({required this.onSuccess});

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  int _preferredDay = DateTime.now().day;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(recurringProvider.notifier).addRecurring({
        'category_id': _selectedCategoryId,
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'preferred_day': _preferredDay,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final categories = categoriesAsync.value ?? [];
    final expenseCategories = categories.where((c) => c.type == 'expense').toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nuevo Gasto Recurrente',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: expenseCategories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Seleccione una categoría' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese un monto';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _preferredDay,
                decoration: const InputDecoration(labelText: 'Día preferido del mes'),
                items: List.generate(31, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}'),
                )),
                onChanged: (v) => setState(() => _preferredDay = v ?? 1),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
