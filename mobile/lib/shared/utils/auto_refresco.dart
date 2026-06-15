import 'dart:async';

import 'package:flutter/widgets.dart';

mixin AutoRefrescoMixin<T extends StatefulWidget> on State<T> {
  Timer? _temporizadorAutoRefresco;

  Duration get intervaloAutoRefresco => const Duration(seconds: 3);

  Future<void> refrescar();

  void iniciarAutoRefresco() {
    _temporizadorAutoRefresco?.cancel();
    _temporizadorAutoRefresco = Timer.periodic(intervaloAutoRefresco, (_) {
      if (mounted) {
        refrescar();
      }
    });
  }

  void detenerAutoRefresco() {
    _temporizadorAutoRefresco?.cancel();
    _temporizadorAutoRefresco = null;
  }

  @override
  void dispose() {
    _temporizadorAutoRefresco?.cancel();
    super.dispose();
  }
}
