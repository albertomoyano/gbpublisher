# Instalación de gbpublisher

## Guía paso a paso para editores científicos

---

> **Antes de empezar**
> Esta guía está escrita para personas que no tienen conocimientos técnicos de informática. Cada paso indica exactamente qué hacer y qué esperar ver en pantalla. Si algo no coincide con lo que describe la guía, no sigas adelante: contactá al responsable técnico de tu institución.

---

## ¿Qué es cada archivo?

La distribución de gbpublisher incluye cuatro archivos que trabajás en este orden:

| Archivo | Para qué sirve |
|---|---|
| `integridad.sh` | Verifica que tu computadora tiene todo lo necesario instalado |
| `gbpublisher.sql` | Contiene la estructura de la base de datos (no lo abrís directamente) |
| `generar_bbdd.sh` | Crea la base de datos en tu servidor |
| `gbpublisher_X.X.deb` | El instalador de la aplicación |

---

## Paso 1 — Verificar dependencias

Este paso revisa que el servidor tiene todo el software necesario para que gbpublisher funcione. **No instala ni modifica nada**: solo informa.

### Cómo ejecutarlo

Abrí una terminal y escribí:

```
bash integridad.sh
```

Presioná Enter.

### Qué vas a ver

El script recorre una lista de programas y muestra el estado de cada uno:

```
  gbpublisher — Verificación de integridad del sistema
  ────────────────────────────────────────────────────────────────────

  Base de datos
  MySQL Server                                        OK

  Java y procesadores XSLT
  Java Runtime Environment                            OK
  Saxon-HE XSLT Processor                            OK

  Procesadores de documentos
  Pandoc                                              OK
  TeX Live (completo)                                 OK
  ...
```

Cada línea muestra **OK** (en verde) o **FALLO** (en rojo).

### Interpretando el resultado

**Si el resumen final dice:**

```
  Sistema listo: todas las dependencias (N) están disponibles.
  Podés instalar gbpublisher y ejecutar generar_bbdd.sh para crear la base de datos.
```

Todo está en orden. Continuá con el Paso 2.

**Si aparece algún FALLO:**

```
  3 de 45 dependencia(s) con FALLO.
  Instalá las dependencias faltantes antes de continuar.
```

Cada línea con FALLO muestra el comando exacto para instalar esa dependencia. Por ejemplo:

```
  TeX Live (completo)      FALLO   →  sudo apt install texlive-full
```

Pasá esa información al responsable técnico para que instale lo que falta. Una vez resuelto, volvé a ejecutar `integridad.sh` para confirmar que todo está en orden.

> **Importante:** No pases al Paso 2 si quedan dependencias con FALLO. La aplicación puede abrirse pero algunas funciones no van a funcionar correctamente.

---

## Paso 2 — Crear la base de datos

Este paso crea la base de datos donde gbpublisher va a guardar toda la información de tus revistas y artículos. **Es una operación destructiva**: si ya existía una base de datos de gbpublisher en este servidor (por ejemplo, de una instalación de prueba), va a ser eliminada y reemplazada por una nueva vacía.

### Cómo ejecutarlo

En la misma terminal, escribí:

```
bash generar_bbdd.sh
```

Presioná Enter.

### Qué vas a ver

El script verifica que el servidor MySQL está activo y que el archivo `gbpublisher.sql` está presente:

```
  gbpublisher — Generación de base de datos
  ════════════════════════════════════════════════════════════════════

  Paso 1: Verificando servicio MySQL
  MySQL             activo

  Paso 2: Verificando archivo de base de datos
  gbpublisher.sql   encontrado  (1743 líneas)
```

A continuación aparece una advertencia importante:

```
  Paso 3: Confirmación

  ATENCIÓN — OPERACIÓN DESTRUCTIVA

  Este proceso realizará las siguientes acciones:

    1. Eliminar la base de datos 'gbpublisher' si existe
       (se perderán TODOS los datos de cualquier instalación
       o prueba previa de gbpublisher en este servidor)

    2. Crear una base de datos 'gbpublisher' limpia
    3. Crear el usuario de conexión 'app_user'
    4. Cargar el esquema y datos de referencia

  ¿Confirmar? Escribí 'si' para continuar:
```

