// Comandos de build por entorno (ver dart_define.*.example.json en la raíz
// del repo para la plantilla de cada uno):
//   Pruebas:     flutter build apk --dart-define-from-file=dart_define.pruebas.json
//   Producción:  flutter build apk --dart-define-from-file=dart_define.produccion.json
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
}
