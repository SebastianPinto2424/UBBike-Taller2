import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> descargarReporteTexto({
  required String nombreArchivo,
  required String contenido,
  String tipoMime = 'text/plain;charset=utf-8',
}) async {
  final blob = web.Blob(
    <web.BlobPart>[contenido.toJS].toJS,
    web.BlobPropertyBag(type: tipoMime),
  );
  final url = web.URL.createObjectURL(blob);

  web.HTMLAnchorElement()
    ..href = url
    ..download = nombreArchivo
    ..click();

  web.URL.revokeObjectURL(url);
  return 'Reporte descargado';
}
