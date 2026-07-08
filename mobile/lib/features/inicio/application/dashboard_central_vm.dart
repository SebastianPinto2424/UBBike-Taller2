import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/features/acceso/data/solicitud_guardia_modelos.dart';
import 'package:ubbike/features/historial/data/historial_modelos.dart';
import 'package:ubbike/features/incidencias/data/incidencia_modelos.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';

class DatosDashboardCentral {
  const DatosDashboardCentral({
    required this.resumen,
    required this.bicicleteros,
    required this.solicitudes,
    required this.incidencias,
    required this.movimientosRecientes,
  });

  final ResumenHistorialApp resumen;
  final List<BicicleteroApp> bicicleteros;
  final List<SolicitudGuardiaApp> solicitudes;
  final List<IncidenciaApp> incidencias;
  final List<MovimientoApp> movimientosRecientes;

  int get capacidadTotal =>
      bicicleteros.fold(0, (total, item) => total + item.capacidad);

  int get ocupadosTotal =>
      bicicleteros.fold(0, (total, item) => total + item.ocupados);

  int get cuposDisponiblesTotal =>
      bicicleteros.fold(0, (total, item) => total + item.cuposDisponibles);

  double get usoCampus => capacidadTotal == 0
      ? 0.0
      : (ocupadosTotal / capacidadTotal).clamp(0.0, 1.0).toDouble();

  List<SolicitudGuardiaApp> get solicitudesAbiertas => solicitudes
      .where((s) => s.estado != 'RESUELTA' && s.estado != 'CANCELADA')
      .toList();

  List<IncidenciaApp> get incidenciasAbiertas => incidencias
      .where((i) => i.estado != 'RESUELTA' && i.estado != 'DESCARTADA')
      .toList();

  List<BicicleteroApp> get bicicleterosCriticos {
    final lista = bicicleteros
        .where((b) => b.porcentajeUso >= 75 || b.cuposDisponibles <= 5)
        .toList()
      ..sort((a, b) => b.porcentajeUso.compareTo(a.porcentajeUso));
    return lista;
  }
}

final periodoDashboardCentralProvider =
    StateProvider.autoDispose<String>((ref) => 'SEMANA');

class DashboardCentralVm extends AutoDisposeAsyncNotifier<DatosDashboardCentral> {
  @override
  Future<DatosDashboardCentral> build() {
    final periodo = ref.watch(periodoDashboardCentralProvider);
    final temporizador = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refrescar(),
    );
    ref.onDispose(temporizador.cancel);
    return _cargar(periodo);
  }

  Future<DatosDashboardCentral> _cargar(String periodo) async {
    final historialRepository = ref.read(historialRepositoryProvider);
    final solicitudGuardiaRepository =
        ref.read(solicitudGuardiaRepositoryProvider);
    final incidenciaRepository = ref.read(incidenciaRepositoryProvider);

    final resumenFuture = historialRepository.resumen(periodo: periodo);
    final bicicleterosFuture = solicitudGuardiaRepository.listarBicicleteros();
    final solicitudesFuture =
        solicitudGuardiaRepository.listarSolicitudes(limite: 300);
    final incidenciasFuture = incidenciaRepository.listar(limite: 300);
    final movimientosFuture =
        historialRepository.listar(periodo: 'DIA', limite: 3);

    return DatosDashboardCentral(
      resumen: await resumenFuture,
      bicicleteros: await bicicleterosFuture,
      solicitudes: await solicitudesFuture,
      incidencias: await incidenciasFuture,
      movimientosRecientes: await movimientosFuture,
    );
  }

  Future<void> refrescar() async {
    try {
      final datos = await _cargar(ref.read(periodoDashboardCentralProvider));
      state = AsyncData(datos);
    } catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  void cambiarPeriodo(String valor) {
    ref.read(periodoDashboardCentralProvider.notifier).state = valor;
  }
}

final dashboardCentralVmProvider = AsyncNotifierProvider.autoDispose<
    DashboardCentralVm, DatosDashboardCentral>(DashboardCentralVm.new);
