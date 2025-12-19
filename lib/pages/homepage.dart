import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:traxer/pages/settings.dart';

import '../components/expensedialog.dart';
import '../components/navbar.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 2. Wrap content in NotificationListener to detect scroll direction
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
              }
              return true;
            },
            child: SingleChildScrollView(
              // Changed to SingleScrollView for better stack handling
              padding: const EdgeInsets.only(bottom: 100),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome Back,",
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Samaksh",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          // Settings Button
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark
                                  ? Colors.grey[800]
                                  : const Color(0xFFE0E5ED),
                              child: Icon(
                                Icons.settings,
                                color: isDark ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Balance Card (Same gradient for both modes as it pops well)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CA1AF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Spent this Month",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "₹ 24,500.00",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem(
                                  Icons.arrow_downward,
                                  "Income",
                                  "₹ 45,000",
                                ),
                                Container(
                                  height: 30,
                                  width: 1,
                                  color: Colors.white24,
                                ),
                                _buildSummaryItem(
                                  Icons.arrow_upward,
                                  "Expense",
                                  "₹ 20,500",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        "Recent Transactions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Transactions List
                      ListView.separated(
                        shrinkWrap: true,
                        // IMPORTANT inside SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        // IMPORTANT
                        itemCount: _recentTransactions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        // Inside _HomePageState -> build -> ListView.separated
                        itemBuilder: (context, index) {
                          final tx = _recentTransactions[index];
                          // Logic for color and symbol
                          final isIncome = tx.type == TransactionType.income;
                          final amountColor = isIncome ? Colors.green : Colors.redAccent;
                          final amountPrefix = isIncome ? "+ ₹" : "- ₹";
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // 1. Icon Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : const Color(0xFFF0F2F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                                    color: isDark ? Colors.white70 : Colors.blueGrey[700],
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // 2. Title and Category Chip
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                      ),
                                      const SizedBox(height: 4), // Small gap

                                      // NEW: Category Chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFE3F2FD),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.category, // Display the category here
                                          style: TextStyle(
                                            color: isDark ? Colors.blue[100] : Colors.blue[800],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Amount and Date
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "$amountPrefix${tx.amount.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: amountColor, // <--- Dynamic Color
                                      ),
                                    ),
                                    // ... date ...
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30, // Distance from bottom
            left: 0,
            right: 0,
            child: Center(
              child: FloatingBottomNavBar(
                isVisible: _isNavBarVisible,
                onAddTap: _showAddDialog,
                // Connects to your existing voice function
                onSearchChanged: (query) {
                  // Handle search logic here later
                  print("Searching for: $query");
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String amount) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
