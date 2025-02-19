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

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }


  Future<void> fetchOrders() async {
    try {
      final data = await _dhanService.getOrderBook();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order Book")),
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
                "Symbol: ${order['securityId'] ?? 'N/A'}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quantity: ${order['quantity'] ?? 'N/A'}"),
                  Text("Price: ₹${order['averagePrice'] ?? 'N/A'}"),
                  Text(
                    "Status: ${order['orderStatus'] ?? 'N/A'}",
                    style: TextStyle(
                      color: order['orderStatus'] == 'COMPLETE'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}
