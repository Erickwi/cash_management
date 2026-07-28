import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/room_provider.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allTransactionsProvider);
    final roomState = ref.watch(roomProvider);
    final transactions = allAsync.transactions;
    final month = DateFormat('MMMM yyyy').format(DateTime.now());

    double totalIncome = 0;
    double totalExpenses = 0;
    double totalSavings = 0;
    double totalEmergency = 0;

    for (final tx in transactions) {
      switch (tx.type) {
        case 'income': totalIncome += tx.amount; break;
        case 'expense': totalExpenses += tx.amount; break;
        case 'savings': totalSavings += tx.amount; break;
        case 'emergency': totalEmergency += tx.amount; break;
      }
    }

    final recentTransactions = transactions.take(5).toList();
    final balance = totalIncome - totalExpenses;
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: () => ref.read(allTransactionsProvider.notifier).loadTransactions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${roomState.device?.alias ?? ''}',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      month,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Balance', style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                      Text(
                        currency.format(balance),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (allAsync.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  SummaryCard(
                    label: 'Ingresos',
                    amount: totalIncome,
                    icon: Icons.arrow_downward,
                    color: AppColors.success,
                  ),
                  SummaryCard(
                    label: 'Gastos',
                    amount: totalExpenses,
                    icon: Icons.arrow_upward,
                    color: AppColors.pending,
                  ),
                  SummaryCard(
                    label: 'Ahorros',
                    amount: totalSavings,
                    icon: Icons.savings,
                    color: AppColors.blue,
                  ),
                  SummaryCard(
                    label: 'Emergencia',
                    amount: totalEmergency,
                    icon: Icons.warning_amber,
                    color: AppColors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Movimientos Recientes',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (recentTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Sin movimientos este mes',
                            style: GoogleFonts.inter(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ...recentTransactions.map((tx) => TransactionCard(
                  transaction: tx,
                  onToggleStatus: () {
                    final newStatus = tx.status == 'paid' ? 'pending' : 'paid';
                    ref.read(allTransactionsProvider.notifier).updateStatus(tx.id, newStatus);
                  },
                )),
            ],
          ],
        ),
      ),
    );
  }
}
