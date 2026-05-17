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
