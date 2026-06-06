import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../notificaciones/data/notificacion_api.dart';
import '../../../shared/modelos/notificacion_app.dart';

class ControladorNotificacionesInicio extends ChangeNotifier {
  ControladorNotificacionesInicio({
    NotificacionApi? notificacionApi,
    Duration intervalo = const Duration(seconds: 5),
  })  : _notificacionApi = notificacionApi ?? NotificacionApi(),
        _intervalo = intervalo;

  final NotificacionApi _notificacionApi;
  final Duration _intervalo;
  final Set<String> _notificacionesConocidas = {};

  Timer? _temporizador;
  bool _inicializado = false;
  int _noLeidas = 0;
  NotificacionApp? _nuevaNotificacion;

  int get noLeidas => _noLeidas;
  NotificacionApp? get nuevaNotificacion => _nuevaNotificacion;

  void iniciar() {
    actualizar();
    _temporizador = Timer.periodic(
      _intervalo,
      (_) => actualizar(avisarNuevas: true),
    );
  }

  Future<void> actualizar({bool avisarNuevas = false}) async {
    try {
      final notificaciones = await _notificacionApi.listar();
      final nuevas = notificaciones
          .where(
            (notificacion) =>
                !notificacion.leida &&
                !_notificacionesConocidas.contains(notificacion.id),
          )
          .toList();

      _notificacionesConocidas
        ..clear()
        ..addAll(notificaciones.map((notificacion) => notificacion.id));
      _noLeidas =
          notificaciones.where((notificacion) => !notificacion.leida).length;
      _nuevaNotificacion = avisarNuevas && _inicializado && nuevas.isNotEmpty
          ? nuevas.first
          : null;
      _inicializado = true;
      notifyListeners();
    } catch (_) {}
  }

  void marcarNuevaNotificacionMostrada() {
    _nuevaNotificacion = null;
  }

  void marcarTodasLeidas() {
    _noLeidas = 0;
    notifyListeners();
    _notificacionApi.marcarTodasLeidas().catchError((_) {});
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}
