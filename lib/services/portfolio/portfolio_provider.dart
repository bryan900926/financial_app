abstract class PortfolioProvider {
  Future<Map<String, double>> getData({required List<String> tickers, required String dataName}); 
}