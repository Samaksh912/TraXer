import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:traxer/pages/settings.dart';

import '../components/expensedialog.dart';
import '../components/navbar.dart';
import '../components/expandable_fab.dart';
import '../main.dart';
import '../models/isarexpense.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isNavBarVisible = true;
  bool _isListening = false;
  final String _listeningText = "Say 'Add 40 rupees for chips'...";
  Future<void> _addNewExpense(IsarExpense newExpense) async {
    await isar.writeTxn(() async {
      await isar.isarExpenses.put(newExpense); // Put saves (insert or update)
    });

    _loadExpenses(); // Refresh the list UI
  }

  // Function to open the dialog
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddExpenseDialog(onAddExpense: _addNewExpense),
    );
  }
  List<IsarExpense> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    // Fetch all expenses, sorted by date (newest first)
    final expenses = await isar.isarExpenses.where()
        .sortByDateDesc()
        .findAll();

    setState(() {
      _recentTransactions = expenses;
    });
  }
  void _startListening() {
    setState(() {
      _isListening = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Added: 40 Rupees for Chips"),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1DFBA5).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF874CFF).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF40485D).withOpacity(0.3)),
                              image: const DecorationImage(
                                image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuCMa9MlXowKW3yW4mVI5HrKq3Isaxiy5dV86De3ubGy53ihw60STZSNUIO9TU55opa0HpVZp_KimCc99OcYsEUkVTwwg6nQjS_izDl-uHJIMms0eAnY__MC53WqSI9gQz-7M5Lbv_AgsLCyjoPVIPo_IBcs4q5vIyygbBLfVIqspn0c-4dQY2RY3XDmkUi93JmxhD-JT9zWN7HOAQlElm9t_zglmh2UUo-dQloz6cR41wgPd1oNHMX4fm64Mz9-lbI8ukT-5AVm9Q"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "EXPNSE",
                            style: TextStyle(
                              color: Color(0xFF9EFFC8),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.notifications_outlined, color: Color(0xFF9EFFC8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Total Balance Card
                  _buildGlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TOTAL BALANCE",
                          style: TextStyle(
                            color: Color(0xFFA3AAC4),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "₹ 24,500.00",
                          style: TextStyle(
                            color: Color(0xFFDEE5FF),
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9EFFC8), Color(0xFF1DFBA5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1DFBA5).withOpacity(0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Add Funds",
                                style: TextStyle(
                                  color: Color(0xFF00452A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF192540).withOpacity(0.4),
                                border: Border.all(color: const Color(0xFF40485D).withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                "Transfer",
                                style: TextStyle(
                                  color: Color(0xFFDEE5FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Monthly Spending Card
                  _buildGlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "MONTHLY SPENDING",
                              style: TextStyle(
                                color: Color(0xFFA3AAC4),
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.insights, color: Color(0xFFA3AAC4), size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "₹ 20,500.00",
                          style: TextStyle(
                            color: Color(0xFFDEE5FF),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          "of ₹ 40,000 budget",
                          style: TextStyle(
                            color: Color(0xFFA3AAC4),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFF40485D).withOpacity(0.2)),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.51,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF9EFFC8), Color(0xFF1DFBA5)],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Spent: 51%", style: TextStyle(color: Color(0xFFA3AAC4), fontSize: 9, fontWeight: FontWeight.w600)),
                            Text("Remaining: ₹ 19,500", style: TextStyle(color: Color(0xFFA3AAC4), fontSize: 9, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Recent Transactions
                  Expanded(
                    child: _buildGlassPanel(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Recent Transactions",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDEE5FF),
                                  ),
                                ),
                                Text(
                                  "VIEW ALL",
                                  style: TextStyle(
                                    color: Color(0xFF9EFFC8),
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: NotificationListener<UserScrollNotification>(
                              onNotification: (notification) {
                                if (notification.direction == ScrollDirection.forward) {
                                  if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
                                } else if (notification.direction == ScrollDirection.reverse) {
                                  if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
                                }
                                return true;
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 130),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _recentTransactions.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final tx = _recentTransactions[index];
                                  final isIncome = tx.type == TransactionType.income;
                                  final amountColor = isIncome ? const Color(0xFF9EFFC8) : const Color(0xFFFF716C);
                                  final amountPrefix = isIncome ? "+ ₹" : "- ₹";
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF060E20).withOpacity(0.3),
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
                                                tx.title,
                                                style: const TextStyle(
                                                  color: Color(0xFFDEE5FF),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${tx.category} • Today",
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
                                          "$amountPrefix${tx.amount.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            color: amountColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ExpandableGlassFab(
        onAddTap: _showAddDialog,
        onSearchChanged: (query) {
          print("Searching for: $query");
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildGlassPanel({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF192540).withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF40485D).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
