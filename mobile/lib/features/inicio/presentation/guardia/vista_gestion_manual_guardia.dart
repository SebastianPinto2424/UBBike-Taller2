part of '../pantalla_principal.dart';

class VistaGestionManualGuardia extends StatefulWidget {
  const VistaGestionManualGuardia({super.key});

  @override
  State<VistaGestionManualGuardia> createState() =>
      _VistaGestionManualGuardiaState();
}

class _VistaGestionManualGuardiaState extends State<VistaGestionManualGuardia> {
  final formKeyGestionManual = GlobalKey<FormState>();
  final accesoApi = AccesoApi();
  final correoController = TextEditingController();
  final rutController = TextEditingController();
  final comentarioController = TextEditingController();
  final bicicletaDescripcionController = TextEditingController();
  final bicicletaMarcaController = TextEditingController();
  final bicicletaModeloController = TextEditingController();
  final bicicletaColorController = TextEditingController();
  final bicicletaAroController = TextEditingController();
  final bicicletaNumeroSerieController = TextEditingController();
  String operacion = 'INGRESO';
  Timer? temporizadorBusqueda;
  CoincidenciaManualApp? coincidenciaManual;
  String? bicicletaSeleccionadaId;
  String? errorBusquedaManual;
  bool buscandoCoincidencia = false;
  bool busquedaRealizada = false;
  bool actualizandoCampos = false;
  bool registrando = false;

  bool get _retiroBloqueadoPorRegistroParcial =>
      coincidenciaManual?.usuario.registroParcial == true &&
      operacion == 'RETIRO';

