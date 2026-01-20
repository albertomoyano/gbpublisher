# Arquitectura de gbpublisher

## 1. Propósito de este documento

Este documento describe las **decisiones arquitectónicas** que estructuran gbpublisher: qué problemas aborda, qué problemas evita deliberadamente y bajo qué criterios técnicos y editoriales se organiza el sistema.

No es un manual de uso ni una especificación técnica exhaustiva, sino una explicación razonada del modelo de diseño que sustenta la aplicación.

---

## 2. Naturaleza de la aplicación

gbpublisher es una **aplicación editorial de escritorio**, concebida como:

* interfaz de trabajo para editores y correctores
* capa de control del flujo editorial
* orquestador de procesos especializados externos

No es un motor de cómputo intensivo ni un sistema monolítico. Su valor reside en **coordinar, validar y hacer visibles** los pasos del proceso editorial.

---

## 3. Elección de plataforma y lenguaje

### 3.1 Gambas como entorno de aplicación

La elección de Gambas responde a una decisión arquitectónica coherente con el tipo de aplicación y su público objetivo.

Gambas permite desarrollar aplicaciones gráficas de escritorio con:

* modelo de eventos claro
* relación directa entre interfaz y funcionalidad
* comportamiento previsible y estable

Desde una perspectiva editorial, Gambas está orientado a **aplicaciones de usuario final**, no a scripts invisibles ni servicios en segundo plano. Esto favorece interfaces claras, acciones explícitas y una curva de aprendizaje baja para usuarios no técnicos.

---

### 3.2 Por qué no Python como base principal

Python forma parte del ecosistema de herramientas utilizadas por gbpublisher, especialmente para tareas de procesamiento y transformación.

Sin embargo, como base principal de una aplicación editorial de escritorio, presenta limitaciones prácticas:

* fragmentación de frameworks gráficos
* dependencia de entornos virtuales
* dificultad para garantizar experiencias homogéneas a largo plazo

En esta arquitectura, Python cumple un rol complementario: **procesa**, mientras que la aplicación **coordina y presenta**.

---

### 3.3 Exclusividad de Linux como decisión consciente

gbpublisher se desarrolla exclusivamente para Linux como decisión técnica y conceptual.

Linux ofrece:

* integración nativa con herramientas científicas y editoriales
* entornos reproducibles y auditables
* una tradición sólida de separación entre contenido, procesos y presentación

Esta exclusividad no es una limitación, sino una forma de **simplificar la arquitectura**, reducir ambigüedades y garantizar consistencia en el comportamiento del sistema.

---

## 4. Modelo general de arquitectura

La arquitectura adopta un modelo en capas claramente diferenciadas:

1. **Contenido**
   Textos, metadatos y referencias en formatos abiertos y legibles.

2. **Procesamiento**
   Herramientas externas especializadas (XSLT, validadores, conversores, LaTeX).

3. **Interfaz y control**
   La aplicación de escritorio, que coordina acciones, presenta estados y expone resultados.

Este modelo evita acoplamientos innecesarios y permite sustituir herramientas sin afectar el contenido.

---

## 5. Integración con herramientas externas

gbpublisher **no incluye ni distribuye** las herramientas de procesamiento que utiliza.

En su lugar, **verifica la disponibilidad** de estas herramientas en el sistema del usuario y las **invoca mediante llamadas**.

Las herramientas externas típicamente utilizadas incluyen:

* `pandoc` — conversión de formatos de documento
* `xmllint` — validación de XML
* `xsltproc` — transformaciones XSLT
* `Saxon-HE` — procesamiento XSLT avanzado
* `LaTeX` — composición tipográfica
* Intérpretes de scripts: Python, Bash, Perl, Lua

### 5.1 Modelo de invocación

gbpublisher no utiliza librerías de Python, Bash, Perl ni Lua.

En su lugar, proporciona funciones que permiten a los usuarios:

* escribir sus propios scripts de procesamiento
* invocarlos mediante `Shell`, `Exec` o `gb.Term` desde la interfaz
* visualizar la salida en consola

Este modelo:

* no requiere instalación de dependencias por parte de gbpublisher
* delega la responsabilidad de las herramientas al usuario
* mantiene la aplicación liviana y sin acoplamientos

### 5.2 Verificación de dependencias

El script `verificar.sh` comprueba la disponibilidad de las herramientas externas esperadas, pero:

* **no instala software**
* **no modifica el sistema**
* solo genera un **informe** sobre el estado de las herramientas instaladas y/o faltantes
* este informe también se puede obtener desde aplicación

---

## 6. Rendimiento y modelo de ejecución

gbpublisher no está diseñado para realizar procesamiento pesado dentro del runtime de la aplicación.

