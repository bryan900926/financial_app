import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'package:news_app/services/portfolio/portfolio_notifier.dart';
import 'package:riverpod/riverpod.dart';

final portfolioProvider = StateNotifierProvider.family<
    PortfolioNotifier, PortfolioStatus, String>((ref, email) {
  return PortfolioNotifier(email: email);
});