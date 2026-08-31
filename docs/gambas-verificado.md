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

---

# Sesión del auditor de XML JATS (agosto 2026)

Los comportamientos de abajo se verificaron sobre **Gambas 3.22 / Qt5 / Linux Mint**, durante el desarrollo de `m_AuditarJats` y del banco de pruebas `FPruebaAuditor`. A diferencia del resto del documento, estas pruebas corrieron en la máquina de desarrollo real y no en contenedor.

Tres de ellos costaron más de una hora de diagnóstico cada uno, y en los tres casos por la misma razón: **el error se manifiesta lejos de su causa**.

---

## 9. Nombres reservados

**`Log` es una función interna de Gambas** — el logaritmo natural — y no puede usarse como nombre de un `Sub`. La declaración compila sin quejarse; el error aparece en el *punto de llamada* como incompatibilidad de tipos, porque el compilador resuelve a la función matemática.

```
Private Sub Log(sTexto As String)   ' COMPILA
...
Log("hola")                          ' ERROR DE TIPO: espera un número
```

Del mismo tenor: `Exp`, `Abs`, `Int`, `Sgn`, `Str`, `Val`, `Left`, `Right`, `Mid`, `Len`, `Space`, `Format`, `Timer`, `Point`, `Line`.

REGLA: para funciones internas de un módulo, nombres de dos palabras o con prefijo del módulo. Viene de VB, donde no hay colisión.

---

## 10. Conversión de Boolean a texto

**`CStr(True)` devuelve `"T"` y `CStr(False)` devuelve CADENA VACÍA.** No `"True"`/`"False"`.

```
CStr(True)   = T
CStr(False)  =            (vacío)
```

Esto es peor que una convención rara: un `False` se vuelve **indistinguible de un campo vacío, de un NULL o de un dato que nunca se calculó**. En una grilla o en un informe, "no cumple" se renderiza como nada.

Y engancha con RC-GM-01: MySQL devuelve `TINYINT(1)` como Boolean, así que cualquier campo booleano de la base que pase por `CStr()` para mostrarse tiene este comportamiento.

REGLA: nunca `CStr()` sobre un Boolean para salida. Conversión explícita, `IIf(bValor, "sí", "no")` o un helper.

---

## 11. Ámbito de `Const`

**`Const` no se puede declarar dentro de un `Sub` o `Function`.** Es declaración de módulo o de clase; un `Const` local es error de compilación.

Combinado con lo ya verificado —que `Const` y `Private` a mitad de módulo compilan y funcionan— la regla práctica es: la constante va inmediatamente antes de la función que la usa si es de uso interno, o en `m_Constantes` si la comparten varias.

Otra herencia de VB/.NET, donde el `Const` local sí existe.

---

## 12. Precedencia de `Not`

**`Not` es unario y liga antes que los operadores de comparación de cadenas.**

```
If Not sNombre Begins "auditoria-" Then    ' SE LEE (Not sNombre) Begins "..."
                                          ' -> ERROR DE TIPO
```

Es la misma familia que RC-GM-17, con otra causa: allí el problema es que `And`/`Or` no cortocircuitan; acá es la precedencia. La salida es la misma en los dos casos: **separar**.

```gambas
For Each sNombre In aTodos
  If sNombre Begins "auditoria-" Then Continue
  aFiltrados.Add(sNombre)
Next
```

REGLA: no encadenar un operador lógico con otro operador en la misma expresión.

---

## 13. `Array.Insert` no inserta un elemento

**`Insert()` empalma OTRO ARRAY dentro del array.** Para insertar un elemento en una posición se usa `Add(Valor, Índice)`.

```
aOrdenados.Insert(oHallazgo, j)   ' ERROR DE TIPO: espera un array
aOrdenados.Add(oHallazgo, j)      ' CORRECTO
```

---

## 14. Arrays de clases propias

**`Dim a As New CMiClase[]` compila y funciona**, y el array guarda **referencias, no copias**.

```
aHallazgos[0].iOcurrencias = 999
For Each o In aHallazgos : Print o.iOcurrencias   ' 999 -> son referencias
```

