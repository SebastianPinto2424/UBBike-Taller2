import 'package:web/web.dart' as web;

bool abrirEnlaceExterno(String url) {
  web.window.location.href = url;
  return true;
}
