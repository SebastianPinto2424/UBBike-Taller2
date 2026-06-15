part of '../pantalla_principal.dart';

class VistaEscanerQrGuardia extends StatefulWidget {
  const VistaEscanerQrGuardia({super.key});

  @override
  State<VistaEscanerQrGuardia> createState() => _VistaEscanerQrGuardiaState();
}

class _VistaEscanerQrGuardiaState extends State<VistaEscanerQrGuardia> {
  final formKeyQrValidado = GlobalKey<FormState>();
  late final AccesoRepository accesoRepository;
  final comentarioController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  String? codigoDetectado;
  QrValidadoApp? qrLeido;
  bool cargando = false;
  bool escaneando = false;

  @override
  void initState() {
    super.initState();
    accesoRepository = _leerProvider(context, accesoRepositoryProvider);
  }

  @override
  void dispose() {
    comentarioController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDeteccion(BarcodeCapture captura) {
    if (cargando || !escaneando || codigoDetectado != null) return;
    final codigo = captura.barcodes.firstOrNull?.rawValue;
    if (codigo == null || codigo.isEmpty) return;
    _scannerController.stop();
    setState(() {
      codigoDetectado = codigo;
      escaneando = false;
    });
    unawaited(_validarQr(codigo));
  }

  void _toggleEscanear() {
    if (escaneando) {
      setState(() => escaneando = false);
      _scannerController.stop();
      return;
    }

    setState(() {
      codigoDetectado = null;
      qrLeido = null;
      comentarioController.clear();
      escaneando = true;
    });
    _scannerController.start();
  }

  void _limpiarLectura() {
    _scannerController.stop();
    setState(() {
      codigoDetectado = null;
      qrLeido = null;
      escaneando = false;
      comentarioController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qr = qrLeido;
    if (qr != null) {
      return ListView(
        children: [
          const SizedBox(height: 8),
          _FormularioQrValidado(
            formKey: formKeyQrValidado,
            qr: qr,
            comentarioController: comentarioController,
            onConfirmar: () => _confirmarQr(qr),
            onDenegar: () => _mostrarDenegacion(context, qr),
            onLeerOtro: _limpiarLectura,
          ),
        ],
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 396,
          width: double.infinity,
          child: Card(
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _ContenidoPanelEscaneoGuardia(
                escaneando: escaneando,
                cargando: cargando,
                codigoDetectado: codigoDetectado != null &&
                    codigoDetectado!.trim().isNotEmpty,
                qrValidado: false,
                controller: _scannerController,
                onDetect: _onDeteccion,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: ColoresUbb.azulApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: cargando ? null : _toggleEscanear,
          child: Text(
            escaneando ? 'Detener escaneo' : 'Escanear QR',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _validarQr([String? codigo]) async {
    final token = (codigo ?? codigoDetectado)?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => cargando = true);

    try {
      final qr = await accesoRepository.validarQr(token);
      if (mounted) {
        setState(() {
          qrLeido = qr;
          comentarioController.clear();
        });
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() {
          qrLeido = null;
          codigoDetectado = null;
        });
        context.mostrarError(error.mensaje);
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  Future<void> _confirmarQr(QrValidadoApp qr) async {
    if (formKeyQrValidado.currentState?.validate() != true) {
      return;
    }

    try {
      final movimiento = await accesoRepository.confirmarQr(
        qr.token,
        comentario: comentarioController.text.trim(),
      );
      if (mounted) {
        _limpiarLectura();
        context.mostrarExito(
          '${movimiento.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro'} confirmado',
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    }
  }

  void _mostrarDenegacion(BuildContext context, QrValidadoApp qr) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SheetDenegacion(
        onConfirmar: (motivo) => _confirmarDenegacion(qr, motivo),
      ),
    );
  }

  Future<bool> _confirmarDenegacion(QrValidadoApp qr, String motivo) async {
    try {
      await accesoRepository.denegarQr(token: qr.token, motivo: motivo);
      if (mounted) {
        _limpiarLectura();
        if (context.mounted) {
          context.mostrarInfo('Operación denegada');
        }
      }
      return true;
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
      return false;
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo conectar con el backend');
      }
      return false;
    }
  }
}

class _SheetDenegacion extends StatefulWidget {
  const _SheetDenegacion({required this.onConfirmar});

  final Future<bool> Function(String motivo) onConfirmar;

  @override
  State<_SheetDenegacion> createState() => _SheetDenegacionState();
}

class _SheetDenegacionState extends State<_SheetDenegacion> {
  final formKeyDenegacion = GlobalKey<FormState>();
  final motivoController = TextEditingController();
  bool enviando = false;

  @override
  void dispose() {
    motivoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (formKeyDenegacion.currentState?.validate() != true || enviando) {
      return;
    }
    setState(() => enviando = true);
    final ok = await widget.onConfirmar(motivoController.text.trim());
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKeyDenegacion,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Motivo de denegación',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Indica el motivo',
                  alignLabelWithHint: true,
                ),
                validator: _validarMotivoDenegacionQrGuardia,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: enviando ? null : _enviar,
                icon: enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Registrar denegación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _validarComentarioQrGuardia(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.length > 600) {
    return 'Maximo 600 caracteres.';
  }
  return null;
}

String? _validarMotivoDenegacionQrGuardia(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'Ingresa el motivo.';
  }
  if (texto.length < 3) {
    return 'Debe tener al menos 3 caracteres.';
  }
  if (texto.length > 600) {
    return 'Maximo 600 caracteres.';
  }
  return null;
}

class _FormularioQrValidado extends StatelessWidget {
  const _FormularioQrValidado({
    required this.formKey,
    required this.qr,
    required this.comentarioController,
    required this.onConfirmar,
    required this.onDenegar,
    required this.onLeerOtro,
  });

  final GlobalKey<FormState> formKey;
  final QrValidadoApp qr;
  final TextEditingController comentarioController;
  final VoidCallback onConfirmar;
  final VoidCallback onDenegar;
  final VoidCallback onLeerOtro;

  @override
  Widget build(BuildContext context) {
    final esIngreso = qr.tipo == 'INGRESO';
    final color = esIngreso ? ColoresUbb.exito : ColoresUbb.azulApp;
    final accion = esIngreso ? 'Ingreso' : 'Retiro';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      esIngreso ? Icons.login : Icons.logout,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR válido',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        Text(
                          'Autorizar $accion',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: ColoresUbb.azulNoche,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  ChipEstado(texto: accion, color: color),
                ],
              ),
              const SizedBox(height: 14),
              const _TituloFormularioQr(
                icono: Icons.person_outline,
                texto: 'Información del usuario',
              ),
              const SizedBox(height: 10),
              _CampoLecturaQr(
                label: 'Nombre',
                valor: qr.usuarioNombre,
              ),
              const SizedBox(height: 10),
              _CampoLecturaQr(
                label: 'Correo',
                valor: qr.usuarioCorreo,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'RUT',
                      valor: qr.usuarioRut ?? 'Sin RUT',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'Bicicletero',
                      valor: qr.bicicleteroNombre ?? 'Asignación guardia',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _TituloFormularioQr(
                icono: Icons.pedal_bike_outlined,
                texto: 'Datos de bicicleta',
              ),
              const SizedBox(height: 10),
              _CampoLecturaQr(
                label: 'Descripción',
                valor: qr.bicicletaDescripcion,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'Marca',
                      valor: _textoNoVacio(qr.bicicletaMarca, 'Sin marca'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'Modelo',
                      valor: _textoNoVacio(qr.bicicletaModelo, 'Sin modelo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'Color',
                      valor: _textoNoVacio(qr.bicicletaColor, 'Sin color'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoLecturaQr(
                      label: 'Aro',
                      valor: _textoNoVacio(qr.bicicletaAro, 'Sin aro'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _CampoLecturaQr(
                label: 'Número de serie',
                valor: _textoNoVacio(qr.bicicletaNumeroSerie, 'Sin serie'),
              ),
              const SizedBox(height: 12),
              _SelectorFotoBicicleta(
                fotoDataUrl: qr.bicicletaFotoUrl,
                onCamara: () {},
                onGaleria: () {},
                onQuitar: null,
                mostrarAcciones: false,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: comentarioController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentario opcional del guardia',
                  hintText: 'Ej: Usuario posee U-Lock',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
                validator: _validarComentarioQrGuardia,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirmar,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Confirmar ${accion.toLowerCase()}',
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
                      onPressed: onDenegar,
                      icon: const Icon(Icons.block_outlined),
                      label: Text(
                        'Denegar ${accion.toLowerCase()}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: onLeerOtro,
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: const Text('Escanear nuevamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _textoNoVacio(String? valor, String respaldo) {
    final texto = valor?.trim();
    return texto == null || texto.isEmpty ? respaldo : texto;
  }
}

class _TituloFormularioQr extends StatelessWidget {
  const _TituloFormularioQr({
    required this.icono,
    required this.texto,
  });

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: ColoresUbb.azulApp, size: 18),
        const SizedBox(width: 8),
        Text(
          texto,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: ColoresUbb.azulNoche,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _CampoLecturaQr extends StatelessWidget {
  const _CampoLecturaQr({
    required this.label,
    required this.valor,
  });

  final String label;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$valor'),
      initialValue: valor,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
    );
  }
}

class _ContenidoPanelEscaneoGuardia extends StatelessWidget {
  const _ContenidoPanelEscaneoGuardia({
    required this.escaneando,
    required this.cargando,
    required this.codigoDetectado,
    required this.qrValidado,
    required this.controller,
    required this.onDetect,
  });

  final bool escaneando;
  final bool cargando;
  final bool codigoDetectado;
  final bool qrValidado;
  final MobileScannerController controller;
  final void Function(BarcodeCapture captura) onDetect;

  @override
  Widget build(BuildContext context) {
    if (escaneando) {
      return ClipRRect(
        key: const ValueKey('camara-activa'),
        borderRadius: BorderRadius.circular(18),
        child: MobileScanner(
          controller: controller,
          onDetect: onDetect,
        ),
      );
    }

    final IconData icono;
    final Color color;
    final String titulo;
    final String detalle;

    if (cargando) {
      icono = Icons.hourglass_empty_outlined;
      color = ColoresUbb.azulApp;
      titulo = 'Validando QR';
      detalle = 'Estamos revisando el movimiento detectado.';
    } else if (qrValidado) {
      icono = Icons.verified_outlined;
      color = ColoresUbb.exito;
      titulo = 'QR validado';
      detalle = 'Revisa los datos y confirma o deniega el movimiento.';
    } else if (codigoDetectado) {
      icono = Icons.qr_code_scanner;
      color = ColoresUbb.exito;
      titulo = 'QR detectado';
      detalle = 'Abriendo el formulario de validacion.';
    } else {
      icono = Icons.qr_code_2;
      color = ColoresUbb.azulApp;
      titulo = 'QR no escaneado';
      detalle = 'Presiona Escanear QR y apunta al codigo del usuario.';
    }

    return Center(
      key: ValueKey(titulo),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: cargando
                ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Icon(
                    icono,
                    color: color,
                    size: 42,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          ),
        ],
      ),
    );
  }
}
