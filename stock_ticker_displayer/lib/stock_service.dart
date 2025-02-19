import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String dhanApiUrl = 'https://api.dhan.co/market/quote/';
  final String accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJkaGFuIiwicGFydG5lcklkIjoiIiwiZXhwIjoxNzQyNDQ5MjcwLCJ0b2tlbkNvbnN1bWVyVHlwZSI6IlNFTEYiLCJ3ZWJob29rVXJsIjoiIiwiZGhhbkNsaWVudElkIjoiMTEwNjM0NzAwNSJ9.DGneSi3Q3eP_c_50D9zB6HNhEppZKoRMTS1MOzDpkEJCbifK0dWEekoo0-_1Klh-gWfy3wBRRGOSH21rxHX3Dg"; // Replace with actual Dhan API key

  // Fetch stock data by ticker from Dhan API
  Future<Map<String, dynamic>> fetchStockData(String ticker) async {
    final Uri url = Uri.parse('$dhanApiUrl$ticker');

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "access-token": accessToken, // Dhan requires only access-token
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'ticker': ticker,
          'latestPrice': data['lastTradedPrice']?.toString() ?? 'N/A',
          'priceDifference': data['change']?.toString() ?? 'N/A',
          'openPrice': data['dayHigh']?.toString() ?? 'N/A',
          'closePrice': data['dayLow']?.toString() ?? 'N/A',
          'highPrice': data['dayHigh']?.toString() ?? 'N/A',
          'lowPrice': data['dayLow']?.toString() ?? 'N/A',
          'volume': data['totalTradedVolume']?.toString() ?? 'N/A',
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
      } else {
        print('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending data to ESP: $e');
    }
  }

  // Fetch historical data for charts
  Future<List<double>> fetchHistoricalData(String ticker) async {
    final Uri url = Uri.parse("https://api.dhan.co/charts/historical");

    final Map<String, dynamic> requestBody = {
      "securityId": ticker, // Stock Symbol
      "exchangeSegment": "BSE_CURRENCY", // Change to BSE if needed
      "instrument": "EQUITY",
      "startTime": DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
      "endTime": DateTime.now().toIso8601String()
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "access-token": accessToken,
        },
        body: jsonEncode(requestBody),
      );

      print("Dhan Historical Data Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? candles = data['data']?['candles']; // Extract candle data

        if (candles == null || candles.isEmpty) {
          print("No historical data available for $ticker.");
          return [];
        }

        return candles.map<double>((candle) => (candle[4] as num).toDouble()).toList(); // Close prices
      } else {
        print("Failed to fetch historical data: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching historical data: $e");
      return [];
    }
  }



  // Fetch stock suggestions by name
  Future<List<Map<String, String>>?> fetchStockSuggestions(String query) async {
    final Uri url = Uri.parse('https://api.dhan.co/search/stocks?q=$query');

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "access-token": accessToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final suggestions = data['stocks'] as List;

        return suggestions.map((stock) {
          return {
            'name': (stock['companyName'] ?? stock['symbol'] ?? 'Unknown').toString(),
            'ticker': (stock['symbol'] ?? 'Unknown').toString(),
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
