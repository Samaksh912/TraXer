import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/isar_expense.dart';

class AddExpenseDialog extends StatefulWidget {
  final Future<void> Function(IsarExpense) onAddExpense;
  final IsarExpense? draft; // Optional prefill from voice

  const AddExpenseDialog({
    super.key,
    required this.onAddExpense,
    this.draft,
  });

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  // Controllers
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();

  // State
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory;
  bool _isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    // Prefill from voice draft if provided
    final draft = widget.draft;
    if (draft != null) {
      _titleController.text = draft.title;
      _amountController.text = draft.amount > 0 ? draft.amount.toStringAsFixed(0) : '';
      _selectedType = draft.type;
      _selectedDate = draft.createdAt;
      // Only set category if it matches a known category in the list
      final knownExpense = ['Food', 'Travel', 'Shopping', 'Housing', 'Utilities', 'Health', 'Entertainment', 'Others'];
      final knownIncome = ['Salary', 'Freelance', 'Business', 'Investments', 'Gift', 'Rental', 'Refund', 'Others'];
      final known = draft.type == TransactionType.expense ? knownExpense : knownIncome;
      if (known.contains(draft.category)) {
        _selectedCategory = draft.category;
      }
    }
  }

  // Configuration Lists
  final List<String> _expenseCategories = [
    'Food', 'Travel', 'Shopping', 'Housing', 'Utilities', 'Health', 'Entertainment', 'Others'
  ];

  final List<String> _incomeCategories = [
    'Salary', 'Freelance', 'Business', 'Investments', 'Gift', 'Rental', 'Refund', 'Others'
  ];

  // Getters for Dynamic Theme
  Color get _activeColor => _selectedType == TransactionType.expense
      ? context.appColors.expense
      : context.appColors.income;

  List<String> get _currentCategories => _selectedType == TransactionType.expense
      ? _expenseCategories
      : _incomeCategories;

  Future<void> _submitData() async {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    // Resolve Category
    String finalCategory = '';
    if (_selectedCategory == 'Others') {
      final customText = _customCategoryController.text.trim();
      finalCategory = customText.isEmpty ? 'Others' : customText;
    } else {
      finalCategory = _selectedCategory ?? '';
    }

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0 || finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields correctly.'))
      );
      return;
    }

    final newExpense = IsarExpense()
      ..title = enteredTitle
      ..amount = enteredAmount
      ..createdAt = _selectedDate
      ..category = finalCategory
      ..type = _selectedType;

    await widget.onAddExpense(newExpense);
    context.pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _activeColor),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87; // Slightly softer black

    // Designed Gradients
    LinearGradient dynamicGradient;

    if (_selectedType == TransactionType.expense) {
      dynamicGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Color(0xFF382222), context.appColors.surface] // Dark: Deep Burgundy -> Dark Grey
            : [context.appColors.background, Color(0xFFFFFFFF)], // Light: Soft Rose -> White
      );
    } else {
      dynamicGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Color(0xFF1A3325), context.appColors.surface] // Dark: Deep Forest -> Dark Grey
            : [context.appColors.background, Color(0xFFFFFFFF)], // Light: Soft Mint -> White
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16), // Slightly tighter margins
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart, // Smoother curve
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: dynamicGradient,
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.white, // In light mode, white border adds a nice "glass" edge
              width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: _activeColor.withOpacity(isDark ? 0.3 : 0.15), // Colored shadow glow
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: -5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSlidingTabSwitcher(isDark),

              const SizedBox(height: 30),

              // Title Input
              TextField(
                controller: _titleController,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
                cursorColor: _activeColor,
                decoration: _inputDecoration("Title", isDark, textColor),
              ),
              const SizedBox(height: 20),

              // Amount & Date Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      cursorColor: _activeColor,
                      decoration: _inputDecoration("Amount", isDark, textColor, prefix: "₹ "),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _presentDatePicker,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 60, // Match input height
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                              width: 1.5
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM').format(_selectedDate),
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            Icon(Icons.calendar_month_rounded, size: 22, color: _activeColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: isDark ? context.appColors.surface : Colors.white,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: _inputDecoration("Category", isDark, textColor),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _activeColor),
                borderRadius: BorderRadius.circular(16),
                items: _currentCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    _isOtherSelected = newValue == 'Others';
                    if (!_isOtherSelected) _customCategoryController.clear();
                  });
                },
              ),

              if (_isOtherSelected) ...[
                const SizedBox(height: 15),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isOtherSelected ? 1.0 : 0.0,
                  child: TextField(
                    controller: _customCategoryController,
                    style: TextStyle(color: textColor),
                    cursorColor: _activeColor,
                    decoration: _inputDecoration("Specify Category", isDark, textColor),
                  ),
                ),
              ],

              const SizedBox(height: 35),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white60 : Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _activeColor.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ]
                    ),
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _activeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      child: Text(_selectedType == TransactionType.expense ? "Add Expense" : "Add Income"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Helper for tab labels
  Widget _buildTabLabel(String label, TransactionType type, bool isDark) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // Helper for Input Decoration (Slightly refined for modern look)
// Helper for Input Decoration
  InputDecoration _inputDecoration(String label, bool isDark, Color textColor, {String? prefix}) { // 1. Add textColor here
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold), // 2. Use it here
      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontWeight: FontWeight.w500),
      floatingLabelStyle: TextStyle(color: _activeColor, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _activeColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
  Widget _buildSlidingTabSwitcher(bool isDark) {
    const double height = 50;
    final bool isExpense = _selectedType == TransactionType.expense;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(
        children: [
          // The sliding bubble
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: _activeColor,
                    borderRadius: BorderRadius.circular((height - 8) / 2),
                    boxShadow: [
                      BoxShadow(
                        color: _activeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                ),
              ),
            ),
          ),
          // The Text Labels
          Row(
            children: [
              _buildTabLabel("Expense", TransactionType.expense, isDark),
              _buildTabLabel("Income", TransactionType.income, isDark),
            ],
          ),
        ],
      ),
    );
  }
}
