import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/movimiento_app.dart';
import 'acceso_modelos.dart';

class AccesoApi {
  const AccesoApi({required this.cliente});

  final ClienteApi cliente;

  Future<CoincidenciaManualApp?> buscarCoincidenciaManual({
    String? correo,
    String? rut,
  }) async {
    final parametros = <String, String>{
      if (correo != null && correo.isNotEmpty) 'correo': correo,
      if (rut != null && rut.isNotEmpty) 'rut': rut,
    };
    final consulta = Uri(queryParameters: parametros).query;
    final respuesta = await cliente.get('/accesos/manual/buscar?$consulta');
    final coincidencia = respuesta['coincidencia'] as Map<String, dynamic>?;

    return coincidencia == null
        ? null
        : CoincidenciaManualApp.desdeJson(coincidencia);
  }

  Future<QrValidadoApp> validarQr(String token) async {
    final respuesta = await cliente.post('/qr/validar', body: {'token': token});
    return QrValidadoApp.desdeJson(respuesta['qr'] as Map<String, dynamic>);
  }

  Future<MovimientoApp> confirmarQr(String token, {String? comentario}) async {
    final respuesta = await cliente.post(
      '/accesos/qr/confirmar',
      body: {
        'token': token,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }

  Future<MovimientoApp> denegarQr({
    required String token,
    required String motivo,
  }) async {
    final respuesta = await cliente.post(
      '/accesos/qr/denegar',
      body: {
        'token': token,
        'motivo': motivo,
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }

  Future<MovimientoApp> registrarManual({
    String? correo,
    String? rut,
    String? bicicletaId,
    String? bicicleteroId,
    required String tipo,
    bool denegar = false,
    String? motivo,
    String? comentario,
    String? bicicletaDescripcion,
    String? bicicletaMarca,
    String? bicicletaModelo,
    String? bicicletaColor,
    String? bicicletaAro,
    String? bicicletaNumeroSerie,
    String? bicicletaFotoUrl,
    bool crearBicicletaNueva = false,
  }) async {
    final respuesta = await cliente.post(
      '/accesos/manual',
      body: {
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        if (rut != null && rut.isNotEmpty) 'rut': rut,
        if (bicicletaId != null && bicicletaId.isNotEmpty)
          'bicicletaId': bicicletaId,
        if (bicicleteroId != null && bicicleteroId.isNotEmpty)
          'bicicleteroId': bicicleteroId,
        'tipo': tipo,
        'denegar': denegar,
        'motivo': motivo,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
        if (bicicletaDescripcion != null && bicicletaDescripcion.isNotEmpty)
          'bicicletaDescripcion': bicicletaDescripcion,
        if (bicicletaMarca != null && bicicletaMarca.isNotEmpty)
          'bicicletaMarca': bicicletaMarca,
        if (bicicletaModelo != null && bicicletaModelo.isNotEmpty)
          'bicicletaModelo': bicicletaModelo,
        if (bicicletaColor != null && bicicletaColor.isNotEmpty)
          'bicicletaColor': bicicletaColor,
        if (bicicletaAro != null && bicicletaAro.isNotEmpty)
          'bicicletaAro': bicicletaAro,
        if (bicicletaNumeroSerie != null && bicicletaNumeroSerie.isNotEmpty)
          'bicicletaNumeroSerie': bicicletaNumeroSerie,
        if (bicicletaFotoUrl != null && bicicletaFotoUrl.isNotEmpty)
          'bicicletaFotoUrl': bicicletaFotoUrl,
        'crearBicicletaNueva': crearBicicletaNueva,
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }
}
