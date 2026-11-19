# Guía de Contribución

Las contribuciones a gbpublisher son bienvenidas, especialmente de la comunidad académica y científica que trabaja con producción editorial, estándares abiertos y flujos de publicación académica.

---

## Entorno de desarrollo

Para contribuir código es necesario contar con:

- Linux Mint con escritorio Cinnamon y X11 (única plataforma soportada)
- Gambas 3.22 (IDE y runtime)
- MySQL 8
- TeX Live completo
- Java
- Las herramientas fijadas en `/opt` (Pandoc, Saxon-HE, epubcheck, veraPDF, packtools). No se instalan a mano: las instala la propia aplicación desde **Acerca de → Controlar integridad del sistema**, con un proyecto abierto.

El proyecto usa `gb.qt6` como toolkit gráfico. No usar `gb.gtk` ni otras variantes: afecta el comportamiento de los acelerados de teclado y los campos de texto con acentos.

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
4. Documentá tu código con las convenciones de abajo: comentarios en MAYÚSCULAS, encabezado en cada función y apartados numerados.
5. Probá tus cambios exhaustivamente.
6. Enviá un **pull request** con descripción clara de qué cambia y por qué.

---

## Convenciones de código

### Encabezado de función obligatorio

Sin excepciones por brevedad: un manejador de una línea también lo lleva.

```gambas
' ============================================
' Función   : NombreFuncion
' Propósito : Descripción clara de qué hace
' Parámetros: sParam As String — descripción
' Retorna   : Boolean — descripción del valor de retorno
' ============================================
Public Function NombreFuncion(sParam As String) As Boolean
```

### Apartados dentro de la función

Las variables se declaran al principio de la función, no dentro de un `If`.

```gambas
Public Function NombreFuncion(sParam As String) As Boolean

  Dim sResultado As String

  ' --- 1. VALIDACIÓN DE ENTRADA ---
  If sParam = "" Then Return False

  ' --- 2. PROCESAMIENTO ---
  Try sResultado = OtraFuncion(sParam)
  If Error Then Return False

  Return True

End
```

### Manejo de errores

En Gambas, `Try` precede una sola línea. No existen bloques `Try/Catch/End`. El `Catch` va al final de la función y captura cualquier error no manejado:

```gambas
Public Function LeerArchivo(sRuta As String) As String

  Dim sContenido As String

  ' --- 1. LECTURA DEFENSIVA ---
  Try sContenido = File.Load(sRuta)
  If Error Then Return ""

  Return sContenido

Catch
  ' CAPTURA DE ERRORES NO PREVISTOS EN LA FUNCIÓN
  Message.Error("Error inesperado en LeerArchivo: " & Error.Text)
  Return ""

End
```

Gambas no es Visual Basic: la herencia se nota, pero las diferencias son justamente las que rompen el código (`ByRef`, `Const` local, `End Try`, la evaluación de `And` y `Or`, que no cortocircuita).

### Estilo general

- Nombres de funciones y procedimientos: **PascalCase**
- Variables privadas de módulo o clase: prefijo `$` (`$cTitulos`)
- Variables locales y parámetros: prefijo de tipo — `s` String, `i` Integer, `b` Boolean, `a` arreglo, `o` objeto, `h` handle, `r` Result
- Controles: prefijo del tipo de control — `txt`, `cmb`, `lst`, `btn`, `lbl`, `txa`, `hbx`, `vbx`, `hsp`. Si el control cambia de tipo, el nombre cambia con él
- Constantes: **MAYÚSCULAS_CON_GUIONES**
- Comentarios internos: siempre en MAYÚSCULAS, explicando el propósito y no la mecánica. Si una línea existe por una regla del proyecto, citarla
- Rutas siempre Unix
- Indentación: 2 espacios, sin tabs

Las reglas completas, con los comportamientos de Gambas verificados que las sostienen, están en el corpus normativo del proyecto (`docs/corpus.md`).

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

Para preguntas sobre contribuciones, abrí un **issue** en GitHub o escribí a [contacto@estudio2a.ar](mailto:contacto@estudio2a.ar).

---

**Copyright © 2026 Alberto Moyano**

Este documento está bajo Creative Commons CC0 1.0 Universal (Dominio Público).
