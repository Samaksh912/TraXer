import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/isar_expense.dart';

class TransactionHistoryPage extends StatefulWidget {
  final List<IsarExpense> allTransactions;

  const TransactionHistoryPage({super.key, required this.allTransactions});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late List<IsarExpense> _filteredTransactions;

  // Filter & Sort States
  bool _sortDescending = true; // True = Newest first
  String _filterType = 'All'; // All, Expense, Income
  String _filterCategory = 'All';
  DateTimeRange? _filterDateRange;

  // Derive unique categories dynamically for the filter
  List<String> get _availableCategories {
    final cats = widget.allTransactions.map((e) => e.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    List<IsarExpense> result = List.from(widget.allTransactions);

    // 1. Filter by Type
    if (_filterType == 'Expense') {
      result.retainWhere((tx) => tx.type == TransactionType.expense);
    } else if (_filterType == 'Income') {
      result.retainWhere((tx) => tx.type == TransactionType.income);
    }

    // 2. Filter by Category
    if (_filterCategory != 'All') {
      result.retainWhere((tx) => tx.category == _filterCategory);
    }

    // 3. Filter by Date Range
    if (_filterDateRange != null) {
      result.retainWhere((tx) {
        return tx.createdAt.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
            tx.createdAt.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      });
    }

    // 4. Sort
    result.sort((a, b) {
      if (_sortDescending) {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return a.createdAt.compareTo(b.createdAt);
      }
    });

    setState(() {
      _filteredTransactions = result;
    });
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF192540) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Filter Transactions', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        // Type Filter
                        Text('Type', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: ['All', 'Expense', 'Income'].map((type) {
                            final isSelected = _filterType == type;
                            return ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (val) {
                                setModalState(() => _filterType = type);
                                _applyFiltersAndSort();
                              },
                              selectedColor: const Color(0xFF5B8EFF).withOpacity(0.2),
                              labelStyle: TextStyle(color: isSelected ? const Color(0xFF5B8EFF) : (isDark ? Colors.white : Colors.black)),
                              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Category Filter
                        Text('Category', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            spacing: 12,
                            children: _availableCategories.map((cat) {
                              final isSelected = _filterCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (val) {
                                  setModalState(() => _filterCategory = cat);
                                  _applyFiltersAndSort();
                                },
                                selectedColor: const Color(0xFF5B8EFF).withOpacity(0.2),
                                labelStyle: TextStyle(color: isSelected ? const Color(0xFF5B8EFF) : (isDark ? Colors.white : Colors.black)),
                                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Date Range Filter
                        Text('Date Range', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _filterDateRange,
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF5B8EFF))),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => _filterDateRange = picked);
                              _applyFiltersAndSort();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _filterDateRange == null
                                      ? 'Select Date Range'
                                      : '${DateFormat('MMM dd').format(_filterDateRange!.start)} - ${DateFormat('MMM dd').format(_filterDateRange!.end)}',
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
                                ),
                                if (_filterDateRange != null)
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() => _filterDateRange = null);
                                      _applyFiltersAndSort();
                                    },
                                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                                  )
                                else
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Apply Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B8EFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  void _showTransactionDetails(IsarExpense tx, bool isDark) {
    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');
    final isExpense = tx.type == TransactionType.expense;
    final color = isExpense ? const Color(0xFFFB1D55) : const Color(0xFF1DFBA5);

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121A2F) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tx.title,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currFormat.format(tx.amount),
                    style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const SizedBox(height: 32),

                  // Details Grid
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Date', DateFormat('MMMM dd, yyyy • hh:mm a').format(tx.createdAt), isDark),
                        const Divider(height: 24, color: Colors.white10),
                        _detailRow('Category', tx.category, isDark),
                        const Divider(height: 24, color: Colors.white10),
                        _detailRow('Type', isExpense ? 'Expense' : 'Income', isDark),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1424) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'History',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          // Filter Button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_filterType != 'All' || _filterCategory != 'All' || _filterDateRange != null)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFB1D55), shape: BoxShape.circle)),
                  )
              ],
            ),
            onPressed: _showFilterBottomSheet,
          ),
          // Sort Button
          IconButton(
            icon: Icon(_sortDescending ? Icons.sort_rounded : Icons.keyboard_arrow_up_rounded),
            onPressed: () {
              setState(() {
                _sortDescending = !_sortDescending;
                _applyFiltersAndSort();
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _filteredTransactions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 16),
            Text('No transactions found', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
          ],
        ),
      )
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final tx = _filteredTransactions[index];
          final isExpense = tx.type == TransactionType.expense;

          // Soft premium colors based on type
          final accentColor = isExpense ? const Color(0xFFFB1D55) : const Color(0xFF1DFBA5);
          final bgColor = isDark ? const Color(0xFF192540) : Colors.white;

          // Grouping by date header logic (Optional, but looks premium)
          bool showDateHeader = false;
          if (index == 0) {
            showDateHeader = true;
          } else {
            final prevTx = _filteredTransactions[index - 1];
            if (tx.createdAt.day != prevTx.createdAt.day || tx.createdAt.month != prevTx.createdAt.month) {
              showDateHeader = true;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader)
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(tx.createdAt),
                    style: TextStyle(color: isDark ? const Color(0xFFA3AAC4) : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),

              // The Transaction Card
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showTransactionDetails(tx, isDark),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Leading Icon/Dot with soft glow
                            Container(
                              height: 44, width: 44,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                  isExpense ? Icons.shopping_bag_rounded : Icons.account_balance_wallet_rounded,
                                  color: accentColor,
                                  size: 22
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Middle Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx.category,
                                    style: TextStyle(color: isDark ? const Color(0xFFA3AAC4) : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Trailing Amount
                            Text(
                              '${isExpense ? '-' : '+'}${currFormat.format(tx.amount)}',
                              style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}