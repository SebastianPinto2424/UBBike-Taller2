import 'package:ubbike/features/incidencias/data/incidencia_api.dart';
import 'package:ubbike/features/incidencias/data/incidencia_modelos.dart';

class IncidenciaRepository {
  const IncidenciaRepository(this._api);

  final IncidenciaApi _api;

  Future<List<IncidenciaApp>> listar({
    String? estado,
    String? tipo,
    String? bicicleteroId,
    String? q,
    int? limite,
  }) =>
      _api.listar(
        estado: estado,
        tipo: tipo,
        bicicleteroId: bicicleteroId,
        q: q,
        limite: limite,
      );

  Future<IncidenciaApp> crear({
    required String bicicleteroId,
    required String tipo,
    required String descripcion,
    String? bicicletaId,
  }) =>
      _api.crear(
        bicicleteroId: bicicleteroId,
        tipo: tipo,
        descripcion: descripcion,
        bicicletaId: bicicletaId,
      );

  Future<IncidenciaApp> actualizarEstado({
    required String incidenciaId,
    required String estado,
    String? respuesta,
  }) =>
      _api.actualizarEstado(
        incidenciaId: incidenciaId,
        estado: estado,
        respuesta: respuesta,
      );
}