Consecuencia práctica: una vista filtrada puede ser un segundo array con punteros a los mismos objetos. Filtrar es barato y no duplica datos.

`Remove(i)` reindexa, así que nunca borrar dentro de un `For` ascendente sobre el mismo array.

---

## 15. GridView virtual

**El GridView es virtual: el evento `Data` solo se dispara para las celdas visibles.** Medido con 5.000 filas × 3 columnas:

| celdas declaradas | disparos de `Data` en el primer pintado |
|---|---|
| 15.000 | 72 |

**Pero NO cachea.** Vuelve a pedir cada celda en cada repintado, para siempre: los incrementos observados fueron +18, +18, +18, +39, +21 con cada click.

Consecuencia dura: el handler `Data` es ruta caliente. No puede tener concatenación, formateo, búsqueda en `Collection` ni resolución contra un catálogo en disco. Solo indexar un array ya formateado.

La celda se escribe con `gvNombre.Data.Text` dentro del evento. Y `ColumnClick(Column As Integer)` **existe** y devuelve el índice de la columna, así que el ordenamiento por encabezado se cuelga de ahí.

---

## 16. `Dialog.SelectDirectory()` devuelve True al CANCELAR

Convención de Gambas, al revés de lo que sugiere el instinto. `Dialog.Path` conserva la ruta elegida, y preasignarlo antes fija la carpeta inicial.

```gambas
Dialog.Title = "Seleccionar carpeta"
Dialog.Path = $sUltimaCarpeta
If Dialog.SelectDirectory() Then Return   ' TRUE = EL USUARIO CANCELÓ
```

---

## 17. Procesos: `Wait()` y los eventos son incompatibles

**El más caro de la sesión.** La documentación oficial lo dice, pero es fácil no reparar en ello: mientras se ejecuta un procedimiento, el intérprete **no entra al bucle de eventos**.

Por lo tanto `hProceso.Wait()` bloquea el procedimiento y los eventos `Read` y `Error` **no se disparan nunca**. Nadie drena las tuberías del proceso hijo, y si el hijo escribe lo suficiente para llenar el búfer del sistema queda bloqueado escribiendo. Espera mutua: la aplicación espera al proceso y el proceso espera a que alguien lea. **La aplicación se cuelga sin ningún mensaje.**

La forma correcta usa la **sentencia** `Wait`, que es el mecanismo documentado para forzar la entrada al bucle de eventos, con una señal levantada por el evento `Kill`:

```gambas
$bProcesoTerminado = False
Try hProceso = Exec aComando For Read As "ProcHerramienta"
If Error Then ...

fVencimiento = Timer + 30.0
While Not $bProcesoTerminado
  Wait 0.01
  If Timer > fVencimiento Then
    Try hProceso.Kill()
    Return -2
  Endif
Wend

' EL EVENTO Kill PUEDE LLEGAR ANTES QUE LOS ÚLTIMOS TROZOS
For iDrenaje = 1 To 10
  Wait 0.01
Next
```

El vencimiento de plazo no es opcional cuando la entrada viene de terceros: una herramienta puede colgarse con un archivo patológico.

Y como la sentencia `Wait` deja correr los eventos de la interfaz, durante la espera **los botones son pulsables**: hace falta una bandera de reentrada.

---

## 18. Las firmas de los handlers de eventos NO son uniformes

**Y se validan al LANZAR, no al compilar.**

| evento de `Process` | firma |
|---|---|
| `Read` | **sin parámetros**; se lee con `Line Input #Last` o `Read #Last, sVar, Lof(Last)` |
| `Error` | **con parámetro**: `Error(sDatos As String)` |
| `Kill` | sin parámetros; el código de salida en `Last.Value` |

Una firma equivocada compila perfectamente y hace fallar el `Exec` en tiempo de ejecución:

```
ERROR AL LANZAR: Bad event handler in Modulo.ProcX_Error(): Not enough arguments
```

