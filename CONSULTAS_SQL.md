# La gobernanza desde el formulario de consultas SQL

En **gbpublisher**, el formulario de consultas SQL no es simplemente una herramienta técnica para extraer datos: es un **punto crítico de gobernanza**. Desde allí se materializan decisiones sobre acceso a la información, trazabilidad de los procesos editoriales, control institucional y auditoría. Analizar este formulario desde la gobernanza permite entender cómo el sistema transforma datos operativos en **evidencia verificable** del funcionamiento editorial.

Este documento propone una lectura del formulario de consultas SQL como un **dispositivo de gobernanza**, no como una utilidad administrativa aislada.

![](/images/sql.png)

---

## 1. El formulario SQL como frontera de poder

En todo sistema editorial existen capas de acceso:

* quienes **producen datos** (editores, correctores, revisores),
* quienes **operan procesos** (gestión editorial),
* y quienes **observan, auditan o evalúan** el sistema.

El formulario de consultas SQL se sitúa en la frontera entre operación y observación. Desde la gobernanza, esto implica responder a preguntas clave:

* ¿Qué tipo de consultas están permitidas?
* ¿Se accede a datos crudos o a vistas controladas?
* ¿Existe registro del uso del formulario?

La gobernanza no elimina el acceso: **lo estructura, lo limita y lo documenta**.

### Implementación en gbpublisher

En gbpublisher, estas preguntas se resuelven mediante:

* **Restricción técnica**: Solo se permiten consultas SELECT (validación en código antes de ejecutar)
* **Control de acceso**: Sistema de usuarios integrado con la base de datos MySQL
* **Consultas predefinidas**: Biblioteca institucional de queries auditadas y documentadas
* **Trazabilidad completa**: Usuario creador y fecha de creación registrados por cada consulta guardada

---

## 2. Separación entre operación editorial y control

Uno de los principios básicos de la gobernanza es la **separación de funciones**. Aplicado al formulario SQL:

* La operación editorial escribe y modifica datos mediante formularios CRUD específicos.
* El formulario SQL **lee, consolida y expone** información sin capacidad de modificación.

Desde esta perspectiva, el formulario no debe:

* alterar datos productivos,
* corregir inconsistencias en caliente,
* ni reemplazar flujos editoriales formales.

Su función es **hacer visible el sistema**, no modificarlo directamente. El poder del formulario SQL no está en alterar datos, sino en **revelar patrones, detectar anomalías y sustentar decisiones institucionales**.

### Arquitectura de seguridad

En gbpublisher, esta separación se garantiza mediante:

1. **Validación previa a ejecución**: El código verifica que toda consulta comience con SELECT
2. **Control de error explícito**: Si se intenta ejecutar INSERT/UPDATE/DELETE/DROP (son muchas más), se rechaza la consulta
3. **Auditoría de intentos**: Cualquier intento de consulta no-SELECT queda registrado
4. **Sin modo administrador**: No existe bypass ni "modo avanzado" que permita modificaciones


---

## 2.5. Conocimiento abierto y memoria institucional compartida

En equipos editoriales pequeños (típicamente menos de 10 personas), la **concentración de conocimiento en una sola persona** es un riesgo crítico. Si el editor que "sabe hacer las consultas" renuncia, se lleva consigo años de conocimiento operativo institucional.

### Principio de transparencia radical

En gbpublisher, el formulario SQL implementa **transparencia radical** mediante:

1. **Todas las consultas son visibles para todos los usuarios**
   - No hay consultas privadas ni ocultas
   - Cualquier usuario puede ver qué consultas existen, quién las creó y para qué sirven
   - Este diseño transforma el conocimiento individual en **patrimonio institucional**

2. **Código SQL completamente legible**
   - Las consultas no están ofuscadas ni encriptadas
   - Cualquier persona del equipo puede leerlas, entenderlas y aprender con ellas
   - Los comentarios y descripciones son obligatorios, no opcionales

3. **Aprendizaje colectivo por observación**
   - Un asistente editorial puede ver cómo el coordinador consulta tiempos editoriales
   - Un nuevo editor puede copiar y adaptar consultas existentes
   - El conocimiento SQL se difunde horizontalmente, no se concentra verticalmente

### Ejemplo práctico

**Escenario**: La coordinadora editorial creó la consulta "Artículos estancados >60 días".

**Sin transparencia radical**: Solo ella sabe que existe, solo ella sabe ejecutarla, solo ella interpreta los resultados. Si renuncia, la revista pierde esa capacidad.

