import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/acceso/data/acceso_api.dart';
import '../../features/acceso/data/acceso_repository.dart';
import '../../features/acceso/data/solicitud_guardia_api.dart';
import '../../features/acceso/data/solicitud_guardia_repository.dart';
import '../../features/admin/data/usuarios_admin_api.dart';
import '../../features/admin/data/usuarios_admin_repository.dart';
import '../../features/auth/data/autenticacion_api.dart';
import '../../features/auth/data/autenticacion_repository.dart';
import '../../features/bicicletas/data/bicicleta_api.dart';
import '../../features/bicicletas/data/bicicleta_repository.dart';
import '../../features/historial/data/historial_api.dart';
import '../../features/historial/data/historial_repository.dart';
import '../../features/incidencias/data/incidencia_api.dart';
import '../../features/incidencias/data/incidencia_repository.dart';
import '../../features/notificaciones/data/notificacion_api.dart';
import '../../features/notificaciones/data/notificacion_repository.dart';
import '../../features/qr/data/qr_api.dart';
import '../../features/qr/data/qr_repository.dart';
import 'cliente_api_provider.dart';

final autenticacionRepositoryProvider =
    Provider<AutenticacionRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return AutenticacionRepository(AutenticacionApi(cliente: cliente));
});

final bicicletaRepositoryProvider = Provider<BicicletaRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return BicicletaRepository(BicicletaApi(cliente: cliente));
});

final accesoRepositoryProvider = Provider<AccesoRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return AccesoRepository(AccesoApi(cliente: cliente));
});

final solicitudGuardiaRepositoryProvider =
    Provider<SolicitudGuardiaRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return SolicitudGuardiaRepository(SolicitudGuardiaApi(cliente: cliente));
});

final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return HistorialRepository(HistorialApi(cliente: cliente));
});

final incidenciaRepositoryProvider = Provider<IncidenciaRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return IncidenciaRepository(IncidenciaApi(cliente: cliente));
});

final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return NotificacionRepository(NotificacionApi(cliente: cliente));
});

final qrRepositoryProvider = Provider<QrRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return QrRepository(QrApi(cliente: cliente));
});

final usuariosAdminRepositoryProvider =
    Provider<UsuariosAdminRepository>((ref) {
  final cliente = ref.watch(clienteApiProvider);
  return UsuariosAdminRepository(UsuariosAdminApi(cliente: cliente));
});
