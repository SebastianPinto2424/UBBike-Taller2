import { NextFunction, Response } from 'express';
import { RolUsuario } from '../../modulos/usuarios/rol-usuario';
import { SolicitudAutenticada } from './autenticacion.middleware';

export const autorizarRoles = (...rolesPermitidos: string[]) => {
  return (req: SolicitudAutenticada, res: Response, next: NextFunction) => {
    const rol = req.usuario?.rol;

    if (!rol || (rol !== RolUsuario.ADMINISTRADOR && !rolesPermitidos.includes(rol))) {
      return res.status(403).json({
        message: 'No tienes permisos para realizar esta acción'
      });
    }

    return next();
  };
};
