import 'package:news_app/services/portfolio/porfolio_status.dart';

abstract class PriceRetrevier {
  Future<List<StockHolding>> getData({required List<StockHolding> holdings, required String dataName}); 
}