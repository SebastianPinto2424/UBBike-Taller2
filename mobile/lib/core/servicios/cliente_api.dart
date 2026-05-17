import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configuracion/configuracion_api.dart';
import 'excepcion_api.dart';

class ClienteApi {
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
    final respuesta = await http.get(_uri(ruta), headers: _headers());
    return _procesarRespuesta(respuesta);
  }

  Future<String> getTexto(String ruta) async {
    final respuesta = await http.get(_uri(ruta), headers: _headers());

    if (respuesta.statusCode >= 400) {
      _procesarRespuesta(respuesta);
    }

    return respuesta.body;
  }

  Future<Map<String, dynamic>> post(
    String ruta, {
    Map<String, dynamic>? body,
  }) async {
    final respuesta = await http.post(
      _uri(ruta),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _procesarRespuesta(respuesta);
  }

  Future<Map<String, dynamic>> patch(
    String ruta, {
    Map<String, dynamic>? body,
  }) async {
    final respuesta = await http.patch(
      _uri(ruta),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _procesarRespuesta(respuesta);
  }

  Future<Map<String, dynamic>> delete(String ruta) async {
    final respuesta = await http.delete(_uri(ruta), headers: _headers());
    return _procesarRespuesta(respuesta);
  }

  Map<String, dynamic> _procesarRespuesta(http.Response respuesta) {
    final contenido = respuesta.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(respuesta.body) as Map<String, dynamic>;

    if (respuesta.statusCode >= 400) {
      throw ExcepcionApi(
        contenido['message']?.toString() ?? 'No se pudo completar la acción',
      );
    }

    return contenido;
  }
}
