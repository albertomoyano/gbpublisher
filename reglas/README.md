# CONTEXTO PARA EL DESARROLLO DE GBPUBLISHER

---

## 1. PROYECTO

- **Nombre:** gbpublisher
- **Repositorio:** https://github.com/albertomoyano/gbpublisher
- **Propósito:** Aplicación de escritorio para manejar flujo de producción editorial académica. con lógica Single Source Publishing. La aplicación NO está orientada al uso por parte de autores.
- **Stack:** Single Source Publishibng · Markdown · Docbook · XML-JATS · XSLT · MySQL
- **SO objetivo:** Linux Mint Cinnamon con X11 (exclusivamente)
- **Rutas:** siempre Unix/Linux (`/home/usuario/`, nunca `C:\`)

---

## 2. LENGUAJE: GAMBAS 3

- Todo el proyecto gbpublisher utiliza sintaxis específica de Gambas — NO asumir Visual Basic
- SIEMPRE, ante la más mínima duda sobre sintaxis o el uso de cualquier componente, se debe consultar la documentación oficial antes de responder, esto vale para Gambas, Docbook, Markdown, XML, XSL, Saxon, LaTeX y W3C
- No se debe suponer o imaginar NADA; todo el código debe tener base documental respaldatoria actualizada
- Si una firma o componente no se puede verificar en la documentación oficial, se debe aclarar de manera explícita y proponer un mini-test antes de comprometer código en el proyecto

---

## 3. CONVENCIONES DE CÓDIGO

### 3.1 Comentarios internos
- Siempre en MAYÚSCULAS
- Ejemplo: `' ESTA ES LA EXPLICACIÓN DE LA FUNCIÓN`

### 3.2 Encabezado obligatorio de función
' ============================================
' Función   : NombreFuncion
' Propósito : Descripción clara de qué hace
' Parámetros: NombreParam As Tipo — descripción
' Retorna   : Tipo — descripción del valor de retorno
' ============================================

### 3.3 Apartados numerados dentro de la función
Cada sección lógica delimitada con:
' --- N. Descripción del apartado ---

Secciones típicas (agregar o eliminar según la función):
1. Inicialización de variables privilegiar declararlas al principio de la función, no agregarlas dentro de If
2. Validación de entrada
3. Consulta a base de datos
4. Procesamiento de resultados
5. Retorno y limpieza

### 3.4 Documentación de flujo interno
Los ciclos, condicionales, consultas y salidas relevantes deben tener un comentario breve que explique su PROPÓSITO, no su mecánica.

### 3.5 Sistema de coordenadas para parches (str_replace)
Localizar siempre el cambio con el formato: "En el archivo X, dentro de la función Y, en el apartado N" seguido del bloque exacto a reemplazar y su reemplazo. Aplica a clases, módulos y formularios.