**Con transparencia radical en gbpublisher**:
- Todos ven la consulta en la biblioteca
- Todos pueden ejecutarla y entender qué mide
- Todos pueden modificarla si las necesidades cambian
- Si ella renuncia, el conocimiento permanece en el sistema

Esta arquitectura transforma **conocimiento tácito personal** en **conocimiento explícito institucional**.

### Limitación consciente: no hay jerarquía de acceso a consultas

A diferencia de sistemas corporativos con múltiples niveles de permisos, gbpublisher adopta un modelo **horizontal por diseño**:

- No hay "consultas de dirección" vs "consultas de asistentes"
- No hay consultas clasificadas por nivel de confidencialidad
- Todos acceden al mismo conjunto de consultas canónicas

Este diseño reconoce que en equipos pequeños, la **colaboración efectiva** requiere información compartida, no fragmentada.

---

## 3. Gobernanza y trazabilidad

Cada consulta SQL relevante puede convertirse en un **acto de trazabilidad**:

* tiempos editoriales,
* historial de decisiones,
* cambios de estado de un manuscrito,
* participación de actores,
* cumplimiento de políticas.

La gobernanza define:

* qué consultas son canónicas,
* qué indicadores se consideran válidos,
* qué resultados son auditables.

Así, el formulario SQL se transforma en una **fuente de evidencia institucional**, no en un simple visor de tablas.

### ¿Quién define las consultas canónicas?

En gbpublisher, la definición de consultas canónicas es un **proceso colaborativo**:

1. **Desarrollador**: Propone consultas técnicamente sólidas basadas en el modelo de datos
2. **Editores/Coordinadores/Correctores**: Validan que respondan a necesidades editoriales reales
3. **Indexadores/Evaluadores**: Solicitan indicadores específicos (SciELO, Latindex, DOAJ, etc.)
4. **Auditoría interna**: Verifica que sean reproducibles y no manipulables

Las consultas canónicas se almacenan en la base de datos con metadatos de autoría, propósito y fecha, transformándose en **documentos institucionales** con el mismo estatus que las políticas editoriales.

Los usuarios pueden:
- Ejecutar consultas canónicas directamente desde la biblioteca
- Modificar parámetros según necesidad (ej: cambiar año, área disciplinaria)
- Exportar resultados con timestamp para auditoría
- Crear nuevas consultas que, una vez validadas, pueden incorporarse al conjunto canónico

---

## 4. Metadatos de gobernanza

Desde el formulario SQL se accede no solo a metadatos científicos (títulos, autores, referencias), sino también a **metadatos de gobernanza**, tales como:

* fechas de recepción, revisión y aceptación,
* roles editoriales asignados,
* número y tipo de revisiones,
* cumplimiento de políticas éticas,
* versiones y estados del manuscrito,
* trazabilidad de modificaciones.

La gobernanza define cuáles de estos metadatos:

* son obligatorios,
* son visibles,
* son exportables,
* son preservables.

En gbpublisher, el formulario SQL actúa como **puente entre base de datos y rendición de cuentas**.

### Operacionalización en gbpublisher

En gbpublisher, esta definición se materializa en:

* **Obligatorios**: Validación en formularios CRUD (campos NOT NULL en base de datos)
* **Exportables**: Consultas predefinidas con botón "Exportar CSV" que incluye timestamp
* **Preservables**: Campos con `fecha_creacion_registro` y `fecha_actualizacion_registro` automáticos (DEFAULT CURRENT_TIMESTAMP)

Ejemplo de campos preservables en la tabla `articulos`:
- `fecha_creacion_registro`: Cuándo se registró el manuscrito por primera vez
- `fecha_actualizacion_registro`: Última modificación (se actualiza automáticamente)
- `usuario_creacion`: Quién creó el registro
- `responsable_edicion`: Editor asignado al manuscrito

Estos campos permiten reconstruir la historia completa de un manuscrito sin intervención manual.

---

## 5. Consultas SQL como instrumentos de auditoría

Una revista gobernada necesita poder responder, sin ambigüedad, a preguntas como:

* ¿Cuánto tiempo tarda el proceso editorial?
* ¿Se respeta la revisión por pares declarada?
* ¿Existen concentraciones de decisiones en una sola persona?
* ¿Se cumplen los criterios éticos declarados?
* ¿Los autores tienen identificadores persistentes (ORCID)?

Estas respuestas no se obtienen desde la interfaz editorial, sino desde **consultas estructuradas y reproducibles**.

El formulario SQL, bajo gobernanza, se convierte en:

* herramienta de auditoría interna,
* soporte para evaluaciones externas,
* insumo para indexadores y agencias de evaluación.

