import nodemailer from 'nodemailer';
import { entorno } from '../../configuracion/entorno';

type AdjuntoCorreo = {
  filename: string;
  path: string;
  cid?: string;
};

type DatosCorreo = {
  para: string;
  asunto: string;
  texto: string;
  html: string;
  adjuntos?: AdjuntoCorreo[];
};

const escaparHtml = (valor: string): string =>
  valor
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

const envolverHtml = (cuerpo: string): string => `<!doctype html>
<html lang="es">
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; color: #172033; margin: 0; padding: 0;">
${cuerpo}
</body>
</html>`;

const crearTransporte = () => {
  if (!entorno.correo.host) {
    return null;
  }

  const auth =
    entorno.correo.usuario && entorno.correo.contrasena
      ? {
          user: entorno.correo.usuario,
          pass: entorno.correo.contrasena
        }
      : undefined;

  return nodemailer.createTransport({
    host: entorno.correo.host,
    port: entorno.correo.puerto,
    secure: entorno.correo.seguro,
    auth
  });
};

export const verificarConfiguracionCorreo = async (): Promise<boolean> => {
  const transporte = crearTransporte();

  if (!transporte) {
    return false;
  }

  await transporte.verify();
  return true;
};

export const enviarCorreo = async (datos: DatosCorreo): Promise<void> => {
  const transporte = crearTransporte();

  if (!transporte) {
    if (entorno.ambiente === 'production') {
      throw new Error('SMTP_HOST debe estar configurado para enviar correos en produccion');
    }

    console.log('[correo-desarrollo]', {
      para: datos.para,
      asunto: datos.asunto,
      texto: datos.texto
    });
    return;
  }

  await transporte.sendMail({
    from: entorno.correo.remitente,
    to: datos.para,
    subject: datos.asunto,
    text: datos.texto,
    html: datos.html,
    attachments: datos.adjuntos
  });
};

export const crearCorreoVerificacion = (nombre: string, enlace: string) => ({
  asunto: 'Verifica tu cuenta UBBike',
  texto: `Hola ${nombre}. Para activar tu cuenta UBBike ingresa a: ${enlace}`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Verifica tu cuenta UBBike</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Recibimos tu solicitud de registro. Para activar tu cuenta, abre el siguiente enlace:</p>
    <p><a href="${escaparHtml(enlace)}" style="color: #014898; font-weight: bold;">Activar cuenta</a></p>
    <p>Si no solicitaste este registro, puedes ignorar este correo.</p>
  `)
});

export const crearCorreoCompletarRegistro = (correoUsuario: string, enlace: string) => ({
  asunto: 'Completa tu registro UBBike',
  texto: `Hola. Un guardia registró un movimiento manual asociado a ${correoUsuario}. Completa tu registro UBBike en: ${enlace}`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Completa tu registro UBBike</h2>
    <p>Hola,</p>
    <p>Un guardia registró un movimiento manual asociado a tu correo.</p>
    <p>Para activar tu cuenta, crear tu contraseña y usar códigos QR, abre el siguiente enlace:</p>
    <p><a href="${escaparHtml(enlace)}" style="color: #014898; font-weight: bold;">Completar registro</a></p>
    <p>Si no reconoces este movimiento, contacta a administración.</p>
  `)
});

export const crearCorreoCuentaVerificada = (nombre: string) => ({
  asunto: 'Cuenta UBBike activada',
  texto: `Hola ${nombre}. Tu cuenta UBBike fue activada correctamente.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Cuenta UBBike activada</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Tu cuenta fue activada correctamente. Ya puedes iniciar sesión y usar UBBike.</p>
  `)
});

export const crearCorreoCuentaDesactivada = (nombre: string) => ({
  asunto: 'Cuenta UBBike desactivada',
  texto: `Hola ${nombre}. Tu cuenta UBBike fue desactivada por administración. Si crees que es un error, contacta a administración.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Cuenta desactivada</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Tu cuenta UBBike fue desactivada por administración.</p>
    <p>No podrás iniciar sesión mientras la cuenta esté desactivada.</p>
    <p>Si crees que es un error, contacta a administración.</p>
  `)
});

