import '../../../shared/modelos/notificacion_app.dart';
import 'notificacion_api.dart';

class NotificacionRepository {
  const NotificacionRepository(this._api);

  final NotificacionApi _api;

  Future<List<NotificacionApp>> listar() => _api.listar();

  Future<void> marcarTodasLeidas() => _api.marcarTodasLeidas();

  Future<void> marcarLeida(String notificacionId) =>
      _api.marcarLeida(notificacionId);
}
