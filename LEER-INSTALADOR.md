# Cómo se instala gbpublisher

Lea este documento completo antes de ejecutar el instalador. Lo primero que el instalador le pregunta es si lo leyó; si responde que no, se detiene y le pide que lo lea.

Este documento explica:

- qué necesita antes de empezar;
- cómo se ejecuta el instalador;
- qué va a ver en la pantalla;
- qué hace en su computadora;
- qué decisiones se tomaron y por qué;
- qué hacer si algo falla.

---

## 1. Antes de empezar

Necesita:

- **Linux Mint 22 con escritorio Cinnamon.** Es la única plataforma soportada. Linux Mint 23 todavía no fue probado: si su computadora tiene Mint 23, el instalador se detiene y se lo dice.
- **Conexión a internet sin límite de datos.** Se descargan varios gigabytes: el instalador incluye TeX Live completo, el sistema de composición tipográfica. No lo haga con los datos del celular.
- **Tiempo.** Según su conexión, la instalación puede llevar más de una hora. No hace falta mirarla, pero no cierre la ventana ni apague la computadora mientras trabaja.
- **Espacio en disco.** El instalador controla el espacio libre antes de empezar y le dice cuánto falta, si falta.
- **La contraseña de su usuario de la computadora,** la que usa para iniciar sesión. El instalador la pide una sola vez, en una ventana, para tener permiso de instalar programas.
- **gbpublisher cerrado,** si ya lo tenía instalado.

---

## 2. Cómo se ejecuta

1. Abra una terminal: en Linux Mint, con las teclas **Ctrl + Alt + T**.
2. Copie esta línea completa:

   ```
   curl -fsSLo instalador.sh https://github.com/albertomoyano/gbpublisher/releases/latest/download/instalador.sh && bash instalador.sh
   ```

3. Péguela en la terminal: haga clic con el **botón derecho** del mouse dentro de la terminal, elija **Pegar** y pulse **Enter**.

No escriba `sudo` delante: el instalador le pide la contraseña cuando la necesita, en una ventana aparte.

La línea descarga el instalador de la última versión de gbpublisher, `instalador.sh`, en su carpeta personal y lo ejecuta. El archivo queda ahí: si la instalación se corta, vuelva a abrir una terminal y escriba `bash instalador.sh`. El instalador retoma desde donde había quedado.

---

## 3. Qué va a ver

**La bienvenida.** El instalador le recuerda que cierre gbpublisher, le muestra la dirección de este documento y le pregunta si lo leyó. Responda con **s** (sí) o **n** (no) y pulse Enter.

**Los controles.** Revisa su computadora sin cambiar nada:

- el sistema;
- el espacio en disco;
- la conexión;
- la configuración de idioma;
- si gbpublisher está abierto.

Cada control termina con una marca: ✔ (bien), ⚠ (aviso, se puede seguir) o ✖ (hay que resolverlo antes; el mensaje dice qué hacer).

**El resumen.** Le dice qué encontró en esta computadora y qué va a hacer: instalar desde cero, actualizar, o verificar y reparar. Si está de acuerdo, responda **s**.

**La contraseña.** Se abre una ventana que pide la contraseña de su usuario. Escríbala y acepte.

**Los pasos.** Cada paso aparece numerado. Mientras trabaja, al lado se ve el tiempo transcurrido y una barra que va y viene. La barra no mide cuánto falta: solo muestra que la computadora sigue trabajando. Cuando el paso termina, queda la palabra **ok**:

```
[1/8] Descarga de gbpublisher ................................... ok
[2/8] Descarga de las herramientas de producción ................ ok
[3/8] Repositorio de Gambas ..................................... ok
[4/8] Instalación de gbpublisher y TeX Live  12:47      ====
```

El paso de TeX Live es el más largo, y es normal que la barra siga yendo y viniendo durante mucho tiempo.

**El cierre.** Le dice qué quedó instalado y cómo abrir gbpublisher (desde el menú de aplicaciones), y dónde quedó el registro de la instalación. La ventana espera a que pulse Enter para cerrarse.

---

## 4. Qué hace en su computadora