### Ejemplo: Auditoría de tiempos editoriales para SciELO

SciELO exige que las revistas reporten tiempos promedio entre recepción y publicación. En gbpublisher, esto se resuelve mediante la consulta canónica `ART-TIME-001`:
```sql
SELECT
    estado_articulo AS 'Decisión',
    COUNT(*) AS 'Cantidad',
    ROUND(AVG(DATEDIFF(fecha_aceptacion, fecha_recepcion)), 0) AS 'Días Promedio',
    MIN(DATEDIFF(fecha_aceptacion, fecha_recepcion)) AS 'Mínimo',
    MAX(DATEDIFF(fecha_aceptacion, fecha_recepcion)) AS 'Máximo'
FROM articulos
WHERE fecha_recepcion IS NOT NULL
    AND fecha_aceptacion IS NOT NULL
    AND estado_articulo IN ('aceptado', 'publicado')
GROUP BY estado_articulo;
```

Esta consulta:
- Es **reproducible**: mismo resultado cada vez que se ejecuta
- Es **auditable**: guarda usuario que la ejecutó y timestamp
- Es **exportable**: CSV con fecha de generación para evidencia
- Es **institucional**: forma parte de la biblioteca canónica verificada

Sin este tipo de consulta, el reporte dependería de cálculos manuales no verificables o de hojas de cálculo externas imposibles de auditar.

### Ejemplo: Control de cumplimiento ético para artículos con humanos
```sql
SELECT
    id_articulo AS 'ID',
    titulo_articulo AS 'Título',
    tipo_sujetos_investigacion AS 'Tipo Sujetos',
    aprobacion_comite_etica AS 'Tiene Aprobación',
    numero_aprobacion_etica AS 'Número Aprobación',
    responsable_edicion AS 'Editor Responsable'
FROM articulos
WHERE tipo_sujetos_investigacion IN ('humanos', 'humanos_y_animales')
    AND (aprobacion_comite_etica = 0 OR aprobacion_comite_etica IS NULL)
    AND estado_articulo IN ('en_revision', 'aceptado', 'publicado')
ORDER BY fecha_recepcion DESC;
```

Esta consulta permite identificar manuscritos que **no deberían publicarse** sin documentación ética, evitando problemas graves de integridad científica.

---

## 6. Riesgos mitigados mediante arquitectura de gobernanza

Un formulario SQL sin marco de gobernanza podría derivar en problemas graves. En gbpublisher, estos riesgos se mitigan mediante diseño arquitectónico:

| Riesgo | Mitigación en gbpublisher |
|--------|---------------------------|
| **Consultas ad hoc no documentadas** | Biblioteca de consultas predefinidas con metadatos completos |
| **Resultados no reproducibles** | Solo SELECT (no modifica datos); exports con timestamp automático |
| **Dependencia de una sola persona** | Consultas guardadas con nombre, descripción, autor y fecha |
| **Modificación accidental de datos** | Validación técnica previa: solo se permiten consultas SELECT |
| **Pérdida de confianza institucional** | Trazabilidad completa: quién, cuándo, qué consultó |
| **Consultas maliciosas o erróneas** | Sistema de verificación antes de guardar; alertas de errores |
| **Falta de documentación** | Campo obligatorio de descripción y comentarios por consulta |

La gobernanza no prohíbe el formulario SQL: **lo estructura, lo legitima y lo hace auditable**.

---

## 7. Trazabilidad sin censura: el borrado controlado

Un principio central de gbpublisher es que **la información no desaparece sin dejar rastro**. Esto aplica tanto a manuscritos como a consultas SQL.

### Regla de borrado de consultas

En gbpublisher existen **tres tipos de consultas** con diferentes reglas de eliminación:

#### 1. Consultas predefinidas de gbpublisher (bloqueadas)
- **No pueden borrarse** bajo ninguna circunstancia
- Son parte del sistema base, como los formularios CRUD
- Están marcadas con un indicador especial en la biblioteca
- Sirven como **plantillas de referencia** para crear consultas derivadas
- Ejemplos: ART-WF-001, AUT-ID-001, BIB-CAL-001, etc.

#### 2. Consultas canónicas institucionales (controladas)
- Creadas por el equipo editorial y validadas como institucionales
- **Solo el autor puede borrarlas**, con registro permanente del borrado
- Fecha y hora de eliminación quedan registradas
- Copia de la consulta eliminada se preserva en tabla de auditoría
- Usuario que ejecutó el borrado queda identificado

