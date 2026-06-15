part of '../pantalla_principal.dart';

class VistaGestionManualGuardia extends StatefulWidget {
  const VistaGestionManualGuardia({super.key});

  @override
  State<VistaGestionManualGuardia> createState() =>
      _VistaGestionManualGuardiaState();
}

class _VistaGestionManualGuardiaState extends State<VistaGestionManualGuardia> {
  final formKeyGestionManual = GlobalKey<FormState>();
  late final AccesoRepository accesoRepository;
  late final SolicitudGuardiaRepository solicitudGuardiaRepository;
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final rutController = TextEditingController();
  final comentarioController = TextEditingController();
  final bicicletaDescripcionController = TextEditingController();
  final bicicletaMarcaController = TextEditingController();
  final bicicletaModeloController = TextEditingController();
  final bicicletaColorController = TextEditingController();
  final bicicletaAroController = TextEditingController();
  final bicicletaNumeroSerieController = TextEditingController();
  String? fotoBicicletaManual;
  String operacion = 'INGRESO';
  Timer? temporizadorBusqueda;
  CoincidenciaManualApp? coincidenciaManual;
  List<BicicleteroApp> bicicleteros = [];
  String? bicicletaSeleccionadaId;
  String? bicicleteroSeleccionadoId;
  String? errorBusquedaManual;
  String? errorBicicleteros;
  bool buscandoCoincidencia = false;
  bool busquedaRealizada = false;
  bool actualizandoCampos = false;
  bool registrando = false;
  bool cargandoBicicleteros = false;

  bool get _retiroBloqueadoPorRegistroParcial =>
      coincidenciaManual?.usuario.registroParcial == true &&
      operacion == 'RETIRO';

  bool get _debeMostrarOperacion =>
      bicicletaSeleccionadaId != null ||
      busquedaRealizada ||
      bicicletaDescripcionController.text.trim().isNotEmpty;

  bool get _requiereDatosUsuarioNuevo =>
      busquedaRealizada && coincidenciaManual == null;

  @override
  void initState() {
    super.initState();
    accesoRepository = _leerProvider(context, accesoRepositoryProvider);
    solicitudGuardiaRepository =
        _leerProvider(context, solicitudGuardiaRepositoryProvider);
    correoController.addListener(_programarBusquedaCoincidencia);
    rutController.addListener(_programarBusquedaCoincidencia);
    bicicletaDescripcionController.addListener(_actualizarOperacionVisible);
    _cargarBicicleteros();
  }

