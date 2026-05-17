import 'rol_usuario.dart';

class UsuarioApp {
  const UsuarioApp({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.correoVerificado,
    required this.cuentaActiva,
    this.rut,
  });

  final String id;
  final String nombre;
  final String correo;
  final String? rut;
  final RolUsuario rol;
  final bool correoVerificado;
  final bool cuentaActiva;

  factory UsuarioApp.desdeJson(Map<String, dynamic> json) {
    return UsuarioApp(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      rut: json['rut'] as String?,
      rol: EtiquetaRolUsuario.desdeApi(json['rol'] as String),
      correoVerificado: json['correoVerificado'] as bool? ?? false,
      cuentaActiva: json['cuentaActiva'] as bool? ?? true,
    );
  }
}
