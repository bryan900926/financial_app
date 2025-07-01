  import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:news_app/portfolio_service/add_portfolio.dart';

List<PieChartSectionData> generatePieChartSections(PortfolioStatus portfolio) {
    if (portfolio.totalValue == 0) {
      return [];
    }
    
    final List<Color> colors = [
      Colors.blue.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.amber.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
    ];

    return portfolio.holdings.asMap().entries.map((entry) {
      final index = entry.key;
      final holding = entry.value;
      final percentage = (holding.totalValue / portfolio.totalValue) * 100;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: holding.totalValue,
        title: '${holding.symbol}\n${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    }).toList();
  }