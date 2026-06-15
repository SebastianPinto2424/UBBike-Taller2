import 'package:flutter_test/flutter_test.dart';
import 'package:ubbike/shared/utils/identidad.dart';
import 'package:ubbike/shared/utils/opciones_bicicleta.dart';

void main() {
  group('validaciones de registro', () {
    test('valida RUT chileno con guion y digito verificador', () {
      expect(rutValido('12.345.678-5'), isTrue);
      expect(rutValido('12345678-5'), isTrue);
      expect(rutValido('12.345.670-K'), isTrue);
      expect(rutValido('12.345.678-9'), isFalse);
      expect(rutValido('123456785'), isFalse);
    });

    test('exige dos nombres y dos apellidos', () {
      expect(nombreCompletoValido('Juan Carlos Perez Soto'), isTrue);
      expect(nombreCompletoValido('Juan Carlos Pérez Soto'), isTrue);
      expect(nombreCompletoValido('Juan Perez'), isFalse);
      expect(nombreCompletoValido('Juan Carlos Perez'), isFalse);
      expect(nombreCompletoValido('Juan 123 Perez Soto'), isFalse);
    });

    test('obtiene nombre corto para saludos', () {
      expect(nombreCorto('Juan Carlos Perez Soto'), 'Juan Perez');
      expect(nombreCorto('Juan Perez'), 'Juan Perez');
      expect(nombreCorto('Juan'), 'Juan');
    });
  });

  group('validaciones de bicicleta', () {
    test('normaliza aros permitidos y rechaza valores desconocidos', () {
      expect(normalizarAroBicicleta('29'), '29');
      expect(normalizarAroBicicleta('700C'), '29');
      expect(normalizarAroBicicleta('27.5 / 650B (ISO 584)'), '27.5');
      expect(normalizarAroBicicleta('R26'), isNull);
    });

    test('normaliza colores y combinaciones validas', () {
      expect(normalizarColorBicicleta('plomo'), 'Gris');
      expect(normalizarColorBicicleta('negro / rojo / plateado'),
          'Negro / Rojo / Plateado');
      expect(normalizarColorBicicleta('negro/rojo/azul/verde'), isNull);
      expect(normalizarColorBicicleta('negro/inventado'), isNull);
    });

    test('sugiere colores por catalogo y alias', () {
      expect(sugerirColoresBicicleta('plo'), contains('Gris'));
      expect(sugerirColoresBicicleta('marino'), contains('Azul marino'));
      expect(sugerirColoresBicicleta(''), contains('Negro'));
    });

    test('valida descripcion marca modelo color y serie', () {
      expect(validarDescripcionBicicleta('Bici urbana'), isNull);
      expect(validarDescripcionBicicleta('--'), isNotNull);
      expect(validarMarcaBicicleta('Oxford'), isNull);
      expect(validarMarcaBicicleta('A'), isNotNull);
      expect(validarModeloBicicleta('ATX 720'), isNull);
      expect(validarColorBicicleta('azul marino'), isNull);
      expect(validarColorBicicleta('azul123'), isNotNull);
      expect(validarNumeroSerieBicicleta('AB-1234'), isNull);
      expect(validarNumeroSerieBicicleta('AB 1234'), isNotNull);
    });
  });
}
