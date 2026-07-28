import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/recurring_expense.dart';
import 'api_provider.dart';

class RecurringNotifier extends Notifier<AsyncValue<List<RecurringExpense>>> {
  @override
  AsyncValue<List<RecurringExpense>> build() {
    Future.microtask(() => loadRecurring());
    return const AsyncValue.loading();
  }

  Future<void> loadRecurring() async {
    try {
      final api = ref.read(apiServiceProvider);
      final list = await api.getRecurringExpenses();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addRecurring(Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.createRecurring(data);
      await loadRecurring();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteRecurring(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteRecurring(id);
      await loadRecurring();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> generate(int month, int year) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.generateRecurring(month, year);
      await loadRecurring();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final recurringProvider = NotifierProvider<RecurringNotifier, AsyncValue<List<RecurringExpense>>>(RecurringNotifier.new);
