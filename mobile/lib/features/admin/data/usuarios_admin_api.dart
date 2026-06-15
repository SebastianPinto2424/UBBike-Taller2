import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';

class UsuariosAdminApi {
  const UsuariosAdminApi({required this.cliente});

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

  Future<UsuarioApp> crearUsuario({
    required String nombre,
    required String correo,
    required RolUsuario rol,
    required String contrasena,
    String? rut,
  }) async {
    final respuesta = await cliente.post(
      '/usuarios',
      body: {
        'nombre': nombre,
        'correo': correo,
        'rol': rol.valorApi,
        'contrasena': contrasena,
        if (rut != null && rut.trim().isNotEmpty) 'rut': rut.trim(),
      },
    );

    return UsuarioApp.desdeJson(respuesta['usuario'] as Map<String, dynamic>);
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

  Future<void> eliminarUsuario(String usuarioId) async {
    await cliente.delete('/usuarios/$usuarioId');
  }
}
