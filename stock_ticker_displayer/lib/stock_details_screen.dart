import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'stock_service.dart';

class StockDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stock;

  const StockDetailsScreen({Key? key, required this.stock}) : super(key: key);

  @override
  _StockDetailsScreenState createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> {
  final StockService _stockService = StockService();
  List<FlSpot> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData(widget.stock['ticker']);
  }

  Future<void> fetchChartData(String ticker) async {
    try {
      final historicalData = await _stockService.fetchHistoricalData(ticker);

      setState(() {
        chartData = historicalData
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching chart data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stock['ticker'] ?? 'Stock Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Information
            _buildStockInfo("Latest Price", widget.stock['latestPrice']),
            _buildStockInfo("Price Change", widget.stock['priceDifference'],
                color: widget.stock['priceDifference'].startsWith('+')
                    ? Colors.green
                    : Colors.red),
            _buildStockInfo("Open", widget.stock['openPrice']),
            _buildStockInfo("Close", widget.stock['closePrice']),
            _buildStockInfo("High", widget.stock['highPrice']),
            _buildStockInfo("Low", widget.stock['lowPrice']),
            _buildStockInfo("Volume", widget.stock['volume']),

            SizedBox(height: 16),

            // Chart Section
            Text(
              'Stock Performance (1 Month)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
        Container(
          height: 200,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : chartData.isEmpty
              ? Center(child: Text("No chart data available"))
              : LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String title, String? value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$title: ${value ?? 'N/A'}",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
