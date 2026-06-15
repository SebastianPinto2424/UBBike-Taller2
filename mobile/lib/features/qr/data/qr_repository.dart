import 'qr_api.dart';
import 'qr_modelos.dart';

class QrRepository {
  const QrRepository(this._api);

  final QrApi _api;

  Future<QrTemporalApp> generar({
    String? bicicletaId,
    String? bicicleteroId,
    String? tipo,
  }) =>
      _api.generar(
        bicicletaId: bicicletaId,
        bicicleteroId: bicicleteroId,
        tipo: tipo,
      );
}
