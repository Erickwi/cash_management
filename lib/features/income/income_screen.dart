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
      child: _buildContent(state, context, ref),
    );
  }

  Widget _buildContent(TransactionState state, BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.pending.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Error al cargar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => ref.read(incomeProvider.notifier).loadTransactions(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No hay ingresos registrados',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: state.transactions.length,
      itemBuilder: (_, i) => TransactionCard(
        key: ValueKey(state.transactions[i].id),
        transaction: state.transactions[i],
        onToggleStatus: () {
          final newStatus = state.transactions[i].status == 'paid' ? 'pending' : 'paid';
          ref.read(incomeProvider.notifier).updateStatus(state.transactions[i].id, newStatus);
          ref.read(allTransactionsProvider.notifier).updateStatusLocally(state.transactions[i].id, newStatus);
        },
        onDelete: () {
          ref.read(incomeProvider.notifier).deleteTransaction(state.transactions[i].id);
          ref.read(allTransactionsProvider.notifier).deleteTransactionLocally(state.transactions[i].id);
        },
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
        onSuccess: (tx) {
          ref.read(incomeProvider.notifier).addTransactionLocally(tx);
          ref.read(allTransactionsProvider.notifier).addTransactionLocally(tx);
        },
        onError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        },
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