Esto obliga a `Try` + `If Error` sobre el propio `Exec` (RC-GM-02), y a que ese error **se informe a algún lado**: en nuestro caso el mensaje existía pero se escribía en el canal de stderr, que el llamador descartaba cuando el código de salida no era cero. El síntoma visible fue "todos los archivos aparecen como no válidos", a metros de la causa.

---

## 19. stderr llega FRAGMENTADO

Los datos del evento `Error` llegan en **trozos de 256 bytes que parten líneas al medio**, e incluso pueden partir un carácter multibyte:

```
[STDERR] largo=256 -> ...Premature end of data in tag a line 1\n<a><b>sin cerrar</a>\n
[STDERR] largo=18  -> ^\n
```

REGLA: el handler **solo acumula**. Nunca parsear ahí. Concatenar primero y recién después usar `String.*`; validar o cortar trozo por trozo rompería la codificación (SC-02, RC-GM-12).

Lo mismo vale para stdout cuando la salida es larga.

---

## 20. `Exec ... To` para stdout, eventos para stderr

**`Exec ... To` NO captura stderr.** Verificado: con un XML mal formado, `xmllint` reportó el error y la variable quedó con largo 0.

Pero **sí captura stdout**, y eso alcanza y sobra cuando la herramienta entrega su resultado por la salida estándar:

```gambas
' RESULTADO POR STDOUT: FORMA SÍNCRONA, CINCO LÍNEAS
Try Exec ["xmllint", "--nonet", "--xpath", sExpresion, sRuta] To sSalida

' DIAGNÓSTICOS POR STDERR: HACE FALTA EL MECANISMO DE EVENTOS
```

REGLA: el aparato asíncrono, con su bucle de espera, su drenaje y su vencimiento de plazo, se reserva para cuando hay que leer la **salida de error**. Para todo lo demás, la forma síncrona.

---

## 21. Saxon-HE no expone NINGUNA función de extensión `saxon:`

No es que falte `saxon:line-number()`: es el namespace entero.

```
XPST0017  Cannot find a 1-argument function named Q{http://saxon.sf.net/}line-number().
Saxon extension functions are not available under Saxon-HE
```

Verificado sobre **SaxonJ-HE 12.9 / Java 21**, con `-l:on` y sin él.

Vale para todos los XSLT del proyecto, no solo para el auditor: cualquier `saxon:evaluate()`, `saxon:serialize()` o `saxon:parse()` de un ejemplo de internet está fuera de alcance.

---

## 22. `xmllint --xpath` no conoce los namespaces del documento

Aunque el documento declare `xmlns:xlink`, la expresión falla:

```
xmllint --xpath '//graphic/@xlink:href' archivo.xml
  -> XPath error : Undefined namespace prefix
```

La forma agnóstica funciona y además sirve para los archivos que declaran el mismo namespace con otro prefijo:

```
xmllint --xpath "//graphic/@*[local-name()='href']" archivo.xml
```

Consecuencia para el auditor: los XPath que se muestran como ubicación de un hallazgo deben escribirse así, no con el prefijo — si no, el proveedor de la revista los pega en su editor y no funcionan.

---

## 23. El patrón que se repitió tres veces en esta sesión

No es un comportamiento de Gambas sino una consecuencia de varios de ellos, y merece quedar escrito:

> **Un `Try` seguido de `Return` silencioso es un canal mudo.** Si el `If Error` no informa a algún lado —ni siquiera con un `Print` durante el desarrollo— el fallo se manifiesta lejos de su causa, como un resultado vacío que parece un dato legítimo.

Los tres casos de la sesión: el `Exec` que fallaba por una firma de handler y devolvía su mensaje por un canal que el llamador descartaba; el `Line Input` que perdía la salida sin salto de línea final y devolvía cadena vacía; y los `Return Null` de `AnalizarArchivo`, que hacían desaparecer archivos de la grilla sin explicación.

RC-GM-02 no pide solo verificar el error: pide **hacer algo** con él.

---

# Sesión de Schematron y conformidad JATS4R (agosto 2026)

Continúa la numeración anterior. Mismo entorno: **Gambas 3.22 / Qt5 / Linux Mint**, máquina de desarrollo real.

