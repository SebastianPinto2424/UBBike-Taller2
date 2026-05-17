import '../../../core/servicios/cliente_api.dart';
import '../../../shared/modelos/usuario_app.dart';

class ResultadoLogin {
  const ResultadoLogin({required this.token, required this.usuario});

  final String token;
  final UsuarioApp usuario;
}

class AutenticacionApi {
  AutenticacionApi({ClienteApi? cliente})
      : cliente = cliente ?? const ClienteApi();

  final ClienteApi cliente;

  Future<ResultadoLogin> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final respuesta = await cliente.post(
      '/autenticacion/login',
      body: {
        'correo': correo,
        'contrasena': contrasena,
      },
    );

    return ResultadoLogin(
      token: respuesta['token'] as String,
      usuario:
          UsuarioApp.desdeJson(respuesta['usuario'] as Map<String, dynamic>),
    );
  }

  Future<String> registrar({
    required String nombre,
    required String rut,
    required String correo,
    required String contrasena,
  }) async {
    final respuesta = await cliente.post(
      '/autenticacion/registro',
      body: {
        'nombre': nombre,
        'rut': rut,
        'correo': correo,
        'contrasena': contrasena,
      },
    );

    return respuesta['message'] as String;
  }

  Future<String> solicitarCambioContrasena(String correo) async {
    final respuesta = await cliente.post(
      '/autenticacion/solicitar-cambio-contrasena',
      body: {'correo': correo},
    );

    return respuesta['message'] as String;
  }

  Future<String> verificarCorreo(String token) async {
    final respuesta = await cliente.post(
      '/autenticacion/verificar-correo',
      body: {'token': token},
    );

    return respuesta['message'] as String;
  }

  Future<String> cambiarContrasena({
    required String token,
    required String contrasena,
  }) async {
    final respuesta = await cliente.post(
      '/autenticacion/cambiar-contrasena',
      body: {
        'token': token,
        'contrasena': contrasena,
      },
    );

    return respuesta['message'] as String;
  }
}
