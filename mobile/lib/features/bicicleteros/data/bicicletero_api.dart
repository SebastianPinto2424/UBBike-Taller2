import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class BicicleteroApi {
  BicicleteroApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<BicicleteroApp>> listar() async {
    final respuesta = await cliente.get('/bicicleteros');
    final datos = respuesta['bicicleteros'] as List<dynamic>;
    return datos
        .map((item) => BicicleteroApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }
}
