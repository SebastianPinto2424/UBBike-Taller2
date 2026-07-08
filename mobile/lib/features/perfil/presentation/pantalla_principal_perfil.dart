import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ubbike/features/acceso/application/solicitudes_guardia_vm.dart';
import 'package:ubbike/features/auth/application/autenticacion_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/core/providers/sesion_provider.dart';
import 'package:ubbike/core/servicios/excepcion_api.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/modelos/rol_usuario.dart';
import 'package:ubbike/shared/utils/sesion_ui_utils.dart';
import 'package:ubbike/shared/widgets/chip_estado.dart';
import 'package:ubbike/shared/widgets/snackbar_semantico.dart';
import 'package:ubbike/features/inicio/presentation/comun/estado_widgets.dart';

class VistaPerfil extends ConsumerWidget {
  const VistaPerfil({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final usuarioSesion = sesion is SesionActiva ? sesion.usuario : null;
    final nombrePerfil = textoNoVacio(usuarioSesion?.nombre, rol.etiqueta);
    final correoPerfil = textoNoVacio(usuarioSesion?.correo, '—');
    final rutPerfil = textoNoVacio(usuarioSesion?.rut, 'Sin RUT registrado');

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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ChipEstado(
                  texto: rol.etiqueta,
                  color: ColoresUbb.azulApp,
                ),
                ChipEstado(
                  texto: usuarioSesion?.correoVerificado == true
                      ? 'Correo verificado'
                      : 'Correo pendiente',
                  color: usuarioSesion?.correoVerificado == true
                      ? ColoresUbb.exito
                      : ColoresUbb.amarilloInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _DatoPerfilFila(
              etiqueta: 'Correo',
              valor: correoPerfil,
            ),
            const Divider(height: 24),
            _DatoPerfilFila(
              etiqueta: 'RUT',
              valor: rutPerfil,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: ColoresUbb.azulApp,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                try {
                  final mensaje = await ref
                      .read(autenticacionVmProvider)
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
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
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
                backgroundColor: ColoresUbb.rojoInstitucional,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                ref.read(sesionProvider.notifier).cerrar();
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
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

class _DatoPerfilFila extends StatelessWidget {
  const _DatoPerfilFila({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        LayoutBuilder(
          builder: (context, constraints) {
            final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ColoresUbb.azulNoche,
                );

            return Tooltip(
              message: valor,
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Text(
                      valor,
                      maxLines: 1,
                      softWrap: false,
                      style: estilo,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class SelectorBicicleteroGuardiaPerfil extends ConsumerStatefulWidget {
  const SelectorBicicleteroGuardiaPerfil({super.key, this.onCambiado});

  final VoidCallback? onCambiado;

  @override
  ConsumerState<SelectorBicicleteroGuardiaPerfil> createState() =>
      _SelectorBicicleteroGuardiaPerfilState();
}

class _SelectorBicicleteroGuardiaPerfilState
    extends ConsumerState<SelectorBicicleteroGuardiaPerfil> {
  SolicitudesGuardiaVm get vm => ref.read(solicitudesGuardiaVmProvider);
  List<BicicleteroApp> bicicleteros = [];
  BicicleteroApp? bicicleteroSeleccionado;
  bool cargando = true;
  bool guardando = false;
  bool liberando = false;
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
        vm.listarBicicleteros(),
        vm.obtenerBicicleteroGestionado(),
      ]);
      final lista = resultados[0] as List<BicicleteroApp>;
      final actual = resultados[1] as BicicleteroApp?;
      final seleccionado = actual == null
          ? null
          : lista.cast<BicicleteroApp?>().firstWhere(
                (item) => item?.id == actual.id,
                orElse: () => null,
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
      final actualizado =
          await vm.seleccionarBicicleteroGestionado(seleccionado.id);

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
        abierto = false;
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

  Future<void> _liberar() async {
    if (guardando || bicicleteroSeleccionado == null) {
      return;
    }

    setState(() {
      guardando = true;
      liberando = true;
    });

    try {
      await vm.liberarBicicleteroGestionado();

      if (!mounted) {
        return;
      }

      setState(() {
        bicicleteroSeleccionado = null;
        guardando = false;
        liberando = false;
        abierto = false;
      });
      context.mostrarExito('Ya no gestionas un bicicletero');
      widget.onCambiado?.call();
    } on ExcepcionApi catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        guardando = false;
        liberando = false;
      });
      context.mostrarError(error.mensaje);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        guardando = false;
        liberando = false;
      });
      context.mostrarError('No se pudo conectar con el backend');
    }
  }

  String _textoBicicleteroSeleccionado() {
    final seleccionado = bicicleteroSeleccionado;
    if (seleccionado == null) {
      return 'Selecciona un bicicletero';
    }

    final cupos = seleccionado.cuposDisponibles == 1
        ? '1 cupo libre'
        : '${seleccionado.cuposDisponibles} cupos libres';
    return '${seleccionado.nombre} · $cupos';
  }

  Widget _opcionNinguno() {
    final seleccionado = bicicleteroSeleccionado == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: guardando || seleccionado ? null : _liberar,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        'Ninguno',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dejar de gestionar un bicicletero',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (liberando)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    seleccionado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: seleccionado
                        ? ColoresUbb.azulApp
                        : ColoresUbb.textoSecundario,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _opcionBicicletero(BicicleteroApp bicicletero) {
    final seleccionado = bicicleteroSeleccionado?.id == bicicletero.id;
    final guardandoEste = guardando && seleccionado;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: guardando || seleccionado
              ? null
              : () {
                  setState(() => bicicleteroSeleccionado = bicicletero);
                  _guardar();
                },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                if (guardandoEste)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    seleccionado
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: seleccionado
                        ? ColoresUbb.azulApp
                        : ColoresUbb.textoSecundario,
                  ),
              ],
            ),
          ),
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
        detalle: 'Central debe habilitar al menos un bicicletero.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => abierto = !abierto),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColoresUbb.bordeFuerte),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: ColoresUbb.azulApp,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _textoBicicleteroSeleccionado(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: bicicleteroSeleccionado == null
                                        ? ColoresUbb.textoSecundario
                                        : ColoresUbb.textoPrincipal,
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
            ),
            Positioned(
              left: 14,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Text(
                  'Bicicletero a gestionar',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ColoresUbb.azulApp,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ],
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
                    _opcionNinguno(),
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