El primero de estos apartados es el más importante de todo el documento, porque invalida una suposición que el proyecto arrastraba en seis funciones de cuatro módulos distintos.

---

## 24. `ByRef` NO EXISTE en la práctica: los primitivos van siempre por valor

**Verificado en seis variantes, todas fallan:**

| caso | resultado |
|---|---|
| `Sub` con `ByRef Integer` | no propaga |
| `Function` con `ByRef Integer` | no propaga |
| `Function` con `ByRef String` | no propaga |
| parámetro sin la palabra `ByRef` | no propaga |
| función **pública** llamada desde otro módulo | no propaga |
| **array como parámetro** | **SÍ propaga** |

```gambas
Private Sub PonerEnDiez(ByRef iSalida As Integer)
  iSalida = 10
End

iValor = 0
PonerEnDiez(iValor)
Print iValor        ' -> 0, NO 10
```

En Gambas los tipos primitivos se pasan **siempre por valor**, con `ByRef` o sin él. Los objetos —arrays y clases— se pasan **siempre por referencia**. No hay forma de devolver un `Integer` o un `String` por parámetro.

Es herencia de VB, donde `ByRef` no solo existe sino que es el modo **por defecto**. Por eso el error es tan fácil de cometer y tan difícil de ver: **compila, no da ningún aviso, y la variable del llamador simplemente queda como estaba**. El fallo se manifiesta lejos, como un dato vacío que parece legítimo.

En este proyecto había seis funciones así, y las seis estaban rotas en silencio: una convertía posiciones a línea y columna para el corrector ortográfico, dos extraían el nombre de un shortcode, una leía configuración de un XSLT, y dos devolvían la salida de procesos externos.

Y produjo un síntoma que costó tres intentos diagnosticar: una función auxiliar que devolvía la posición de avance por `ByRef` dejaba el índice en cero, `InStr` volvía a encontrar la primera coincidencia y **el bucle no terminaba nunca**, con la interfaz congelada y sin ningún mensaje.

REGLA: nunca usar un parámetro como canal de salida para un primitivo. Las alternativas, por orden de preferencia:

1. **Invertir el retorno.** Si la función devuelve `Boolean` más un dato, que devuelva el dato y que el vacío signifique falso.
2. **Una clase pequeña**, cuando los datos tienen sentido juntos: una posición es línea y columna, no dos enteros sueltos.
3. **Un array como canal**, que sí funciona por ser objeto.
4. **Variable de módulo con accesor**, cuando el dato es un subproducto y no el resultado.

---

## 25. Saxon 12 resuelve la DTD por red y NO se lo puede impedir

Un XML de 70 KB con DOCTYPE de JATS tarda **ocho segundos** en parsear con Saxon. El desglose ubica la causa sin ambigüedad:

| medición | tiempo |
|---|---|
| arranque de la JVM sin hacer nada | 0,24 s |
| ese XML con una plantilla que no hace nada | 12,87 s |
| una regla real sobre un XML mínimo | 0,57 s |
| el mismo comando **sin red** (`unshare -rn`) | 0,42 s, y falla |

No es la JVM ni son las reglas: es **parsear ese XML**. `strace` confirma dos conexiones salientes. Saxon va a buscar la DTD a `jats.nlm.nih.gov` en cada archivo.

**Ninguna opción lo evita.** Se probaron `-Djavax.xml.accessExternalDTD`, `-Djavax.xml.accessExternalSchema`, `-dtd:off`, `-Dxml.catalog.ignoreMissing` y `-Dxmlresolver.properties`: el tiempo no cambió en ningún caso. El resolvedor de Saxon 12 ignora las propiedades estándar de JAXP.

SOLUCIÓN: cuando la DTD no hace falta para la transformación, entregarle a Saxon una copia **sin DOCTYPE**. Verificado: 0,43 s en lugar de 8,1 s, con resultados idénticos.

Al recortar el DOCTYPE hay que **contar corchetes**: el de JATS trae declaraciones de entidades entre `[` y `]`, que contienen sus propios `>`. Cortar en el primero rompe el documento — un `sed` ingenuo dejó el prefijo `ali` sin enlazar.