Escribí exactamente `si` (sin acento, en minúscula) y presioná Enter.

### Qué pasa después

El script crea la base de datos e informa el avance:

```
  Paso 4: Creando base de datos y usuario
  Base de datos     creada
  Usuario           creado  (app_user@localhost)

  Paso 5: Cargando esquema y datos de referencia
  Tablas creadas    27 tablas
```

Si todo salió bien, el resumen final muestra:

```
  ════════════════════════════════════════════════════════════════════
  Proceso completado con éxito.
  ════════════════════════════════════════════════════════════════════

  La base de datos 'gbpublisher' está lista.

  Próximos pasos:

    1. Abrí gbpublisher
    2. En la pantalla principal, hacé clic en el ícono de
       administración (mano abierta con cubos) en la esquina
       inferior izquierda
    3. Iniciá sesión con:  usuario: admin  /  contraseña: admin123
    4. Creá al menos 1 usuario operativo
    5. Cerrá Administración y logueate con ese usuario

  Nota: cambiá la contraseña del administrador después del primer acceso.
```

### Si algo sale mal

**"El servicio MySQL no está corriendo"**
El servidor de base de datos no está activo. Ejecutá `sudo systemctl start mysql` y volvé a intentar.

**"No se encontró el archivo gbpublisher.sql"**
El archivo `gbpublisher.sql` no está en el mismo directorio que `generar_bbdd.sh`. Verificá que ambos archivos están juntos en la misma carpeta.

**"No se pudo crear la base de datos"**
El usuario del sistema no tiene permisos de administrador. Contactá al responsable técnico.

---

## Paso 3 — Instalar la aplicación

Hacé doble clic sobre el archivo `gbpublisher_X.X.deb`. El instalador del sistema va a pedir tu contraseña de usuario y completará la instalación automáticamente.

Una vez instalado, gbpublisher aparece en el menú de aplicaciones de tu sistema.

---

## Paso 4 — Primer acceso y creación de usuarios

La base de datos recién creada no tiene usuarios de aplicación. Antes de poder trabajar, necesitás crear al menos uno.

### Abrir gbpublisher por primera vez

Al abrir gbpublisher aparece la pantalla de aviso legal. Leé los términos y aceptá para continuar. La pantalla principal de la aplicación se abre sin datos cargados.

### Acceder al panel de administración

En la **esquina inferior derecha** de la pantalla principal encontrás un ícono con una mano abierta y tres cubos. Hacé clic sobre él para abrir el panel de Administración del sistema.

### Iniciar sesión como administrador

En el panel de Administración ingresá con las credenciales iniciales:

- **Usuario:** `admin`
- **Contraseña:** `admin123`

> **Importante:** Estas credenciales son públicamente conocidas. Cambiá la contraseña del administrador inmediatamente después de este primer acceso.

### Crear el primer usuario operativo

Desde el panel de Administración creá al menos un usuario con el que vas a trabajar normalmente en la aplicación. Completá los campos requeridos y guardá.

### Cerrar Administración y conectarse

Cerrá el panel de Administración. En la pantalla principal, abrí el formulario de conexión al servidor, ingresá la IP del servidor (si es la misma máquina: `127.0.0.1`), el usuario y la contraseña que acabás de crear, y conectate.

A partir de este punto gbpublisher está listo para usar.

---

## Verificación final

Para confirmar que la instalación está completa y funcional, verificá que podés:

- [ ] Abrir gbpublisher sin mensajes de error
- [ ] Conectarte con el usuario creado
- [ ] Ver el menú principal habilitado
- [ ] Acceder a Acerca de... → la integridad del sistema sin elementos en rojo

---

## Información técnica de la instalación

Esta sección es para el responsable técnico de la institución.

| Parámetro | Valor |
|---|---|
| Base de datos | MySQL 8.0+ |
| Nombre de la BD | `gbpublisher` |
| Usuario de aplicación | `app_user` |
| Puerto | 3306 |
| Codificación | utf8mb4 / utf8mb4_unicode_ci |

La contraseña del usuario `app_user` está configurada en el archivo de conexión de la aplicación. No se muestra en esta guía por razones de seguridad.

---

*gbpublisher — Sistema de producción editorial académica*
*Estudio 2A — Buenos Aires*
