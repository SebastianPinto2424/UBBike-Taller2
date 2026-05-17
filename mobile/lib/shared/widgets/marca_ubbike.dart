import 'package:flutter/material.dart';

import '../../core/tema/colores_ubb.dart';

class MarcaUbbike extends StatelessWidget {
  const MarcaUbbike({
    super.key,
    this.compacta = false,
    this.sobreAzul = false,
  });

  final bool compacta;
  final bool sobreAzul;

  @override
  Widget build(BuildContext context) {
    final altoLogo = compacta ? 34.0 : 68.0;
    final anchoLogo = compacta ? 128.0 : 224.0;
    final logo = Image.asset(
      'assets/imagenes/ubbike-logo-transparente.png',
      semanticLabel: 'Logo UBBike',
      height: altoLogo,
      width: anchoLogo,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      color: sobreAzul ? Colors.white : null,
      colorBlendMode: sobreAzul ? BlendMode.srcIn : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sobreAzul)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacta ? 0 : 2,
              vertical: compacta ? 0 : 2,
            ),
            child: logo,
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacta ? 4 : 0,
              vertical: compacta ? 4 : 0,
            ),
            child: logo,
          ),
        if (!compacta) ...[
          const SizedBox(height: 10),
          Text(
            'Universidad del Bio-Bio',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sobreAzul ? Colors.white : ColoresUbb.turquesa,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ],
    );
  }
}
