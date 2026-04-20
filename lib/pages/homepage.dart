import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../components/expensedialog.dart';
import '../components/expandable_fab.dart';
import '../components/voice_bottom_sheet.dart';
import '../models/isar_expense.dart';
import '../providers/app_providers.dart';
import '../providers/expense_providers.dart';
import 'home/widgets/expense_card.dart';
import 'home/widgets/glass_panel.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/monthly_spending_card.dart';
import 'home/widgets/recent_transactions_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _addNewExpense(IsarExpense newExpense) async {
    await ref.read(expenseRepositoryProvider).addExpense(newExpense);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AddExpenseDialog(onAddExpense: _addNewExpense),
    );
  }

  void _handleVoiceTap() {
    showVoiceBottomSheet(context, onSave: _addNewExpense);
  }

  void _handleTransactionScroll(ScrollDirection direction) {
    final controller = ref.read(navBarVisibleProvider.notifier);

    if (direction == ScrollDirection.forward && !controller.state) {
      controller.state = true;
    } else if (direction == ScrollDirection.reverse && controller.state) {
      controller.state = false;
    }
  }

  void _openSettings() {
    context.pushNamed(AppRoutes.settingsName);
  }

  @override
  Widget build(BuildContext context) {
    final isNavBarVisible = ref.watch(navBarVisibleProvider);
    final recentTransactionsAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                    const Color(0xFF1DFBA5).withValues(alpha: 0.05),
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
                    const Color(0xFF874CFF).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: recentTransactionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1DFBA5)),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load transactions: $error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (recentTransactions) => NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  _handleTransactionScroll(notification.direction);
                  return true;
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 10),
                    HomeHeader(onNotificationsTap: _openSettings),
                    const SizedBox(height: 20),
                    GlassPanel(child: ExpenseCard(transactions: recentTransactions)),
                    const SizedBox(height: 12),
                    GlassPanel(
                      padding: const EdgeInsets.all(16),
                      child: MonthlySpendingCard(transactions: recentTransactions),
                    ),
                    const SizedBox(height: 12),
                    GlassPanel(
                      padding: const EdgeInsets.all(0),
                      child: RecentTransactionsCard(
                        transactions: recentTransactions,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        offset: isNavBarVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isNavBarVisible ? 1 : 0,
          child: ExpandableGlassFab(
            onAddTap: _showAddDialog,
            onVoiceTap: _handleVoiceTap,
            onSearchChanged: (query) {
              debugPrint('Searching for: $query');
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
