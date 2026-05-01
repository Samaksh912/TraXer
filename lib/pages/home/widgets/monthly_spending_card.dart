import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../models/isar_expense.dart';
import '../../../../providers/app_providers.dart';
import 'expand_from_point.dart';
import 'expense_detail_overlay.dart';
class MonthlySpendingCard extends ConsumerStatefulWidget {
  final List<IsarExpense> transactions;

  const MonthlySpendingCard({super.key, required this.transactions});

  // Pre-defined color palette for categories
  static const List<Color> _palette = [
    Color(0xFF1DFBA5), // Mint Green
    Color(0xFF874CFF), // Purple
    Color(0xFFFB1D55), // Red
    Color(0xFF5B8EFF), // Blue
    Color(0xFFFF9E9E), // Light Pink
    Color(0xFFFACC15), // Yellow
    Color(0xFF2DD4BF), // Teal
  ];

  @override
  ConsumerState<MonthlySpendingCard> createState() => _MonthlySpendingCardState();
}

class _MonthlySpendingCardState extends ConsumerState<MonthlySpendingCard> {
  int _touchedIndex = -1;
  Offset? _touchOffset; // Tracks exactly where the user tapped

  Map<String, Color> _assignColors(List<IsarExpense> transactions) {
    final categoryColors = <String, Color>{};
    int colorIndex = 0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.expense && !categoryColors.containsKey(tx.category)) {
        categoryColors[tx.category] = MonthlySpendingCard._palette[colorIndex % MonthlySpendingCard._palette.length];
        colorIndex++;
      }
    }
    var sortedKeys = categoryColors.keys.toList()..sort();
    var newMap = <String, Color>{};
    for (var k in sortedKeys) {
      newMap[k] = categoryColors[k]!;
    }
    return newMap;
  }

  @override
  Widget build(BuildContext context) {
    final isDailyView = ref.watch(monthlySpendingViewProvider);
    final categoryColors = _assignColors(widget.transactions);

    final now = DateTime.now();
    final expenses = widget.transactions.where((t) => t.type == TransactionType.expense).toList();

    double totalSpent = 0;

    int numIntervals = isDailyView ? 7 : 6;
    List<String> xLabels = [];
    List<Map<String, double>> groupedData = List.generate(numIntervals, (_) => {});

    // Declare these here so the onTap function can see them!
    final startDay = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final startMonth = DateTime(now.year, now.month - 5);


    if (isDailyView) {
      final startDay = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      for (int i = 0; i < 7; i++) {
        final d = startDay.add(Duration(days: i));
        xLabels.add(DateFormat('E').format(d));
      }
      for (var tx in expenses) {
        final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
        final diff = txDate.difference(startDay).inDays;
        if (diff >= 0 && diff < 7) {
          groupedData[diff][tx.category] = (groupedData[diff][tx.category] ?? 0) + tx.amount;
          totalSpent += tx.amount;
        }
      }
    } else {
      final startMonth = DateTime(now.year, now.month - 5);
      for (int i = 0; i < 6; i++) {
        final m = DateTime(startMonth.year, startMonth.month + i);
        xLabels.add(DateFormat('MMM').format(m));
      }
      for (var tx in expenses) {
        final txMonth = DateTime(tx.createdAt.year, tx.createdAt.month);
        int monthsDiff = (txMonth.year - startMonth.year) * 12 + txMonth.month - startMonth.month;
        if (monthsDiff >= 0 && monthsDiff < 6) {
          groupedData[monthsDiff][tx.category] = (groupedData[monthsDiff][tx.category] ?? 0) + tx.amount;
          totalSpent += tx.amount;
        }
      }
    }

    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    double maxY = 0;
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < numIntervals; i++) {
      List<BarChartRodStackItem> stackItems = [];
      final categoriesInInterval = groupedData[i].keys.toList()..sort();

      double currentStackY = 0;
      for (var category in categoriesInInterval) {
        double val = groupedData[i][category]!;
        if (val > 0) {
          stackItems.add(BarChartRodStackItem(currentStackY, currentStackY + val, categoryColors[category] ?? Colors.grey));
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
              borderRadius: BorderRadius.circular(4),
              rodStackItems: stackItems,
              color: Colors.transparent,
            ),
          ],
        ),
      );
    }

    maxY = maxY > 0 ? maxY * 1.2 : 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- YOUR EXACT SPENDING ANALYSIS HEADER & TOGGLE ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SPENDING ANALYSIS',
              style: TextStyle(color: Color(0xFFA3AAC4), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF192540).withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF40485D).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(monthlySpendingViewProvider.notifier).state = true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDailyView ? const Color(0xFF40485D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Days', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDailyView ? Colors.white : const Color(0xFFA3AAC4))),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(monthlySpendingViewProvider.notifier).state = false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: !isDailyView ? const Color(0xFF40485D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Months', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: !isDailyView ? Colors.white : const Color(0xFFA3AAC4))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(currFormat.format(totalSpent), style: const TextStyle(color: Color(0xFFDEE5FF), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        Text(isDailyView ? 'Spent in last 7 days' : 'Spent in last 6 months', style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 10)),
        const SizedBox(height: 24),

        // --- THE CHART WITH OVERLAY LOGIC ---
        // --- THE CHART WITH STRICTLY CLAMPED OVERLAY ---
        SizedBox(
          height: 150,
          child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Builder(
                        builder: (chartContext) {
                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                                ),
                                touchCallback: (FlTouchEvent event, barTouchResponse) {
                                  if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                    return;
                                  }
                                  setState(() {
                                    _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                    _touchOffset = barTouchResponse.spot!.offset;
                                  });
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    getTitlesWidget: (double value, _) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(xLabels[value.toInt()], style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxY / 4,
                                getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFF40485D).withOpacity(0.2), strokeWidth: 1, dashArray: [4, 4]),
                              ),
                              barGroups: barGroups,
                            ),
                          );
                        }
                    ),

                    // The simple, perfectly clickable "Show Details" Button
                    if (_touchedIndex != -1 && _touchOffset != null)
                      Positioned(
                        // STRICT CLAMPING: Button is ~100px wide and ~35px tall.
                        // This math guarantees it never leaves the 150px height or the width of the screen.
                        left: (_touchOffset!.dx - 50).clamp(0.0, constraints.maxWidth - 100),
                        top: (_touchOffset!.dy - 45).clamp(0.0, constraints.maxHeight - 35),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              // 1. Get the exact global coordinates of the button
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              final Offset globalPos = box.localToGlobal(_touchOffset!);

                              // 2. Fetch the specific data for the bar that was tapped
                              final selectedTx = widget.transactions.where((tx) {
                                if (tx.type != TransactionType.expense) return false;
                                if (isDailyView) {
                                  final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
                                  final diff = txDate.difference(startDay).inDays;
                                  return diff == _touchedIndex;
                                } else {
                                  final txMonth = DateTime(tx.createdAt.year, tx.createdAt.month);
                                  int monthsDiff = (txMonth.year - startMonth.year) * 12 + txMonth.month - startMonth.month;
                                  return monthsDiff == _touchedIndex;
                                }
                              }).toList();

                              final label = xLabels[_touchedIndex];

                              // 3. Push the custom route
                              Navigator.of(context).push(
                                  ExpandFromPointRoute(
                                    tapPosition: globalPos,
                                    page: ExpenseDetailOverlay(
                                      transactions: selectedTx,
                                      categoryColors: categoryColors,
                                      intervalLabel: label,
                                    ),
                                  )
                              );

                              // 4. Reset the chart state
                              setState(() => _touchedIndex = -1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B8EFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                  'Show Details',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
          ),
        ),
        const SizedBox(height: 16),
        // --- YOUR EXACT LEGEND WRAP ---
        if (categoryColors.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categoryColors.entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(e.key, style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}