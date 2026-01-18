# Arquitectura de gbpublisher

## Principios de diseño

gbpublisher fue concebido bajo una serie de principios técnicos y conceptuales claros:

* **XML-first** como modelo editorial
* Separación estricta entre contenido, estructura y presentación
* Reproducibilidad total del proceso
* Transparencia y auditabilidad
* Uso exclusivo de estándares abiertos
* Soberanía tecnológica institucional

---

## Modelo XML-first

El núcleo de gbpublisher es un **JATS maestro canónico**, validado y versionado, que actúa como fuente única y autoritativa.

Este enfoque permite:

* Evitar duplicación de fuentes
* Generar múltiples salidas coherentes
* Auditar cada transformación
* Adaptarse a nuevos estándares sin reescritura de contenidos

---

## Flujo técnico simplificado

1. Contenidos en Markdown estructurado
2. Metadatos almacenados en base de datos SQL
3. Generación del JATS maestro
4. Validación formal del XML
5. Transformaciones XSLT a distintos flavors
6. Producción de salidas finales (XML, HTML, EPUB, PDF)

Cada etapa es explícita, documentada y repetible.

---

## ¿Por qué Gambas?

La elección de **Gambas** no es circunstancial ni ideológica, sino técnica:

* Lenguaje compilado y eficiente
* Orientado a aplicaciones de escritorio complejas
* Integración nativa con bases de datos
* Excelente manejo de procesos externos (xmllint, LaTeX, XSLT)
* Curva de mantenimiento baja para proyectos institucionales
* Código legible y estable a largo plazo

A diferencia de entornos scripting más generales, Gambas permite construir una **aplicación editorial robusta**, con interfaz clara y control total del flujo.

---

## ¿Por qué no Python (u otros lenguajes)?

Python es excelente para scripting, prototipado y servicios, pero presenta limitaciones para este tipo de aplicación:

* Dependencia de entornos virtuales
* Fragmentación de toolkits gráficos
* Menor previsibilidad en despliegues institucionales
* Mayor complejidad de mantenimiento a largo plazo

gbpublisher prioriza **estabilidad, previsibilidad y longevidad**, por sobre la moda tecnológica.

---

## ¿Por qué Linux?

gbpublisher es **100% Linux** por razones técnicas y editoriales:

* Entorno natural para herramientas como LaTeX, xmllint y XSLT
* Automatización y scripting robustos
* Estabilidad comprobada en entornos académicos
* Ausencia de dependencias comerciales del sistema operativo
* Reproducibilidad real de builds y salidas

La aplicación no es multiplataforma por decisión consciente: prioriza coherencia técnica y control del entorno.

---

## ¿Qué no hace gbpublisher?

* No adivina metadatos
* No corrige errores conceptuales de los autores
* No reemplaza el criterio editorial
* No tiene una bola mágica

gbpublisher **automatiza procesos**, no sustituye decisiones académicas ni editoriales.

---

## Seguridad, control y soberanía

* No es SaaS
* No envía datos a terceros
* No encierra información en formatos propietarios
* Todo el procesamiento ocurre dentro de la institución

---

## En síntesis

La arquitectura de gbpublisher está diseñada para:

* Resistir el paso del tiempo
* Facilitar auditorías académicas
* Adaptarse a nuevos estándares
* Mantener independencia tecnológica real

Es una infraestructura editorial, no una aplicación efímera.

