import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/repositorios_provider.dart';
import 'package:ubbike/shared/modelos/bicicleta_app.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';

class InicioUsuarioVm {
  const InicioUsuarioVm(this._ref);

  final Ref _ref;

  Future<BicicletaApp?> obtenerActiva() =>
      _ref.read(bicicletaRepositoryProvider).obtenerActiva();

  Future<List<BicicleteroApp>> listarBicicleteros() =>
      _ref.read(solicitudGuardiaRepositoryProvider).listarBicicleteros();
}

final inicioUsuarioVmProvider = Provider.autoDispose<InicioUsuarioVm>(
  (ref) => InicioUsuarioVm(ref),
);
