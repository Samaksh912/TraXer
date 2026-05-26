import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
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
        isIncome ? context.appColors.income : context.appColors.expense;
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
      color: context.appColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.appColors.surface.withValues(alpha: 0.5)),
      ),
      offset: const Offset(0, 45), // Drops down slightly below the tap area
      tooltip: 'Transaction options', // Removed default long-press tooltip
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: context.appColors.primaryText, size: 18),
              SizedBox(width: 12),
              Text(
                'Details',
                style: TextStyle(color: context.appColors.primaryText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: context.appColors.primaryText, size: 18),
              SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(color: context.appColors.primaryText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8), // Divider before destructive action
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: context.appColors.expense, size: 18),
              SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: context.appColors.expense, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
      // The child is our existing transaction container. Clicking it opens the menu.
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: context.appColors.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                color: context.appColors.income,
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
                    style: TextStyle(
                      color: context.appColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} • $dateLabel',
                    style: TextStyle(
                      color: context.appColors.primaryText.withOpacity(0.7),
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

