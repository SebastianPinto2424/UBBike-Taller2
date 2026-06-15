import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../notificaciones/data/notificacion_repository.dart';
import '../../../shared/modelos/notificacion_app.dart';

class ControladorNotificacionesInicio extends ChangeNotifier {
  ControladorNotificacionesInicio({
    required NotificacionRepository notificacionRepository,
    Stream<void>? eventosTiempoReal,
    Duration intervalo = const Duration(seconds: 30),
  })  : _notificacionRepository = notificacionRepository,
        _eventosTiempoReal = eventosTiempoReal,
        _intervalo = intervalo;

  final NotificacionRepository _notificacionRepository;
  final Stream<void>? _eventosTiempoReal;
  final Duration _intervalo;
  final Set<String> _notificacionesConocidas = {};

  Timer? _temporizador;
  StreamSubscription<void>? _suscripcionTiempoReal;
  bool _inicializado = false;
  bool _actualizando = false;
  int _noLeidas = 0;
  NotificacionApp? _nuevaNotificacion;

  int get noLeidas => _noLeidas;
  NotificacionApp? get nuevaNotificacion => _nuevaNotificacion;

  void iniciar() {
    actualizar();
    _suscripcionTiempoReal = _eventosTiempoReal?.listen(
      (_) => actualizar(avisarNuevas: true),
    );
    _temporizador = Timer.periodic(
      _intervalo,
      (_) => actualizar(avisarNuevas: true),
    );
  }

  Future<void> actualizar({bool avisarNuevas = false}) async {
    if (_actualizando) {
      return;
    }

    _actualizando = true;
    try {
      final notificaciones = await _notificacionRepository.listar();
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
    } catch (_) {
    } finally {
      _actualizando = false;
    }
  }

  void marcarNuevaNotificacionMostrada() {
    _nuevaNotificacion = null;
  }

  void marcarTodasLeidas() {
    _noLeidas = 0;
    notifyListeners();
    _notificacionRepository.marcarTodasLeidas().catchError((_) {});
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _suscripcionTiempoReal?.cancel();
    super.dispose();
  }
}