  @override
  void dispose() {
    temporizadorBusqueda?.cancel();
    correoController.removeListener(_programarBusquedaCoincidencia);
    rutController.removeListener(_programarBusquedaCoincidencia);
    bicicletaDescripcionController.removeListener(_actualizarOperacionVisible);
    nombreController.dispose();
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
    if (actualizandoCampos) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cargarBicicleteros() async {
    setState(() {
      cargandoBicicleteros = true;
      errorBicicleteros = null;
    });

    try {
      final datos = await solicitudGuardiaRepository.listarBicicleteros();
      if (!mounted) {
        return;
      }
      setState(() {
        bicicleteros = datos;
        if (!bicicleteros.any((item) => item.id == bicicleteroSeleccionadoId)) {
          bicicleteroSeleccionadoId = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        bicicleteros = [];
        bicicleteroSeleccionadoId = null;
        errorBicicleteros = 'No se pudieron cargar los bicicleteros.';
      });
    } finally {
      if (mounted) {
        setState(() => cargandoBicicleteros = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolSesion = _rolSesionActual(context);
    final requiereBicicletero =
        rolSesion != RolUsuario.guardia && operacion == 'INGRESO';
    final retiroRegistroParcialBloqueado = _retiroBloqueadoPorRegistroParcial;
    final mostrarOperacion = _debeMostrarOperacion;
    final bicicletaSeleccionada =
        _buscarBicicletaSeleccionada(bicicletaSeleccionadaId);
    final creandoBicicletaNueva = bicicletaSeleccionadaId == null;

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
                  if (requiereBicicletero) ...[
                    _SelectorBicicleteroManual(
                      bicicleteros: bicicleteros,
                      value: bicicleteroSeleccionadoId,
                      cargando: cargandoBicicleteros,
                      error: errorBicicleteros,
                      onChanged: (valor) =>
                          setState(() => bicicleteroSeleccionadoId = valor),
                      onRecargar: _cargarBicicleteros,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                    ),
                    validator: (valor) => _validarCorreoGestionManual(
                      valor,
                      rutController.text,
                      requiereCorreo: _requiereDatosUsuarioNuevo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: rutController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'RUT',
                    ),
                    validator: (valor) => _validarRutGestionManual(
                      valor,
                      requerido: _requiereDatosUsuarioNuevo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nombreController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Se completa si existe coincidencia',
                    ),
                  ),
                  _EstadoBusquedaManual(
                    buscando: buscandoCoincidencia,
                    error: errorBusquedaManual,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Datos de bicicleta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: ColoresUbb.azulNoche,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (bicicletaSeleccionadaId != null)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ChipEstado(
                              texto: 'Bicicleta registrada',
                              color: ColoresUbb.azulApp,
                            ),
                          ),
                        )
                      else if (busquedaRealizada)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ChipEstado(
                              texto: 'Bicicleta no registrada',
                              color: ColoresUbb.azulMedio,
                            ),
                          ),
                        ),
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
                        validator: (valor) => creandoBicicletaNueva
                            ? validarDescripcionBicicleta(valor)
                            : _validarDescripcionBicicletaManual(
                                valor,
                                false,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaMarcaController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                              ),
                              validator: (valor) =>
                                  _validarCampoRequeridoConFormato(
                                valor,
                                requerido: creandoBicicletaNueva,
                                mensajeRequerido: 'Ingresa la marca.',
                                validarFormato: validarMarcaBicicleta,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaModeloController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                              ),
                              validator: (valor) =>
                                  _validarCampoRequeridoConFormato(
                                valor,
                                requerido: creandoBicicletaNueva,
                                mensajeRequerido: 'Ingresa el modelo.',
                                validarFormato: validarModeloBicicleta,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaColorController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                              ),
                              validator: (valor) =>
                                  _validarCampoRequeridoConFormato(
                                valor,
                                requerido: creandoBicicletaNueva,
                                mensajeRequerido: 'Ingresa el color.',
                                validarFormato: validarColorBicicleta,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: bicicletaAroController,
                              readOnly: bicicletaSeleccionadaId != null,
                              decoration: const InputDecoration(
                                labelText: 'Aro',
                              ),
                              validator: (valor) => _validarAroGestionManual(
                                valor,
                                requerido: creandoBicicletaNueva,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bicicletaNumeroSerieController,
                        readOnly: bicicletaSeleccionadaId != null,
                        decoration: const InputDecoration(
                          labelText: 'N° de serie',
                        ),
                        validator: (valor) => _validarCampoRequeridoConFormato(
                          valor,
                          requerido: creandoBicicletaNueva,
                          mensajeRequerido: 'Ingresa el numero de serie.',
                          validarFormato: validarNumeroSerieBicicleta,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SelectorFotoBicicleta(
                        fotoDataUrl: bicicletaSeleccionada?.fotoUrl ??
                            fotoBicicletaManual,
                        onCamara: creandoBicicletaNueva
                            ? () => _seleccionarFotoBicicletaManual(
                                  ImageSource.camera,
                                )
                            : () {},
                        onGaleria: creandoBicicletaNueva
                            ? () => _seleccionarFotoBicicletaManual(
                                  ImageSource.gallery,
                                )
                            : () {},
                        onQuitar: !creandoBicicletaNueva ||
                                fotoBicicletaManual == null
                            ? null
                            : () => setState(
                                  () => fotoBicicletaManual = null,
                                ),
                        mostrarAcciones: creandoBicicletaNueva,
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: registrando ||
                                  buscandoCoincidencia ||
                                  retiroRegistroParcialBloqueado
                              ? null
                              : () => _registrarManual(),
                          icon: registrando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            'Registrar ${operacion == 'INGRESO' ? 'ingreso' : 'retiro'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColoresUbb.rojoInstitucional,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: registrando ||
                                  buscandoCoincidencia ||
                                  retiroRegistroParcialBloqueado
                              ? null
                              : () => _mostrarRechazoManual(context),
                          icon: const Icon(Icons.block_outlined),
                          label: Text(
                            'Rechazar ${operacion == 'INGRESO' ? 'ingreso' : 'retiro'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: registrando ? null : _cancelarAccionManual,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar acción'),
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
      nombreController.clear();
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        fotoBicicletaManual = null;
        errorBusquedaManual = null;
      });
      return;
    }

    if (!_datoBusquedaSuficiente(correo, rut)) {
      nombreController.clear();
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = false;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        fotoBicicletaManual = null;
        errorBusquedaManual = null;
      });
      return;
    }

    setState(() {
      buscandoCoincidencia = true;
      busquedaRealizada = false;
      coincidenciaManual = null;
      bicicletaSeleccionadaId = null;
      fotoBicicletaManual = null;
      errorBusquedaManual = null;
    });
    nombreController.clear();

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
      final coincidencia = await accesoRepository.buscarCoincidenciaManual(
        correo: correo,
        rut: rut,
      );

      if (!mounted ||
          correoController.text.trim() != correo ||
          rutController.text.trim() != rut) {
        return;
      }

      if (coincidencia == null) {
        nombreController.clear();
        setState(() {
          buscandoCoincidencia = false;
          busquedaRealizada = true;
          coincidenciaManual = null;
          bicicletaSeleccionadaId = null;
          fotoBicicletaManual = null;
          bicicletaDescripcionController.clear();
          bicicletaMarcaController.clear();
          bicicletaModeloController.clear();
          bicicletaColorController.clear();
          bicicletaAroController.clear();
          bicicletaNumeroSerieController.clear();
          errorBusquedaManual = null;
        });
        return;
      }

      _aplicarCoincidenciaManual(coincidencia);
    } on ExcepcionApi catch (error) {
      if (!mounted) return;
      nombreController.clear();
      setState(() {
        buscandoCoincidencia = false;
        busquedaRealizada = true;
        coincidenciaManual = null;
        bicicletaSeleccionadaId = null;
        fotoBicicletaManual = null;
        errorBusquedaManual = error.mensaje;
      });
    }
  }

