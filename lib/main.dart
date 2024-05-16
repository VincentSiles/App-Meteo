import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Importez DateFormat

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appli météo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final String apiKey = '0230b4bb8939ca1f714b66e6ae4877f1';

  TextEditingController _cityController = TextEditingController();
  dynamic _weatherData;
  bool _isCelsius = true;
  bool _isSearching = false;
  String _previousTemperature = '';
  String _weatherDescription = '';
  List<String> _favoriteCities = [];

  void _toggleFavorite(String city) {
    setState(() {
      if (_favoriteCities.contains(city)) {
        _favoriteCities.remove(city);
      } else {
        _favoriteCities.add(city);
      }
    });
    print('Favorite cities: $_favoriteCities');
  }

  Future<dynamic> fetchWeather(String city) async {
    final String unit = _isCelsius ? 'metric' : 'imperial';
    final Uri uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$unit');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }

  Future<dynamic> fetchHourlyForecast(double lat, double lon) async {
    final String exclude =
        'current,minutely,daily,alerts'; // Exclure les données actuelles, minutieuses, quotidiennes et d'alerte
    final Uri uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=$exclude&appid=$apiKey');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load hourly forecast');
    }
  }

  void _getWeather() async {
    setState(() {
      _isSearching = true;
    });
    String city = _cityController.text;
    dynamic weather = await fetchWeather(city);
    setState(() {
      _weatherData = weather;
      _previousTemperature = _formatTemperature(weather);
      _weatherDescription = _weatherData['weather'][0]['description'];
      _isSearching = false;
    });

    // Récupérer les coordonnées de la ville
    double lat = _weatherData['coord']['lat'];
    double lon = _weatherData['coord']['lon'];

    // Récupérer les prévisions météorologiques horaires
    dynamic hourlyForecast = await fetchHourlyForecast(lat, lon);
    print('Hourly Forecast: $hourlyForecast');
  }

  String _getWeatherImage() {
    if (_weatherData != null && _weatherData['weather'] != null) {
      String iconCode = _weatherData['weather'][0]['icon'];
      return 'https://openweathermap.org/img/wn/$iconCode.png';
    } else {
      return 'assets/images/sunny.png';
    }
  }

  String _formatTemperature(dynamic weatherData) {
    double temperature = _isCelsius
        ? weatherData['main']['temp']
        : (weatherData['main']['temp'] * 9 / 5) + 32;
    if (!_isCelsius) {
      temperature = (temperature - 32) * 5 / 9;
    }
    return '${temperature.toStringAsFixed(2)} ${_isCelsius ? '°C' : '°F'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Enter city name',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _toggleFavorite(_cityController.text);
                  },
                  icon: Icon(
                    _favoriteCities.contains(_cityController.text)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoriteCities.contains(_cityController.text)
                        ? Colors.red
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSearching ? null : _getWeather,
              child: Text('Get Weather'),
            ),
            SizedBox(height: 20),
            if (_weatherData != null)
              Column(
                children: [
                  Image.network(
                    _getWeatherImage(),
                    height: 100,
                  ),
                  Text(
                    'Temperature: $_previousTemperature',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Weather: $_weatherDescription',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'City: ${_weatherData['name']}',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            SizedBox(height: 20),
            Switch(
              value: _isCelsius,
              onChanged: (value) {
                setState(() {
                  _isCelsius = value;
                  _getWeather();
                });
              },
            ),
            Text(
              '°F / °C',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
