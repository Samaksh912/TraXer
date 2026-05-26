import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/isar_expense.dart';

class AnalyticsPage extends StatefulWidget {
  final List<IsarExpense> transactions;

  const AnalyticsPage({super.key, required this.transactions});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _timeFilter = 'This Month'; // Options: This Week, This Month, This Year
  int _touchedPieIndex = -1;

  List<Color> _palette(BuildContext context) => [
    context.appColors.accent, // Blue
    context.appColors.accent, // Purple
    Color(0xFFFACC15), // Yellow
    context.appColors.income, // Mint Green
    context.appColors.expense, // Light Pink
    context.appColors.accent, // Teal
    context.appColors.expense, // Red
  ];

  // --- DATA PROCESSING LOGIC ---
  List<IsarExpense> get _filteredTx {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.transactions.where((tx) {
      if (_timeFilter == 'This Week') {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return tx.createdAt.isAfter(startOfWeek) || tx.createdAt.isAtSameMomentAs(startOfWeek);
      } else if (_timeFilter == 'This Month') {
        return tx.createdAt.year == now.year && tx.createdAt.month == now.month;
      } else {
        return tx.createdAt.year == now.year;
      }
    }).toList();
  }

  List<FlSpot> _getCashFlowSpots(TransactionType type) {
    final txs = _filteredTx.where((t) => t.type == type).toList();
    final Map<int, double> grouped = {};
    final now = DateTime.now();

    if (_timeFilter == 'This Week') {
      for (int i = 1; i <= 7; i++) {
        grouped[i] = 0;
      }
      for (var tx in txs) {
        grouped[tx.createdAt.weekday] = (grouped[tx.createdAt.weekday] ?? 0) + tx.amount;
      }
      return grouped.entries.map((e) => FlSpot(e.key.toDouble() - 1, e.value)).toList();
    } else if (_timeFilter == 'This Month') {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        grouped[i] = 0;
      }
      for (var tx in txs) {
        grouped[tx.createdAt.day] = (grouped[tx.createdAt.day] ?? 0) + tx.amount;
      }
      return grouped.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    } else {
      for (int i = 1; i <= 12; i++) {
        grouped[i] = 0;
      }
      for (var tx in txs) {
        grouped[tx.createdAt.month] = (grouped[tx.createdAt.month] ?? 0) + tx.amount;
      }
      return grouped.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    }
  }

  double get _totalIncome => _filteredTx
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _filteredTx
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  Map<String, double> get _categoryExpenses {
    final map = <String, double>{};
    for (var tx in _filteredTx.where((t) => t.type == TransactionType.expense)) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    // Sort by highest amount
    var sortedEntries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  @override
  void dispose() {
    _touchedPieIndex = -1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final txs = _filteredTx;
    final hasData = txs.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? context.appColors.background : context.appColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Analytics',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 26, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFilter(isDark),
            const SizedBox(height: 24),

            if (!hasData)
              _buildEmptyState(isDark)
            else ...[
              _buildOverviewCards(isDark, currFormat),
              const SizedBox(height: 32),

              _buildSectionHeader('Cash Flow', isDark),
              const SizedBox(height: 16),
              _buildCashFlowChart(isDark),

              const SizedBox(height: 32),

              _buildSectionHeader('Spending Breakdown', isDark),
              const SizedBox(height: 16),
              _buildDonutChart(isDark, currFormat),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions for this period',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the time filter or adding some expenses',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? context.appColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: ['This Week', 'This Month', 'This Year'].map((filter) {
          final isSelected = _timeFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF2C3E66) : const Color(0xFF2C3E50)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? context.appColors.primaryText.withOpacity(0.7) : Colors.grey.shade500),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCards(bool isDark, NumberFormat currFormat) {
    final netBalance = _totalIncome - _totalExpense;
    return Column(
      children: [
        // Net Balance (Large)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF2C3E50), context.appColors.primaryText]
                    : [Color(0xFF2C3E50), context.appColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF2C3E50)).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Net Balance', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                  Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withOpacity(0.5), size: 20),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    currFormat.format(netBalance),
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Income / Expense Split
        Row(
          children: [
            Expanded(child: _buildMiniCard('Income', _totalIncome, context.appColors.income, isDark, currFormat, Icons.keyboard_arrow_down_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniCard('Expense', _totalExpense, context.appColors.expense, isDark, currFormat, Icons.keyboard_arrow_up_rounded)),
          ],
        )
      ],
    );
  }

  Widget _buildMiniCard(String title, double amount, Color color, bool isDark, NumberFormat format, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? context.appColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isDark ? context.appColors.primaryText.withOpacity(0.7) : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            format.format(amount),
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(bool isDark) {
    final incomeSpots = _getCashFlowSpots(TransactionType.income);
    final expenseSpots = _getCashFlowSpots(TransactionType.expense);

    final maxAmount = [...incomeSpots, ...expenseSpots].fold(0.0, (max, spot) => spot.y > max ? spot.y : max);
    final interval = maxAmount > 0 ? (maxAmount / 5).ceilToDouble() : 1.0;

    return Container(
      height: 260,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? context.appColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF2C3E66) : Colors.white,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((barSpot) {
                  final flSpot = barSpot;
                  if (flSpot.barIndex == 0) {
                    return LineTooltipItem(
                      'Income: ₹${flSpot.y.toStringAsFixed(0)}',
                      TextStyle(color: context.appColors.income, fontWeight: FontWeight.bold),
                    );
                  } else {
                    return LineTooltipItem(
                      'Expense: ₹${flSpot.y.toStringAsFixed(0)}',
                      TextStyle(color: context.appColors.expense, fontWeight: FontWeight.bold),
                    );
                  }
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval > 0 ? interval : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), strokeWidth: 1, dashArray: [5, 5]),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _timeFilter == 'This Year' ? 3 : (_timeFilter == 'This Month' ? 7 : 1),
                getTitlesWidget: (value, meta) {
                  final style = TextStyle(color: context.appColors.primaryText.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10);
                  String text = '';
                  if (_timeFilter == 'This Week') {
                    switch (value.toInt()) {
                      case 0: text = 'Mon'; break;
                      case 2: text = 'Wed'; break;
                      case 4: text = 'Fri'; break;
                      case 6: text = 'Sun'; break;
                    }
                  } else if (_timeFilter == 'This Month') {
                    if (value == 1 || value == 10 || value == 20 || value == 30) {
                      text = value.toInt().toString();
                    }
                  } else {
                    switch (value.toInt()) {
                      case 1: text = 'Jan'; break;
                      case 4: text = 'Apr'; break;
                      case 7: text = 'Jul'; break;
                      case 10: text = 'Oct'; break;
                    }
                  }
                  return SideTitleWidget(meta: meta, child: Text(text, style: style));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Income Line
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: context.appColors.income,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [context.appColors.income.withOpacity(0.2), context.appColors.income.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Expense Line
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: context.appColors.expense,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [context.appColors.expense.withOpacity(0.2), context.appColors.expense.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChart(bool isDark, NumberFormat currFormat) {
    final categories = _categoryExpenses;

    if (categories.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text("No expenses to show", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      );
    }

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];

    categories.forEach((category, amount) {
      final isTouched = categories.keys.toList().indexOf(category) == _touchedPieIndex;
      final color = _palette(context)[colorIndex % _palette(context).length];
      final percentage = (amount / _totalExpense) * 100;

      // Build Chart Section
      sections.add(PieChartSectionData(
        color: color,
        value: amount,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 45.0 : 35.0, // Pop out effect on touch
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));

      // Build Legend Item
      legendItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        category,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)
                    )
                ),
                Text(
                    currFormat.format(amount),
                    style: TextStyle(color: isDark ? context.appColors.primaryText.withOpacity(0.7) : Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
      );

      colorIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? context.appColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (event is! FlTapUpEvent || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          // Toggle logic: tapping the same section deselects it, tapping a different section selects it
                          if (_touchedPieIndex == touchedIndex) {
                            _touchedPieIndex = -1; // Deselect if same section is tapped again
                          } else {
                            _touchedPieIndex = touchedIndex; // Select the new section
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4, // Spacing between donut slices
                    centerSpaceRadius: 60, // Hollow center for donut effect
                    sections: sections,
                  ),
                ),
                // Center Label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: TextStyle(color: isDark ? context.appColors.primaryText.withOpacity(0.7) : Colors.black54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      currFormat.format(_totalExpense),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                    )
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Legend List
          ...legendItems,
        ],
      ),
    );
  }
}