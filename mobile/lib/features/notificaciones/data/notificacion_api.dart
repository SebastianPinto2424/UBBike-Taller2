import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/notificacion_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class NotificacionApi {
  NotificacionApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<NotificacionApp>> listar() async {
    final respuesta = await cliente.get('/notificaciones');
    final datos = respuesta['notificaciones'] as List<dynamic>;
    return datos
        .map((item) => NotificacionApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> marcarTodasLeidas() async {
    await cliente.patch('/notificaciones/leidas');
  }

  Future<void> marcarLeida(String notificacionId) async {
    await cliente.patch('/notificaciones/$notificacionId/leida');
  }
}
