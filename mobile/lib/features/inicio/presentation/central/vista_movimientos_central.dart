part of '../pantalla_principal.dart';

class VistaMovimientosCentral extends StatefulWidget {
  const VistaMovimientosCentral({super.key});

  @override
  State<VistaMovimientosCentral> createState() =>
      _VistaMovimientosCentralState();
}

class _VistaMovimientosCentralState extends State<VistaMovimientosCentral> {
  static const int _limiteVistaHistorial = 300;
  static const int _limiteReporteHistorial = 100000;

  late final HistorialRepository historialRepository;
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
    final sesion = _leerProvider(context, sesionProvider).value;
    final rol = sesion is SesionActiva ? sesion.usuario.rol : null;
    return rol == RolUsuario.adminCentral || rol == RolUsuario.administrador;
  }

  @override
  void initState() {
    super.initState();
    historialRepository = _leerProvider(context, historialRepositoryProvider);
    futuroMovimientos = _obtenerMovimientos();
    if (_esCentral) {
      futuroOpciones = historialRepository.opciones();
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
    return historialRepository.listar(
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
    setState(() => futuroMovimientos = _obtenerMovimientos());
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
      _etiquetaPeriodoFiltro(periodo),
      if (fechaDesde != null || fechaHasta != null) _textoRangoFechas(),
      _etiquetaTipoMovimientoFiltro(tipoMovimiento),
      _etiquetaEstadoMovimientoFiltro(estadoMovimiento),
      _etiquetaOrigenMovimientoFiltro(origenMovimiento),
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
      final excel = await historialRepository.exportarExcel(
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
                      _etiquetaOrigenMovimientoFiltro(m.origen),
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
      _EtiquetaFiltro(
        texto: 'Período',
        child: _SegmentadoEnLinea<String>(
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
      _EtiquetaFiltro(
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
      _EtiquetaFiltro(
        texto: 'Tipo de movimiento',
        child: _SegmentadoEnLinea<String>(
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
      _EtiquetaFiltro(
        texto: 'Resultado',
        child: _SegmentadoEnLinea<String>(
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
      _EtiquetaFiltro(
        texto: 'Origen',
        child: _SegmentadoEnLinea<String>(
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _PanelFiltros(
                  titulo: 'Filtros',
                  detalle: _resumenFiltros(),
                  onLimpiar: _limpiarFiltros,
                  children: _controlesFiltros(),
                ),
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
                const SizedBox(height: 16),
                FutureBuilder<List<MovimientoApp>>(
                  future: futuroMovimientos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return TarjetaAccion(
                        icono: Icons.error_outline,
                        titulo: 'No se pudieron cargar movimientos',
                        detalle: 'Toca para reintentar.',
                        color: ColoresUbb.rojoInstitucional,
                        onTap: _recargar,
                      );
                    }
                    final movimientos = snapshot.data ?? [];
                    if (movimientos.isEmpty) {
                      return const EstadoLista(
                        icono: Icons.history,
                        titulo: 'Sin movimientos',
                        detalle:
                            'Los ingresos y retiros que coincidan aparecerán aquí.',
                      );
                    }
                    return Column(
                      children: [
                        ...movimientos.map(
                          (movimiento) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TarjetaMovimientoCentral(
                              movimiento: movimiento,
                              mostrarIdentidad: true,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaMovimientoCentral extends StatelessWidget {
  const _TarjetaMovimientoCentral({
    required this.movimiento,
    this.mostrarIdentidad = true,
    this.mostrarGuardia = true,
  });

  final MovimientoApp movimiento;
  final bool mostrarIdentidad;
  final bool mostrarGuardia;

  @override
  Widget build(BuildContext context) {
    final esIngreso = movimiento.tipo == 'INGRESO';
    final confirmado = movimiento.estado == 'CONFIRMADO';
    final tipoTexto = esIngreso ? 'Ingreso' : 'Retiro';
    final motivo = movimiento.motivoDenegacion?.trim();
    final comentario = movimiento.comentarioGuardia?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  esIngreso ? Icons.login : Icons.logout,
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mostrarIdentidad
                        ? '$tipoTexto | ${movimiento.usuarioNombre}'
                        : tipoTexto,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                ChipEstado(
                  texto: confirmado ? 'Confirmado' : 'Denegado',
                  color: confirmado
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mostrarIdentidad) ...[
              FilaDato(
                etiqueta: 'Correo',
                valor: movimiento.usuarioCorreo,
                anchoCompleto: true,
              ),
              FilaDato(
                etiqueta: 'RUT',
                valor: movimiento.usuarioRut ?? 'Sin RUT',
              ),
            ],
            FilaDato(
              etiqueta: 'Bicicleta',
              valor: movimiento.bicicletaDescripcion,
            ),
            FilaDato(
              etiqueta: 'Bicicletero',
              valor: movimiento.bicicleteroNombre,
              anchoCompleto: true,
            ),
            if (mostrarGuardia)
              FilaDato(etiqueta: 'Guardia', valor: movimiento.guardiaNombre),
            FilaDato(
              etiqueta: 'Fecha',
              valor: formatearFecha(movimiento.creadoEn),
            ),
            FilaDato(
              etiqueta: 'Hora',
              valor: formatearHora(movimiento.creadoEn),
            ),
            FilaDato(
              etiqueta: 'Método',
              valor: _etiquetaOrigenMovimientoFiltro(movimiento.origen),
            ),
            if (motivo != null && motivo.isNotEmpty)
              FilaDato(
                etiqueta: 'Motivo de rechazo',
                valor: motivo,
                anchoCompleto: true,
                valorColor: ColoresUbb.rojoInstitucional,
                valorPeso: FontWeight.w700,
              ),
            if (comentario != null && comentario.isNotEmpty)
              FilaDato(
                etiqueta: 'Comentario guardia',
                valor: comentario,
                anchoCompleto: true,
                valorColor: ColoresUbb.textoSecundario,
                valorPeso: FontWeight.w700,
              ),
          ],
        ),
      ),
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

class _PanelFiltros extends StatelessWidget {
  const _PanelFiltros({
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

class _EtiquetaFiltro extends StatelessWidget {
  const _EtiquetaFiltro({required this.texto, required this.child});

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

class _SegmentadoEnLinea<T extends Object> extends StatelessWidget {
  const _SegmentadoEnLinea({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: segments,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }
}

String _etiquetaPeriodoFiltro(String periodo) {
  return switch (periodo) {
    'DIA' => 'Día',
    'SEMANA' => 'Semana',
    'MES' => 'Mes',
    'ANIO' => 'Año',
    _ => periodo,
  };
}

String _etiquetaTipoMovimientoFiltro(String tipo) {
  return switch (tipo) {
    'TODOS' => 'Todos los movimientos',
    'INGRESO' => 'Ingresos',
    'RETIRO' => 'Retiros',
    _ => tipo,
  };
}

String _etiquetaEstadoMovimientoFiltro(String estado) {
  return switch (estado) {
    'TODOS' => 'Todos los resultados',
    'CONFIRMADO' => 'Confirmados',
    'DENEGADO' => 'Denegados',
    _ => estado,
  };
}

String _etiquetaOrigenMovimientoFiltro(String origen) {
  return switch (origen) {
    'TODOS' => 'Todos los orígenes',
    'QR' => 'QR',
    'MANUAL' => 'Manual',
    _ => origen,
  };
}

String _formatearFechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}