  bool get _debeMostrarOperacion =>
      bicicletaSeleccionadaId != null ||
      busquedaRealizada ||
      bicicletaDescripcionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    correoController.addListener(_programarBusquedaCoincidencia);
    rutController.addListener(_programarBusquedaCoincidencia);
    bicicletaDescripcionController.addListener(_actualizarOperacionVisible);
  }

  @override
  void dispose() {
    temporizadorBusqueda?.cancel();
    correoController.removeListener(_programarBusquedaCoincidencia);
    rutController.removeListener(_programarBusquedaCoincidencia);
    bicicletaDescripcionController.removeListener(_actualizarOperacionVisible);
    correoController.dispose();
    rutController.dispose();
    comentarioController.dispose();
    bicicletaDescripcionController.dispose();
    bicicletaMarcaController.dispose();
    bicicletaModeloController.dispose();
    bicicletaColorController.dispose();
    bicicletaAroController.dispose();
    bicicletaNumeroSerieController.dispose();
    super.dispose();
  }

  void _actualizarOperacionVisible() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final retiroRegistroParcialBloqueado = _retiroBloqueadoPorRegistroParcial;
    final mostrarOperacion = _debeMostrarOperacion;

    return ListView(
      children: [
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKeyGestionManual,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (mostrarOperacion) ...[
                    _IndicadorOperacionManual(
                      operacion: operacion,
                      autodetectada: bicicletaSeleccionadaId != null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                    ),
                    validator: (valor) =>
                        _validarCorreoGestionManual(valor, rutController.text),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rutController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'RUT',
                    ),
                    validator: _validarRutGestionManual,
                  ),
                  _EstadoBusquedaManual(
                    buscando: buscandoCoincidencia,
                    busquedaRealizada: busquedaRealizada,
                    error: errorBusquedaManual,
                    coincidencia: coincidenciaManual,
                    onUsarDatos:
                        coincidenciaManual == null ? null : _autocompletarDatos,
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    initiallyExpanded:
                        busquedaRealizada && coincidenciaManual == null,
                    title: const Text('Datos de bicicleta'),
                    subtitle: Text(
                      bicicletaSeleccionadaId == null
                          ? 'Para usuario nuevo o bicicleta no registrada'
                          : 'Bicicleta registrada seleccionada',
                    ),
                    children: [
                      if ((coincidenciaManual?.bicicletas ?? const [])
                          .isNotEmpty) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return DropdownAnclado<String>(
                              key: ValueKey(
                                bicicletaSeleccionadaId ?? 'sin-bici',
                              ),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              menuMaxHeight: 300,
                              value: bicicletaSeleccionadaId,
                              decoration: const InputDecoration(
                                labelText: 'Bicicleta registrada',
                              ),
                              items: coincidenciaManual!.bicicletas
                                  .map(
                                    (bicicleta) => DropdownMenuItem(
                                      value: bicicleta.id,
                                      child: Text(
                                        _resumenBicicleta(bicicleta),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (valor) =>
                                  _seleccionarBicicleta(valor),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _usarBicicletaNoRegistrada,
                            child: const Text('Usar bicicleta no registrada'),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: bicicletaDescripcionController,
                        readOnly: bicicletaSeleccionadaId != null,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Ej: MTB roja con canasto',
                        ),
                        validator: (valor) =>
                            _validarDescripcionBicicletaManual(
                          valor,
                          bicicletaSeleccionadaId == null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bicicletaMarcaController,
                        readOnly: bicicletaSeleccionadaId != null,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                        ),
                        validator: (valor) =>
                            _validarCampoOpcionalGestionManual(valor, 80),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bicicletaModeloController,
                        readOnly: bicicletaSeleccionadaId != null,
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                        ),
                        validator: (valor) =>
                            _validarCampoOpcionalGestionManual(valor, 80),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bicicletaColorController,
                        readOnly: bicicletaSeleccionadaId != null,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                        ),
                        validator: (valor) =>
                            _validarCampoOpcionalGestionManual(valor, 60),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaAroController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'Aro',
                              ),
                              validator: (valor) =>
                                  _validarCampoOpcionalGestionManual(valor, 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaNumeroSerieController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'N. serie',
                              ),
                              validator: (valor) =>
                                  _validarCampoOpcionalGestionManual(
                                      valor, 120),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: comentarioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comentario opcional del guardia',
                      hintText: 'Ej: Usuario posee U-Lock',
                      alignLabelWithHint: true,
                    ),
                    validator: (valor) =>
                        _validarCampoOpcionalGestionManual(valor, 600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColoresUbb.superficieAzulSuave,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColoresUbb.borde),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: ColoresUbb.azulApp),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ingresa correo o RUT. Si existe coincidencia, los datos y la operacion se detectan automaticamente.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (retiroRegistroParcialBloqueado) ...[
                    const SizedBox(height: 12),
                    const _CajaBusquedaManual(
                      icono: Icons.lock_outline,
                      color: ColoresUbb.rojoInstitucional,
                      children: [
                        Text(
                          'Retiro bloqueado: el usuario debe completar su registro desde el correo de activacion antes de retirar la bicicleta.',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: registrando || retiroRegistroParcialBloqueado
                        ? null
                        : _registrarManual,
                    child: registrando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Registrar ${operacion == 'INGRESO' ? 'ingreso' : 'retiro'}',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _programarBusquedaCoincidencia() {
    if (actualizandoCampos) {
      return;
    }

    temporizadorBusqueda?.cancel();
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();

    if (correo.isEmpty && rut.isEmpty) {
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = null;
      });
      return;
    }

    if (!_datoBusquedaSuficiente(correo, rut)) {
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = null;
      });
      return;
    }

    setState(() {
      buscandoCoincidencia = true;
      busquedaRealizada = false;
      coincidenciaManual = null;
      bicicletaSeleccionadaId = null;
      errorBusquedaManual = null;
    });

    temporizadorBusqueda = Timer(
      const Duration(milliseconds: 550),
      () => _buscarCoincidencia(correo, rut),
    );
  }

  bool _datoBusquedaSuficiente(String correo, String rut) {
    final rutLimpio = rut.replaceAll('.', '').replaceAll('-', '');
    return correo.contains('@') || rutLimpio.length >= 7;
  }

  Future<void> _buscarCoincidencia(String correo, String rut) async {
    try {
      final coincidencia = await accesoApi.buscarCoincidenciaManual(
        correo: correo,
        rut: rut,
      );

      if (!mounted ||
          correoController.text.trim() != correo ||
          rutController.text.trim() != rut) {
        return;
      }

      if (coincidencia == null) {
        setState(() {
          buscandoCoincidencia = false;
          busquedaRealizada = true;
          coincidenciaManual = null;
          bicicletaSeleccionadaId = null;
          errorBusquedaManual = null;
        });
        return;
      }

      _aplicarCoincidenciaManual(coincidencia);
    } on ExcepcionApi catch (error) {
      if (!mounted) return;
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = true;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        errorBusquedaManual = error.mensaje;
      });
    }
  }

  void _autocompletarDatos() {
    final coincidencia = coincidenciaManual;
    if (coincidencia == null) {
      return;
    }

    _aplicarCoincidenciaManual(coincidencia);
    context.mostrarInfo('Datos cargados para ${coincidencia.usuario.nombre}');
  }

  void _aplicarCoincidenciaManual(
    CoincidenciaManualApp coincidencia,
  ) {
    actualizandoCampos = true;
    correoController.text = coincidencia.usuario.correo;
    rutController.text = coincidencia.usuario.rut ?? rutController.text.trim();
    actualizandoCampos = false;

    final preferida = _bicicletaPreferidaAutodetectada(coincidencia.bicicletas);

    setState(() {
      buscandoCoincidencia = false;
      busquedaRealizada = true;
      coincidenciaManual = coincidencia;
      bicicletaSeleccionadaId = preferida?.id;
      errorBusquedaManual = null;

      if (preferida == null) {
        operacion = 'INGRESO';
        return;
      }

      _cargarDatosBicicleta(preferida);
      operacion = _operacionParaBicicleta(preferida);
    });
  }

  BicicletaApp? _bicicletaPreferidaAutodetectada(
    List<BicicletaApp> bicicletas,
  ) {
    if (bicicletas.isEmpty) {
      return null;
    }

    final dentroActivas = bicicletas.where(
      (bicicleta) => bicicleta.dentroBicicletero && bicicleta.activa,
    );
    if (dentroActivas.isNotEmpty) {
      return dentroActivas.first;
    }

    final dentro = bicicletas.where((bicicleta) => bicicleta.dentroBicicletero);
    if (dentro.isNotEmpty) {
      return dentro.first;
    }

    final activas = bicicletas.where((bicicleta) => bicicleta.activa);
    if (activas.isNotEmpty) {
      return activas.first;
    }

    return bicicletas.first;
  }

  String _operacionParaBicicleta(BicicletaApp bicicleta) {
    return bicicleta.dentroBicicletero ? 'RETIRO' : 'INGRESO';
  }

  BicicletaApp? _buscarBicicletaSeleccionada(String? bicicletaId) {
    if (bicicletaId == null) {
      return null;
    }

    for (final bicicleta
        in coincidenciaManual?.bicicletas ?? const <BicicletaApp>[]) {
      if (bicicleta.id == bicicletaId) {
        return bicicleta;
      }
    }

    return null;
  }

  void _seleccionarBicicleta(String? bicicletaId) {
    final bicicleta = _buscarBicicletaSeleccionada(bicicletaId);

    setState(() {
      bicicletaSeleccionadaId = bicicleta?.id;
      if (bicicleta != null) {
        _cargarDatosBicicleta(bicicleta);
        operacion = _operacionParaBicicleta(bicicleta);
      }
    });
  }

  void _cargarDatosBicicleta(BicicletaApp bicicleta) {
    bicicletaDescripcionController.text = bicicleta.descripcion;
    bicicletaMarcaController.text = bicicleta.marca ?? '';
    bicicletaModeloController.text = bicicleta.modelo ?? '';
    bicicletaColorController.text = bicicleta.color ?? '';
    bicicletaAroController.text = bicicleta.aro ?? '';
    bicicletaNumeroSerieController.text = bicicleta.numeroSerie ?? '';
  }

  void _usarBicicletaNoRegistrada() {
    setState(() {
      operacion = 'INGRESO';
      bicicletaSeleccionadaId = null;
      bicicletaDescripcionController.clear();
      bicicletaMarcaController.clear();
      bicicletaModeloController.clear();
      bicicletaColorController.clear();
      bicicletaAroController.clear();
      bicicletaNumeroSerieController.clear();
    });
  }

  String _resumenBicicleta(BicicletaApp bicicleta) {
    final estado = bicicleta.dentroBicicletero
        ? 'Dentro${bicicleta.bicicleteroActualNombre == null ? '' : ' - ${bicicleta.bicicleteroActualNombre}'}'
        : 'Fuera';
    final activa = bicicleta.activa ? 'Activa' : 'Inactiva';
    return '${bicicleta.descripcion} | $activa | $estado';
  }

  Future<void> _registrarManual() async {
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();

    if (formKeyGestionManual.currentState?.validate() != true) {
      return;
    }

    setState(() => registrando = true);

    try {
      final movimiento = await accesoApi.registrarManual(
        correo: correo,
        rut: rut,
        bicicletaId: bicicletaSeleccionadaId,
        tipo: operacion,
        comentario: comentarioController.text.trim(),
        bicicletaDescripcion: bicicletaDescripcionController.text.trim(),
        bicicletaMarca: bicicletaMarcaController.text.trim(),
        bicicletaModelo: bicicletaModeloController.text.trim(),
        bicicletaColor: bicicletaColorController.text.trim(),
        bicicletaAro: bicicletaAroController.text.trim(),
        bicicletaNumeroSerie: bicicletaNumeroSerieController.text.trim(),
      );

      if (mounted) {
        correoController.clear();
        rutController.clear();
        comentarioController.clear();
        bicicletaDescripcionController.clear();
        bicicletaMarcaController.clear();
        bicicletaModeloController.clear();
        bicicletaColorController.clear();
        bicicletaAroController.clear();
        bicicletaNumeroSerieController.clear();
        setState(() {
          bicicletaSeleccionadaId = null;
          coincidenciaManual = null;
          busquedaRealizada = false;
          errorBusquedaManual = null;
        });
        context.mostrarExito(
          '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} registrado para ${movimiento.usuarioNombre}',
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } finally {
      if (mounted) {
        setState(() => registrando = false);
      }
    }
  }
}

String? _validarCorreoGestionManual(String? valor, String rutActual) {
  final correo = valor?.trim() ?? '';
  final rut = rutActual.trim();

  if (correo.isEmpty && rut.isEmpty) {
    return 'Ingresa correo o RUT.';
  }
  if (correo.isEmpty) {
    return null;
  }
  if (correo.length > 160) {
    return 'Maximo 160 caracteres.';
  }

  final correoValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  if (!correoValido.hasMatch(correo)) {
    return 'Ingresa un correo valido. Ej: usuario@ubiobio.cl';
  }
  return null;
}

String? _validarRutGestionManual(String? valor) {
  final rut = valor?.trim() ?? '';
  if (rut.isEmpty) {
    return null;
  }
  if (rut.length > 20) {
    return 'Maximo 20 caracteres.';
  }

  final rutLimpio = rut.replaceAll('.', '').replaceAll('-', '');
  if (rutLimpio.length < 7) {
    return 'Ingresa un RUT valido.';
  }
  return null;
}

String? _validarDescripcionBicicletaManual(
  String? valor,
  bool requerida,
) {
  final texto = valor?.trim() ?? '';
  if (!requerida && texto.isEmpty) {
    return null;
  }
  if (texto.isEmpty) {
    return 'Ingresa una descripcion.';
  }
  if (texto.length < 3) {
    return 'Debe tener al menos 3 caracteres.';
  }
  if (texto.length > 255) {
    return 'Maximo 255 caracteres.';
  }
  return null;
}

String? _validarCampoOpcionalGestionManual(String? valor, int maximo) {
  final texto = valor?.trim() ?? '';
  if (texto.length > maximo) {
    return 'Maximo $maximo caracteres.';
  }
  return null;
}

class _IndicadorOperacionManual extends StatelessWidget {
  const _IndicadorOperacionManual({
    required this.operacion,
    required this.autodetectada,
  });

  final String operacion;
  final bool autodetectada;

  @override
  Widget build(BuildContext context) {
    final esIngreso = operacion == 'INGRESO';
    final color = esIngreso ? ColoresUbb.exito : ColoresUbb.azulApp;
    final textoBase = esIngreso ? 'Ingreso' : 'Retiro';
    final textoOperacion =
        autodetectada ? '$textoBase autodetectado' : textoBase;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ChipEstado(texto: textoOperacion, color: color),
        ],
      ),
    );
  }
}

