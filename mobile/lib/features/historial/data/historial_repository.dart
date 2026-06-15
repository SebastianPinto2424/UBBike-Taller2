import '../../../shared/modelos/movimiento_app.dart';
import 'historial_api.dart';
import 'historial_modelos.dart';

class HistorialRepository {
  const HistorialRepository(this._api);

  final HistorialApi _api;

  Future<List<MovimientoApp>> listar({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
    int? limite,
  }) =>
      _api.listar(
        filtro: filtro,
        periodo: periodo,
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        estado: estado,
        bicicleteroId: bicicleteroId,
        guardiaId: guardiaId,
        origen: origen,
        limite: limite,
      );

  Future<ResumenHistorialApp> resumen({
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
  }) =>
      _api.resumen(
        periodo: periodo,
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        estado: estado,
        bicicleteroId: bicicleteroId,
        guardiaId: guardiaId,
        origen: origen,
      );

  Future<OpcionesHistorialApp> opciones() => _api.opciones();

  Future<String> exportarExcel({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
  }) =>
      _api.exportarExcel(
        filtro: filtro,
        periodo: periodo,
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        estado: estado,
        bicicleteroId: bicicleteroId,
        guardiaId: guardiaId,
        origen: origen,
      );
}
