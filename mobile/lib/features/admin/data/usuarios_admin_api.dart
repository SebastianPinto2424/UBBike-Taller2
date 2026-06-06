import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/servicios/sesion_actual.dart';

class UsuariosAdminApi {
  UsuariosAdminApi()
      : cliente = ClienteApi(obtenerToken: () => SesionActual.token);

  final ClienteApi cliente;

  Future<List<UsuarioApp>> listarUsuarios({
    String? q,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    final parametros = <String, String>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (rol != null) 'rol': rol.valorApi,
      if (cuentaActiva != null) 'cuentaActiva': cuentaActiva.toString(),
      if (correoVerificado != null)
        'correoVerificado': correoVerificado.toString(),
    };
    final consulta =
        parametros.isEmpty ? '' : '?${Uri(queryParameters: parametros).query}';
    final respuesta = await cliente.get('/usuarios$consulta');
    final datos = respuesta['usuarios'] as List<dynamic>;
    return datos
        .map((item) => UsuarioApp.desdeJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioApp> actualizarPermisos({
    required String usuarioId,
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    final respuesta = await cliente.patch(
      '/usuarios/$usuarioId/permisos',
      body: {
        if (nombre != null) 'nombre': nombre,
        if (correo != null) 'correo': correo,
        if (rut != null) 'rut': rut,
        if (rol != null) 'rol': rol.valorApi,
        if (cuentaActiva != null) 'cuentaActiva': cuentaActiva,
        if (correoVerificado != null) 'correoVerificado': correoVerificado,
      },
    );

    return UsuarioApp.desdeJson(respuesta['usuario'] as Map<String, dynamic>);
  }
}
