import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';

class QrTemporalApp {
  const QrTemporalApp({
    required this.token,
    required this.tipo,
    required this.duracionSegundos,
    required this.expiraEn,
    required this.bicicleta,
    this.bicicletero,
  });

  final String token;
  final String tipo;
  final int duracionSegundos;
  final DateTime expiraEn;
  final BicicletaApp bicicleta;
  final BicicleteroApp? bicicletero;

  factory QrTemporalApp.desdeJson(Map<String, dynamic> json) {
    final bicicletaJson = json['bicicleta'] as Map<String, dynamic>;
    final bicicleteroJson = json['bicicletero'] as Map<String, dynamic>?;

    return QrTemporalApp(
      token: json['token'] as String,
      tipo: json['tipo'] as String,
      duracionSegundos: json['duracionSegundos'] as int,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
      bicicleta: BicicletaApp(
        id: bicicletaJson['id'] as String,
        descripcion: bicicletaJson['descripcion'] as String,
        fotoUrl: null,
        activa: true,
        dentroBicicletero: json['tipo'] == 'RETIRO',
      ),
      bicicletero: bicicleteroJson == null
          ? null
          : BicicleteroApp.desdeJson(bicicleteroJson),
    );
  }
}
