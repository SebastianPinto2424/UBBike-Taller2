import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import 'widgets/estilos_formulario_auth.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final rutController = TextEditingController();
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final autenticacionApi = AutenticacionApi();
  bool cargando = false;
  bool mostrarContrasena = false;

  @override
  void dispose() {
    nombreController.dispose();
    rutController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: ContenedorResponsivo(
        anchoMaximo: 560,
        child: ListView(
          children: [
            const MarcaUbbike(compacta: true),
            const SizedBox(height: 22),
            Text(
              'Solicitar cuenta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ColoresUbb.azulOscuro,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Se enviará un correo de activación. La cuenta no queda habilitada hasta confirmar el enlace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColoresUbb.textoSecundario,
                  ),
            ),
            const SizedBox(height: 18),
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nombreController,
                    decoration: decoracionCampoAuth(
                      labelText: 'Nombre completo',
                      icono: Icons.person_outline,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: rutController,
                    decoration: decoracionCampoAuth(
                      labelText: 'RUT',
                      icono: Icons.badge_outlined,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El RUT es obligatorio.';
                      }
                      final rutRegex =
                          RegExp(r'^\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]$');
                      if (!rutRegex.hasMatch(value)) {
                        return 'Formato incorrecto. Ej: 12.345.678-9 o 12345678-9';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: correoController,
                    decoration: decoracionCampoAuth(
                      labelText: 'Correo institucional',
                      icono: Icons.mail_outline,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El correo es obligatorio.';
                      }
                      if (!value.endsWith('@ubiobio.cl') &&
                          !value.endsWith('@alumnos.ubiobio.cl')) {
                        return 'Debe ser @ubiobio.cl o @alumnos.ubiobio.cl';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: contrasenaController,
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
                    obscureText: !mostrarContrasena,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
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
                    },
                  ),
                  const SizedBox(height: 26),
                  ElevatedButton.icon(
                    style: estiloBotonAuth(),
                    onPressed: cargando ? null : _registrar,
                    icon: cargando
                        ? indicadorBotonAuth()
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(
                      cargando ? 'Enviando...' : 'Enviar solicitud',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrar() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => cargando = true);

    try {
      final correo = correoController.text.trim();

      final mensaje = await autenticacionApi.registrar(
        nombre: nombreController.text.trim(),
        rut: rutController.text.trim(),
        correo: correo,
        contrasena: contrasenaController.text,
      );

      if (mounted) {
        _mostrarConfirmacion(context, mensaje);
      }
    } on ExcepcionApi catch (error) {
      if (mounted) {
        _mostrarMensaje(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        _mostrarMensaje('No se pudo conectar con el backend');
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

  void _mostrarConfirmacion(BuildContext context, String mensaje) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Correo enviado'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text('Volver al ingreso'),
            ),
          ],
        );
      },
    );
  }
}
