import 'package:flutter/material.dart';

class StockDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> stock;

  StockDetailsScreen({required this.stock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${stock['ticker']} Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "${stock['ticker']} (${stock['name'] ?? 'N/A'})",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            DetailRow(title: "Latest Price", value: "${stock['latestPrice']}", isHighlighted: true),
            DetailRow(title: "Price Difference", value: "${stock['priceDifference'] ?? 'N/A'}"),
            DetailRow(title: "Open Price", value: "${stock['openPrice'] ?? 'N/A'}"),
            DetailRow(title: "Close Price", value: "${stock['closePrice'] ?? 'N/A'}"),
            DetailRow(title: "High Price", value: "${stock['highPrice'] ?? 'N/A'}"),
            DetailRow(title: "Low Price", value: "${stock['lowPrice'] ?? 'N/A'}"),
            DetailRow(title: "Volume", value: "${stock['volume'] ?? 'N/A'}"),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Back"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isHighlighted;

  const DetailRow({
    required this.title,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}