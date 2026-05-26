import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../../../models/isar_expense.dart';

class ExpenseCard extends StatelessWidget {
  final List<IsarExpense> transactions;

  const ExpenseCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double todayExpense = 0;
    double weekExpense = 0;
    double weekIncome = 0;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Assuming week starts on Monday (now.weekday is 1 for Mon, 7 for Sun)
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    for (var tx in transactions) {
      bool isToday = tx.createdAt.year == now.year &&
                     tx.createdAt.month == now.month &&
                     tx.createdAt.day == now.day;
      
      bool isThisWeek = tx.createdAt.isAfter(startOfWeek) ||
                        (tx.createdAt.year == startOfWeek.year &&
                         tx.createdAt.month == startOfWeek.month &&
                         tx.createdAt.day == startOfWeek.day);

      if (tx.type == TransactionType.expense) {
        if (isToday) todayExpense += tx.amount;
        if (isThisWeek) weekExpense += tx.amount;
      } else if (tx.type == TransactionType.income) {
        if (isThisWeek) weekIncome += tx.amount;
      }
    }

    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TODAY'S EXPENDITURE",
          style: TextStyle(
            color: context.appColors.primaryText.withOpacity(0.7),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currFormat.format(todayExpense),
          style: TextStyle(
            color: context.appColors.primaryText,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.appColors.surface.withValues(alpha: 0.4),
            border: Border.all(color: context.appColors.surface.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // This Week's Expenditure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, color: context.appColors.expense, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "This Week's Exp",
                        style: TextStyle(
                          color: context.appColors.primaryText.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currFormat.format(weekExpense),
                    style: TextStyle(
                      color: context.appColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Divider
              Container(
                height: 30,
                width: 1,
                color: context.appColors.surface.withValues(alpha: 0.5),
              ),
              // This Week's Income
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, color: context.appColors.income, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "This Week's Inc",
                        style: TextStyle(
                          color: context.appColors.primaryText.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currFormat.format(weekIncome),
                    style: TextStyle(
                      color: context.appColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
