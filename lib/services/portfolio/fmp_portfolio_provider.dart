import 'dart:convert';
import 'dart:developer';
import 'package:news_app/services/portfolio/portfolio_exceptions.dart';
import 'package:news_app/services/portfolio/portfolio_provider.dart';
import 'package:http/http.dart' as http;

class FmpPortfolioProvider implements PortfolioProvider {
  final String apiKey;

  FmpPortfolioProvider({required this.apiKey});

  @override
  Future<Map<String, double>> getData({
    required List<String> tickers,
    required String dataName,
  }) async {
    final Map<String, double> infos = {};

    try {
      final symbols = tickers.join(',');
      final searchUrl =
          'https://financialmodelingprep.com/api/v3/quote/$symbols?apikey=$apiKey';
      final response = await http.get(Uri.parse(searchUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var ticker in tickers) {
          final quote = data.firstWhere(
            (q) => q['symbol'] == ticker,
            orElse: () => null,
          );

          if (quote != null && quote[dataName] != null) {
            infos[ticker] = (quote[dataName] as num).toDouble();
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
