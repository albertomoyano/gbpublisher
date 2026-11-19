# Arquitectura de gbpublisher

## Propósito de este documento

Este documento describe las decisiones arquitectónicas que estructuran gbpublisher: qué problemas aborda, qué problemas evita deliberadamente y bajo qué criterios técnicos y editoriales se organiza el sistema.

No es un manual de uso ni una especificación técnica exhaustiva, sino una explicación razonada del modelo de diseño que sustenta la aplicación.

---

## Naturaleza de la aplicación

gbpublisher es una aplicación editorial de escritorio concebida como interfaz de trabajo para editores y correctores, capa de control del flujo editorial y orquestador de procesos especializados externos.

No es un motor de cómputo intensivo ni un sistema monolítico. Su valor reside en coordinar, validar y hacer visibles los pasos del proceso editorial.

---

## Elección de plataforma y lenguaje

### Gambas como entorno de aplicación

La elección de Gambas responde a una decisión arquitectónica coherente con el tipo de aplicación y su público objetivo.

Gambas permite desarrollar aplicaciones gráficas de escritorio con modelo de eventos claro, relación directa entre interfaz y funcionalidad, y comportamiento previsible y estable. Está orientado a aplicaciones de usuario final, no a scripts invisibles ni servicios en segundo plano. Esto favorece interfaces claras, acciones explícitas y una curva de aprendizaje baja para usuarios no técnicos.

El toolkit gráfico utilizado es `gb.qt6`, sobre Gambas 3.22. Esta elección no es intercambiable: `gb.gtk` y otras variantes presentan diferencias de comportamiento en campos de texto con acentos y acelerados de teclado que afectan la experiencia de edición en español y portugués.

### Por qué no Python como base principal

Python forma parte del ecosistema de herramientas utilizadas por gbpublisher, especialmente para tareas de procesamiento y transformación. Sin embargo, como base principal de una aplicación editorial de escritorio presenta limitaciones prácticas: fragmentación de frameworks gráficos, dependencia de entornos virtuales y dificultad para garantizar experiencias homogéneas a largo plazo.

En esta arquitectura, Python cumple un rol complementario: procesa, mientras que la aplicación coordina y presenta.

### Linux como decisión consciente

gbpublisher se desarrolla exclusivamente para Linux Mint con escritorio Cinnamon. Esta exclusividad no es una limitación sino una forma de simplificar la arquitectura, reducir ambigüedades y garantizar consistencia en el comportamiento del sistema.

Linux ofrece integración nativa con herramientas científicas y editoriales, entornos reproducibles y auditables, y una tradición sólida de separación entre contenido, procesos y presentación. La plataforma soportada requiere servidor de pantalla X11: la aplicación no es compatible con Wayland.

---

## Modelo general de arquitectura

La arquitectura adopta un modelo en tres capas claramente diferenciadas:

1. **Contenido.** Textos, metadatos y referencias en formatos abiertos y legibles: Markdown, XML JATS (revistas), DocBook (libros), BibTeX.
2. **Procesamiento.** Herramientas externas especializadas que transforman y validan el contenido: XSLT, validadores, conversores, LaTeX.
3. **Interfaz y control.** La aplicación de escritorio, que coordina acciones, presenta estados y expone resultados.

La separación estricta entre estas capas es el principio central del diseño. El contenido se mantiene independiente de los formatos de salida, las herramientas específicas y las decisiones de diseño visual. El procesamiento se aplica de forma explícita, controlada y reproducible. Este enfoque permite sustituir herramientas sin afectar el contenido, editar sin pensar en la salida final y mantener coherencia editorial en el tiempo.

Desde el punto de vista editorial, equivale a separar claramente escritura y corrección de armado y composición.

---

## Integración con herramientas externas

gbpublisher no reimplementa las herramientas de procesamiento que utiliza: las invoca mediante llamadas al sistema operativo. Pero no todas se tratan igual.

**Herramientas fijadas.** Las que deciden el resultado de una salida, o su validez, se instalan en una versión fija en `/opt`, con su suma de verificación, y la aplicación usa siempre esa copia:

- `pandoc` 3.1.3 — conversión de Markdown a XML canónico
- `Saxon-HE` 12.9 — procesamiento XSLT 2.0
- `epubcheck` 4.2.6 — validación de EPUB
- `veraPDF` 1.30.1 — validación de PDF/A
- `packtools` 4.18.2 — validación de paquetes SciELO
- `vnu` 26.7.3 (Nu Html Checker) — validación de HTML5; sin él, el HTML no se genera

