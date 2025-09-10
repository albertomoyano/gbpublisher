---
layout: default
title: Manifiesto técnico
parent: Manual
---

# Manifiesto técnico

## Por qué una aplicación de escritorio. Contexto del proyecto

Este software fue desarrollado para asistir en la edición técnica y académica de libros y revistas científicas. El dominio de trabajo requiere:

- Precisión en el marcado estructural de los textos.
- Flujo editorial controlado.
- Exportación en formatos académicos como ePub, PDF, HTML y XML.
- Integración con una base de datos para trazabilidad, metadatos y automatización.

## Decisión arquitectónica

La aplicación está desarrollada como **software de escritorio en GNU/Linux**, específicamente diseñada para funcionar bajo entornos **Debian + GTK**, utilizando:

- **Gambas** como entorno de desarrollo.
- **SQLite** como base de datos.
- **Markdown** y **LaTeX** como formatos base.
- **Herramientas del sistema GNU/Linux** para procesamiento.
- **Scripts en Python, Lua y Bash** cuando resultan más eficaces o rápidos que una implementación nativa.

## La aplicación como orquestador de flujos

Más que una herramienta monolítica, esta aplicación cumple el rol de un **coordinador de flujos de trabajo**. Orquesta la ejecución de scripts, gestiona documentos, integra bases de datos, captura y muestra resultados de consola en tiempo real. Este enfoque modular permite:

- Reutilizar herramientas existentes (Pandoc, LaTeX, etc.).
- Integrar scripts en distintos lenguajes (Python, Lua, Bash).
- Extender capacidades sin reescribir componentes ya probados.

Gambas resulta ideal para este tipo de arquitectura: su integración con el entorno gráfico y los recursos del sistema permiten desarrollar de forma productiva y eficaz.

## Valor estratégico de Gambas

Algunos componentes del entorno Gambas, como `gb.term`, son difíciles de replicar con el mismo nivel de integración en otras plataformas. La posibilidad de embebido de consola, manipulación directa de archivos, ventanas modales simples y control total del sistema convierten a Gambas en una opción subestimada pero poderosa para el desarrollo de herramientas técnicas en GNU/Linux.

## Razones para no hacer una versión web

### 1. El trabajo editorial es de escritorio

La edición científica implica documentos largos, estructurados, con marcado semántico y control tipográfico. Este trabajo no se puede realizar eficazmente desde navegadores, móviles o tablets.

### 2. Precisión técnica y control del entorno

El sistema requiere integración con herramientas de consola, ejecución de comandos locales, rutas de archivos, versiones específicas de paquetes y scripts. Un entorno controlado (Debian + GTK) evita inconsistencias.

### 3. Seguridad y confidencialidad

El proceso editorial se realiza offline o en red local, sin exposición en la web. Esto evita fugas de información o accesos no autorizados.

### 4. Alto rendimiento sin sobrecarga

Al ser una aplicación nativa no depende de navegadores ni intérpretes web. Esto garantiza velocidad, bajo uso de memoria y estabilidad en hardware modesto.

### 5. Estándares abiertos y editables

El uso de texto plano (LaTeX, Markdown) garantiza trazabilidad, edición con cualquier editor y control con herramientas estándar (grep, diff, git, etc.).

## Contra la percepción de obsolescencia

No todas las soluciones deben ser web. Las apps de escritorio siguen siendo el estándar en:

- Edición profesional (InDesign, QuarkXpress, etc.).
- Programación (IDEs).
- Sistemas cerrados o de misión crítica.

Este proyecto no busca seguir modas tecnológicas, sino resolver problemas reales con eficiencia, robustez y apertura.

## Conclusión

En un mundo donde muchas herramientas privilegian la estética y la ubicuidad sobre la eficiencia y el control, esta aplicación apuesta por un entorno productivo, reproducible y auditable. Se privilegia la integración profunda con el sistema operativo GNU/Linux y las herramientas existentes, con una arquitectura que no impone su lógica, sino que **coordina inteligentemente los recursos del sistema y del usuario**.
