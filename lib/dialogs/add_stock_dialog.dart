import 'package:flutter/material.dart';
import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'package:news_app/services/portfolio/portfolio_exceptions.dart';

Future<StockHolding?> showAddStockDialog(BuildContext context) async {
  final symbolController = TextEditingController();
  final sharesController = TextEditingController();
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  return showDialog<StockHolding>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Add Stock to Portfolio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: "Enter stock symbol (e.g., TSLA)",
              ),
            ),
            TextField(
              controller: sharesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter number of shares",
              ),
            ),
            const SizedBox(height: 8),
            // Use ValueListenableBuilder instead of setState
            ValueListenableBuilder<String?>(
              valueListenable: errorNotifier,
              builder: (_, error, __) => error == null
                  ? const SizedBox.shrink()
                  : Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(null);
            },
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final symbol = symbolController.text.trim().toUpperCase();
              final shares = int.tryParse(sharesController.text.trim());

              if (symbol.isEmpty || shares == null || shares < 0) {
                errorNotifier.value = "Please enter a valid symbol or shares.";
                return;
              }

              try {
                final newHolding = await PortfolioStatus.fmp()
                    .addStockPriceToPortfolio(ticker: symbol, shares: shares);
                Navigator.of(dialogContext).pop(newHolding);
              } on PortfolioProviderRequestFail catch (_) {
                errorNotifier.value = "Network error occurred.";
              } on UnableToFetchData catch (_) {
                errorNotifier.value = "ticker data not found";
              }
              catch (e) {
                errorNotifier.value = "Something went wrong.";
              }
            },
          ),
        ],
      );
    },
  );
}
