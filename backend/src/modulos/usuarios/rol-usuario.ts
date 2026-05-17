export const RolUsuario = {
  ESTUDIANTE: 'ESTUDIANTE',
  FUNCIONARIO: 'FUNCIONARIO',
  GUARDIA: 'GUARDIA',
  ADMIN_CENTRAL: 'ADMIN_CENTRAL',
  ADMINISTRADOR: 'ADMINISTRADOR'
} as const;

export type RolUsuario = (typeof RolUsuario)[keyof typeof RolUsuario];
