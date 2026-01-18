
# Guía de Contribución

## Bienvenida

Las contribuciones a gbpublisher son bienvenidas, especialmente de la comunidad académica y científica.

---

## Licenciamiento de Contribuciones

Al contribuir código a gbpublisher, aceptas que:

1. Tu contribución será licenciada bajo **Business Source License 1.1**, los mismos términos que el proyecto principal.

2. Tu contribución se convertirá automáticamente a **GPL-3.0** en la Fecha de Cambio (5 años desde la publicación de cada versión).

3. Retienes el copyright de tu contribución, pero otorgas al proyecto una licencia perpetua, mundial, no exclusiva, gratuita, libre de regalías e irrevocable para usar, reproducir, modificar, mostrar, distribuir y sublicenciar tu contribución como parte de gbpublisher.

---

## Acuerdo de Licencia de Contribuidor (CLA)

No requerimos un CLA formal, pero al enviar un pull request, confirmas que:

* Eres el autor original del código contribuido, o tienes el derecho legal de contribuirlo.
* Aceptas los términos de licenciamiento arriba mencionados.
* Tu contribución no infringe derechos de terceros.

---

## Tipos de Contribuciones Bienvenidas

### Código

* Corrección de errores
* Mejoras de rendimiento
* Nuevas funcionalidades alineadas con la arquitectura del proyecto
* Mejoras en la documentación del código

### Documentación

* Correcciones ortográficas y gramaticales
* Aclaraciones técnicas
* Ejemplos de uso
* Traducciones

### Reportes de Errores

* Descripción clara del problema
* Pasos para reproducir
* Comportamiento esperado vs. observado
* Versión de gbpublisher
* Sistema operativo y distribución Linux

---

## Proceso de Contribución

1. **Fork** el repositorio
2. Crea una **rama** con un nombre descriptivo (`fix/nombre-error` o `feature/nueva-funcionalidad`)
3. Realiza tus cambios siguiendo las convenciones del proyecto
4. **Documenta** tu código en MAYÚSCULAS (estilo gbpublisher)
5. **Prueba** tus cambios exhaustivamente
6. Envía un **pull request** con descripción clara

---

## Convenciones de Código

### Comentarios
```gambas
' ESTA ES LA DESCRIPCIÓN DE LA FUNCIÓN
' PARÁMETROS:
'   - param1: DESCRIPCIÓN
'   - param2: DESCRIPCIÓN
' RETORNA:
'   - TIPO Y DESCRIPCIÓN DEL VALOR DE RETORNO
Public Sub MiFuncion(param1 As String, param2 As Integer) As Boolean

End
```

### Estilo

* Nombres de funciones en **PascalCase**
* Variables locales en **camelCase**
* Constantes en **MAYÚSCULAS_CON_GUIONES**
* Indentación: 2 espacios (no tabs)

### Manejo de Errores
```gambas
Try
  ' CÓDIGO QUE PUEDE FALLAR
Catch
  ' MANEJO DE ERROR EXPLÍCITO
  Print "ERROR: " & Error.Text
  Return False
End
```

O con limpieza de recursos:
```gambas
Try
  ' CÓDIGO QUE PUEDE FALLAR
Catch
  ' MANEJO DE ERROR EXPLÍCITO
  Print "ERROR: " & Error.Text
  Return False
Finally
  ' LIMPIEZA DE RECURSOS
  If miArchivo Then miArchivo.Close()
End
```

---

## Qué NO Será Aceptado

* Código que viole la arquitectura del proyecto
* Dependencias innecesarias o propietarias
* Funcionalidades que comprometan la separación contenido/procesamiento
* Cambios que requieran plataformas distintas de Linux
* "Mejoras" que oculten procesos al usuario
* Automatismos que tomen decisiones editoriales implícitas

---

## Revisión de Código

Todas las contribuciones serán revisadas por el mantenedor del proyecto.

El proceso puede incluir:

* Solicitud de cambios
* Discusión sobre decisiones de diseño
* Pruebas adicionales
* Ajustes de documentación

La revisión busca mantener la coherencia arquitectónica y la calidad del código.

---

## Código de Conducta

* Respeto mutuo en todas las interacciones
* Críticas constructivas al código, no a las personas
* Enfoque en mejorar el proyecto
* Reconocimiento de que el tiempo de todos es valioso

---

## Reconocimiento

Los contribuidores serán reconocidos en el archivo `CONTRIBUTORS.md` (próximamente).

---

## Preguntas

Para preguntas sobre contribuciones, abre un **issue** en GitHub o contacta a:  estudio2a@outlook.com.ar

---

**Copyright © 2024-2026 Alberto Moyano**

Este documento está bajo Creative Commons CC0 1.0 Universal (Dominio Público).
