import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/transaction_card.dart';
import '../../widgets/transaction_form.dart';
import '../../widgets/pie_chart_widget.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseBody extends ConsumerStatefulWidget {
  const ExpenseBody({super.key});

  @override
  ConsumerState<ExpenseBody> createState() => _ExpenseBodyState();
}

class _ExpenseBodyState extends ConsumerState<ExpenseBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseProvider);
    final reportAsync = ref.watch(reportProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.blue,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Lista'),
            Tab(text: 'Gráfico'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(state),
              _buildChart(reportAsync),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(TransactionState state) {
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
              onPressed: () => ref.read(expenseProvider.notifier).loadTransactions(),
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
            Icon(Icons.shopping_cart, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No hay gastos registrados', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(expenseProvider.notifier).loadTransactions(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: state.transactions.length,
        itemBuilder: (_, i) => TransactionCard(
          transaction: state.transactions[i],
          onToggleStatus: () {
            final newStatus = state.transactions[i].status == 'paid' ? 'pending' : 'paid';
            ref.read(expenseProvider.notifier).updateStatus(state.transactions[i].id, newStatus);
          },
          onDelete: () => ref.read(expenseProvider.notifier).deleteTransaction(state.transactions[i].id),
        ),
      ),
    );
  }

  Widget _buildChart(AsyncValue reportAsync) {
    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (report) {
        if (report == null || report.expenseByCategory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('Sin datos de gastos este mes', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Gastos por Categoría',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              PieChartWidget(data: report.expenseByCategory),
              const SizedBox(height: 24),
              ...report.expenseByCategory.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(item.color.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.name, style: GoogleFonts.inter(fontSize: 14))),
                    Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

void showExpenseForm(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: TransactionForm(
        type: 'expense',
        onSuccess: () {
          ref.read(expenseProvider.notifier).loadTransactions();
          ref.read(reportProvider.notifier).loadReport(DateTime.now().month, DateTime.now().year);
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

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.blue,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Lista'),
            Tab(text: 'Gráfico'),
          ],
        ),
      ),
      body: const ExpenseBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showExpenseForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
