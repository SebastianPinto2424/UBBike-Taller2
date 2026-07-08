import 'package:flutter/material.dart';

import 'package:ubbike/core/tema/colores_ubb.dart';

class VistaConTabs extends StatelessWidget {
  const VistaConTabs({
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

Tab tabCompacto(IconData icono, String texto) {
  return Tab(
    height: 44,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
