// home_controller.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

enum MonthKeying { zeroBased, oneBased }

class HomeController extends GetxController {
  final int currentYear = DateTime.now().year;
  late final DatabaseReference dbRef;
  late final String userId;

  // reactive state
  final RxDouble totalExpense = 0.0.obs;
  final RxList<Map<String, dynamic>> transactions = <Map<String, dynamic>>[].obs;
  final RxList<double> monthlyTotals = List<double>.filled(12, 0.0).obs;
  final RxInt selectedMonthIndex = (DateTime.now().month - 1).obs;
  final RxString selectedTab = "Month".obs;

  final List<String> months = const [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December",
  ];

  StreamSubscription<DatabaseEvent>? _yearSub;
  MonthKeying _yearKeying = MonthKeying.oneBased;

  @override
  void onInit() {
    super.onInit();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? 'guest';
    dbRef = FirebaseDatabase.instance.ref("expenses").child(userId);

    // start listening
    fetchExpenses();
  }

  @override
  void onClose() {
    _yearSub?.cancel();
    super.onClose();
  }

  // helpers (moved from your original file)
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

  MonthKeying _detectKeying(dynamic rawYear) {
    if (rawYear is List) return MonthKeying.zeroBased;
    if (rawYear is Map) {
      final keys = rawYear.keys.map((k) => k.toString()).toList();
      if (keys.contains('0')) return MonthKeying.zeroBased;
      if (keys.any((k) => k == '1' || k == '12')) return MonthKeying.oneBased;
    }
    return MonthKeying.oneBased;
  }

  Map<String, dynamic> _normalizeYearToOneBased(dynamic rawYear) {
    final Map<String, dynamic> out = {
      for (int m = 1; m <= 12; m++) m.toString(): {},
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

  // Public setters
  void setSelectedMonth(int newIndex) {
    if (selectedMonthIndex.value != newIndex) {
      selectedMonthIndex.value = newIndex;
      fetchExpenses(); // re-evaluate using new month anchor
    }
  }

  void setSelectedTab(String tab) {
    if (selectedTab.value != tab) {
      selectedTab.value = tab;
      fetchExpenses(); // re-evaluate because filter changed
    }
  }

  Future<void> fetchExpenses() async {
    _yearSub?.cancel();
    final yearRef = dbRef.child(currentYear.toString());

    _yearSub = yearRef.onValue.listen((event) {
      final rawYear = event.snapshot.value;
      _yearKeying = _detectKeying(rawYear);
      final Map<String, dynamic> yearMap = _normalizeYearToOneBased(rawYear);

      double runningTotalForFilter = 0.0;
      List<Map<String, dynamic>> tempList = [];
      List<double> tempMonthlyTotals = List.filled(12, 0.0);

      // anchor is based on selectedMonthIndex (this is the fix)
      int daysInSelectedMonth = DateTime(
        currentYear,
        (selectedMonthIndex.value + 1) + 1,
        0,
      ).day;
      int todayDay = DateTime.now().day;
      if (todayDay > daysInSelectedMonth) todayDay = daysInSelectedMonth;

      final DateTime anchor = DateTime(
        currentYear,
        selectedMonthIndex.value + 1,
        todayDay,
      );

      final DateTime startOfWeek = anchor.subtract(Duration(days: anchor.weekday - 1));
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
        if (totalRaw != null) monthTotal = _parseAmount(totalRaw);

        final dynamic rawItems = monthNode['items'];
        final Map<dynamic, dynamic> itemsMap = _toMap(rawItems);

        if (monthTotal == 0.0 && itemsMap.isNotEmpty) {
          double computed = 0.0;
          for (final entry in itemsMap.entries) {
            final dynamic v = entry.value;
            final Map<dynamic, dynamic> item = (v is Map) ? v : (v is List ? _toMap(v) : {});
            if (item.isEmpty) continue;
            computed += _parseAmount(item['amount']);
          }
          monthTotal = computed;
        }

        tempMonthlyTotals[m - 1] = monthTotal;

        if (itemsMap.isNotEmpty) {
          for (final e in itemsMap.entries) {
            final dynamic rawItem = e.value;
            final Map<dynamic, dynamic> item = (rawItem is Map) ? rawItem : (rawItem is List ? _toMap(rawItem) : {});
            if (item.isEmpty) continue;

            final double amount = _parseAmount(item['amount']);
            final DateTime? date = _parseDate(item['date']);
            if (date == null) continue;

            bool matches = false;
            if (selectedTab.value == "Today") {
              matches =
                  (date.year == currentYear) &&
                  (date.month == selectedMonthIndex.value + 1) &&
                  (date.day == anchor.day);
            } else if (selectedTab.value == "Week") {
              matches =
                  (date.year == currentYear) &&
                  (date.month == selectedMonthIndex.value + 1) &&
                  inRange(date, startOfWeek, endOfWeek);
            } else if (selectedTab.value == "Month") {
              matches = (date.year == currentYear) && (date.month == selectedMonthIndex.value + 1);
            } else if (selectedTab.value == "Year") {
              matches = (date.year == currentYear);
            }

            if (matches) {
              runningTotalForFilter += amount;
              tempList.add({
                "title": item['title'] ?? '',
                "subtitle": item['subtitle'] ?? '',
                "amount": amount,
                "time": item['time'] ?? (date != null ? DateFormat.Hm().format(date) : ''),
                "date": item['date'] ?? '',
                "raw": item,
              });
            }
          }
        }
      }

      // update reactive state
      totalExpense.value = runningTotalForFilter;
      transactions.assignAll(tempList);
      monthlyTotals.assignAll(tempMonthlyTotals);
    });
  }

  // Optional helper to add an expense programmatically (keeps existing behavior)
  Future<void> addExpenseProgrammatic(String title, String subtitle, double amount) async {
    final DateTime now = DateTime.now();
    final int monthKeyForWrite = _yearKeying == MonthKeying.zeroBased ? now.month - 1 : now.month;
    final DatabaseReference monthRef = dbRef.child('$currentYear/$monthKeyForWrite');
    final DatabaseReference pushRef = monthRef.child('items').push();

    await pushRef.set({
      "title": title,
      "subtitle": subtitle,
      "amount": amount,
      "time": DateFormat.Hm().format(now),
      "date": now.toIso8601String(),
    });

    await monthRef.child('total').runTransaction((Object? currentData) {
      double currentTotal = 0.0;
      if (currentData != null) currentTotal = (currentData as num).toDouble();
      double updatedTotal = currentTotal + amount;
      return Transaction.success(updatedTotal);
    });

    // refresh local state (not strictly necessary because listener will fire, but safe)
    fetchExpenses();
  }
}
