import 'package:flutter/material.dart';

import '../../../../core/tema/colores_ubb.dart';

InputDecoration decoracionCampoAuth({
  required String labelText,
  required IconData icono,
  Widget? suffixIcon,
}) {
  OutlineInputBorder borde(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color),
    );
  }

  return InputDecoration(
    border: borde(ColoresUbb.textoPrincipal),
    enabledBorder: borde(ColoresUbb.textoPrincipal),
    focusedBorder: borde(ColoresUbb.textoPrincipal),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    labelText: labelText,
    labelStyle: const TextStyle(color: Colors.grey),
    prefixIcon: Icon(icono, color: ColoresUbb.azulApp),
    suffixIcon: suffixIcon,
  );
}

ButtonStyle estiloBotonAuth() {
  return ElevatedButton.styleFrom(
    backgroundColor: ColoresUbb.azulApp,
    foregroundColor: Colors.white,
    disabledBackgroundColor: Colors.grey,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  );
}

Widget indicadorBotonAuth() {
  return const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      color: Colors.white,
    ),
  );
}
