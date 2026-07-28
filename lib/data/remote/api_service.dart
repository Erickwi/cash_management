import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/monthly_report.dart';
import '../models/recurring_expense.dart';
import '../models/room.dart';
import '../models/transaction.dart';

class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  Future<void> setBaseUrl(String url) => _client.setBaseUrl(url);

  Future<String> getBaseUrl() => _client.getBaseUrl();

  Future<RoomJoinResponse> createRoom(String alias) async {
    final res = await _client.post('/api/rooms', data: {'alias': alias});
    return RoomJoinResponse.fromJson(res.data);
  }

  Future<RoomJoinResponse> joinRoom(String code, String alias) async {
    final res = await _client.post('/api/rooms/join', data: {'code': code, 'alias': alias});
    return RoomJoinResponse.fromJson(res.data);
  }

  Future<List<Category>> getCategories() async {
    final res = await _client.get('/api/categories');
    return (res.data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    final res = await _client.post('/api/categories', data: data);
    return Category.fromJson(res.data);
  }

  Future<List<Transaction>> getTransactions({String? type, int? month, int? year, String? status}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    if (status != null) params['status'] = status;

    final res = await _client.get('/api/transactions', params: params);
    return (res.data as List).map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Transaction> createTransaction(Map<String, dynamic> data) async {
    final res = await _client.post('/api/transactions', data: data);
    return Transaction.fromJson(res.data);
  }

  Future<Transaction> updateTransaction(String id, Map<String, dynamic> data) async {
    final res = await _client.put('/api/transactions/$id', data: data);
    return Transaction.fromJson(res.data);
  }

  Future<void> updateTransactionStatus(String id, String status) async {
    await _client.patch('/api/transactions/$id/status', data: {'status': status});
  }

  Future<void> deleteTransaction(String id) async {
    await _client.delete('/api/transactions/$id');
  }

  Future<List<RecurringExpense>> getRecurringExpenses() async {
    final res = await _client.get('/api/recurring');
    return (res.data as List).map((e) => RecurringExpense.fromJson(e)).toList();
  }

  Future<RecurringExpense> createRecurring(Map<String, dynamic> data) async {
    final res = await _client.post('/api/recurring', data: data);
    return RecurringExpense.fromJson(res.data);
  }

  Future<void> deleteRecurring(String id) async {
    await _client.delete('/api/recurring/$id');
  }

  Future<Map<String, dynamic>> generateRecurring(int month, int year) async {
    final res = await _client.post('/api/recurring/generate', data: {'month': month, 'year': year});
    return res.data;
  }

  Future<MonthlyReport> getMonthlyReport(int month, int year) async {
    final res = await _client.get('/api/reports/monthly', params: {'month': month, 'year': year});
    return MonthlyReport.fromJson(res.data);
  }
}
