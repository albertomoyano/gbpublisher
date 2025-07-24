# Manifiesto técnico: Por qué una aplicación de escritorio

## Contexto del proyecto

Este software fue desarrollado para asistir en la edición técnica y académica de libros y revistas científicas. El dominio de trabajo requiere:

- Precisión en el marcado estructural de los textos.
- Flujo editorial controlado.
- Exportación en formatos académicos como PDF, XML (TEI, JATS, DocBook) y otros.
- Integración con bases de datos para trazabilidad, metadatos y automatización.

## Decisión arquitectónica

La aplicación está desarrollada como **software de escritorio en Linux**, específicamente diseñada para funcionar bajo entornos **Debian + KDE**, utilizando:

- **Gambas** como entorno de desarrollo.
- **MySQL** como base de datos.
- **LaTeX** como formato de texto base.
- Herramientas del sistema (Bash, Pandoc, LuaLaTeX, etc.) para procesamiento.

## Razones para no hacer una versión web

### 1. El trabajo editorial es de escritorio

La edición científica implica documentos largos, estructurados, con marcado semántico y control tipográfico. Este trabajo no se puede realizar eficazmente desde navegadores, móviles o tablets.

### 2. Precisión técnica y control del entorno

El sistema requiere integración con herramientas de consola, ejecución de comandos locales, rutas de archivos, versiones específicas de paquetes y scripts. Un entorno controlado (Debian + KDE) evita inconsistencias.

### 3. Seguridad y confidencialidad

El proceso editorial se realiza offline o en red local, sin exposición en la web. Esto evita fugas de información o accesos no autorizados.

### 4. Alto rendimiento sin sobrecarga

Al ser una app nativa, no depende de navegadores ni intérpretes web. Esto garantiza velocidad, bajo uso de memoria y estabilidad en hardware modesto.

### 5. Estándares abiertos y editables

El uso de texto plano (LaTeX) garantiza trazabilidad, edición con cualquier editor y control con herramientas estándar (grep, diff, git, etc.).

## Sobre la percepción de "obsolescencia"

No todas las soluciones deben ser web. Las apps de escritorio siguen siendo el estándar en:

- Edición profesional (DTP, InDesign, etc.)
- Programación (IDEs)
- Producción científica
- Sistemas cerrados o de misión crítica

Este proyecto no busca seguir modas tecnológicas, sino resolver problemas reales con eficiencia, robustez y apertura.
