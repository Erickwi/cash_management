import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import 'api_provider.dart';

class CategoryNotifier extends Notifier<AsyncValue<List<Category>>> {
  @override
  AsyncValue<List<Category>> build() {
    Future.microtask(() => loadCategories());
    return const AsyncValue.loading();
  }

  Future<void> loadCategories() async {
    try {
      final api = ref.read(apiServiceProvider);
      final cats = await api.getCategories();
      state = AsyncValue.data(cats);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.createCategory(data);
      await loadCategories();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  List<Category> getExpenseCategories() {
    return state.value?.where((c) => c.type == 'expense').toList() ?? [];
  }

  List<Category> getIncomeCategories() {
    return state.value?.where((c) => c.type == 'income').toList() ?? [];
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>(CategoryNotifier.new);