1. **Descarga gbpublisher** y verifica que el archivo sea exactamente el publicado, con su huella digital. Lo guarda en `~/gbpublisher-instalacion/`, junto con las herramientas que haya que instalar: si la instalación se corta, no se vuelve a descargar.
2. **Agrega el repositorio oficial de Gambas.** Gambas es el lenguaje en que está escrito gbpublisher. La versión que trae Linux Mint es vieja y no alcanza. El instalador agrega el canal estable del equipo de Gambas, publicado en el servicio de openSUSE (`home:gambas:stable`), como indican las instrucciones oficiales de Gambas. Si su computadora tenía otro repositorio de Gambas, lo deshabilita: no pueden convivir dos.
3. **Instala gbpublisher y lo que necesita del sistema:** TeX Live completo, Java, Python y las bibliotecas de Qt.
4. **Instala en `/opt` las herramientas que deciden el resultado de una salida,** en versiones fijas:
   - Pandoc 3.1.3;
   - Saxon-HE 12.9;
   - epubcheck 4.2.6;
   - veraPDF 1.30.1;
   - packtools 4.18.2;
   - el validador de HTML vnu 26.7.3.

   Las versiones fijas son las que permiten regenerar un libro o un artículo idéntico años después: una actualización del sistema no las cambia.
5. **Instala MySQL,** si no está, y crea la base de datos de gbpublisher. La base solo acepta conexiones desde esta misma computadora.
6. **Crea la cuenta con la que gbpublisher se conecta a la base,** con una contraseña generada al azar, distinta en cada instalación. Nadie tiene que escribirla ni recordarla: queda guardada en un archivo que solo puede leer su usuario, `~/.gbpublisher/conexion.conf`.
7. **Verifica todo:** que la aplicación se conecta a la base y que las herramientas responden.
8. **Guarda un registro** de todo lo que hizo en su carpeta personal: `gbpublisher-instalacion-AAAAMMDD-HHMM.log`, un archivo por cada vez que se ejecuta.

### Si ya tenía gbpublisher

- **Versión anterior:** el instalador actualiza gbpublisher y aplica los cambios de la base que correspondan a la versión nueva. Cada cambio de la base hace antes un respaldo completo en `~/gbpublisher-respaldos/`. Sus datos, sus preferencias y su archivo de conexión se conservan.
- **Una base de datos anterior a la 2.0.0:** el instalador se detiene sin cambiar nada. Esa base se actualiza a mano; pida ayuda con el formulario de la sección 6.
- **La misma versión:** el instalador ofrece **verificar y reparar**. Revisa todo y arregla lo que falte o esté roto. Es lo primero que conviene hacer si gbpublisher deja de funcionar bien.
- **Una versión más nueva que la de este instalador:** el instalador se detiene. Nunca vuelve atrás una instalación.

---

## 5. Decisiones que se tomaron y por qué

- **Un instalador por versión.** Cada versión de gbpublisher publica su propio instalador, con la versión y la huella de lo que instala escritas adentro. La línea de la sección 2 descarga siempre el de la última versión. Así, el instalador y la aplicación siempre coinciden, y quien da soporte sabe exactamente qué tiene instalado cada persona: el registro lo dice.
- **Sin `sudo` y con una sola contraseña.** La contraseña se pide en una ventana gráfica y una sola vez. En la terminal, `sudo` no muestra lo que se escribe y muchas personas creen que se colgó.
- **La base de datos es MySQL.** gbpublisher se desarrolla, se prueba y se usa con MySQL.
- **Base local.** Esta versión del instalador prepara una computadora con su propia base de datos. El uso compartido por varias computadoras o personas se documenta aparte y lo configura el área de sistemas.
- **Contraseña de la base distinta en cada instalación.** No está escrita en el programa ni en ningún documento público.
- **Herramientas críticas en versiones fijas; el resto, del sistema.** Lo que puede cambiar el resultado de una salida (la transformación del XML, los validadores) queda fijo en `/opt`. TeX Live se toma del sistema porque sus actualizaciones no cambian el resultado de lo ya compuesto.
- **El instalador no cambia la configuración de idioma de su sistema.** Si no es UTF-8, se detiene y le explica cómo corregirla (sección 6).

---

## 6. Si algo falla

**Primero, vuelva a ejecutar el instalador** (`bash instalador.sh` en una terminal). Retoma desde donde había quedado y muchas veces resuelve el problema.

**Problemas frecuentes:**

