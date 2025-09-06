import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:money_stacker/features/expenses/controllers/addExpenses.dart';

class AddExpenseView extends GetView<AddExpenseController> {
  const AddExpenseView({super.key});

  @override
  Widget build(BuildContext context) {
    final AddExpenseController controller=Get.put(AddExpenseController());

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
                controller: controller.amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "How much?",
                  prefixText: "\₹ ",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Obx(() {
                return DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  items: controller.categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => controller.selectedCategory.value = val,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Description
              TextField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker
              Obx(() {
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  title: const Text("Date & Time"),
                  subtitle: Text(DateFormat("dd MMM yyyy, hh:mm a").format(controller.selectedDate.value)),
                  trailing: const Icon(Icons.calendar_today, color: Colors.black),
                  onTap: () => controller.pickDateTime(context),
                );
              }),
              const SizedBox(height: 16),

              // Attachment
              Obx(() {
                final File? file = controller.attachment.value;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  title: const Text("Add Attachment"),
                  subtitle: file != null ? Text(file.path.split('/').last) : const Text("No file selected"),
                  trailing: const Icon(Icons.attach_file, color: Colors.black),
                  onTap: () => controller.pickAttachment(context),
                );
              }),
              Obx(() {
                final File? file = controller.attachment.value;
                if (file == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(file, height: 120, fit: BoxFit.cover),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
