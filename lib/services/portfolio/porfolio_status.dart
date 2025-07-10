import 'package:news_app/api_key/api.dart';
import 'package:news_app/database/portfolio_db.dart';
import 'package:news_app/services/portfolio/fmp_portfolio_provider.dart';
import 'package:news_app/services/portfolio/price_retrevier.dart';

// A result class to hold either the data or an error message.
class PortfolioStatus {
  double totalValue;
  PriceRetrevier provider;
  String? errorMessage;
  final portfolioDbHelper = PortfolioDbHelper.instance;
  List<StockHolding> holdings;

  PortfolioStatus({
    required this.totalValue,
    required this.provider,
    required this.holdings,
    required this.errorMessage,
  });

  factory PortfolioStatus.fmp() => PortfolioStatus(
    totalValue: 0,
    provider: FmpPortfolioProvider(apiKey: apiPriceKey),
    holdings: [],
    errorMessage: null,
  );

  Future<StockHolding> addStockPriceToPortfolio({
    required String ticker,
    required int shares,
  }) async {
    try {
      final info = await provider.getData(
        holdings: [StockHolding(symbol: ticker, shares: shares)],
        dataName: "price",
      );
      info[0].shares = shares;
      return info[0];
    } catch (_) {
      rethrow;
    }
  }

  Future<List<StockHolding>> fetchPortfolioPrices() =>
      provider.getData(holdings: holdings, dataName: "price");

  Future<void> updatePortfolioData() async {
    holdings = await fetchPortfolioPrices();
    totalValue = 0;
    for (var holding in holdings) {
      totalValue += holding.currentPrice * holding.shares;
    }
  }

  PortfolioStatus copyWith({
    double? totalValue,
    PriceRetrevier? provider,
    String? errorMessage,
    List<StockHolding>? holdings,
  }) {
    return PortfolioStatus(
      totalValue: totalValue ?? this.totalValue,
      provider: provider ?? this.provider,
      holdings: holdings ?? this.holdings,
      errorMessage: errorMessage,
    );
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
