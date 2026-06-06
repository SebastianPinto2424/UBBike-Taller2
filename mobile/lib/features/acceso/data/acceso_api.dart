import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/movimiento_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class QrValidadoApp {
  const QrValidadoApp({
    required this.token,
    required this.tipo,
    required this.expiraEn,
    required this.usuarioNombre,
    required this.usuarioCorreo,
    required this.usuarioRut,
    required this.bicicletaDescripcion,
    this.bicicletaMarca,
    this.bicicletaModelo,
    this.bicicletaColor,
    this.bicicletaAro,
    this.bicicletaNumeroSerie,
    this.bicicletaFotoUrl,
    this.bicicleteroNombre,
  });

  final String token;
  final String tipo;
  final DateTime expiraEn;
  final String usuarioNombre;
  final String usuarioCorreo;
  final String? usuarioRut;
  final String bicicletaDescripcion;
  final String? bicicletaMarca;
  final String? bicicletaModelo;
  final String? bicicletaColor;
  final String? bicicletaAro;
  final String? bicicletaNumeroSerie;
  final String? bicicletaFotoUrl;
  final String? bicicleteroNombre;

  factory QrValidadoApp.desdeJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>;
    final bicicleta = json['bicicleta'] as Map<String, dynamic>;
    final bicicletero = json['bicicletero'] as Map<String, dynamic>?;

    return QrValidadoApp(
      token: json['token'] as String,
      tipo: json['tipo'] as String,
      expiraEn: DateTime.parse(json['expiraEn'] as String),
      usuarioNombre: usuario['nombre'] as String,
      usuarioCorreo: usuario['correo'] as String,
      usuarioRut: usuario['rut'] as String?,
      bicicletaDescripcion: bicicleta['descripcion'] as String,
      bicicletaMarca: bicicleta['marca'] as String?,
      bicicletaModelo: bicicleta['modelo'] as String?,
      bicicletaColor: bicicleta['color'] as String?,
      bicicletaAro: bicicleta['aro'] as String?,
      bicicletaNumeroSerie: bicicleta['numeroSerie'] as String?,
      bicicletaFotoUrl: bicicleta['fotoUrl'] as String?,
      bicicleteroNombre: bicicletero?['nombre'] as String?,
    );
  }
}

class AccesoApi {
  AccesoApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

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
  }) async {
    final respuesta = await cliente.post(
      '/accesos/manual',
      body: {
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        if (rut != null && rut.isNotEmpty) 'rut': rut,
        if (bicicletaId != null && bicicletaId.isNotEmpty)
          'bicicletaId': bicicletaId,
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
      },
    );
    return MovimientoApp.desdeJson(
      respuesta['movimiento'] as Map<String, dynamic>,
    );
  }
}

class CoincidenciaManualApp {
  const CoincidenciaManualApp({
    required this.usuario,
    required this.bicicletas,
  });

  final UsuarioApp usuario;
  final List<BicicletaApp> bicicletas;

  factory CoincidenciaManualApp.desdeJson(Map<String, dynamic> json) {
    final bicicletasJson = json['bicicletas'] as List<dynamic>? ?? const [];

    return CoincidenciaManualApp(
      usuario: UsuarioApp.desdeJson(json['usuario'] as Map<String, dynamic>),
      bicicletas: bicicletasJson
          .map((item) => BicicletaApp.desdeJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
