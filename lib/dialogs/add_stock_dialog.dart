import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:news_app/api_key/api.dart';
import 'package:news_app/services/portfolio/porfolio_status.dart';
import 'dart:convert';

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

              if (symbol.isEmpty || shares == null || shares <= 0) {
                errorNotifier.value = "Please enter a valid symbol or shares.";
                return;
              }

              try {
                final searchUrl =
                    'https://financialmodelingprep.com/api/v3/search?query=$symbol&limit=1&apikey=$apiPriceKey';
                final response = await http.get(Uri.parse(searchUrl));

                if (response.statusCode == 200) {
                  final List<dynamic> data = jsonDecode(response.body);
                  if (data.isNotEmpty && data[0]['symbol'] == symbol) {
                    final companyName = data[0]['name'] ?? 'Unknown Company';
                    final price = data[0]['price'];

                    final newHolding = StockHolding(
                      currentPrice: price,
                      symbol: symbol,
                      companyName: companyName,
                      shares: shares,
                    );

                    Navigator.of(dialogContext).pop(newHolding);
                  } else {
                    errorNotifier.value = "Ticker not found.";
                  }
                } else {
                  errorNotifier.value = "Network error occurred.";
                }
              } catch (e) {
                errorNotifier.value = "Something went wrong.";
              }
            },
          ),
        ],
      );
    },
  );
}