class _EstadoBusquedaManual extends StatelessWidget {
  const _EstadoBusquedaManual({
    required this.buscando,
    required this.busquedaRealizada,
    required this.coincidencia,
    required this.error,
    required this.onUsarDatos,
  });

  final bool buscando;
  final bool busquedaRealizada;
  final CoincidenciaManualApp? coincidencia;
  final String? error;
  final VoidCallback? onUsarDatos;

  @override
  Widget build(BuildContext context) {
    if (buscando) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
                child: Text('Buscando coincidencias en la base de datos...')),
          ],
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.error_outline,
          color: ColoresUbb.rojoInstitucional,
          children: [Text(error!)],
        ),
      );
    }

    final datos = coincidencia;
    if (datos != null) {
      final cantidadBicicletas = datos.bicicletas.length;
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.manage_search_outlined,
          color: ColoresUbb.exito,
          children: [
            Text(
              'Coincidencia encontrada',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            FilaDato(etiqueta: 'Usuario', valor: datos.usuario.nombre),
            FilaDato(
              etiqueta: 'Correo',
              valor: datos.usuario.correo,
              anchoCompleto: true,
            ),
            FilaDato(
              etiqueta: 'RUT',
              valor: datos.usuario.rut ?? 'Sin RUT',
            ),
            if (datos.usuario.registroParcial)
              const FilaDato(
                etiqueta: 'Estado',
                valor: 'Registro pendiente',
              ),
            FilaDato(
              etiqueta: 'Bicicletas',
              valor: cantidadBicicletas == 0
                  ? 'Sin bicicletas registradas'
                  : '$cantidadBicicletas registradas',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onUsarDatos,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('Usar datos encontrados'),
              ),
            ),
          ],
        ),
      );
    }

    if (busquedaRealizada) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: _CajaBusquedaManual(
          icono: Icons.info_outline,
          color: ColoresUbb.azulApp,
          children: [
            Text(
              'Sin coincidencia. Para un usuario nuevo, completa correo, RUT y datos de bicicleta.',
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _CajaBusquedaManual extends StatelessWidget {
  const _CajaBusquedaManual({
    required this.icono,
    required this.color,
    required this.children,
  });

  final IconData icono;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
