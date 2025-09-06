// add_expense_binding.dart
import 'package:get/get.dart';
import 'package:money_stacker/features/expenses/controllers/addExpenses.dart';

class AddExpenseBinding extends Bindings {
  @override
  void dependencies() {
    // lazy put controller when page is opened; set fenix true if you want it recreated after removal
    Get.lazyPut<AddExpenseController>(() => AddExpenseController());
  }
}