export const crearCorreoCuentaReactivada = (nombre: string) => ({
  asunto: 'Cuenta UBBike reactivada',
  texto: `Hola ${nombre}. Tu cuenta UBBike fue reactivada por administración. Ya puedes intentar iniciar sesión nuevamente.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Cuenta reactivada</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Tu cuenta UBBike fue reactivada por administración.</p>
    <p>Ya puedes intentar iniciar sesión nuevamente.</p>
  `)
});

export const crearCorreoRolActualizado = (
  nombre: string,
  rolAnterior: string,
  rolNuevo: string
) => ({
  asunto: 'Rol UBBike actualizado',
  texto: `Hola ${nombre}. Administración actualizó tu rol UBBike de ${rolAnterior} a ${rolNuevo}.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Rol actualizado</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Administración actualizó tu rol UBBike.</p>
    <ul>
      <li><strong>Rol anterior:</strong> ${escaparHtml(rolAnterior)}</li>
      <li><strong>Rol nuevo:</strong> ${escaparHtml(rolNuevo)}</li>
    </ul>
    <p>Si no reconoces este cambio, contacta a administración.</p>
  `)
});

export const crearCorreoCuentaAdministrativa = (
  nombre: string,
  enlace: string,
  horasExpiracion: number
) => ({
  asunto: 'Cuenta UBBike creada por administración',
  texto: `Hola ${nombre}. Administración creó o reactivó tu cuenta UBBike. Define tu contraseña en: ${enlace}. Este enlace expira en ${horasExpiracion} horas.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Cuenta UBBike creada</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Administración creó o reactivó tu cuenta UBBike.</p>
    <p>Por seguridad, no enviamos contraseñas temporales. Define tu propia contraseña usando este enlace:</p>
    <p><a href="${escaparHtml(enlace)}" style="color: #014898; font-weight: bold;">Definir contraseña</a></p>
    <p>El enlace expira en ${horasExpiracion} horas. Si no reconoces esta acción, contacta a administración.</p>
  `)
});

