import 'package:flutter/material.dart';
import 'dhan_service.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class OrderBookScreen extends StatefulWidget {
  final String fromDate;
  final String toDate;
  OrderBookScreen({required this.fromDate, required this.toDate});

  @override
  _OrderBookScreenState createState() => _OrderBookScreenState();
}

class _OrderBookScreenState extends State<OrderBookScreen> {
  final DhanService _dhanService = DhanService();
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      List<Map<String, dynamic>> data = await _dhanService.getPastTrades(widget.fromDate, widget.toDate);
      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching orders: $e");
    }
  }

  Future<void> exportToCSV() async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ No data available to export!")),
      );
      return;
    }

    List<List<dynamic>> csvData = [
      ["Symbol", "Quantity", "Price", "Trade ID", "Date", "Type", "Transaction Type"]
    ];

    for (var order in orders) {
      csvData.add([
        order['customSymbol'] ?? 'N/A',
        order['tradedQuantity'] ?? 'N/A',
        order['tradedPrice'] ?? 'N/A',
        order['orderId'] ?? 'N/A',
        order['exchangeTime'] ?? 'N/A',
        order['orderType'] ?? 'N/A',
        order['transactionType'] ?? 'N/A'
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getDownloadsDirectory();
    final path = "${directory!.path}/orders.csv";
    final file = File(path);

    await file.writeAsString(csvString);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ CSV file saved at: $path")),
    );

    print("CSV file saved at: $path");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Past Trades"),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: "Export to CSV",
            onPressed: exportToCSV,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text("No orders available."))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                "Symbol: ${order['customSymbol'] ?? 'N/A'}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quantity: ${order['tradedQuantity'] ?? 'N/A'}"),
                  Text("Price: ₹${order['tradedPrice'] ?? 'N/A'}"),
                  Text("Trade ID: ${order['orderId'] ?? 'N/A'}"),
                  Text("Date: ${order['exchangeTime'] ?? 'N/A'}"),
                  Text("Type: ${order['orderType'] ?? 'N/A'}"),
                  Text("Transaction Type: ${order['transactionType'] ?? 'N/A'}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
