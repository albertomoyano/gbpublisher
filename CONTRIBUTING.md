# Guía de Contribución

Las contribuciones a gbpublisher son bienvenidas, especialmente de la comunidad académica y científica que trabaja con producción editorial, estándares abiertos y flujos de publicación académica.

---

## Entorno de desarrollo

Para contribuir código es necesario contar con:

- Linux Mint con escritorio Cinnamon (única plataforma soportada)
- Gambas 3.21 o superior (IDE y runtime)
- MySQL/MariaDB
- TeXLive full
- Pandoc
- Saxon-HE (JAR en `/opt/Saxon-HE/`)
- Java (para Saxon-HE)

El proyecto usa `gb.qt5` como toolkit gráfico. No usar `gb.gtk` ni otras variantes: afecta el comportamiento de los acelerados de teclado y los campos de texto con acentos.

---

## Licenciamiento de contribuciones

Al contribuir código a gbpublisher, aceptás que:

1. Tu contribución será licenciada bajo **Business Source License 1.1**, los mismos términos que el proyecto principal.
2. Tu contribución se convertirá automáticamente a **GPL-3.0-or-later** en la Fecha de Cambio (5 años desde la publicación de cada versión).
3. Retenés el copyright de tu contribución, pero otorgás al proyecto una licencia perpetua, mundial, no exclusiva, gratuita y libre de regalías para usar, reproducir, modificar, distribuir y sublicenciar tu contribución como parte de gbpublisher.

No requerimos un CLA formal. Al enviar un pull request confirmás que sos el autor original del código contribuido o tenés el derecho legal de contribuirlo, que aceptás los términos de licenciamiento mencionados y que tu contribución no infringe derechos de terceros.

---

## Tipos de contribuciones bienvenidas

**Código:** corrección de errores, mejoras de rendimiento, nuevas funcionalidades alineadas con la arquitectura del proyecto, mejoras en la documentación del código.

**Documentación:** correcciones ortográficas y gramaticales, aclaraciones técnicas, ejemplos de uso.

**Reportes de errores:** descripción clara del problema, pasos para reproducir, comportamiento esperado versus observado, versión de gbpublisher y sistema operativo.

---

## Proceso de contribución

1. Hacé un **fork** del repositorio.
2. Creá una **rama** con nombre descriptivo: `fix/nombre-error` o `feature/nueva-funcionalidad`.
3. Realizá tus cambios siguiendo las convenciones del proyecto.
4. Documentá tu código en MAYÚSCULAS (estilo gbpublisher).
5. Probá tus cambios exhaustivamente.
6. Enviá un **pull request** con descripción clara de qué cambia y por qué.

---

## Convenciones de código

### Encabezado de función obligatorio

```gambas
'' ============================================
'' Función   : NombreFuncion
'' Propósito : Descripción clara de qué hace
'' Parámetros: NombreParam As Tipo — descripción
'' Retorna   : Tipo — descripción del valor de retorno
'' ============================================
Public Function NombreFuncion(sParam As String) As Boolean
```

### Apartados dentro de la función

```gambas
Public Function NombreFuncion(sParam As String) As Boolean

  ' --- 1. Inicialización de variables ---
  Dim sResultado As String

  ' --- 2. Validación de entrada ---
  If sParam = "" Then Return False

  ' --- 3. Procesamiento ---
  Try sResultado = OtraFuncion(sParam)
  If Error Then Return False

  Return True

End Function
```

### Manejo de errores

En Gambas, `Try` precede una sola línea. No existen bloques `Try/Catch/End`. El `Catch` va al final de la función y captura cualquier error no manejado:

```gambas
Public Function LeerArchivo(sRuta As String) As String

  ' --- 1. Inicialización ---
  Dim sContenido As String

  ' --- 2. Lectura defensiva ---
  Try sContenido = File.Load(sRuta)
  If Error Then Return ""

  Return sContenido

Catch
  ' CAPTURA DE ERRORES NO PREVISTOS EN LA FUNCIÓN
  Message.Error("Error inesperado en LeerArchivo: " & Error.Text)
  Return ""

End Function
```

### Estilo general

- Nombres de funciones y procedimientos: **PascalCase**
- Variables locales: **camelCase** con prefijo de tipo (`s` para String, `i` para Integer, `b` para Boolean, `h` para objetos)
- Constantes: **MAYÚSCULAS_CON_GUIONES**
- Comentarios internos: siempre en MAYÚSCULAS
- Indentación: 2 espacios, sin tabs

---

## Qué no será aceptado

- Código que rompa la arquitectura Single Source del proyecto
- Dependencias innecesarias o propietarias
- Funcionalidades que comprometan la separación entre contenido y procesamiento
- Cambios que requieran plataformas distintas de Linux Mint
- Automatismos que tomen decisiones editoriales implícitas
- Código que oculte procesos al usuario

---

## Revisión de código

Todas las contribuciones son revisadas por el mantenedor del proyecto. El proceso puede incluir solicitud de cambios, discusión sobre decisiones de diseño, pruebas adicionales y ajustes de documentación. El objetivo de la revisión es mantener coherencia arquitectónica y calidad del código, no bloquear contribuciones.

---

## Código de conducta

Críticas constructivas al código, no a las personas. Respeto por el tiempo de todos. Enfoque en mejorar el proyecto.

---

## Reconocimiento

Los contribuidores son reconocidos en [CONTRIBUTORS.md](CONTRIBUTORS.md).

---

## Contacto

Para preguntas sobre contribuciones, abrí un **issue** en GitHub o escribí a [estudio2a@outlook.com.ar](mailto:estudio2a@outlook.com.ar).

---

**Copyright © 2026 Alberto Moyano**

Este documento está bajo Creative Commons CC0 1.0 Universal (Dominio Público).
