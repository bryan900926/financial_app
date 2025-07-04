import 'package:news_app/api_key/api.dart';
import 'package:news_app/services/portfolio/fmp_portfolio_provider.dart';
import 'package:news_app/services/portfolio/portfolio_provider.dart';

class PortfolioService {
  PortfolioProvider provider;
  PortfolioService({required this.provider});
  factory PortfolioService.fmp() =>
      PortfolioService(provider: FmpPortfolioProvider(apiKey: apiPriceKey));
  Future<Map<String, double>> getData({required tickers, required dataName}) =>
      provider.getData(tickers: tickers, dataName: dataName);
}
