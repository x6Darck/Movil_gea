# GEA MOVIL 📱

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean_Architecture-00599C?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![State Management](https://img.shields.io/badge/State_Management-Riverpod-764ABC?style=for-the-badge)](https://riverpod.dev)

GEA es una plataforma profesional de gestión de eventos, calendario y agenda. Esta aplicación móvil está diseñada con los más altos estándares de ingeniería de software, priorizando la escalabilidad, el rendimiento y la mantenibilidad.

## 🚀 Características Principales

- **Gestión de Anuncios:** Comunicación fluida y organizada.
- **Calendario Inteligente:** Visualización de eventos con priorización y diseño premium.
- **Autenticación Segura:** Manejo profesional de tokens JWT y persistencia segura.
- **Arquitectura Enterprise:** Implementación estricta de Clean Architecture.

## 🛠️ Stack Tecnológico

- **Lenguaje:** Dart
- **Framework:** Flutter
- **Gestión de Estado:** Riverpod (Generator)
- **Networking:** Dio
- **Navegación:** GoRouter
- **Persistencia:** Flutter Secure Storage & Shared Preferences
- **Diseño:** Google Fonts, Flutter SVG, Skeletonizer

## 🏗️ Arquitectura

El proyecto sigue los principios de **Clean Architecture**, dividiendo cada funcionalidad en tres capas principales:

1.  **Data:** Implementación de repositorios, modelos (DTOs) y data sources.
2.  **Domain:** Entidades de negocio, interfaces de repositorios y casos de uso.
3.  **Presentation:** Widgets, controladores (Providers) y gestión de estado de la UI.

Estructura de carpetas:
```text
lib/
├── config/          # Configuración de temas, rutas y constantes.
├── core/            # Utilidades globales, errores y widgets compartidos.
└── features/        # Módulos funcionales (Auth, Calendar, Announcements).
    └── [feature]/
        ├── data/
        ├── domain/
        └── presentation/
```

## 📋 Requisitos

- Flutter SDK `^3.11.5`
- Dart SDK `^3.1.0`
- Android Studio / VS Code con extensiones de Flutter

## ⚙️ Instalación y Ejecución

1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/x6Darck/GEA_MOVIL.git
    ```

2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Generar código (Riverpod/Freezed/etc):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```

## 🧪 Comandos Útiles

- **Análisis de código:** `flutter analyze`
- **Limpieza del proyecto:** `flutter clean`
- **Compilación APK (desarrollo local):** `flutter build apk --release --dart-define-from-file=dart_define.json`
- **Compilación APK (servidor de pruebas):** `flutter build apk --release --dart-define-from-file=dart_define.pruebas.json`
- **Compilación APK (producción):** `flutter build apk --release --dart-define-from-file=dart_define.produccion.json`

Cada uno de estos tres archivos (`dart_define*.json`, no se suben a git) trae
la URL del backend y las credenciales de Microsoft para ese entorno — copia
la plantilla correspondiente (`dart_define.pruebas.example.json` /
`dart_define.produccion.example.json`) y completa los valores reales.

---
Desarrollado con ❤️ por el equipo de ingeniería de **GEA**.
