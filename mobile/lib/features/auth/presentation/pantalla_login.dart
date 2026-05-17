import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../features/auth/presentation/pantalla_registro.dart';
import '../../../features/inicio/presentation/pantalla_principal.dart';
import '../../../shared/servicios/sesion_actual.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import 'widgets/estilos_formulario_auth.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;
  bool mostrarContrasena = false;

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColoresUbb.azulNoche,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final altoFormulario =
              constraints.maxHeight > 246 ? constraints.maxHeight - 246 : 0.0;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const _CabeceraIngreso(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: altoFormulario,
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: ColoresUbb.fondo,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                24,
                              ),
                              child: _FormularioIngreso(
                                correoController: correoController,
                                contrasenaController: contrasenaController,
                                cargando: cargando,
                                mostrarContrasena: mostrarContrasena,
                                onAlternarContrasena: () {
                                  setState(
                                    () =>
                                        mostrarContrasena = !mostrarContrasena,
                                  );
                                },
                                onIngresar: _iniciarSesion,
                                onRegistro: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PantallaRegistro(),
                                    ),
                                  );
                                },
                                onRecuperar: () =>
                                    _mostrarRecuperacion(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _iniciarSesion() {
    if (cargando) {
      return;
    }

    _iniciarSesionAsync();
  }

  Future<void> _iniciarSesionAsync() async {
    final correo = correoController.text.trim().toLowerCase();
    final contrasena = contrasenaController.text;

    if (correo.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa correo y contraseña'),
        ),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final resultado = await autenticacionApi.iniciarSesion(
        correo: correo,
        contrasena: contrasena,
      );

      SesionActual.iniciar(
        nuevoToken: resultado.token,
        nuevoUsuario: resultado.usuario,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PantallaPrincipal(rol: resultado.usuario.rol),
        ),
      );
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _mostrarMensajeCorreo(context, error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensajeCorreo(context, 'No se pudo conectar con el backend');
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  void _mostrarRecuperacion(BuildContext context) {
    final contextoPantalla = this.context;
    final correoRecuperacionController = TextEditingController(
      text: correoController.text.trim(),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
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
                  'Recuperar contraseña',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enviaremos un enlace seguro al correo institucional registrado.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: correoRecuperacionController,
                  decoration: decoracionCampoAuth(
                    labelText: 'Correo institucional',
                    icono: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: estiloBotonAuth(),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      final mensaje =
                          await autenticacionApi.solicitarCambioContrasena(
                        correoRecuperacionController.text.trim(),
                      );
                      if (contextoPantalla.mounted) {
                        _mostrarMensajeCorreo(contextoPantalla, mensaje);
                      }
                    } on ExcepcionApi catch (error) {
                      if (contextoPantalla.mounted) {
                        _mostrarMensajeCorreo(contextoPantalla, error.mensaje);
                      }
                    } catch (_) {
                      if (contextoPantalla.mounted) {
                        _mostrarMensajeCorreo(
                          contextoPantalla,
                          'No se pudo conectar con el backend',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Enviar correo'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(correoRecuperacionController.dispose);
  }

  void _mostrarMensajeCorreo(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

class _CabeceraIngreso extends StatelessWidget {
  const _CabeceraIngreso();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ContenedorResponsivo(
        anchoMaximo: 520,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MarcaUbbike(compacta: true, sobreAzul: true),
            const SizedBox(height: 24),
            Text(
              'Tu acceso seguro a los bicicleteros UBB',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Registra tu bicicleta, genera códigos temporales y revisa cada ingreso o retiro desde una sola app institucional.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioIngreso extends StatelessWidget {
  const _FormularioIngreso({
    required this.correoController,
    required this.contrasenaController,
    required this.cargando,
    required this.mostrarContrasena,
    required this.onAlternarContrasena,
    required this.onIngresar,
    required this.onRegistro,
    required this.onRecuperar,
  });

  final TextEditingController correoController;
  final TextEditingController contrasenaController;
  final bool cargando;
  final bool mostrarContrasena;
  final VoidCallback onAlternarContrasena;
  final VoidCallback onIngresar;
  final VoidCallback onRegistro;
  final VoidCallback onRecuperar;

  @override
  Widget build(BuildContext context) {
    final estiloEnlace = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ColoresUbb.textoPrincipal,
          fontWeight: FontWeight.w500,
        );
    final estiloEnlaceDestacado = estiloEnlace?.copyWith(
      fontWeight: FontWeight.w900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Iniciar Sesión',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ColoresUbb.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: correoController,
          decoration: decoracionCampoAuth(
            labelText: 'Correo electrónico',
            icono: Icons.mail_outline,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: contrasenaController,
          decoration: decoracionCampoAuth(
            labelText: 'Contraseña',
            icono: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: mostrarContrasena
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              onPressed: onAlternarContrasena,
              icon: Icon(
                mostrarContrasena
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          obscureText: !mostrarContrasena,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onIngresar(),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onRecuperar,
            style: TextButton.styleFrom(
              foregroundColor: ColoresUbb.textoPrincipal,
              shape: const StadiumBorder(),
            ),
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: estiloEnlace,
                children: [
                  const TextSpan(text: '¿Has olvidado tu contraseña? '),
                  TextSpan(text: 'Recuperar', style: estiloEnlaceDestacado),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: cargando ? null : onIngresar,
          style: estiloBotonAuth(),
          child: cargando ? indicadorBotonAuth() : const Text('Ingresar'),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onRegistro,
          style: TextButton.styleFrom(
            foregroundColor: ColoresUbb.textoPrincipal,
            shape: const StadiumBorder(),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: estiloEnlace,
              children: [
                const TextSpan(text: '¿Aún no tienes cuenta? '),
                TextSpan(text: 'Registrarse', style: estiloEnlaceDestacado),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