El código propio se mantiene deliberadamente simple y se orienta a:

* responder de forma inmediata a la interacción del usuario
* gestionar estados editoriales
* coordinar procesos externos

El costo computacional dominante se encuentra en:

* ejecución de herramientas externas
* operaciones de E/S
* validación y transformación de documentos

En este contexto, el rendimiento del lenguaje o del runtime **no constituye un cuello de botella**. La claridad, mantenibilidad y previsibilidad tienen prioridad sobre la optimización prematura.

---

## 7. Separación entre contenido y procesamiento

Uno de los principios centrales de la arquitectura es la **separación estricta entre contenido y procesos**.

El contenido se mantiene independiente de:

* formatos de salida
* herramientas específicas
* decisiones de diseño visual

El procesamiento se aplica de forma explícita, controlada y reproducible.

Este enfoque permite:

* editar sin pensar en la salida final
* reutilizar contenido para múltiples formatos
* reducir errores derivados de ajustes manuales
* mantener coherencia editorial en el tiempo

Desde el punto de vista editorial, equivale a separar claramente **escritura y corrección** de **armado y composición**.

---

## 8. Trazabilidad

El formulario principal de la aplicación contiene una grilla como espacio visible de ejecución de procesos externos.

Esta decisión no responde a una limitación técnica, sino a un criterio de diseño orientado a la **transparencia**.

Cada acción relevante muestra:

* qué herramienta se ejecuta
* con qué parámetros
* en qué orden
* y qué salida produce

Esta grilla cumple un rol similar al de un informe de preimpresión: no es el espacio principal de trabajo, pero sí el lugar donde se verifica que el proceso es correcto, auditable y comprensible.

---

## 9. Filosofía de diseño: una función, una tarea

El desarrollo se apoya explícitamente en la **filosofía UNIX**:

> cada función hace una sola cosa, la hace bien y no falla.

Este principio se traduce en:

* funciones pequeñas y acotadas
* acciones claramente delimitadas
* ausencia de automatismos implícitos

Desde el punto de vista del usuario, esto se refleja en una interfaz que no sorprende ni oculta estados.

---

## 10. Interfaces claras y ayuda contextual

La interfaz es consecuencia directa del modelo de funciones simples.

En cada formulario, cada componente:

* tiene un rol único
* espera un tipo de información explícito
* produce un efecto previsible

La aplicación incorpora **ayuda contextual** inspirada en las `man pages` de UNIX: información breve, localizada y orientada a la tarea concreta, accesible sin abandonar el flujo de trabajo, respetando el principio de que

> El sistema debe documentarse a sí mismo.

---

## 11. Coherencia con el flujo editorial

La arquitectura está alineada con prácticas editoriales profesionales, donde:

* la claridad reduce errores
* la previsibilidad genera confianza
* los procesos deben ser repetibles y auditables

La aplicación no reemplaza el criterio editorial: lo acompaña, haciendo visibles los pasos y reduciendo la fricción cognitiva.

---

## 12. Qué NO hace la aplicación

* La aplicación no adivina
* No tiene una bola mágica
* No interpreta intenciones
* No completa información implícita
* No toma decisiones editoriales por el usuario

Este enfoque evita:

* comportamientos imprevisibles
* correcciones automáticas opacas
* decisiones difíciles de auditar

La ausencia de **inteligencia implícita** no es una carencia, sino una garantía: lo que ocurre en el sistema es siempre visible, comprensible y reproducible.

---

## 13. Licencia y sostenibilidad del proyecto

gbpublisher está licenciado bajo **Business Source License 1.1**, una licencia de código fuente disponible con restricciones de uso comercial durante un período definido.

Esta decisión arquitectónica responde a:

* **Sostenibilidad**: proteger el esfuerzo de desarrollo de apropiación comercial no autorizada
* **Transparencia**: mantener el código accesible para auditoría y contribuciones
* **Transición futura**: garantizar que el software será completamente libre tras el período de protección

La licencia BSL 1.1:

* permite el uso académico sin costo
* restringe el uso comercial durante 5 años
* convierte automáticamente el código a GPL-3.0 tras ese período

Este modelo alinea los intereses de la comunidad académica con la viabilidad del proyecto a largo plazo.

---

## 14. Cierre

gbpublisher se apoya en decisiones arquitectónicas conservadoras, explícitas y alineadas con el trabajo editorial real.

La prioridad no es la complejidad técnica ni la automatización extrema, sino la **comprensión del proceso**, la estabilidad del contenido y el control consciente del flujo editorial.

---

**Copyright © 2024-2026 Alberto Moyano**

Licenciado bajo Business Source License 1.1
