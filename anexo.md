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
* El carácter open source del software.
* La delimitación de responsabilidades y del alcance del soporte.

---

### 2. Naturaleza del software y documentación

gbpublisher es un software **open source**, distribuido bajo una licencia **Creative Commons 4.0**, conforme a la especificación exacta indicada en su repositorio oficial.

El repositorio del proyecto incluye el código fuente y la documentación técnica asociada, entre otros archivos:

* El presente Anexo Técnico
* `leeme.md`
* `arquitectura.md`
* `verificar.sh`

El archivo `leeme.md` contiene instrucciones sobre como proceder para una correcta instalación de gbpublisher en su máquina local.

El archivo `arquitectura.md` constituye la **fuente principal de documentación funcional y técnica** de la aplicación, describiendo su diseño general, flujo de trabajo y criterios de integración con infraestructura institucional.

El acceso al software y a la documentación es libre y gratuito, conforme a los términos de la licencia aplicable.

---

### 3. Base de datos

#### 3.1. Estructura incluida en el repositorio

El repositorio oficial de gbpublisher incluye un archivo *dump* SQL que contiene **exclusivamente la estructura de las tablas necesarias** para el funcionamiento de la aplicación.

El archivo *dump*:

* No contiene datos institucionales.
* No contiene información sensible.
* Define únicamente tablas, índices y relaciones básicas.

#### 3.2. Responsabilidades del área de IT

El área de IT de la universidad será responsable de:

* Crear la base de datos correspondiente.
* Crear el usuario de base de datos.
* Importar el archivo *dump* SQL incluido en el repositorio.
* Verificar la correcta creación de la estructura resultante.

La importación deberá realizarse mediante herramientas estándar del motor de base de datos.

#### 3.3. Permisos requeridos

El usuario de base de datos asignado a gbpublisher contará únicamente con los siguientes permisos:

* `SELECT`
* `INSERT`
* `UPDATE`
* `DELETE`

No se requieren ni se solicitarán permisos administrativos, de creación de bases de datos ni de modificación estructural.

---

### 4. Uso de recursos del servidor

gbpublisher realiza un uso **liviano y predecible** del motor de base de datos, limitado a:

* Operaciones de alta, baja y modificación de registros.
* Consultas simples.
* Exportación de datos en formatos JSON, BibTeX y YAML.

La aplicación:

* No ejecuta procesos de cálculo intensivo.
* No realiza consultas complejas ni agregaciones pesadas.
* No utiliza el servidor como motor de procesamiento.

---

### 5. Acceso de red y principio de IP única

#### 5.1. Principio de diseño obligatorio

gbpublisher ha sido diseñada para operar **exclusivamente** bajo un esquema de **dirección IP única de origen**, el cual forma parte integral del mecanismo de acceso y control de la aplicación.

Bajo este esquema:

* Todas las instancias de gbpublisher, independientemente del equipo desde el que se utilicen,
  **se conectan siempre, sin excepción, desde la misma dirección IP de salida**.
* La dirección IP es **única, fija y común** para todos los usuarios y equipos.
* Este comportamiento es permanente.

---

### 6. Responsabilidades del área de IT en materia de red

El área de IT de la universidad deberá:

* Proveer una dirección IP fija desde la cual se realizarán las conexiones.
* Autorizar dicha IP en los mecanismos de seguridad correspondientes.
* Garantizar que todas las conexiones hacia la base de datos se originen desde dicha IP.

La provisión, estabilidad y validez de la dirección IP son responsabilidad exclusiva del área de IT.

---

### 7. Verificación del entorno de ejecución

El repositorio de gbpublisher incluye el script `verificar.sh`, desarrollado en lenguaje Bash.

Dicho script debe ser ejecutado **por cada usuario, en su propia máquina**, una vez instalada la aplicación.

El objetivo del script es verificar el entorno local de ejecución, incluyendo:

* La presencia de dependencias externas requeridas por gbpublisher, tales como:

  * `pandoc`
  * `xmllint`
  * y otras herramientas de línea de comandos utilizadas por la aplicación.

El script `verificar.sh`:

* **No instala software**.
* **No modifica configuraciones del sistema**.
* **No altera el servidor ni la base de datos**.
* Se limita a comprobar la disponibilidad de los componentes necesarios.

---

### 8. Verificación desde la aplicación

gbpublisher realiza verificaciones internas sobre su propio funcionamiento.

Sin embargo, las herramientas externas utilizadas por la aplicación:

* Son aplicaciones independientes.
* Deben ser instaladas por cada usuario conforme a las políticas de su sistema operativo.
* No son gestionadas ni distribuidas por gbpublisher.

La aplicación únicamente verifica que dichas herramientas estén disponibles en el entorno del usuario.

---

### 9. Uso de VPN

En caso de que el acceso al servidor se realice mediante VPN:

* La VPN deberá garantizar que la salida hacia el servidor se realice siempre desde la misma IP.
* Las credenciales y políticas de la VPN serán provistas y administradas por el área de IT.
* El uso de VPN no modifica ni reemplaza el requisito de IP única de origen.

---

### 10. Alcance de la gratuidad y exclusión de soporte

La provisión de gbpublisher como software open source, junto con su documentación técnica:

* No implica la prestación automática de servicios de implementación.
* No incluye soporte técnico, auditoría ni acompañamiento en la puesta en producción.
* No transfiere responsabilidad operativa al proveedor del software.

El área de IT y los usuarios finales son responsables de la correcta instalación del entorno local conforme a la documentación disponible.

---

### 11. Asesoramiento profesional

Cualquier servicio de asistencia técnica, asesoramiento o validación:

* No se encuentra incluido en la licencia open source.
* Podrá ser prestado únicamente mediante acuerdo específico y arancelado entre las partes.

---

### 12. Límites de alcance

Quedan expresamente fuera del alcance del presente Anexo Técnico:

* Configuraciones que no garanticen una IP única de origen.
* Instalación de dependencias externas en equipos de usuarios.
* Cambios en la infraestructura general de la universidad.
* Ajustes avanzados de rendimiento del servidor o del motor de base de datos.

---

### 13. Aceptación

La utilización de gbpublisher sobre infraestructura institucional implica la aceptación expresa de las condiciones establecidas en el presente Anexo Técnico.
