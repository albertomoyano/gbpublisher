# gbpublisher

## Introducción

**gbpublisher** es una plataforma integral de producción editorial académica, diseñada para revistas científicas, series académicas y proyectos editoriales institucionales.

Está pensada para entornos universitarios y científicos que requieren **estandarización, reproducibilidad y soberanía tecnológica**, sin depender de plataformas propietarias ni servicios externos.

gbpublisher implementa un flujo de trabajo **XML-first**, basado en estándares abiertos ampliamente adoptados en el ecosistema académico internacional: Markdown, bases de datos SQL, JATS XML, XSLT y LaTeX.

---

## Modelo de producción XML-first

En gbpublisher, cada artículo se transforma en un **JATS maestro validado**, que actúa como fuente única y autoritativa para todas las salidas editoriales posteriores.

Este enfoque garantiza:

* cumplimiento de estándares internacionales (JATS, PubMed, SciELO, Crossref)
* portabilidad total de los contenidos
* independencia de proveedores externos
* trazabilidad y auditoría del proceso editorial
* reproducibilidad en entornos académicos

---

## Flujo editorial completo

gbpublisher unifica en una única aplicación de escritorio (Gambas sobre Linux) todo el proceso editorial:

### Gestión de metadatos (base de datos SQL)

* autores y afiliaciones
* referencias bibliográficas
* palabras clave
* información institucional
* datos para indexadores
* órdenes de taller y control editorial

### Edición basada en Markdown

El contenido se redacta y mantiene en archivos Markdown estructurados, facilitando:

* escritura y corrección
* control de versiones
* independencia del formato final

### Generación y validación del JATS maestro

* generación reproducible
* validación con `xmllint`
* control de versiones y consistencia estructural

### Transformación a múltiples salidas mediante XSLT

* SciELO (por colección)
* PubMed / PMC
* Crossref Journal Metadata Deposit XML
* XML para flujos con InDesign
* HTML académico
* EPUB accesible

### Generación de PDF de alta calidad

* composición con LaTeX
* control tipográfico profesional
* compatibilidad con PDF/A

---

## Calidad editorial y validación

Cada salida generada por gbpublisher pasa por procesos de validación formal:

* JATS maestro: validación estándar
* salidas específicas: validación por flavor
* PDF: reproducibilidad garantizada
* HTML y EPUB: estructura semántica consistente

Este modelo reduce errores, mejora la calidad editorial y acelera los procesos de indexación.

---

## Licencia y modelo de uso

**gbpublisher** está disponible bajo la **Business Source License 1.1 (BSL)**.

Esta licencia permite el acceso al código fuente mientras protege el modelo de desarrollo sostenible del proyecto.

### Uso permitido sin costo de licencia

El uso de gbpublisher **no requiere pago de licencia** para:

* instituciones académicas y científicas sin fines de lucro
* universidades y bibliotecas en su función académica
* revistas académicas de acceso abierto o con modelo institucional
* proyectos editoriales institucionales sin intermediación comercial
* uso interno para investigación y docencia

### Uso que requiere licencia comercial

El uso de gbpublisher **requiere acuerdo comercial explícito** para:

* empresas editoriales con fines de lucro
* plataformas SaaS de servicios editoriales
* proveedores de servicios editoriales externos a instituciones
* redistribución del software con fines comerciales
* uso del software como parte de servicios facturados a terceros
* integración en productos comerciales

### Casos especiales

Los siguientes casos requieren consulta previa con el autor:

* editoriales universitarias con modelo híbrido (comercial/académico)
* revistas con APCs (Article Processing Charges) administradas institucionalmente
* consorcios interinstitucionales con participación mixta
* proyectos de cooperación público-privada

Para estos casos, contactar a: estudio2a@outlook.com.ar

### Transición futura a licencia permisiva

Conforme al modelo BSL 1.1, el código de gbpublisher pasará automáticamente a **licencia GPL-3.0** transcurridos **10 años** desde la fecha de publicación de cada versión.

Esto garantiza que, a largo plazo, el software será completamente libre, protegiendo el interés académico mientras se preserva un modelo de desarrollo sostenible durante el período inicial.

---

## Filosofía del proyecto

gbpublisher prioriza:

* estándares abiertos
* procesos explícitos y auditables
* separación entre contenido y procesamiento
* estabilidad a largo plazo
* claridad editorial por sobre automatismos opacos

La aplicación no toma decisiones editoriales por el usuario.
No adivina. No oculta procesos. No impone formatos.

---

## gbpublisher y la ciencia abierta

gbpublisher se alinea con los principios de:

* acceso abierto
* interoperabilidad
* reproducibilidad
* transparencia
* soberanía tecnológica

Es una herramienta pensada para instituciones públicas, universidades y proyectos editoriales comprometidos con el conocimiento como bien común.

---

## Software de código abierto, no software libre sin restricciones

gbpublisher hace su código fuente **disponible públicamente** bajo Business Source License 1.1.

Esto significa:

* El código puede ser inspeccionado, estudiado y auditado
* Las instituciones académicas pueden usarlo sin costo
* El desarrollo es transparente y trazable
* Las contribuciones son bienvenidas bajo las condiciones establecidas

Sin embargo, **no es software libre** en el sentido de licencias como GPL, MIT o Apache durante el período inicial de 5 años.

La restricción de uso comercial garantiza que el esfuerzo de desarrollo no sea apropiado por actores comerciales sin retribución al proyecto.

---

## Conclusión

gbpublisher no es solo una herramienta, sino un **ecosistema editorial académico**, diseñado para producir contenidos de calidad profesional de forma abierta, controlada y sostenible.

Permite a universidades y revistas científicas trabajar con estándares internacionales sin depender de plataformas propietarias ni servicios externos, manteniendo el control total sobre sus datos y procesos.

---

**Copyright © 2024-2026 Alberto Moyano**

Licenciado bajo Business Source License 1.1
Repositorio: https://github.com/albertomoyano/gbpublisher
Consultas sobre licenciamiento: alberto.alejandro.moyano@gmail.com
