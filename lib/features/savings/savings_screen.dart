import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/transaction_form.dart';
import '../../core/theme/app_theme.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ahorros')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(savingsProvider.notifier).loadTransactions(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No hay ahorros registrados', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: state.transactions.length,
                    itemBuilder: (_, i) => TransactionCard(
                      transaction: state.transactions[i],
                      onDelete: () => ref
                          .read(savingsProvider.notifier)
                          .deleteTransaction(state.transactions[i].id),
                    ),
                  ),
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
      builder: (_) => TransactionForm(
        type: 'savings',
        onSuccess: () => ref.read(savingsProvider.notifier).loadTransactions(),
      ),
    );
  }
}
