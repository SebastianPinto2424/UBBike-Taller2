import nodemailer from 'nodemailer';
import { entorno } from '../../configuracion/entorno';

type DatosCorreo = {
  para: string;
  asunto: string;
  texto: string;
  html: string;
};

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
    html: datos.html
  });
};

export const crearCorreoVerificacion = (nombre: string, enlace: string) => ({
  asunto: 'Verifica tu cuenta UBBike',
  texto: `Hola ${nombre}. Para activar tu cuenta UBBike ingresa a: ${enlace}`,
  html: `
    <div style="font-family: Arial, sans-serif; color: #172033;">
      <h2 style="color: #014898;">Verifica tu cuenta UBBike</h2>
      <p>Hola ${nombre},</p>
      <p>Recibimos tu solicitud de registro. Para activar tu cuenta, abre el siguiente enlace:</p>
      <p><a href="${enlace}" style="color: #014898; font-weight: bold;">Activar cuenta</a></p>
      <p>Si no solicitaste este registro, puedes ignorar este correo.</p>
    </div>
  `
});

export const crearCorreoCompletarRegistro = (correoUsuario: string, enlace: string) => ({
  asunto: 'Completa tu registro UBBike',
  texto: `Hola. Un guardia registró un movimiento manual asociado a ${correoUsuario}. Completa tu registro UBBike en: ${enlace}`,
  html: `
    <div style="font-family: Arial, sans-serif; color: #172033;">
      <h2 style="color: #014898;">Completa tu registro UBBike</h2>
      <p>Hola,</p>
      <p>Un guardia registró un movimiento manual asociado a tu correo institucional.</p>
      <p>Para activar tu cuenta, crear tu contraseña y usar códigos QR, abre el siguiente enlace:</p>
      <p><a href="${enlace}" style="color: #014898; font-weight: bold;">Completar registro</a></p>
      <p>Si no reconoces este movimiento, contacta a administración.</p>
    </div>
  `
});

export const crearCorreoCuentaVerificada = (nombre: string) => ({
  asunto: 'Cuenta UBBike activada',
  texto: `Hola ${nombre}. Tu cuenta UBBike fue activada correctamente.`,
  html: `
    <div style="font-family: Arial, sans-serif; color: #172033;">
      <h2 style="color: #014898;">Cuenta UBBike activada</h2>
      <p>Hola ${nombre},</p>
      <p>Tu cuenta fue activada correctamente. Ya puedes iniciar sesión y usar UBBike.</p>
    </div>
  `
});

export const crearCorreoCambioContrasena = (nombre: string, enlace: string) => ({
  asunto: 'Cambio de contraseña UBBike',
  texto: `Hola ${nombre}. Para cambiar tu contraseña UBBike ingresa a: ${enlace}`,
  html: `
    <div style="font-family: Arial, sans-serif; color: #172033;">
      <h2 style="color: #014898;">Cambio de contraseña UBBike</h2>
      <p>Hola ${nombre},</p>
      <p>Solicitaste cambiar tu contraseña. Usa este enlace para continuar:</p>
      <p><a href="${enlace}" style="color: #014898; font-weight: bold;">Cambiar contraseña</a></p>
      <p>El enlace expira por seguridad. Si no solicitaste el cambio, ignora este correo.</p>
    </div>
  `
});

export const crearCorreoContrasenaActualizada = (nombre: string) => ({
  asunto: 'Contraseña UBBike actualizada',
  texto: `Hola ${nombre}. Tu contraseña UBBike fue actualizada correctamente.`,
  html: `
    <div style="font-family: Arial, sans-serif; color: #172033;">
      <h2 style="color: #014898;">Contraseña actualizada</h2>
      <p>Hola ${nombre},</p>
      <p>Tu contraseña UBBike fue cambiada correctamente.</p>
      <p>Si no realizaste este cambio, contacta a administración lo antes posible.</p>
    </div>
  `
});

type DatosCorreoMovimientoManual = {
  nombre: string;
  tipo: string;
  estado: string;
  bicicleta: string;
  bicicletero: string;
  guardia: string;
  fecha: Date;
  motivoDenegacion?: string | null;
  comentarioGuardia?: string | null;
};

const etiquetaMovimiento = (tipo: string) => (tipo === 'INGRESO' ? 'Ingreso' : 'Retiro');

const etiquetaEstadoMovimiento = (estado: string) =>
  estado === 'CONFIRMADO' ? 'confirmado' : 'denegado';

export const crearCorreoMovimientoManual = (datos: DatosCorreoMovimientoManual) => {
  const tipo = etiquetaMovimiento(datos.tipo);
  const estado = etiquetaEstadoMovimiento(datos.estado);
  const fecha = datos.fecha.toLocaleString('es-CL', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'America/Santiago'
  });
  const motivo = datos.motivoDenegacion ? `Motivo de denegación: ${datos.motivoDenegacion}` : '';
  const comentario = datos.comentarioGuardia
    ? `Comentario del guardia: ${datos.comentarioGuardia}`
    : '';

  return {
    asunto: `${tipo} manual ${estado} en UBBike`,
    texto: [
      `Hola ${datos.nombre}.`,
      `Se registró un ${tipo.toLowerCase()} manual ${estado}.`,
      `Bicicleta: ${datos.bicicleta}.`,
      `Bicicletero: ${datos.bicicletero}.`,
      `Guardia: ${datos.guardia}.`,
      `Fecha y hora: ${fecha}.`,
      motivo,
      comentario
    ]
      .filter(Boolean)
      .join('\n'),
    html: `
      <div style="font-family: Arial, sans-serif; color: #172033;">
        <h2 style="color: #014898;">${tipo} manual ${estado}</h2>
        <p>Hola ${datos.nombre},</p>
        <p>Se registró un movimiento manual en UBBike.</p>
        <ul>
          <li><strong>Operación:</strong> ${tipo}</li>
          <li><strong>Resultado:</strong> ${estado}</li>
          <li><strong>Bicicleta:</strong> ${datos.bicicleta}</li>
          <li><strong>Bicicletero:</strong> ${datos.bicicletero}</li>
          <li><strong>Guardia:</strong> ${datos.guardia}</li>
          <li><strong>Fecha y hora:</strong> ${fecha}</li>
          ${datos.motivoDenegacion ? `<li><strong>Motivo:</strong> ${datos.motivoDenegacion}</li>` : ''}
          ${
            datos.comentarioGuardia
              ? `<li><strong>Comentario del guardia:</strong> ${datos.comentarioGuardia}</li>`
              : ''
          }
        </ul>
      </div>
    `
  };
};
