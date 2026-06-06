import 'package:flutter/services.dart';

Future<String> descargarReporteTexto({
  required String nombreArchivo,
  required String contenido,
  String tipoMime = 'text/plain;charset=utf-8',
}) async {
  await Clipboard.setData(ClipboardData(text: contenido));
  return 'Reporte copiado al portapapeles';
}
