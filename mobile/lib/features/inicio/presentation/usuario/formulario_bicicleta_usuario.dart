part of '../pantalla_principal.dart';

class _FormularioBicicletaSheet extends StatefulWidget {
  const _FormularioBicicletaSheet({
    required this.bicicleta,
    required this.bicicletaRepository,
  });

  final BicicletaApp? bicicleta;
  final BicicletaRepository bicicletaRepository;

  @override
  State<_FormularioBicicletaSheet> createState() =>
      _FormularioBicicletaSheetState();
}

class _FormularioBicicletaSheetState extends State<_FormularioBicicletaSheet> {
  final formKeyBicicleta = GlobalKey<FormState>();
  late final TextEditingController descripcionController;
  late final TextEditingController marcaController;
  late final TextEditingController modeloController;
  late final TextEditingController numeroSerieController;
  late String colorTexto;
  String? aroSeleccionado;
  late String? fotoSeleccionada;
  late bool activar;
  bool guardando = false;
  bool fotoModificada = false;

  @override
  void initState() {
    super.initState();
    final bicicleta = widget.bicicleta;
    descripcionController =
        TextEditingController(text: bicicleta?.descripcion ?? '');
    marcaController = TextEditingController(text: bicicleta?.marca ?? '');
    modeloController = TextEditingController(text: bicicleta?.modelo ?? '');
    colorTexto =
        normalizarColorBicicleta(bicicleta?.color) ?? bicicleta?.color ?? '';
    aroSeleccionado = normalizarAroBicicleta(bicicleta?.aro);
    numeroSerieController =
        TextEditingController(text: bicicleta?.numeroSerie ?? '');
    fotoSeleccionada = bicicleta?.fotoUrl;
    activar = bicicleta?.activa ?? true;
  }

  @override
  void dispose() {
    descripcionController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    numeroSerieController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
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
              'La foto es muy pesada. Elige una imagen más liviana.');
        }
        return;
      }

      if (mounted) {
        setState(() {
          fotoSeleccionada = dataUrl;
          fotoModificada = true;
        });
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo cargar la foto.');
      }
    }
  }

  Future<void> _guardar() async {
    if (formKeyBicicleta.currentState?.validate() != true || guardando) {
      return;
    }

    if (widget.bicicleta == null &&
        (fotoSeleccionada == null || fotoSeleccionada!.trim().isEmpty)) {
      context.mostrarError('Toma o sube una foto de la bicicleta.');
      return;
    }

    final descripcion = descripcionController.text.trim();
    final color = normalizarColorBicicleta(colorTexto) ?? '';
    final numeroSerie = numeroSerieController.text.trim().toUpperCase();

    setState(() => guardando = true);

    try {
      final bicicleta = widget.bicicleta;
      if (bicicleta == null) {
        await widget.bicicletaRepository.crear(
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: color,
          aro: aroSeleccionado ?? '',
          numeroSerie: numeroSerie,
          fotoUrl: fotoSeleccionada,
          activar: activar,
        );
      } else {
        await widget.bicicletaRepository.actualizar(
          bicicletaId: bicicleta.id,
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: color,
          aro: aroSeleccionado ?? '',
          numeroSerie: numeroSerie,
          fotoUrl: fotoSeleccionada,
          actualizarFoto: fotoModificada,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo guardar. Revisa tu conexión.');
      }
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bicicleta = widget.bicicleta;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKeyBicicleta,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bicicleta == null ? 'Registrar bicicleta' : 'Editar bicicleta',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                ),
                textInputAction: TextInputAction.next,
                validator: validarDescripcionBicicleta,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: validarMarcaBicicleta,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: validarModeloBicicleta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CampoColorBicicleta(
                      valorInicial: colorTexto,
                      habilitado: !guardando,
                      onChanged: (valor) => colorTexto = valor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownAnclado<String>(
                      value: aroSeleccionado ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Aro',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Sin especificar'),
                        ),
                        ...arosBicicleta.map(
                          (aro) => DropdownMenuItem<String>(
                            value: aro,
                            child: Text(aro),
                          ),
                        ),
                      ],
                      onChanged: guardando
                          ? null
                          : (valor) => setState(
                                () => aroSeleccionado =
                                    valor == '' ? null : valor,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: numeroSerieController,
                decoration: const InputDecoration(
                  labelText: 'Número de serie',
                ),
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                validator: validarNumeroSerieBicicleta,
              ),
              const SizedBox(height: 12),
              _SelectorFotoBicicleta(
                fotoDataUrl: fotoSeleccionada,
                onCamara: () => _seleccionarFoto(ImageSource.camera),
                onGaleria: () => _seleccionarFoto(ImageSource.gallery),
                onQuitar: fotoSeleccionada == null
                    ? null
                    : () => setState(() {
                          fotoSeleccionada = null;
                          fotoModificada = true;
                        }),
              ),
              if (bicicleta == null) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: activar,
                  onChanged: guardando
                      ? null
                      : (valor) => setState(() => activar = valor ?? false),
                  title: const Text('Usar como bicicleta activa'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: guardando ? null : _guardar,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(guardando ? 'Guardando' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampoColorBicicleta extends StatelessWidget {
  const _CampoColorBicicleta({
    required this.valorInicial,
    required this.habilitado,
    required this.onChanged,
  });

  final String valorInicial;
  final bool habilitado;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: valorInicial),
      displayStringForOption: (opcion) => opcion,
      optionsBuilder: (texto) => sugerirColoresBicicleta(texto.text),
      onSelected: onChanged,
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: habilitado,
          decoration: const InputDecoration(
            labelText: 'Color',
          ),
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          validator: validarColorBicicleta,
        );
      },
    );
  }
}

