# Comportamientos de Gambas verificados empíricamente

Cada afirmación de este documento se comprobó ejecutando código Gambas, no leyendo documentación. Las pruebas corrieron sobre **Gambas 3.19** en contenedor (3.22 no está en los repos de Ubuntu noble). Para las funciones de `String.*`, `File.*`, `Dir`, `Exist` y los operadores lógicos no se esperan diferencias con 3.22, pero si algo se comporta raro, el mini-test es de cinco líneas.

Origen: sesión de refactorización de `m_FuncionesGenericas`, `m_EscanerUTF8` y `m_EscanerTipografico` (agosto 2026).

---

## 1. Rutas y directorios

**`Exist()` devuelve `True` también para archivos regulares.** No sirve como guard de "esto es una carpeta". Para eso hace falta `IsDir()`, en `If` anidado porque `And` no cortocircuita.

**`Dir()` sobre un archivo regular lanza el error 49.**

```
Exist("/tmp/x/archivo.md")        -> True
Dir("/tmp/x/archivo.md", "*.md")  -> ERROR #49: Not a directory
Dir("/tmp/x/no-existe", "*.md")   -> ERROR: File or directory does not exist
```

Este fue el bug raíz de siete funciones del proyecto: recibían la ruta de un `.md` donde esperaban una carpeta, `Exist()` decía `True`, y el `Dir()` siguiente mataba la función sin mensaje visible.

**`File.RealPath()` devuelve cadena vacía para una ruta inexistente**, y la ruta real para una existente. O sea que el idiom `If Not File.RealPath(x) Then` funciona como test de existencia. Ya estaba en uso en el proyecto y es correcto.

**`"/a/b" &/ ""` devuelve `"/a/b"`.** Concatenar con cadena vacía no agrega barra. Consecuencia práctica: una property que devuelve `Ruta &/ Nombre` con `Nombre` vacío devuelve la carpeta, no un archivo — lo que puede hacer que un código roto funcione de casualidad.

**`Dir(dir, "*.*")` omite los archivos sin extensión.** Es un modismo de Windows. Para todos los archivos: `Dir(dir, "*", gb.File)`.

```
Dir("*.*")  = [con.ext]
Dir("*")    = [sinext, subdir, con.ext]
```

**`File.Name()` devuelve el nombre CON extensión; `File.BaseName()` SIN extensión.**

```
File.Name("/x/y/script.py")     = script.py
File.BaseName("/x/y/script.py") = script
File.Ext("/x/y/script.py")      = py
```

---

## 2. Operadores lógicos

**`And If` y `Or If` existen SOLO en `If`.** Dentro de un `While` dan error de compilación:

```
While a.Count > 0 And If Trim$(a[a.Max]) = ""
                   ^ error: Unexpected And
```

Esto es un agregado a RC-GM-17: la regla dice separar en `If` anidados, y el reflejo natural es escribir `And If` en cualquier condición. En un `While` hay que abrir el bloque:

```gambas
Do
  If a.Count = 0 Then Break
  If Trim$(a[a.Max]) <> "" Then Break
  a.Remove(a.Max)
Loop
```

**El `While` con `And` común revienta con `Out of bounds`** cuando el array se vacía, porque evalúa `a[a.Max]` con `Max = -1`. Verificado, y encontrado vivo en `ProcesarArchivoFootnote`.

---

## 3. UTF-8 y cadenas

**`Lower()`, `LCase()` y `String.Lower()` son las tres ASCII-only.** No pliegan acentos:

```
Lower("SEÑOR ÁRBOL")            = seÑor Árbol
Lower("SEÑOR") = Lower("señor") -> False
String.Comp("SEÑOR", "señor", gb.IgnoreCase) = 0  -> False
```

