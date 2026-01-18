# Anexo Técnico

## Condiciones de implementación, acceso y responsabilidad para el uso de gbpublisher

---

### 1. Objeto

El presente Anexo Técnico establece las condiciones técnicas, operativas y de responsabilidad bajo las cuales la aplicación **gbpublisher** podrá ser utilizada sobre infraestructura provista por la universidad.

El documento regula específicamente:

* La utilización de la estructura de base de datos incluida en el repositorio.
* Las condiciones de acceso de red.
* El uso obligatorio de una dirección IP única de origen.
* El alcance del uso de recursos del servidor.
* La naturaleza del licenciamiento del software.
* La delimitación de responsabilidades y del alcance del soporte.

---

### 2. Naturaleza del software y documentación

El repositorio del proyecto incluye el código fuente y la documentación técnica asociada, entre otros archivos:

* El presente Anexo Técnico
* `README.md`
* `arquitectura.md`
* `leeme.md`
* `verificar.sh`

El archivo `README.md` describe el modelo general del proyecto, su filosofía y condiciones de licenciamiento.

El archivo `arquitectura.md` constituye la **fuente principal de documentación funcional y técnica** de la aplicación, describiendo su diseño general, flujo de trabajo y criterios de integración con infraestructura institucional.

El archivo `leeme.md` contiene instrucciones sobre cómo proceder para una correcta instalación de gbpublisher en máquinas locales.

El acceso al código fuente y a la documentación está disponible en el repositorio público, conforme a los términos de la Business Source License 1.1.

---

### 3. Licenciamiento

gbpublisher está licenciado bajo **Business Source License 1.1 (BSL)**.

#### 3.1. Uso académico sin costo de licencia

El uso de gbpublisher por parte de la universidad **no requiere pago de licencia** siempre que:

* El uso se realice en el marco de funciones académicas, científicas o institucionales.
* No se presten servicios editoriales comerciales a terceros mediante el software.
* No se redistribuya el software como parte de productos o servicios comerciales.

#### 3.2. Uso comercial

Si la universidad o alguna de sus unidades:

* Presta servicios editoriales comerciales externos utilizando gbpublisher.
* Integra gbpublisher en plataformas comerciales.
* Redistribuye o comercializa productos derivados del software.

Deberá contactar al autor para obtener una licencia comercial.

#### 3.3. Transición futura

Conforme a BSL 1.1, el código de gbpublisher pasará automáticamente a licencia GPL-3.0 transcurridos 5 años desde la publicación de cada versión.

---

### 4. Base de datos

#### 4.1. Estructura incluida en el repositorio

El repositorio oficial de gbpublisher incluye un archivo *dump* SQL que contiene **exclusivamente la estructura de las tablas necesarias** para el funcionamiento de la aplicación.

El archivo *dump*:

* No contiene datos institucionales.
* No contiene información sensible.
* Define únicamente tablas, índices y relaciones básicas.

#### 4.2. Responsabilidades del área de IT

El área de IT de la universidad será responsable de:

* Crear la base de datos correspondiente.
* Crear el usuario de base de datos.
* Importar el archivo *dump* SQL incluido en el repositorio.
* Verificar la correcta creación de la estructura resultante.

La importación deberá realizarse mediante herramientas estándar del motor de base de datos.

#### 4.3. Permisos requeridos

El usuario de base de datos asignado a gbpublisher contará únicamente con los siguientes permisos:

* `SELECT`
* `INSERT`
* `UPDATE`
* `DELETE`

No se requieren ni se solicitarán permisos administrativos, de creación de bases de datos ni de modificación estructural.

---

### 5. Uso de recursos del servidor

gbpublisher realiza un uso **liviano y predecible** del motor de base de datos, limitado a:

* Operaciones de alta, baja y modificación de registros.
* Consultas simples.
* Exportación de datos en formatos JSON, BibTeX y YAML.

La aplicación:

* No ejecuta procesos de cálculo intensivo en el servidor.
* No realiza consultas complejas ni agregaciones pesadas.
* No utiliza el servidor de base de datos como motor de procesamiento.

---

### 6. Acceso de red y principio de IP única

#### 6.1. Principio de diseño obligatorio

