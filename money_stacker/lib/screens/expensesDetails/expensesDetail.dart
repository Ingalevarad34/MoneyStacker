import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpensesDetailScreen extends StatefulWidget {
  Map<String, dynamic> data = {};
  ExpensesDetailScreen({super.key, required this.data});

  @override
  State<ExpensesDetailScreen> createState() => _ExpensesDetailScreenState(data);
}

class _ExpensesDetailScreenState extends State<ExpensesDetailScreen> {
  Map<String, dynamic> data = {};
  _ExpensesDetailScreenState(this.data);
  @override
  Widget build(BuildContext context) {
    // print("Check here ✅ : $data");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Expenses Details",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 12,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[200]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(4, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Item Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "${data['title']}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Divider(height: 24, thickness: 1.2, color: Colors.grey[300]),

                  Text(
                    "Item Description",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "${data['subtitle']}",
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  Divider(height: 24, thickness: 1.2, color: Colors.grey[300]),

                  Text(
                    "Item Amount",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "₹${data['amount']}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Divider(height: 24, thickness: 1.2, color: Colors.grey[300]),

                  Text(
                    "Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.parse(data['date'])),
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  Divider(height: 24, thickness: 1.2, color: Colors.grey[300]),

                  SizedBox(height: 6),
                  Text(
                    "Time",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    "${data['time']}",
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
