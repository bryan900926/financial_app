import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:news_app/api_key/api.dart';
import 'package:news_app/portfolio_service/add_portfolio.dart';
import 'dart:convert';

Future<StockHolding?> showAddStockDialog(BuildContext context) async {
  final symbolController = TextEditingController();
  final sharesController = TextEditingController();

  // The dialog now returns a Future that resolves to a StockHolding or null.
  return showDialog<StockHolding>(
    context: context,
    barrierDismissible: false, // User must tap a button to close.
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
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            // When "Cancel" is pressed, pop the dialog and return null.
            onPressed: () => Navigator.of(dialogContext).pop(null),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              final symbol = symbolController.text.trim().toUpperCase();
              final shares = int.tryParse(sharesController.text.trim());

              if (symbol.isEmpty || shares == null || shares <= 0) {
                // Here you could show an inline error, but for now we just prevent adding.
                return;
              }
              
              try {
                final searchUrl =
                    'https://financialmodelingprep.com/api/v3/search?query=$symbol&limit=1&apikey=$apiPriceKey';
                final searchResponse = await http.get(Uri.parse(searchUrl));

                if (searchResponse.statusCode == 200) {
                  final List<dynamic> searchData =
                      json.decode(searchResponse.body);
                  if (searchData.isNotEmpty && searchData[0]['symbol'] == symbol) {
                    final companyName =
                        searchData[0]['name'] ?? 'Unknown Company';
                    
                    final newHolding = StockHolding(
                      symbol: symbol,
                      companyName: companyName,
                      shares: shares,
                    );
                    
                    // When successful, pop the dialog and return the new holding.
                    return Navigator.of(dialogContext).pop(newHolding);

                  } else {
                    // Ticker not found, pop and return null.
                    Navigator.of(dialogContext).pop(null);
                    // You could also show another error dialog here if you prefer.
                  }
                }
              } catch (e) {
                // Network error, pop and return null.
                Navigator.of(dialogContext).pop(null);
              }
            },
          ),
        ],
      );
    },
  );
}