gbpublisher ha sido diseñada para operar **exclusivamente** bajo un esquema de **dirección IP única de origen**, el cual forma parte integral del mecanismo de acceso y control de la aplicación.

Bajo este esquema:

* Todas las instancias de gbpublisher, independientemente del equipo desde el que se utilicen,
  **se conectan siempre, sin excepción, desde la misma dirección IP de salida**.
* La dirección IP es **única, fija y común** para todos los usuarios y equipos.
* Este comportamiento es permanente.

---

### 7. Responsabilidades del área de IT en materia de red

El área de IT de la universidad deberá:

* Proveer una dirección IP fija desde la cual se realizarán las conexiones.
* Autorizar dicha IP en los mecanismos de seguridad correspondientes.
* Garantizar que todas las conexiones hacia la base de datos se originen desde dicha IP.

La provisión, estabilidad y validez de la dirección IP son responsabilidad exclusiva del área de IT.

---

### 8. Verificación del entorno de ejecución

El repositorio de gbpublisher incluye el script `verificar.sh`, desarrollado en lenguaje Bash.

Dicho script debe ser ejecutado **por cada usuario, en su propia máquina**, una vez instalada la aplicación.

El objetivo del script es verificar el entorno local de ejecución, incluyendo:

* La presencia de dependencias externas requeridas por gbpublisher, tales como:

  * `pandoc`
  * `xmllint`
  * `xsltproc`
  * Saxon-HE
  * LaTeX
  * y otras herramientas de línea de comandos utilizadas por la aplicación.

El script `verificar.sh`:

* **No instala software**.
* **No modifica configuraciones del sistema**.
* **No altera el servidor ni la base de datos**.
* Se limita a comprobar la disponibilidad de los componentes necesarios.

---

### 9. Verificación desde la aplicación

gbpublisher realiza verificaciones internas sobre su propio funcionamiento.

Sin embargo, las herramientas externas utilizadas por la aplicación:

* Son aplicaciones independientes.
* Deben ser instaladas por cada usuario conforme a las políticas de su sistema operativo.
* No son gestionadas ni distribuidas por gbpublisher.

La aplicación únicamente verifica que dichas herramientas estén disponibles en el entorno del usuario.

---

### 10. Uso de VPN

En caso de que el acceso al servidor se realice mediante VPN:

* La VPN deberá garantizar que la salida hacia el servidor se realice siempre desde la misma IP.
* Las credenciales y políticas de la VPN serán provistas y administradas por el área de IT.
* El uso de VPN no modifica ni reemplaza el requisito de IP única de origen.

---

### 11. Código fuente disponible y servicios profesionales

El acceso al código fuente y documentación de gbpublisher es gratuito para instituciones académicas conforme a la licencia BSL 1.1.

Sin embargo, el acceso al código **no incluye**:

* Servicios de implementación personalizada.
* Soporte técnico directo.
* Auditorías de infraestructura.
* Capacitación presencial o remota.
* Acompañamiento en puesta en producción.
* Consultoría sobre flujos editoriales específicos.

El área de IT y los usuarios finales son responsables de la correcta instalación del entorno local conforme a la documentación disponible en el repositorio.

---

### 12. Servicios profesionales opcionales

Cualquier servicio de asistencia técnica, asesoramiento, auditoría o capacitación:

* No se encuentra incluido en la licencia de uso académico.
* Podrá ser prestado únicamente mediante acuerdo específico y arancelado entre las partes.

Para solicitar servicios profesionales, contactar a: [tu email]

---

### 13. Límites de alcance

Quedan expresamente fuera del alcance del presente Anexo Técnico:

* Configuraciones que no garanticen una IP única de origen.
* Instalación de dependencias externas en equipos de usuarios.
* Cambios en la infraestructura general de la universidad.
* Ajustes avanzados de rendimiento del servidor o del motor de base de datos.
* Modificaciones personalizadas del código fuente.
* Integración con sistemas externos no contemplados en la arquitectura original.

---

### 14. Aceptación

La utilización de gbpublisher sobre infraestructura institucional implica la aceptación expresa de las condiciones establecidas en el presente Anexo Técnico.

---

**Copyright © 2024-2026 Alberto Moyano**

Licenciado bajo Business Source License 1.1
Repositorio: https://github.com/albertomoyano/gbpublisher
