import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skyly/models/tempo_model.dart';
import 'package:http/http.dart' as http;

class TempoService {
  static const URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiK;

  TempoService(this.apiK);

  // Fetch pelas coordenadas, talvez mais rrápido?
  Future<Tempo> getTempoPorPosicao(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$URL?lat=$lat&lon=$lon&appid=$apiK&units=metric'),
    );

    if (response.statusCode == 200) {
      final tempo = Tempo.fromJson(jsonDecode(response.body));
      saveLastTempo(tempo);
      return tempo;
    } else {
      throw Exception('Falhou na procura pela informação!');
    }
  }

  // Deprecated: Fetch antigo
  Future<Tempo> getTempo(String cidade) async {
    final response = await http.get(
      Uri.parse('$URL?q=$cidade&appid=$apiK&units=metric'),
    );

    if (response.statusCode == 200) {
      final tempo = Tempo.fromJson(jsonDecode(response.body));
      saveLastTempo(tempo);
      return tempo;
    } else {
      throw Exception('Falhou na procura pela informação!');
    }
  }

  Future<void> saveLastTempo(Tempo tempo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_tempo', jsonEncode(tempo.toJson()));
  }

  Future<Tempo?> getLastTempo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tempoJson = prefs.getString('last_tempo');
    if (tempoJson != null) {
      return Tempo.fromJson(jsonDecode(tempoJson));
    }
    return null;
  }

  // Função pra pegar a posição atual (Lat/Lon)
  Future<Position> getPosicaoAtual() async {
    // Verifica permissões
    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    // Tenta ultima conhecida (Instantanea)
    Position? posicao = await Geolocator.getLastKnownPosition();

    // Se não tiver, busca a atual (demora um pouco)
    if (posicao == null) {
      posicao = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    return posicao;
  }
}
