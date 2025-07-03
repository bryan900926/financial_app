import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:news_app/api_key/api.dart';

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

// A result class to hold either the data or an error message.
class PortfolioStatus {
  List<StockHolding> holdings;
  double totalValue;
  String? errorMessage;

  PortfolioStatus({
    required this.holdings,
    required this.totalValue,
    this.errorMessage,
  });

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
}
