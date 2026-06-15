import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repositorios_provider.dart';
import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../../../shared/widgets/snackbar_semantico.dart';
import '../data/usuarios_admin_repository.dart';

enum _FiltroEstadoCuenta { todos, activos, denegados }

extension _DatosFiltroEstadoCuenta on _FiltroEstadoCuenta {
  String get etiqueta {
    switch (this) {
      case _FiltroEstadoCuenta.todos:
        return 'Todos';
      case _FiltroEstadoCuenta.activos:
        return 'Activos';
      case _FiltroEstadoCuenta.denegados:
        return 'Acceso denegado';
    }
  }

  bool? get valor {
    switch (this) {
      case _FiltroEstadoCuenta.todos:
        return null;
      case _FiltroEstadoCuenta.activos:
        return true;
      case _FiltroEstadoCuenta.denegados:
        return false;
    }
  }
}

enum _FiltroEstadoCorreo { todos, verificados, pendientes }

extension _DatosFiltroEstadoCorreo on _FiltroEstadoCorreo {
  String get etiqueta {
    switch (this) {
      case _FiltroEstadoCorreo.todos:
        return 'Todos';
      case _FiltroEstadoCorreo.verificados:
        return 'Verificados';
      case _FiltroEstadoCorreo.pendientes:
        return 'Pendientes';
    }
  }

  bool? get valor {
    switch (this) {
      case _FiltroEstadoCorreo.todos:
        return null;
      case _FiltroEstadoCorreo.verificados:
        return true;
      case _FiltroEstadoCorreo.pendientes:
        return false;
    }
  }
}

class VistaGestionUsuarios extends ConsumerStatefulWidget {
  const VistaGestionUsuarios({super.key});

  @override
  ConsumerState<VistaGestionUsuarios> createState() =>
      _VistaGestionUsuariosState();
}

class _VistaGestionUsuariosState extends ConsumerState<VistaGestionUsuarios> {
  late final UsuariosAdminRepository usuariosRepository;
  final busquedaController = TextEditingController();
  late Future<List<UsuarioApp>> futuroUsuarios;
  Timer? debounceBusqueda;
  String filtroBusqueda = '';
  RolUsuario? filtroRol;
  _FiltroEstadoCuenta filtroEstadoCuenta = _FiltroEstadoCuenta.todos;
  _FiltroEstadoCorreo filtroEstadoCorreo = _FiltroEstadoCorreo.todos;

  @override
  void initState() {
    super.initState();
    usuariosRepository = ref.read(usuariosAdminRepositoryProvider);
    futuroUsuarios = _consultarUsuarios();
  }

  @override
  void dispose() {
    debounceBusqueda?.cancel();
    busquedaController.dispose();
    super.dispose();
  }

  Future<List<UsuarioApp>> _consultarUsuarios() {
    return usuariosRepository.listarUsuarios(
      q: filtroBusqueda,
      rol: filtroRol,
      cuentaActiva: filtroEstadoCuenta.valor,
      correoVerificado: filtroEstadoCorreo.valor,
    );
  }

  void _recargar() {
    setState(() {
      futuroUsuarios = _consultarUsuarios();
    });
  }

