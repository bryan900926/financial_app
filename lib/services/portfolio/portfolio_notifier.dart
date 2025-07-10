import 'package:news_app/database/portfolio_db.dart';
import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'package:riverpod/riverpod.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(this.toString());
}

class PortfolioNotifier extends StateNotifier<PortfolioStatus> {
  final portfolioDbHelper = PortfolioDbHelper.instance;
  final String email;
  PortfolioNotifier({required this.email}) : super(PortfolioStatus.fmp());
  Future<void> loadHoldings() async {
    try {
      state.holdings = await PortfolioDbHelper.instance.getAllHoldings(email);
      final holdings = await state.fetchPortfolioPrices();
      final total = holdings.fold(
        0.0,
        (sum, h) => sum + h.currentPrice * h.shares,
      );
      state = state.copyWith(
        holdings: holdings,
        totalValue: total,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void addHolding(StockHolding newholding) {
    for (var holding in state.holdings) {
      if (holding.symbol == newholding.symbol) {
        holding = newholding;
      }
    }
    state = state.copyWith(errorMessage: null);
    portfolioDbHelper.insertStock(newholding, email);
  }

  void deleteHolding(String symbol) {
    final updatedHoldings = state.holdings
        .where((holding) => holding.symbol != symbol)
        .toList();

    final total = updatedHoldings.fold(
      0.0,
      (sum, h) => sum + h.currentPrice * h.shares,
    );
    portfolioDbHelper.deleteStock(symbol, email);
    state = state.copyWith(holdings: updatedHoldings, totalValue: total);
  }
}
