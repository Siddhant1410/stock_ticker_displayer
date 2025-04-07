import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'stock_service.dart';
import 'stock_details_screen.dart';
import 'order_book_screen.dart';
import 'package:intl/intl.dart';
const Color darkBlue = Color(0xFF091525);

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
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      String fromDate = DateFormat('yyyy-MM-dd').format(picked.start);
      String toDate = DateFormat('yyyy-MM-dd').format(picked.end);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderBookScreen(fromDate: fromDate, toDate: toDate),
        ),
      );
    }
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
          _showSearchField = false;
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

  Widget _buildIndexCard() {
    if (watchlist.length < 2) return SizedBox.shrink();

    final firstStock = watchlist[0] ;
    final secondStock = watchlist[1] ;

    // Parse the price difference to determine color (green for positive, red for negative)
    final firstPriceDiff = firstStock['priceDifference'] ?? '0';
    final secondPriceDiff = secondStock['priceDifference'] ?? '0';

    final firstIsPositive = firstPriceDiff.startsWith('+');
    final secondIsPositive = secondPriceDiff.startsWith('+');

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              firstStock['ticker'] + "                                            " + secondStock ['ticker'] ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),
            Text(
              firstStock['latestPrice'] + "                       " +secondStock['latestPrice']  ?? 'N/A',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              firstStock['priceDifference'] + "                                          " +secondStock['priceDifference'] ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                color: firstIsPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TickX", style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearchField = !_showSearchField;
                if (!_showSearchField) {
                  searchResults = [];
                  _tickerController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            tooltip: "View Order Book",
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top 30% colored section - always maintains height
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.25,
            color: darkBlue,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: watchlist.length >= 2
                  ? _buildIndexCard()
                  : Center(
                child: Text(
                  "Add at least 2 stocks to see the index card",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          // The rest of your content (70%)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_showSearchField) ...[
                    TextField(
                      controller: _tickerController,
                      decoration: InputDecoration(
                        labelText: "Enter Stock Name or Ticker",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () =>
                              fetchStockData(_tickerController.text.trim()),
                        ),
                      ),
                      onChanged: (value) => searchStocksByName(value),
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
                              title: Text(
                                  stock['shortname'] ?? stock['symbol']),
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
                  ],
                  Expanded(
                    child: watchlist.isEmpty
                        ? Center(
                      child: Text(
                        "Your watchlist is empty\nAdd some stocks to get started",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      itemCount: watchlist.length,
                      itemBuilder: (context, index) {
                        final stock = watchlist[index];
                        return Card(
                          child: ListTile(
                            title: Text("${stock['ticker']}"),
                            subtitle: Text(
                                "Price: ${stock['latestPrice'] ?? 'N/A'}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () => sendStockData(stock),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteStock(index),
                                )
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
          ),
        ],
      ),
    );
  }
  }