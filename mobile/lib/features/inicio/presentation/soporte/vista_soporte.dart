part of '../pantalla_principal.dart';

class VistaSoporteUsuario extends StatelessWidget {
  const VistaSoporteUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      tabs: [
        _tabCompacto(Icons.headset_mic_outlined, 'Atención'),
        _tabCompacto(Icons.flag_outlined, 'Incidencias'),
      ],
      vistas: const [
        VistaSolicitarGuardia(),
        VistaIncidencias(
          mostrarReportante: false,
          puedeGestionar: false,
          permitirBicicletaPropia: true,
        ),
      ],
    );
  }
}

class VistaSoporteGuardia extends StatelessWidget {
  const VistaSoporteGuardia({super.key});

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      tabs: [
        _tabCompacto(Icons.notifications_active_outlined, 'Alertas'),
        _tabCompacto(Icons.report_problem_outlined, 'Incidencias'),
      ],
      vistas: const [
        VistaAlertasGuardia(),
        VistaIncidencias(
          mostrarReportante: true,
          puedeGestionar: false,
          gestionGuardia: true,
        ),
      ],
    );
  }
}

class VistaSoporteCentral extends StatelessWidget {
  const VistaSoporteCentral({super.key});

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      tabs: [
        _tabCompacto(Icons.campaign_outlined, 'Solicitudes'),
        _tabCompacto(Icons.report_problem_outlined, 'Incidencias'),
      ],
      vistas: const [
        VistaSolicitudesCentral(),
        VistaIncidencias(
          mostrarReportante: true,
          puedeGestionar: true,
          gestionCentral: true,
        ),
      ],
    );
  }
}

class VistaSoporteAdministrador extends StatelessWidget {
  const VistaSoporteAdministrador({super.key});

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      tabs: [
        _tabCompacto(Icons.security_outlined, 'Guardias'),
        _tabCompacto(Icons.campaign_outlined, 'Solicitudes'),
        _tabCompacto(Icons.report_problem_outlined, 'Incidencias'),
      ],
      vistas: const [
        VistaOperacionesGuardiasCentral(),
        VistaSolicitudesCentral(),
        VistaIncidencias(
          mostrarReportante: true,
          puedeGestionar: true,
          gestionCentral: true,
        ),
      ],
    );
  }
}

class _VistaConTabs extends StatelessWidget {
  const _VistaConTabs({
    super.key,
    required this.tabs,
    required this.vistas,
    this.initialIndex = 0,
  });

  final List<Tab> tabs;
  final List<Widget> vistas;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Column(
        children: [
          Material(
            color: ColoresUbb.superficieAzulSuave,
            borderRadius: BorderRadius.circular(14),
            child: TabBar(
              tabs: tabs,
              padding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: ColoresUbb.textoSecundario,
              indicator: BoxDecoration(
                color: ColoresUbb.azulApp,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(children: vistas),
          ),
        ],
      ),
    );
  }
}

Tab _tabCompacto(IconData icono, String texto) {
  return Tab(
    height: 44,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 18),
        const SizedBox(width: 8),
        Text(texto),
      ],
    ),
  );
}
