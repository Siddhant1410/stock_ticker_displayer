import 'package:flutter/material.dart';
import 'stock_service.dart';

class StockDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stock;

  const StockDetailsScreen({Key? key, required this.stock}) : super(key: key);

  @override
  _StockDetailsScreenState createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> {
  final StockService _stockService = StockService();
  final Color darkBlue = const Color(0xFF091525);
  final Color lightBlue = const Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    final bool isPositive = widget.stock['priceDifference']?.startsWith('+') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stock['ticker'] ?? 'Stock Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkBlue, lightBlue],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stock Header Card
              // Replace your current header Card with this:
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9, // Adjust this value
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          widget.stock['name'] ?? widget.stock['ticker'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${widget.stock['latestPrice'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.stock['priceDifference'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              // Stock Details Section
              Text(
                'Stock Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              _buildDetailCard(
                children: [
                  _buildDetailRow("Open Price", widget.stock['openPrice']),
                  _buildDetailRow("Close Price", widget.stock['closePrice']),
                  _buildDetailRow("High Price", widget.stock['highPrice']),
                  _buildDetailRow("Low Price", widget.stock['lowPrice']),
                  _buildDetailRow("Volume", widget.stock['volume']),
                ],
              ),
              SizedBox(height: 50),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.send, color: Colors.white),
                    label: Text('Send to ESP', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _stockService.sendStockDataToESP(
                      widget.stock['ticker'],
                      widget.stock['latestPrice'],
                      widget.stock['priceDifference'],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 250),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}