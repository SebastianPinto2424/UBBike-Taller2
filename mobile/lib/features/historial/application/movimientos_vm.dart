import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/features/historial/data/historial_modelos.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';

class FiltrosMovimientosUsuario {
  const FiltrosMovimientosUsuario({
    this.busqueda = '',
    this.periodo = 'MES',
    this.tipo = 'TODOS',
    this.estado = 'TODOS',
    this.origen = 'TODOS',
  });

  final String busqueda;
  final String periodo;
  final String tipo;
  final String estado;
  final String origen;

  FiltrosMovimientosUsuario copyWith({
    String? busqueda,
    String? periodo,
    String? tipo,
    String? estado,
    String? origen,
  }) {
    return FiltrosMovimientosUsuario(
      busqueda: busqueda ?? this.busqueda,
      periodo: periodo ?? this.periodo,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      origen: origen ?? this.origen,
    );
  }
}

final filtrosMovimientosUsuarioProvider =
    StateProvider.autoDispose<FiltrosMovimientosUsuario>(
  (ref) => const FiltrosMovimientosUsuario(),
);

class MovimientosUsuarioVm extends AutoDisposeAsyncNotifier<List<MovimientoApp>> {
  Timer? _debounceBusqueda;

  @override
  Future<List<MovimientoApp>> build() {
    final filtros = ref.watch(filtrosMovimientosUsuarioProvider);
    final temporizador = Timer.periodic(
      const Duration(seconds: 3),
      (_) => refrescar(),
    );
    ref.onDispose(() {
      temporizador.cancel();
      _debounceBusqueda?.cancel();
    });
    return _cargar(filtros);
  }

  Future<List<MovimientoApp>> _cargar(FiltrosMovimientosUsuario filtros) {
    return ref.read(historialRepositoryProvider).listar(
          filtro: filtros.busqueda,
          periodo: filtros.periodo,
          tipo: filtros.tipo,
          estado: filtros.estado,
          origen: filtros.origen,
        );
  }

  Future<void> refrescar() async {
    try {
      final datos = await _cargar(ref.read(filtrosMovimientosUsuarioProvider));
      state = AsyncData(datos);
    } catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError(error, stackTrace);
      }
    }
  }

  void recargar() {
    ref.invalidateSelf();
  }

  void buscar(String valor) {
    _debounceBusqueda?.cancel();
    _debounceBusqueda = Timer(const Duration(milliseconds: 350), () {
      final filtros = ref.read(filtrosMovimientosUsuarioProvider);
      ref.read(filtrosMovimientosUsuarioProvider.notifier).state =
          filtros.copyWith(busqueda: valor.trim());
    });
  }

  void cambiarFiltros({
    String? periodo,
    String? tipo,
    String? estado,
    String? origen,
  }) {
    final filtros = ref.read(filtrosMovimientosUsuarioProvider);
    ref.read(filtrosMovimientosUsuarioProvider.notifier).state =
        filtros.copyWith(
      periodo: periodo,
      tipo: tipo,
      estado: estado,
      origen: origen,
    );
  }

  void limpiarFiltros() {
    _debounceBusqueda?.cancel();
    ref.read(filtrosMovimientosUsuarioProvider.notifier).state =
        const FiltrosMovimientosUsuario();
  }
}

final movimientosUsuarioVmProvider = AsyncNotifierProvider.autoDispose<
    MovimientosUsuarioVm, List<MovimientoApp>>(MovimientosUsuarioVm.new);

class MovimientosCentralVm {
  const MovimientosCentralVm(this._ref);

  final Ref _ref;

  Future<List<MovimientoApp>> listar({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
    int? limite,
  }) =>
      _ref.read(historialRepositoryProvider).listar(
            filtro: filtro,
            periodo: periodo,
            desde: desde,
            hasta: hasta,
            tipo: tipo,
            estado: estado,
            bicicleteroId: bicicleteroId,
            guardiaId: guardiaId,
            origen: origen,
            limite: limite,
          );

  Future<OpcionesHistorialApp> opciones() =>
      _ref.read(historialRepositoryProvider).opciones();

  Future<String> exportarExcel({
    String? filtro,
    String? periodo,
    DateTime? desde,
    DateTime? hasta,
    String? tipo,
    String? estado,
    String? bicicleteroId,
    String? guardiaId,
    String? origen,
  }) =>
      _ref.read(historialRepositoryProvider).exportarExcel(
            filtro: filtro,
            periodo: periodo,
            desde: desde,
            hasta: hasta,
            tipo: tipo,
            estado: estado,
            bicicleteroId: bicicleteroId,
            guardiaId: guardiaId,
            origen: origen,
          );
}

final movimientosCentralVmProvider = Provider.autoDispose<MovimientosCentralVm>(
  (ref) => MovimientosCentralVm(ref),
);
