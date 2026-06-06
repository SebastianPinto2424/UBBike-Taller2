import '../modelos/usuario_app.dart';

class SesionActual {
  static String? token;
  static String? refreshToken;
  static UsuarioApp? usuario;

  static void iniciar({
    required String nuevoToken,
    required UsuarioApp nuevoUsuario,
    String? nuevoRefreshToken,
  }) {
    token = nuevoToken;
    usuario = nuevoUsuario;
    if (nuevoRefreshToken != null) refreshToken = nuevoRefreshToken;
  }

  static void cerrar() {
    token = null;
    refreshToken = null;
    usuario = null;
  }
}