#### 3. Consultas personales/experimentales (libre eliminación)
- Creadas por usuarios para uso individual o temporal
- El autor puede borrarlas sin restricciones adicionales
- El borrado queda registrado en logs pero no requiere preservación
- Útiles para consultas ad-hoc que no justifican institucionalización

### Flujo de evolución de consultas
```
┌────────────────────────┐
│ Consultas predefinidas │ ← Bloqueadas, parte del sistema
│    (gbpublisher)       │
└───────────┬────────────┘
            │
            ├──→ Copiar/adaptar
            │
            ▼
┌────────────────────────┐
│ Consulta experimental  │ ← Borrable libremente
│     (usuario)          │
└───────────┬────────────┘
            │
            ├──→ [No es útil] → Se borra
            │
            └──→ [Se usa repetidamente]
                        ↓
                 ┌──────────────┐
                 │  Se valida   │
                 │ Se documenta │
                 └──────┬───────┘
                        ▼
                 ┌──────────────┐
                 │   Consulta   │ ← Borrable con registro
                 │  canónica    │   (solo por autor)
                 │ institucional│
                 └──────────────┘
```

### ¿Por qué bloquear las consultas predefinidas?

Las consultas que trae gbpublisher por defecto **no son solo ejemplos**: son **infraestructura de gobernanza**. Borrarlas sería equivalente a borrar:

- El formulario de gestión de autores
- El módulo de validación JATS
- Los campos obligatorios de metadatos

Estas consultas garantizan que **cualquier instalación de gbpublisher** puede:
1. Responder a requisitos de indexadores (SciELO, DOAJ, etc.)
2. Auditar tiempos editoriales
3. Controlar calidad de metadatos
4. Detectar problemas éticos

### Consultas predefinidas como base de aprendizaje

Un editor nuevo puede:
1. Ver la consulta predefinida `AUT-ID-001` (autores sin ORCID)
2. Entender cómo se estructura la query
3. Copiarla y modificarla para crear `AUT-ID-001-ACTIVOS` (solo autores con artículos activos)
4. Guardar su versión como consulta personal
5. Si el equipo la encuentra útil, se convierte en canónica institucional

Las consultas predefinidas actúan como **código de referencia educativo**, no como restricciones arbitrarias.

### Ejemplo práctico

**Consulta predefinida** (bloqueada):
```sql
-- AUT-ID-001: Autores sin ORCID (CRÍTICO para indexadores)
SELECT apellidos_nombre, email_principal, afiliacion_actual
FROM autores
WHERE (orcid IS NULL OR orcid = '')
  AND estado_autor = 'activo'
ORDER BY apellidos;
```

**Consulta derivada** (creada por coordinadora, borrable con registro):
```sql
-- AUT-ID-001-URGENTE: Autores sin ORCID con artículos aceptados
-- Necesitamos contactarlos ANTES de publicar
SELECT
    a.apellidos_nombre,
    a.email_principal,
    COUNT(art.id_articulo) AS 'Artículos Pendientes'
FROM autores a
JOIN articulo_autor aa ON a.id_autor = aa.id_autor
JOIN articulos art ON aa.id_articulo = art.id_articulo
WHERE (a.orcid IS NULL OR a.orcid = '')
  AND art.estado_articulo = 'aceptado'
GROUP BY a.id_autor
ORDER BY COUNT(art.id_articulo) DESC;
```

La segunda consulta:
- Parte de la lógica de la primera (bloqueo de ORCID faltantes)
- La especializa para un caso de uso editorial específico
- Puede borrarse si cambian las políticas editoriales
- Pero su borrado queda registrado como decisión institucional

### ¿Por qué importa esto en equipos pequeños?

En equipos grandes, las consultas son documentos formales con procesos de aprobación. En equipos pequeños de 4-10 personas, las consultas son **conversaciones codificadas**:

- "¿Cómo sabemos si estamos atrasados?" → Consulta ART-WF-002
- "¿Cuántos autores nos faltan por completar ORCID?" → Consulta AUT-ID-001
- "¿Qué referencias tienen problemas?" → Consulta BIB-CAL-001

Si esas consultas desaparecen sin registro, se pierde la **memoria de cómo el equipo resolvía problemas**.

### Ejemplo de trazabilidad

**Situación**: Un editor creó la consulta "Revisores con más de 3 asignaciones activas" para balancear carga. Después de 6 meses, considera que ya no es necesaria y la borra.

**Sistema sin trazabilidad**: La consulta desaparece. En 2 años, cuando vuelva a surgir el problema de sobrecarga de revisores, nadie recuerda que existía esa consulta.

