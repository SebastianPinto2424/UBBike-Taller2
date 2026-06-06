import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class SolicitudGuardiaApp {
  const SolicitudGuardiaApp({
    required this.id,
    required this.tipo,
    required this.estado,
    required this.bicicletero,
    required this.solicitante,
    required this.creadaEn,
    required this.puedeNotificarGuardia,
    required this.puedeNotificarGuardiaUsuario,
    required this.notificacionesGuardia,
    this.guardiaAsignado,
    this.mensaje,
    this.notificadaGuardiaEn,
    this.ultimaNotificacionUsuarioEn,
    this.respondidaPorGuardiaEn,
    this.enCaminoEn,
    this.resueltaEn,
    this.segundosParaNotificarGuardia,
    this.guardiasAsignados = const [],
  });

  final String id;
  final String tipo;
  final String estado;
  final String? mensaje;
  final BicicleteroApp bicicletero;
  final UsuarioApp solicitante;
  final UsuarioApp? guardiaAsignado;
  final List<UsuarioApp> guardiasAsignados;
  final DateTime creadaEn;
  final DateTime? notificadaGuardiaEn;
  final DateTime? ultimaNotificacionUsuarioEn;
  final int notificacionesGuardia;
  final DateTime? respondidaPorGuardiaEn;
  final DateTime? enCaminoEn;
  final DateTime? resueltaEn;
  final bool puedeNotificarGuardia;
  final bool puedeNotificarGuardiaUsuario;
  final int? segundosParaNotificarGuardia;

  factory SolicitudGuardiaApp.desdeJson(Map<String, dynamic> json) {
    final guardia = json['guardiaAsignado'] as Map<String, dynamic>?;
    final guardias = json['guardiasAsignados'] as List<dynamic>? ?? const [];

    return SolicitudGuardiaApp(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      estado: json['estado'] as String,
      mensaje: json['mensaje'] as String?,
      bicicletero: BicicleteroApp.desdeJson(
        json['bicicletero'] as Map<String, dynamic>,
      ),
      solicitante: UsuarioApp.desdeJson(
        json['solicitante'] as Map<String, dynamic>,
      ),
      guardiaAsignado: guardia == null ? null : UsuarioApp.desdeJson(guardia),
      guardiasAsignados: guardias
          .whereType<Map<String, dynamic>>()
          .map(UsuarioApp.desdeJson)
          .toList(),
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      notificadaGuardiaEn: json['notificadaGuardiaEn'] == null
          ? null
          : DateTime.parse(json['notificadaGuardiaEn'] as String),
      ultimaNotificacionUsuarioEn: json['ultimaNotificacionUsuarioEn'] == null
          ? null
          : DateTime.parse(json['ultimaNotificacionUsuarioEn'] as String),
      notificacionesGuardia: json['notificacionesGuardia'] as int? ?? 0,
      respondidaPorGuardiaEn: json['respondidaPorGuardiaEn'] == null
          ? null
          : DateTime.parse(json['respondidaPorGuardiaEn'] as String),
      enCaminoEn: json['enCaminoEn'] == null
          ? null
          : DateTime.parse(json['enCaminoEn'] as String),
      resueltaEn: json['resueltaEn'] == null
          ? null
          : DateTime.parse(json['resueltaEn'] as String),
      puedeNotificarGuardia: json['puedeNotificarGuardia'] as bool? ?? false,
      puedeNotificarGuardiaUsuario:
          json['puedeNotificarGuardiaUsuario'] as bool? ?? false,
      segundosParaNotificarGuardia:
          json['segundosParaNotificarGuardia'] as int?,
    );
  }
}

class SolicitudGuardiaApi {
  SolicitudGuardiaApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<BicicleteroApp>> listarBicicleteros() async {
    final respuesta = await cliente.get('/bicicleteros');
    final datos = respuesta['bicicleteros'] as List<dynamic>;
    return datos
        .map((item) => BicicleteroApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BicicleteroApp?> obtenerBicicleteroGestionado() async {
    final respuesta = await cliente.get('/guardias/me/bicicletero');
    final datos = respuesta['bicicletero'] as Map<String, dynamic>?;

    return datos == null ? null : BicicleteroApp.desdeJson(datos);
  }

  Future<BicicleteroApp> seleccionarBicicleteroGestionado(
    String bicicleteroId,
  ) async {
    final respuesta = await cliente.patch(
      '/guardias/me/bicicletero',
      body: {'bicicleteroId': bicicleteroId},
    );

    return BicicleteroApp.desdeJson(
      respuesta['bicicletero'] as Map<String, dynamic>,
    );
  }

  Future<void> crearSolicitud({
    required String bicicleteroId,
    required String tipo,
    String? mensaje,
  }) async {
    await cliente.post(
      '/solicitudes-guardia',
      body: {
        'bicicleteroId': bicicleteroId,
        'tipo': tipo,
        'mensaje': mensaje,
      },
    );
  }

  Future<SolicitudGuardiaApp> notificarGuardia({
    required String solicitudId,
    String? mensaje,
  }) async {
    final respuesta = await cliente.post(
      '/solicitudes-guardia/$solicitudId/notificar-guardia',
      body: {
        if (mensaje != null && mensaje.isNotEmpty) 'mensaje': mensaje,
      },
    );

    return SolicitudGuardiaApp.desdeJson(
      respuesta['solicitud'] as Map<String, dynamic>,
    );
  }

  Future<List<SolicitudGuardiaApp>> listarSolicitudes({
    String? estado,
    String? q,
    int? limite,
  }) async {
    final parametros = <String, String>{
      if (estado != null && estado != 'TODOS') 'estado': estado,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (limite != null && limite > 0) 'limite': limite.toString(),
    };
    final consulta =
        parametros.isEmpty ? '' : '?${Uri(queryParameters: parametros).query}';
    final respuesta = await cliente.get('/solicitudes-guardia$consulta');
    final datos = respuesta['solicitudes'] as List<dynamic>;
    return datos
        .map((item) =>
            SolicitudGuardiaApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SolicitudGuardiaApp> actualizarEstado({
    required String solicitudId,
    required String estado,
  }) async {
    final respuesta = await cliente.patch(
      '/solicitudes-guardia/$solicitudId/estado',
      body: {'estado': estado},
    );

    return SolicitudGuardiaApp.desdeJson(
      respuesta['solicitud'] as Map<String, dynamic>,
    );
  }
}
