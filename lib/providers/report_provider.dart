import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/monthly_report.dart';
import 'api_provider.dart';

class ReportNotifier extends Notifier<AsyncValue<MonthlyReport?>> {
  @override
  AsyncValue<MonthlyReport?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> loadReport(int month, int year) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      final report = await api.getMonthlyReport(month, year);
      state = AsyncValue.data(report);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final reportProvider = NotifierProvider<ReportNotifier, AsyncValue<MonthlyReport?>>(ReportNotifier.new);
