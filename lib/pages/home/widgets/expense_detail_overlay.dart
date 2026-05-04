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
  late Animation<double> _lineDrawAnimation;
  late ScrollController _scrollController; // Added to track scrolling

  late Map<String, List<IsarExpense>> groupedTx;
  late double totalAmount;
  late List<String> categories;

  final List<GlobalKey> _leftKeys = [];
  final List<GlobalKey> _rightKeys = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scrollController = ScrollController(); // Initialize scroll controller

    _barGrowthAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutQuart)
    );

    _lineDrawAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeInOutCubic)
    );

    groupedTx = {};
    totalAmount = 0;
    for (var tx in widget.transactions) {
      groupedTx.putIfAbsent(tx.category, () => []).add(tx);
      totalAmount += tx.amount;
    }

    categories = groupedTx.keys.toList()..sort();
    categories = categories.reversed.toList();

    for (int i = 0; i < categories.length; i++) {
      _leftKeys.add(GlobalKey());
      _rightKeys.add(GlobalKey());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); // Don't forget to dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Invisible tap detector to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // 2. Dynamic Connecting Lines with Scroll Tracking & Fade Mask
          AnimatedBuilder(
            // SMART FIX: Listen to BOTH the animation AND the scroll view!
            animation: Listenable.merge([_controller, _scrollController]),
            builder: (context, child) {
              if (_lineDrawAnimation.value == 0.0) return const SizedBox.shrink();

              final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
              if (overlayBox == null) return const SizedBox.shrink();

              final List<Offset> starts = [];
              final List<Offset> ends = [];
              final List<Color> activeColors = [];

              for (int i = 0; i < categories.length; i++) {
                final leftContext = _leftKeys[i].currentContext;
                final rightContext = _rightKeys[i].currentContext;

                if (leftContext != null && rightContext != null) {
                  final leftBox = leftContext.findRenderObject() as RenderBox;
                  final rightBox = rightContext.findRenderObject() as RenderBox;

                  starts.add(leftBox.localToGlobal(Offset(leftBox.size.width, leftBox.size.height / 2), ancestor: overlayBox));
                  ends.add(rightBox.localToGlobal(Offset(0, rightBox.size.height / 2), ancestor: overlayBox));
                  activeColors.add(widget.categoryColors[categories[i]] ?? Colors.grey);
                }
              }

              if (starts.isEmpty) return const SizedBox.shrink();

              // SMART FIX: ShaderMask smoothly fades the lines out at the top and bottom of the screen
              return ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                    stops: [0.05, 0.2, 0.8, 1.0], // Fades the top 20% and bottom 20%
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: ConnectionLinePainter(
                    progress: _lineDrawAnimation.value,
                    startPoints: starts,
                    endPoints: ends,
                    colors: activeColors,
                  ),
                ),
              );
            },
          ),

          // 3. Main Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // --- LEFT SIDE: Expanded Bar ---
                  AnimatedBuilder(
                    animation: _barGrowthAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 20,
                        height: MediaQuery.of(context).size.height * 0.65 * _barGrowthAnimation.value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF192540).withOpacity(0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: categories.asMap().entries.map((entry) {
                            int index = entry.key;
                            String cat = entry.value;

                            double catTotal = groupedTx[cat]!.fold(0.0, (sum, tx) => sum + tx.amount);
                            double percentage = catTotal / totalAmount;

                            return Container(
                              key: _leftKeys[index],
                              height: (MediaQuery.of(context).size.height * 0.65 * _barGrowthAnimation.value) * percentage,
                              width: 20,
                              color: widget.categoryColors[cat] ?? Colors.grey,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 36),

                  // --- RIGHT SIDE: Detail Cards ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.intervalLabel,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total: ${currFormat.format(totalAmount)}',
                                  style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Color(0xFFA3AAC4), size: 24),
                              onPressed: () => Navigator.of(context).pop(),
                            )
                          ],
                        ),
                        const SizedBox(height: 28),

                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController, // Attach the scroll controller here
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: categories.asMap().entries.map((entry) {
                                int index = entry.key;
                                String cat = entry.value;
                                final txList = groupedTx[cat]!;
                                final catColor = widget.categoryColors[cat] ?? Colors.grey;

                                final start = 0.55 + ((index / categories.length) * 0.25);
                                final end = (start + 0.2).clamp(0.0, 1.0);

                                final curvedAnimation = CurvedAnimation(
                                  parent: _controller,
                                  curve: Interval(start, end, curve: Curves.easeOutQuart),
                                );

                                final slideAnimation = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(curvedAnimation);
                                final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

                                return Container(
                                  key: _rightKeys[index],
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: SlideTransition(
                                    position: slideAnimation,
                                    child: FadeTransition(
                                      opacity: fadeAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF121A2F).withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: catColor.withOpacity(0.15), width: 1),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 1. SMART CARD HEADER: Category Name, Dot, and Category Subtotal
                                            Row(
                                              children: [
                                                Container(
                                                  width: 10, height: 10,
                                                  decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                    cat, // The Category Name (e.g., "Shopping") only appears once per card!
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)
                                                ),
                                                const Spacer(),
                                                // Smart Addition: Show the total spent just in this category
                                                Text(
                                                    currFormat.format(txList.fold(0.0, (sum, item) => sum + item.amount)),
                                                    style: const TextStyle(color: Color(0xFFA3AAC4), fontSize: 13, fontWeight: FontWeight.w600)
                                                ),
                                              ],
                                            ),

                                            // 2. SUBTLE DIVIDER: Separates the category header from the items
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                                              child: Container(height: 1, color: catColor.withOpacity(0.15)),
                                            ),

                                            // 3. THE CLEAN LIST: Only titles and amounts, no redundant text
                                            ...txList.asMap().entries.map((txEntry) {
                                              int txIndex = txEntry.key;
                                              var tx = txEntry.value;

                                              return Padding(
                                                padding: EdgeInsets.only(bottom: txIndex == txList.length - 1 ? 0 : 12.0),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        tx.title,
                                                        style: const TextStyle(color: Color(0xFFDEE5FF), fontSize: 14, fontWeight: FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                        currFormat.format(tx.amount),
                                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionLinePainter extends CustomPainter {
  final double progress;
  final List<Offset> startPoints;
  final List<Offset> endPoints;
  final List<Color> colors;

  ConnectionLinePainter({
    required this.progress,
    required this.startPoints,
    required this.endPoints,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    for (int i = 0; i < startPoints.length; i++) {
      final start = startPoints[i];
      final end = endPoints[i];
      final color = colors[i];

      final path = Path();
      path.moveTo(start.dx, start.dy);

      final ctrl1 = Offset(start.dx + 30, start.dy);
      final ctrl2 = Offset(end.dx - 30, end.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, end.dx, end.dy);

      final pathMetrics = path.computeMetrics().first;
      final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);

      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(extractPath, paint);

      if (progress > 0.0 && progress < 1.0) {
        final currentPosition = pathMetrics.getTangentForOffset(pathMetrics.length * progress)?.position;
        if (currentPosition != null) {
          canvas.drawCircle(
              currentPosition,
              2.0,
              Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5)
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionLinePainter oldDelegate) {
    // Because we are triggering repaints on scroll, we must ALWAYS return true so the lines update!
    return true;
  }
}
