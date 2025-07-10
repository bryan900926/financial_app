import 'package:flutter/material.dart';
import 'package:news_app/charts/portfolio_pie_charts.dart';
import 'package:news_app/database/portfolio_db.dart';
import 'package:news_app/dialogs/add_stock_dialog.dart';
import 'package:news_app/dialogs/show_delete_dialog.dart';
import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:news_app/services/auth/auth_user.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:news_app/view/stock_detail_view.dart';

class PortfolioView extends StatefulWidget {
  const PortfolioView({super.key});

  @override
  _PortfolioViewState createState() => _PortfolioViewState();
}

class _PortfolioViewState extends State<PortfolioView> {
  final portfolioDbHelper = PortfolioDbHelper.instance;
  late ValueNotifier<PortfolioStatus> portfolioNotifier = ValueNotifier(
    PortfolioStatus.fmp(),
  );
  final AuthUser? currentUser = AuthService.firebase().currentUser;

  @override
  void initState() {
    super.initState();
    _initializePortfolio();
  }

  Future<void> _initializePortfolio() async {
    portfolioNotifier.value.holdings = await portfolioDbHelper.getAllHoldings(
      currentUser!.email,
    );
    await portfolioNotifier.value.updatePortfolioData();
    if (portfolioNotifier.value.holdings.isEmpty){
      portfolioNotifier.value.errorMessage = "Please construct your portfolio with plus bottom at down right side";
    }
    else {
      portfolioNotifier.value.errorMessage = null;
    }
    portfolioNotifier.value = PortfolioStatus(
      totalValue: portfolioNotifier.value.totalValue,
      provider: portfolioNotifier.value.provider,
      holdings: portfolioNotifier.value.holdings,
      errorMessage: portfolioNotifier.value.errorMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newHolding = await showAddStockDialog(context);
          if (newHolding != null) {
            await portfolioDbHelper.insertStock(newHolding, currentUser!.email);

            _initializePortfolio();
          }
        },
        tooltip: 'Add Stock',
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: portfolioNotifier,
        builder: (context, value, child) {
          final error_message = portfolioNotifier.value.errorMessage;
          if (error_message != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $error_message',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // portfolio total value
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
                          currencyFormatter.format(
                            portfolioNotifier.value.totalValue,
                          ),
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

                //Pie Chart
                if (portfolioNotifier.value.holdings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: generatePieChartSections(
                            portfolioNotifier.value,
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ),
                // composite of portfolio
                ListView.builder(
                  shrinkWrap: true, // Important for nested scrolling
                  physics: const NeverScrollableScrollPhysics(), // Important
                  itemCount: portfolioNotifier.value.holdings.length,
                  itemBuilder: (context, index) {
                    final holding = portfolioNotifier.value.holdings[index];
                    return Dismissible(
                      key: Key(holding.symbol), // Unique key for each item
                      direction:
                          DismissDirection.down, // Swipe from right to left
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
                        await portfolioDbHelper.deleteStock(
                          holding.symbol,
                          currentUser!.email,
                        );
                        _initializePortfolio();
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
          );
        },
      ),
    );
  }
}
