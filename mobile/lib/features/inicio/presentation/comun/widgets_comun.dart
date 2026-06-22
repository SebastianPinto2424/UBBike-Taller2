import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/configuracion/configuracion_api.dart';
import '../../../../core/tema/colores_ubb.dart';
import '../../../../core/servicios/excepcion_api.dart';
import '../../../../shared/modelos/bicicleta_app.dart';
import '../../../../shared/modelos/bicicletero_app.dart';
import '../../../../shared/modelos/movimiento_app.dart';
import '../../../../shared/widgets/chip_estado.dart';
import '../../../../shared/widgets/snackbar_semantico.dart';
import '../../../acceso/data/solicitud_guardia_modelos.dart';

part 'bicicletas_widgets.dart';
part 'bicicletero_widgets.dart';
part 'central_widgets.dart';
part 'encabezado_widgets.dart';
part 'estado_widgets.dart';
part 'qr_demostracion.dart';
part 'qr_widgets.dart';
part 'solicitud_guardia_widgets.dart';
part 'utiles_comun.dart';
part 'widgets_movimientos.dart';
