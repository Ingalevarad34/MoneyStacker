import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Root: /expenses
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("expenses");

  // ---------- UPPER LOGIC STATE ----------
  final int currentYear = DateTime.now().year;

  double totalExpense = 0.0;
  List<Map<String, dynamic>> transactions = [];
  List<double> monthlyTotals = List.filled(12, 0.0);

  final List<String> months = [
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
  String selectedTab = "Month"; // Default filter tab
  // --------------------------------------

  StreamSubscription<DatabaseEvent>? _yearSub;

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

  /// Convert a raw Firebase node into a Map. If raw is a List, we convert it to a Map.
  /// If [monthListToMonthKeys] is true, list index 0 -> month "1", index 1 -> "2", etc.
  Map<dynamic, dynamic> _toMap(dynamic raw,
      {bool monthListToMonthKeys = false}) {
    if (raw is Map) return raw;
    if (raw is List) {
      final Map<dynamic, dynamic> out = {};
      for (int i = 0; i < raw.length; i++) {
        final val = raw[i];
        if (val != null) {
          final key = monthListToMonthKeys ? (i + 1).toString() : i.toString();
          out[key] = val;
        }
      }
      return out;
    }
    return {};
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
      // assume milliseconds epoch
      try {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      } catch (_) {
        return null;
      }
    }
    if (raw is String) {
      // try ISO first
      try {
        return DateTime.parse(raw);
      } catch (_) {
        // try common fallback
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

  // ---------- UPPER LOGIC UPDATED ----------
  // Reads hierarchical data: /expenses/<year>/<month>/{total, items}
  // Works whether Firebase stores nodes as Map or List (old data).
  void fetchExpenses() {
    // Cancel existing subscription to avoid duplicates
    _yearSub?.cancel();

    _yearSub = dbRef.child(currentYear.toString()).onValue.listen((event) {
      final rawYear = event.snapshot.value;
      final Map<dynamic, dynamic> yearMap =
          _toMap(rawYear, monthListToMonthKeys: true);

      double runningTotalForFilter = 0.0;
      List<Map<String, dynamic>> tempList = [];
      List<double> tempMonthlyTotals = List.filled(12, 0.0);

      // Anchor day inside selected month (prevents day overflow)
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

      if (yearMap.isNotEmpty) {
        for (int m = 1; m <= 12; m++) {
          final dynamic monthRaw = yearMap[m.toString()];
          if (monthRaw == null) {
            tempMonthlyTotals[m - 1] = 0.0;
            continue;
          }

          // If monthRaw is a Map, treat normally.
          // If monthRaw is a List (older shape), assume that list represents items -> wrap as { "items": list }
          Map<dynamic, dynamic> monthNode;
          if (monthRaw is Map) {
            monthNode = monthRaw;
          } else {
            // cover lists or other raw forms
            monthNode = _toMap({'items': monthRaw});
            // if monthRaw itself was a list of items, above will put it under key 'items'
            // but _toMap returns map with numeric keys; handle explicitly below too
            if (monthNode.isEmpty && monthRaw is List) {
              monthNode = {'items': monthRaw};
            }
          }

          // Read stored total (if present) else compute from items
          double monthTotal = 0.0;
          final dynamic totalRaw = monthNode['total'];
          if (totalRaw != null) {
            monthTotal = _parseAmount(totalRaw);
          }

          // Normalize items into a map for safe iteration
          final dynamic rawItems = monthNode['items'];
          final Map<dynamic, dynamic> itemsMap = _toMap(rawItems);

          if (monthTotal == 0.0 && itemsMap.isNotEmpty) {
            // compute sum fallback
            double computed = 0.0;
            for (final entry in itemsMap.entries) {
              final dynamic v = entry.value;
              if (v is Map || v is List) {
                // if list inside, try to normalize
                final Map<dynamic, dynamic> maybeItem =
                    v is Map ? v : _toMap(v);
                final amt = _parseAmount(maybeItem['amount']);
                computed += amt;
              } else {
                // not map -> skip
              }
            }
            monthTotal = computed;
          }

          tempMonthlyTotals[m - 1] = monthTotal;

          // Now build list + running total according to active tab filter
          if (itemsMap.isNotEmpty) {
            for (final e in itemsMap.entries) {
              final dynamic rawItem = e.value;
              // rawItem might be Map or primitive; we only support Map items
              final Map<dynamic, dynamic> item = (rawItem is Map)
                  ? rawItem
                  : (rawItem is List ? _toMap(rawItem) : <dynamic, dynamic>{});
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
                  "title": item['title'],
                  "subtitle": item['subtitle'] ?? '',
                  "amount": amount,
                  "time": item['time'] ?? DateFormat.Hm().format(date),
                });
              }
            }
          }
        } // end month loop
      } // end if yearMap not empty

      setState(() {
        totalExpense = runningTotalForFilter;
        transactions = tempList;
        monthlyTotals = tempMonthlyTotals;
      });
    });
  }

  // Writes to: /expenses/<year>/<month>/items/<id>, and updates /total
  void addExpense(String title, String subtitle, double amount) async {
    final DateTime now = DateTime.now();
    final DateTime expenseDate = DateTime(
      currentYear,
      selectedMonthIndex + 1,
      now.day,
      now.hour,
      now.minute,
    );

    final DatabaseReference monthRef =
        dbRef.child('$currentYear/${selectedMonthIndex + 1}');

    final DatabaseReference pushRef = monthRef.child('items').push();
    final String id = pushRef.key!;
    await pushRef.set({
      "title": title,
      "subtitle": subtitle,
      "amount": amount,
      "time": DateFormat.Hm().format(expenseDate),
      "date": expenseDate.toIso8601String(),
    });

    // Update monthly total (simple read + set)
    final snap = await monthRef.child('total').once();
    final double currentTotal =
        (snap.snapshot.value as num?)?.toDouble() ?? 0.0;
    await monthRef.child('total').set(currentTotal + amount);
  }
  // ---------------------------------------

  @override
  Widget build(BuildContext context) {
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
                  value: index,
                  child: Text(months[index]),
                ),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Tab Bar
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

            // Total Expense Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expenses",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        "\$${totalExpense.toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bar Chart for yearly expenses
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (monthlyTotals.reduce((a, b) => a > b ? a : b) + 50),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            final monthAbbr =
                                months[value.toInt()].substring(0, 3);
                            return Text(monthAbbr,
                                style: const TextStyle(fontSize: 10));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyTotals[i],
                          color: Colors.blueAccent,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  print(transactions.length);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: const Icon(Icons.shopping_cart,
                            color: Colors.blueAccent),
                      ),
                      title: Text(tx['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tx['subtitle']),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("-\$${tx['amount']}",
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          Text(tx['time'],
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

      // Add new expense (adds to the selected AppBar month)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          addExpense("Shopping", "Buy groceries", 120.0);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
