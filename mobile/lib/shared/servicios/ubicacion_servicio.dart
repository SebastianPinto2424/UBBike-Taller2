import 'package:geolocator/geolocator.dart';

class UbicacionServicio {
  const UbicacionServicio();

  Future<Position?> obtenerPosicionActual() async {
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        return null;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  double distanciaEnMetros({
    required double latitudOrigen,
    required double longitudOrigen,
    required double latitudDestino,
    required double longitudDestino,
  }) {
    return Geolocator.distanceBetween(
      latitudOrigen,
      longitudOrigen,
      latitudDestino,
      longitudDestino,
    );
  }
}
