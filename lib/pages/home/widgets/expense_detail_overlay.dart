import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/isar_expense.dart';

class ExpenseDetailOverlay extends StatefulWidget {
  final List<IsarExpense> transactions;
  final Map<String, Color> categoryColors;
  final String intervalLabel;

  const ExpenseDetailOverlay({
    super.key,
    required this.transactions,
    required this.categoryColors,
    required this.intervalLabel,
  });

  @override
  State<ExpenseDetailOverlay> createState() => _ExpenseDetailOverlayState();
}

class _ExpenseDetailOverlayState extends State<ExpenseDetailOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barGrowthAnimation;

  // Group transactions by category for the detail view
  late Map<String, List<IsarExpense>> groupedTx;
  late double totalAmount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _barGrowthAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    groupedTx = {};
    totalAmount = 0;
    for (var tx in widget.transactions) {
      groupedTx.putIfAbsent(tx.category, () => []).add(tx);
      totalAmount += tx.amount;
    }

    // Start animation immediately upon loading the overlay
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');
    final categories = groupedTx.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. The Blur Background
          GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Tap outside to dismiss
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: const Color(0xFF0D1424).withOpacity(0.6), // Dark tint
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2. The Expanding Stacked Bar (Left Side)
                  AnimatedBuilder(
                    animation: _barGrowthAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 40,
                        height: MediaQuery.of(context).size.height * 0.7 * _barGrowthAnimation.value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFF192540),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: categories.map((cat) {
                            double catTotal = groupedTx[cat]!.fold(0.0, (sum, tx) => sum + tx.amount);
                            double percentage = catTotal / totalAmount;
                            return Container(
                              height: (MediaQuery.of(context).size.height * 0.7 * _barGrowthAnimation.value) * percentage,
                              width: 40,
                              color: widget.categoryColors[cat] ?? Colors.grey,
                            );
                          }).toList().reversed.toList(), // Reverse so bottom logic matches chart
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 24),

                  // 3. The Details List (Right Side)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.intervalLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        ),
                        Text(
                          'Total: ${currFormat.format(totalAmount)}',
                          style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 16),
                        ),
                        const SizedBox(height: 24),

                        // Staggered Category List
// Staggered Category List
                        Expanded(
                          child: ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final txList = groupedTx[cat]!;
                              final catColor = widget.categoryColors[cat] ?? Colors.grey;

                              // Calculate stagger interval for this specific item
                              final start = (index / categories.length) * 0.5;
                              final end = start + 0.5;

                              // 1. Create the base curved animation (this is an Animation<double>)
                              final curvedAnimation = CurvedAnimation(
                                parent: _controller,
                                curve: Interval(start, end, curve: Curves.easeOutCubic),
                              );

                              // 2. Drive the Slide (Offset) off the curved animation
                              final slideAnimation = Tween<Offset>(
                                  begin: const Offset(0.5, 0),
                                  end: Offset.zero
                              ).animate(curvedAnimation);

                              // 3. Drive the Fade (double) off the SAME curved animation
                              final fadeAnimation = Tween<double>(
                                  begin: 0.0,
                                  end: 1.0
                              ).animate(curvedAnimation);

                              return SlideTransition(
                                position: slideAnimation,
                                child: FadeTransition(
                                  opacity: fadeAnimation, // Use the corrected fadeAnimation here
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF192540).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: catColor.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(radius: 6, backgroundColor: catColor),
                                            const SizedBox(width: 8),
                                            Text(
                                                cat,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ...txList.map((tx) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(tx.category, style: const TextStyle(color: Color(0xFFA3AAC4))),
                                              Text(currFormat.format(tx.amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}