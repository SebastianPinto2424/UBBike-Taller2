import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class BicicletaApi {
  BicicletaApi() : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<BicicletaApp>> listar() async {
    final respuesta = await cliente.get('/bicicletas');
    final datos = respuesta['bicicletas'] as List<dynamic>;
    return datos
        .map((item) => BicicletaApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BicicletaApp?> obtenerActiva() async {
    final respuesta = await cliente.get('/bicicletas/activa');
    final datos = respuesta['bicicleta'];

    if (datos == null) {
      return null;
    }

    return BicicletaApp.desdeJson(datos as Map<String, dynamic>);
  }

  Future<void> crear({
    required String descripcion,
    String? marca,
    String? modelo,
    String? color,
    String? aro,
    String? numeroSerie,
    String? fotoUrl,
    bool activar = false,
  }) async {
    await cliente.post(
      '/bicicletas',
      body: {
        'descripcion': descripcion,
        'marca': marca,
        'modelo': modelo,
        'color': color,
        'aro': aro,
        'numeroSerie': numeroSerie,
        'fotoUrl': fotoUrl,
        'activar': activar,
      },
    );
  }

  Future<void> actualizar({
    required String bicicletaId,
    required String descripcion,
    String? marca,
    String? modelo,
    String? color,
    String? aro,
    String? numeroSerie,
    String? fotoUrl,
  }) async {
    await cliente.patch(
      '/bicicletas/$bicicletaId',
      body: {
        'descripcion': descripcion,
        'marca': marca,
        'modelo': modelo,
        'color': color,
        'aro': aro,
        'numeroSerie': numeroSerie,
        'fotoUrl': fotoUrl,
      },
    );
  }

  Future<void> eliminar(String bicicletaId) async {
    await cliente.delete('/bicicletas/$bicicletaId');
  }

  Future<void> activar(String bicicletaId) async {
    await cliente.patch('/bicicletas/$bicicletaId/activar');
  }

  Future<void> desactivar(String bicicletaId) async {
    await cliente.patch('/bicicletas/$bicicletaId/desactivar');
  }
}
