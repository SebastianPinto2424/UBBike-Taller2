import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configuracion/configuracion_api.dart';
import 'excepcion_api.dart';

class ClienteApi {
  static String? Function()? obtenerRefreshTokenGlobal;
  static String? Function()? obtenerUsuarioIdGlobal;
  static Future<void> Function(String token, String? refreshToken)?
      alActualizarTokensGlobal;
  static Future<void> Function()? alExpirarSesionGlobal;

  const ClienteApi({this.obtenerToken});

  final String? Function()? obtenerToken;

  Uri _uri(String ruta) => Uri.parse('${ConfiguracionApi.baseUrl}$ruta');

  Map<String, String> _headers() {
    final token = obtenerToken?.call();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String ruta) async {
    return _ejecutar(() => http.get(_uri(ruta), headers: _headers()));
  }

  Future<String> getTexto(String ruta) async {
    final respuesta = await http.get(_uri(ruta), headers: _headers());
    if (respuesta.statusCode >= 400) _procesarRespuesta(respuesta);
    return respuesta.body;
  }

  Future<Map<String, dynamic>> post(
    String ruta, {
    Map<String, dynamic>? body,
  }) async {
    return _ejecutar(
      () => http.post(
        _uri(ruta),
        headers: _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String ruta, {
    Map<String, dynamic>? body,
  }) async {
    return _ejecutar(
      () => http.patch(
        _uri(ruta),
        headers: _headers(),
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String ruta) async {
    return _ejecutar(() => http.delete(_uri(ruta), headers: _headers()));
  }

  Future<Map<String, dynamic>> _ejecutar(
    Future<http.Response> Function() solicitud,
  ) async {
    var respuesta = await solicitud();

    if (respuesta.statusCode == 401) {
      final refreshToken = obtenerRefreshTokenGlobal?.call();
      final usuarioId = obtenerUsuarioIdGlobal?.call();

      if (refreshToken != null &&
          usuarioId != null &&
          alActualizarTokensGlobal != null) {
        final reintentado = await _intentarRefresh(refreshToken, usuarioId);
        if (reintentado) {
          respuesta = await solicitud();
        }
      }
    }

    return _procesarRespuesta(respuesta);
  }

  static Future<bool> _intentarRefresh(
    String refreshToken,
    String usuarioId,
  ) async {
    try {
      final respuesta = await http.post(
        Uri.parse('${ConfiguracionApi.baseUrl}/autenticacion/refresh'),
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'usuarioId': usuarioId, 'refreshToken': refreshToken}),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final nuevoToken = datos['token'] as String;
        final nuevoRefreshToken = datos['refreshToken'] as String?;
        await alActualizarTokensGlobal!(nuevoToken, nuevoRefreshToken);
        return true;
      }
    } catch (_) {}

    await alExpirarSesionGlobal?.call();
    return false;
  }

  Map<String, dynamic> _procesarRespuesta(http.Response respuesta) {
    Map<String, dynamic> contenido;
    try {
      contenido = respuesta.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(respuesta.body) as Map<String, dynamic>;
    } on FormatException {
      contenido = <String, dynamic>{};
    }

    if (respuesta.statusCode >= 400) {
      final details = contenido['details'] as List?;
      final primerDetalle = details != null && details.isNotEmpty
          ? details.first.toString()
          : null;
      final mensaje = primerDetalle ?? contenido['message']?.toString();
      throw ExcepcionApi(
        _mensajeApiAmigable(mensaje) ?? 'Error ${respuesta.statusCode}',
      );
    }

    return contenido;
  }

  String? _mensajeApiAmigable(String? mensaje) {
    if (mensaje == null || mensaje.trim().isEmpty) {
      return null;
    }

    final texto = mensaje.trim();
    final textoLower = texto.toLowerCase();
    final campo = _campoDesdeMensajeJoi(texto);

    if (textoLower.contains('refresh token') ||
        textoLower.contains('token de autenticacion') ||
        textoLower.contains('token de autenticación')) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }
    if (textoLower.contains('token') && textoLower.contains('contrase')) {
      return 'El enlace para cambiar tu contraseña no es válido o expiró. Solicita uno nuevo.';
    }
    if (textoLower.contains('token') && textoLower.contains('registro')) {
      return 'El enlace de registro no es válido o expiró. Solicita uno nuevo para continuar.';
    }
    if (textoLower.contains('token') && textoLower.contains('verificaci')) {
      return 'El enlace de verificación no es válido o expiró. Solicita uno nuevo para continuar.';
    }
    if (textoLower.contains('"token"')) {
      return 'El enlace no es válido o expiró. Solicita uno nuevo para continuar.';
    }

    if (textoLower.contains('must be a valid email')) {
      return campo == null
          ? 'Ingresa un correo valido. Ej: usuario@ubiobio.cl'
          : 'Ingresa un $campo valido. Ej: usuario@ubiobio.cl';
    }
    if (textoLower.contains('is not allowed to be empty') ||
        textoLower.contains('is required')) {
      return campo == null ? 'Completa este campo.' : 'Completa $campo.';
    }
    if (textoLower.contains('length must be at least')) {
      return campo == null
          ? 'Ingresa mas caracteres.'
          : '$campo debe tener mas caracteres.';
    }
    if (textoLower.contains('length must be less than or equal to')) {
      return campo == null
          ? 'El texto ingresado es demasiado largo.'
          : '$campo es demasiado largo.';
    }
    if (textoLower.contains('fails to match the required pattern') ||
        textoLower.contains('must be one of') ||
        textoLower.contains('contains an invalid value')) {
      return campo == null ? 'Revisa el valor ingresado.' : 'Revisa $campo.';
    }
    if (texto.contains('"')) {
      return 'Revisa los datos ingresados.';
    }

    return texto;
  }

  String? _campoDesdeMensajeJoi(String mensaje) {
    final coincidencia = RegExp(r'"([^"]+)"').firstMatch(mensaje);
    if (coincidencia == null) {
      return null;
    }

    final campo = coincidencia.group(1);
    return switch (campo) {
      'correo' => 'correo',
      'contrasena' => 'contrasena',
      'nombre' => 'nombre',
      'rut' => 'RUT',
      'descripcion' => 'descripcion',
      'bicicletaDescripcion' => 'descripcion de bicicleta',
      'comentario' => 'comentario',
      'motivo' => 'motivo',
      'mensaje' => 'mensaje',
      _ => 'campo',
    };
  }
}
