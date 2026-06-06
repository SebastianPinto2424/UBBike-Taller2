import 'package:flutter/material.dart';

import '../../../core/servicios/excepcion_api.dart';
import '../../../core/tema/colores_ubb.dart';
import '../../../features/auth/data/autenticacion_api.dart';
import '../../../shared/widgets/contenedor_responsivo.dart';
import '../../../shared/widgets/marca_ubbike.dart';
import '../../../shared/widgets/snackbar_semantico.dart';
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
                      return _validarNombreRegistroFrontend(value);
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
                      return _validarRutRegistroFrontend(value);
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
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    validator: (value) {
                      final correo = value?.trim() ?? '';
                      if (correo.isEmpty) {
                        return 'El correo es obligatorio.';
                      }
                      if (correo.length > 160) {
                        return 'Maximo 160 caracteres.';
                      }
                      final correoValido =
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
                      if (!correoValido.hasMatch(correo)) {
                        return 'Ingresa un correo valido. Ej: estudiante@alumnos.ubiobio.cl';
                      }
                      if (!correo.endsWith('@ubiobio.cl') &&
                          !correo.endsWith('@alumnos.ubiobio.cl')) {
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
        context.mostrarError(error.mensaje);
      }
    } catch (_) {
      if (mounted) {
        context.mostrarError('No se pudo conectar con el backend');
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
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

String? _validarNombreRegistroFrontend(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'El nombre es obligatorio.';
  }
  if (texto.length < 3) {
    return 'El nombre debe tener al menos 3 caracteres.';
  }
  if (texto.length > 120) {
    return 'Maximo 120 caracteres.';
  }
  return null;
}

String? _validarRutRegistroFrontend(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) {
    return 'El RUT es obligatorio.';
  }
  if (!_rutRegistroFrontendValido(texto)) {
    return 'Ingresa un RUT valido.';
  }
  return null;
}

bool _rutRegistroFrontendValido(String valor) {
  final limpio = valor
      .replaceAll('.', '')
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .toUpperCase();
  if (!RegExp(r'^\d{7,8}[0-9K]$').hasMatch(limpio)) {
    return false;
  }

  final cuerpo = limpio.substring(0, limpio.length - 1);
  final digito = limpio.substring(limpio.length - 1);
  var suma = 0;
  var multiplicador = 2;

  for (var i = cuerpo.length - 1; i >= 0; i--) {
    suma += int.parse(cuerpo[i]) * multiplicador;
    multiplicador = multiplicador == 7 ? 2 : multiplicador + 1;
  }

  final resto = 11 - (suma % 11);
  final esperado = switch (resto) {
    11 => '0',
    10 => 'K',
    _ => resto.toString(),
  };

  return digito == esperado;
}
