import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import 'api_provider.dart';

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final int currentMonth;
  final int currentYear;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    int? currentMonth,
    int? currentYear,
  })  : currentMonth = currentMonth ?? DateTime.now().month,
        currentYear = currentYear ?? DateTime.now().year;

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    int? currentMonth,
    int? currentYear,
  }) => TransactionState(
    transactions: transactions ?? this.transactions,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentMonth: currentMonth ?? this.currentMonth,
    currentYear: currentYear ?? this.currentYear,
  );
}

class TransactionNotifier extends Notifier<TransactionState> {
  final String? typeFilter;

  TransactionNotifier({this.typeFilter});

  @override
  TransactionState build() {
    Future.microtask(() => loadTransactions());
    return TransactionState(isLoading: true);
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final tx = await api.getTransactions(
        type: typeFilter,
        month: state.currentMonth,
        year: state.currentYear,
      );
      state = state.copyWith(transactions: tx, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTransaction(Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.createTransaction(data);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateTransactionStatus(id, status);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setMonth(int month, int year) {
    state = state.copyWith(currentMonth: month, currentYear: year);
    loadTransactions();
  }
}

final incomeProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  () => TransactionNotifier(typeFilter: 'income'),
);

final expenseProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  () => TransactionNotifier(typeFilter: 'expense'),
);

final savingsProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  () => TransactionNotifier(typeFilter: 'savings'),
);

final emergencyProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  () => TransactionNotifier(typeFilter: 'emergency'),
);

final allTransactionsProvider = NotifierProvider<TransactionNotifier, TransactionState>(
  () => TransactionNotifier(),
);
