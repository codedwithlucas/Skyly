class Tempo {
  final String cidade;
  final double temperatura;
  final String condicao;

  Tempo({
    required this.cidade,
    required this.condicao,
    required this.temperatura,
  });

  factory Tempo.fromJson(Map<String, dynamic> json) {
    return Tempo(
      cidade: json['name'],
      temperatura: json['main']['temp'].toDouble(),
      condicao: json['weather'][0]['main'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': cidade,
    'main': {'temp': temperatura},
    'weather': [
      {'main': condicao},
    ],
  };
}
