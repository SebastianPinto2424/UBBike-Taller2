import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

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

class QrApi {
  QrApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<QrTemporalApp> generar({
    String? bicicletaId,
    String? bicicleteroId,
    String? tipo,
  }) async {
    final respuesta = await cliente.post(
      '/qr/generar',
      body: {
        if (bicicletaId != null) 'bicicletaId': bicicletaId,
        if (bicicleteroId != null) 'bicicleteroId': bicicleteroId,
        if (tipo != null) 'tipo': tipo,
      },
    );

    return QrTemporalApp.desdeJson(respuesta['qr'] as Map<String, dynamic>);
  }
}
