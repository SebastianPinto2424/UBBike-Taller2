part of '../pantalla_principal.dart';

class _FormularioBicicletaSheet extends StatefulWidget {
  const _FormularioBicicletaSheet({
    required this.bicicleta,
    required this.bicicletaApi,
  });

  final BicicletaApp? bicicleta;
  final BicicletaApi bicicletaApi;

  @override
  State<_FormularioBicicletaSheet> createState() =>
      _FormularioBicicletaSheetState();
}

class _FormularioBicicletaSheetState extends State<_FormularioBicicletaSheet> {
  final formKeyBicicleta = GlobalKey<FormState>();
  late final TextEditingController descripcionController;
  late final TextEditingController marcaController;
  late final TextEditingController modeloController;
  late final TextEditingController colorController;
  late final TextEditingController aroController;
  late final TextEditingController numeroSerieController;
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
    colorController = TextEditingController(text: bicicleta?.color ?? '');
    aroController = TextEditingController(text: bicicleta?.aro ?? '');
    numeroSerieController =
        TextEditingController(text: bicicleta?.numeroSerie ?? '');
    fotoSeleccionada = bicicleta?.fotoUrl;
    activar = bicicleta?.activa ?? false;
  }

  @override
  void dispose() {
    descripcionController.dispose();
    marcaController.dispose();
    modeloController.dispose();
    colorController.dispose();
    aroController.dispose();
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

    final descripcion = descripcionController.text.trim();

    setState(() => guardando = true);

    try {
      final bicicleta = widget.bicicleta;
      if (bicicleta == null) {
        await widget.bicicletaApi.crear(
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: colorController.text.trim(),
          aro: aroController.text.trim(),
          numeroSerie: numeroSerieController.text.trim(),
          fotoUrl: fotoSeleccionada,
          activar: activar,
        );
      } else {
        await widget.bicicletaApi.actualizar(
          bicicletaId: bicicleta.id,
          descripcion: descripcion,
          marca: marcaController.text.trim(),
          modelo: modeloController.text.trim(),
          color: colorController.text.trim(),
          aro: aroController.text.trim(),
          numeroSerie: numeroSerieController.text.trim(),
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
                validator: _validarDescripcionBicicleta,
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
                      validator: (valor) =>
                          _validarCampoOpcionalBicicleta(valor, 80),
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
                      validator: (valor) =>
                          _validarCampoOpcionalBicicleta(valor, 80),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (valor) =>
                          _validarCampoOpcionalBicicleta(valor, 60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: aroController,
                      decoration: const InputDecoration(
                        labelText: 'Aro',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (valor) =>
                          _validarCampoOpcionalBicicleta(valor, 30),
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
                validator: (valor) =>
                    _validarCampoOpcionalBicicleta(valor, 120),
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

String? _validarDescripcionBicicleta(String? valor) {
  final texto = valor?.trim() ?? '';
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

String? _validarCampoOpcionalBicicleta(String? valor, int maximo) {
  final texto = valor?.trim() ?? '';
  if (texto.length > maximo) {
    return 'Maximo $maximo caracteres.';
  }
  return null;
}

class _SelectorFotoBicicleta extends StatelessWidget {
  const _SelectorFotoBicicleta({
    required this.fotoDataUrl,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
  });

  final String? fotoDataUrl;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback? onQuitar;

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
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColoresUbb.superficieAzulSuave,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresUbb.borde),
          ),
          child: Stack(
            children: [
              areaImagen,
              if (hayFoto)
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
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (hayFoto)
          Text(
            'Toca la ✕ para quitar la imagen.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColoresUbb.textoSecundario,
                ),
          ),
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
}
