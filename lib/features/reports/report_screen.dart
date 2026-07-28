import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/monthly_report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/pie_chart_widget.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reportProvider.notifier).loadReport(_selectedMonth, _selectedYear));
  }

  void _loadReport() {
    ref.read(reportProvider.notifier).loadReport(_selectedMonth, _selectedYear);
  }

  Future<void> _generatePdf(MonthlyReport report) async {
    final pdf = pw.Document();
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cash Management',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF1565C0),
                  )),
              pw.Text(
                '$_selectedMonth/$_selectedYear',
                style: const pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xFF6B7280)),
              ),
            ],
          ),
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text('Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF9CA3AF))),
        ),
        build: (ctx) => [
          pw.Paragraph(text: 'Miembros: ${report.members.join(', ')}'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Resumen Mensual'),
          _summaryTable(currencyFmt, report.summary),
          pw.SizedBox(height: 20),
          if (report.incomes.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Ingresos'),
            _transactionTable(currencyFmt, report.incomes),
            pw.SizedBox(height: 16),
          ],
          if (report.expenses.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Gastos'),
            _expenseTable(currencyFmt, report.expenses),
            pw.SizedBox(height: 16),
          ],
          if (report.expenseByCategory.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Gastos por Categoria'),
            _categoryTable(currencyFmt, report.expenseByCategory),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reporte_$_selectedMonth$_selectedYear.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Reporte Cash Management $_selectedMonth/$_selectedYear'),
    );
  }

  pw.Widget _summaryTable(NumberFormat fmt, Summary summary) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFFFFFFF)),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1565C0)),
      headers: ['Concepto', 'Monto'],
      data: [
        ['Ingresos', fmt.format(summary.totalIncome)],
        ['Gastos', fmt.format(summary.totalExpenses)],
        ['Ahorros', fmt.format(summary.totalSavings)],
        ['Emergencia', fmt.format(summary.totalEmergency)],
        ['Balance', fmt.format(summary.balance)],
      ],
      columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1)},
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB)),
      ),
    );
  }

  pw.Widget _transactionTable(NumberFormat fmt, List list) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFFFFFFF)),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7B1FA2)),
      headers: ['Descripcion', 'Fecha', 'Monto'],
      data: list.map((t) => [
        t.description.isNotEmpty ? t.description : (t.categoryName ?? ''),
        DateFormat('dd/MM/yy').format(t.date),
        fmt.format(t.amount),
      ]).toList(),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB)),
      ),
    );
  }

  pw.Widget _expenseTable(NumberFormat fmt, List list) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFFFFFFF)),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7B1FA2)),
      headers: ['Categoria', 'Descripcion', 'Fecha', 'Monto', 'Estado'],
      data: list.map((t) => [
        t.categoryName ?? '',
        t.description.isNotEmpty ? t.description : '-',
        DateFormat('dd/MM/yy').format(t.date),
        fmt.format(t.amount),
        t.status == 'paid' ? 'Pagado' : 'Pendiente',
      ]).toList(),
      columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(1)},
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB)),
      ),
    );
  }

  pw.Widget _categoryTable(NumberFormat fmt, List list) {
    final total = list.fold<double>(0, (s, e) => s + e.total);
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFFFFFFF)),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1565C0)),
      headers: ['Categoria', 'Total', '%'],
      data: list.map((e) {
        final pct = (e.total / total * 100).toStringAsFixed(1);
        return [e.name, fmt.format(e.total), '$pct%'];
      }).toList(),
      columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              final report = reportAsync.value;
              if (report != null) _generatePdf(report);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 1) {
                          _selectedMonth = 12;
                          _selectedYear--;
                        } else {
                          _selectedMonth--;
                        }
                      });
                      _loadReport();
                    },
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedMonth == 12) {
                          _selectedMonth = 1;
                          _selectedYear++;
                        } else {
                          _selectedMonth++;
                        }
                      });
                      _loadReport();
                    },
                    label: const Text('Siguiente'),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (report) {
                if (report == null) {
                  return const Center(child: Text('Selecciona un mes'));
                }
                final hasNoData = report.incomes.isEmpty && report.expenses.isEmpty && report.summary.totalIncome == 0 && report.summary.totalExpenses == 0;
                if (hasNoData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No hay datos para este mes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Agrega ingresos y gastos para ver el reporte',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('Resumen', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              _SummaryRow('Ingresos', report.summary.totalIncome, AppColors.success),
                              _SummaryRow('Gastos', report.summary.totalExpenses, AppColors.pending),
                              _SummaryRow('Ahorros', report.summary.totalSavings, AppColors.blue),
                              _SummaryRow('Emergencia', report.summary.totalEmergency, AppColors.purple),
                              const Divider(),
                              _SummaryRow('Balance', report.summary.balance, AppColors.textPrimary, bold: true),
                            ],
                          ),
                        ),
                      ),
                      if (report.expenseByCategory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('Gastos por Categoria', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 16),
                                PieChartWidget(data: report.expenseByCategory),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;

  const _SummaryRow(this.label, this.amount, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          )),
          Text(currency.format(amount), style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          )),
        ],
      ),
    );
  }
}
