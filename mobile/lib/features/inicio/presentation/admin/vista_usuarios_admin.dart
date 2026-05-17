part of '../pantalla_principal.dart';

class VistaUsuariosAdmin extends StatefulWidget {
  const VistaUsuariosAdmin({super.key});

  @override
  State<VistaUsuariosAdmin> createState() => _VistaUsuariosAdminState();
}

class _VistaUsuariosAdminState extends State<VistaUsuariosAdmin> {
  final usuariosApi = UsuariosApi();
  late Future<List<UsuarioApp>> futuroUsuarios;

  @override
  void initState() {
    super.initState();
    futuroUsuarios = usuariosApi.listarUsuarios();
  }

  void _recargar() {
    setState(() {
      futuroUsuarios = usuariosApi.listarUsuarios();
    });
  }

  Future<void> _actualizar(
    UsuarioApp usuario, {
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) async {
    try {
      await usuariosApi.actualizarPermisos(
        usuarioId: usuario.id,
        nombre: nombre,
        correo: correo,
        rut: rut,
        rol: rol,
        cuentaActiva: cuentaActiva,
        correoVerificado: correoVerificado,
      );
      _recargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado')),
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.mensaje)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Usuarios',
          detalle: 'Administra datos, roles y estado de las cuentas.',
          icono: Icons.manage_accounts_outlined,
        ),
        const SizedBox(height: 16),
        _TituloApartado(titulo: 'Cuentas registradas', onRefresh: _recargar),
        const SizedBox(height: 10),
        FutureBuilder<List<UsuarioApp>>(
          future: futuroUsuarios,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return TarjetaAccion(
                icono: Icons.cloud_off_outlined,
                titulo: 'No se pudieron cargar usuarios',
                detalle: 'Toca para reintentar.',
                color: ColoresUbb.rojoInstitucional,
                onTap: _recargar,
              );
            }

            final usuarios = snapshot.data ?? [];
            if (usuarios.isEmpty) {
              return const _EstadoLista(
                icono: Icons.group_off_outlined,
                titulo: 'Sin usuarios',
                detalle: 'Los registros aparecerán aquí.',
              );
            }

            return Column(
              children: usuarios
                  .map(
                    (usuario) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TarjetaUsuarioAdmin(
                        usuario: usuario,
                        onActualizar: _actualizar,
                        onEditarDatos: _editarDatos,
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

  Future<void> _editarDatos(UsuarioApp usuario) async {
    final nombreController = TextEditingController(text: usuario.nombre);
    final correoController = TextEditingController(text: usuario.correo);
    final rutController = TextEditingController(text: usuario.rut ?? '');

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: correoController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rutController,
                decoration: const InputDecoration(labelText: 'RUT'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true) {
      await _actualizar(
        usuario,
        nombre: nombreController.text.trim(),
        correo: correoController.text.trim(),
        rut: rutController.text.trim(),
      );
    }

    nombreController.dispose();
    correoController.dispose();
    rutController.dispose();
  }
}

class _TarjetaUsuarioAdmin extends StatelessWidget {
  const _TarjetaUsuarioAdmin({
    required this.usuario,
    required this.onActualizar,
    required this.onEditarDatos,
  });

  final UsuarioApp usuario;
  final Future<void> Function(
    UsuarioApp usuario, {
    String? nombre,
    String? correo,
    String? rut,
    RolUsuario? rol,
    bool? cuentaActiva,
    bool? correoVerificado,
  }) onActualizar;
  final Future<void> Function(UsuarioApp usuario) onEditarDatos;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: ColoresUbb.azulApp,
                  foregroundColor: Colors.white,
                  child: Text(_inicialSegura(usuario.nombre)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        usuario.correo,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColoresUbb.textoSecundario,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<RolUsuario>(
                  tooltip: 'Cambiar rol',
                  onSelected: (rol) => onActualizar(usuario, rol: rol),
                  itemBuilder: (context) => RolUsuario.values
                      .map(
                        (rol) => PopupMenuItem(
                          value: rol,
                          child: Text(rol.etiqueta),
                        ),
                      )
                      .toList(),
                  icon: const Icon(Icons.manage_accounts_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChipEstado(
                    texto: usuario.rol.etiqueta, color: ColoresUbb.azulApp),
                ChipEstado(
                  texto: usuario.cuentaActiva ? 'Activo' : 'Acceso denegado',
                  color: usuario.cuentaActiva
                      ? ColoresUbb.exito
                      : ColoresUbb.rojoInstitucional,
                ),
                ChipEstado(
                  texto: usuario.correoVerificado
                      ? 'Correo verificado'
                      : 'Correo pendiente',
                  color: usuario.correoVerificado
                      ? ColoresUbb.exito
                      : ColoresUbb.amarilloInstitucional,
                ),
                if (usuario.rut != null && usuario.rut!.isNotEmpty)
                  ChipEstado(texto: usuario.rut!, color: ColoresUbb.azulMedio),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onActualizar(
                    usuario,
                    cuentaActiva: !usuario.cuentaActiva,
                  ),
                  icon: Icon(
                    usuario.cuentaActiva
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(usuario.cuentaActiva ? 'Denegar' : 'Habilitar'),
                ),
                OutlinedButton.icon(
                  onPressed: usuario.correoVerificado
                      ? null
                      : () => onActualizar(usuario, correoVerificado: true),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Verificar correo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onEditarDatos(usuario),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar datos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
