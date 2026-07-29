import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionForm extends ConsumerStatefulWidget {
  final String type;
  final VoidCallback? onSuccess;
  final void Function(String)? onError;

  const TransactionForm({
    super.key,
    required this.type,
    this.onSuccess,
    this.onError,
  });

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCategoryId;
  String _status = 'paid';
  bool _isSubmitting = false;

  String get _title {
    switch (widget.type) {
      case 'income': return 'Nuevo Ingreso';
      case 'expense': return 'Nuevo Gasto';
      case 'savings': return 'Nuevo Ahorro';
      case 'emergency': return 'Nueva Emergencia';
      default: return 'Nuevo';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final data = <String, dynamic>{
      'type': widget.type,
      'amount': double.parse(_amountController.text),
      'description': _descriptionController.text,
      'date': dateTime.toIso8601String(),
      'status': _status,
    };

    if (_selectedCategoryId != null) {
      data['category_id'] = _selectedCategoryId;
    }

    try {
      switch (widget.type) {
        case 'income':
          await ref.read(incomeProvider.notifier).addTransaction(data);
        case 'expense':
          await ref.read(expenseProvider.notifier).addTransaction(data);
        case 'savings':
          await ref.read(savingsProvider.notifier).addTransaction(data);
        case 'emergency':
          await ref.read(emergencyProvider.notifier).addTransaction(data);
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      widget.onError?.call(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final categories = categoriesAsync.value ?? [];
    final showCategories = widget.type == 'income' || widget.type == 'expense';
    final filteredCategories = showCategories
        ? categories.where((c) => c.type == widget.type).toList()
        : [];

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese un monto';
                  if (double.tryParse(v) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (filteredCategories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: filteredCategories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 18,
                            color: Color(int.parse(c.color.replaceAll('#', '0xFF')))),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) {
                    if (widget.type == 'expense' && v == null) return 'Seleccione una categoria';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripcion (opcional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_selectedTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.type == 'expense') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Estado: '),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'paid', label: Text('Pagado')),
                        ButtonSegment(value: 'pending', label: Text('Pendiente')),
                      ],
                      selected: {_status},
                      onSelectionChanged: (v) => setState(() => _status = v.first),
                    ),
                  ],
                ),
              ],
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
