import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../data/models/transaction.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onToggleStatus,
    this.onDelete,
  });

  Color _statusColor() {
    return transaction.status == 'paid' ? AppColors.success : AppColors.pending;
  }

  String _statusLabel() {
    return transaction.status == 'paid' ? 'Pagado' : 'Pendiente';
  }

  IconData _typeIcon() {
    switch (transaction.type) {
      case 'income': return Icons.arrow_downward;
      case 'expense': return Icons.arrow_upward;
      case 'savings': return Icons.savings;
      case 'emergency': return Icons.warning_amber;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final date = DateFormat('dd/MM/yy').format(transaction.date);
    final hour = DateFormat('HH:mm').format(transaction.date);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(int.parse(
                    (transaction.categoryColor ?? '#78909C').replaceAll('#', '0xFF'))),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _typeIcon(),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description.isNotEmpty
                        ? transaction.description
                        : transaction.categoryName ?? transaction.type,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (transaction.categoryName != null) ...[
                        Text(
                          transaction.categoryName!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(' · ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                      Text(
                        '$date $hour',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(transaction.amount),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: transaction.type == 'income' ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onToggleStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
