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
  late final TextEditingController descripcionController;
  late final TextEditingController marcaController;
  late final TextEditingController modeloController;
  late final TextEditingController colorController;
  late final TextEditingController aroController;
  late final TextEditingController numeroSerieController;
  late String? fotoSeleccionada;
  late bool activar;
  bool guardando = false;

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

      final mime = _normalizarMimeFoto(imagen.mimeType, imagen.name);
      if (!_mimesFotoPermitidos.contains(mime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La foto debe ser JPG, PNG o WEBP.')),
          );
        }
        return;
      }

      final bytes = await imagen.readAsBytes();
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      if (dataUrl.length > _maxFotoDataUrlLength) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('La foto es muy pesada. Elige una imagen más liviana.'),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => fotoSeleccionada = dataUrl);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar la foto.')),
        );
      }
    }
  }

  Future<void> _guardar() async {
    final descripcion = descripcionController.text.trim();
    if (descripcion.isEmpty || guardando) {
      return;
    }

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
        );
        if (activar && !bicicleta.activa) {
          await widget.bicicletaApi.activar(bicicleta.id);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
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
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.pedal_bike),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: marcaController,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: aroController,
                    decoration: const InputDecoration(
                      labelText: 'Aro',
                      prefixIcon: Icon(Icons.circle_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numeroSerieController,
              decoration: const InputDecoration(
                labelText: 'Número de serie',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            _SelectorFotoBicicleta(
              fotoDataUrl: fotoSeleccionada,
              onCamara: () => _seleccionarFoto(ImageSource.camera),
              onGaleria: () => _seleccionarFoto(ImageSource.gallery),
              onQuitar: fotoSeleccionada == null
                  ? null
                  : () => setState(() => fotoSeleccionada = null),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: activar,
              onChanged: guardando
                  ? null
                  : (valor) => setState(() => activar = valor ?? false),
              title: const Text('Usar como bicicleta activa'),
              contentPadding: EdgeInsets.zero,
            ),
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
    );
  }
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
    final bytesFoto = _decodificarFotoDataUrl(foto);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColoresUbb.superficieAzulSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColoresUbb.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bytesFoto != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytesFoto,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamara,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar foto'),
                ),
                OutlinedButton.icon(
                  onPressed: onGaleria,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Subir foto'),
                ),
                if (onQuitar != null)
                  TextButton.icon(
                    onPressed: onQuitar,
                    icon: const Icon(Icons.close),
                    label: const Text('Quitar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
