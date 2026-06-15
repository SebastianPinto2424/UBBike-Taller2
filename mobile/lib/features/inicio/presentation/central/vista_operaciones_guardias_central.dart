part of '../pantalla_principal.dart';

class _ResumenGuardia {
  int total = 0;
  int denegaciones = 0;
  final bicicleteros = <String>{};
}

String _detalleResumenGuardia(_ResumenGuardia resumen) {
  final bicicleteros = resumen.bicicleteros.toList()..sort();
  final visibles = bicicleteros.take(2).join(', ');
  final restantes = bicicleteros.length - 2;
  final detalleBicicleteros =
      restantes > 0 ? '$visibles y $restantes más' : visibles;

  return [
    '${resumen.total} validaciones',
    '${resumen.denegaciones} denegaciones',
    if (detalleBicicleteros.isNotEmpty) detalleBicicleteros,
  ].join(' | ');
}

Map<String, _ResumenGuardia> _agruparPorGuardia(
  List<MovimientoApp> movimientos,
) {
  final resumen = <String, _ResumenGuardia>{};

  for (final movimiento in movimientos) {
    final guardia = resumen.putIfAbsent(
      movimiento.guardiaNombre,
      _ResumenGuardia.new,
    );

    guardia.total += 1;
    if (movimiento.estado == 'DENEGADO') {
      guardia.denegaciones += 1;
    }
    guardia.bicicleteros.add(movimiento.bicicleteroNombre);
  }

  return resumen;
}

class VistaOperacionesGuardiasCentral extends StatefulWidget {
  const VistaOperacionesGuardiasCentral({super.key});

  @override
  State<VistaOperacionesGuardiasCentral> createState() =>
      _VistaOperacionesGuardiasCentralState();
}

class _VistaOperacionesGuardiasCentralState
    extends State<VistaOperacionesGuardiasCentral> {
  late final HistorialRepository historialRepository;
  late final SolicitudGuardiaRepository solicitudGuardiaRepository;
  String periodo = 'DIA';
  String estadoMovimiento = 'TODOS';
  BicicleteroApp? bicicleteroSeleccionado;
  List<BicicleteroApp> bicicleteros = [];
  late Future<List<MovimientoApp>> futuroMovimientos;

  @override
  void initState() {
    super.initState();
    historialRepository = _leerProvider(context, historialRepositoryProvider);
    solicitudGuardiaRepository = _leerProvider(
      context,
      solicitudGuardiaRepositoryProvider,
    );
    futuroMovimientos = _obtenerMovimientos();
    _cargarBicicleteros();
  }

  Future<void> _cargarBicicleteros() async {
    try {
      final datos = await solicitudGuardiaRepository.listarBicicleteros();
      if (mounted) {
        setState(() => bicicleteros = datos);
      }
    } catch (_) {
      if (mounted) {
        setState(() => bicicleteros = []);
      }
    }
  }

  Future<List<MovimientoApp>> _obtenerMovimientos() {
    return historialRepository.listar(
      periodo: periodo,
      estado: estadoMovimiento,
      bicicleteroId: bicicleteroSeleccionado?.id,
      limite: 100000,
    );
  }

  void _recargar() {
    setState(() => futuroMovimientos = _obtenerMovimientos());
  }

  String _resumenFiltros() {
    return [
      _etiquetaPeriodoFiltro(periodo),
      bicicleteroSeleccionado?.nombre ?? 'Todos los bicicleteros',
      _etiquetaEstadoMovimientoFiltro(estadoMovimiento),
    ].join(' | ');
  }

  void _limpiarFiltros() {
    setState(() {
      periodo = 'DIA';
      estadoMovimiento = 'TODOS';
      bicicleteroSeleccionado = null;
      futuroMovimientos = _obtenerMovimientos();
    });
  }

  void _mostrarDetalleGuardia(
    String nombre,
    _ResumenGuardia resumen,
    List<MovimientoApp> movimientos,
  ) {
    final ordenados = [...movimientos]
      ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    final double alturaInicial =
        (0.42 + ordenados.length * 0.12).clamp(0.42, 0.9).toDouble();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: alturaInicial,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Operaciones de $nombre',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              _detalleResumenGuardia(resumen),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            ...ordenados.map(
              (movimiento) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TarjetaMovimientoCentral(
                  movimiento: movimiento,
                  mostrarIdentidad: true,
                  mostrarGuardia: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        const TituloApartado(titulo: 'Operaciones por guardia'),
        const SizedBox(height: 10),
        _PanelFiltros(
          titulo: 'Filtros de operaciones',
          detalle: _resumenFiltros(),
          onLimpiar: _limpiarFiltros,
          children: [
            _EtiquetaFiltro(
              texto: 'Periodo',
              child: _SegmentadoEnLinea<String>(
                segments: const [
                  ButtonSegment(value: 'DIA', label: Text('Día')),
                  ButtonSegment(value: 'SEMANA', label: Text('Semana')),
                  ButtonSegment(value: 'MES', label: Text('Mes')),
                  ButtonSegment(value: 'ANIO', label: Text('Año')),
                ],
                selected: {periodo},
                onSelectionChanged: (valor) {
                  setState(() {
                    periodo = valor.first;
                    futuroMovimientos = _obtenerMovimientos();
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownAnclado<BicicleteroApp?>(
                  key: ValueKey(bicicleteroSeleccionado?.id ?? 'todos'),
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 300,
                  value: bicicleteroSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Bicicletero',
                  ),
                  items: [
                    const DropdownMenuItem<BicicleteroApp?>(
                      value: null,
                      child: Text('Todos los bicicleteros'),
                    ),
                    ...bicicleteros.map(
                      (bicicletero) => DropdownMenuItem<BicicleteroApp?>(
                        value: bicicletero,
                        child: Text(
                          bicicletero.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      bicicleteroSeleccionado = valor;
                      futuroMovimientos = _obtenerMovimientos();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _EtiquetaFiltro(
              texto: 'Resultado',
              child: _SegmentadoEnLinea<String>(
                segments: const [
                  ButtonSegment(value: 'TODOS', label: Text('Todos')),
                  ButtonSegment(
                      value: 'CONFIRMADO', label: Text('Confirmados')),
                  ButtonSegment(value: 'DENEGADO', label: Text('Denegados')),
                ],
                selected: {estadoMovimiento},
                onSelectionChanged: (valor) {
                  setState(() {
                    estadoMovimiento = valor.first;
                    futuroMovimientos = _obtenerMovimientos();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<MovimientoApp>>(
          future: futuroMovimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar operaciones',
                detalle: '${snapshot.error}\nToca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final movimientos = snapshot.data ?? [];
            final resumen = _agruparPorGuardia(movimientos);
            final entradas = resumen.entries.toList()
              ..sort((a, b) => b.value.total.compareTo(a.value.total));

            if (entradas.isEmpty) {
              return const EstadoLista(
                icono: Icons.security_outlined,
                titulo: 'Sin operaciones',
                detalle: 'No hay validaciones para el periodo seleccionado.',
              );
            }

            return Column(
              children: entradas
                  .map(
                    (entrada) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TarjetaAccion(
                        icono: Icons.verified_user_outlined,
                        titulo: entrada.key,
                        detalle: _detalleResumenGuardia(entrada.value),
                        color: entrada.value.denegaciones == 0
                            ? ColoresUbb.exito
                            : ColoresUbb.amarilloInstitucional,
                        onTap: () => _mostrarDetalleGuardia(
                          entrada.key,
                          entrada.value,
                          movimientos
                              .where((m) => m.guardiaNombre == entrada.key)
                              .toList(),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
