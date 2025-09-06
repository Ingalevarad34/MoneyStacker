// home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money_stacker/features/expenses/views/addExpensesView.dart';
import 'package:money_stacker/features/home/controllers/homeController.dart';
import 'package:money_stacker/features/home/widgets/homeWidgets.dart';
import 'package:money_stacker/screens/addExpenses/addExpenses.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the controller from GetView. Ensure HomeBinding or Get.put(HomeController()) is executed earlier.
    final HomeController controller = Get.put(HomeController());
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
          // DO NOT use const here because MonthDropdown uses Obx internally
          child: MonthDropdown(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total card: only the amount text is reactive
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expenses",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      // Wrap only the reactive text in Obx
                      Obx(
                        () => Text(
                          "₹${controller.totalExpense.value.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // These widgets have internal Obx — do NOT instantiate them as const
            ExpensesChart(),
            const SizedBox(height: 20),

            FilterChips(),
            const SizedBox(height: 20),

            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // TransactionsList already uses Obx internally — no outer Obx needed and don't use const
            Expanded(child: TransactionsList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final result = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseView()),
          );
          if (result == true) {
            // listener in controller should update automatically, but call fetchExpenses to be safe
            controller.fetchExpenses();
            // use Get.snackbar if you prefer getx snackbar
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Expense added')));
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
