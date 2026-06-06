part of 'widgets_comun.dart';

Uint8List? decodificarFotoDataUrl(String? fotoDataUrl) {
  if (fotoDataUrl == null || !fotoDataUrl.startsWith('data:image')) {
    return null;
  }

  final partes = fotoDataUrl.split(',');
  if (partes.length < 2) {
    return null;
  }

  try {
    return base64Decode(partes.last);
  } on FormatException {
    return null;
  }
}

String resolverUrlFotoBicicleta(String fotoUrl) {
  if (fotoUrl.startsWith('data:image') ||
      fotoUrl.startsWith('http://') ||
      fotoUrl.startsWith('https://')) {
    return fotoUrl;
  }

  if (fotoUrl.startsWith('/')) {
    return '${ConfiguracionApi.baseUrl}$fotoUrl';
  }

  return fotoUrl;
}

String formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}

String formatearHora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}
