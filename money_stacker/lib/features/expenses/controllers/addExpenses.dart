// add_expense_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum MonthKeying { zeroBased, oneBased }

class AddExpenseController extends GetxController {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final RxnString selectedCategory = RxnString();
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<File> attachment = Rxn<File>();

  final List<String> categories = [
    "Food",
    "Medicine",
    "Transport",
    "Shopping",
    "Bills",
    "Entertainment",
    "Shared",
    "Other"
  ];

  late final DatabaseReference dbRef;
  late final String userId;
  final int currentYear = DateTime.now().year;

  MonthKeying _yearKeying = MonthKeying.oneBased;

  @override
  void onInit() {
    super.onInit();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? 'guest';
    dbRef = FirebaseDatabase.instance.ref("expenses").child(userId);

    // Detect existing year's keying (zero-based vs one-based)
    _detectYearKeying();
  }

  @override
  void onClose() {
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  // ---------- Helpers ----------
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

  MonthKeying _detectKeyingFromRaw(dynamic rawYear) {
    if (rawYear is List) return MonthKeying.zeroBased;
    if (rawYear is Map) {
      final keys = rawYear.keys.map((k) => k.toString()).toList();
      if (keys.contains('0')) return MonthKeying.zeroBased;
      if (keys.any((k) => k == '1' || k == '12')) return MonthKeying.oneBased;
    }
    return MonthKeying.oneBased;
  }

  Future<void> _detectYearKeying() async {
    try {
      final snap = await dbRef.child(currentYear.toString()).get();
      _yearKeying = _detectKeyingFromRaw(snap.value);
    } catch (_) {
      _yearKeying = MonthKeying.oneBased;
    }
  }

  // ---------- UI-interaction helpers (require context) ----------
  Future<void> pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate.value),
    );
    if (pickedTime == null) return;

    selectedDate.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> pickAttachment(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  final f = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.of(ctx).pop(f);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  final f = await picker.pickImage(source: ImageSource.camera);
                  Navigator.of(ctx).pop(f);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        );
      },
    );

    if (file != null) {
      attachment.value = File(file.path);
    }
  }

  // ---------- Submit (same functionality as your original page) ----------
  Future<void> submit(BuildContext context) async {
    final amountRaw = amountController.text.trim();
    final double? amount = double.tryParse(amountRaw);

    if (amount == null || amount <= 0.0 || selectedCategory.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount and select a category")),
      );
      return;
    }

    final int month = selectedDate.value.month; // 1..12

    try {
      // ensure we know the keying
      await _detectYearKeying();

      final int monthKeyForWrite = _yearKeying == MonthKeying.zeroBased ? month - 1 : month;
      final DatabaseReference monthRef = dbRef.child('$currentYear/$monthKeyForWrite');
      final DatabaseReference pushRef = monthRef.child('items').push();

      final expenseData = {
        "title": selectedCategory.value,
        "subtitle": descriptionController.text.trim(),
        "amount": amount,
        "time": DateFormat.Hm().format(selectedDate.value),
        "date": selectedDate.value.toIso8601String(),
        "attachment": attachment.value?.path,
      };

      // Save item
      await pushRef.set(expenseData);

      // Update monthly total safely using a transaction
      await monthRef.child('total').runTransaction((Object? currentData) {
        double currentTotal = 0.0;
        if (currentData != null) currentTotal = (currentData as num).toDouble();
        double updatedTotal = currentTotal + amount;
        return Transaction.success(updatedTotal);
      });

      // Return success to caller (keeps same behavior as original page)
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save expense: $e")),
      );
    }
  }
}