- **Sin conexión o un sitio que no responde.** Verifique su conexión. Si está en una red institucional, puede que bloquee alguno de los sitios de descarga: pásele al área de sistemas la sección 7.
- **Poco espacio en disco.** Libere el espacio que indica el instalador y vuelva a ejecutarlo.
- **Otra versión de Linux Mint u otro sistema.** Esta versión del instalador solo funciona en Linux Mint 22.
- **Sesión que no es X11.** Es un aviso. gbpublisher funciona en la sesión X11 de Cinnamon, la que Linux Mint usa por defecto: al iniciar sesión, elíjala si había elegido otra.
- **Configuración de idioma que no es UTF-8.** Abra **Configuración del sistema → Idiomas**, elija su idioma y región, aplique los cambios para todo el sistema y reinicie la sesión.
- **Cerró la ventana o se cortó la luz a mitad de camino.** Vuelva a ejecutar el instalador. Si el corte fue mientras instalaba paquetes, el instalador primero repara la instalación interrumpida.

**Si el problema sigue**, cuando algo falla el instalador muestra:

- qué falló;
- dónde quedó el registro de esa ejecución;
- un enlace al formulario de reporte de problemas, ya completado con la versión, el sistema y el paso donde falló.

Abra ese enlace, adjunte el archivo de registro y envíe el reporte. Para usar el formulario necesita una cuenta de GitHub. Cómo crearla y cómo reportar un problema lo explica [el artículo del blog de Estudio 2A](@ENLACE_ARTICULO_GITHUB@).

---

## 7. Para el área de sistemas

**Sitios a los que se conecta el instalador.** Todos por HTTPS, salvo el repositorio de Gambas, que se lee por HTTP como indican sus instrucciones oficiales: apt verifica la firma de cada paquete.

| Sitio | Para qué |
|---|---|
| `github.com`, `release-assets.githubusercontent.com`, `raw.githubusercontent.com`, `codeload.github.com` | gbpublisher, su instalador, Pandoc, Saxon-HE, epubcheck y packtools |
| `download.opensuse.org` (y los espejos a los que redirige) | El repositorio de Gambas |
| `registry.npmjs.org` | vnu |
| `software.verapdf.org` | veraPDF |
| `pypi.org`, `files.pythonhosted.org` | Las dependencias de packtools |
| Los repositorios de Ubuntu y Linux Mint configurados en el sistema | MySQL, TeX Live, Java, Python, Qt |

**Qué queda instalado y dónde:**

| Qué | Dónde |
|---|---|
| La aplicación | El paquete `gbpublisher`: sus recursos en `/usr/share/gbpublisher` y el acceso en el menú de aplicaciones |
| Las herramientas en versiones fijas | `/opt` |
| El repositorio de Gambas | `/etc/apt/sources.list.d/home:gambas:stable.list` y su clave en `/etc/apt/trusted.gpg.d/home_gambas_stable.gpg`. Otro repositorio de Gambas que hubiera queda con la terminación `.gbpublisher-deshabilitado` |
| Lo descargado por el instalador | `~/gbpublisher-instalacion/` (se puede borrar cuando terminó bien) |
| El registro de cada ejecución | `~/gbpublisher-instalacion-AAAAMMDD-HHMM.log` |
| La base de datos | MySQL, base `gbpublisher`, cuenta `app_user@localhost` |
| Los datos del usuario | `~/.gbpublisher/` (preferencias y `conexion.conf`, con permisos 600) |
| Los respaldos de la base | `~/gbpublisher-respaldos/` y `~/.gbpublisher/respaldo/` |

MySQL queda escuchando solo en la propia computadora (`bind-address = 127.0.0.1`). Para el uso compartido entre varias computadoras, vea `BBDD_LEEME.md`.

---

## 8. El primer acceso

Al terminar, abra gbpublisher desde el menú de aplicaciones. Para crear las personas que van a usarlo, entre al panel de administración (el ícono de la mano con tres cubos, abajo a la derecha):

```
PRIMER ACCESO AL PANEL DE ADMINISTRACIÓN: USUARIO admin, CONTRASEÑA admin123.
ESTOS DATOS SON PÚBLICOS: CUALQUIERA QUE LEA ESTE MENSAJE O LA DOCUMENTACIÓN
LOS CONOCE. CAMBIE LA CONTRASEÑA APENAS ENTRE POR PRIMERA VEZ.
```

La cuenta del administrador vive solo en esta computadora; no es una cuenta de la base de datos.