Esto es la **contracara de RC-XJ-03**, y las dos reglas deben leerse juntas: allí el problema era que Saxon *no conseguía* la DTD y la solución fue permitirle buscarla; acá la busca cuando no hace falta.

Vale para todo el proyecto, no solo para el auditor: cualquier cadena XSLT que reciba un JATS con DOCTYPE remoto está pagando esos ocho segundos por archivo.

---

## 26. Los Schematron de JATS4R no se ejecutan tal como se distribuyen

Cuatro problemas distintos, todos verificados:

**El `.xsl` publicado en el repositorio está mal compilado.** Un `<xsl:function>` quedó sin `@name`, con lo que tres de las cuatro funciones `j4r:` no se declaran y Saxon aborta con `XPST0017`.

**`compile-for-svrl.xsl` de SchXslt 1.10.1 copia solo la primera `<xsl:function>`** del `<schema>` y descarta las demás. De las cuatro de `jats4r.sch` sobrevive una.

**Los archivos temáticos no son documentos Schematron completos.** Empiezan en `<pattern>` y están pensados para entrar por `<include>`. Sueltos dan *"this document contains more than one top-level element"*. Necesitan un envoltorio con las declaraciones de namespace del maestro.

**Y hay reglas que abortan con estructuras normales.** Una regla sobre `<sec>` llama a `normalize-space()` sobre un conjunto de títulos y falla con `XPTY0004` en cuanto un artículo tiene subsecciones. En el corpus de referencia, doce secciones de un solo artículo tenían más de un título. Como Saxon aborta, **se pierde el análisis del archivo entero**, no solo esa regla.

COMBINACIÓN QUE FUNCIONA: `include.xsl` de SchXslt para resolver los includes, esqueleto ISO `iso_svrl_for_xslt2.xsl` para compilar. Cada implementación aporta lo que la otra rompe.

REGLA: compilar y ejecutar **temático por temático**, nunca el maestro completo, y verificar cada grupo contra un corpus real antes de darlo por bueno. Que una regla compile no garantiza que ejecute.

---

## 27. El SVRL no trae identificador por aserción

Un `<svrl:failed-assert>` trae `@test`, `@role` y `@location`, pero **no `@id`**. La clave estable para identificar una regla es el par **patrón + test**:

```xml
<svrl:active-pattern id="general-citations-errors"/>
<svrl:fired-rule context="element-citation|mixed-citation"/>
<svrl:failed-assert test="@publication-type" role="error"
                    location="/article[1]/back[1]/ref-list[1]/ref[3]/mixed-citation[1]"/>
```

El `@location` viene **resuelto, con predicados numéricos y sin prefijos de namespace**, así que se puede pegar en cualquier editor XML y funciona.

Dos detalles del parseo:

- La severidad se lee del `@role` de la aserción y **no de la fase ejecutada**: la fase `errors` de JATS4R activa un patrón de advertencias, así que fiarse de la fase da severidades equivocadas.
- Los `<successful-report>` **también llevan `<svrl:text>`**. Un parseo que emita un mensaje cada vez que ve esa etiqueta cuenta reportes informativos como errores.

---

## 28. `pipeline-for-svrl.xsl` de SchXslt compila pero no ejecuta

Invocado con `document=archivo.xml`, produce el **XSLT compilado**, no el informe SVRL. La raíz de la salida es `<xsl:transform>` y los atributos aparecen como plantillas sin evaluar: `location="{schxslt:location(.)}"`.

Consecuencia práctica en este proyecto: durante un tiempo se contaron los `<failed-assert>` de ese archivo creyendo que eran incumplimientos. Eran **las reglas**, así que el resultado era idéntico para cualquier XML de entrada.

REGLA: verificar siempre que la salida contenga `schematron-output` antes de parsearla. Es una comprobación de dos líneas que habría ahorrado el diagnóstico entero.

El pipeline correcto es de tres pasos: `include.xsl` → esqueleto ISO para compilar → ejecutar el `.xsl` resultante sobre el documento. Y los dos primeros se hacen **una sola vez**, en la compilación del paquete.


