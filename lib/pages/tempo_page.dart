import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:skyly/models/tempo_model.dart';
import 'package:skyly/secret.dart';
import 'package:skyly/services/tempo_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TempoPage extends StatefulWidget {
  const TempoPage({super.key});

  @override
  State<TempoPage> createState() => _TempoPageState();
}

class _TempoPageState extends State<TempoPage> {
  // Instância do serviço que pega o tempo, com a chave da API
  final _tempoService = TempoService(OPENWEATHER_API_KEY);

  Tempo? _tempo;

  // Função que busca a cidade atual e depois o tempo pra ela
  Future<void> _pegaTempo() async {
    try {
      // Pego o nome da cidade atual pelo GPS
      String cidade = await _tempoService.getCidadeAtual();
      
      // Busco os dados do tempo pra essa cidade
      Tempo tempo = await _tempoService.getTempo(cidade);

      // Atualizo o estado
      setState(() {
        _tempo = tempo;
      });
    } catch (e) {
      print('Erro ao buscar tempo: $e');
    }
  }

  // Função pra escolher o ícone certo conforme a condição do tempo
  String pegaTempoIcone(String? condicao) {
    if(condicao == null) return 'assets/icons/sol.png';

    switch (condicao.toLowerCase()) {
      case 'clouds':
        return 'assets/icons/nublado.png';
      case 'mist':
        return 'assets/icons/neblina.png';
      case 'smoke':
        return 'assets/icons/fumaca.png';
      case 'haze':
        return 'assets/icons/nevoa.png';
      case 'dust':
        return 'assets/icons/poeira.png';
      case 'fog':
        return 'assets/icons/neblina.png';
      case 'rain':
        return 'assets/icons/chuva_forte.png';
      case 'drizzle':
        return 'assets/icons/chuvisco.png';
      case 'shower rain':
        return 'assets/icons/pancada.png';
      case 'thunderstorm':
        return 'assets/icons/tempestade.png';
      case 'clear':
        return 'assets/icons/sol.png';
      default:
        return 'assets/icons/sol.png';
    }
  }

  @override
  void initState() {
    super.initState();
    // Quando o widget inicia, já disparo a busca do tempo
    _pegaTempo();
  }

  @override
  Widget build(BuildContext context) {
    final temaDark = Theme.of(context).brightness == Brightness.dark;

    // Defino a cor de fundo conforme o tema do android...
    final corBackground = temaDark ? Colors.black : Colors.white;
    final textIconsCor   = temaDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: corBackground,
      body: SafeArea(
        child: SizedBox.expand(
          child: _tempo == null 
            // Enquanto não chegou o dado do tempo, mostra um loading
            // Tava lento, manter esse...
            ? Center(child: CircularProgressIndicator(color: textIconsCor))
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Parte de cima: ícone de localização e a cidade
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid, 
                          color: textIconsCor,
                          size: 32,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _tempo!.cidade,
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            color: textIconsCor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Meio: o ícone do clima atual
                  Image.asset(
                    pegaTempoIcone(_tempo!.condicao),
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),

                  // Parte de baixo: a temperatura
                  // Depois tentar fazer algo pra converter automatico pra Fahrenheit
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      '${_tempo!.temperatura.round()}ºC',
                      style: GoogleFonts.roboto(
                        fontSize: 60,
                        fontWeight: FontWeight.w300,
                        color: textIconsCor,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
