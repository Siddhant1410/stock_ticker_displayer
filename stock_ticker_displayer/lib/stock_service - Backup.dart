import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String yahooFinanceUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';

  // Fetch stock data by ticker
  Future<Map<String, dynamic>> fetchStockData(String ticker) async {
    final String baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';
    final Uri url = Uri.parse('$baseUrl$ticker?interval=1d&range=1d');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Navigate through JSON to extract relevant fields
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final quote = result['indicators']['quote'][0];

        final double regularMarketPrice = meta['regularMarketPrice'] ?? 0.0;
        final double? openPrice = (quote['open'] != null && quote['open'].isNotEmpty)
            ? quote['open'][0]
            : null;
        final double? closePrice = (quote['close'] != null && quote['close'].isNotEmpty)
            ? quote['close'][0]
            : null;
        final double? highPrice = (quote['high'] != null && quote['high'].isNotEmpty)
            ? quote['high'][0]
            : null;
        final double? lowPrice = (quote['low'] != null && quote['low'].isNotEmpty)
            ? quote['low'][0]
            : null;
        final double? volume = (quote['volume'] != null && quote['volume'].isNotEmpty)
            ? quote['volume'][0]
            : null;

        // Calculate price difference if both open and close are available
        final String? priceDifference = (openPrice != null && closePrice != null)
            ? (closePrice - openPrice).toStringAsFixed(2)
            : null;
        final String? priceChange = (priceDifference != null && closePrice! > openPrice!)
            ? '+$priceDifference'
            : priceDifference;

        return {
          'ticker': ticker,
          'latestPrice': regularMarketPrice.toStringAsFixed(2),
          'priceDifference': priceChange,
          'openPrice': openPrice?.toStringAsFixed(2) ?? 'N/A',
          'closePrice': closePrice?.toStringAsFixed(2) ?? 'N/A',
          'highPrice': highPrice?.toStringAsFixed(2) ?? 'N/A',
          'lowPrice': lowPrice?.toStringAsFixed(2) ?? 'N/A',
          'volume': volume?.toStringAsFixed(0) ?? 'N/A',
        };
      } else {
        throw Exception('Failed to fetch stock data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock data: $e');
      return {'error': 'Failed to fetch stock data'};
    }
  }

  // Send stock data to ESP
  Future<void> sendStockDataToESP(String ticker, String latestPrice, String priceDifference) async {
    if (ticker.isEmpty || latestPrice.isEmpty || priceDifference.isEmpty) {
      print('Error: One or more fields are empty. Cannot send data to ESP.');
      return;
    }

    final Uri espUrl = Uri.parse('http://192.168.1.13/update-stock');

    try {
      final response = await http.post(
        espUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticker': ticker,
          'latestPrice': latestPrice,
          'priceDifference': priceDifference,
        }),
      );

      if (response.statusCode == 200) {
        print('Data sent successfully to ESP');
        // Provide user feedback
      } else {
        print('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data to ESP: $e');
    }
  }


  // Fetch stock suggestions by query
  Future<List<Map<String, String>>> fetchStockSuggestions(String query) async {
    final Uri url = Uri.parse('https://query2.finance.yahoo.com/v1/finance/search?q=$query');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['quotes'] as List;

        return suggestions.map((stock) {
          return {
            'name': (stock['shortname'] ?? stock['symbol']).toString(),
            'ticker': stock['symbol'].toString(),
          };
        }).toList();

      } else {
        throw Exception('Failed to fetch stock suggestions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock suggestions: $e');
      return [];
    }
  }
}
