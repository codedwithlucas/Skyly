import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _dadosAtualizados = false; // Guard para evitar race conditions do cache
  bool _isCelsius = true; // Controle da unidade de temperatura

  // Carrega preferencia de unidade
  Future<void> _carregarPreferenciaUnidade() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isCelsius = prefs.getBool('isCelsius') ?? true;
      });
    }
  }

  // Alterna e salva
  void _alternarUnidade() async {
    await HapticFeedback.selectionClick();
    setState(() {
      _isCelsius = !_isCelsius;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isCelsius', _isCelsius);
  }

  // Função que busca a posição e depois o tempo (agora por lat/lon)
  Future<void> _pegaTempo() async {
    try {
      // Pega posição (lat/lon)
      Position posicao = await _tempoService.getPosicaoAtual();

      // Busco os dados usando coordenadas (sem geocoding reverso!)
      Tempo tempo = await _tempoService.getTempoPorPosicao(
        posicao.latitude,
        posicao.longitude,
      );

      // Marca que temos dados atualizados
      _dadosAtualizados = true;

      // Atualizo o estado
      if (mounted) {
        setState(() {
          _tempo = tempo;
        });
      }
    } catch (e) {
      print('Erro ao buscar tempo: $e');
    }
  }

  // Carrega o ultimo tempo salvo pra mostrar instantaneamente
  Future<void> _carregarCache() async {
    try {
      Tempo? tempoCache = await _tempoService.getLastTempo();
      // So atualiza se ainda não tiver chegado dados novos da rede
      if (tempoCache != null && mounted && !_dadosAtualizados) {
        setState(() {
          _tempo = tempoCache;
        });
      }
    } catch (e) {
      print('Erro ao carregar cache: $e');
    }
  }

  // Função pra escolher o ícone certo conforme a condição do tempo
  String pegaTempoIcone(String? condicao) {
    if (condicao == null) return 'assets/icons/sol.png';

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
    // Dispara os dois em paralelo
    _carregarPreferenciaUnidade();
    _carregarCache();
    _pegaTempo();
  }

  @override
  Widget build(BuildContext context) {
    final temaDark = Theme.of(context).brightness == Brightness.dark;

    // Defino a cor de fundo conforme o tema do android...
    final corBackground = temaDark ? Colors.black : Colors.white;
    final textIconsCor = temaDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: corBackground,
      body: SafeArea(
        child: _tempo == null
            // Enquanto não chegou o dado do tempo, mostra um loading
            ? Center(child: CircularProgressIndicator(color: textIconsCor))
            : RefreshIndicator(
                color: textIconsCor,
                backgroundColor: corBackground,
                onRefresh: () async {
                  await HapticFeedback.lightImpact();
                  await _pegaTempo();
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
                        child: Column(
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
                            GestureDetector(
                              onTap: _alternarUnidade,
                              child: Image.asset(
                                pegaTempoIcone(_tempo!.condicao),
                                width: MediaQuery.of(context).size.width * 0.5,
                              ),
                            ),

                            // Parte de baixo: a temperatura
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: GestureDetector(
                                onTap: _alternarUnidade,
                                child: Text(
                                  _isCelsius
                                      ? '${_tempo!.temperatura.round()}ºC'
                                      : '${(_tempo!.temperatura * 1.8 + 32).round()}ºF',
                                  style: GoogleFonts.roboto(
                                    fontSize: 60,
                                    fontWeight: FontWeight.w300,
                                    color: textIconsCor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
