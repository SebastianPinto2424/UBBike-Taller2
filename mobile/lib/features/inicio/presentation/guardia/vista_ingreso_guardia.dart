part of '../pantalla_principal.dart';

enum ModoIngresoGuardia { qr, manual }

extension _ModoIngresoGuardiaTabs on ModoIngresoGuardia {
  int get indice {
    return switch (this) {
      ModoIngresoGuardia.qr => 0,
      ModoIngresoGuardia.manual => 1,
    };
  }
}

class VistaIngresoGuardia extends StatelessWidget {
  const VistaIngresoGuardia({
    super.key,
    required this.modoInicial,
  });

  final ModoIngresoGuardia modoInicial;

  @override
  Widget build(BuildContext context) {
    return _VistaConTabs(
      key: ValueKey(modoInicial),
      initialIndex: modoInicial.indice,
      tabs: [
        _tabCompacto(Icons.qr_code_scanner, 'QR'),
        _tabCompacto(Icons.edit_note_outlined, 'Manual'),
      ],
      vistas: const [
        VistaEscanerQrGuardia(),
        VistaGestionManualGuardia(),
      ],
    );
  }
}
