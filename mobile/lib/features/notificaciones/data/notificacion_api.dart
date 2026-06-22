import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/notificacion_app.dart';

class NotificacionApi {
  const NotificacionApi({required this.cliente});

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

  Future<void> registrarDispositivo(String token,
      {String plataforma = 'android'}) async {
    await cliente.post(
      '/notificaciones/dispositivos',
      body: {'token': token, 'plataforma': plataforma},
    );
  }

  Future<void> eliminarDispositivo(String token) async {
    await cliente.delete('/notificaciones/dispositivos', body: {'token': token});
  }
}
