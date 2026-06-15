import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../servicios/cliente_api.dart';
import '../../features/auth/data/autenticacion_api.dart';
import '../../features/auth/data/autenticacion_repository.dart';
import '../../shared/modelos/rol_usuario.dart';
import '../../shared/modelos/usuario_app.dart';

sealed class SesionState {
  const SesionState();
}

class SesionCargando extends SesionState {
  const SesionCargando();
}

class SesionVacia extends SesionState {
  const SesionVacia();
}

class SesionActiva extends SesionState {
  const SesionActiva({
    required this.usuario,
    required this.token,
    this.refreshToken,
  });

  final UsuarioApp usuario;
  final String token;
  final String? refreshToken;
}

const _storageKeyToken = 'ubbike_jwt';
const _storageKeyRefreshToken = 'ubbike_refresh';
const _storageKeyUsuarioId = 'ubbike_usuario_id';
const _storageKeyUsuarioNombre = 'ubbike_usuario_nombre';
const _storageKeyUsuarioCorreo = 'ubbike_usuario_correo';
const _storageKeyUsuarioRol = 'ubbike_usuario_rol';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class SesionNotifier extends AsyncNotifier<SesionState> {
  @override
  Future<SesionState> build() async {
    return _restaurarSesion();
  }

  Future<SesionState> _restaurarSesion() async {
    try {
      final token = await _storage.read(key: _storageKeyToken);
      final refreshToken = await _storage.read(key: _storageKeyRefreshToken);

      if (token == null) return const SesionVacia();

      final repository = AutenticacionRepository(
        AutenticacionApi(cliente: ClienteApi(obtenerToken: () => token)),
      );
      final usuario = await repository.obtenerPerfil();

      return SesionActiva(
        usuario: usuario,
        token: token,
        refreshToken: refreshToken,
      );
    } catch (_) {
      await _limpiarStorage();
      return const SesionVacia();
    }
  }

  Future<void> iniciar({
    required String token,
    required UsuarioApp usuario,
    String? refreshToken,
  }) async {
    await _storage.write(key: _storageKeyToken, value: token);
    await _storage.write(key: _storageKeyUsuarioId, value: usuario.id);
    await _storage.write(key: _storageKeyUsuarioNombre, value: usuario.nombre);
    await _storage.write(key: _storageKeyUsuarioCorreo, value: usuario.correo);
    await _storage.write(
      key: _storageKeyUsuarioRol,
      value: usuario.rol.valorApi,
    );

    if (refreshToken != null) {
      await _storage.write(key: _storageKeyRefreshToken, value: refreshToken);
    }

    state = AsyncData(
      SesionActiva(
        usuario: usuario,
        token: token,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<void> actualizarToken(
    String nuevoToken,
    String? nuevoRefreshToken,
  ) async {
    final sesionActual = state.value;
    if (sesionActual is! SesionActiva) return;

    await _storage.write(key: _storageKeyToken, value: nuevoToken);
    if (nuevoRefreshToken != null) {
      await _storage.write(
          key: _storageKeyRefreshToken, value: nuevoRefreshToken);
    }

    final refreshFinal = nuevoRefreshToken ?? sesionActual.refreshToken;
    state = AsyncData(
      SesionActiva(
        usuario: sesionActual.usuario,
        token: nuevoToken,
        refreshToken: refreshFinal,
      ),
    );
  }

  Future<void> cerrar() async {
    try {
      final sesionActual = state.value;
      if (sesionActual is SesionActiva) {
        final repository = AutenticacionRepository(
          AutenticacionApi(
            cliente: ClienteApi(obtenerToken: () => sesionActual.token),
          ),
        );
        await repository.cerrarSesion(refreshToken: sesionActual.refreshToken);
      }
    } catch (_) {}

    await _limpiarStorage();
    state = const AsyncData(SesionVacia());
  }

  Future<void> _limpiarStorage() async {
    await _storage.deleteAll();
  }
}

final sesionProvider = AsyncNotifierProvider<SesionNotifier, SesionState>(
  SesionNotifier.new,
);
