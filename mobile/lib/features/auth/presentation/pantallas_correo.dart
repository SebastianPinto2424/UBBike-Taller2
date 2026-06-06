import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import '../../../shared/widgets/snackbar_semantico.dart';
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
          mensaje = _mensajeEnlaceAuth(error.mensaje);
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

class PantallaCompletarRegistro extends StatefulWidget {
  const PantallaCompletarRegistro({super.key, required this.token});

  final String token;

  @override
  State<PantallaCompletarRegistro> createState() =>
      _PantallaCompletarRegistroState();
}

class _PantallaCompletarRegistroState extends State<PantallaCompletarRegistro> {
  final nombreController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;
  bool mostrarContrasena = false;

  @override
  void dispose() {
    nombreController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _completar() async {
    final nombre = nombreController.text.trim();
    final segura = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$',
    );

    if (nombre.length < 2) {
      context.mostrarError('Ingresa tu nombre completo');
      return;
    }

    if (!segura.hasMatch(contrasenaController.text)) {
      context.mostrarError(
        'Mínimo 12 caracteres con mayúscula, minúscula, número y símbolo',
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final mensaje = await autenticacionApi.completarRegistro(
        token: widget.token,
        nombre: nombre,
        contrasena: contrasenaController.text,
      );

      if (mounted) {
        context.mostrarExito(mensaje);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
          (_) => false,
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(_mensajeEnlaceAuth(error.mensaje));
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar registro')),
      body: ContenedorResponsivo(
        anchoMaximo: 560,
        child: ListView(
          children: [
            const MarcaUbbike(compacta: true),
            const SizedBox(height: 20),
            Text(
              'Activa tu cuenta',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa tus datos para iniciar sesión y generar códigos QR.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nombreController,
              decoration: decoracionCampoAuth(
                labelText: 'Nombre completo',
                icono: Icons.person_outline,
              ),
              textInputAction: TextInputAction.next,
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
                    setState(() => mostrarContrasena = !mostrarContrasena);
                  },
                  icon: Icon(
                    mostrarContrasena
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              style: estiloBotonAuth(),
              onPressed: cargando ? null : _completar,
              icon: cargando
                  ? indicadorBotonAuth()
                  : const Icon(Icons.check_circle_outline),
              label: Text(cargando ? 'Activando...' : 'Completar registro'),
            ),
          ],
        ),
      ),
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
  final formKey = GlobalKey<FormState>();
  final contrasenaController = TextEditingController();
  final confirmarContrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;
  bool mostrarContrasena = false;
  bool mostrarConfirmacion = false;

  @override
  void dispose() {
    contrasenaController.dispose();
    confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => cargando = true);

    try {
      final mensaje = await autenticacionApi.cambiarContrasena(
        token: widget.token,
        contrasena: contrasenaController.text,
      );

      if (mounted) {
        context.mostrarExito(mensaje);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
          (_) => false,
        );
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        context.mostrarError(_mensajeEnlaceAuth(error.mensaje));
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
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
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
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
                        textInputAction: TextInputAction.next,
                        validator: _validarContrasenaAuth,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: confirmarContrasenaController,
                        obscureText: !mostrarConfirmacion,
                        decoration: decoracionCampoAuth(
                          labelText: 'Confirmar contraseña',
                          icono: Icons.lock_outline,
                          suffixIcon: IconButton(
                            tooltip: mostrarConfirmacion
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            onPressed: () {
                              setState(
                                () =>
                                    mostrarConfirmacion = !mostrarConfirmacion,
                              );
                            },
                            icon: Icon(
                              mostrarConfirmacion
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final texto = value ?? '';
                          if (texto.isEmpty) {
                            return 'Confirma tu nueva contraseña.';
                          }
                          if (texto != contrasenaController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 26),
                      ElevatedButton.icon(
                        style: estiloBotonAuth(),
                        onPressed: cargando ? null : _cambiar,
                        icon: cargando
                            ? indicadorBotonAuth()
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          cargando ? 'Guardando...' : 'Guardar cambio',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String? _validarContrasenaAuth(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es obligatoria.';
  }

  final segura = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$',
  );
  if (!segura.hasMatch(value)) {
    return 'Mínimo 12 caracteres con mayúscula, minúscula, número y símbolo.';
  }
  return null;
}

String _mensajeEnlaceAuth(String mensaje) {
  final texto = mensaje.trim();
  final textoLower = texto.toLowerCase();

  if (textoLower.contains('token') || textoLower.contains('enlace')) {
    if (textoLower.contains('contrase')) {
      return 'El enlace para cambiar tu contraseña no es válido o expiró. Solicita uno nuevo desde Recuperar contraseña.';
    }
    if (textoLower.contains('registro')) {
      return 'El enlace de registro no es válido o expiró. Solicita apoyo al guardia para recibir uno nuevo.';
    }
    if (textoLower.contains('verificaci')) {
      return 'El enlace de verificación no es válido o expiró. Solicita uno nuevo para continuar.';
    }
    return 'El enlace no es válido o expiró. Solicita uno nuevo para continuar.';
  }

  return texto;
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
