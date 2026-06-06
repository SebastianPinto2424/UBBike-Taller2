import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class IncidenciaApp {
  const IncidenciaApp({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.creadaEn,
    required this.actualizadaEn,
    required this.bicicletero,
    required this.reportadaPorUsuario,
    this.bicicleta,
    this.gestionadaPorUsuario,
    this.respuesta,
    this.resueltaEn,
  });

  final String id;
  final String tipo;
  final String descripcion;
  final String estado;
  final String? respuesta;
  final DateTime creadaEn;
  final DateTime actualizadaEn;
  final DateTime? resueltaEn;
  final BicicleteroApp bicicletero;
  final BicicletaApp? bicicleta;
  final UsuarioApp reportadaPorUsuario;
  final UsuarioApp? gestionadaPorUsuario;

  factory IncidenciaApp.desdeJson(Map<String, dynamic> json) {
    final bicicleta = json['bicicleta'] as Map<String, dynamic>?;
    final gestionadaPorUsuario =
        json['gestionadaPorUsuario'] as Map<String, dynamic>?;

    return IncidenciaApp(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      estado: json['estado'] as String,
      respuesta: json['respuesta'] as String?,
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      actualizadaEn: DateTime.parse(json['actualizadaEn'] as String),
      resueltaEn: json['resueltaEn'] == null
          ? null
          : DateTime.parse(json['resueltaEn'] as String),
      bicicletero: BicicleteroApp.desdeJson(
        json['bicicletero'] as Map<String, dynamic>,
      ),
      bicicleta: bicicleta == null ? null : BicicletaApp.desdeJson(bicicleta),
      reportadaPorUsuario: UsuarioApp.desdeJson(
        json['reportadaPorUsuario'] as Map<String, dynamic>,
      ),
      gestionadaPorUsuario: gestionadaPorUsuario == null
          ? null
          : UsuarioApp.desdeJson(gestionadaPorUsuario),
    );
  }
}

class IncidenciaApi {
  IncidenciaApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<IncidenciaApp>> listar({
    String? estado,
    String? tipo,
    String? bicicleteroId,
    String? q,
    int? limite,
  }) async {
    final parametros = <String, String>{
      if (estado != null && estado != 'TODOS') 'estado': estado,
      if (tipo != null && tipo != 'TODOS') 'tipo': tipo,
      if (bicicleteroId != null && bicicleteroId.isNotEmpty)
        'bicicleteroId': bicicleteroId,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (limite != null && limite > 0) 'limite': limite.toString(),
    };
    final consulta =
        parametros.isEmpty ? '' : '?${Uri(queryParameters: parametros).query}';
    final respuesta = await cliente.get('/incidencias$consulta');
    final datos = respuesta['incidencias'] as List<dynamic>;

    return datos
        .map((item) => IncidenciaApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<IncidenciaApp> crear({
    required String bicicleteroId,
    required String tipo,
    required String descripcion,
    String? bicicletaId,
  }) async {
    final respuesta = await cliente.post(
      '/incidencias',
      body: {
        'bicicleteroId': bicicleteroId,
        'tipo': tipo,
        'descripcion': descripcion,
        if (bicicletaId != null && bicicletaId.isNotEmpty)
          'bicicletaId': bicicletaId,
      },
    );

    return IncidenciaApp.desdeJson(
      respuesta['incidencia'] as Map<String, dynamic>,
    );
  }

  Future<IncidenciaApp> actualizarEstado({
    required String incidenciaId,
    required String estado,
    String? respuesta,
  }) async {
    final datos = await cliente.patch(
      '/incidencias/$incidenciaId/estado',
      body: {
        'estado': estado,
        if (respuesta != null && respuesta.trim().isNotEmpty)
          'respuesta': respuesta.trim(),
      },
    );

    return IncidenciaApp.desdeJson(
      datos['incidencia'] as Map<String, dynamic>,
    );
  }
}