**Sistema con trazabilidad (gbpublisher)**:
- El borrado queda registrado: "Editor A eliminó consulta X el 2024-03-15"
- La consulta borrada sigue en tabla de auditoría
- Si el problema reaparece, puede consultarse el historial y recuperar la consulta
- Se preserva el **conocimiento institucional** incluso de soluciones descartadas

Este diseño reconoce que en equipos pequeños, **no hay redundancia humana**: si se pierde conocimiento, puede no haber nadie más que lo tenga.

---

## 8. El formulario SQL como expresión del modelo editorial

En gbpublisher, el diseño del esquema de base de datos, junto con el formulario SQL, refleja un modelo editorial explícito:

* estados bien definidos (borrador, en_revision, aceptado, publicado, rechazado, retractado),
* procesos versionados y auditables,
* separación entre contenido científico y metadatos de control,
* centralidad de los metadatos de gobernanza.

Desde la gobernanza, esto implica que cada consulta relevante es una **lectura del modelo editorial**, no solo de los datos.

### Implicaciones prácticas

En términos concretos, esto significa que:

- Una revista con workflow mal definido **no puede generar consultas de auditoría coherentes**
- Un sistema sin estados claros **no puede medir tiempos editoriales con precisión**
- Una base de datos sin metadatos de gobernanza **no puede rendir cuentas ante evaluadores**
- Un proceso editorial opaco **no puede transformarse en evidencia verificable**

Por lo tanto, la calidad de las consultas SQL es un **indicador directo de la madurez del proceso editorial**, no solo de la competencia técnica del sistema.

### Ejemplo de madurez editorial

Una revista con proceso editorial maduro puede responder instantáneamente:

**Pregunta**: "¿Cuántos manuscritos están estancados en revisión por más de 60 días?"

**Respuesta**: Consulta canónica `ART-WF-002` ejecutada en 0.3 segundos con resultado exportable.

Una revista sin gobernanza debe:
1. Pedir al editor que revise correos manualmente
2. Consolidar información en hoja de cálculo
3. Esperar días o semanas para tener una respuesta aproximada
4. Confiar en que no hubo errores humanos en el proceso

La diferencia no es solo de velocidad: es de **confiabilidad institucional**.

---

## 9. Consultas canónicas y su función de gobernanza

En gbpublisher se distingue entre dos tipos de consultas:

### Consultas operativas

- Usadas diariamente por editores para tareas rutinarias
- Responden necesidades inmediatas ("¿Qué artículos están en revisión?")
- Pueden modificarse según evolucione el flujo de trabajo
- Son herramientas de productividad individual

### Consultas de gobernanza (canónicas)

- Usadas para auditoría, evaluación externa, indexación
- Responden a políticas institucionales ("¿Cumplimos los tiempos declarados?")
- Son **canónicas**: versionadas, documentadas, reproducibles
- Son instrumentos de rendición de cuentas institucional

### Ejemplos de consultas canónicas en gbpublisher

| ID Consulta | Propósito | Frecuencia | Stakeholder |
|-------------|-----------|------------|-------------|
| **ART-WF-001** | Estado actual del pipeline editorial | Diaria | Coordinadores |
| **ART-WF-002** | Artículos estancados >60 días | Semanal | Editores jefe |
| **ART-TIME-001** | Tiempo promedio decisión editorial | Trimestral | Comité editorial |
| **AUT-ID-001** | Autores sin ORCID (requisito indexadores) | Semanal | Asistentes editoriales |
| **REV-META-001** | Revistas con metadatos incompletos | Mensual | Responsables técnicos |
| **ART-STD-002** | Estudios con humanos sin aprobación ética | Semanal | Comité de ética |
| **BIB-CAL-001** | Referencias sin DOI (artículos >2010) | Por número | Correctores |
| **CROSS-004** | Dashboard ejecutivo completo | Mensual | Dirección |

### Estructura de una consulta canónica

Cada consulta canónica en gbpublisher incluye:

1. **Código SQL verificado**: Sintaxis validada y probada
2. **ID único**: Nomenclatura sistemática (ej: ART-WF-001)
3. **Nombre descriptivo**: Título claro de qué mide
4. **Descripción del propósito**: Para qué se usa, qué decisiones soporta
5. **Frecuencia recomendada**: Cuándo ejecutarla (diaria, semanal, etc.)
6. **Campos retornados**: Explicación de cada columna del resultado
7. **Usuario creador**: Quién diseñó la consulta originalmente
8. **Fecha de creación/modificación**: Trazabilidad temporal
9. **Comentarios de uso**: Notas sobre interpretación de resultados

Esta estructura transforma cada consulta en un **documento institucional** con el mismo estatus que una política editorial formal.

