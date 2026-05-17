import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ubbike/core/tema/tema_ubb.dart';
import 'package:ubbike/features/inicio/presentation/pantalla_principal.dart';
import 'package:ubbike/main.dart';
import 'package:ubbike/shared/modelos/rol_usuario.dart';

void _configurarTamano(WidgetTester tester, Size size) {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('muestra la pantalla de ingreso UBBike', (tester) async {
    await tester.pumpWidget(const AplicacionUBBike());

    expect(find.bySemanticsLabel('Logo UBBike'), findsOneWidget);
    expect(
        find.text('Tu acceso seguro a los bicicleteros UBB'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('el ingreso soporta alto reducido sin romper layout',
      (tester) async {
    _configurarTamano(tester, const Size(360, 220));

    await tester.pumpWidget(const AplicacionUBBike());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('pantalla principal carga sin errores iniciales por rol',
      (tester) async {
    _configurarTamano(tester, const Size(360, 640));

    for (final rol in RolUsuario.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: crearTemaUbb(),
          home: PantallaPrincipal(key: ValueKey(rol), rol: rol),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'rol ${rol.name}');
    }
  });
}
