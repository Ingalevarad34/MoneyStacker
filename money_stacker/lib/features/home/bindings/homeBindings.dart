// home_binding.dart
import 'package:get/get.dart';
import 'package:money_stacker/features/home/controllers/homeController.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
