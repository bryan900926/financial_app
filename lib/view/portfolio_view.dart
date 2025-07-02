import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:news_app/auth_service/firebase.dart';
import 'package:news_app/charts/portfolio_charts.dart';
import 'package:news_app/database/portfolio_db.dart';
import 'package:news_app/dialogs/add_stock_dialog.dart';
import 'package:news_app/dialogs/show_delete_dialog.dart';
import 'package:news_app/portfolio_service/add_portfolio.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:news_app/view/stock_detail_view.dart';

class PortfolioView extends StatefulWidget {
  const PortfolioView({super.key});

  @override
  _PortfolioViewState createState() => _PortfolioViewState();
}

class _PortfolioViewState extends State<PortfolioView> {
  final portfolio_Db_Helper = PortfolioDbHelper.instance;
  late PortfolioStatus portfolio = PortfolioStatus(holdings: [], totalValue: 0);
  bool _isLoading = true;
  final User? currentUser = FirebaseAuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _updatePortfolioData();
  }

  Future<void> _updatePortfolioData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final holdingsFromDb = await portfolio_Db_Helper.getAllHoldings(currentUser!.email!);
    if (holdingsFromDb.isEmpty) {
      if (!mounted) return;
      setState(() {
        portfolio.holdings = [];
        portfolio.totalValue = 0;
        _isLoading = false;
      });
      return;
    }
    portfolio.holdings = holdingsFromDb;
    // Call the method on the portfolio object to fetch prices.
    await portfolio.fetchPortfolioPrices();

    if (!mounted) return;
    // Call setState to rebuild the UI with the updated data in the portfolio object.
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleAddStock() async {
    // Await the result from the dialog. It will be a StockHolding or null.
    final newHolding = await showAddStockDialog(context);

    // If the user added a stock (result is not null)
    if (newHolding != null) {
      setState(() {
        final existingHoldingIndex = portfolio.holdings.indexWhere(
          (h) => h.symbol == newHolding.symbol,
        );

        if (existingHoldingIndex != -1) {
          // If the stock already exists, update the share count
          final existing = portfolio.holdings[existingHoldingIndex];
          portfolio.holdings[existingHoldingIndex] = StockHolding(
            symbol: existing.symbol,
            companyName: existing.companyName,
            shares: existing.shares + newHolding.shares,
          );
          portfolio_Db_Helper.updateStock(existing, currentUser!.email!);
        } else {
          // Otherwise, add the new stock to the list
          portfolio.holdings.add(newHolding);
          portfolio_Db_Helper.insertStock(newHolding, currentUser!.email!);
        }
      });
      // Refresh all prices and update the UI
      _updatePortfolioData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddStock,
        tooltip: 'Add Stock',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : portfolio.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${portfolio.errorMessage!}',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              // MODIFIED: Added to prevent overflow with chart
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Total Portfolio Value',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(portfolio.totalValue),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // MODIFIED: Added the Pie Chart section
                  if (portfolio.holdings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: generatePieChartSections(portfolio),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ),

                  ListView.builder(
                    shrinkWrap: true, // Important for nested scrolling
                    physics: const NeverScrollableScrollPhysics(), // Important
                    itemCount: portfolio.holdings.length,
                    itemBuilder: (context, index) {
                      final holding = portfolio.holdings[index];
                      return Dismissible(
                        key: Key(holding.symbol), // Unique key for each item
                        direction: DismissDirection
                            .endToStart, // Swipe from right to left
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          final bool? res = await showDeleteDialog(
                            context,
                            holding.symbol,
                          );
                          return res ?? false;
                        },
                        onDismissed: (direction) async {
                          await portfolio_Db_Helper.deleteStock(holding.symbol, currentUser!.email!);
                          _updatePortfolioData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${holding.symbol} removed from portfolio',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6.0,
                          ),
                          child: ListTile(
                            title: Text(
                              holding.symbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StockDetailPage(
                                    stockSymbol: holding.symbol,
                                  ),
                                ),
                              );
                            },
                            subtitle: Text(holding.companyName),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormatter.format(holding.totalValue),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${holding.shares} shares',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