### Proceso de incorporación de consultas canónicas

Para que una consulta se convierta en canónica debe:

1. **Validación técnica**: Verificar que produce resultados correctos
2. **Validación editorial**: Confirmar que responde a necesidad real
3. **Documentación completa**: Incluir todos los metadatos requeridos
4. **Prueba de reproducibilidad**: Ejecutar múltiples veces, verificar consistencia
5. **Aprobación institucional**: Comité editorial o coordinación valida su incorporación

Este proceso garantiza que solo las consultas realmente relevantes y confiables se incorporen al conjunto canónico.

---

## 10. Consultas efímeras: experimentación sin burocracia

No todas las preguntas editoriales requieren consultas permanentes. A veces, un editor necesita responder algo puntual sin crear un documento institucional.

### Modo de uso sin guardar

gbpublisher permite **ejecutar consultas sin guardarlas**:

1. El editor escribe la consulta directamente en el editor SQL
2. La ejecuta y obtiene resultados
3. Puede exportar a CSV si necesita el dato
4. La consulta **no** se guarda en la biblioteca

### ¿Cuándo usar consultas efímeras?

**Situación A**: "¿Cuántos artículos recibimos en enero de 2024 sobre inteligencia artificial?"
- Pregunta puntual, no recurrente
- No justifica crear una consulta permanente
- Modo efímero: escribir, ejecutar, leer resultado, listo

**Situación B**: "¿Cuántos artículos están estancados en revisión más de 60 días?"
- Pregunta recurrente, parte del control de calidad editorial
- Justifica consulta canónica ART-WF-002
- Modo permanente: guardar en biblioteca con documentación

### Ventaja para equipos pequeños

En equipos grandes con procesos burocráticos, cada consulta requiere aprobación, documentación, validación. Esto frena la agilidad.

En gbpublisher, diseñado para equipos pequeños:
- **Consultas efímeras** → Agilidad, experimentación, respuestas rápidas
- **Consultas canónicas** → Institucionalización de lo que funciona

Este doble modo permite:
- **Probar sin compromiso**: "¿Y si consulto esto de esta manera?"
- **Institucionalizar lo útil**: "Esto lo vamos a necesitar siempre, lo guardamos"

### Ciclo de vida de una consulta
```
┌─────────────────┐
│ Pregunta nueva  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Consulta efímera│ ← Se ejecuta sin guardar
└────────┬────────┘
         │
         ├──→ [No se vuelve a usar] → Se descarta
         │
         └──→ [Se usa repetidamente]
                     ↓
              ┌──────────────┐
              │ Se documenta │
              │ Se valida    │
              │ Se guarda    │
              └──────┬───────┘
                     ▼
              ┌──────────────┐
              │   Consulta   │
              │   canónica   │
              └──────────────┘
```

Este flujo es **orgánico, no burocrático**: las consultas se institucionalizan porque son útiles, no porque alguien decretó que deben existir.

---

## 11. Exportación y preservación de resultados

### Formatos de exportación

Toda consulta en gbpublisher puede exportarse a CSV con:

- **Timestamp de generación**: Fecha y hora exacta de ejecución
- **Usuario ejecutor**: Quién generó el reporte
- **Nombre de consulta**: ID y descripción si es canónica
- **Datos completos**: Todas las filas retornadas sin filtrado

Este formato garantiza que los resultados sean:
- **Auditables**: Se puede verificar cuándo y quién los generó
- **Reproducibles**: Ejecutar la misma consulta da el mismo resultado
- **Preservables**: CSV es formato estándar, legible a largo plazo

### Uso en evaluaciones externas

Los archivos CSV generados sirven como evidencia para:

1. **Solicitudes de indexación**: SciELO, Latindex, DOAJ requieren reportes de tiempos editoriales
2. **Evaluaciones CONICET/ANPCyT**: Agencias de financiamiento solicitan indicadores
3. **Auditorías internas**: Comités editoriales revisan cumplimiento de políticas
4. **Informes anuales**: Memorias institucionales con datos verificables

La trazabilidad completa (quién, cuándo, qué) transforma estos archivos en **evidencia institucional válida**.

---

## 12. Espíritu colaborativo: la edición como obra colectiva

En revistas académicas pequeñas (la mayoría en Latinoamérica), la edición **no puede depender de una sola persona**. El modelo de "editor heroico" que conoce todo y hace todo es insostenible.

### Principios de trabajo colectivo en gbpublisher

1. **Conocimiento distribuido, no concentrado**
   - Las consultas canónicas son patrimonio del equipo, no de individuos
   - Cualquier persona puede ejecutar cualquier consulta
   - El conocimiento SQL se difunde por imitación y adaptación

