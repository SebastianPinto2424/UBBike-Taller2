import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../servicios/cliente_api.dart';
import 'sesion_provider.dart';

final clienteApiProvider = Provider<ClienteApi>((ref) {
  final sesionState = ref.watch(sesionProvider).value;

  String? token;
  if (sesionState is SesionActiva) {
    token = sesionState.token;
  }

  return ClienteApi(obtenerToken: () => token);
});
