import 'package:flutter/material.dart';
import 'package:news_app/view/portfolio_view_v2.dart';
import 'package:news_app/view/setting_view.dart';
import 'package:news_app/view/news_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Index of the currently selected tab
  int _selectedIndex = 0;

  // List of the widgets (views) for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    PortfolioViewV2(), // A new portfolio page you would create
    NewsView(), // Your existing news page
    SettingsView(),
  ];
  // Function to handle tap events on the navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body of the Scaffold is the currently selected view
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // The BottomNavigationBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
