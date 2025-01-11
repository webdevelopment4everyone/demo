import 'package:flutter/material.dart';

class WeatherList extends StatefulWidget {
  const WeatherList({super.key});

  @override
  State<WeatherList> createState() => _WeatherListState();
}

class _WeatherListState extends State<WeatherList> {
  void weatherData(List<String> arguments) async {
    // This example uses the Google Books API to search for books about http.
    // https://developers.google.com/books/docs/overview
    var url =
        Uri.https('https://api.openweathermap.org', '/data/2.5/weather?', {'q': '{http}'});

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      var itemCount = jsonResponse['totalItems'];
      print('Number of books about http: $itemCount.');
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListView.builder(
              itemBuilder: (context, index) {
                return const Card(
                  child: Column(
                    children: [Text("City Name"), Text("Curr Tem")],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
