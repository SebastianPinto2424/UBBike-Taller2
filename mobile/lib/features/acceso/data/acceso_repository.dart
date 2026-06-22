import '../../../shared/modelos/movimiento_app.dart';
import 'acceso_api.dart';
import 'acceso_modelos.dart';

class AccesoRepository {
  const AccesoRepository(this._api);

  final AccesoApi _api;

  Future<CoincidenciaManualApp?> buscarCoincidenciaManual({
    String? correo,
    String? rut,
  }) =>
      _api.buscarCoincidenciaManual(correo: correo, rut: rut);

  Future<QrValidadoApp> validarQr(String token) => _api.validarQr(token);

  Future<MovimientoApp> confirmarQr(String token, {String? comentario}) =>
      _api.confirmarQr(token, comentario: comentario);

  Future<MovimientoApp> denegarQr({
    required String token,
    required String motivo,
  }) =>
      _api.denegarQr(token: token, motivo: motivo);

  Future<MovimientoApp> registrarManual({
    String? nombre,
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
  }) =>
      _api.registrarManual(
        nombre: nombre,
        correo: correo,
        rut: rut,
        bicicletaId: bicicletaId,
        bicicleteroId: bicicleteroId,
        tipo: tipo,
        denegar: denegar,
        motivo: motivo,
        comentario: comentario,
        bicicletaDescripcion: bicicletaDescripcion,
        bicicletaMarca: bicicletaMarca,
        bicicletaModelo: bicicletaModelo,
        bicicletaColor: bicicletaColor,
        bicicletaAro: bicicletaAro,
        bicicletaNumeroSerie: bicicletaNumeroSerie,
        bicicletaFotoUrl: bicicletaFotoUrl,
        crearBicicletaNueva: crearBicicletaNueva,
      );
}
