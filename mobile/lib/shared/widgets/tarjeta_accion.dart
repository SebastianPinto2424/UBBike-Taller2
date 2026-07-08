import 'package:flutter/material.dart';

import 'package:ubbike/core/tema/colores_ubb.dart';

class TarjetaAccion extends StatelessWidget {
  const TarjetaAccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.color = ColoresUbb.azulApp,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Icon(icono, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detalle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ColoresUbb.textoSecundario,
                            height: 1.32,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ColoresUbb.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
