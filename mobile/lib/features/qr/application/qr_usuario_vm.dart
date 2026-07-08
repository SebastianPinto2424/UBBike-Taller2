import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/features/qr/data/qr_modelos.dart';
import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';

class QrUsuarioVm {
  const QrUsuarioVm(this._ref);

  final Ref _ref;

  Future<QrTemporalApp> generar({
    String? bicicletaId,
    String? bicicleteroId,
    String? tipo,
  }) =>
      _ref.read(qrRepositoryProvider).generar(
            bicicletaId: bicicletaId,
            bicicleteroId: bicicleteroId,
            tipo: tipo,
          );

  Future<BicicletaApp?> obtenerActiva() =>
      _ref.read(bicicletaRepositoryProvider).obtenerActiva();

  Future<List<BicicleteroApp>> listarBicicleteros() =>
      _ref.read(solicitudGuardiaRepositoryProvider).listarBicicleteros();
}

final qrUsuarioVmProvider = Provider.autoDispose<QrUsuarioVm>(
  (ref) => QrUsuarioVm(ref),
);
