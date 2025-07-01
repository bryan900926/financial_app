import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:news_app/api_key/api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class NewsArticle {
  final String title;
  final String url;
  final String publishedAt;

  NewsArticle({
    required this.title,
    required this.url,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title Found',
      url: json['url'] ?? 'https://news.google.com',
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _totalResults = 0;
  final ScrollController _scrollController = ScrollController();

  // MODIFIED: Added state variables for search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchNews();
    _scrollController.addListener(_onScroll);
    // MODIFIED: Added listener to handle changes in the search field
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // MODIFIED: Debounce function to prevent API calls on every keystroke
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (_searchQuery != _searchController.text) {
        _resetSearch();
        _fetchNews();
      }
    });
  }

  // MODIFIED: Helper function to reset the state for a new search
  void _resetSearch() {
    setState(() {
      _articles = [];
      _currentPage = 1;
      _hasMore = true;
      _totalResults = 0;
      _errorMessage = null;
      _searchQuery = _searchController.text;
    });
  }

  void _onScroll() {
    if (!_isLoadingMore &&
        _hasMore &&
        _scrollController.position.extentAfter < 300) {
      _fetchNews();
    }
  }

  Future<void> _fetchNews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      if (_articles.isEmpty) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    const apiKey = apiNewsKey;
    // MODIFIED: The API URL now changes based on whether there's a search query
    String apiUrl;
    if (_searchQuery.isEmpty) {
      // Fetch top business headlines if there is no search query
      apiUrl = apiNoSearch(currentPage: _currentPage, apiKey: apiKey);
    } else {
      // Use the 'everything' endpoint to search for the query
      apiUrl = buildNewsSearchUrl(
        apiKey: apiKey,
        query: _searchQuery,
        currentPage: _currentPage,
      );
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'];

        if (_currentPage == 1) {
          _totalResults = data['totalResults'] ?? 0;
          debugPrint('Total available articles for this query: $_totalResults');
        }

        final newArticles = articlesJson
            .map((json) => NewsArticle.fromJson(json))
            .toList();
        // for (var article in newArticles) {
        //   debugPrint('--- Article ---');
        //   debugPrint('Title: ${article.title}');
        //   debugPrint('Published At: ${article.publishedAt}');
        //   debugPrint('URL: ${article.url}');
        //   debugPrint('---------------');
        // }

        setState(() {
          _articles.addAll(newArticles);
          _currentPage++;
          if (_articles.length >= _totalResults) {
            _hasMore = false;
          }
        });
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        final errorMessage =
            data['message'] ??
            'Failed to load news. Status code: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
      setState(() {
        _errorMessage =
            'Error: $e\n\nPlease check your API key and internet connection.';
        _hasMore = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  // MODIFIED: Function to toggle the search bar in the AppBar
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching && _searchQuery.isNotEmpty) {
        // If we close the search, clear the query and fetch the default headlines
        _searchController
            .clear(); // This will trigger _onSearchChanged to reset
      }
    });
  }

  // MODIFIED: Build the AppBar dynamically based on whether we are searching
  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search news...',
                hintStyle: TextStyle(color: Colors.black),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.black, fontSize: 18),
            )
          : const Text('Live Flutter News'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _resetSearch();
                  _fetchNews();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // MODIFIED: Show a message if a search yields no results
    if (_articles.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No results found for "$_searchQuery".'
              : 'Loading news...',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _articles.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _articles.length) {
          return _hasMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text('You have reached the end of the list.'),
                  ),
                );
        }

        final article = _articles[index];
        String formattedDate = '';
        if (article.publishedAt.isNotEmpty) {
          try {
            // Parse the UTC date string and convert it to the user's local time zone.
            final dateTime = DateTime.parse(article.publishedAt).toLocal();
            formattedDate = DateFormat.yMMMMd().add_jm().format(dateTime);
          } catch (e) {
            debugPrint('Could not parse date: ${article.publishedAt}');
          }
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 3,
          child: ListTile(
            title: Text(
              article.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(formattedDate, style: const TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchURL(article.url),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }
}
