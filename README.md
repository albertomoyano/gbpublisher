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

El código fuente de gbpublisher está disponible bajo la **Business Source License 1.1 (BSL)**.

### Uso permitido sin costo

* instituciones académicas y científicas
* universidades y bibliotecas
* revistas académicas sin fines comerciales
* proyectos editoriales institucionales

### Uso comercial

El uso comercial **no está permitido sin acuerdo explícito** con el autor.

Esto incluye:

* prestación de servicios editoriales a terceros
* integración en plataformas comerciales
* SaaS o servicios alojados
* redistribución con fines de lucro

Para licencias comerciales, contactar al autor.

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

## Conclusión

gbpublisher no es solo una herramienta, sino un **ecosistema editorial académico**, diseñado para producir contenidos de calidad profesional de forma abierta, controlada y sostenible.

Permite a universidades y revistas científicas trabajar con estándares internacionales sin depender de plataformas propietarias ni servicios externos, manteniendo el control total sobre sus datos y procesos.