  void _aplicarCoincidenciaManual(
    CoincidenciaManualApp coincidencia,
  ) {
    actualizandoCampos = true;
    nombreController.text = coincidencia.usuario.nombre;
    correoController.text = coincidencia.usuario.correo;
    rutController.text = coincidencia.usuario.rut ?? rutController.text.trim();
    actualizandoCampos = false;

    final preferida = _bicicletaPreferidaAutodetectada(coincidencia.bicicletas);

    setState(() {
      buscandoCoincidencia = false;
      busquedaRealizada = true;
      coincidenciaManual = coincidencia;
      bicicletaSeleccionadaId = preferida?.id;
      fotoBicicletaManual = null;
      errorBusquedaManual = null;

      if (preferida == null) {
        operacion = 'INGRESO';
        bicicletaDescripcionController.clear();
        bicicletaMarcaController.clear();
        bicicletaModeloController.clear();
        bicicletaColorController.clear();
        bicicletaAroController.clear();
        bicicletaNumeroSerieController.clear();
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
        fotoBicicletaManual = null;
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

  Future<void> _seleccionarFotoBicicletaManual(ImageSource source) async {
    try {
      final imagen = await ImagePicker().pickImage(
        source: source,
        imageQuality: 72,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagen == null) {
        return;
      }

      final bytes = await imagen.readAsBytes();
      final mime = _detectarMimeDesdeBytes(bytes);

      if (!_mimesFotoPermitidos.contains(mime)) {
        if (mounted) {
          context.mostrarError('La foto debe ser JPG, PNG o WEBP.');
        }
        return;
      }

      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      if (dataUrl.length > _maxFotoDataUrlLength) {
        if (mounted) {
          context.mostrarError(
            'La foto es muy pesada. Elige una imagen mas liviana.',
          );
        }
        return;
      }

      if (mounted) {
        setState(() => fotoBicicletaManual = dataUrl);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo cargar la foto.');
      }
    }
  }

  void _usarBicicletaNoRegistrada() {
    setState(() {
      operacion = 'INGRESO';
      bicicletaSeleccionadaId = null;
      fotoBicicletaManual = null;
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

  void _mostrarRechazoManual(BuildContext context) {
    if (!_validarFormularioGestionManual()) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SheetDenegacion(
        onConfirmar: (motivo) => _registrarManual(
          denegar: true,
          motivo: motivo,
        ),
      ),
    );
  }

  bool _validarFormularioGestionManual() {
    final crearBicicletaNueva = bicicletaSeleccionadaId == null;
    final requiereBicicletero =
        _rolSesionActual(context) != RolUsuario.guardia &&
            operacion == 'INGRESO';

    if (registrando) {
      return false;
    }
    if (buscandoCoincidencia) {
      context
          .mostrarError('Espera a que termine la busqueda de coincidencias.');
      return false;
    }
    if (formKeyGestionManual.currentState?.validate() != true) {
      return false;
    }
    if (crearBicicletaNueva && fotoBicicletaManual == null) {
      context.mostrarError('Toma o sube una foto de la bicicleta.');
      return false;
    }
    if (requiereBicicletero && bicicleteroSeleccionadoId == null) {
      context.mostrarError('Selecciona el bicicletero del ingreso.');
      return false;
    }

    return true;
  }

  Future<bool> _registrarManual({
    bool denegar = false,
    String? motivo,
  }) async {
    final correo = correoController.text.trim();
    final rut = rutController.text.trim();
    final crearBicicletaNueva = bicicletaSeleccionadaId == null;

    if (!_validarFormularioGestionManual()) {
      return false;
    }

    setState(() => registrando = true);

    try {
      final movimiento = await accesoRepository.registrarManual(
        correo: correo,
        rut: rut,
        bicicletaId: bicicletaSeleccionadaId,
        bicicleteroId:
            operacion == 'INGRESO' ? bicicleteroSeleccionadoId : null,
        tipo: operacion,
        comentario: comentarioController.text.trim(),
        bicicletaDescripcion: bicicletaDescripcionController.text.trim(),
        bicicletaMarca: bicicletaMarcaController.text.trim(),
        bicicletaModelo: bicicletaModeloController.text.trim(),
        bicicletaColor: bicicletaColorController.text.trim(),
        bicicletaAro: bicicletaAroController.text.trim(),
        bicicletaNumeroSerie: bicicletaNumeroSerieController.text.trim(),
        bicicletaFotoUrl: fotoBicicletaManual,
        crearBicicletaNueva: crearBicicletaNueva,
        denegar: denegar,
        motivo: motivo,
      );

      if (mounted) {
        _limpiarFormularioGestionManual();
        final tipoMovimiento =
            movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro';
        context.mostrarExito(
          '$tipoMovimiento ${denegar ? 'rechazado' : 'registrado'} para ${movimiento.usuarioNombre}',
        );
      }
      return true;
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => registrando = false);
      }
    }
  }

  void _cancelarAccionManual() {
    _limpiarFormularioGestionManual();
    context.mostrarInfo('Acción cancelada');
  }

  void _limpiarFormularioGestionManual() {
    temporizadorBusqueda?.cancel();
    actualizandoCampos = true;
    nombreController.clear();
    correoController.clear();
    rutController.clear();
    comentarioController.clear();
    bicicletaDescripcionController.clear();
    bicicletaMarcaController.clear();
    bicicletaModeloController.clear();
    bicicletaColorController.clear();
    bicicletaAroController.clear();
    bicicletaNumeroSerieController.clear();
    actualizandoCampos = false;

    setState(() {
      operacion = 'INGRESO';
      buscandoCoincidencia = false;
      busquedaRealizada = false;
      coincidenciaManual = null;
      bicicletaSeleccionadaId = null;
      bicicleteroSeleccionadoId = null;
      fotoBicicletaManual = null;
      errorBusquedaManual = null;
    });
  }
}

RolUsuario _rolSesionActual(BuildContext context) {
  final sesion = _leerProvider(context, sesionProvider).value;
  return sesion is SesionActiva ? sesion.usuario.rol : RolUsuario.estudiante;
}

String? _validarCorreoGestionManual(
  String? valor,
  String rutActual, {
  bool requiereCorreo = false,
}) {
  final correo = valor?.trim() ?? '';
  final rut = rutActual.trim();

  if (requiereCorreo && correo.isEmpty) {
    return 'Ingresa correo para crear el registro parcial.';
  }
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

String? _validarRutGestionManual(
  String? valor, {
  bool requerido = false,
}) {
  final rut = valor?.trim() ?? '';
  if (requerido && rut.isEmpty) {
    return 'Ingresa RUT para crear el registro parcial.';
  }
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

String? _validarCampoRequeridoConFormato(
  String? valor, {
  required bool requerido,
  required String mensajeRequerido,
  required String? Function(String?) validarFormato,
}) {
  final texto = valor?.trim() ?? '';
  if (requerido && texto.isEmpty) {
    return mensajeRequerido;
  }
  if (!requerido && texto.isEmpty) {
    return null;
  }
  return validarFormato(valor);
}

String? _validarAroGestionManual(
  String? valor, {
  required bool requerido,
}) {
  final texto = valor?.trim() ?? '';
  if (requerido && texto.isEmpty) {
    return 'Ingresa el aro.';
  }
  if (!requerido && texto.isEmpty) {
    return null;
  }
  if (normalizarAroBicicleta(texto) == null) {
    return 'Ingresa un aro valido.';
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

class _SelectorBicicleteroManual extends StatelessWidget {
  const _SelectorBicicleteroManual({
    required this.bicicleteros,
    required this.value,
    required this.cargando,
    required this.error,
    required this.onChanged,
    required this.onRecargar,
  });

  final List<BicicleteroApp> bicicleteros;
  final String? value;
  final bool cargando;
  final String? error;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRecargar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const _CajaBusquedaManual(
        icono: Icons.hourglass_empty_outlined,
        color: ColoresUbb.azulApp,
        children: [
          Text('Cargando bicicleteros disponibles...'),
        ],
      );
    }

    if (error != null) {
      return _CajaBusquedaManual(
        icono: Icons.error_outline,
        color: ColoresUbb.rojoInstitucional,
        children: [
          Text(error!),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRecargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    if (bicicleteros.isEmpty) {
      return const _CajaBusquedaManual(
        icono: Icons.info_outline,
        color: ColoresUbb.azulApp,
        children: [
          Text('No hay bicicleteros activos para registrar el ingreso.'),
        ],
      );
    }

    final valorSeguro =
        bicicleteros.any((bicicletero) => bicicletero.id == value)
            ? value
            : null;

    return DropdownAnclado<String>(
      value: valorSeguro,
      borderRadius: BorderRadius.circular(16),
      menuMaxHeight: 320,
      decoration: const InputDecoration(
        labelText: 'Bicicletero del ingreso',
        prefixIcon: Icon(Icons.local_parking_outlined),
      ),
      items: bicicleteros
          .map(
            (bicicletero) => DropdownMenuItem<String>(
              value: bicicletero.id,
              child: Text(
                '${bicicletero.nombre} | ${bicicletero.cuposDisponibles} cupos',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
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
    final textoOperacion = autodetectada ? '$textoBase detectado' : textoBase;

    return Align(
      alignment: Alignment.centerLeft,
      child: ChipEstado(
        texto: textoOperacion,
        color: color,
      ),
    );
  }
}

class _EstadoBusquedaManual extends StatelessWidget {
  const _EstadoBusquedaManual({
    required this.buscando,
    required this.error,
  });

  final bool buscando;
  final String? error;

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
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          error!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColoresUbb.rojoInstitucional,
                fontWeight: FontWeight.w700,
              ),
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
