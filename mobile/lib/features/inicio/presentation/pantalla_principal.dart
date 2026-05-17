import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/presentation/pantalla_login.dart';
import '../../../features/bicicletas/data/bicicleta_api.dart';
import '../../../features/bicicleteros/data/bicicletero_api.dart';
import '../../../features/usuarios/data/usuarios_api.dart';
import '../../../shared/modelos/bicicleta_app.dart';
import '../../../shared/modelos/bicicletero_app.dart';
import '../../../shared/modelos/usuario_app.dart';
import '../../../shared/modelos/rol_usuario.dart';
import '../../../shared/servicios/sesion_actual.dart';
import '../../../shared/widgets/chip_estado.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import '../../../shared/widgets/tarjeta_accion.dart';

part 'usuario/vista_inicio_usuario.dart';
part 'usuario/vista_bicicletas_usuario.dart';
part 'usuario/formulario_bicicleta_usuario.dart';
part 'admin/vista_usuarios_admin.dart';
part 'widgets/bicicletas_widgets.dart';
part 'widgets/estado_widgets.dart';
part 'widgets/bicicletero_widgets.dart';
part 'widgets/encabezado_widgets.dart';

const int _maxFotoDataUrlLength = 1400000;
const Set<String> _mimesFotoPermitidos = {
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
};

String _normalizarMimeFoto(String? mime, String nombreArchivo) {
  final normalizado = mime?.toLowerCase().trim();
  if (_mimesFotoPermitidos.contains(normalizado)) {
    return normalizado!;
  }

  final nombre = nombreArchivo.toLowerCase();
  if (nombre.endsWith('.jpg') || nombre.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (nombre.endsWith('.png')) {
    return 'image/png';
  }
  if (nombre.endsWith('.webp')) {
    return 'image/webp';
  }

  return normalizado ?? 'image/jpeg';
}

Uint8List? _decodificarFotoDataUrl(String? fotoDataUrl) {
  if (fotoDataUrl == null || !fotoDataUrl.startsWith('data:image')) {
    return null;
  }

  final partes = fotoDataUrl.split(',');
  if (partes.length < 2) {
    return null;
  }

  try {
    return base64Decode(partes.last);
  } on FormatException {
    return null;
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, required this.rol});

  final RolUsuario rol;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int indice = 0;

  @override
  Widget build(BuildContext context) {
    final esAdministrador = widget.rol == RolUsuario.administrador;
    final paginas = [
      const VistaInicioUsuario(),
      const VistaBicicletas(),
      if (esAdministrador) const VistaUsuariosAdmin(),
      VistaPerfil(rol: widget.rol),
    ];
    final destinos = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Inicio',
      ),
      const NavigationDestination(
        icon: Icon(Icons.pedal_bike),
        label: 'Bicicletas',
      ),
      if (esAdministrador)
        const NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          label: 'Usuarios',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Perfil',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const MarcaUbbike(compacta: true, sobreAzul: true),
      ),
      body: ContenedorResponsivo(
        anchoMaximo: 940,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: paginas[indice],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (nuevoIndice) =>
            setState(() => indice = nuevoIndice),
        destinations: destinos,
      ),
    );
  }
}

class VistaPerfil extends StatelessWidget {
  const VistaPerfil({super.key, required this.rol});

  final RolUsuario rol;

  @override
  Widget build(BuildContext context) {
    final usuario = SesionActual.usuario;
    final nombre = _textoNoVacio(usuario?.nombre, 'Usuario UBB');
    final correo = _textoNoVacio(usuario?.correo, 'Correo no informado');
    final rut = _textoNoVacio(usuario?.rut, 'RUT no informado');

    return ListView(
      children: [
        const _EncabezadoSeccion(
          titulo: 'Perfil',
          detalle: 'Datos de la sesión actual y rol asignado en el sistema.',
          icono: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: ColoresUbb.azulApp,
                      foregroundColor: Colors.white,
                      child: Text(_inicialSegura(nombre)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            correo,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: ColoresUbb.textoSecundario,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    ChipEstado(
                        texto: _etiquetaRol(rol), color: ColoresUbb.azulApp),
                  ],
                ),
                const SizedBox(height: 18),
                _FilaPerfil(
                  icono: Icons.badge_outlined,
                  etiqueta: 'RUT',
                  valor: rut,
                ),
                const SizedBox(height: 10),
                _FilaPerfil(
                  icono: Icons.verified_user_outlined,
                  etiqueta: 'Rol',
                  valor: _etiquetaRol(rol),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            SesionActual.cerrar();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const PantallaLogin()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

class _FilaPerfil extends StatelessWidget {
  const _FilaPerfil({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: ColoresUbb.azulApp),
        const SizedBox(width: 10),
        Text(
          '$etiqueta:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ColoresUbb.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

String _saludoActual() {
  final hora = DateTime.now().hour;
  if (hora < 12) {
    return 'Buenos días';
  }
  if (hora < 20) {
    return 'Buenas tardes';
  }
  return 'Buenas noches';
}

String _nombreSesion(String respaldo) {
  return _textoNoVacio(SesionActual.usuario?.nombre, respaldo);
}

String _textoNoVacio(String? valor, String respaldo) {
  final texto = valor?.trim();
  if (texto == null || texto.isEmpty) {
    return respaldo;
  }
  return texto;
}

String _inicialSegura(String valor) {
  final texto = valor.trim();
  if (texto.isEmpty) {
    return '?';
  }
  return String.fromCharCode(texto.runes.first).toUpperCase();
}

String _etiquetaRol(RolUsuario rol) {
  switch (rol) {
    case RolUsuario.estudiante:
      return 'Estudiante';
    case RolUsuario.funcionario:
      return 'Funcionario';
    case RolUsuario.guardia:
      return 'Guardia';
    case RolUsuario.adminCentral:
      return 'Admin central';
    case RolUsuario.administrador:
      return 'Administrador';
  }
}