  void _buscar(String valor) {
    debounceBusqueda?.cancel();
    setState(() {});
    debounceBusqueda = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      setState(() {
        filtroBusqueda = valor.trim();
        futuroUsuarios = _consultarUsuarios();
      });
    });
  }

  void _actualizarFiltros({
    RolUsuario? rol,
    bool limpiarRol = false,
    _FiltroEstadoCuenta? estadoCuenta,
    _FiltroEstadoCorreo? estadoCorreo,
  }) {
    setState(() {
      if (limpiarRol) {
        filtroRol = null;
      } else if (rol != null) {
        filtroRol = rol;
      }
      if (estadoCuenta != null) {
        filtroEstadoCuenta = estadoCuenta;
      }
      if (estadoCorreo != null) {
        filtroEstadoCorreo = estadoCorreo;
      }
      futuroUsuarios = _consultarUsuarios();
    });
  }

  void _limpiarFiltros() {
    debounceBusqueda?.cancel();
    busquedaController.clear();
    setState(() {
      filtroBusqueda = '';
      filtroRol = null;
      filtroEstadoCuenta = _FiltroEstadoCuenta.todos;
      filtroEstadoCorreo = _FiltroEstadoCorreo.todos;
      futuroUsuarios = _consultarUsuarios();
    });
  }

  void _limpiarBusqueda() {
    debounceBusqueda?.cancel();
    busquedaController.clear();
    setState(() {
      filtroBusqueda = '';
      futuroUsuarios = _consultarUsuarios();
    });
  }

  Future<void> _actualizar(
    UsuarioApp usuario, {
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    try {
      await usuariosRepository.actualizarPermisos(
        usuarioId: usuario.id,
        nombre: nombre,
        correo: correo,
        rut: rut,
        rol: rol,
        cuentaActiva: cuentaActiva,
        correoVerificado: correoVerificado,
      );
      _recargar();
      if (mounted) {
        context.mostrarExito('Permisos actualizados');
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo conectar con el backend');
      }
    }
  }

  Future<void> _crearUsuario() async {
    final resultado = await showModalBottomSheet<
        ({
          String nombre,
          String correo,
          String rut,
          RolUsuario rol,
          String contrasena,
        })>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => const _SheetCrearUsuario(),
    );

    if (resultado == null) {
      return;
    }

    try {
      await usuariosRepository.crearUsuario(
        nombre: resultado.nombre,
        correo: resultado.correo,
        rut: resultado.rut,
        rol: resultado.rol,
        contrasena: resultado.contrasena,
      );
      _recargar();
      if (mounted) {
        context.mostrarExito('Cuenta creada correctamente');
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo conectar con el backend');
      }
    }
  }

  Future<void> _eliminarUsuario(UsuarioApp usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: ColoresUbb.rojoInstitucional,
          size: 44,
        ),
        title: const Text('Eliminar cuenta'),
        content: Text(
          'Se desactivara la cuenta de ${usuario.nombre}, se cerraran sus sesiones y dejara de aparecer en la gestion diaria.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColoresUbb.rojoInstitucional,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await usuariosRepository.eliminarUsuario(usuario.id);
      _recargar();
      if (mounted) {
        context.mostrarExito('Cuenta eliminada');
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo conectar con el backend');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsuarioApp>>(
      future: futuroUsuarios,
      builder: (context, snapshot) {
        final cargando = snapshot.connectionState == ConnectionState.waiting;
        final usuarios = snapshot.data ?? const <UsuarioApp>[];
        final tieneFiltros = filtroBusqueda.isNotEmpty ||
            filtroRol != null ||
            filtroEstadoCuenta != _FiltroEstadoCuenta.todos ||
            filtroEstadoCorreo != _FiltroEstadoCorreo.todos;

        return Column(
          children: [
            _EncabezadoAdminUsuarios(onCrear: _crearUsuario),
            const SizedBox(height: 12),
            _FiltrosUsuariosAdmin(
              busquedaController: busquedaController,
              total: usuarios.length,
              cargando: cargando,
              tieneFiltros: tieneFiltros,
              rol: filtroRol,
              estadoCuenta: filtroEstadoCuenta,
              estadoCorreo: filtroEstadoCorreo,
              onBuscar: _buscar,
              onRol: (rol) => _actualizarFiltros(
                rol: rol,
                limpiarRol: rol == null,
              ),
              onEstadoCuenta: (estado) =>
                  _actualizarFiltros(estadoCuenta: estado),
              onEstadoCorreo: (estado) =>
                  _actualizarFiltros(estadoCorreo: estado),
              onLimpiarBusqueda: _limpiarBusqueda,
              onLimpiar: _limpiarFiltros,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: snapshot.hasError || cargando || usuarios.isEmpty
                    ? 1
                    : usuarios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (cargando) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const _EstadoUsuarios(
                      icono: Icons.cloud_off_outlined,
                      titulo: 'No se pudieron cargar usuarios',
                      detalle: 'Revisa la conexión con el backend.',
                    );
                  }

                  if (usuarios.isEmpty) {
                    return _EstadoUsuarios(
                      icono: Icons.people_outline,
                      titulo: tieneFiltros ? 'Sin resultados' : 'Sin usuarios',
                      detalle: tieneFiltros
                          ? 'Ajusta la búsqueda o los filtros.'
                          : 'Los registros aparecerán aquí.',
                    );
                  }

                  final usuario = usuarios[index];
                  return _TarjetaUsuarioAdmin(
                    key: ValueKey('usuario-${usuario.id}'),
                    usuario: usuario,
                    onActualizar: _actualizar,
                    onEditarCredenciales: _editarCredenciales,
                    onEliminar: _eliminarUsuario,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarCredenciales(UsuarioApp usuario) async {
    final resultado = await showModalBottomSheet<
        ({String nombre, String correo, String rut})>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => _SheetEditarCuenta(usuario: usuario),
    );

    if (resultado != null) {
      await _actualizar(
        usuario,
        nombre: resultado.nombre,
        correo: resultado.correo,
        rut: resultado.rut,
      );
    }
  }
}

class _SheetEditarCuenta extends StatefulWidget {
  const _SheetEditarCuenta({required this.usuario});

  final UsuarioApp usuario;

  @override
  State<_SheetEditarCuenta> createState() => _SheetEditarCuentaState();
}

class _SheetCrearUsuario extends StatefulWidget {
  const _SheetCrearUsuario();

  @override
  State<_SheetCrearUsuario> createState() => _SheetCrearUsuarioState();
}

class _SheetCrearUsuarioState extends State<_SheetCrearUsuario> {
  final formKeyCrearCuenta = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final rutController = TextEditingController();
  final contrasenaController = TextEditingController();
  RolUsuario rol = RolUsuario.guardia;
  bool mostrarContrasena = false;

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    rutController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (formKeyCrearCuenta.currentState?.validate() != true) {
      return;
    }

    Navigator.pop(
      context,
      (
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim().toLowerCase(),
        rut: rutController.text.trim(),
        rol: rol,
        contrasena: contrasenaController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKeyCrearCuenta,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Crear cuenta',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Para guardias puedes usar un correo externo. La cuenta queda activa y verificada.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ColoresUbb.textoSecundario,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _validarNombreCuentaAdmin,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: _validarCorreoCuentaAdmin,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rutController,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'RUT'),
                validator: _validarRutCuentaAdmin,
              ),
              const SizedBox(height: 12),
              _DropdownAdmin<RolUsuario>(
                value: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: RolUsuario.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.etiqueta),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => rol = valor);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contrasenaController,
                obscureText: !mostrarContrasena,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _guardar(),
                decoration: InputDecoration(
                  labelText: 'Contrasena temporal',
                  suffixIcon: IconButton(
                    tooltip: mostrarContrasena
                        ? 'Ocultar contrasena'
                        : 'Mostrar contrasena',
                    onPressed: () {
                      setState(() => mostrarContrasena = !mostrarContrasena);
                    },
                    icon: Icon(
                      mostrarContrasena
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: _validarContrasenaCuentaAdmin,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: ColoresUbb.azulApp,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _guardar,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Crear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetEditarCuentaState extends State<_SheetEditarCuenta> {
  final formKeyEditarCuenta = GlobalKey<FormState>();
  late final TextEditingController nombreController;
  late final TextEditingController correoController;
  late final TextEditingController rutController;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.usuario.nombre);
    correoController = TextEditingController(text: widget.usuario.correo);
    rutController = TextEditingController(text: widget.usuario.rut ?? '');
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    rutController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (formKeyEditarCuenta.currentState?.validate() != true) {
      return;
    }

    Navigator.pop(
      context,
      (
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim(),
        rut: rutController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKeyEditarCuenta,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Editar datos de cuenta',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _validarNombreCuentaAdmin,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(labelText: 'Correo institucional'),
                validator: _validarCorreoCuentaAdmin,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rutController,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _guardar(),
                decoration: const InputDecoration(labelText: 'RUT'),
                validator: _validarRutCuentaAdmin,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: ColoresUbb.azulApp,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _validarNombreCuentaAdmin(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Ingresa un nombre.';
  }
  if (texto.length < 3) {
    return 'Debe tener al menos 3 caracteres.';
  }
  if (texto.length > 120) {
    return 'Maximo 120 caracteres.';
  }
  return null;
}

String? _validarCorreoCuentaAdmin(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Ingresa un correo.';
  }
  if (texto.length > 160) {
    return 'Maximo 160 caracteres.';
  }

  final correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  if (!correoValido.hasMatch(texto)) {
    return 'Ingresa un correo valido. Ej: usuario@ubiobio.cl';
  }
  return null;
}

String? _validarContrasenaCuentaAdmin(String? valor) {
  final texto = valor ?? '';
  if (texto.isEmpty) {
    return 'Ingresa una contrasena.';
  }
  if (texto.length < 12) {
    return 'Minimo 12 caracteres.';
  }
  if (texto.length > 72) {
    return 'Maximo 72 caracteres.';
  }

  final segura = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$',
  );
  if (!segura.hasMatch(texto)) {
    return 'Incluye mayuscula, minuscula, numero y simbolo.';
  }
  return null;
}

String? _validarRutCuentaAdmin(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return null;
  }
  if (texto.length > 20) {
    return 'Maximo 20 caracteres.';
  }
  if (!_rutCuentaAdminValido(texto)) {
    return 'El RUT no es valido.';
  }
  return null;
}

bool _rutCuentaAdminValido(String valor) {
  final limpio = valor
      .replaceAll('.', '')
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .toUpperCase();
  if (!RegExp(r'^\d{7,8}[0-9K]$').hasMatch(limpio)) {
    return false;
  }

  final cuerpo = limpio.substring(0, limpio.length - 1);
  final digito = limpio.substring(limpio.length - 1);
  var suma = 0;
  var multiplicador = 2;

  for (var i = cuerpo.length - 1; i >= 0; i--) {
    suma += int.parse(cuerpo[i]) * multiplicador;
    multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
  }

  final resto = 11 - (suma % 11);
  final esperado = switch (resto) {
    11 => '0',
    10 => 'K',
    _ => resto.toString(),
  };

  return digito == esperado;
}

class _EncabezadoAdminUsuarios extends StatelessWidget {
  const _EncabezadoAdminUsuarios({required this.onCrear});

  final VoidCallback onCrear;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColoresUbb.azulNoche,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: ColoresUbb.turquesa,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuarios y permisos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administra roles, accesos y verificacion de cuentas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: 'Crear cuenta',
              onPressed: onCrear,
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosUsuariosAdmin extends StatelessWidget {
  const _FiltrosUsuariosAdmin({
    required this.busquedaController,
    required this.total,
    required this.cargando,
    required this.tieneFiltros,
    required this.rol,
    required this.estadoCuenta,
    required this.estadoCorreo,
    required this.onBuscar,
    required this.onRol,
    required this.onEstadoCuenta,
    required this.onEstadoCorreo,
    required this.onLimpiarBusqueda,
    required this.onLimpiar,
  });

  final TextEditingController busquedaController;
  final int total;
  final bool cargando;
  final bool tieneFiltros;
  final RolUsuario? rol;
  final _FiltroEstadoCuenta estadoCuenta;
  final _FiltroEstadoCorreo estadoCorreo;
  final ValueChanged<String> onBuscar;
  final ValueChanged<RolUsuario?> onRol;
  final ValueChanged<_FiltroEstadoCuenta> onEstadoCuenta;
  final ValueChanged<_FiltroEstadoCorreo> onEstadoCorreo;
  final VoidCallback onLimpiarBusqueda;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final contador = cargando ? 'Buscando...' : '$total usuarios';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Buscar usuarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColoresUbb.azulNoche,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Text(
              contador,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresUbb.textoSecundario,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: busquedaController,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          onChanged: onBuscar,
          decoration: InputDecoration(
            labelText: 'Nombre, correo o RUT',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: busquedaController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: onLimpiarBusqueda,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        _PanelFiltrosUsuarios(
          titulo: 'Filtros',
          detalle: _resumenFiltros(),
          onLimpiar: tieneFiltros ? onLimpiar : null,
          children: [
            _EtiquetaFiltroUsuarios(
              texto: 'Rol',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipFiltroUsuarios<RolUsuario?>(
                    label: 'Todos',
                    value: null,
                    selectedValue: rol,
                    onTap: onRol,
                  ),
                  for (final item in RolUsuario.values)
                    _ChipFiltroUsuarios<RolUsuario?>(
                      label: item.etiqueta,
                      value: item,
                      selectedValue: rol,
                      onTap: onRol,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _EtiquetaFiltroUsuarios(
              texto: 'Estado cuenta',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _FiltroEstadoCuenta.values)
                    _ChipFiltroUsuarios<_FiltroEstadoCuenta>(
                      label: item.etiqueta,
                      value: item,
                      selectedValue: estadoCuenta,
                      onTap: onEstadoCuenta,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _EtiquetaFiltroUsuarios(
              texto: 'Estado correo',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _FiltroEstadoCorreo.values)
                    _ChipFiltroUsuarios<_FiltroEstadoCorreo>(
                      label: item.etiqueta,
                      value: item,
                      selectedValue: estadoCorreo,
                      onTap: onEstadoCorreo,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _resumenFiltros() {
    final rolTexto = rol?.etiqueta ?? 'Todos los roles';
    return '$rolTexto | ${estadoCuenta.etiqueta} | ${estadoCorreo.etiqueta}';
  }
}

class _PanelFiltrosUsuarios extends StatelessWidget {
  const _PanelFiltrosUsuarios({
    required this.titulo,
    required this.detalle,
    required this.children,
    this.onLimpiar,
  });

  final String titulo;
  final String detalle;
  final List<Widget> children;
  final VoidCallback? onLimpiar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune, color: ColoresUbb.azulApp),
        title: Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Text(
          detalle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 6),
          ...children,
          if (onLimpiar != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLimpiar,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Restablecer filtros'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EtiquetaFiltroUsuarios extends StatelessWidget {
  const _EtiquetaFiltroUsuarios({required this.texto, required this.child});

  final String texto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresUbb.textoSecundario,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ChipFiltroUsuarios<T> extends StatelessWidget {
  const _ChipFiltroUsuarios({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  final String label;
  final T value;
  final T selectedValue;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    final seleccionado = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => onTap(value),
      showCheckmark: false,
      selectedColor: ColoresUbb.azulApp,
      backgroundColor: ColoresUbb.superficieAzulSuave,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: seleccionado ? Colors.white : ColoresUbb.azulApp,
            fontWeight: FontWeight.w800,
          ),
      side: BorderSide(
        color: seleccionado ? ColoresUbb.azulApp : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _DropdownAdmin<T> extends StatelessWidget {
  const _DropdownAdmin({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.decoration,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tieneSeleccion = items.any((item) => item.value == value);
        final decoracion = decoration
            .applyDefaults(Theme.of(context).inputDecorationTheme)
            .copyWith(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            );

        return InputDecorator(
          decoration: decoracion,
          isEmpty: !tieneSeleccion,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              isDense: true,
              menuWidth: constraints.maxWidth,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.azulNoche,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaUsuarioAdmin extends StatefulWidget {
  const _TarjetaUsuarioAdmin({
    super.key,
    required this.usuario,
    required this.onActualizar,
    required this.onEditarCredenciales,
    required this.onEliminar,
  });

  final UsuarioApp usuario;
  final Future<void> Function(
    UsuarioApp usuario, {
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) onActualizar;
  final Future<void> Function(UsuarioApp usuario) onEditarCredenciales;
  final Future<void> Function(UsuarioApp usuario) onEliminar;

  @override
  State<_TarjetaUsuarioAdmin> createState() => _TarjetaUsuarioAdminState();
}

class _TarjetaUsuarioAdminState extends State<_TarjetaUsuarioAdmin> {
  bool abierto = false;

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usuario.correo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChipEstado(
                  texto: usuario.rol.etiqueta,
                  color: ColoresUbb.azulApp,
                ),
                ChipEstado(
                  texto: usuario.cuentaActiva ? 'Activo' : 'Acceso denegado',
                  color: usuario.cuentaActiva
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                ChipEstado(
                  texto: usuario.correoVerificado
                      ? 'Correo verificado'
                      : 'Correo pendiente',
                  color: usuario.correoVerificado
                      ? ColoresUbb.exito
                      : ColoresUbb.amarilloInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _BotonGestionUsuario(
              expandido: abierto,
              onTap: () => setState(() => abierto = !abierto),
            ),
            if (abierto)
              _PanelGestionUsuario(
                usuario: usuario,
                onActualizar: widget.onActualizar,
                onEditarCredenciales: widget.onEditarCredenciales,
                onEliminar: widget.onEliminar,
              ),
          ],
        ),
      ),
    );
  }
}

class _BotonGestionUsuario extends StatelessWidget {
  const _BotonGestionUsuario({
    required this.expandido,
    required this.onTap,
  });

  final bool expandido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresUbb.bordeFuerte),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.manage_accounts_outlined,
                    color: ColoresUbb.azulApp),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gestionar usuario',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresUbb.azulOscuro,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Icon(
                  expandido
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColoresUbb.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelGestionUsuario extends StatelessWidget {
  const _PanelGestionUsuario({
    required this.usuario,
    required this.onActualizar,
    required this.onEditarCredenciales,
    required this.onEliminar,
  });

  final UsuarioApp usuario;
  final Future<void> Function(
    UsuarioApp usuario, {
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) onActualizar;
  final Future<void> Function(UsuarioApp usuario) onEditarCredenciales;
  final Future<void> Function(UsuarioApp usuario) onEliminar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColoresUbb.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColoresUbb.borde),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _EtiquetaSeccion('Estado de cuenta'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: usuario.correoVerificado
                          ? null
                          : () => onActualizar(usuario, correoVerificado: true),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Verificar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onActualizar(
                        usuario,
                        cuentaActiva: !usuario.cuentaActiva,
                      ),
                      style: usuario.cuentaActiva
                          ? OutlinedButton.styleFrom(
                              foregroundColor: ColoresUbb.rojoInstitucional,
                              side: const BorderSide(
                                color: ColoresUbb.rojoInstitucional,
                              ),
                            )
                          : null,
                      icon: Icon(
                        usuario.cuentaActiva
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        usuario.cuentaActiva ? 'Denegar' : 'Habilitar',
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              const _EtiquetaSeccion('Rol'),
              const SizedBox(height: 8),
              _DropdownAdmin<RolUsuario>(
                key: ValueKey('rol-${usuario.id}-${usuario.rol.name}'),
                value: usuario.rol,
                decoration: const InputDecoration(
                  labelText: 'Rol del usuario',
                ),
                items: RolUsuario.values
                    .map(
                      (rol) => DropdownMenuItem(
                        value: rol,
                        child: Text(rol.etiqueta),
                      ),
                    )
                    .toList(),
                onChanged: (rol) {
                  if (rol != null && rol != usuario.rol) {
                    onActualizar(usuario, rol: rol);
                  }
                },
              ),
              const Divider(height: 28),
              const _EtiquetaSeccion('Datos de cuenta'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => onEditarCredenciales(usuario),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar datos de cuenta'),
              ),
              const Divider(height: 28),
              const _EtiquetaSeccion('Zona de riesgo'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColoresUbb.rojoInstitucional,
                  side: const BorderSide(color: ColoresUbb.rojoInstitucional),
                ),
                onPressed: () => onEliminar(usuario),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Eliminar cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  const _EtiquetaSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ColoresUbb.textoSecundario,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _EstadoUsuarios extends StatelessWidget {
  const _EstadoUsuarios({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icono, color: ColoresUbb.azulApp, size: 44),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(detalle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
