import 'dart:developer';

import 'package:flutter/scheduler.dart';
import 'package:news_app/api_key/api.dart';
import 'package:news_app/database/portfolio_db.dart';
import 'package:news_app/services/portfolio/fmp_portfolio_provider.dart';
import 'package:news_app/services/portfolio/portfolio_provider.dart';

// A result class to hold either the data or an error message.
class PortfolioStatus {
  double totalValue;
  PortfolioProvider provider;
  String? errorMessage;
  final portfolioDbHelper = PortfolioDbHelper.instance;
  List<StockHolding> holdings;

  PortfolioStatus({required this.totalValue, required this.provider, required this.holdings, required this.errorMessage});

  factory PortfolioStatus.fmp() => PortfolioStatus(
    totalValue: 0,
    provider: FmpPortfolioProvider(apiKey: apiPriceKey),
    holdings: [],
    errorMessage: null,
  );

  Future<Map<String, double>> fetchPortfolioPrices() => provider.getData(
    tickers: holdings.map((h) => h.symbol).toList(),
    dataName: "price",
  );

  Future<void> updatePortfolioData() async {
    log(holdings.map((h) => h.symbol).toList().toString());
    final infos = await fetchPortfolioPrices();
    totalValue = 0;
    for (var holding in holdings) {
      final ticker = holding.symbol;
      holding.currentPrice = infos[ticker] ?? 0.0;
      totalValue += holding.currentPrice * holding.shares;
    }
  }
}

class StockHolding {
  String symbol;
  int shares;
  double currentPrice;
  double get totalValue => shares * currentPrice;
  String companyName;

  StockHolding({
    required this.symbol,
    required this.shares,
    this.companyName = "",
    this.currentPrice = 0.0,
  });
}