export const crearCorreoCambioContrasena = (nombre: string, enlace: string) => ({
  asunto: 'Cambio de contraseña UBBike',
  texto: `Hola ${nombre}. Para cambiar tu contraseña UBBike ingresa a: ${enlace}`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Cambio de contraseña UBBike</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Solicitaste cambiar tu contraseña. Usa este enlace para continuar:</p>
    <p><a href="${escaparHtml(enlace)}" style="color: #014898; font-weight: bold;">Cambiar contraseña</a></p>
    <p>El enlace expira por seguridad. Si no solicitaste el cambio, ignora este correo.</p>
  `)
});

export const crearCorreoContrasenaActualizada = (nombre: string) => ({
  asunto: 'Contraseña UBBike actualizada',
  texto: `Hola ${nombre}. Tu contraseña UBBike fue actualizada correctamente.`,
  html: envolverHtml(`
    <h2 style="color: #014898;">Contraseña actualizada</h2>
    <p>Hola ${escaparHtml(nombre)},</p>
    <p>Tu contraseña UBBike fue cambiada correctamente.</p>
    <p>Si no realizaste este cambio, contacta a administración lo antes posible.</p>
  `)
});

type DatosCorreoMovimiento = {
  nombre: string;
  tipo: string;
  estado: string;
  origen: string;
  bicicleta: string;
  marca?: string | null;
  modelo?: string | null;
  color?: string | null;
  aro?: string | null;
  numeroSerie?: string | null;
  bicicletero: string;
  guardia: string;
  fecha: Date;
  motivoDenegacion?: string | null;
  comentarioGuardia?: string | null;

  fotoCid?: string | null;
};

const etiquetaMovimiento = (tipo: string) => (tipo === 'INGRESO' ? 'Ingreso' : 'Retiro');

const etiquetaEstadoMovimiento = (estado: string) =>
  estado === 'CONFIRMADO' ? 'confirmado' : 'denegado';

const etiquetaOrigenMovimiento = (origen: string) =>
  origen === 'MANUAL' ? 'manual' : 'por código QR';

export const crearCorreoMovimiento = (datos: DatosCorreoMovimiento) => {
  const tipo = etiquetaMovimiento(datos.tipo);
  const estado = etiquetaEstadoMovimiento(datos.estado);
  const origen = etiquetaOrigenMovimiento(datos.origen);
  const fecha = datos.fecha.toLocaleString('es-CL', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'America/Santiago'
  });
  const motivo = datos.motivoDenegacion ? `Motivo de denegación: ${datos.motivoDenegacion}` : '';
  const comentario = datos.comentarioGuardia
    ? `Comentario del guardia: ${datos.comentarioGuardia}`
    : '';

  const detalleBicicleta: Array<[string, string | null | undefined]> = [
    ['Descripción', datos.bicicleta],
    ['Marca', datos.marca],
    ['Modelo', datos.modelo],
    ['Color', datos.color],
    ['Aro', datos.aro],
    ['Número de serie', datos.numeroSerie]
  ];
  const camposBicicleta = detalleBicicleta.filter(([, valor]) => valor && `${valor}`.trim());

  const textoBicicleta = camposBicicleta
    .map(([etiqueta, valor]) => `  - ${etiqueta}: ${valor}`)
    .join('\n');
  const htmlBicicleta = camposBicicleta
    .map(
      ([etiqueta, valor]) =>
        `<li><strong>${etiqueta}:</strong> ${escaparHtml(`${valor}`)}</li>`
    )
    .join('');
  const htmlFoto = datos.fotoCid
    ? `<p style="margin-top:8px;"><strong>Foto de la bicicleta:</strong></p>
       <img src="cid:${datos.fotoCid}" alt="Foto de la bicicleta"
            style="max-width:320px; width:100%; border-radius:8px; border:1px solid #e5e7eb;" />`
    : '';

  return {
    asunto: `${tipo} ${origen} ${estado} en UBBike`,
    texto: [
      `Hola ${datos.nombre}.`,
      `Se registró un ${tipo.toLowerCase()} ${origen} ${estado}.`,
      `Bicicletero: ${datos.bicicletero}.`,
      `Guardia: ${datos.guardia}.`,
      `Fecha y hora: ${fecha}.`,
      'Datos de la bicicleta:',
      textoBicicleta,
      datos.fotoCid ? '(La foto de la bicicleta se adjunta en este correo.)' : '',
      motivo,
      comentario
    ]
      .filter(Boolean)
      .join('\n'),
    html: envolverHtml(`
      <h2 style="color: #014898;">${tipo} ${origen} ${estado}</h2>
      <p>Hola ${escaparHtml(datos.nombre)},</p>
      <p>Se registró un movimiento ${origen} en UBBike.</p>
      <ul>
        <li><strong>Operación:</strong> ${tipo}</li>
        <li><strong>Resultado:</strong> ${estado}</li>
        <li><strong>Origen:</strong> ${origen}</li>
        <li><strong>Bicicletero:</strong> ${escaparHtml(datos.bicicletero)}</li>
        <li><strong>Guardia:</strong> ${escaparHtml(datos.guardia)}</li>
        <li><strong>Fecha y hora:</strong> ${escaparHtml(fecha)}</li>
        ${
          datos.motivoDenegacion
            ? `<li><strong>Motivo:</strong> ${escaparHtml(datos.motivoDenegacion)}</li>`
            : ''
        }
        ${
          datos.comentarioGuardia
            ? `<li><strong>Comentario del guardia:</strong> ${escaparHtml(datos.comentarioGuardia)}</li>`
            : ''
        }
      </ul>
      <h3 style="color: #014898; margin-bottom:4px;">Datos de la bicicleta</h3>
      <ul>${htmlBicicleta}</ul>
      ${htmlFoto}
      <p>Si no reconoces este movimiento, contacta a administración.</p>
    `)
  };
};

export const crearCorreoMovimientoManual = crearCorreoMovimiento;
