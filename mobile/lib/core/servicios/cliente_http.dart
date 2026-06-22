import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../configuracion/configuracion_api.dart';

http.Client clienteHttp = http.Client();

Future<void> inicializarClienteHttp() async {

  if (kIsWeb) {
    return;
  }

  if (!ConfiguracionApi.baseUrl.startsWith('https')) {
    return;
  }

  try {

    final contexto = SecurityContext(withTrustedRoots: false);
    final certificado = await rootBundle.load('assets/certs/ubbike.crt');
    contexto.setTrustedCertificatesBytes(certificado.buffer.asUint8List());
    clienteHttp = IOClient(HttpClient(context: contexto));
  } catch (error) {

    if (kDebugMode) {
      debugPrint('No se pudo cargar el certificado pinned: $error');
    }
  }
}
