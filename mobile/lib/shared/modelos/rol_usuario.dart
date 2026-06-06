enum RolUsuario { estudiante, funcionario, guardia, administrador }

extension EtiquetaRolUsuario on RolUsuario {
  static RolUsuario desdeApi(String valor) {
    switch (valor.toUpperCase()) {
      case 'FUNCIONARIO':
        return RolUsuario.funcionario;
      case 'GUARDIA':
        return RolUsuario.guardia;
      case 'ADMIN_CENTRAL':
        return RolUsuario.administrador;
      case 'ADMINISTRADOR':
        return RolUsuario.administrador;
      case 'ESTUDIANTE':
      default:
        return RolUsuario.estudiante;
    }
  }

  String get valorApi {
    switch (this) {
      case RolUsuario.estudiante:
        return 'ESTUDIANTE';
      case RolUsuario.funcionario:
        return 'FUNCIONARIO';
      case RolUsuario.guardia:
        return 'GUARDIA';
      case RolUsuario.administrador:
        return 'ADMINISTRADOR';
    }
  }

  String get etiqueta {
    switch (this) {
      case RolUsuario.estudiante:
        return 'Estudiante';
      case RolUsuario.funcionario:
        return 'Funcionario';
      case RolUsuario.guardia:
        return 'Guardia';
      case RolUsuario.administrador:
        return 'Administrador';
    }
  }

  bool get esUsuarioRegular {
    return this == RolUsuario.estudiante || this == RolUsuario.funcionario;
  }
}
