import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/features/incidencias/data/incidencia_modelos.dart';
import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';

class FiltrosIncidencias {
  const FiltrosIncidencias({
    this.estado = 'TODOS',
    this.tipo = 'TODOS',
    this.busqueda = '',
  });

  final String estado;
  final String tipo;
  final String busqueda;

  FiltrosIncidencias copyWith({String? estado, String? tipo, String? busqueda}) {
    return FiltrosIncidencias(
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

final filtrosIncidenciasProvider =
    StateProvider.autoDispose<FiltrosIncidencias>(
  (ref) => const FiltrosIncidencias(),
);

class IncidenciasVm extends AutoDisposeAsyncNotifier<List<IncidenciaApp>> {
  Timer? _debounceBusqueda;

  @override
  Future<List<IncidenciaApp>> build() {
    final filtros = ref.watch(filtrosIncidenciasProvider);
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

  Future<List<IncidenciaApp>> _cargar(FiltrosIncidencias filtros) {
    return ref.read(incidenciaRepositoryProvider).listar(
          estado: filtros.estado,
          tipo: filtros.tipo,
          q: filtros.busqueda,
        );
  }

  Future<void> refrescar() async {
    try {
      final datos = await _cargar(ref.read(filtrosIncidenciasProvider));
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
      final filtros = ref.read(filtrosIncidenciasProvider);
      ref.read(filtrosIncidenciasProvider.notifier).state =
          filtros.copyWith(busqueda: valor.trim());
    });
  }

  void cambiarEstado(String valor) {
    final filtros = ref.read(filtrosIncidenciasProvider);
    ref.read(filtrosIncidenciasProvider.notifier).state =
        filtros.copyWith(estado: valor);
  }

  void cambiarTipo(String valor) {
    final filtros = ref.read(filtrosIncidenciasProvider);
    ref.read(filtrosIncidenciasProvider.notifier).state =
        filtros.copyWith(tipo: valor);
  }

  void limpiarFiltros() {
    _debounceBusqueda?.cancel();
    ref.read(filtrosIncidenciasProvider.notifier).state =
        const FiltrosIncidencias();
  }

  Future<void> crear({
    required String bicicleteroId,
    required String tipo,
    required String descripcion,
    String? bicicletaId,
  }) async {
    await ref.read(incidenciaRepositoryProvider).crear(
          bicicleteroId: bicicleteroId,
          tipo: tipo,
          descripcion: descripcion,
          bicicletaId: bicicletaId,
        );
    recargar();
  }

  Future<void> actualizarEstado({
    required String incidenciaId,
    required String estado,
    String? respuesta,
  }) async {
    await ref.read(incidenciaRepositoryProvider).actualizarEstado(
          incidenciaId: incidenciaId,
          estado: estado,
          respuesta: respuesta,
        );
    recargar();
  }
}

final incidenciasVmProvider =
    AsyncNotifierProvider.autoDispose<IncidenciasVm, List<IncidenciaApp>>(
  IncidenciasVm.new,
);

class DatosFormularioIncidencia {
  const DatosFormularioIncidencia({
    required this.bicicleteros,
    required this.bicicletas,
  });

  final List<BicicleteroApp> bicicleteros;
  final List<BicicletaApp> bicicletas;
}

final datosFormularioIncidenciaProvider = FutureProvider.autoDispose
    .family<DatosFormularioIncidencia,
        ({bool gestionGuardia, bool permitirBicicletaPropia})>(
  (ref, args) async {
    final solicitudGuardiaRepository =
        ref.read(solicitudGuardiaRepositoryProvider);
    final datosBicicletero = args.gestionGuardia
        ? await solicitudGuardiaRepository.obtenerBicicleteroGestionado()
        : null;
    final bicicleteros = args.gestionGuardia
        ? [if (datosBicicletero != null) datosBicicletero]
        : await solicitudGuardiaRepository.listarBicicleteros();
    final bicicletas = args.permitirBicicletaPropia
        ? await ref.read(bicicletaRepositoryProvider).listar()
        : <BicicletaApp>[];

    return DatosFormularioIncidencia(
      bicicleteros: bicicleteros,
      bicicletas: bicicletas,
    );
  },
);
