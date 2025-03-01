import 'dart:convert';
import 'package:http/http.dart' as http;

class DhanService {
  final String baseUrl = "https://api.dhan.co";
  final String accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJkaGFuIiwicGFydG5lcklkIjoiIiwiZXhwIjoxNzQwOTI4OTk1LCJ0b2tlbkNvbnN1bWVyVHlwZSI6IlNFTEYiLCJ3ZWJob29rVXJsIjoiIiwiZGhhbkNsaWVudElkIjoiMTEwMjY0MjU0OCJ9.KJ_K_ppDInqYP8OWI1SmU0hItrxD8_zU6wdvyI0iGwSd6S-e7t3INf6qyU9N5G8SrDKvN5QSKq-ZSS4APBkmxw"; // Replace with actual token

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

  Future<List<Map<String, dynamic>>> getOrderBook() async {
    final Uri url = Uri.parse("https://api.dhan.co/tradeHistory/2023-01-01/2025-03-01/1");

    try {
      final response = await http.get(
        url,
        headers: {
          "accept": "application/json",
          "access-token": accessToken, // Ensure this token is valid
        },
      );

      print("API Response Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body); // Allow any type

        if (data is List) {
          // API returns a list at root level
          return List<Map<String, dynamic>>.from(data); // Directly return it
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          // Handle cases where data might be inside another object
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print("Unexpected response format: $data");
          return [];
        }
      } else {
        print("Failed to fetch order book: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching order book: $e");
      return [];
    }
  }





}
