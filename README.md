# GEA - Mobile App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State%20Management-5C6BC0?style=flat)
![Estado](https://img.shields.io/badge/Estado-Completado-2EA44F?style=flat)

**GEA (Gestión de Eventos y Anuncios)** es una plataforma institucional para la gestión de eventos, calendarios, espacios físicos, reservas y anuncios públicos.

Este repositorio contiene la **aplicación móvil** de GEA, desarrollada con **Flutter** y **Dart**, orientada a los usuarios de la institución para consultar información, visualizar eventos y anuncios, y realizar solicitudes desde dispositivos móviles.

GEA fue desarrollado como un **proyecto real para una institución universitaria**. La aplicación móvil, junto con el backend y la plataforma web, fue diseñada, estructurada y programada de forma individual.

---

## 📑 Tabla de contenido

- [Características principales](#-características-principales)
- [Arquitectura](#️-arquitectura)
- [Stack tecnológico](#-stack-tecnológico)
- [Clean Architecture](#️-clean-architecture)
- [Autenticación y seguridad](#-autenticación-y-seguridad)
- [Integración con el backend](#-integración-con-el-backend)
- [Requisitos](#-requisitos)
- [Instalación y ejecución local](#️-instalación-y-ejecución-local)
- [Generación de código](#-generación-de-código)
- [Compilación](#-compilación)
- [Pruebas](#-pruebas)
- [Ecosistema GEA](#-ecosistema-gea)
- [Entornos](#-entornos)
- [Estado del proyecto](#-estado-del-proyecto)
- [Desarrollo](#-desarrollo)
- [Propiedad y uso](#-propiedad-y-uso)
- [Autor](#-autor)

---

## 📱 Características principales

- Consulta de eventos institucionales
- Calendario de eventos
- Visualización de información detallada de eventos
- Consulta de anuncios institucionales
- Solicitud de publicación de anuncios
- Autenticación de usuarios
- Gestión de sesión
- Navegación entre módulos
- Consumo de API REST
- Almacenamiento seguro de credenciales y sesión
- Manejo de estados de la aplicación
- Interfaz adaptable a dispositivos móviles
- Componentes reutilizables
- Navegación declarativa
- Indicadores de carga y estados de contenido
- Validación de formularios

---

## 🏗️ Arquitectura

La aplicación móvil utiliza una arquitectura basada en **Clean Architecture**, separando las responsabilidades de presentación, dominio y acceso a datos.

```text
GEA_MOVIL/
│
├── lib/
│   ├── core/
│   │   └── Configuración y recursos compartidos
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   └── Fuentes de datos y comunicación con API
│   │   ├── models/
│   │   │   └── Modelos de datos
│   │   └── repositories/
│   │       └── Implementaciones de repositorios
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   └── Entidades del dominio
│   │   ├── repositories/
│   │   │   └── Contratos de repositorios
│   │   └── usecases/
│   │       └── Casos de uso
│   │
│   ├── presentation/
│   │   ├── pages/
│   │   │   └── Pantallas de la aplicación
│   │   ├── widgets/
│   │   │   └── Componentes reutilizables
│   │   └── providers/
│   │       └── Gestión de estados
│   │
│   ├── routes/
│   │   └── Configuración de navegación
│   │
│   └── main.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

### Flujo de la aplicación

```text
Usuario
   │
   ▼
Interfaz Flutter
   │
   ▼
Presentation
   │
   ▼
Use Cases
   │
   ▼
Repository
   │
   ▼
Dio / API Client
   │
   ▼
GEA Backend
   │
   ▼
REST API
   │
   ▼
MySQL
```

---

## 🧰 Stack tecnológico

| Tecnología | Uso |
|---|---|
| Flutter | Framework de desarrollo móvil |
| Dart | Lenguaje de programación |
| Riverpod | Gestión de estado |
| Riverpod Generator | Generación de código para providers |
| Dio | Cliente HTTP para consumo de API |
| GoRouter | Navegación de la aplicación |
| Flutter Secure Storage | Almacenamiento seguro |
| Shared Preferences | Persistencia de preferencias |
| Google Fonts | Tipografías |
| Flutter SVG | Manejo de recursos SVG |
| Skeletonizer | Estados de carga y skeletons |

---

## 🏛️ Clean Architecture

La aplicación separa las responsabilidades principales en diferentes capas.

### Presentation

Contiene las pantallas, widgets y lógica relacionada con la interacción del usuario.

```text
presentation/
├── pages/
├── widgets/
└── providers/
```

### Domain

Contiene las reglas principales del negocio y los contratos utilizados por la aplicación.

```text
domain/
├── entities/
├── repositories/
└── usecases/
```

### Data

Se encarga de la comunicación con servicios externos y de la transformación de los datos.

```text
data/
├── datasources/
├── models/
└── repositories/
```

Esta separación permite mantener una estructura organizada y facilita el mantenimiento y la evolución de la aplicación.

---

## 🔐 Autenticación y seguridad

La aplicación móvil utiliza el sistema de autenticación proporcionado por el backend de GEA.

```text
Usuario
   │
   ▼
Pantalla de Login
   │
   ▼
GEA Backend
   │
   ▼
Validación de credenciales
   │
   ▼
JWT
   │
   ▼
Almacenamiento seguro
   │
   ▼
Sesión autenticada
   │
   ▼
Acceso a funcionalidades protegidas
```

La aplicación utiliza:

- Autenticación mediante API REST
- Tokens JWT
- Persistencia segura de la sesión
- Flutter Secure Storage para información sensible
- Control de navegación según el estado de autenticación
- Comunicación HTTPS en entornos de producción
- Manejo de expiración y estados de sesión

---

## 🔗 Integración con el backend

La aplicación móvil se comunica con el backend mediante una API REST.

Ejemplo de configuración:

```env
API_BASE_URL=http://localhost:8083
```

La URL de la API debe configurarse de acuerdo con el entorno donde se ejecute la aplicación.

```text
Desarrollo
    │
    ▼
GEA Mobile
    │
    ▼
GEA Backend
    │
    ▼
MySQL
```

La comunicación HTTP se realiza mediante **Dio**, lo que permite centralizar las solicitudes y el manejo de las respuestas provenientes del backend.

---

## 📋 Requisitos

Para ejecutar el proyecto localmente se requiere:

- Flutter SDK
- Dart SDK
- Android Studio
- Android SDK
- Git
- Dispositivo Android o emulador
- Backend GEA ejecutándose y disponible

Para comprobar la instalación de Flutter:

```bash
flutter doctor
```

Se recomienda utilizar una versión de Flutter compatible con las dependencias definidas en `pubspec.yaml`.

---

## ⚙️ Instalación y ejecución local

### 1. Clonar el repositorio

```bash
git clone https://github.com/x6Darck/Movil_gea.git
cd Movil_gea
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar el backend

Verificar que el backend de GEA se encuentre ejecutándose y que la aplicación móvil tenga configurada correctamente la URL de la API.

### 4. Ejecutar la aplicación

```bash
flutter run
```

También es posible seleccionar un dispositivo específico:

```bash
flutter devices
flutter run -d <device_id>
```

---

## 🧪 Generación de código

El proyecto utiliza generación de código para determinados componentes, especialmente los relacionados con Riverpod.

Para generar los archivos correspondientes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Durante el desarrollo también puede utilizarse:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 📦 Compilación

### APK

```bash
flutter build apk
```

El archivo generado estará disponible dentro de:

```text
build/app/outputs/flutter-apk/
```

### APK Release

```bash
flutter build apk --release
```

### App Bundle

```bash
flutter build appbundle
```

El archivo generado puede utilizarse para procesos de distribución y publicación en Google Play.

---

## ✅ Pruebas

Para ejecutar las pruebas del proyecto:

```bash
flutter test
```

También es posible analizar el código mediante:

```bash
flutter analyze
```

---

## 🗂️ Estructura general del proyecto

```text
GEA_MOVIL/
│
├── android/
├── ios/
│
├── assets/
│   ├── images/
│   └── icons/
│
├── lib/
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   ├── routes/
│   └── main.dart
│
├── test/
│
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

---

## 🔄 Ecosistema GEA

GEA está compuesto por tres aplicaciones principales que trabajan sobre una arquitectura centralizada.

### Backend — GEA Backend

**Tecnologías principales:**

- Java
- Spring Boot
- Spring Security
- JWT
- Spring Data JPA
- MySQL
- Hibernate Envers
- Spring Mail
- Swagger / OpenAPI

**Repositorio:** [github.com/x6Darck/Backend_gea](https://github.com/x6Darck/Backend_gea)

### Frontend web — GEA Frontend

**Tecnologías principales:**

- React
- Vite
- JavaScript
- Axios
- React Router
- Shadcn/UI
- Lucide Icons

**Repositorio:** [github.com/x6Darck/Front_gea](https://github.com/x6Darck/Front_gea)

### Aplicación móvil — GEA Mobile

**Tecnologías principales:**

- Flutter
- Dart
- Riverpod
- Dio
- GoRouter
- Flutter Secure Storage

**Repositorio:** [github.com/x6Darck/Movil_gea](https://github.com/x6Darck/Movil_gea)

### Comunicación del ecosistema

```text
                    ┌──────────────────────┐
                    │      GEA Mobile      │
                    │    Flutter / Dart    │
                    └──────────┬───────────┘
                               │
                               │ REST API
                               ▼
┌──────────────────────┐   ┌──────────────────────┐
│     GEA Frontend     │──▶│     GEA Backend      │
│    React / Vite      │   │  Spring Boot / Java  │
└──────────────────────┘   └──────────┬───────────┘
                                      │
                                      │ JPA
                                      ▼
                               ┌──────────────┐
                               │    MySQL     │
                               └──────────────┘
```

---

## 🌐 Entornos

La aplicación puede trabajar con diferentes configuraciones dependiendo del entorno.

### Desarrollo

Utilizado durante el desarrollo y las pruebas locales.

```text
GEA Mobile
     │
     ▼
GEA Backend Local
     │
     ▼
MySQL Local
```

### Pruebas

Permite validar la integración de la aplicación móvil con una instancia de backend destinada a pruebas.

### Producción

En producción, la aplicación se comunica con la infraestructura correspondiente del sistema institucional.

---

## 📌 Estado del proyecto

**Estado:** Completado

GEA fue desarrollado como un proyecto real para una institución universitaria.

El ecosistema está compuesto por:

- Aplicación móvil
- Plataforma web administrativa
- API REST centralizada
- Base de datos
- Sistema de autenticación y autorización
- Gestión de eventos
- Gestión de anuncios
- Gestión de espacios
- Gestión de reservas

---

## 👨‍💻 Desarrollo

GEA fue diseñado, estructurado y desarrollado de forma individual.

En la aplicación móvil se realizó el desarrollo de:

- Arquitectura de la aplicación
- Implementación de Clean Architecture
- Diseño de interfaces móviles
- Desarrollo de pantallas y componentes
- Navegación de la aplicación
- Gestión de estados
- Integración con Riverpod
- Consumo de API REST
- Integración con Dio
- Manejo de autenticación
- Gestión de sesiones
- Almacenamiento seguro
- Validación de formularios
- Integración con el backend
- Manejo de estados de carga
- Adaptación de la interfaz para dispositivos móviles

El desarrollo se realizó buscando mantener la separación de responsabilidades, la reutilización de componentes, la mantenibilidad y una integración consistente con el resto del ecosistema GEA.

---

## 📄 Propiedad y uso

GEA fue desarrollado como un proyecto real para una institución universitaria.

Este repositorio se presenta con fines de **demostración y portafolio profesional**. Su publicación no implica transferencia de derechos de propiedad intelectual ni autorización para copiar, modificar, redistribuir o utilizar comercialmente el proyecto.

Los derechos correspondientes al software y sus componentes se mantienen de acuerdo con los acuerdos y condiciones bajo los cuales fue desarrollado.

Este repositorio no contiene:

- Contraseñas
- Credenciales
- Tokens
- Claves privadas
- Información personal
- Datos institucionales sensibles
- Configuraciones privadas
- Secretos de autenticación

---

## 👤 Autor

**Jean Pier Gómez**

Desarrollo individual del ecosistema GEA.

---

<p align="center">
  <strong>GEA — Gestión de Eventos y Anuncios</strong><br>
  Sistema institucional desarrollado con Java, Spring Boot, React y Flutter.
</p>
