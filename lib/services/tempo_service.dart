import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skyly/models/tempo_model.dart';
import 'package:http/http.dart' as http;

class TempoService {
  static const URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiK;

  TempoService(this.apiK);

  Future<Tempo> getTempo(String cidade) async {
    // Tenta buscar os dados daa API do OpenWeather
    final response = await http.get(Uri.parse('$URL?q=$cidade&appid=$apiK&units=metric'));

    // Se o servidor OK
    if (response.statusCode == 200) {
      return Tempo.fromJson(jsonDecode(response.body));
    } else {
      // Se deu ruim, joga um erro pra cima para ser tratado onde chamar essa função
      throw Exception('Falhou na procura pela informação!');
    }
  }

  // Função pra pegar o nome da cidade atual do usuário
  Future<String> getCidadeAtual() async {
    // Verifica se a gente tem permissão de localização
    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      // Se não tiver, pede para o usuário liberar
      permissao = await Geolocator.requestPermission();
    }

    // Pega a posição atual com precisão alta
    //Se der ruim, tentar baixar pra um medium...
    Position posicao = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
 
    // Converte latitude e longitude para um endereço placemark
    List<Placemark> marcacao = await placemarkFromCoordinates(posicao.latitude, posicao.longitude);

    // Pega a cidade do primeiro resultado...
    String? cidade = marcacao[0].subAdministrativeArea;

    // Se não achou, devolve uma string padrão
    return cidade ?? "Cidade não encontrada";
  }
}
