const apiPriceKey = "ZP707lVgq0tFGJXmqTI69VvOml5sUKh3"; 
const apiNewsKey = 'd66108140f134d7e810851694560aaf2';

String apiNoSearch({required int currentPage, required String apiKey}) =>
    'https://newsapi.org/v2/top-headlines?country=us&category=business&page=$currentPage&pageSize=20&apiKey=$apiKey';

String buildNewsSearchUrl({
  required String apiKey,
  required String query,
  int currentPage = 1,
  int pageSize = 20,
  String sortBy = 'relevancy',
}) {
  final uri = Uri.https('newsapi.org', '/v2/everything', {
    'q': query,
    'page': currentPage.toString(),
    'pageSize': pageSize.toString(),
    'sortBy': sortBy,
    'apiKey': apiKey,
  });

  return uri.toString();
}
