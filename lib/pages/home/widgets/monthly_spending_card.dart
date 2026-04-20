import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../models/isar_expense.dart';
import '../../../../providers/app_providers.dart';

class MonthlySpendingCard extends ConsumerWidget {
  final List<IsarExpense> transactions;

  const MonthlySpendingCard({super.key, required this.transactions});

  // Pre-defined color palette for categories
  static const List<Color> _palette = [
    const Color(0xFF1DFBA5), // Mint Green
    const Color(0xFF874CFF), // Purple
    const Color(0xFFFB1D55), // Red
    const Color(0xFF5B8EFF), // Blue
    const Color(0xFFFF9E9E), // Light Pink
    const Color(0xFFFACC15), // Yellow
    const Color(0xFF2DD4BF), // Teal
  ];

  Map<String, Color> _assignColors(List<IsarExpense> transactions) {
    final categoryColors = <String, Color>{};
    int colorIndex = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense &&
          !categoryColors.containsKey(tx.category)) {
        categoryColors[tx.category] = _palette[colorIndex % _palette.length];
        colorIndex++;
      }
    }
    // Sort categories alphabetically to keep legend stable
    var sortedKeys = categoryColors.keys.toList()..sort();
    var newMap = <String, Color>{};
    for (var k in sortedKeys) {
      newMap[k] = categoryColors[k]!;
    }
    return newMap;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDailyView = ref.watch(monthlySpendingViewProvider);
    final categoryColors = _assignColors(transactions);

    final now = DateTime.now();
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    double totalSpent = 0;

    // Determine the time intervals and labels
    int numIntervals = isDailyView ? 7 : 6;
    List<String> xLabels = [];

    // Group totals: intervalIndex -> { category -> amount }
    List<Map<String, double>> groupedData = List.generate(
      numIntervals,
      (_) => {},
    );

    if (isDailyView) {
      // Last 7 days, ending today
      final startDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      for (int i = 0; i < 7; i++) {
        final d = startDay.add(Duration(days: i));
        xLabels.add(DateFormat('E').format(d)); // 'Mon', 'Tue'
      }

      for (var tx in expenses) {
        final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
        final diff = txDate.difference(startDay).inDays;
        if (diff >= 0 && diff < 7) {
          groupedData[diff][tx.category] =
              (groupedData[diff][tx.category] ?? 0) + tx.amount;
          totalSpent += tx.amount;
        }
      }
    } else {
      // Last 6 months
      final startMonth = DateTime(now.year, now.month - 5);

      for (int i = 0; i < 6; i++) {
        final m = DateTime(startMonth.year, startMonth.month + i);
        xLabels.add(DateFormat('MMM').format(m)); // 'Jan', 'Feb'
      }

      for (var tx in expenses) {
        final txMonth = DateTime(tx.createdAt.year, tx.createdAt.month);
        // difference in months
        int monthsDiff =
            (txMonth.year - startMonth.year) * 12 +
            txMonth.month -
            startMonth.month;
        if (monthsDiff >= 0 && monthsDiff < 6) {
          groupedData[monthsDiff][tx.category] =
              (groupedData[monthsDiff][tx.category] ?? 0) + tx.amount;
          totalSpent += tx.amount;
        }
      }
    }

    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    // Build bar groups
    double maxY = 0;
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < numIntervals; i++) {
      List<BarChartRodStackItem> stackItems = [];

      final categoriesInInterval = groupedData[i].keys.toList();
      categoriesInInterval.sort(); // Sort to keep stack order consistent

      double currentStackY = 0;
      for (var category in categoriesInInterval) {
        double val = groupedData[i][category]!;
        if (val > 0) {
          stackItems.add(
            BarChartRodStackItem(
              currentStackY,
              currentStackY + val,
                categoryColors[category] ?? Colors.grey,
            ),
          );
          currentStackY += val;
        }
      }

      if (currentStackY > maxY) maxY = currentStackY;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: currentStackY,
              width: 16,
              borderRadius: BorderRadius.circular(4), // Rounded top
              rodStackItems: stackItems,
              color: Colors.transparent,
            ),
          ],
        ),
      );
    }

    // Add padding to maxY for chart breathing room
    maxY = maxY > 0 ? maxY * 1.2 : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SPENDING ANALYSIS',
              style: TextStyle(
                color: Color(0xFFA3AAC4),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Toggle
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF192540).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF40485D).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(monthlySpendingViewProvider.notifier).state = true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDailyView
                            ? const Color(0xFF40485D)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Days',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDailyView
                              ? Colors.white
                              : const Color(0xFFA3AAC4),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(monthlySpendingViewProvider.notifier).state = false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: !isDailyView
                            ? const Color(0xFF40485D)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Months',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: !isDailyView
                              ? Colors.white
                              : const Color(0xFFA3AAC4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          currFormat.format(totalSpent),
          style: const TextStyle(
            color: Color(0xFFDEE5FF),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          isDailyView ? 'Spent in last 7 days' : 'Spent in last 6 months',
          style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 10),
        ),
        const SizedBox(height: 24),
        // Chart
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (double value, _) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          xLabels[value.toInt()],
                          style: const TextStyle(
                            color: Color(0xFFA3AAC4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFF40485D).withValues(alpha: 0.2),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Legend
        if (categoryColors.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categoryColors.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: e.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    e.key,
                    style: const TextStyle(
                      color: Color(0xFFA3AAC4),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
