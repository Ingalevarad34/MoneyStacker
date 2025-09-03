// add_expense_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? selectedCategory;
  DateTime selectedDate = DateTime.now();
  File? attachment;

  final List<String> categories = [
    "Food",
    "Transport",
    "Shopping",
    "Bills",
    "Entertainment",
    "Other"
  ];

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("expenses");
  final int currentYear = DateTime.now().year;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate),
    );
    if (pickedTime == null) return;

    setState(() {
      selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickAttachment() async {
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
      setState(() {
        attachment = File(file.path);
      });
    }
  }

  Future<void> _submit() async {
    final amountRaw = _amountController.text.trim();
    final double? amount = double.tryParse(amountRaw);

    if (amount == null || amount <= 0.0 || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid amount and select a category")),
      );
      return;
    }

    final int month = selectedDate.month; // 1..12

    try {
      final DatabaseReference monthRef = dbRef.child('$currentYear/$month');
      final DatabaseReference pushRef = monthRef.child('items').push();

      final expenseData = {
        "title": selectedCategory,
        "subtitle": _descriptionController.text.trim(),
        "amount": amount,
        "time": DateFormat.Hm().format(selectedDate),
        "date": selectedDate.toIso8601String(),
        // NOTE: we store a local path here; consider uploading attachments to Firebase Storage and saving URL
        "attachment": attachment?.path,
      };

      // Save item
      await pushRef.set(expenseData);

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

      // Return success to caller (HomePage)
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Save failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save expense: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expense"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "How much?",
                  prefixText: "\$ ",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                title: const Text("Date & Time"),
                subtitle: Text(
                    DateFormat("dd MMM yyyy, hh:mm a").format(selectedDate)),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 16),

              // Attachment
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                title: const Text("Add Attachment"),
                subtitle: attachment != null
                    ? Text(attachment!.path.split('/').last)
                    : const Text("No file selected"),
                trailing: const Icon(Icons.attach_file, color: Colors.blue),
                onTap: _pickAttachment,
              ),
              if (attachment != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.file(attachment!, height: 120, fit: BoxFit.cover),
                ),
              ],

              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