`String.Comp` con `gb.IgnoreCase` tampoco sirve. Para comparar palabras sin distinguir caja hay que plegar a mano el bloque Latin-1: para codepoints 192–222 (salteando 215, que es el signo de multiplicación y no una letra), la minúscula está 32 codepoints después. Cubre castellano, portugués, francés e italiano. Implementado como `PlegarMinusculas()` en `m_EscanerTipografico`.

**`String.IsValid()` responde si una cadena es UTF-8 válido.** Es la única forma de detectar un archivo mal codificado:

```
ASCII puro           -> True      Latin-1             -> False
UTF-8 con acentos    -> True      Multibyte truncado  -> False
UTF-8 con BOM        -> True
```

**`File.Load()` no decodifica ni valida.** Un archivo en Latin-1 NO produce `U+FFFD`: produce codepoints basura y ceros que se comen el resto del contenido.

```
"café señor" en Latin-1 -> 99 97 102 38963 101 457866 0 0 0 0 0
```

`457866` está fuera del rango Unicode. Corolario: **buscar `U+FFFD` no sirve como detector de codificación corrupta.** Un `U+FFFD` literal sí es un hallazgo real, pero significa otra cosa — que una conversión anterior ya perdió datos.

**`Mid()` con longitud en bytes puede cortar un carácter por la mitad**; `String.Mid()` no:

```
Mid("café señor", 1, 4)        = [caf<0xEF><0xBF><0xBD>]  IsValid=False
String.Mid("café señor", 1, 4) = [café]                    IsValid=True
```

**`InStr` y `String.InStr` devuelven posiciones distintas** sobre el mismo texto: bytes contra codepoints. Mezclarlas produce desfasajes silenciosos.

```
InStr("café señor", "señor")        = 7   (byte)
String.InStr("café señor", "señor") = 6   (codepoint)
```

**El bucle `String.Mid` + `String.Code` por codepoint escala LINEALMENTE, no cuadráticamente.** Medido sobre texto con acentos:

| codepoints | tiempo |
|---|---|
| 5.000 | 0,003 s |
| 10.000 | 0,005 s |
| 20.000 | 0,011 s |
| 40.000 | 0,021 s |

No hace falta optimizarlo ni reemplazarlo por acceso por bytes, que perdería la semántica de codepoint (RC-GM-12).

Verificado en ambos entornos, agosto 2026. El método `UpperCase` del `TextEditor` también pliega bajo locale UTF-8.

Para gbpublisher esto es PEOR que "ASCII-only": un comportamiento uniformemente roto se detecta en la primera prueba, mientras que uno dependiente del entorno funciona en la máquina del desarrollador y falla en una instalación cliente con locale mínimo. Las máquinas de las universidades no se controlan.

REGLA: donde la salida deba ser reproducible entre máquinas, NO usar `Upper`/`Lower` nativos. Usar las tablas explícitas de `m_FuncionesGenericas`, que son locale-independientes por construcción:

- `EsLetra(iCodigo)` — criterio de letra para partir palabras
- `PlegarAMayuscula(iCodigo)` / `PlegarAMinuscula(iCodigo)` — plegado por codepoint

Cobertura: ASCII y Latin-1 Supplement, salteando `×` (215) y `÷` (247), y sin plegar `ß` (223) ni `ÿ` (255), cuyas mayúsculas no siguen la regla de ±32. Alcanza para castellano, portugués, francés e italiano. Latin Extended cuenta como letra pero no se pliega. Si hiciera falta polaco, checo o turco, extender ahí y todos los consumidores lo heredan.

`PlegarMinusculas()` en `m_EscanerTipografico` es hoy un envoltorio por texto sobre `PlegarAMinuscula()`; no tiene tabla propia.

PENDIENTE: `String.Comp` con `gb.IgnoreCase` tampoco plegó acentos en el contenedor, pero esa medición arrastra el mismo sesgo de locale. Reverificar en Mint antes de confiar en ella.

---

## 4. Colecciones

**Las claves de `Collection` son case-sensitive por defecto.** `c["Nota"] = "A"` y después `c.Exist("nota")` devuelve `False`. Coincide con Pandoc, donde `[^Nota]` y `[^nota]` son dos identificadores distintos.

