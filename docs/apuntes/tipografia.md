---
layout: default
title: Tipografía en LaTeX
parent: Apuntes
---

# Tipografía en LaTeX y libros científicos

## Introducción
La tipografía constituye un elemento decisivo en la calidad de un libro o artículo científico. No solo incide en la legibilidad y la claridad del texto, sino también en la coherencia visual de una colección editorial y en la correcta representación de símbolos especializados. En publicaciones académicas —ya sean **revistas científicas** o **libros de investigación**— existe una necesidad de equilibrar la **precisión técnica** con la **estética visual** del documento.

Así como los filólogos son extremadamente rigurosos con la correcta colocación de diacríticos y acentos, los autores de matemáticas, química, física o lingüística requieren una exactitud absoluta en la representación de fórmulas, ecuaciones y notaciones. Este nivel de detalle puede perderse en el flujo de trabajo del diseño gráfico convencional, ya que los profesionales de DTP (Desktop Publishing) no siempre están especializados en las particularidades de cada disciplina científica. Por ello, seleccionar fuentes adecuadas y motores tipográficos compatibles con Unicode y OpenType es fundamental para mantener la **fidelidad del contenido técnico** sin sacrificar la presentación visual.

En este documento se analizan los principales formatos tipográficos compatibles con LaTeX, los criterios técnicos de selección de fuentes y las recomendaciones prácticas para editores y autores académicos.

## Relevancia del soporte Unicode
La transición desde codificaciones limitadas como ASCII hacia Unicode marcó un cambio fundamental en la composición tipográfica. Unicode permite representar en un mismo documento múltiples alfabetos, caracteres científicos, símbolos técnicos y escrituras complejas (griego, cirílico, CJK, IPA).
Los motores **XeLaTeX** y **LuaLaTeX** ofrecen soporte nativo para Unicode y acceso directo a fuentes del sistema, lo que los convierte en la opción preferida para proyectos multilingües y científicos.

## Formatos de fuentes en LaTeX
Históricamente, LaTeX se apoyó en distintos formatos de fuentes:

- **Type 1 (PostScript Type 1)**: estándar profesional en los 80–90, con alta calidad en impresión pero soporte limitado para Unicode.
- **Type 3**: ofrecía efectos gráficos avanzados, pero resultaba poco escalable y con baja compatibilidad. Hoy está en desuso.
- **TrueType (TTF)**: creado por Apple y Microsoft, ampliamente soportado en sistemas operativos modernos, con compatibilidad básica con Unicode. Menos preciso que OpenType en tipografía avanzada.
- **OpenType (OTF)**: evolución de TrueType, con soporte integral para Unicode, ligaduras, kerning y variantes estilísticas. Actualmente es el estándar de facto para la edición científica y profesional.

**Conclusión parcial:** en la práctica editorial académica, OpenType en combinación con LuaLaTeX es la opción más robusta y versátil.

## Criterios de selección de tipografía en libros científicos

### 3.1 Legibilidad y lectura prolongada
- Diferenciación clara entre caracteres similares (`I/l`, `0/O`).
- Buena altura de x y espaciado equilibrado.
- Preferencia por fuentes serif para impresión (*Libertinus*, *STIX Two*), y sans-serif en digital de baja resolución (*Noto Sans*).

### 3.2 Cobertura de glifos y soporte multilingüe
- Repertorio amplio (miles de glifos) para cubrir latín extendido, griego, cirílico, IPA, matemáticas avanzadas y CJK.
- Soporte actualizado de Unicode (15.0+).
- Ejemplos de fuentes: *Noto Serif* (cobertura pan-Unicode), *Libertinus* (equilibrio en latín y matemáticas), *STIX Two* (especializada en símbolos científicos).

### 3.3 Manejo de diacríticos y caracteres compuestos
- Soporte tanto para caracteres **precompuestos** (ej. `ắ`) como para **combinados** (ej. `a` + tilde).
- Correcta posición de diacríticos en distintas escrituras (latín, cirílico, tailandés, griego).
- Fundamental en disciplinas como lingüística, química o física.

### 3.4 Compatibilidad técnica
- Adecuada representación de escrituras complejas: griego politónico, verticalidad en CJK, notación matemática avanzada.
- Verificación de kerning, ligaduras y métricas con herramientas como *FontForge*.

### 3.5 Neutralidad y profesionalismo
- Evitar estilos decorativos o fuentes poco académicas.
- Mantener consistencia tipográfica entre distintos sistemas de escritura (ej. armonía visual entre texto latino y caracteres chinos en un mismo cuerpo tipográfico).

### 3.6 Coherencia editorial en colecciones
- Uso consistente de la misma familia o conjunto limitado de fuentes.
- Uniformidad en encabezados, notas, bibliografía y ecuaciones.
- Refuerzo de la identidad visual de la colección.

### 3.7 Licencias y disponibilidad
- Preferencia por fuentes open source (OFL, Apache 2.0).
- Ejemplos: *Libertinus*, *Noto Serif*, *Source Han Serif*.
- Evitar licencias restrictivas que comprometan la escalabilidad del proyecto.

### 3.8 Impresión y distribución digital
- Evaluar el rendimiento tipográfico en impresión offset y en formatos digitales (PDF, EPUB).
- Garantizar legibilidad en diferentes resoluciones de pantalla.
- Considerar densidad de texto: algunas fuentes compactas permiten mayor cantidad de líneas por página (ej. *Arno Pro* frente a *Garamond*).

## Comparaciones técnicas

| Característica         | Libertinus | Noto Serif | STIX Two |
|------------------------|------------|------------|----------|
| Cobertura griego       | 100%       | 85%        | 95%      |
| Símbolos matemáticos   | 1,900+     | 1,200+     | 7,500+   |
| Licencia               | OFL        | OFL        | Propia   |
| Soporte vertical CJK   | No         | Sí         | No       |

## Configuración recomendada en LaTeX

```latex
\usepackage{unicode-math}
\setmainfont{Libertinus Serif}
\setmathfont{Libertinus Math}
\setsansfont{Noto Sans CJK SC} % Para títulos o pasajes en chino.
```

## Conclusión general

La elección tipográfica en el ámbito científico debe equilibrar tres dimensiones: calidad tipográfica, compatibilidad técnica y coherencia editorial.
- Para textos matemáticos extensos, Libertinus es una opción óptima.
- Para proyectos multilingües con fuerte presencia de CJK, Noto Serif ofrece cobertura más amplia.
- STIX Two destaca en símbolos especializados, aunque con licencia más restrictiva.

En conjunto, el estándar actual para libros científicos combina OpenType, Unicode y motores como LuaLaTeX, garantizando la legibilidad, la precisión terminológica y la identidad profesional de la obra.
