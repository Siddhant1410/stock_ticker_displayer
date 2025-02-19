import 'dart:convert';
import 'package:http/http.dart' as http;

class DhanService {
  final String baseUrl = "https://api.dhan.co";
  final String accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJkaGFuIiwicGFydG5lcklkIjoiIiwiZXhwIjoxNzQyNDQ5MjcwLCJ0b2tlbkNvbnN1bWVyVHlwZSI6IlNFTEYiLCJ3ZWJob29rVXJsIjoiIiwiZGhhbkNsaWVudElkIjoiMTEwNjM0NzAwNSJ9.DGneSi3Q3eP_c_50D9zB6HNhEppZKoRMTS1MOzDpkEJCbifK0dWEekoo0-_1Klh-gWfy3wBRRGOSH21rxHX3Dg"; // Replace with actual token

  Future<Map<String, dynamic>> getStockData(String ticker) async {
    final Uri url = Uri.parse("$baseUrl/market/quote/$ticker");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "access-token": accessToken, // No client-id required
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to fetch stock data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      return {'error': 'Failed to fetch stock data'};
    }
  }

  Future<List<dynamic>> getOrderBook() async {
    final String baseUrl = "https://api.dhan.co/v2/orders";
    final Uri url = Uri.parse(baseUrl);

    try {
      final response = await http.get(url, headers: {
        "Content-Type": "application/json",
        "access-token": accessToken
      });

      if (response.statusCode == 200) {
        return json.decode(response.body)['orders'];
      } else {
        throw Exception("Failed to fetch order book");
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

}
