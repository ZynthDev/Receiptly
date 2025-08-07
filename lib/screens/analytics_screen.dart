import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/receipt_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../models/expense_category.dart';
import '../widgets/loading_shimmer.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.receipts.isEmpty) {
            return const AnalyticsShimmer();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider),
              _buildCategoriesTab(provider),
              _buildCalendarTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(ReceiptProvider provider) {
    final currentMonth = Helpers.getStartOfMonth(_selectedMonth);
    final nextMonth = Helpers.getEndOfMonth(_selectedMonth);
    final receiptsThisMonth = provider.getReceiptsByDateRange(currentMonth, nextMonth);
    final totalThisMonth = receiptsThisMonth.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
    
    final lastMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    final lastMonthStart = Helpers.getStartOfMonth(lastMonth);
    final lastMonthEnd = Helpers.getEndOfMonth(lastMonth);
    final receiptsLastMonth = provider.getReceiptsByDateRange(lastMonthStart, lastMonthEnd);
    final totalLastMonth = receiptsLastMonth.fold<double>(0.0, (sum, r) => sum + r.totalAmount);
    
    final percentageChange = Helpers.calculatePercentageChange(totalLastMonth, totalThisMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          _buildMonthSelector(),
          
          const SizedBox(height: 24),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'This Month',
                  Helpers.formatCurrency(totalThisMonth),
                  AppTheme.primaryColor,
                  Icons.trending_up,
                  percentageChange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Receipts',
                  receiptsThisMonth.length.toString(),
                  AppTheme.secondaryColor,
                  Icons.receipt_long,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Monthly trend chart
          _buildMonthlyTrendChart(provider),
          
          const SizedBox(height: 24),
          
          // Recent transactions
          _buildRecentTransactions(receiptsThisMonth),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ReceiptProvider provider) {
    final currentMonth = Helpers.getStartOfMonth(_selectedMonth);
    final nextMonth = Helpers.getEndOfMonth(_selectedMonth);
    final receiptsThisMonth = provider.getReceiptsByDateRange(currentMonth, nextMonth);
    final categoryTotals = <String, double>{};
    
    for (final receipt in receiptsThisMonth) {
      categoryTotals[receipt.category] = 
          (categoryTotals[receipt.category] ?? 0) + receipt.totalAmount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          _buildMonthSelector(),
          
          const SizedBox(height: 24),
          
          // Pie chart
          if (categoryTotals.isNotEmpty) ...[
            _buildCategoryPieChart(categoryTotals),
            const SizedBox(height: 24),
          ],
          
          // Category list
          _buildCategoryList(categoryTotals),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(ReceiptProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar
          _buildExpenseCalendar(provider),
          
          const SizedBox(height: 24),
          
          // Daily expenses for selected day
          _buildDailyExpenses(provider),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              '${Helpers.monthFullNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              if (nextMonth.isBefore(DateTime.now()) || 
                  nextMonth.month == DateTime.now().month) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
              }
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, [
    double? percentageChange,
  ]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (percentageChange != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentageChange >= 0 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percentageChange >= 0 
                            ? Icons.trending_up 
                            : Icons.trending_down,
                        size: 12,
                        color: percentageChange >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentageChange.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: percentageChange >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(ReceiptProvider provider) {
    final currentYear = _selectedMonth.year;
    final monthlyData = <int, double>{};
    
    // Initialize all months with 0
    for (int i = 1; i <= 12; i++) {
      monthlyData[i] = 0.0;
    }
    
    // Calculate monthly totals
    for (final receipt in provider.receipts) {
      if (receipt.date.year == currentYear) {
        monthlyData[receipt.date.month] = 
            (monthlyData[receipt.date.month] ?? 0) + receipt.totalAmount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend ($currentYear)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['J', 'F', 'M', 'A', 'M', 'J', 
                                       'J', 'A', 'S', 'O', 'N', 'D'];
                        final index = value.toInt() - 1;
                        if (index >= 0 && index < months.length) {
                          return Text(
                            months[index],
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.entries.map((e) => 
                        FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryColor,
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minX: 1,
                maxX: 12,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> categoryTotals) {
    final total = categoryTotals.values.fold<double>(0.0, (sum, val) => sum + val);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sortedEntries.take(5).map((entry) {
                        final category = ExpenseCategory.getCategoryByName(entry.key);
                        final percentage = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: category.color,
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          radius: 60,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: sortedEntries.take(5).map((entry) {
                      final category = ExpenseCategory.getCategoryByName(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> categoryTotals) {
    final total = categoryTotals.values.fold<double>(0.0, (sum, val) => sum + val);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final category = ExpenseCategory.getCategoryByName(entry.key);
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}% of total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(entry.value),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseCalendar(ReceiptProvider provider) {
    final dailyTotals = <DateTime, double>{};
    
    for (final receipt in provider.receipts) {
      final dateKey = DateTime(receipt.date.year, receipt.date.month, receipt.date.day);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + receipt.totalAmount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = selectedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final dateKey = DateTime(date.year, date.month, date.day);
            final total = dailyTotals[dateKey];
            if (total != null && total > 0) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyExpenses(ReceiptProvider provider) {
    final dateKey = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    final dayReceipts = provider.receipts.where((receipt) {
      final receiptDate = DateTime(receipt.date.year, receipt.date.month, receipt.date.day);
      return isSameDay(receiptDate, dateKey);
    }).toList();

    final total = dayReceipts.fold<double>(0.0, (sum, r) => sum + r.totalAmount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Expenses for ${Helpers.formatDate(_focusedDay)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                Helpers.formatCurrency(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dayReceipts.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No expenses for this day',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...dayReceipts.map((receipt) {
              final category = ExpenseCategory.getCategoryByName(receipt.category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.merchantName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            receipt.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(receipt.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List receipts) {
    final recentReceipts = receipts.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (recentReceipts.isEmpty) ...[
            Center(
              child: Text(
                'No transactions this month',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ] else ...[
            ...recentReceipts.map((receipt) {
              final category = ExpenseCategory.getCategoryByName(receipt.category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.merchantName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            Helpers.formatRelativeDate(receipt.date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(receipt.totalAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