2. **Autoría reconocida, no privatizada**
   - Cada consulta registra quién la creó (reconocimiento)
   - Pero cualquiera puede usarla, modificarla, mejorarla (bien común)
   - El conocimiento es firmado pero no es propietario

3. **Mejora continua colectiva**
   - Si un asistente encuentra una forma más eficiente de consultar algo, puede proponer mejora
   - Las consultas evolucionan con el equipo, no quedan congeladas
   - La biblioteca SQL es un **documento vivo**, como un wiki editorial

### Ejemplo: evolución de una consulta por aporte colectivo

**Versión 1 (Coordinadora, 2024-01)**:
"Artículos en revisión más de 60 días"
```sql
SELECT titulo_articulo, fecha_recepcion
FROM articulos
WHERE estado_articulo = 'en_revision'
  AND DATEDIFF(CURDATE(), fecha_recepcion) > 60;
```

**Versión 2 (Editor técnico, 2024-03)**:
Agregó cantidad de revisores asignados
```sql
SELECT a.titulo_articulo, a.fecha_recepcion, COUNT(ar.id_revision)
FROM articulos a
LEFT JOIN articulo_revisor ar ON a.id_articulo = ar.id_articulo
WHERE a.estado_articulo = 'en_revision'
  AND DATEDIFF(CURDATE(), a.fecha_recepcion) > 60
GROUP BY a.id_articulo;
```

**Versión 3 (Asistente editorial, 2024-06)**:
Agregó cuántas revisiones están completadas vs pendientes
```sql
SELECT
    a.titulo_articulo,
    a.fecha_recepcion,
    COUNT(ar.id_revision) AS 'Total Revisores',
    SUM(CASE WHEN ar.decision IS NULL THEN 1 ELSE 0 END) AS 'Pendientes'
FROM articulos a
LEFT JOIN articulo_revisor ar ON a.id_articulo = ar.id_articulo
WHERE a.estado_articulo = 'en_revision'
  AND DATEDIFF(CURDATE(), a.fecha_recepcion) > 60
GROUP BY a.id_articulo;
```

**Dinámica colaborativa**:
- La coordinadora aportó la pregunta inicial
- El editor técnico agregó contexto de gestión
- La asistente agregó detalle operativo útil
- **Ninguno borró el trabajo del otro**, se construyó sobre lo existente

Esta evolución es posible porque:
1. Todos pueden ver todas las consultas
2. Todos pueden proponer mejoras
3. El historial de cambios queda registrado
4. La autoría colectiva está reconocida

### Contraste con modelos jerárquicos

**Modelo corporativo tradicional**:
- "El DBA hace las consultas complejas"
- "Los usuarios comunes solo ven reportes predefinidos"
- El conocimiento está estratificado

**Modelo colaborativo de gbpublisher**:
- "Cualquiera puede aprender a hacer consultas"
- "Las consultas útiles se comparten con el equipo"
- El conocimiento circula horizontalmente

Este modelo reconoce que en equipos de 3-8 personas, **no hay especialistas full-time**: todos hacen de todo. El formulario SQL debe facilitar esa polivalencia, no obstaculizarla con barreras técnicas o burocráticas.

### Caso real: revista con 4 personas

**Equipo**:
- 1 coordinadora (20h/semana)
- 2 editores asociados (10h/semana cada uno)
- 1 asistente editorial (30h/semana)

**Problema previo** (sin gbpublisher):
- Solo la coordinadora sabía hacer reportes de tiempos editoriales
- Si se enfermaba o estaba de vacaciones, no había reportes
- El conocimiento estaba en su cabeza y en hojas de cálculo personales

**Solución con gbpublisher**:
- Las 12 consultas canónicas están documentadas y visibles
- Cualquiera de las 4 personas puede ejecutarlas
- La asistente aprendió SQL viendo las consultas existentes
- Ahora genera reportes sin depender de la coordinadora

**Resultado**: El equipo pasó de **dependencia de una persona** a **capacidad distribuida**. La revista dejó de ser frágil.

---

## 12. Limitaciones y casos especiales

### Cuando el formulario SQL NO es la herramienta adecuada

El formulario SQL **no debe usarse** para:

1. **Modificar datos productivos**: Usar formularios CRUD específicos
2. **Corregir errores masivos**: Crear script de migración versionado
3. **Generar reportes complejos con gráficos**: Usar herramientas de BI externas
4. **Analizar tendencias temporales complejas**: Exportar a R/Python para análisis estadístico

### Integración con otras herramientas

