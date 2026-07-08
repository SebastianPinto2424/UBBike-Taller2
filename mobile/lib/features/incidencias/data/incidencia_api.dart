import 'package:ubbike/core/servicios/cliente_api.dart';
import 'package:ubbike/features/incidencias/data/incidencia_modelos.dart';

class IncidenciaApi {
  const IncidenciaApi({required this.cliente});

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
