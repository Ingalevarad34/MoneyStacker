// home_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:money_stacker/screens/addExpenses/addExpenses.dart';

enum MonthKeying { zeroBased, oneBased }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("expenses");
  final int currentYear = DateTime.now().year;

  double totalExpense = 0.0;
  List<Map<String, dynamic>> transactions = [];
  List<double> monthlyTotals = List.filled(12, 0.0);

  final List<String> months = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  int selectedMonthIndex = DateTime.now().month - 1;
  String selectedTab = "Month";

  StreamSubscription<DatabaseEvent>? _yearSub;
  MonthKeying _yearKeying = MonthKeying.oneBased;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  @override
  void dispose() {
    _yearSub?.cancel();
    super.dispose();
  }

  Map<dynamic, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return raw;
    if (raw is List) {
      final Map<dynamic, dynamic> out = {};
      for (int i = 0; i < raw.length; i++) {
        if (raw[i] != null) out[i.toString()] = raw[i];
      }
      return out;
    }
    return {};
  }

  Map<String, dynamic> _normalizeYearToOneBased(dynamic rawYear) {
    final Map<String, dynamic> out = {
      for (int m = 1; m <= 12; m++) m.toString(): {}
    };

    if (rawYear is List) {
      for (int i = 0; i < rawYear.length && i < 12; i++) {
        final val = rawYear[i];
        if (val != null) out[(i + 1).toString()] = val;
      }
    } else if (rawYear is Map) {
      final keys = rawYear.keys.map((k) => k.toString()).toList();
      final hasZeroKey = keys.contains('0');
      for (final k in rawYear.keys) {
        final ks = k.toString();
        final asInt = int.tryParse(ks);
        if (asInt != null) {
          if (hasZeroKey && asInt >= 0 && asInt <= 11) {
            out[(asInt + 1).toString()] = rawYear[k];
          } else if (asInt >= 1 && asInt <= 12) {
            out[asInt.toString()] = rawYear[k];
          }
        }
      }
    }
    return out;
  }

  MonthKeying _detectKeying(dynamic rawYear) {
    if (rawYear is List) return MonthKeying.zeroBased;
    if (rawYear is Map) {
      final keys = rawYear.keys.map((k) => k.toString()).toList();
      if (keys.contains('0')) return MonthKeying.zeroBased;
      if (keys.any((k) => k == '1' || k == '12')) return MonthKeying.oneBased;
    }
    return MonthKeying.oneBased;
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[^\d\.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parse(raw);
        } catch (_) {
          try {
            return DateFormat('MM/dd/yyyy').parse(raw);
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  void fetchExpenses() {
    _yearSub?.cancel();
    final yearRef = dbRef.child(currentYear.toString());

    _yearSub = yearRef.onValue.listen((event) {
      final rawYear = event.snapshot.value;
      _yearKeying = _detectKeying(rawYear);
      final Map<String, dynamic> yearMap = _normalizeYearToOneBased(rawYear);

      double runningTotalForFilter = 0.0;
      List<Map<String, dynamic>> tempList = [];
      List<double> tempMonthlyTotals = List.filled(12, 0.0);

      int daysInSelectedMonth =
          DateTime(currentYear, (selectedMonthIndex + 1) + 1, 0).day;
      int todayDay = DateTime.now().day;
      if (todayDay > daysInSelectedMonth) todayDay = daysInSelectedMonth;
      final DateTime anchor =
          DateTime(currentYear, selectedMonthIndex + 1, todayDay);

      final DateTime startOfWeek =
          anchor.subtract(Duration(days: anchor.weekday - 1));
      final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      bool inRange(DateTime d, DateTime start, DateTime end) {
        return !d.isBefore(start) && !d.isAfter(end);
      }

      for (int m = 1; m <= 12; m++) {
        final dynamic monthRaw = yearMap[m.toString()];
        if (monthRaw == null) {
          tempMonthlyTotals[m - 1] = 0.0;
          continue;
        }

        Map<dynamic, dynamic> monthNode;
        if (monthRaw is Map) {
          monthNode = monthRaw;
        } else {
          monthNode = {'items': monthRaw};
        }

        double monthTotal = 0.0;
        final dynamic totalRaw = monthNode['total'];
        if (totalRaw != null) {
          monthTotal = _parseAmount(totalRaw);
        }

        final dynamic rawItems = monthNode['items'];
        final Map<dynamic, dynamic> itemsMap = _toMap(rawItems);

        if (monthTotal == 0.0 && itemsMap.isNotEmpty) {
          double computed = 0.0;
          for (final entry in itemsMap.entries) {
            final dynamic v = entry.value;
            final Map<dynamic, dynamic> item =
                (v is Map) ? v : (v is List ? _toMap(v) : {});
            if (item.isEmpty) continue;
            computed += _parseAmount(item['amount']);
          }
          monthTotal = computed;
        }

        tempMonthlyTotals[m - 1] = monthTotal;

        if (itemsMap.isNotEmpty) {
          for (final e in itemsMap.entries) {
            final dynamic rawItem = e.value;
            final Map<dynamic, dynamic> item = (rawItem is Map)
                ? rawItem
                : (rawItem is List ? _toMap(rawItem) : {});
            if (item.isEmpty) continue;

            final double amount = _parseAmount(item['amount']);
            final DateTime? date = _parseDate(item['date']);
            if (date == null) continue;

            bool matches = false;
            if (selectedTab == "Today") {
              matches = (date.year == currentYear) &&
                  (date.month == selectedMonthIndex + 1) &&
                  (date.day == anchor.day);
            } else if (selectedTab == "Week") {
              matches = (date.year == currentYear) &&
                  (date.month == selectedMonthIndex + 1) &&
                  inRange(date, startOfWeek, endOfWeek);
            } else if (selectedTab == "Month") {
              matches = (date.year == currentYear) &&
                  (date.month == selectedMonthIndex + 1);
            } else if (selectedTab == "Year") {
              matches = (date.year == currentYear);
            }

            if (matches) {
              runningTotalForFilter += amount;
              tempList.add({
                "title": item['title'] ?? '',
                "subtitle": item['subtitle'] ?? '',
                "amount": amount,
                "time": item['time'] ??
                    (date != null ? DateFormat.Hm().format(date) : ''),
              });
            }
          }
        }
      }

      setState(() {
        totalExpense = runningTotalForFilter;
        transactions = tempList;
        monthlyTotals = tempMonthlyTotals;
      });
    });
  }

  // Legacy: kept for compatibility — not used by FAB anymore.
  Future<void> addExpenseProgrammatic(
      String title, String subtitle, double amount) async {
    final DateTime now = DateTime.now();
    final int monthKeyForWrite = _yearKeying == MonthKeying.zeroBased
        ? now.month - 1 // 0..11
        : now.month; // 1..12

    final DatabaseReference monthRef =
        dbRef.child('$currentYear/$monthKeyForWrite');
    final DatabaseReference pushRef = monthRef.child('items').push();
    await pushRef.set({
      "title": title,
      "subtitle": subtitle,
      "amount": amount,
      "time": DateFormat.Hm().format(now),
      "date": now.toIso8601String(),
    });

    // Update monthly total safely using a transaction
    await monthRef.child('total').runTransaction((Object? currentData) {
      // currentData is Object? and may be null
      double currentTotal = 0.0;

      if (currentData != null) {
        currentTotal = (currentData as num).toDouble();
      }

      double updatedTotal = currentTotal + amount;

      return Transaction.success(updatedTotal);
    });
  }

  @override
  Widget build(BuildContext context) {
    const double barWidth = 20.0;
    const double approxGroupGap = 28.0;
    final double contentWidth = math.max(
      MediaQuery.of(context).size.width - 32,
      months.length * (barWidth + approxGroupGap),
    );

    final double maxMonthly =
        monthlyTotals.fold<double>(0.0, (p, e) => e > p ? e : p);
    final double maxY = (maxMonthly <= 0 ? 100.0 : maxMonthly * 1.2);
    final int currentMonthIndex = DateTime.now().month - 1;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonthIndex,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
              dropdownColor: Colors.white,
              items: List.generate(
                months.length,
                (index) => DropdownMenuItem<int>(
                    value: index, child: Text(months[index])),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedMonthIndex = val;
                    fetchExpenses();
                  });
                }
              },
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blueAccent),
            onPressed: () async {
              // Another entry point to add expense
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (_) => const AddExpensePage()),
              );
              if (result == true) {
                // Fetch fresh data (not strictly necessary because stream updates, but safe)
                fetchExpenses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense added')),
                  );
                }
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Today", "Week", "Month", "Year"].map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tab),
                      selected: selectedTab == tab,
                      onSelected: (val) {
                        setState(() {
                          selectedTab = tab;
                          fetchExpenses();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Total card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Expenses",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text("\$${totalExpense.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // Swipeable chart
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                            final label =
                                months[group.x.toInt()].substring(0, 3);
                            return BarTooltipItem(
                              '$label\n\$${rod.toY.toStringAsFixed(2)}',
                              const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i >= 0 && i < months.length) {
                                final isCurrent = i == currentMonthIndex;
                                final monthAbbr = months[i].substring(0, 3);
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
                                      color:
                                          isCurrent ? Colors.red : Colors.black,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData:
                          const FlGridData(show: true, horizontalInterval: 50),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyTotals[i],
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
            ),

            const SizedBox(height: 20),

            const Text("Recent Transactions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: const Icon(Icons.shopping_cart,
                            color: Colors.blueAccent),
                      ),
                      title: Text(tx['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tx['subtitle'] ?? ''),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              "-\$${(tx['amount'] as double).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(tx['time'] ?? '',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB now opens AddExpensePage (no hardcoded values)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpensePage()),
          );
          if (result == true) {
            // refresh (stream already updates, but this ensures UI consistency)
            fetchExpenses();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Expense added')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
