part of '../pantalla_principal.dart';

class VistaPerfil extends ConsumerWidget {
  const VistaPerfil({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final usuarioSesion = sesion is SesionActiva ? sesion.usuario : null;
    final nombrePerfil = _textoNoVacio(usuarioSesion?.nombre, rol.etiqueta);
    final correoPerfil = _textoNoVacio(usuarioSesion?.correo, '—');
    final rutPerfil = _textoNoVacio(usuarioSesion?.rut, 'Sin RUT registrado');

    final tarjetaPerfil = Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                nombrePerfil,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: ColoresUbb.azulNoche,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: ColoresUbb.azulApp.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  rol.etiqueta,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: ColoresUbb.azulApp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _DatoPerfilBox(
              etiqueta: 'Correo',
              valor: correoPerfil,
            ),
            const SizedBox(height: 12),
            _DatoPerfilBox(
              etiqueta: 'RUT',
              valor: rutPerfil,
            ),
            const SizedBox(height: 12),
            _DatoPerfilBox(
              etiqueta: 'Estado',
              valor: usuarioSesion?.correoVerificado == true
                  ? 'Correo verificado'
                  : 'Correo pendiente de verificación',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ColoresUbb.azulApp.withValues(alpha: 0.1),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                try {
                  final mensaje = await AutenticacionApi()
                      .solicitarCambioContrasena(correoPerfil);
                  if (context.mounted) {
                    context.mostrarExito(mensaje);
                  }
                } on ExcepcionApi catch (error) {
                  if (context.mounted) {
                    context.mostrarError(error.mensaje);
                  }
                }
              },
              child: const Text(
                'Cambiar contraseña',
                style: TextStyle(
                    color: ColoresUbb.azulApp,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Se enviará un correo electrónico con un enlace seguro para cambiar tu contraseña.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    ColoresUbb.rojoInstitucional.withValues(alpha: 0.1),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                ref.read(sesionProvider.notifier).cerrar();
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                    color: ColoresUbb.rojoInstitucional,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final altoMinimo =
            constraints.maxHeight > 32 ? constraints.maxHeight - 32 : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: altoMinimo),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: tarjetaPerfil,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatoPerfilBox extends StatelessWidget {
  const _DatoPerfilBox({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColoresUbb.azulApp.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ColoresUbb.azulNoche,
                ),
          ),
        ],
      ),
    );
  }
}

class _SelectorBicicleteroGuardiaPerfil extends StatefulWidget {
  const _SelectorBicicleteroGuardiaPerfil({this.onCambiado});

  final VoidCallback? onCambiado;

  @override
  State<_SelectorBicicleteroGuardiaPerfil> createState() =>
      _SelectorBicicleteroGuardiaPerfilState();
}

class _SelectorBicicleteroGuardiaPerfilState
    extends State<_SelectorBicicleteroGuardiaPerfil> {
  final solicitudGuardiaApi = SolicitudGuardiaApi();
  List<BicicleteroApp> bicicleteros = [];
  BicicleteroApp? bicicleteroSeleccionado;
  bool cargando = true;
  bool guardando = false;
  bool abierto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => cargando = true);

    try {
      final resultados = await Future.wait([
        solicitudGuardiaApi.listarBicicleteros(),
        solicitudGuardiaApi.obtenerBicicleteroGestionado(),
      ]);
      final lista = resultados[0] as List<BicicleteroApp>;
      final actual = resultados[1] as BicicleteroApp?;
      final seleccionado = actual == null
          ? (lista.isEmpty ? null : lista.first)
          : lista.cast<BicicleteroApp?>().firstWhere(
                (item) => item?.id == actual.id,
                orElse: () => lista.isEmpty ? null : lista.first,
              );

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteros = lista;
        bicicleteroSeleccionado = seleccionado;
        cargando = false;
      });
    } on ExcepcionApi catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => cargando = false);
      context.mostrarError(error.mensaje);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => cargando = false);
      context.mostrarError('No se pudo conectar con el backend');
    }
  }

  Future<void> _guardar() async {
    final seleccionado = bicicleteroSeleccionado;
    if (seleccionado == null || guardando) {
      return;
    }

    setState(() => guardando = true);

    try {
      final actualizado = await solicitudGuardiaApi
          .seleccionarBicicleteroGestionado(seleccionado.id);

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteros = bicicleteros
            .map((item) => item.id == actualizado.id ? actualizado : item)
            .toList();
        bicicleteroSeleccionado = bicicleteros.firstWhere(
          (item) => item.id == actualizado.id,
        );
        guardando = false;
      });
      context.mostrarExito('Ahora gestionas ${actualizado.nombre}');
      widget.onCambiado?.call();
    } on ExcepcionApi catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => guardando = false);
      context.mostrarError(error.mensaje);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => guardando = false);
      context.mostrarError('No se pudo conectar con el backend');
    }
  }

  Widget _opcionBicicletero(BicicleteroApp bicicletero) {
    final seleccionado = bicicleteroSeleccionado?.id == bicicletero.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado
              ? ColoresUbb.azulApp.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? ColoresUbb.azulApp : ColoresUbb.borde,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bicicletero.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bicicletero.cuposDisponibles} cupos disponibles',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresUbb.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: seleccionado,
              onChanged: guardando
                  ? null
                  : (valor) {
                      if (valor) {
                        setState(() => bicicleteroSeleccionado = bicicletero);
                        _guardar();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bicicleteros.isEmpty) {
      return const EstadoLista(
        icono: Icons.location_off_outlined,
        titulo: 'Sin bicicleteros activos',
        detalle: 'Administracion debe habilitar al menos un bicicletero.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Seleccione el bicicletero a asistir en este turno.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => abierto = !abierto),
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColoresUbb.bordeFuerte),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined,
                        color: ColoresUbb.azulApp),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Seleccionar bicicletero',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColoresUbb.azulOscuro,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Icon(
                      abierto
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: ColoresUbb.textoSecundario,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState:
              abierto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ColoresUbb.fondo,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColoresUbb.borde),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...bicicleteros.map(_opcionBicicletero),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