class _SelectorFotoBicicleta extends StatelessWidget {
  const _SelectorFotoBicicleta({
    required this.fotoDataUrl,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
    this.mostrarAcciones = true,
  });

  final String? fotoDataUrl;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback? onQuitar;
  final bool mostrarAcciones;

  @override
  Widget build(BuildContext context) {
    final foto = fotoDataUrl;
    final bytesFoto = decodificarFotoDataUrl(foto);
    final hayFoto = bytesFoto != null || (foto != null && foto.isNotEmpty);

    Widget areaImagen;
    if (bytesFoto != null) {
      areaImagen = Image.memory(
        bytesFoto,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (foto != null && foto.isNotEmpty) {
      areaImagen = Image.network(
        resolverUrlFotoBicicleta(foto),
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _placeholderImagen('No se pudo cargar la imagen'),
      );
    } else {
      areaImagen = _placeholderImagen('Sin imagen');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Imagen bicicleta',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ColoresUbb.azulApp,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: ColoresUbb.superficieAzulSuave,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: hayFoto && foto != null && foto.isNotEmpty
                ? () => _mostrarImagenAmpliada(context, foto)
                : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColoresUbb.borde),
              ),
              child: Stack(
                children: [
                  areaImagen,
                  if (hayFoto && foto != null && foto.isNotEmpty)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Tooltip(
                        message: 'Ampliar imagen',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.56),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.open_in_full,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  if (hayFoto && mostrarAcciones)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onQuitar,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (mostrarAcciones) const SizedBox(height: 6),
        if (hayFoto && mostrarAcciones)
          Text(
            'Toca la ✕ para quitar la imagen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          ),
        if (mostrarAcciones) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamara,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGaleria,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Subir foto'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _placeholderImagen(String texto) {
    return Container(
      height: 170,
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined,
              size: 42, color: ColoresUbb.textoSecundario),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(color: ColoresUbb.textoSecundario),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarImagenAmpliada(
    BuildContext context,
    String fotoReferencia,
  ) async {
    final bytesFoto = decodificarFotoDataUrl(fotoReferencia);
    final imagen = bytesFoto != null
        ? Image.memory(bytesFoto, fit: BoxFit.contain)
        : Image.network(
            resolverUrlFotoBicicleta(fotoReferencia),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholderImagen(
              'No se pudo cargar la imagen',
            ),
          );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  maxWidth: MediaQuery.sizeOf(context).width * 0.94,
                ),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(child: imagen),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