gbpublisher está diseñado para integrarse con:

- **LibreOffice Calc**: Procesamiento de CSV exportados
- **R/Python**: Análisis estadístico avanzado de datos exportados
- **Metabase/Grafana**: Dashboards visuales conectados a la misma BD
- **Archivos JATS-XML**: Metadatos exportables para indexadores

El formulario SQL es **una** herramienta en un ecosistema más amplio, no la única.

---

## Conclusión

El formulario de consultas SQL en gbpublisher no es un accesorio técnico. Es un **dispositivo de gobernanza editorial** que:

* hace visible el proceso científico,
* permite la auditoría y la rendición de cuentas,
* conecta la operación diaria con la evaluación institucional,
* y transforma datos en evidencia verificable.

Gobernar no es controlar personas, sino **controlar procesos**. Y en un sistema editorial académico, controlar procesos significa:

1. **Poder demostrar** que se cumplieron los procedimientos declarados en las políticas editoriales
2. **Poder medir** la eficiencia y calidad del trabajo editorial con indicadores objetivos
3. **Poder rendir cuentas** ante agencias de financiamiento, indexadores y la comunidad científica
4. **Poder mejorar** mediante evidencia cuantitativa, no mediante intuiciones o suposiciones

El formulario SQL es el lugar donde la gobernanza deja de ser un discurso institucional abstracto y se vuelve **estructura operativa verificable**.

### El formulario SQL como infraestructura para la autonomía colectiva

En equipos editoriales pequeños, la gobernanza no puede ser burocracia ni jerarquía. Debe ser **infraestructura que habilite autonomía colectiva**:

- **Autonomía**: Cualquier persona puede responder preguntas editoriales sin pedir permiso
- **Colectiva**: El conocimiento no se privatiza, se comparte y se construye entre todos

El formulario SQL de gbpublisher materializa esto mediante:

1. **Transparencia radical**: Todas las consultas visibles para todos
2. **Experimentación sin burocracia**: Consultas efímeras para explorar
3. **Institucionalización orgánica**: Lo útil se preserva, lo demás se descarta
4. **Trazabilidad sin censura**: Se puede borrar pero queda registro
5. **Autoría reconocida pero no propietaria**: Firmas pero no candados
6. **Mejora continua colectiva**: Las consultas evolucionan con el equipo

Este diseño no es neutral: es una **decisión política** sobre cómo debe funcionar una revista académica pequeña. Rechaza el modelo del "experto único" y adopta el modelo de **comunidad de práctica**.

En ese sentido, el formulario SQL no solo implementa gobernanza técnica: implementa **gobernanza democrática del conocimiento editorial**.

### Principios fundamentales aplicados

Los principios de gobernanza materializados en el formulario SQL de gbpublisher son:

- **Transparencia**: Todo proceso es visible mediante consultas documentadas
- **Trazabilidad**: Cada acción queda registrada con quién, cuándo y qué
- **Reproducibilidad**: Los mismos datos producen los mismos resultados siempre
- **Separación de funciones**: Leer datos ≠ modificar datos
- **Auditoría permanente**: Cualquier momento puede verificarse el estado del sistema

Estos principios no son declaraciones aspiracionales: son **restricciones técnicas implementadas en código**.

## NOTAS FINALES

Convenciones utilizadas:

Prefijos:

- AUT (Autores)
- ART (Artículos)
- REV (Revistas)
- CROSS (Cruzadas)

Sufijos funcionales:

- REV: Revisores
- BIB: Bibliométrico
- INST: Institucional
- DISC: Disciplinaria
- ID: Identificadores
- CAL: Calidad
- EST: Estado
- ROL: Roles
- FORM: Formación
- WF: Workflow
- STD: Estándares
- PROD: Productividad
- MET: Métricas
- TIME: Tiempos
- META: Metadatos
- AUD: Auditoría

Etiquetas de prioridad:

**CRÍTICO:** Requiere atención inmediata, bloquea publicación

**GOBERNANZA:** Control operativo y auditoría

**AUDITORÍA:** Trazabilidad de cambios

Frecuencias recomendadas:

- **Diaria:** Para operaciones editoriales críticas
- **Semanal:** Para seguimiento de workflow
- **Mensual:** Para control de calidad general
- **Trimestral:** Para análisis de tendencias
- **Semestral/Anual:** Para reportes estratégicos

Versión: 1.0.0

Última actualización: 2025-01-30

Mantenido por: Alberto Moyano - [Estudio 2A](https://estudio2a.netlify.app/)

Licencia: Business Source License 1.1 (convierte a GPL v3 después de 5 años)
