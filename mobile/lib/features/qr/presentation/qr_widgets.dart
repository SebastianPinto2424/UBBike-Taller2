import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ubbike/core/tema/colores_ubb.dart';

class QrTemporal extends StatelessWidget {
  const QrTemporal({
    super.key,
    required this.token,
    required this.segundosRestantes,
  });

  final String token;
  final int segundosRestantes;

  @override
  Widget build(BuildContext context) {
    final expirado = segundosRestantes <= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoDisponible =
            constraints.maxWidth.isFinite ? constraints.maxWidth - 28 : 240.0;
        final dimensionQr = anchoDisponible.clamp(160.0, 240.0).toDouble();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColoresUbb.bordeFuerte),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: expirado ? 0.22 : 1,
                  child: QrImageView(
                    data: token,
                    version: QrVersions.auto,
                    size: dimensionQr,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: ColoresUbb.textoPrincipal,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: ColoresUbb.textoPrincipal,
                    ),
                  ),
                ),
                if (expirado)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ColoresUbb.rojoInstitucional,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        'Expirado',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
