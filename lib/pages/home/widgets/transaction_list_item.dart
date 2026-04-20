import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/isar_expense.dart';

class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  final IsarExpense transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountColor =
        isIncome ? const Color(0xFF9EFFC8) : const Color(0xFFFF716C);
    final amountPrefix = isIncome ? '+ ₹' : '- ₹';
    final dateLabel = DateFormat('dd MMM').format(transaction.createdAt);

    return PopupMenuButton<String>(
      onSelected: (String result) {
        if (result == 'details') {
          // TODO: Implement Details
          print('Details for ${transaction.title}');
        } else if (result == 'edit') {
          // TODO: Implement Edit
          print('Edit ${transaction.title}');
        } else if (result == 'delete') {
          // TODO: Implement Delete
          print('Delete ${transaction.title}');
        }
      },
      color: const Color(0xFF192540),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF40485D).withValues(alpha: 0.5)),
      ),
      offset: const Offset(0, 45), // Drops down slightly below the tap area
      tooltip: 'Transaction options', // Removed default long-press tooltip
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFDEE5FF), size: 18),
              SizedBox(width: 12),
              Text(
                'Details',
                style: TextStyle(color: Color(0xFFDEE5FF), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Color(0xFFDEE5FF), size: 18),
              SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(color: Color(0xFFDEE5FF), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8), // Divider before destructive action
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Color(0xFFFF716C), size: 18),
              SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Color(0xFFFF716C), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
      // The child is our existing transaction container. Clicking it opens the menu.
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF060E20).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF192540),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                color: const Color(0xFF9EFFC8),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: Color(0xFFDEE5FF),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} • $dateLabel',
                    style: const TextStyle(
                      color: Color(0xFFA3AAC4),
                      fontSize: 10,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$amountPrefix${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

