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
            onPressed: () {
              final now = DateTime.now();
              ref.read(recurringProvider.notifier).generate(now.month, now.year);
            },
            icon: const Icon(Icons.playlist_add_check, size: 18),
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
      builder: (_) => _RecurringForm(
        onSuccess: () => ref.read(recurringProvider.notifier).loadRecurring(),
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringExpense recurring;
  final VoidCallback onDelete;

  const _RecurringCard({required this.recurring, required this.onDelete});

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
                    (recurring.categoryColor ?? '#78909C').replaceAll('#', '0xFF'))),
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
                    recurring.description.isNotEmpty ? recurring.description : (recurring.categoryName ?? ''),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Día ${recurring.preferredDay} · ${recurring.categoryName ?? ''}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              currency.format(recurring.amount),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
              onPressed: onDelete,
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(recurringProvider.notifier).addRecurring({
      'category_id': _selectedCategoryId,
      'amount': double.parse(_amountController.text),
      'description': _descriptionController.text,
      'preferred_day': _preferredDay,
    });

    Navigator.of(context).pop();
    widget.onSuccess();
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
                child: ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
