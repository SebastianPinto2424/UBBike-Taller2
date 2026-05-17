import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import 'pantalla_login.dart';
import 'widgets/estilos_formulario_auth.dart';

class PantallaVerificarCorreo extends StatefulWidget {
  const PantallaVerificarCorreo({super.key, required this.token});

  final String token;

  @override
  State<PantallaVerificarCorreo> createState() =>
      _PantallaVerificarCorreoState();
}

class _PantallaVerificarCorreoState extends State<PantallaVerificarCorreo> {
  final autenticacionApi = AutenticacionApi();
  String mensaje = 'Verificando correo...';
  bool cargando = true;
  bool correcto = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    try {
      final respuesta = await autenticacionApi.verificarCorreo(widget.token);
      if (mounted) {
        setState(() {
          mensaje = respuesta;
          correcto = true;
          cargando = false;
        });
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        setState(() {
          mensaje = error.mensaje;
          cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          mensaje = 'No se pudo conectar con el backend';
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PantallaEstadoCorreo(
      titulo: correcto ? 'Cuenta activada' : 'Verificación de correo',
      mensaje: mensaje,
      cargando: cargando,
      icono: correcto
          ? Icons.check_circle_outline
          : Icons.mark_email_read_outlined,
      color: correcto ? ColoresUbb.exito : ColoresUbb.azulApp,
    );
  }
}

class PantallaCambiarContrasena extends StatefulWidget {
  const PantallaCambiarContrasena({super.key, required this.token});

  final String token;

  @override
  State<PantallaCambiarContrasena> createState() =>
      _PantallaCambiarContrasenaState();
}

class _PantallaCambiarContrasenaState extends State<PantallaCambiarContrasena> {
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;
  bool mostrarContrasena = false;

  @override
  void dispose() {
    contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    final segura = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$',
    );

    if (!segura.hasMatch(contrasenaController.text)) {
      _mostrarMensaje(
        'Mínimo 12 caracteres con mayúscula, minúscula, número y símbolo',
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final mensaje = await autenticacionApi.cambiarContrasena(
        token: widget.token,
        contrasena: contrasenaController.text,
      );

      if (mounted) {
        _mostrarMensaje(mensaje);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
          (_) => false,
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _mostrarMensaje(error.mensaje);
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ContenedorResponsivo(
        anchoMaximo: 520,
        child: ListView(
          children: [
            const MarcaUbbike(compacta: true),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nueva contraseña',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: contrasenaController,
                  obscureText: !mostrarContrasena,
                  decoration: decoracionCampoAuth(
                    labelText: 'Contraseña',
                    icono: Icons.lock_outline,
                    suffixIcon: IconButton(
                      tooltip: mostrarContrasena
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      onPressed: () {
                        setState(
                          () => mostrarContrasena = !mostrarContrasena,
                        );
                      },
                      icon: Icon(
                        mostrarContrasena
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  style: estiloBotonAuth(),
                  onPressed: cargando ? null : _cambiar,
                  icon: cargando
                      ? indicadorBotonAuth()
                      : const Icon(Icons.save_outlined),
                  label: Text(cargando ? 'Guardando...' : 'Guardar cambio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PantallaEstadoCorreo extends StatelessWidget {
  const _PantallaEstadoCorreo({
    required this.titulo,
    required this.mensaje,
    required this.cargando,
    required this.icono,
    required this.color,
  });

  final String titulo;
  final String mensaje;
  final bool cargando;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ContenedorResponsivo(
        anchoMaximo: 520,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MarcaUbbike(compacta: true),
                  const SizedBox(height: 22),
                  Icon(icono, color: color, size: 48),
                  const SizedBox(height: 14),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(mensaje, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (cargando)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      style: estiloBotonAuth(),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const PantallaLogin()),
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Ir al ingreso'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
