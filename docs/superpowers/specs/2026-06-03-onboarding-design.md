# Onboarding — Pantalla de Bienvenida GEA
**Fecha:** 2026-06-03  
**Estado:** Aprobado

## Goal

Mostrar una pantalla de bienvenida estática cada vez que el usuario abre la app Flutter o entra al panel web. La pantalla muestra el logo de GEA, nombre de la plataforma y tagline institucional, con un botón que lleva al login.

## Scope

- App Flutter (`gea_app`)
- Frontend web React (`GEA_FRONT`)
- No toca el backend

---

## Flutter App

### Ruta
- Nueva pantalla `WelcomeScreen` en `/` (ruta raíz)
- GoRouter ya tiene redirect: si hay sesión activa, salta a `/calendario` automáticamente — la bienvenida solo aparece cuando no hay sesión o se acaba de abrir la app

### Archivo nuevo
`lib/features/welcome/presentation/screens/welcome_screen.dart`

### Contenido visual
- Fondo: color primario GEA `Color(0xFFCE1126)`
- Logo: `Image.asset('assets/images/gea-logo.png')` — 120x120px, centrado
- Título: `"GEA"` — blanco, bold, 32sp
- Subtítulo: `"Gestión de Eventos y Anuncios"` — blanco, 16sp
- Línea secundaria: `"Unilibre CUC"` — blanco con opacidad 80%, 14sp
- Botón: `ElevatedButton` blanco con texto rojo `"Entrar"` — navega a `/login`

### Cambio en router
`lib/config/router/app_router.dart` — agregar ruta `/` apuntando a `WelcomeScreen`

---

## Frontend Web (React)

### Ruta
- Nueva página `WelcomePage` en la ruta `/bienvenida`
- La ruta `/` redirige a `/bienvenida` (o se configura directamente como página inicial)

### Archivo nuevo
`src/pages/Welcome.jsx`
`src/pages/Welcome.module.css`

### Contenido visual
- Fondo: gradiente o color sólido `#CE1126` (mismo que la app)
- Logo: `gea-logo.png` — 120px centrado
- Título: `"GEA"` — blanco, bold
- Subtítulo: `"Gestión de Eventos y Anuncios · Unilibre CUC"` — blanco
- Botón: blanco con texto rojo `"Iniciar sesión"` — navega a `/login`

### Cambio en router
`src/App.jsx` — agregar ruta `/bienvenida` y redirigir `/` a `/bienvenida`

---

## Lo que NO cambia

- El flujo de login existente no se toca
- Los redirects de autenticación existentes no se tocan
- El backend no recibe ningún cambio
- Las rutas autenticadas (`/eventos`, `/anuncios`, etc.) no cambian

---

## Criterios de aceptación

1. Al abrir la app Flutter sin sesión → aparece la pantalla de bienvenida
2. Al pulsar "Entrar" en la app → se navega a la pantalla de login
3. Al entrar al panel web → aparece la pantalla de bienvenida
4. Al pulsar "Iniciar sesión" en la web → se navega al login
5. Si hay sesión activa en la app, GoRouter redirige directamente al home (sin pasar por bienvenida)
6. El diseño visual es consistente entre app y web (mismo logo, colores, mensaje)
