class NotificacionApp {
  const NotificacionApp({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.creadaEn,
    required this.datos,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime creadaEn;
  final Map<String, dynamic> datos;

  bool get accionPropia => datos['accionPropia'] == true;
  bool get muestraAccionVer => !accionPropia;
  String get tituloVisible => _normalizarTituloNotificacion(titulo, mensaje);
  String get mensajeVisible => _normalizarMensajeNotificacion(mensaje);

  factory NotificacionApp.desdeJson(Map<String, dynamic> json) {
    return NotificacionApp(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      tipo: json['tipo'] as String,
      leida: json['leida'] as bool? ?? false,
      creadaEn: DateTime.parse(json['creadaEn'] as String),
      datos: (json['datos'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }
}

String _normalizarTituloNotificacion(String titulo, String mensaje) {
  if (titulo == 'Recordatorio enviado' &&
      mensaje.startsWith('Enviamos un nuevo aviso al guardia para ')) {
    return 'Guardia notificado';
  }
  if (titulo == 'Atención solicitada' &&
      mensaje.startsWith('Notificamos al guardia asignado para ')) {
    return 'Guardia notificado';
  }

  return titulo;
}

String _normalizarMensajeNotificacion(String mensaje) {
  const recordatorioAntiguo = 'Enviamos un nuevo aviso al guardia para ';
  const solicitudAntigua = 'Notificamos al guardia asignado para ';

  if (mensaje.startsWith(recordatorioAntiguo)) {
    final bicicletero = mensaje.substring(recordatorioAntiguo.length);
    return 'Tu recordatorio fue enviado al guardia asignado a $bicicletero';
  }

  if (mensaje.startsWith(solicitudAntigua)) {
    final bicicletero = mensaje.substring(solicitudAntigua.length);
    return 'Tu solicitud fue enviada al guardia asignado a $bicicletero';
  }

  return mensaje;
}
