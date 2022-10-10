import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:array_frequency_calculator/array_frequency_calculator.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

// Configure routes.
final _router = Router()
  // ..get('/', _rootHandler)
  ..get('/', _getNnewsHandler)
  ..get('/echo/<message>', _echoHandler);

Future<Response> _getNnewsHandler(Request req) async {
  try{
    String result;
    final api_key = '0e5d7dcd12014146a890521464346010';
    final params = req.requestedUri.queryParameters;
    final count = params['count'];
    final keyword = params['keyword'];
    final name = params['name'];

    String apiUrl = 'https://gnews.io/api/v4/search?token=$api_key';

    if(name == null && count != null){
      apiUrl += '&max=$count';
    }

    if (keyword != null){
      apiUrl += '&q=$keyword';
    }

    //load data
    Future<String> fetchArticle() async {
      var result = await http.get(Uri.parse(apiUrl));
      return result.body;
    }

    List article = json.decode( await fetchArticle())['articles'];
    if (name != null){
      article = article.where((element) => element['source']['name'] == name).toList();
      if (article.length > int.parse(count!)){
        article = article.sublist(0, int.parse(count));
      }
    }

    //count word frequency
    for (final item in article){
      var frequency = WordsCalculator(item['description']);
      item['frequency'] = frequency;
    }

    result = jsonEncode(article);

    return Response.ok('$result\n');
  } catch(e){
    return Response.badRequest(body: 'error');
  }
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).        
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
