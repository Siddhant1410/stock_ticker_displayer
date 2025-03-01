import 'package:flutter/material.dart';
import 'dhan_service.dart'; // Ensure this service is correctly implemented

class OrderBookScreen extends StatefulWidget {
  @override
  _OrderBookScreenState createState() => _OrderBookScreenState();
}

class _OrderBookScreenState extends State<OrderBookScreen> {
  final DhanService _dhanService = DhanService();
  List<dynamic> orders = [];
  bool isLoading = true;

  String get accessToken => _dhanService.accessToken;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }


  Future<void> fetchOrders() async {
    try {
      List<Map<String, dynamic>> data = await _dhanService.getOrderBook();
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

  Future<void> fetchPastTrades() async {
    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> pastTrades = await _dhanService.getOrderBook();  // ✅ Call function here

      // setState(() {
      //   orderBook = pastTrades;
      // });

      if (pastTrades.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ No past trades found!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 Error fetching past trades: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Past Trades")),
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
              // trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
