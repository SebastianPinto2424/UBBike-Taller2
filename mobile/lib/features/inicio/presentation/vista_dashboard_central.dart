
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ubbike/features/inicio/application/dashboard_central_vm.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/features/historial/data/historial_modelos.dart';
import 'package:ubbike/shared/modelos/bicicletero_app.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';
import 'package:ubbike/shared/utils/sesion_ui_utils.dart';
import 'package:ubbike/shared/widgets/chip_estado.dart';
import 'package:ubbike/shared/widgets/tarjeta_accion.dart';
import 'package:ubbike/features/inicio/presentation/comun/central_widgets.dart';
import 'package:ubbike/features/inicio/presentation/comun/encabezado_widgets.dart';
import 'package:ubbike/features/inicio/presentation/comun/estado_widgets.dart';
import 'package:ubbike/features/inicio/presentation/comun/utiles_comun.dart';

class VistaDashboardCentral extends ConsumerWidget {
  const VistaDashboardCentral({
    super.key,
    this.onAbrirMovimientos,
    this.onAbrirGuardias,
    this.onAbrirSoporte,
  });

  final VoidCallback? onAbrirMovimientos;
  final VoidCallback? onAbrirGuardias;
  final VoidCallback? onAbrirSoporte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(dashboardCentralVmProvider);
    final periodo = ref.watch(periodoDashboardCentralProvider);
    final vm = ref.read(dashboardCentralVmProvider.notifier);

