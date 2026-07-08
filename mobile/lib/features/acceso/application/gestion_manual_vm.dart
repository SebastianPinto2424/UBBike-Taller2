import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/features/acceso/data/acceso_modelos.dart';
import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';

class GestionManualVm {
  const GestionManualVm(this._ref);

  final Ref _ref;

  Future<List<BicicleteroApp>> listarBicicleteros() =>
      _ref.read(solicitudGuardiaRepositoryProvider).listarBicicleteros();

  Future<CoincidenciaManualApp?> buscarCoincidencia({
    required String correo,
    required String rut,
  }) =>
      _ref.read(accesoRepositoryProvider).buscarCoincidenciaManual(
            correo: correo,
            rut: rut,
          );

  Future<MovimientoApp> registrarManual({
    required String nombre,
    required String correo,
    required String rut,
    String? bicicletaId,
    String? bicicleteroId,
    required String tipo,
    required String comentario,
    required String bicicletaDescripcion,
    required String bicicletaMarca,
    required String bicicletaModelo,
    required String bicicletaColor,
    required String bicicletaAro,
    required String bicicletaNumeroSerie,
    String? bicicletaFotoUrl,
    required bool crearBicicletaNueva,
    required bool denegar,
    String? motivo,
  }) =>
      _ref.read(accesoRepositoryProvider).registrarManual(
            nombre: nombre,
            correo: correo,
            rut: rut,
            bicicletaId: bicicletaId,
            bicicleteroId: bicicleteroId,
            tipo: tipo,
            comentario: comentario,
            bicicletaDescripcion: bicicletaDescripcion,
            bicicletaMarca: bicicletaMarca,
            bicicletaModelo: bicicletaModelo,
            bicicletaColor: bicicletaColor,
            bicicletaAro: bicicletaAro,
            bicicletaNumeroSerie: bicicletaNumeroSerie,
            bicicletaFotoUrl: bicicletaFotoUrl,
            crearBicicletaNueva: crearBicicletaNueva,
            denegar: denegar,
            motivo: motivo,
          );

  bool datoBusquedaSuficiente(String correo, String rut) {
    final rutLimpio = rut.replaceAll('.', '').replaceAll('-', '');
    return correo.contains('@') || rutLimpio.length >= 7;
  }

  BicicletaApp? bicicletaPreferidaAutodetectada(List<BicicletaApp> bicicletas) {
    if (bicicletas.isEmpty) {
      return null;
    }

    final dentroActivas = bicicletas.where(
      (bicicleta) => bicicleta.dentroBicicletero && bicicleta.activa,
    );
    if (dentroActivas.isNotEmpty) {
      return dentroActivas.first;
    }

    final dentro = bicicletas.where((bicicleta) => bicicleta.dentroBicicletero);
    if (dentro.isNotEmpty) {
      return dentro.first;
    }

    final activas = bicicletas.where((bicicleta) => bicicleta.activa);
    if (activas.isNotEmpty) {
      return activas.first;
    }

    return bicicletas.first;
  }

  String operacionParaBicicleta(BicicletaApp bicicleta) {
    return bicicleta.dentroBicicletero ? 'RETIRO' : 'INGRESO';
  }
}

final gestionManualVmProvider = Provider.autoDispose<GestionManualVm>(
  (ref) => GestionManualVm(ref),
);
