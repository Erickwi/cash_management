import 'transaction.dart';

class MonthlyReport {
  final String month;
  final String year;
  final List<String> members;
  final Summary summary;
  final List<Transaction> incomes;
  final List<Transaction> expenses;
  final List<ExpenseByCategory> expenseByCategory;

  MonthlyReport({
    required this.month,
    required this.year,
    required this.members,
    required this.summary,
    required this.incomes,
    required this.expenses,
    required this.expenseByCategory,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) => MonthlyReport(
    month: json['month'].toString(),
    year: json['year'].toString(),
    members: (json['members'] as List).cast<String>(),
    summary: Summary.fromJson(json['summary']),
    incomes: (json['incomes'] as List).map((e) => Transaction.fromJson(e)).toList(),
    expenses: (json['expenses'] as List).map((e) => Transaction.fromJson(e)).toList(),
    expenseByCategory: (json['expense_by_category'] as List)
        .map((e) => ExpenseByCategory.fromJson(e))
        .toList(),
  );
}

class Summary {
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final double totalEmergency;
  final double balance;

  Summary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.totalEmergency,
    required this.balance,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    totalIncome: double.parse(json['total_income'].toString()),
    totalExpenses: double.parse(json['total_expenses'].toString()),
    totalSavings: double.parse(json['total_savings'].toString()),
    totalEmergency: double.parse(json['total_emergency'].toString()),
    balance: double.parse(json['balance'].toString()),
  );
}