    return RefreshIndicator(
      onRefresh: vm.refrescar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EncabezadoSeccion(
            saludo: saludoActual(),
            nombre: nombreSesion(context, 'Central'),
            detalle: 'Alertas, ocupación y actividad reciente.',
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final datos = estado.valueOrNull;

              if (datos == null) {
                if (estado.isLoading) {
                  return _DashboardCentralCargando(
                    periodo: periodo,
                    onPeriodo: vm.cambiarPeriodo,
                  );
                }
                return TarjetaAccion(
                  icono: Icons.error_outline,
                  titulo: 'No se pudo cargar el tablero',
                  detalle: 'Toca para reintentar.',
                  color: ColoresUbb.rojoInstitucional,
                  onTap: vm.refrescar,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PanelAtencionOperativa(
                    datos: datos,
                    onAbrirMovimientos: onAbrirMovimientos,
                    onAbrirGuardias: onAbrirGuardias,
                    onAbrirSoporte: onAbrirSoporte,
                  ),
                  const SizedBox(height: 14),
                  _EstadoCampusCentral(datos: datos),
                  const SizedBox(height: 14),
                  const TituloApartado(titulo: 'Resumen operacional'),
                  const SizedBox(height: 8),
                  SelectorPeriodoDashboard(
                    seleccionado: periodo,
                    onChange: vm.cambiarPeriodo,
                  ),
                  const SizedBox(height: 12),
                  _MetricasDashboardCentral(datos: datos),
                  const SizedBox(height: 10),
                  BannerTasaExito(
                    confirmados: datos.resumen.confirmados,
                    denegados: datos.resumen.denegados,
                    total: datos.resumen.totalMovimientos,
                  ),
                  _CanalesValidacionCentral(resumen: datos.resumen),
                  const SizedBox(height: 14),
                  _AccionesRapidasCentral(
                    onAbrirMovimientos: onAbrirMovimientos,
                    onAbrirGuardias: onAbrirGuardias,
                    onAbrirSoporte: onAbrirSoporte,
                  ),
                  const SizedBox(height: 16),
                  _EstadoBicicleterosOperativo(
                    bicicleteros: datos.bicicleteros,
                    onVerGuardias: onAbrirGuardias,
                  ),
                  const SizedBox(height: 16),
                  _ActividadPeriodoCentral(resumen: datos.resumen),
                  const SizedBox(height: 16),
                  _ActividadRecienteDashboard(
                    movimientos: datos.movimientosRecientes,
                    onVerMovimientos: onAbrirMovimientos,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCentralCargando extends StatelessWidget {
  const _DashboardCentralCargando({
    required this.periodo,
    required this.onPeriodo,
  });

  final String periodo;
  final ValueChanged<String> onPeriodo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 96,
          child: Center(child: CircularProgressIndicator()),
        ),
        SelectorPeriodoDashboard(
          seleccionado: periodo,
          onChange: onPeriodo,
        ),
        const SizedBox(height: 12),
        const GridIndicadoresCentral(
          indicadores: [
            IndicadorCentral(
              valor: '-',
              etiqueta: 'Movimientos',
              icono: Icons.swap_horiz_outlined,
              colorIcono: ColoresUbb.azulApp,
            ),
            IndicadorCentral(
              valor: '-',
              etiqueta: 'Denegados',
              icono: Icons.block_outlined,
              colorIcono: ColoresUbb.rojoInstitucional,
            ),
            IndicadorCentral(
              valor: '-',
              etiqueta: 'Incidencias',
              icono: Icons.report_problem_outlined,
              colorIcono: ColoresUbb.amarilloInstitucional,
            ),
          ],
        ),
      ],
    );
  }
}

class _EstadoCampusCentral extends StatelessWidget {
  const _EstadoCampusCentral({required this.datos});

  final DatosDashboardCentral datos;

  @override
  Widget build(BuildContext context) {
    final uso = datos.usoCampus;
    final porcentaje = (uso * 100).round();
    final color = uso >= 0.9
        ? ColoresUbb.rojoInstitucional
        : uso >= 0.75
            ? ColoresUbb.amarilloInstitucional
            : ColoresUbb.exito;
    final detalle = datos.capacidadTotal == 0
        ? 'Sin capacidad configurada'
        : '${datos.cuposDisponiblesTotal} cupos disponibles';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_city_outlined,
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacidad del campus',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: ColoresUbb.azulNoche,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$porcentaje%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: uso,
                minHeight: 9,
                color: color,
                backgroundColor: ColoresUbb.borde,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DatoCapacidadCampus(
                  etiqueta: 'Disponibles',
                  valor: datos.cuposDisponiblesTotal.toString(),
                  color: ColoresUbb.exito,
                ),
                _DatoCapacidadCampus(
                  etiqueta: 'Ocupados',
                  valor: datos.ocupadosTotal.toString(),
                  color: ColoresUbb.azulApp,
                ),
                _DatoCapacidadCampus(
                  etiqueta: 'Capacidad',
                  valor: datos.capacidadTotal.toString(),
                  color: ColoresUbb.azulNoche,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatoCapacidadCampus extends StatelessWidget {
  const _DatoCapacidadCampus({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _PanelAtencionOperativa extends StatelessWidget {
  const _PanelAtencionOperativa({
    required this.datos,
    this.onAbrirMovimientos,
    this.onAbrirGuardias,
    this.onAbrirSoporte,
  });

  final DatosDashboardCentral datos;
  final VoidCallback? onAbrirMovimientos;
  final VoidCallback? onAbrirGuardias;
  final VoidCallback? onAbrirSoporte;

  @override
  Widget build(BuildContext context) {
    final solicitudes = datos.solicitudesAbiertas.length;
    final incidencias = datos.incidenciasAbiertas.length;
    final bicicleteros = datos.bicicleterosCriticos.length;
    final denegados = datos.resumen.denegados;
    final sinAlertas = solicitudes == 0 &&
        incidencias == 0 &&
        bicicleteros == 0 &&
        denegados == 0;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.priority_high_outlined,
                  color: ColoresUbb.azulApp,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requiere atención',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ColoresUbb.azulNoche,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (sinAlertas)
              const _EstadoOperativoEstable()
            else if (solicitudes > 0)
              _AlertaOperativa(
                icono: Icons.campaign_outlined,
                titulo: 'Solicitudes activas',
                valor: solicitudes,
                detalle: 'Usuarios esperando atención',
                color: ColoresUbb.azulApp,
                onTap: onAbrirSoporte,
              ),
            if (incidencias > 0)
              _AlertaOperativa(
                icono: Icons.report_problem_outlined,
                titulo: 'Incidencias abiertas',
                valor: incidencias,
                detalle: 'Pendientes de gestión',
                color: ColoresUbb.amarilloInstitucional,
                onTap: onAbrirSoporte,
              ),
            if (bicicleteros > 0)
              _AlertaOperativa(
                icono: Icons.location_on_outlined,
                titulo: 'Bicicleteros en atención',
                valor: bicicleteros,
                detalle: bicicleteros == 0
                    ? 'Ocupación controlada'
                    : 'Alta ocupación o pocos cupos',
                color: bicicleteros == 0
                    ? ColoresUbb.exito
                    : ColoresUbb.rojoInstitucional,
                onTap: onAbrirGuardias,
              ),
            if (denegados > 0)
              _AlertaOperativa(
                icono: Icons.block_outlined,
                titulo: 'Denegados del periodo',
                valor: denegados,
                detalle:
                    denegados == 0 ? 'Sin rechazos' : 'Revisar validaciones',
                color: denegados == 0
                    ? ColoresUbb.exito
                    : ColoresUbb.rojoInstitucional,
                onTap: onAbrirMovimientos,
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertaOperativa extends StatelessWidget {
  const _AlertaOperativa({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
    required this.color,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final int valor;
  final String detalle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresUbb.azulNoche,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detalle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresUbb.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$valor',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: ColoresUbb.textoSecundario,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoOperativoEstable extends StatelessWidget {
  const _EstadoOperativoEstable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColoresUbb.exito.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColoresUbb.exito.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ColoresUbb.exito.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: ColoresUbb.exito,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operación estable',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ColoresUbb.azulNoche,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Sin alertas abiertas para este momento.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricasDashboardCentral extends StatelessWidget {
  const _MetricasDashboardCentral({required this.datos});

  final DatosDashboardCentral datos;

  @override
  Widget build(BuildContext context) {
    final resumen = datos.resumen;
    return GridIndicadoresCentral(
      indicadores: [
        IndicadorCentral(
          valor: resumen.totalMovimientos.toString(),
          etiqueta: 'Movimientos',
          icono: Icons.swap_horiz_outlined,
          colorIcono: ColoresUbb.azulApp,
        ),
        IndicadorCentral(
          valor: resumen.ingresos.toString(),
          etiqueta: 'Ingresos',
          icono: Icons.login_outlined,
          colorIcono: ColoresUbb.exito,
        ),
        IndicadorCentral(
          valor: resumen.retiros.toString(),
          etiqueta: 'Retiros',
          icono: Icons.logout_outlined,
          colorIcono: ColoresUbb.azulApp,
        ),
        IndicadorCentral(
          valor: resumen.denegados.toString(),
          etiqueta: 'Denegados',
          icono: Icons.block_outlined,
          colorIcono: ColoresUbb.rojoInstitucional,
        ),
        IndicadorCentral(
          valor: datos.solicitudesAbiertas.length.toString(),
          etiqueta: 'Solicitudes',
          icono: Icons.campaign_outlined,
          colorIcono: ColoresUbb.turquesa,
        ),
        IndicadorCentral(
          valor: datos.incidenciasAbiertas.length.toString(),
          etiqueta: 'Incidencias',
          icono: Icons.report_problem_outlined,
          colorIcono: ColoresUbb.amarilloInstitucional,
        ),
      ],
    );
  }
}

class _CanalesValidacionCentral extends StatelessWidget {
  const _CanalesValidacionCentral({required this.resumen});

  final ResumenHistorialApp resumen;

  @override
  Widget build(BuildContext context) {
    final total = resumen.qr + resumen.manuales;
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hub_outlined,
                    color: ColoresUbb.azulApp,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Origen de validaciones',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ColoresUbb.azulNoche,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Text(
                    '$total total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresUbb.textoSecundario,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _BarraCanalValidacion(
                etiqueta: 'QR',
                valor: resumen.qr,
                total: total,
                icono: Icons.qr_code_2_outlined,
                color: ColoresUbb.azulApp,
              ),
              const SizedBox(height: 10),
              _BarraCanalValidacion(
                etiqueta: 'Manual',
                valor: resumen.manuales,
                total: total,
                icono: Icons.edit_note_outlined,
                color: ColoresUbb.turquesa,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarraCanalValidacion extends StatelessWidget {
  const _BarraCanalValidacion({
    required this.etiqueta,
    required this.valor,
    required this.total,
    required this.icono,
    required this.color,
  });

  final String etiqueta;
  final int valor;
  final int total;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final proporcion =
        total == 0 ? 0.0 : (valor / total).clamp(0.0, 1.0).toDouble();
    final porcentaje = (proporcion * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icono, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                etiqueta,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.azulNoche,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              '$valor · $porcentaje%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColoresUbb.textoSecundario,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: proporcion,
            minHeight: 7,
            color: color,
            backgroundColor: ColoresUbb.borde,
          ),
        ),
      ],
    );
  }
}

class _AccionesRapidasCentral extends StatelessWidget {
  const _AccionesRapidasCentral({
    this.onAbrirMovimientos,
    this.onAbrirGuardias,
    this.onAbrirSoporte,
  });

  final VoidCallback? onAbrirMovimientos;
  final VoidCallback? onAbrirGuardias;
  final VoidCallback? onAbrirSoporte;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acciones rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ColoresUbb.azulNoche,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BotonAccionDashboard(
                  icono: Icons.manage_search_outlined,
                  texto: 'Movimientos',
                  onPressed: onAbrirMovimientos,
                ),
                _BotonAccionDashboard(
                  icono: Icons.security_outlined,
                  texto: 'Guardias',
                  onPressed: onAbrirGuardias,
                ),
                _BotonAccionDashboard(
                  icono: Icons.support_agent_outlined,
                  texto: 'Soporte',
                  onPressed: onAbrirSoporte,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccionDashboard extends StatelessWidget {
  const _BotonAccionDashboard({
    required this.icono,
    required this.texto,
    this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: Text(texto),
    );
  }
}

class _EstadoBicicleterosOperativo extends StatelessWidget {
  const _EstadoBicicleterosOperativo({
    required this.bicicleteros,
    this.onVerGuardias,
  });

  final List<BicicleteroApp> bicicleteros;
  final VoidCallback? onVerGuardias;

  @override
  Widget build(BuildContext context) {
    final ordenados = [...bicicleteros]
      ..sort((a, b) => b.porcentajeUso.compareTo(a.porcentajeUso));
    final visibles = ordenados.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: TituloApartado(titulo: 'Estado de bicicleteros'),
            ),
            if (onVerGuardias != null)
              TextButton(
                onPressed: onVerGuardias,
                child: const Text('Ver detalle'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibles.isEmpty)
          const EstadoLista(
            icono: Icons.location_off_outlined,
            titulo: 'Sin bicicleteros activos',
            detalle: 'Habilita bicicleteros desde configuración.',
          )
        else
          ...visibles.map(
            (bicicletero) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TarjetaBicicleteroOperativa(bicicletero: bicicletero),
            ),
          ),
      ],
    );
  }
}

class _TarjetaBicicleteroOperativa extends StatelessWidget {
  const _TarjetaBicicleteroOperativa({required this.bicicletero});

  final BicicleteroApp bicicletero;

  @override
  Widget build(BuildContext context) {
    final uso = (bicicletero.porcentajeUso / 100).clamp(0.0, 1.0);
    final sinCupos = bicicletero.cuposDisponibles == 0;
    final pocosCupos = bicicletero.cuposDisponibles <= 5;
    final color = sinCupos || uso >= 0.9
        ? ColoresUbb.rojoInstitucional
        : uso >= 0.75 || pocosCupos
            ? ColoresUbb.amarilloInstitucional
            : ColoresUbb.exito;
    final estado = sinCupos
        ? 'Sin cupos'
        : uso >= 0.9 || bicicletero.cuposDisponibles <= 2
            ? 'Crítico'
            : uso >= 0.75 || pocosCupos
                ? 'Atención'
                : 'Normal';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_on_outlined, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bicicletero.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColoresUbb.azulNoche,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        '${bicicletero.cuposDisponibles} cupos disponibles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                ChipEstado(texto: estado, color: color),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: uso,
                minHeight: 8,
                color: color,
                backgroundColor: ColoresUbb.borde,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${bicicletero.ocupados}/${bicicletero.capacidad} ocupados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColoresUbb.textoSecundario,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '${bicicletero.porcentajeUso}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActividadPeriodoCentral extends StatelessWidget {
  const _ActividadPeriodoCentral({required this.resumen});

  final ResumenHistorialApp resumen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloApartado(titulo: 'Actividad del periodo'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final guardias = _RankingResumen(
              titulo: 'Operaciones por guardia',
              datos: resumen.operacionesPorGuardia,
              icono: Icons.security_outlined,
              maxItems: 3,
            );
            final bicicleteros = _RankingResumen(
              titulo: 'Operaciones por bicicletero',
              datos: resumen.operacionesPorBicicletero,
              icono: Icons.location_on_outlined,
              maxItems: 3,
            );

            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: guardias),
                  const SizedBox(width: 10),
                  Expanded(child: bicicleteros),
                ],
              );
            }

            return Column(
              children: [
                guardias,
                const SizedBox(height: 10),
                bicicleteros,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ActividadRecienteDashboard extends StatelessWidget {
  const _ActividadRecienteDashboard({
    required this.movimientos,
    this.onVerMovimientos,
  });

  final List<MovimientoApp> movimientos;
  final VoidCallback? onVerMovimientos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: TituloApartado(titulo: 'Actividad reciente'),
            ),
            if (onVerMovimientos != null)
              TextButton(
                onPressed: onVerMovimientos,
                child: const Text('Ver historial'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (movimientos.isEmpty)
          const EstadoLista(
            icono: Icons.history_outlined,
            titulo: 'Sin actividad reciente',
            detalle: 'No hay movimientos registrados hoy.',
          )
        else
          ...movimientos.map(
            (movimiento) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MovimientoRecienteCompacto(movimiento: movimiento),
            ),
          ),
      ],
    );
  }
}

class _MovimientoRecienteCompacto extends StatelessWidget {
  const _MovimientoRecienteCompacto({required this.movimiento});

  final MovimientoApp movimiento;

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';
    final color = confirmado ? ColoresUbb.exito : ColoresUbb.rojoInstitucional;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              esIngreso ? Icons.login_outlined : Icons.logout_outlined,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${esIngreso ? 'Ingreso' : 'Retiro'} | ${movimiento.usuarioNombre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColoresUbb.azulNoche,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${movimiento.bicicleteroNombre} · ${formatearHora(movimiento.creadoEn)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresUbb.textoSecundario,
                        ),
                  ),
                ],
              ),
            ),
            ChipEstado(
              texto: confirmado ? 'Confirmado' : 'Denegado',
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingResumen extends StatelessWidget {
  const _RankingResumen({
    required this.titulo,
    required this.datos,
    required this.icono,
    this.maxItems = 5,
  });

  final String titulo;
  final Map<String, int> datos;
  final IconData icono;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final entradas = datos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximo = entradas.isEmpty ? 1 : entradas.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: ColoresUbb.azulApp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entradas.isEmpty)
              Text(
                'Sin datos para el filtro seleccionado.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.textoSecundario,
                    ),
              )
            else
              ...entradas.take(maxItems).map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entrada.key,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                entrada.value.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: entrada.value / maximo,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