---

## 5. Sintaxis de funciones

**Un `Sub` con tipo de retorno debe cerrar con `End`, no con `End Sub`.**

```
Public Sub PruebaSub() As Boolean
  Return True
End Sub          -> error: END FUNCTION expected
```

`Public Sub` sin retorno cierra bien con `End Sub`, y `Public Function` con `End Function`. El proyecto ya usa la forma correcta en `IsValidISSN` y `GitVersion`.

**Las declaraciones `Const` y `Private` a mitad de módulo, después de otras funciones, compilan y funcionan.** No hace falta moverlas arriba (aunque conviene por estilo).

---

## 6. Shell y procesos

**`Quote()` NO escapa para shell.** Es el escapado de Gambas: devuelve el texto entre comillas **dobles**, y dentro de comillas dobles `sh` sigue expandiendo `$(...)` y backticks.

```
Quote("http://x.com/$(id)")  =  "http://x.com/$(id)"
```

Una URL pegada en un TextBox con esa forma ejecutaba el comando. `Shell$()` sí escapa con comillas simples, pero lo correcto según SC-05 es `Exec` con array, que no pasa por `sh -c`.

**`Exec` acepta un `String[]` construido en una variable**, no solo un array literal. La restricción de "una sola línea" de SC-05 aplica al literal, no a un array armado con `.Add()`.

**Para pasar nombres a un script de shell sin interpolarlos**, usar `$@`:

```gambas
aComando.Add("sh")
aComando.Add("-c")
aComando.Add(sScript)   ' EL SCRIPT USA "$@", NO CONCATENA NOMBRES
aComando.Add("sh")      ' $0; LOS ARGUMENTOS ARRANCAN EN $1
```

---

## 7. Consultas a dpkg

**`dpkg -l NOMBRE` sin comodines es exacto**, no matchea prefijos. `dpkg -l gambas3-gb-form` no incluye a `gambas3-gb-form-editor`.

**`dpkg-query -W` acepta todos los paquetes en una sola llamada y devuelve la versión.** Medido contra el método de un `Shell` por paquete:

| método | tiempo |
|---|---|
| 30 × `sh` + `dpkg` + `grep` | 0,468 s |
| 1 × `dpkg-query` | 0,014 s |

Los no encontrados van a **stderr**, no a stdout, y la salida viene ordenada alfabéticamente y no en el orden pedido — hay que parsear a una `Collection`, no a un array paralelo. Solo cuenta como instalado el estado `install ok installed`.

**Para recuperar la versión de un ejecutable**, `dpkg -S` acepta varias rutas en una llamada y devuelve el paquete dueño. Hay que resolver el symlink antes: `/usr/bin/java` es un enlace de *alternatives* y `dpkg -S` no lo encuentra, pero `readlink -f` llega a `openjdk-21-jre-headless`. Igual `lualatex`, que resuelve a `luahbtex` y de ahí a `texlive-binaries`.

**`java -version` escribe en stderr, no en stdout.** Un `Exec ... To` devolvería cadena vacía.

**`command -v` es preferible a `which`**: es builtin de POSIX sh, mientras que `which` vive en debianutils y puede no estar.

---

## 8. Empaquetado en Ubuntu / Mint

**El paquete `lua` no existe** (`apt-cache policy lua` devuelve `Candidate: (none)`). `lua5.4` instala `/usr/bin/lua5.4`, no `/usr/bin/lua`. Para tener el nombre corto hace falta un `update-alternatives`.

**El servidor de base de datos no debe verificarse en el cliente.** gbpublisher es multiusuario contra una base compartida que normalmente vive en otra máquina, así que buscar `mysqld` en el PATH local da fallo en toda instalación cliente. Lo que el cliente necesita es el driver (`gambas3-gb-db2-mysql`); que el servidor responda lo prueba la conexión real.


