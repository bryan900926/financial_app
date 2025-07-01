import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:news_app/api_key/api.dart';

class StockDetailPage extends StatefulWidget {
  final String stockSymbol;

  const StockDetailPage({super.key, required this.stockSymbol});

  @override
  _StockDetailPageState createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FlSpot> _historicalDataSpots = [];
  double _minY = double.maxFinite;
  double _maxY = double.minPositive;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalData();
  }

  Future<void> _fetchHistoricalData() async {
    final toDate = DateTime.now();
    // Fetch a bit more than a year to ensure we have enough data after downsampling
    final fromDate = toDate.subtract(const Duration(days: 400));
    final formatter = DateFormat('yyyy-MM-dd');
    final url =
        'https://financialmodelingprep.com/api/v3/historical-price-full/${widget.stockSymbol}?from=${formatter.format(fromDate)}&to=${formatter.format(toDate)}&apikey=$apiPriceKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['historical'] == null ||
            (data['historical'] as List).isEmpty) {
          _errorMessage = 'No historical data found for this stock.';
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final List<dynamic> historicals = data['historical'];
        final List<FlSpot> spots = [];

        DateTime? lastDate;
        for (var entry in historicals) {
          final date = DateTime.tryParse(entry['date'] ?? '');
          if (date != null) {
            // If this is the first point, or if it's been at least 7 days since the last one, add it.
            if (lastDate == null ||
                date.difference(lastDate).inDays.abs() >= 7) {
              final closePrice = (entry['close'] as num).toDouble();
              spots.add(
                FlSpot(date.millisecondsSinceEpoch.toDouble(), closePrice),
              );

              if (closePrice < _minY) _minY = closePrice;
              if (closePrice > _maxY) _maxY = closePrice;
              lastDate = date; // Update the last date
            }
          }
        }

        if (spots.isEmpty && historicals.isNotEmpty) {
          // Fallback in case the logic doesn't add any spots, add the last one at least.
          final lastEntry = historicals.first;
          final date = DateTime.tryParse(lastEntry['date'] ?? '');
          if (date != null) {
            final closePrice = (lastEntry['close'] as num).toDouble();
            spots.add(
              FlSpot(date.millisecondsSinceEpoch.toDouble(), closePrice),
            );
            _minY = closePrice;
            _maxY = closePrice;
          }
        }

        spots.sort((a, b) => a.x.compareTo(b.x));

        setState(() {
          _historicalDataSpots = spots;
          _isLoading = false;
        });
      } else {
        throw Exception(
          'Failed to load historical data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // allow pops generally
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.stockSymbol} - 1 Year Performance'),
        ),
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $_errorMessage',
                    textAlign: TextAlign.center,
                  ),
                )
              : _historicalDataSpots.isEmpty
              ? const Text('No data available to display chart.')
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final price = spot.y;
                              return LineTooltipItem(
                                '\$${price.toStringAsFixed(2)}',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xff37434d),
                            strokeWidth: 0.5,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xff37434d),
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval:
                                (_historicalDataSpots.last.x -
                                    _historicalDataSpots.first.x) /
                                4,
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4.0,
                                  child: Transform.rotate(
                                    angle: -pi / 4,
                                    child: Text(
                                      DateFormat('yyyy-MM').format(date),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: const Color(0xff37434d),
                          width: 1,
                        ),
                      ),
                      minY: _minY * 0.95,
                      maxY: _maxY * 1.05,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _historicalDataSpots,
                          isCurved: true,
                          barWidth: 2,
                          color: Theme.of(context).primaryColor,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColorLight,
                                Theme.of(context).primaryColorDark,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
