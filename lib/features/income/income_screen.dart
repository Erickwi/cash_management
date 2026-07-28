import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/transaction_form.dart';
import '../../core/theme/app_theme.dart';

class IncomeBody extends ConsumerWidget {
  const IncomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomeProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(incomeProvider.notifier).loadTransactions(),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('No hay ingresos registrados',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: state.transactions.length,
                  itemBuilder: (_, i) => TransactionCard(
                    transaction: state.transactions[i],
                    onToggleStatus: () {
                      final newStatus = state.transactions[i].status == 'paid' ? 'pending' : 'paid';
                      ref.read(incomeProvider.notifier).updateStatus(state.transactions[i].id, newStatus);
                    },
                    onDelete: () => ref.read(incomeProvider.notifier).deleteTransaction(state.transactions[i].id),
                  ),
                ),
    );
  }
}

void showIncomeForm(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: TransactionForm(
        type: 'income',
        onSuccess: () => ref.read(incomeProvider.notifier).loadTransactions(),
      ),
    ),
  );
}

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos')),
      body: const IncomeBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showIncomeForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
