import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:news_app/charts/portfolio_pie_charts.dart';
import 'package:news_app/dialogs/add_stock_dialog.dart';
import 'package:news_app/dialogs/show_delete_dialog.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:news_app/services/portfolio/porfolio_provider.dart';
import 'package:news_app/view/stock_detail_view.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(this.toString());
}

class PortfolioViewV2 extends ConsumerStatefulWidget {
  const PortfolioViewV2({super.key});

  @override
  ConsumerState<PortfolioViewV2> createState() => _PortfolioViewV2State();
}

class _PortfolioViewV2State extends ConsumerState<PortfolioViewV2> {
  @override
  void initState() {
    super.initState();

    final email = AuthService.firebase().currentUser?.email;
    if (email != null) {
      Future.microtask(() async {
        await ref.read(portfolioProvider(email).notifier).loadHoldings();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.firebase().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    final portfolio = ref.watch(portfolioProvider(currentUser.email));
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    );

    return portfolio.errorMessage != null
        ? Scaffold(
            body: Center(
              child: Text(
                portfolio.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          )
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final newHolding = await showAddStockDialog(context);
                if (newHolding != null) {
                  ref
                      .read(portfolioProvider(currentUser.email).notifier)
                      .addHolding(newHolding);
                }
              },
              tooltip: 'Add Stock',
              child: const Icon(Icons.add),
            ),
            body: SingleChildScrollView(
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

                  // Pie Chart
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

                  // composite of portfolio
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: portfolio.holdings.length,
                    itemBuilder: (context, index) {
                      final holding = portfolio.holdings[index];
                      return Dismissible(
                        key: Key(holding.symbol),
                        direction: DismissDirection.down,
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
                          ref
                              .read(
                                portfolioProvider(currentUser.email).notifier,
                              )
                              .deleteHolding(holding.symbol);
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
