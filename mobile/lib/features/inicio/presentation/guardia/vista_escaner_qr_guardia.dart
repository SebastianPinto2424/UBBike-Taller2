part of '../pantalla_principal.dart';

class VistaEscanerQrGuardia extends StatefulWidget {
  const VistaEscanerQrGuardia({super.key});

  @override
  State<VistaEscanerQrGuardia> createState() => _VistaEscanerQrGuardiaState();
}

class _VistaEscanerQrGuardiaState extends State<VistaEscanerQrGuardia> {
  final formKeyQrValidado = GlobalKey<FormState>();
  final accesoApi = AccesoApi();
  final comentarioController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  String? codigoDetectado;
  QrValidadoApp? qrLeido;
  bool cargando = false;
  bool escaneando = false;

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
    final hayCodigoDetectado =
        codigoDetectado != null && codigoDetectado!.trim().isNotEmpty;

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
                codigoDetectado: hayCodigoDetectado,
                qrValidado: qr != null,
                controller: _scannerController,
                onDetect: _onDeteccion,
              ),
            ),
          ),
        ),
        if (qr == null) ...[
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
          if (hayCodigoDetectado) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: cargando ? null : _validarQr,
              icon: cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(cargando ? 'Validando...' : 'Validar QR'),
            ),
          ],
        ],
        if (qr != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: formKeyQrValidado,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ChipEstado(
                        texto: 'QR válido', color: ColoresUbb.exito),
                    const SizedBox(height: 12),
                    _ResumenUsuarioQrGuardia(qr: qr),
                    const SizedBox(height: 12),
                    const SizedBox(height: 14),
                    _FichaVerificacionBicicleta(qr: qr),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: comentarioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Comentario opcional del guardia',
                        hintText: 'Ej: Usuario posee U-Lock',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.sticky_note_2_outlined),
                      ),
                      validator: _validarComentarioQrGuardia,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _confirmarQr(qr),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        qr.tipo == 'INGRESO'
                            ? 'Confirmar ingreso'
                            : 'Confirmar retiro',
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _mostrarDenegacion(context, qr),
                      icon: const Icon(Icons.block_outlined),
                      label: Text(
                        qr.tipo == 'INGRESO'
                            ? 'Denegar ingreso'
                            : 'Denegar retiro',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          qrLeido = null;
                          codigoDetectado = null;
                          comentarioController.clear();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Leer otro QR'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _validarQr() async {
    final token = codigoDetectado?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => cargando = true);

    try {
      final qr = await accesoApi.validarQr(token);
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
      final movimiento = await accesoApi.confirmarQr(
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
      await accesoApi.denegarQr(token: qr.token, motivo: motivo);
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

class _ResumenUsuarioQrGuardia extends StatelessWidget {
  const _ResumenUsuarioQrGuardia({required this.qr});

  final QrValidadoApp qr;

  @override
  Widget build(BuildContext context) {
    final operacion = qr.tipo == 'INGRESO' ? 'Ingreso' : 'Retiro';
    final colorOperacion =
        qr.tipo == 'INGRESO' ? ColoresUbb.exito : ColoresUbb.azulApp;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: ColoresUbb.azulApp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del usuario',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ColoresUbb.azulApp,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      qr.usuarioNombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ColoresUbb.azulNoche,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      qr.usuarioCorreo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColoresUbb.textoSecundario,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ChipEstado(texto: operacion, color: colorOperacion),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DatoResumenQr(
                etiqueta: 'RUT',
                valor: qr.usuarioRut ?? 'Sin RUT',
              ),
              _DatoResumenQr(
                etiqueta: 'Bicicletero',
                valor: qr.bicicleteroNombre ?? 'Asignacion del guardia',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoResumenQr extends StatelessWidget {
  const _DatoResumenQr({
    required this.etiqueta,
    required this.valor,
  });

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 136),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ColoresUbb.borde),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: ColoresUbb.textoSecundario,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                valor,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColoresUbb.azulNoche,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
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
      detalle = 'Estamos revisando el codigo detectado.';
    } else if (qrValidado) {
      icono = Icons.verified_outlined;
      color = ColoresUbb.exito;
      titulo = 'QR validado';
      detalle = 'Revisa los datos y confirma o deniega el movimiento.';
    } else if (codigoDetectado) {
      icono = Icons.qr_code_scanner;
      color = ColoresUbb.exito;
      titulo = 'QR detectado';
      detalle = 'Presiona Validar QR para revisar el movimiento.';
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

class _FichaVerificacionBicicleta extends StatelessWidget {
  const _FichaVerificacionBicicleta({required this.qr});

  final QrValidadoApp qr;

  @override
  Widget build(BuildContext context) {
    final foto = qr.bicicletaFotoUrl;
    final bytesFoto = decodificarFotoDataUrl(foto);
    final imagenMovil = _ImagenBicicletaQr(
      foto: foto,
      bytesFoto: bytesFoto,
      height: 190,
    );
    final imagenAncha = _ImagenBicicletaQr(
      foto: foto,
      bytesFoto: bytesFoto,
      height: 170,
    );
    final detalles = <Widget>[
      if (qr.bicicletaMarca?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaMarca!, color: ColoresUbb.azulApp),
      if (qr.bicicletaModelo?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaModelo!, color: ColoresUbb.azulMedio),
      if (qr.bicicletaColor?.isNotEmpty == true)
        ChipEstado(texto: qr.bicicletaColor!, color: ColoresUbb.turquesa),
      if (qr.bicicletaAro?.isNotEmpty == true)
        ChipEstado(texto: 'Aro ${qr.bicicletaAro}', color: ColoresUbb.exito),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verificacion de bicicleta',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final contenido = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qr.bicicletaDescripcion,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (detalles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: detalles),
                  ],
                  if (qr.bicicletaNumeroSerie?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    FilaDato(
                      etiqueta: 'Serie',
                      valor: qr.bicicletaNumeroSerie!,
                    ),
                  ],
                ],
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    imagenMovil,
                    const SizedBox(height: 12),
                    contenido,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 220, child: imagenAncha),
                  const SizedBox(width: 14),
                  Expanded(child: contenido),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ImagenBicicletaQr extends StatelessWidget {
  const _ImagenBicicletaQr({
    required this.foto,
    required this.bytesFoto,
    required this.height,
  });

  final String? foto;
  final Uint8List? bytesFoto;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fotoUrl = foto?.trim();
    final puedeUsarUrl = fotoUrl != null &&
        fotoUrl.isNotEmpty &&
        !fotoUrl.startsWith('data:image');
    final tieneImagen = bytesFoto != null || puedeUsarUrl;

    final Widget imagen;
    if (bytesFoto != null) {
      imagen = Image.memory(bytesFoto!, fit: BoxFit.cover);
    } else if (puedeUsarUrl) {
      imagen = Image.network(
        resolverUrlFotoBicicleta(fotoUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PlaceholderImagenBicicleta(),
      );
    } else {
      imagen = const _PlaceholderImagenBicicleta();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imagen,
            if (tieneImagen)
              Positioned(
                right: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      'Imagen app',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImagenBicicleta extends StatelessWidget {
  const _PlaceholderImagenBicicleta();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pedal_bike_outlined,
              color: ColoresUbb.azulApp,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Sin imagen registrada',
              style: TextStyle(
                color: ColoresUbb.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
