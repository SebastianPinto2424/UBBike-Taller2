import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:ubbike/core/configuracion/configuracion_api.dart';

class TiempoRealService {
  io.Socket? _socket;
  String? _tokenActual;

  final _notificacionesController = StreamController<void>.broadcast();
  final _solicitudesController = StreamController<void>.broadcast();

  Stream<void> get notificaciones => _notificacionesController.stream;
  Stream<void> get solicitudes => _solicitudesController.stream;

  void conectar(String token) {
    final tokenLimpio = token.trim();
    if (tokenLimpio.isEmpty) {
      desconectar();
      return;
    }

    if (_socket != null && _tokenActual == tokenLimpio) {
      if (_socket?.connected != true) {
        _socket?.connect();
      }
      return;
    }

    desconectar();
    _tokenActual = tokenLimpio;

    final socket = io.io(
      ConfiguracionApi.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(1000)
          .setTimeout(8000)
          .setAuth({'token': tokenLimpio})
          .build(),
    );

    socket.on('notificacion', (_) {
      if (!_notificacionesController.isClosed) {
        _notificacionesController.add(null);
      }
    });
    socket.on('solicitud', (_) {
      if (!_solicitudesController.isClosed) {
        _solicitudesController.add(null);
      }
    });

    _socket = socket;
    socket.connect();
  }

  void desconectar() {
    final socket = _socket;
    if (socket != null) {
      socket.disconnect();
      socket.dispose();
    }
    _socket = null;
    _tokenActual = null;
  }

  void dispose() {
    desconectar();
    _notificacionesController.close();
    _solicitudesController.close();
  }
}
