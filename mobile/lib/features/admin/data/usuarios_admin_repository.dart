import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';
import 'usuarios_admin_api.dart';

class UsuariosAdminRepository {
  const UsuariosAdminRepository(this._api);

  final UsuariosAdminApi _api;

  Future<List<UsuarioApp>> listarUsuarios({
    String? q,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) =>
      _api.listarUsuarios(
        q: q,
        rol: rol,
        cuentaActiva: cuentaActiva,
        correoVerificado: correoVerificado,
      );

  Future<UsuarioApp> crearUsuario({
    required String nombre,
    required String correo,
    required RolUsuario rol,
    required String contrasena,
    String? rut,
  }) =>
      _api.crearUsuario(
        nombre: nombre,
        correo: correo,
        rol: rol,
        contrasena: contrasena,
        rut: rut,
      );

  Future<UsuarioApp> actualizarPermisos({
    required String usuarioId,
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) =>
      _api.actualizarPermisos(
        usuarioId: usuarioId,
        nombre: nombre,
        correo: correo,
        rut: rut,
        rol: rol,
        cuentaActiva: cuentaActiva,
        correoVerificado: correoVerificado,
      );

  Future<void> eliminarUsuario(String usuarioId) =>
      _api.eliminarUsuario(usuarioId);
}
