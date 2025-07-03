import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:news_app/api_key/api.dart';
import 'package:news_app/database/portfolio_db.dart';


// A result class to hold either the data or an error message.
class PortfolioStatus {
  double totalValue;
  String? errorMessage;
  final portfolioDbHelper = PortfolioDbHelper.instance;
  List<StockHolding> holdings = [];


  PortfolioStatus({
    required this.totalValue,
    this.errorMessage,
  });

  static Future<PortfolioStatus> fromDb(String userEmail) async {
    final instance = PortfolioStatus(totalValue: 0.0);
    final dbHoldings = await instance.portfolioDbHelper.getAllHoldings(userEmail);
    instance.holdings = dbHoldings;
    await instance.fetchPortfolioPrices();
    return instance;
  }

  Future<void> fetchPortfolioPrices() async {
    if (holdings.isEmpty) {
      totalValue = 0.0;
      errorMessage = null;
      return;
    }

    final symbols = holdings.map((h) => h.symbol).join(',');
    final url =
        'https://financialmodelingprep.com/api/v3/quote/$symbols?apikey=$apiPriceKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        double tempTotalValue = 0;

        for (var holding in holdings) {
          final quote = data.firstWhere(
            (q) => q['symbol'] == holding.symbol,
            orElse: () => null,
          );
          if (quote != null) {
            holding.currentPrice = (quote['price'] as num?)?.toDouble() ?? 0.0;
            tempTotalValue += holding.totalValue;
            holding.companyName = quote["name"];
          }
          else{
            holding.companyName = "Cannot find this company";
          }
        }
        totalValue = tempTotalValue;
      }
    } catch (e) {
      errorMessage = e.toString();
      throw Exception(errorMessage);
    }
  }
  Future<void> updatePortfolioData({required List<StockHolding> DbHoldings}) async {
    holdings = DbHoldings;
    await fetchPortfolioPrices();
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