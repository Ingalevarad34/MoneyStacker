// home_widgets.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_stacker/features/home/controllers/homeController.dart';
import 'package:money_stacker/screens/expensesDetails/expensesDetail.dart';

class MonthDropdown extends StatelessWidget {
  const MonthDropdown({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      return DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: c.selectedMonthIndex.value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          dropdownColor: Colors.white,
          items: List.generate(
            c.months.length,
            (index) => DropdownMenuItem<int>(
              value: index,
              child: Text(c.months[index]),
            ),
          ),
          onChanged: (val) {
            if (val != null) c.setSelectedMonth(val);
          },
        ),
      );
    });
  }
}

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    final tabs = ["Today", "Week", "Month", "Year"];
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final selected = c.selectedTab.value == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                color: WidgetStatePropertyAll(Colors.white),
                label: Text(tab),
                selected: selected,
                onSelected: (val) => c.setSelectedTab(tab),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class ExpensesChart extends StatelessWidget {
  const ExpensesChart({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    const double barWidth = 20.0;
    const double approxGroupGap = 28.0;
    final double contentWidth = math.max(
      MediaQuery.of(context).size.width - 32,
      c.months.length * (barWidth + approxGroupGap),
    );
    return Obx(() {
      final monthly = c.monthlyTotals;
      final double maxMonthly = monthly.fold<double>(
        0.0,
        (p, e) => e > p ? e : p,
      );
      final double maxY = (maxMonthly <= 0 ? 100.0 : maxMonthly * 1.2);
      final int currentMonthIndex = DateTime.now().month - 1;
      return SizedBox(
        height: 260,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = c.months[group.x.toInt()].substring(0, 3);
                      return BarTooltipItem(
                        '$label\n\₹${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i >= 0 && i < c.months.length) {
                          final isCurrent = i == currentMonthIndex;
                          final monthAbbr = c.months[i].substring(0, 3);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 6,
                            child: Text(
                              monthAbbr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrent ? Colors.red : Colors.black,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true, horizontalInterval: 200),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthly[i],
                        width: barWidth,
                        borderRadius: BorderRadius.circular(4),
                        color: i == currentMonthIndex
                            ? Colors.redAccent
                            : Colors.blueAccent,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class TransactionsList extends StatelessWidget {
  const TransactionsList({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      final txs = c.transactions;
      if (txs.isEmpty) {
        return const Center(
          child: Text(
            "No transactions for this filter",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        );
      }
      return ListView.builder(
        itemCount: txs.length,
        itemBuilder: (context, index) {
          final tx = txs[index];
          final amount = (tx['amount'] ?? 0).toString();
          return InkWell(
            onTap: () {
              Get.to(() => ExpensesDetailScreen(data: tx));
            },
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.blueAccent,
                  ),
                ),
                title: Text(
                  tx['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  tx['subtitle'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "- ₹$amount",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['time'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
