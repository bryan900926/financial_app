import 'dart:convert';
import 'dart:developer';
import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'package:news_app/services/portfolio/portfolio_exceptions.dart';
import 'package:news_app/services/portfolio/price_retrevier.dart';
import 'package:http/http.dart' as http;

class FmpPortfolioProvider implements PriceRetrevier {
  final String apiKey;

  FmpPortfolioProvider({required this.apiKey});

  @override
  Future<List<StockHolding>> getData({
    required List<StockHolding> holdings,
    required String dataName,
  }) async {
    final List<StockHolding> infos = [];

    try {
      final symbols = holdings.map((h) => h.symbol).join(',');
      final searchUrl =
          'https://financialmodelingprep.com/api/v3/quote/$symbols?apikey=$apiKey';
      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var h in holdings) {
          final String ticker = h.symbol;
          final quote = data.firstWhere(
            (q) => q['symbol'] == ticker,
            orElse: () => null,
          );
          if (quote != null && quote[dataName] != null) {
            var newHolding = StockHolding(
              symbol: ticker,
              shares: h.shares,
              currentPrice: quote[dataName],
            );
            newHolding.companyName = quote["name"] ?? 'companyname not found';
            infos.add(newHolding);
          }
        }
      } else {
        throw PortfolioProviderRequestFail();
      }
    } catch (e) {
      throw UnableToFetchData();
    }

    return infos;
  }
}
