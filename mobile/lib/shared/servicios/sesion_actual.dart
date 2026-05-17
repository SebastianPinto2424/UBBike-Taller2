import '../modelos/usuario_app.dart';

class SesionActual {
  static String? token;
  static UsuarioApp? usuario;

  static void iniciar({
    required String nuevoToken,
    required UsuarioApp nuevoUsuario,
  }) {
    token = nuevoToken;
    usuario = nuevoUsuario;
  }

  static void cerrar() {
    token = null;
    usuario = null;
  }
}
