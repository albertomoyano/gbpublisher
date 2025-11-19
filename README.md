# Acerca de este proyecto

## Introducción

gbpublisher es una plataforma integral de **producción editorial académica**, diseñada específicamente para revistas científicas, series académicas y proyectos editoriales institucionales. Desarrollada íntegramente en **software libre**, gbpublisher ofrece un flujo de trabajo moderno, reproducible y estandarizado, basado en **Markdown, motor de base de datos SQL, JATS XML, XSLT, LaTeX** y otras tecnologías abiertas ampliamente adoptadas en el ecosistema científico internacional.

## Un modelo de producción XML-first con soberanía tecnológica

A diferencia de las soluciones comerciales cerradas, gbpublisher se sustenta en un flujo XML-first, donde cada artículo se transforma en un **JATS maestro validado**, que luego sirve como fuente única y autoritativa para todas las salidas editoriales posteriores. Este enfoque garantiza:

- Estándares internacionales (JATS, PubMed, SciELO, Crossref)
- Total portabilidad
- Independencia de proveedores externos
- Transparencia en cada fase del proceso
- Reproducibilidad y auditoría en ambiente académico

## 100% Software Libre y multiplataforma Linux

gbpublisher se distribuye con licencia Creative Commons, permitiendo:

- Revisar el código
- Auditar procesos
- Adaptar flujos editoriales
- Extender funcionalidades
- Integrarse con infraestructura institucional existente

Es una solución pensada para universidades y bibliotecas que buscan soberanía tecnológica, control interno y sustentabilidad a largo plazo.

## Flujo editorial completo

gbpublisher unifica en una sola herramienta de escritorio (Gambas/Linux) la gestión de todo el proceso editorial:

### Gestión de metadatos (ABM en MySQL)

- Autores/as
- Afiliaciones
- Referencias
- Siglas
- Ordenes de taller
- Palabras clave
- Información institucional
- Datos para indexadores

### Edición basada en Markdown

El contenido se procesa a partir de archivos **Markdown estructurados**, simplificando la escritura, revisiones y control de cambios.

### Generación automática del JATS maestro

- Validación con xmllint
- Generación reproducible
- Registro de versiones

### Transformación a múltiples salidas mediante XSLT

- SciELO (formatos por colección)
- PubMed/PMC
- Crossref Journal Metadata Deposit XML
- XML para InDesign
- HTML académico
- EPUB accesible

### Generación de PDF de alta calidad

- Compuesto con LaTeX
- Control tipográfico profesional
- Compatible con PDF/A

### Validación rigurosa y calidad editorial garantizada

Cada salida generada por **gbpublisher** pasa por un proceso de validación formal:

- **JATS maestro**: validación estándar W3C con xmllint
- **Flavors**: validación de conformidad según el estándar específico (SciELO, PubMed, Crossref)
- **PDF**: reproducibilidad garantizada
- **EPUB/HTML**: estructura semántica consistente

Este modelo reduce errores, mejora la calidad editorial y acelera el proceso de indexación.

### Beneficios para instituciones académicas

- **Costos reducidos**

El software libre elimina licencias costosas y evita depender de servicios externos.

- **Control interno del proceso editorial**

La editorial o revista mantiene la propiedad total de los datos y del flujo de producción.

- **Cumplimiento con indexadores y estándares internacionales**

Listo para SciELO, Latindex, DOAJ, RedALyC, PubMed, Crossref y repositorios institucionales.

- **Sustentabilidad a largo plazo**

Al usar estándares abiertos, los documentos generados seguirán siendo utilizables y migrables dentro de 10, 20 o 30 años.

- **Flexibilidad total en personalización**

Las transformaciones XSLT pueden adaptarse a cualquier necesidad:
nuevas indexaciones, estructura local, políticas de publicación, diseño, etc.

### ¿Por qué gbpublisher es único en Iberoamérica?

- No depende de Word ni de InDesign

(bases hegemónicas del mercado)

- No es SaaS ni envía datos a terceros

(se aloja y ejecuta en la institución)

- No encierra información en formatos propietarios

(todo es abierto XML/Markdown/SQL)

- Ofrece multi-output profesional desde una única fuente
- Pensado especialmente para editoriales universitarias
- 100% Linux, estable, reproducible y transparente

En la región no existe otra herramienta con este modelo técnico, con este nivel de integración, y completamente libre.

### gbpublisher en el ecosistema de ciencia abierta

**gbpublisher** se alinea con los principios de:

- Acceso abierto
- Reproducibilidad
- Interoperabilidad
- Transparencia
- Soberanía tecnológica
- Infraestructura abierta

Esto lo convierte en una opción ideal para instituciones públicas e iniciativas editoriales con enfoque social.

## Conclusión

**gbpublisher** es más que una herramienta: es un ecosistema editorial completo, abierto, validado, reproducible y adaptado al contexto académico.

Permite a universidades y revistas científicas producir contenidos de calidad profesional sin depender de servicios costosos ni plataformas propietarias, garantizando independencia y estandarización total.