El canónico se regenera muchas veces durante la edición, y una versión distinta de una de estas herramientas puede producir otro XML u otro veredicto. Fijarlas es lo que permite regenerar un título idéntico años después.

**Herramientas del sistema.** Las que mantienen compatibilidad hacia atrás se toman de la distribución: `LuaLaTeX` y TeX Live, `xmllint`, Java. Fijarlas no aportaría reproducibilidad y sí un costo de mantenimiento.

### Scripts del sistema y scripts del usuario

gbpublisher incluye scripts propios de sistema, escritos en Bash y Python, que forman parte del flujo de producción interno. Estos scripts se instalan junto con la aplicación y son invocados por ella en pasos específicos del proceso editorial.

Adicionalmente, la aplicación expone una interfaz que permite al usuario escribir y ejecutar sus propios scripts de procesamiento, visualizando la salida en consola. Este mecanismo no requiere modificar la aplicación ni instalar dependencias adicionales.

### Integridad del sistema

El script `integridad.sh` controla las herramientas externas y repara las fijadas: si falta una, o no es la versión esperada, la descarga, comprueba su suma de verificación y la instala en `/opt`. Pide la contraseña de administrador en una ventana. Se lanza desde la aplicación (menú **Acerca de → Controlar integridad del sistema**, con un proyecto abierto) y muestra su avance en la terminal embebida, con mensajes pensados para quien no lee la consola. No corre al arrancar: es una herramienta de control en manos del usuario.

---

## Rendimiento y modelo de ejecución

gbpublisher no está diseñado para realizar procesamiento pesado dentro de su propio runtime. El código propio se mantiene deliberadamente simple y se orienta a responder de forma inmediata a la interacción del usuario, gestionar estados editoriales y coordinar procesos externos.

El costo computacional dominante se encuentra en la ejecución de herramientas externas, las operaciones de entrada/salida y la validación y transformación de documentos. En este contexto, el rendimiento del lenguaje o del runtime no constituye un cuello de botella. La claridad, mantenibilidad y previsibilidad tienen prioridad sobre la optimización prematura.

---

## Trazabilidad y transparencia

El formulario principal de la aplicación contiene una terminal embebida como espacio visible de ejecución de procesos externos. Esta decisión responde a un criterio de diseño orientado a la transparencia, no a una limitación técnica.

Cada acción relevante muestra qué herramienta se ejecuta, con qué parámetros, en qué orden y qué salida produce. Este registro cumple un rol similar al de un informe de preimpresión: no es el espacio principal de trabajo, pero sí el lugar donde se verifica que el proceso es correcto, auditable y comprensible.

---

## Filosofía de diseño

El desarrollo se apoya explícitamente en la filosofía UNIX: cada función hace una sola cosa, la hace bien y produce un resultado predecible. Este principio se traduce en funciones pequeñas y acotadas, acciones claramente delimitadas y ausencia de automatismos implícitos.

En cada formulario, cada componente tiene un rol único, espera un tipo de información explícito y produce un efecto previsible. La aplicación no adivina, no interpreta intenciones, no completa información implícita y no toma decisiones editoriales por el usuario.

La ausencia de inteligencia implícita no es una carencia sino una garantía: lo que ocurre en el sistema es siempre visible, comprensible y reproducible. La aplicación no reemplaza el criterio editorial: lo acompaña, haciendo visibles los pasos y reduciendo la fricción cognitiva.

### Ayuda contextual

La aplicación incorpora ayuda contextual inspirada en las `man pages` de UNIX: información breve, localizada y orientada a la tarea concreta, accesible sin abandonar el flujo de trabajo. El sistema se documenta a sí mismo.

---

## Coherencia con el flujo editorial

La arquitectura está alineada con prácticas editoriales profesionales donde la claridad reduce errores, la previsibilidad genera confianza y los procesos deben ser repetibles y auditables.

Cada salida generada por gbpublisher pasa por procesos de validación formal. El canónico se valida contra su esquema (RNG y DTD de JATS, o RNG de DocBook) y contra reglas Schematron: las propias del proyecto y, en revistas, las de JATS4R. Las salidas para indexadores se validan con el esquema de cada destino. El EPUB pasa por epubcheck, el PDF/A por veraPDF y el HTML por el Nu Html Checker. El PDF garantiza reproducibilidad tipográfica; el HTML y el EPUB mantienen estructura semántica consistente.

---

**Copyright © 2026 Alberto Moyano**

Licenciado bajo Business Source License 1.1 — véase [LICENSE.md](LICENSE.md)
