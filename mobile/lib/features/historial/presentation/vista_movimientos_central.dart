import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ubbike/features/historial/application/movimientos_vm.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:ubbike/core/providers/sesion_provider.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';
import 'package:ubbike/features/historial/data/historial_modelos.dart';
import 'package:ubbike/shared/modelos/movimiento_app.dart';
import 'package:ubbike/shared/modelos/rol_usuario.dart';
import 'package:ubbike/shared/servicios/descarga_reporte.dart';
import 'package:ubbike/shared/widgets/snackbar_semantico.dart';
import 'package:ubbike/shared/widgets/tarjeta_accion.dart';
import 'package:ubbike/features/inicio/presentation/comun/estado_widgets.dart';
import 'package:ubbike/features/inicio/presentation/comun/utiles_comun.dart';
import 'package:ubbike/features/historial/presentation/widgets_movimientos.dart';

class VistaMovimientosCentral extends ConsumerStatefulWidget {
  const VistaMovimientosCentral({super.key});

  @override
  ConsumerState<VistaMovimientosCentral> createState() =>
      _VistaMovimientosCentralState();
}

class _VistaMovimientosCentralState
    extends ConsumerState<VistaMovimientosCentral> {
  MovimientosCentralVm get vm => ref.read(movimientosCentralVmProvider);
  static const int _limiteVistaHistorial = 300;
  static const int _limiteReporteHistorial = 100000;

  final filtroController = TextEditingController();
  Timer? temporizadorBusqueda;
  String periodo = 'SEMANA';
  String tipoMovimiento = 'TODOS';
  String estadoMovimiento = 'TODOS';
  String origenMovimiento = 'TODOS';
  String? bicicleteroId;
  String? guardiaId;
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  String? formatoExportacion;
  bool exportarAbierto = false;
  bool exportando = false;
  late Future<List<MovimientoApp>> futuroMovimientos;
  Future<OpcionesHistorialApp>? futuroOpciones;

  bool get _esCentral {
    final sesion = ref.read(sesionProvider).value;
    final rol = sesion is SesionActiva ? sesion.usuario.rol : null;
    return rol == RolUsuario.adminCentral || rol == RolUsuario.administrador;
  }

  bool get _puedeExportar {
    final sesion = ref.read(sesionProvider).value;
    final rol = sesion is SesionActiva ? sesion.usuario.rol : null;
    return rol == RolUsuario.adminCentral;
  }

  @override
  void initState() {
    super.initState();
    futuroMovimientos = _obtenerMovimientos();
    if (_esCentral) {
      futuroOpciones = vm.opciones();
    }
  }

  @override
  void dispose() {
    temporizadorBusqueda?.cancel();
    filtroController.dispose();
    super.dispose();
  }

  Future<List<MovimientoApp>> _obtenerMovimientos({
    int limite = _limiteVistaHistorial,
  }) {
    return vm.listar(
      filtro: filtroController.text,
      periodo: periodo,
      desde: fechaDesde,
      hasta: fechaHasta,
      tipo: tipoMovimiento,
      estado: estadoMovimiento,
      bicicleteroId: bicicleteroId,
      guardiaId: guardiaId,
      origen: origenMovimiento,
      limite: limite,
    );
  }

  void _recargar() {
    temporizadorBusqueda?.cancel();
    setState(() {
      futuroMovimientos = _obtenerMovimientos();
    });
  }

  void _programarBusqueda() {
    setState(() {});
    temporizadorBusqueda?.cancel();
    temporizadorBusqueda = Timer(
      const Duration(milliseconds: 350),
      _recargar,
    );
  }

  String _resumenFiltros() {
    final busqueda = filtroController.text.trim();
    final partes = [
      etiquetaPeriodoFiltro(periodo),
      if (fechaDesde != null || fechaHasta != null) _textoRangoFechas(),
      etiquetaTipoMovimientoFiltro(tipoMovimiento),
      etiquetaEstadoMovimientoFiltro(estadoMovimiento),
      etiquetaOrigenMovimientoFiltro(origenMovimiento),
      if (bicicleteroId != null) 'Bicicletero seleccionado',
      if (guardiaId != null) 'Guardia seleccionado',
      if (busqueda.isNotEmpty) 'Búsqueda activa',
    ];

    return partes.join(' | ');
  }

  void _limpiarFiltros() {
    temporizadorBusqueda?.cancel();
    filtroController.clear();
    periodo = 'SEMANA';
    tipoMovimiento = 'TODOS';
    estadoMovimiento = 'TODOS';
    origenMovimiento = 'TODOS';
    bicicleteroId = null;
    guardiaId = null;
    fechaDesde = null;
    fechaHasta = null;
    _recargar();
  }

  String _textoRangoFechas() {
    final desde =
        fechaDesde == null ? 'Inicio' : _formatearFechaCorta(fechaDesde!);
    final hasta =
        fechaHasta == null ? 'Hoy' : _formatearFechaCorta(fechaHasta!);
    return '$desde a $hasta';
  }

  Future<void> _seleccionarFecha({required bool esDesde}) async {
    final res = await showDatePicker(
      context: context,
      initialDate: (esDesde ? fechaDesde : fechaHasta) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 1),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (res != null) {
      if (!mounted) {
        return;
      }

      final nuevoDesde = esDesde ? res : fechaDesde;
      final nuevoHasta = esDesde ? fechaHasta : res;

      if (nuevoDesde != null &&
          nuevoHasta != null &&
          nuevoDesde.isAfter(nuevoHasta)) {
        context.mostrarError('El rango de fechas no es válido.');
        return;
      }

      setState(() {
        fechaDesde = nuevoDesde;
        fechaHasta = nuevoHasta;
      });
      _recargar();
    }
  }

  Future<void> _exportarExcel() async {
    if (exportando) return;
    setState(() => exportando = true);
    try {
      final excel = await vm.exportarExcel(
        filtro: filtroController.text,
        periodo: periodo,
        desde: fechaDesde,
        hasta: fechaHasta,
        tipo: tipoMovimiento,
        estado: estadoMovimiento,
        bicicleteroId: bicicleteroId,
        guardiaId: guardiaId,
        origen: origenMovimiento,
      );
      final nombre =
          'historial-ubbike-${DateTime.now().millisecondsSinceEpoch}.xls';
      final mensaje = await descargarReporteTexto(
        nombreArchivo: nombre,
        contenido: excel,
        tipoMime: 'application/vnd.ms-excel;charset=utf-8',
      );
      if (mounted) {
        context.mostrarExito(mensaje);
      }
    } catch (error) {
      if (mounted) {
        context.mostrarError(error.toString());
      }
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  Future<void> _exportarPdf() async {
    if (exportando) return;
    setState(() => exportando = true);
    try {
      final movimientos = await _obtenerMovimientos(
        limite: _limiteReporteHistorial,
      );
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Header(
                level: 0, child: pw.Text('Reporte de movimientos UBBike')),
            pw.Text('Filtros: ${_resumenFiltros()}'),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              data: <List<String>>[
                <String>[
                  'Tipo',
                  'Estado',
                  'Fecha',
                  'Hora',
                  'Usuario',
                  'Correo',
                  'RUT',
                  'Bicicleta',
                  'Bicicletero',
                  'Guardia',
                  'Método',
                ],
                ...movimientos.map((m) => [
                      m.tipo == "INGRESO" ? "Ingreso" : "Retiro",
                      m.estado == "CONFIRMADO" ? "Confirmado" : "Denegado",
                      formatearFecha(m.creadoEn),
                      formatearHora(m.creadoEn),
                      m.usuarioNombre,
                      m.usuarioCorreo,
                      m.usuarioRut ?? 'Sin RUT',
                      m.bicicletaDescripcion,
                      m.bicicleteroNombre,
                      m.guardiaNombre,
                      etiquetaOrigenMovimientoFiltro(m.origen),
                    ]),
              ],
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'historial-ubbike.pdf',
      );
    } catch (e) {
      if (mounted) {
        context.mostrarError('Error al exportar PDF: $e');
      }
    } finally {
      if (mounted) setState(() => exportando = false);
    }
  }

  Future<void> _exportarSeleccionado(String? formato) async {
    if (formato == null || exportando) {
      return;
    }

    if (formato == 'EXCEL') {
      await _exportarExcel();
    } else if (formato == 'PDF') {
      await _exportarPdf();
    }
  }

  List<Widget> _controlesFiltros() {
    return [
      EtiquetaFiltro(
        texto: 'Período',
        child: SegmentadoEnLinea<String>(
          segments: const [
            ButtonSegment(value: 'DIA', label: Text('Día')),
            ButtonSegment(value: 'SEMANA', label: Text('Semana')),
            ButtonSegment(value: 'MES', label: Text('Mes')),
            ButtonSegment(value: 'ANIO', label: Text('Año')),
          ],
          selected: {periodo},
          onSelectionChanged: (valor) {
            setState(() => periodo = valor.first);
            _recargar();
          },
        ),
      ),
      const SizedBox(height: 12),
      EtiquetaFiltro(
        texto: 'Rango exacto',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(esDesde: true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      fechaDesde == null
                          ? 'Desde'
                          : _formatearFechaCorta(fechaDesde!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarFecha(esDesde: false),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(
                      fechaHasta == null
                          ? 'Hasta'
                          : _formatearFechaCorta(fechaHasta!),
                    ),
                  ),
                ),
              ],
            ),
            if (fechaDesde != null || fechaHasta != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      fechaDesde = null;
                      fechaHasta = null;
                    });
                    _recargar();
                  },
                  child: const Text('Quitar rango'),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      EtiquetaFiltro(
        texto: 'Tipo de movimiento',
        child: SegmentadoEnLinea<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todos')),
            ButtonSegment(value: 'INGRESO', label: Text('Ingresos')),
            ButtonSegment(value: 'RETIRO', label: Text('Retiros')),
          ],
          selected: {tipoMovimiento},
          onSelectionChanged: (valor) {
            setState(() => tipoMovimiento = valor.first);
            _recargar();
          },
        ),
      ),
      const SizedBox(height: 12),
      EtiquetaFiltro(
        texto: 'Resultado',
        child: SegmentadoEnLinea<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todos')),
            ButtonSegment(value: 'CONFIRMADO', label: Text('Confirmados')),
            ButtonSegment(value: 'DENEGADO', label: Text('Denegados')),
          ],
          selected: {estadoMovimiento},
          onSelectionChanged: (valor) {
            setState(() => estadoMovimiento = valor.first);
            _recargar();
          },
        ),
      ),
      const SizedBox(height: 12),
      EtiquetaFiltro(
        texto: 'Origen',
        child: SegmentadoEnLinea<String>(
          segments: const [
            ButtonSegment(value: 'TODOS', label: Text('Todos')),
            ButtonSegment(value: 'QR', label: Text('QR')),
            ButtonSegment(value: 'MANUAL', label: Text('Manual')),
          ],
          selected: {origenMovimiento},
          onSelectionChanged: (valor) {
            setState(() => origenMovimiento = valor.first);
            _recargar();
          },
        ),
      ),
      if (_esCentral && futuroOpciones != null) ...[
        const SizedBox(height: 12),
        FutureBuilder<OpcionesHistorialApp>(
          future: futuroOpciones,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final opciones = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownAnclado<String>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      menuMaxHeight: 300,
                      value: bicicleteroId,
                      decoration:
                          const InputDecoration(labelText: 'Bicicletero'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...opciones.bicicleteros.map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => bicicleteroId = v);
                        _recargar();
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownAnclado<String>(
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(16),
                      menuMaxHeight: 300,
                      value: guardiaId,
                      decoration: const InputDecoration(labelText: 'Guardia'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...opciones.guardias.map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(g.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => guardiaId = v);
                        _recargar();
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloApartado(titulo: 'Historial'),
        const SizedBox(height: 10),
        TextField(
          controller: filtroController,
          textInputAction: TextInputAction.search,
          onChanged: (_) => _programarBusqueda(),
          onSubmitted: (_) => _recargar(),
          decoration: InputDecoration(
            labelText: 'Buscar por bicicleta, bicicletero o guardia',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: filtroController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      temporizadorBusqueda?.cancel();
                      filtroController.clear();
                      _recargar();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),

        PanelFiltros(
          titulo: 'Filtros',
          detalle: _resumenFiltros(),
          onLimpiar: _limpiarFiltros,
          children: _controlesFiltros(),
        ),

        if (_puedeExportar) ...[
          const SizedBox(height: 10),
          _PanelExportarHistorial(
            exportando: exportando,
            expandido: exportarAbierto,
            formatoSeleccionado: formatoExportacion,
            onToggle: () {
              setState(() => exportarAbierto = !exportarAbierto);
            },
            onFormato: (formato) {
              setState(() => formatoExportacion = formato);
            },
            onDescargar: () => _exportarSeleccionado(formatoExportacion),
          ),
        ],
        const SizedBox(height: 16),

        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: FutureBuilder<List<MovimientoApp>>(
              future: futuroMovimientos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      TarjetaAccion(
                        icono: Icons.error_outline,
                        titulo: 'No se pudieron cargar movimientos',
                        detalle: 'Toca para reintentar.',
                        color: ColoresUbb.rojoInstitucional,
                        onTap: _recargar,
                      ),
                    ],
                  );
                }
                final movimientos = snapshot.data ?? [];
                if (movimientos.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EstadoLista(
                        icono: Icons.history,
                        titulo: 'Sin movimientos',
                        detalle:
                            'Los ingresos y retiros que coincidan aparecerán aquí.',
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: movimientos.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TarjetaMovimientoCentral(
                      movimiento: movimientos[index],
                      mostrarIdentidad: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelExportarHistorial extends StatelessWidget {
  const _PanelExportarHistorial({
    required this.exportando,
    required this.expandido,
    required this.formatoSeleccionado,
    required this.onToggle,
    required this.onFormato,
    required this.onDescargar,
  });

  final bool exportando;
  final bool expandido;
  final String? formatoSeleccionado;
  final VoidCallback onToggle;
  final ValueChanged<String?> onFormato;
  final VoidCallback onDescargar;

  @override
  Widget build(BuildContext context) {
    final etiquetaFormato = switch (formatoSeleccionado) {
      'EXCEL' => 'Excel',
      'PDF' => 'PDF',
      _ => 'Excel o PDF',
    };

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: exportando ? null : onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (exportando) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColoresUbb.azulApp,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exportando ? 'Exportando' : 'Exportar',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: ColoresUbb.azulNoche,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Usa los filtros actuales',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ColoresUbb.textoSecundario,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    etiquetaFormato,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColoresUbb.azulApp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: ColoresUbb.azulApp,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _OpcionExportacion(
                    titulo: 'Excel',
                    detalle: 'Archivo editable con los movimientos filtrados.',
                    seleccionado: formatoSeleccionado == 'EXCEL',
                    onChanged: exportando
                        ? null
                        : (activo) => onFormato(activo ? 'EXCEL' : null),
                  ),
                  const SizedBox(height: 10),
                  _OpcionExportacion(
                    titulo: 'PDF',
                    detalle: 'Reporte listo para compartir o imprimir.',
                    seleccionado: formatoSeleccionado == 'PDF',
                    onChanged: exportando
                        ? null
                        : (activo) => onFormato(activo ? 'PDF' : null),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: formatoSeleccionado == null || exportando
                        ? null
                        : onDescargar,
                    child: Text(exportando ? 'Descargando...' : 'Descargar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionExportacion extends StatelessWidget {
  const _OpcionExportacion({
    required this.titulo,
    required this.detalle,
    required this.seleccionado,
    required this.onChanged,
  });

  final String titulo;
  final String detalle;
  final bool seleccionado;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!seleccionado),
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? ColoresUbb.azulApp.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionado ? ColoresUbb.azulApp : ColoresUbb.borde,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            const SizedBox(width: 10),
            Switch.adaptive(
              value: seleccionado,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: ColoresUbb.azulApp,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}
