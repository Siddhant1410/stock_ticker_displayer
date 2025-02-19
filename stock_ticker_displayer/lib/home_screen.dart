import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'stock_service.dart';
import 'stock_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _tickerController = TextEditingController();
  final StockService _stockService = StockService();

  List<Map<String, dynamic>> watchlist = [];
  List<dynamic> searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['watchlist'] != null) {
          final List<dynamic> storedWatchlist = doc.data()?['watchlist'];
          setState(() {
            watchlist = storedWatchlist.map((item) => Map<String, dynamic>.from(item)).toList();
          });
        }
      }
    } catch (e) {
      print("Error loading watchlist: $e");
    }
  }

  Future<void> _saveWatchlist() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'watchlist': watchlist,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error saving watchlist: $e");
    }
  }

  Future<void> searchStocksByName(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://query1.finance.yahoo.com/v1/finance/search?q=$query'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = data['quotes'] ?? [];
        });
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      print("Error searching stocks: $e");
      setState(() => searchResults = []);
    }
  }

  Future<void> fetchStockData(String ticker) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$ticker'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final quote = result['indicators']['quote'][0];

        final double regularMarketPrice = meta['regularMarketPrice']?.toDouble() ?? 0.0;
        final double openPrice = quote['open'][0];
        final double? closePrice = (quote['close'] != null && quote['close'].isNotEmpty)
            ? (quote['close'][0]?.toDouble())
            : null;

        // Calculate price difference/change
        final String priceDifference = (closePrice! - openPrice).toStringAsFixed(2);
        final String priceChange = closePrice > openPrice ? '+$priceDifference' : priceDifference;

        final double highPrice = (quote?['high'] != null && quote['high'].isNotEmpty)
            ? quote['high'][0]
            : 0.0;
        final double lowPrice = (quote?['low'] != null && quote['low'].isNotEmpty)
            ? quote['low'][0]
            : 0.0;
        int  volume = (quote?['volume'] != null && quote['volume'].isNotEmpty)
            ? quote['volume'][0]
            : 0.0;

        final stock = {
          'ticker': ticker,
          'name': meta['symbol'] ?? 'Unknown',
          'latestPrice': regularMarketPrice.toStringAsFixed(2),
          'openPrice': openPrice.toStringAsFixed(2) ?? 'N/A',
          'closePrice': closePrice.toStringAsFixed(2) ?? 'N/A',
          'priceDifference': priceChange,'highPrice': highPrice.toStringAsFixed(2),
          'lowPrice': lowPrice.toStringAsFixed(2),
          'volume': volume.toStringAsFixed(0),
        };

        setState(() {
          watchlist.add(stock);
          _tickerController.clear();
        });

        _saveWatchlist();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Stock added to watchlist!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch stock data.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void deleteStock(int index) {
    setState(() {
      watchlist.removeAt(index);
    });
    _saveWatchlist();
  }

  void sendDataToESP(Map<String, dynamic> stock) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data sent to ESP: ${stock['ticker']}")),
    );
  }

  Future<void> sendStockData(Map<String, dynamic> stock) async {
    try {
      await _stockService.sendStockDataToESP(
        stock['ticker'],
        stock['latestPrice'],
        stock['priceDifference'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stock data sent to ESP!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send stock data: $e")),
      );
    }
  }

  void logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tickerController,
              decoration: InputDecoration(
                labelText: "Enter Stock Name or Ticker",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => searchStocksByName(value), // Trigger search as user types
            ),
            if (searchResults.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final stock = searchResults[index];
                    return ListTile(
                      title: Text(stock['shortname'] ?? stock['symbol']),
                      subtitle: Text(stock['symbol']),
                      onTap: () {
                        fetchStockData(stock['symbol']);
                        setState(() => searchResults = []);
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: () => fetchStockData(_tickerController.text.trim()),
              child: Text("Fetch Stock Data"),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: watchlist.length,
                itemBuilder: (context, index) {
                  final stock = watchlist[index];
                  return Card(
                    child: ListTile(
                      title: Text("${stock['ticker']}"),
                      subtitle: Text("Price: ${stock['latestPrice'] ?? 'N/A'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.send),
                            onPressed: () => sendStockData(stock),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deleteStock(index),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockDetailsScreen(stock: stock),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
