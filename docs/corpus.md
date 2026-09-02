# Corpus normativo de gbpublisher

Documento generado desde la base del corpus. No editar a mano:
los cambios se hacen en la aplicación y se vuelve a exportar.

---

## RC-GM — Reglas críticas Gambas

Comportamientos del lenguaje que obligan a un patrón determinado

### RC-GM-01 — TINYINT(1) no es Integer

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

MySQL devuelve `TINYINT(1)` como `Boolean` en Gambas.

NUNCA:

    CInt(resultado["campo"]) = 1

SIEMPRE:

    resultado["campo"] = True

### RC-GM-02 — Try no interrumpe la ejecución

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Si un `Try` falla silenciosamente, el código continúa con datos incorrectos o vacíos. Verificar siempre con `If Error Then` inmediatamente después del `Try`.

Y no alcanza con verificar: hay que HACER algo con el error. Un `Try` seguido de un `Return` silencioso es un canal mudo, y el fallo se manifiesta lejos de su causa (ver GV-23).

**Relaciones:** apoya:GV-23

### RC-GM-03 — Guardar en el evento, no en el botón

**Estado:** vigente · **Evidencia:** inferida

Los campos críticos (por ejemplo `es_autor_correspondencia`) deben guardarse en el evento del control (`CheckBox_Click`) para evitar que una deselección previa al guardado deje el dato sin escribir en la base.

### RC-GM-04 — Verificar las columnas antes de usarlas en un SELECT

**Estado:** vigente · **Evidencia:** inferida

Confirmar con `SHOW COLUMNS FROM tabla` que el campo existe exactamente con ese nombre.

Un campo inexistente puede lanzar un error silencioso que corta la ejecución sin advertencia visible.

**Relaciones:** apoya:RC-GM-02

### RC-GM-05 — Recompilar siempre desde el IDE

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Gambas no recompila automáticamente al guardar.

Después de cualquier cambio: Proyecto → Limpiar, y luego Proyecto → Compilar, antes de probar.

### RC-GM-06 — Firmas de Goto y Select en TextEditor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.editor

TextEditor usa el orden `(Column, Line)` en TODOS los métodos de posicionamiento, igual que `Goto`. NO seguir la convención semántica "línea primero, columna después" que sugieren las propiedades de lectura (`Line`, `Column`, `SelectionLine`, `SelectionColumn`).

Firmas confirmadas:

    Goto(Column As Integer, Line As Integer)
    Select(Column1 As Integer, Line1 As Integer, Column2 As Integer, Line2 As Integer)

Síntoma de inversión en archivos largos: la selección abarca múltiples líneas en lugar del rango intra-línea esperado.

Síntoma en archivos cortos: la selección queda vacía por clamp a `Max`, lo que enmascara el bug. Probar SIEMPRE en archivos largos.

### RC-GM-07 — Restaurar el foco después de los eventos de UI

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.editor

El click en un botón transfiere el foco al botón. Cualquier modal posterior (`Message.Info/Warning/Error`) refuerza esa pérdida.

Si la acción modifica el editor o el usuario espera seguir escribiendo, restaurar el foco explícitamente AL FINAL del evento, después de cualquier `Message.*`:

    txtEditorProyecto.SetFocus()

Aplica a: botones de toolbar de formato (Bold, Italic, footnote), botones de guardar, botones de inserción de plantillas, y todo botón cuyo flujo natural deje al usuario editando.

### RC-GM-08 — Try / If Error también en las operaciones de TextEditor

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22 / gb.form.editor

`Insert`, `Goto`, `Select`, `Load` y `Save` del TextEditor pueden fallar silenciosamente: estado interno inválido, archivo bloqueado, posición fuera de rango.

Aplicar el patrón de RC-GM-02 a cada llamada que modifique estado o cursor:

    Try txtEditor.Insert(sTexto)
    If Error Then
      m_Sonido.sonar("Error")
      Message.Error("Mensaje: " & gb.NewLine & Error.Text)
      Return
    Endif

Excepción razonable: el último `SetFocus` del evento no requiere `Try`, porque su fallo no compromete el estado de los datos.

**Relaciones:** apoya:RC-GM-02

### RC-GM-09 — Numeración por máximo, no por conteo

**Estado:** vigente · **Evidencia:** inferida

Para identificadores secuenciales en estructuras donde el usuario puede borrar elementos intermedios (footnotes, items numerados, marcas de revisión), determinar el siguiente número buscando el MÁXIMO ya usado y sumando 1, NUNCA contando las ocurrencias existentes y sumando 1.

Razón: si hay 5 footnotes y el usuario borra la `[^3]`, el conteo devuelve 4 y el siguiente sería `[^5]`, que ya existe. Colisión silenciosa que rompe el renderizado posterior.

Aplica a: `ContarFootnotes` (deprecado) → `ObtenerSiguienteNumeroFootnote`.

### RC-GM-10 — Las constantes de teclado: las letras no son propiedades

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

La clase `Key` solo tiene constantes nombradas para teclas especiales (`Key.Esc`, `Key.Return`, `Key.F1`, `Key.BackSpace`, flechas, etc.). Para letras NO existe `Key.S`, `Key.A`, etc. Se accede con notación de array indexable por nombre de tecla:

    If Key.Control And Key.Code = Key["S"] Then ...

Nota sobre X11: según declaración del autor de Gambas, X11 cambió el manejo de teclas y puede haber inconsistencia entre `Key["S"]` (mayúscula) y `Key["s"]` (minúscula) según la versión del servidor X. Si el atajo no responde con un caso, probar el otro antes de recurrir a `Key.Text`, que se contamina con Ctrl y reporta caracteres de control en lugar de la letra.

Aplica a cualquier handler `_KeyPress` o `_KeyRelease` que intercepte combinaciones con letras.

### RC-GM-11 — Cachear los IDs de sesión al login

**Estado:** vigente · **Evidencia:** inferida

Si un dato requiere consultar la base (típicamente IDs derivados de un campo no clave, como el nombre de usuario), cachearlo en una variable global de sesión al iniciar sesión, y no consultar la base cada vez que se necesita.

    ' EN m_InicioCierre:
    Public UsuarioEnCurso As String
    Public IdUsuarioEnCurso As Integer

    ' EN EL FLUJO DE LOGIN (FLogin), DESPUÉS DE VALIDAR CREDENCIALES:
    m_InicioCierre.UsuarioEnCurso = usuario

    ' CACHEAR EL ID NUMÉRICO ASOCIADO
    Try rsId = mConn.Exec("SELECT id FROM usuarios WHERE usuario = &1 LIMIT 1", usuario)
    If Error Or If Not rsId.Available Then
      ' DESHACER LOGIN PARCIAL Y ABORTAR
    Endif
    m_InicioCierre.IdUsuarioEnCurso = rsId["id"]

    ' EN EL LOGOUT (FLogin, m_InicioCierre.CerrarTodoMySQL):
    m_InicioCierre.UsuarioEnCurso = ""
    m_InicioCierre.IdUsuarioEnCurso = 0

Razón: las validaciones de autoría se repiten muchas veces por sesión —cada click en `gridNotas`, cada guardado, cada borrado—. Consultar la base cada vez es overhead innecesario y, peor, acopla la lógica de UI a la disponibilidad de la base: si MySQL tartamudea, la UI deja de responder o falla validaciones por timeout.

**Relaciones:** vinculo:RC-GM-16

### RC-GM-12 — String.* para operar con caracteres UTF-8 multibyte

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Las funciones sin prefijo (`Len`, `Mid`, `InStr`) operan en BYTES, no en codepoints UTF-8. Esto rompe silenciosamente para caracteres multibyte (¿, ¡, «, », tildes, comillas tipográficas curvas):

    ' MAL — Mid devuelve 1 BYTE, no 1 caracter
    For i = 1 To Len(texto)
      If Mid(texto, i, 1) = "¿" Then ...  ' NUNCA MATCHEA
    Next

Patrón seguro para iterar codepoint a codepoint: `String.Len` y `String.Mid`.

Patrón seguro y eficiente para buscar o contar ocurrencias de un carácter: `InStr` con offset, que es byte-oriented pero correcto en UTF-8 válido, porque los bytes de un carácter multibyte nunca aparecen como bytes válidos de otros caracteres.

    Do
      iPos = InStr(sTexto, sCaracter, iPos)
      If iPos = 0 Then Break
      Inc iCuenta
      iPos += Len(sCaracter)
    Loop

Síntoma de este bug: la cuenta de caracteres ASCII funciona pero la de caracteres del español devuelve siempre 0. La consecuencia visual en validadores tipo ContarCaracteresPares es que la columna del carácter multibyte siempre aparece roja sin importar el contenido del archivo.

**Relaciones:** apoya:GV-03, vinculo:SC-02

### RC-GM-13 — Variables de retorno entre formularios modales: módulos, no Public en el form

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Las variables `Public` declaradas en un form NO sirven como canal de retorno si el form se cierra después de escribirlas. Al hacer `Me.Close()` la instancia se destruye y el valor se pierde. Cuando el llamador intenta leer la variable, Gambas instancia un form nuevo, con la variable en su valor inicial.

Para canal de retorno entre formularios usar siempre variables globales en un módulo (`m_FuncionesGenericas.X`, `m_Metadatos.X`, etc.).

Patrón canónico ya en uso: `m_FuncionesGenericas.sCreditSeleccionado` (FCreditRoles) y `m_FuncionesGenericas.iAutorSeleccionadoEnFAutores` (FAutores).

Síntoma del bug: el modal se cierra normalmente pero el llamador "no ve" el resultado.

### RC-GM-14 — DateBox.ReadOnly no bloquea el botón del calendario

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

`DateBox` es internamente un `ButtonBox` más una máscara de fecha y un diálogo `DateChooser`. Poner `ReadOnly = True` solo bloquea la edición manual de la máscara: el botón del calendario sigue activo y permite seleccionar otra fecha, que reemplaza el valor.

Para hacer un campo de fecha realmente inmutable desde la UI, usar `Enabled = False` (idiomático), o reemplazar el control por un `TextBox` con `ReadOnly = True` y formatear la fecha como string.

Aplica especialmente a campos de auditoría:

`fecha_creacion_registro`,
`fecha_actualizacion_registro`.

**Relaciones:** vinculo:RC-GM-19

### RC-GM-15 — Connection.Exec con &10 o más placeholders es inestable

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

El parser de placeholders de `Connection.Exec()` reemplaza `&N` por substring matching, lo cual rompe cuando hay `&10` o superiores: primero matchea `&1` dentro de `&10` y deja el `0` suelto sin escapar.

Síntoma: error de sintaxis SQL con el valor del primer parámetro pegado a un dígito.

Para queries con muchos campos, usar siempre el patrón Edit + Update:

    r = hConn.Edit("tabla", "id = &1", iId)
    With r
      !campo1 = valor1
      !campo2 = valor2
      ...
      Try .Update()
    End With

Asignación por nombre y no por posición, sin límite de cantidad de campos, sin riesgo de invertir parámetros.

### RC-GM-16 — Los IDs de sesión van a variables globales, no a controles de UI

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Los `ValueBox` / `TextBox` de FMain (típicamente `id_articulo`, `id_capitulo`) NO son confiables como fuente de verdad para los IDs activos: pueden resetearse silenciosamente por eventos de UI (cambio de foco, modales, `_Activate`).

El patrón canónico es cachear en variables `Public` de `m_InicioCierre`, populadas en el handler del combobox y leídas por todos los consumidores. Reset al logout y al abrir proyecto.

El bug se manifiesta como: "el botón pide reseleccionar el artículo después de un cambio de foco aunque el artículo está abierto en el editor". Si aparece en cualquier flujo nuevo, la solución es migrar el ID a global, no agregar otro workaround del tipo derivar desde el nombre del archivo.

### RC-GM-17 — And y Or no son short-circuit

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint

Ambas expresiones se evalúan siempre, incluso si el resultado ya está determinado por la primera. Patrones defensivos como:

    If Not IsNull(campo) And CInt(campo) > 0 Then ...

fallan con Type mismatch cuando `campo` es NULL: el `CInt(NULL)` se ejecuta igual y crashea.

El patrón correcto es el `If` anidado:

    If Not IsNull(campo) Then
      If CInt(campo) > 0 Then ...
      Endif
    Endif

Regla operativa: nunca combinar un null-check con una operación que dependa del null-check en la misma línea `And`/`Or`. Separarlos siempre en bloques `If` anidados.

Aplica a: null-checks con conversiones (`CInt`, `CStr`, `CFloat`), null-checks con acceso a propiedades, y validaciones de rango que asumen no-null.

**Relaciones:** apoya:GV-02, vinculo:GV-12

### RC-GM-18 — Declarar los Dim al inicio de la función (convención de estilo)

**Estado:** corregida · **Evidencia:** empirica · **Entorno:** Código fuente del compilador Gambas

CORRECCIÓN DE MECANISMO, verificado en el compilador (`main/gbc/gbc_trans_code.c`, función `TRANS_local`): la afirmación previa de que "un Dim con inicialización inline dentro de un condicional se procesa al inicio y su asignación falla silenciosamente" es FALSA.

Lo que hace el compilador: para un `Dim` no estático, solo el SLOT de la variable se reserva al inicio de la función (no hay ámbito de bloque: la variable existe en toda la función). Pero el CÓDIGO de la inicialización se emite EN EL PUNTO TEXTUAL donde está escrito el `Dim`. Un `Dim x As New JSONCollection` dentro de un `While` se ejecuta en cada iteración y crea un objeto nuevo cada vez, como uno esperaría.

REGLA DE ESTILO: declarar todos los `Dim` al inicio de la función por legibilidad y consistencia, NO porque la inicialización inline falle.

SÍNTOMA HUÉRFANO: la regla nació de un caso observado, un bloque condicional con `Dim` inline que no emitía output aunque las condiciones se cumplían. Como el mecanismo atribuido era falso, esa causa sigue SIN identificar. Si el síntoma reaparece, buscar la causa real: posible `Try` que traga un error, o una condición que no se cumple como se cree.

**Relaciones:** apoya:RC-GM-02

**PENDIENTE:** El síntoma original que dio origen a la regla sigue sin diagnóstico. Si reaparece, no atribuirlo al Dim inline.

### RC-GM-19 — Dialog.Filter es cosmético, no un mecanismo de control

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Dialog.Filter` es case-insensitive en Qt5. Un patrón `r-*.md` lista también `r-03REVISTA.MD` y `r-03revista.md`.

El filtro del diálogo es comodidad visual, no validación: cualquier regla sobre el nombre de archivo debe verificarse en código después de `Dialog.Path`, sobre el nombre original y sin `LCase`.

**Relaciones:** vinculo:GV-16

### RC-GM-20 — No hay bloque Try/Catch: hay dos mecanismos de error de alcances distintos

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** gambaswiki.org/wiki/lang/try, /lang/catch, /lang/finally · **Verificado:** 2026-08

Escribir `Try ... End Try` es error de compilación. La confusión viene de VB/.NET y de código generado por IA. Lo que existe es:

NIVEL SENTENCIA — `Try` + `If Error`

`Try` protege UNA sola sentencia y no interrumpe el flujo (RC-GM-02). Es el mecanismo por defecto del proyecto: falla donde falla, se verifica ahí mismo, se decide ahí mismo.

    Try hResultado = mConn.Exec(...)
    If Error Then
      m_Sonido.sonar("Error")
      Message.Error("...: " & gb.NewLine & Error.Text)
      Return
    Endif

NIVEL FUNCIÓN — secciones `Finally` y `Catch`

No son bloques: son secciones terminales de la función, entre el cuerpo y el `End`. Orden obligatorio: primero `Finally`, después `Catch`.

    Public Sub Algo()
      ' CUERPO
    Finally
      ' SIEMPRE — CON LA SALVEDAD DE ABAJO
    Catch
      ' SOLO SI HUBO ERROR
    End

`Catch` atrapa además los errores de funciones llamadas que no tengan su propio `Catch`: gana el más cercano al error. Y NO se protege a sí mismo: un error dentro del `Catch` se propaga.

TRAMPA CRÍTICA DE `Finally`

`Finally` NO corre en un `Return` normal. Documentación oficial (gambaswiki.org/wiki/lang/finally): si se sale con `Return` antes del `Finally`, esa parte solo se ejecuta si se disparó un error.

Consecuencia directa para gbpublisher: `Finally` NO SIRVE para liberar recursos (cerrar archivos, liberar locks de proyecto, restaurar foco) en funciones con guardas de salida temprana, que son casi todas. La liberación va explícita antes de cada `Return`, o se centraliza en una función de limpieza invocada en cada camino. Esto es lo que hace RC-GM-07 con `SetFocus()` y SC-07 con la liberación atómica de recursos en la base.

REGLA OPERATIVA

1. Por defecto, `Try` + `If Error` en el punto de falla.
2. `Catch` solo como red de último recurso en funciones cuyo fallo total sea aceptable y no deba propagarse. Ejemplo en el proyecto: `LeerLeyendaCSL()`, lectura de metadatos opcionales.
3. `Finally` no se usa para liberar recursos. Si aparece la necesidad, revisar si el problema real es que la función tiene demasiados caminos de salida.
4. Nunca `End Try`. Nunca `Catch` como bloque a mitad de función.

**Relaciones:** apoya:RC-GM-02, vinculo:RC-GM-07, vinculo:SC-07

**PENDIENTE:** Verificar empíricamente el comportamiento de Finally con Return en 3.22.1 antes de comprometer código que dependa de él.

---

## RC-XJ — Reglas críticas XSLT + JATS

Transformación y validación de XML de revistas

### RC-XJ-01 — Derivar xml:lang en cascada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Saxon-HE 12 / JATS 1.4

Artículos sin resumen (editoriales, reseñas, obituarios) no tienen `<abstract xml:lang="...">`.

La variable `$xmlLang` debe implementarse con `<xsl:choose>` en cadena:

1. `abstract/@xml:lang`
2. `custom-meta[meta-name='xml-lang']/meta-value`
3. `'es'` como último recurso.

**Relaciones:** apoya:RC-XJ-02

### RC-XJ-02 — Propagar datos de la base como custom-meta

**Estado:** vigente · **Evidencia:** inferida

Cuando un dato necesario para el XSLT proviene de la base y no del manuscrito, se escribe en el front XML como `<custom-meta>` dentro de `<custom-meta-group>`.

NO usar parámetros de Saxon para esto: el XML canónico debe ser autónomo y reproducible por sí solo, sin depender de la línea de comandos que lo transformó.

### RC-XJ-03 — El I/O error de Saxon puede ser la DTD remota

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.9 / Java 21

Si Saxon falla con `I/O error reported by XML parser`, verificar si intenta cargar `https://jats.nlm.nih.gov/...`.

Solución: agregar `-Djavax.xml.accessExternalDTD=all` al comando Java.

ATENCIÓN: leer junto con GV-25, que es su contracara. Acá el problema es que Saxon NO CONSIGUE la DTD y la solución es permitirle buscarla; allá la busca cuando no hace falta y cuesta ocho segundos por archivo.

**Relaciones:** contracara:GV-25

---

## RC-DB — Reglas críticas DocBook

Modelo de contenido y serialización de libros

### RC-DB-01 — biblioref es EMPTY en DocBook 5.2

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** DocBook 5.2

No acepta texto interior. Emitir siempre como self-closing:

    <biblioref linkend="bib-X" role="modo"/>

El texto formateado de la cita lo genera el XSLT de salida según el CSL.

### RC-DB-02 — Content model estricto de chapter y section

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** DocBook 5.2

Los bloques de contenido (`<para>`, `<figure>`, `<table>`, etc.) deben ir ANTES de cualquier `<section>` hija.

En Markdown esto se traduce a: poner los divs no estructurales antes de los `##` que abren subsecciones.

### RC-DB-03 — Los elementos formales requieren title

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** DocBook 5.2

`<example>`, `<figure>`, `<table>` y `<equation>` son formal objects y exigen `<title>` (o `<info>`) como primer hijo.

Sus variantes sin numeración formal (`<informalexample>`, `<informalfigure>`, etc.) no exigen título pero pierden la numeración automática.

### RC-DB-04 — dialogue y poetry están en Publishers, no en base

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** DocBook 5.2

DocBook 5.2 base no tiene `dialogue`, `poetry` ni `drama`.

Para verso: `<literallayout role="verse">`.
Para parlamento: `<para role="speech">` con `<emphasis role="speaker">`.

### RC-DB-05 — XSLT 2.0 sigue regex de XSD, no PCRE

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Saxon-HE 12 / XSLT 2.0

No usar `\x00-\x7F` ni `\d` / `\s` con semántica Perl.

Para "no ASCII": `[^\p{IsBasicLatin}]`
Para dígitos: `[0-9]` o `\p{N}`

**Relaciones:** contracara:RC-PL-01

### RC-DB-06 — Namespaces de los fragmentos de Pandoc

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc / DocBook 5.2

Pandoc emite el body sin `xmlns:mml`, asumiendo que el wrapper lo declara. Antes de procesarlo con Saxon hay que inyectar `xmlns:mml="http://www.w3.org/1998/Math/MathML"` en el `<section>` raíz.

Es análogo al `xlink` en revistas. En producción la inyección la hace Gambas, en `m_GenerarSalidas`.

**Relaciones:** apoya:RC-DB-07

### RC-DB-07 — Filtro Lua y wrapper de namespace en la serialización interna

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc / filtros Lua

`pandoc.write(doc, 'docbook5', PANDOC_WRITER_OPTIONS)` propaga las opciones de math del comando original.

Sin eso, el math display se renderiza como markup inline y no como MathML.

### RC-DB-08 — copy-namespaces=no en la plantilla de identidad

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Saxon-HE 12 / XSLT 2.0

Cuando se hace `apply-templates` sobre nodos cargados con `document()`, el identity template debe usar `copy-namespaces="no"` para que los descendientes no redeclaren `xmlns` redundantes.

---

## RC-PL — Reglas críticas Perl

Motor de expresiones regulares externo

### RC-PL-01 — En los reemplazos con regex nunca /e ni /ee

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** perl-base / -CSD

El modo `s///e` evalúa el string de reemplazo como código Perl; `s///ee` lo evalúa dos veces. Con un reemplazo que viene del usuario, eso es ejecución de código arbitrario:

    s/x/$rep/ee   con   $rep = 'system("id")'   ->   ejecuta system("id")

El script `engine/buscar_regex.pl` expande las referencias del reemplazo A MANO (`$0..$99`, `${nombre}`, `$$`, y los escapes de carácter `\n` `\t` `\xHH` `\x{HHHH}` `\\`), tratando todo lo demás como literal. NUNCA hay un `s///e` en el script y no puede haberlo: es verificable con grep.

El patrón de BÚSQUEDA, en cambio, ya está protegido por Perl, que rechaza `(?{...})` en patrones que vienen de variable ("Eval-group not allowed at runtime").

**Relaciones:** apoya:SC-05

---

## SC — Soluciones canónicas

Decisiones cerradas: aplicar, no rediscutir

### SC-01 — Caracteres especiales en strings (convención de estilo)

**Estado:** corregida · **Evidencia:** empirica · **Entorno:** Código fuente del lexer de Gambas

CORRECCIÓN DE MECANISMO, verificado en el lexer del compilador (`main/gbc/gbc_read.c`): la afirmación previa de que "Gambas no interpreta secuencias de escape en strings literales" es FALSA. El compilador SÍ interpreta escapes con backslash.

Tabla real de escapes válidos en un literal de string:

    \n    LF (salto de línea)
    \t    tab
    \r    CR
    \b    backspace
    \v    tab vertical
    \f    form feed
    \e    ESC (0x1B)
    \0    NUL
    \"    comilla doble literal
    \'    comilla simple literal
    \\    backslash literal
    \xHH  carácter por código hexadecimal de dos dígitos

CUALQUIER OTRO backslash+letra (`\d`, `\w`, `\s`) es ERROR DE COMPILACIÓN: "Bad character constant in string". Esto es lo que invalida la justificación de la vieja SC-05, hoy deprecada como SC-10.

REGLA DE ESTILO: preferir `Chr(34)` y `Chr(10)` a los escapes, porque son explícitos y no dependen de recordar la tabla de arriba.

- `Chr(34)` para comillas dobles
- `Chr(10)` para salto de línea (LF)
- `Chr(13) & Chr(10)` si se necesita CRLF

Ejemplo en el estilo preferido:

    "INSERT INTO t VALUES(" & Chr(34) & sValor & Chr(34) & ")"

Nota: `"\n"` SÍ produce un salto de línea real y `"\d"` NO compila. El código viejo del proyecto que usa `"\n"` —por ejemplo los botones de git en `m_GitHub`— funciona correctamente por esto; no estaba roto pese a la regla, la regla estaba mal justificada.

### SC-02 — UTF-8 en los archivos Markdown y TeX

**Estado:** vigente · **Evidencia:** inferida

Los archivos `.md` y `.tex` son siempre generados por Pandoc en Linux, por lo que llegan en UTF-8 sin BOM. La regla es preservar esa codificación en toda manipulación posterior.

- Gambas: usar `File.Load(ruta)` y `File.Save(ruta, contenido)`, que operan en UTF-8 nativamente. No pasar parámetros de codificación ni recodificar.
- Para recorrer o cortar contenido, usar `String.Len()` y `String.Mid()`, NUNCA `Len()` / `Mid()`, porque las funciones sin prefijo operan en bytes y pueden cortar caracteres multibyte.
- Pandoc: invocar sin flags de codificación. UTF-8 es su default en entrada y salida.
- LuaLaTeX: consume UTF-8 nativamente. NO usar `\usepackage[utf8]{inputenc}` ni `[latin1]`.
- Shell: no se requiere `LANG` explícito. Documentarlo igualmente en `integridad.sh` como precondición verificable.

PROHIBIDO: cualquier paso intermedio que recodifique a Latin-1, ISO-8859-1 o Windows-1252, aun de forma transitoria.

**Relaciones:** apoya:GV-03, apoya:GV-19

### SC-03 — Centralizar las constantes de UI en m_Constantes

**Estado:** vigente · **Evidencia:** inferida

Placeholders, etiquetas recurrentes, marcadores de formato y prefijos sintácticos van como `Public Const` en `m_Constantes`, no como literales repartidos por formularios.

    ' EN m_Constantes:
    Public Const FOOTNOTE_PLACEHOLDER As String = "Texto del footnote aquí"
    Public Const COMENTARIO_PLACEHOLDER As String = "Escribir comentario..."

    ' EN EL FORMULARIO:
    txtEditor.Insert(m_Constantes.FOOTNOTE_PLACEHOLDER)

Beneficios: i18n futura, búsqueda global de placeholders sin quedar incompletos, consistencia entre eventos que comparten el mismo texto, y posibilidad de detectar marcas sin completar buscando el literal exacto.

**Relaciones:** vinculo:GV-11

### SC-04 — Capturar las posiciones del editor, no calcularlas

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22 / gb.form.editor

Para seleccionar texto recién insertado, capturar `txtEditor.Line` y `txtEditor.Column` ANTES y DESPUÉS de cada `Insert()`. Nunca calcular columnas con `String.Len()` sobre el texto a insertar.

    Try txtEditor.Insert(sPrefijo)
    If Error Then ... : Return
    Endif
    iLineaIni = txtEditor.Line
    iColumnaIni = txtEditor.Column

    Try txtEditor.Insert(sPlaceholder)
    If Error Then ... : Return
    Endif
    iLineaFin = txtEditor.Line
    iColumnaFin = txtEditor.Column

    ' RECORDAR RC-GM-06: ORDEN (Col, Line, Col, Line)
    Try txtEditor.Select(iColumnaIni, iLineaIni, iColumnaFin, iLineaFin)

Razón: el editor tiene mejor información que cualquier conteo manual sobre saltos de línea implícitos, normalización de `EndOfLine` y caracteres multibyte.

**Relaciones:** vinculo:RC-GM-06, vinculo:RC-GM-08

### SC-05 — Expresiones regulares: motor perl externo, no gb.pcre

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** perl-base / -CSD / Gambas 3.22

DECISIÓN CERRADA: gbpublisher NO usa `gb.pcre` para expresiones regulares. El motor es perl invocado como proceso externo. Razones verificadas empíricamente:

- `gb.pcre` (PCRE2) tiene siete limitaciones duras para texto en castellano y para uso desde UI: offsets en BYTES y no en caracteres, sin constante UCP expuesta (`\w` `\b` `\d` rompen con acentos), `Exec` sin start-offset (obliga a truncar y rompe `\b` y lookbehind), match vacío que cuelga el proceso, sin timeout, sin grupos nombrados accesibles.
- Un match in-process no se puede cancelar (Gambas es single-thread en el loop de eventos); un proceso externo sí (`Process.Kill`).
- `perl-base` es Essential en Debian/Ubuntu: cero dependencias nuevas.
- perl con `-CSD` da offsets en CARACTERES y `\w` `\b` `\d` correctos en UTF-8 sin verbos ni configuración.

ARQUITECTURA DEL MOTOR

- Script: `engine/buscar_regex.pl`, en la instalación del sistema y NO en `~/.gbpublisher`: es infraestructura, no se personaliza; viaja en el `.deb` junto al módulo compilado, sin posibilidad de desincronización.
- Se invoca con `Exec ["perl", "-CSA", RutaScript(), <modo>, ...] To s` (síncrono) o `Exec ... For Read As "..."` (asíncrono con cancelación). NUNCA con `Shell`: el patrón del usuario tiene metacaracteres y no debe pasar por `sh -c`. El array literal de `Exec` va en UNA sola línea: partido con coma final, Gambas lo lee como String y da Type mismatch.
- La forma `Exec ... To` NO expone stdin, porque la cláusula `With` en esa forma es solo `With Error`. El texto de entrada que no es un archivo del proyecto va por archivo temporal: `Temp$()` + `File.Save` + `Kill`.
- Modos del script:
  - `validar` — compila y audita. Salida `OK\0grupos\0avisos` o `ERROR\0mensaje`.
  - `probar` — banco de pruebas en seco sobre un archivo.
  - `buscar` — aplica a una lista de archivos. Salida de ocho campos por coincidencia, separados por NUL.
- Campos separados por `Chr(0)`; el parseo en Gambas corta con `InStr` por los primeros NUL, NO con `Split` completo, porque el cuerpo puede contener datos.
- REGLA DE SEGURIDAD INVIOLABLE: nunca `/e` ni `/ee` en el `s///`. El string de reemplazo se expande a mano (`$1`, `${nombre}`, `\x{HHHH}`); `/ee` sería ejecución de código arbitrario del usuario.

DIVISIÓN GAMBAS ↔ PERL: perl ENCUENTRA Y CALCULA (offsets, texto de reemplazo ya expandido); Gambas ESCRIBE. perl nunca escribe archivos. El reemplazo aplica los offsets capturados de atrás para adelante por archivo, con `String.Mid` —caracteres, coherente con los offsets del script—, un solo `File.Load` / `File.Save` por archivo.

Para búsquedas triviales de substring sin metacaracteres, seguir prefiriendo `String.InStr`: no hace falta lanzar un proceso.

ATENCIÓN AL DIALECTO: perl y PCRE2 NO son el mismo motor. perl rechaza `(*UCP)` y `(?U)`, que PCRE2 acepta; perl acepta lookbehind de longitud variable, que PCRE2 rechaza. Validar con un motor y ejecutar con otro produce falsos positivos y negativos. Un solo motor: perl.

**Relaciones:** vinculo:GV-06, vinculo:GV-20

### SC-06 — Guard de cambios sin guardar antes de un cambio de contexto

**Estado:** vigente · **Evidencia:** inferida

Cualquier acción que cambie el contenido del editor o el proyecto activo (abrir otro proyecto, cambiar de archivo en el combobox, ir a modo parcial, cerrar la app) debe invocar `ConfirmarDescartarCambios()` AL INICIO de la función, ANTES de cualquier cambio visible en UI o reasignación de variables globales. Si retorna False, el flujo aborta con `Return` sin tocar nada.

    ' --- 1. GUARD: CAMBIOS SIN GUARDAR EN EL PROYECTO PREVIO ---
    If Not ConfirmarDescartarCambios() Then Return

Si la acción dispara un evento `_Click` de combobox como efecto colateral de asignar `Index`, usar la bandera `bAbriendoProyecto` para suprimir el guard interno del handler: ya se evaluó al inicio y no debe volver a preguntar.

    Public bAbriendoProyecto As Boolean = False

    bAbriendoProyecto = True
    AbrirProyectoMD(nTipoProyecto)
    bAbriendoProyecto = False

    ' EN EL HANDLER DEL COMBOBOX:
    If Not bAbriendoProyecto Then
      If Not ConfirmarDescartarCambios() Then Return
    Endif

Razón: si el guard se evalúa después de cambios en UI o variables globales, la pregunta aparece fuera de contexto y "Cancelar" no cancela realmente: solo aborta el handler local, no la acción raíz que disparó el cambio.

### SC-07 — Liberación atómica de recursos compartidos en la base

**Estado:** vigente · **Evidencia:** inferida

Cuando un usuario libera proyectos, locks o cualquier recurso identificado por owner, usar UNA sola sentencia que filtre por el owner, y no buscar primero y actualizar después basándose en variables de UI.

    ' INCORRECTO (frágil, desync entre rsCheck y FMain.id_proyecto.Value):
    rsCheck = mConn.Exec("SELECT id FROM proyectos WHERE usuario_propietario = &1 AND ocupado = 1", sUsuario)
    If rsCheck.Available Then
      mConn.Exec("UPDATE proyectos SET ocupado = 0 WHERE id = &1", FMain.id_proyecto.Value)
    Endif

    ' CORRECTO (atómico, robusto a inconsistencias):
    mConn.Exec("UPDATE proyectos SET usuario_propietario = NULL, ocupado = 0 " &
               "WHERE usuario_propietario = &1 AND ocupado = 1", sUsuario)

Razón: la versión incorrecta libera el recurso indicado por la UI, no el efectivamente ocupado por el usuario en la base. Si hay desync (cambio externo, otra instancia, bug previo), la liberación opera sobre el ID equivocado y deja el real colgado.

**Relaciones:** vinculo:RC-GM-16

### SC-08 — Escape de wildcards en el LIKE de MySQL

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** MySQL / MariaDB

Para que `%` y `_` se traten como literales en cláusulas `LIKE` (el comportamiento esperado en buscadores informales, donde el usuario no conoce los wildcards SQL), usar la cláusula `ESCAPE` con un carácter que no sea backslash. El backslash en código Gambas es problemático: algunos editores lo interpretan como escape de comillas o continuación de línea, y los strings `"\\"` pueden renderizarse mal al copiar y pegar.

    ' EN GAMBAS:
    sBusqueda = Replace(sBusqueda, "!", "!!")
    sBusqueda = Replace(sBusqueda, "%", "!%")
    sBusqueda = Replace(sBusqueda, "_", "!_")
    sBusqueda = "%" & sBusqueda & "%"

    ' EN LA CONSULTA:
    "WHERE campo LIKE &1 ESCAPE '!'"

El orden importa: primero escapar el carácter de escape mismo, luego los wildcards. Cualquier carácter no especial sirve —`!`, `#`, `@`—; elegir uno improbable en el texto buscado.

### SC-09 — Validar los caracteres self-paired por paridad

**Estado:** vigente · **Evidencia:** inferida

Los caracteres que actúan como apertura y cierre simultáneamente (la comilla recta es el ejemplo paradigmático en textos académicos) no pueden validarse comparando "cantidad de aperturas = cantidad de cierres". La única verificación posible es que la cantidad total sea PAR.

En estructuras de datos paralelas (`aAperturas[i]` / `aCierres[i]`), detectar self-paired con `aAperturas[i] = aCierres[i]` y aplicar lógica de paridad (`Mod 2 = 0`) en lugar de comparación.

En UI, mostrar una sola columna en lugar de dos, para no confundir al usuario con dos columnas idénticas.

### SC-10 — API de Regexp con gb.pcre (versión anterior de SC-05)

**Estado:** deprecada · **Evidencia:** empirica · **Entorno:** gb.pcre / PCRE2

DEPRECADA. Reemplazada por SC-05, que fija el motor perl externo.

Texto histórico, conservado porque explica código que todavía puede aparecer en módulos viejos:

El patrón se pasaba como string crudo. Firma de iteración:

    Dim oRegex As New Regexp
    oRegex.Compile("patron")
    oRegex.Exec(sTexto)
    While oRegex.Offset >= 0
      ' PROCESAR: oRegex.Text, oRegex.Offset, oRegex.Length
      sTexto = String.Mid(sTexto, oRegex.Offset + oRegex.Length + 1)
      oRegex.Exec(sTexto)
    Wend

NUNCA `Exec(texto, offset)`: la firma toma un solo argumento. Para avanzar la búsqueda había que truncar el texto, y eso es justamente una de las siete limitaciones que motivaron el cambio de motor: truncar rompe `\b` y lookbehind.

La justificación de esta regla incluía además que "Gambas no interpreta secuencias de escape en strings literales", afirmación que resultó falsa (ver SC-01).

`gb.pcre` permanece como componente por si algún día se necesitara validación de sintaxis in-process. Hoy no se usa.

**Relaciones:** reemplazada_por:SC-05

---

## RF — Referencia de API

Qué existe y con qué firma. No manda: informa.

### RF-01 — Advertencia oficial de inestabilidad del TextEditor

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22 / gb.form.editor

La documentación de gambaswiki.org indica explícitamente que el TextEditor es, ante todo, el editor del IDE de Gambas, y que puede cambiar en cualquier momento sin aviso, en particular en lo referido al resaltado (`gb.highlight`).

Implicancia práctica:

- ANCLAR la versión de Gambas en el repositorio: gbpublisher requiere Gambas ≥ 3.21.
- Verificar tras cada actualización del IDE que `m_EditorHighlight`, `m_Themes` y los handlers del evento `Highlight` siguen funcionando, ANTES de hacer release.
- No usar APIs marcadas como "Since 3.X" sin confirmar que ese X coincide con el mínimo soportado.

### RF-02 — Propiedades de posicionamiento del TextEditor

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22 / gb.form.editor

Todas 0-indexadas.

CURSOR

    Line, Column              posición actual del cursor (lectura)
    LastLine, LastColumn      posición previa a un movimiento

SELECCIÓN

    Selected                  Boolean: hay texto seleccionado
    SelectedText              texto efectivamente seleccionado
    SelectionLine,
    SelectionColumn           posición de la marca de selección

ESTRUCTURA

    Count                     número de líneas
    Max                       Count - 1, índice de la última línea
    Current                   línea actual como objeto virtual
    txtEditor[i]              acceso a línea como objeto _TextEditor_Line

### RF-03 — Métodos de posicionamiento del TextEditor

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22 / gb.form.editor

Todos en orden `(Column, Line)`. Ver RC-GM-06: la convención semántica "línea primero" que sugieren las propiedades de lectura NO se aplica a los métodos.

    Goto(Column, Line)                    mueve el cursor sin seleccionar
    GotoCenter(Column, Line)              ídem y centra el viewport
    Select(Col1, Line1, Col2, Line2)      selecciona un rango
    SaveCursor / RestoreCursor            snapshot y restauración de cursor + selección
    HideSelection                         limpia la selección actual
    EnsureVisible(Column, Line)           scroll sin mover el cursor [Since 3.20]

**Relaciones:** vinculo:RC-GM-06

### RF-04 — Highlighting: dos APIs coexisten

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22 / gb.form.editor

API legacy: `Styles`, objeto virtual con sub-propiedades por tipo.
API nueva: `Theme`, que reemplaza a `Styles` y está orientada a temas con nombre.

Verificar SIEMPRE qué versión de Gambas está corriendo antes de decidir cuál usar. El roadmap del proyecto —`m_Themes`, cuatro o cinco temas seleccionables persistidos en `gbpublisher.conf`— va sobre `Theme`, no sobre `Styles`.

MODOS DISPONIBLES (propiedad `Highlight` / `Mode`)

Gambas, HTML, CSS, C, C++, JavaScript, SQL, diff.

Custom: se define vía `gb.highlight` con archivos `.highlight` propios. Este es el camino para el Markdown extendido con shortcodes, fenced divs y atributos específicos del proyecto.

EVENTO CLAVE

`Highlight(Line As Integer)` se dispara cuando una línea debe rehighlightearse. Ahí se aplica la lógica cromática de `m_EditorHighlight` si no se usa un definition file declarativo.

PROPIEDAD DE CAMBIO RECIENTE

`Rewrite` [Since 3.19] permite que el highlighter modifique los caracteres mostrados y no solo el estilo. Útil para ligaduras o display alterado; riesgoso, porque el contenido visual deja de coincidir uno a uno con el texto subyacente.

### RF-05 — Patrón canónico: insertar, seleccionar y restaurar el foco

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22 / gb.form.editor

Combinación de RC-GM-06, RC-GM-07, RC-GM-08 y SC-04. Aplicar en cualquier evento de botón de toolbar que inserte texto.

    ' --- 1. INSERTAR PRIMERA PARTE ---
    Try txtEditor.Insert(sParte1)
    If Error Then m_Sonido.sonar("Error") : Message.Error(...) : Return
    Endif

    ' --- 2. CAPTURAR POSICIÓN INICIAL DE LA SELECCIÓN ---
    iColIni = txtEditor.Column
    iLineaIni = txtEditor.Line

    ' --- 3. INSERTAR PARTE A SELECCIONAR ---
    Try txtEditor.Insert(sParteSeleccionable)
    If Error Then m_Sonido.sonar("Error") : Message.Error(...) : Return
    Endif

    ' --- 4. CAPTURAR POSICIÓN FINAL Y SELECCIONAR ---
    iColFin = txtEditor.Column
    iLineaFin = txtEditor.Line
    Try txtEditor.Select(iColIni, iLineaIni, iColFin, iLineaFin)

    ' --- 5. RESTAURAR FOCO ---
    txtEditor.SetFocus()

**Relaciones:** vinculo:RC-GM-07, vinculo:RC-GM-08, vinculo:SC-04

### RF-06 — Componentes relacionados que deben estar en el proyecto

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22 / gb.form.editor

    gb.form.editor      el TextEditor en sí
    gb.highlight        definition files para sintaxis custom
    gb.eval.highlight   evaluación de expresiones con highlight
    gb.pcre             NO se usa para expresiones regulares

Sobre `gb.pcre`: el motor de expresiones regulares del proyecto es perl externo (SC-05). El componente permanece solo por si algún día se necesitara validación de sintaxis in-process; hoy no tiene uso. Para regex del usuario: `engine/buscar_regex.pl`.

**Relaciones:** vinculo:SC-05

---

## GV — Comportamientos verificados

Evidencia empírica de gambas-verificado.md

### GV-01 — Rutas y directorios

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

`Exist()` devuelve True TAMBIÉN para archivos regulares. No sirve como guard de "esto es una carpeta". Para eso hace falta `IsDir()`, en `If` anidado porque `And` no cortocircuita.

`Dir()` sobre un archivo regular lanza el error 49.

    Exist("/tmp/x/archivo.md")        -> True
    Dir("/tmp/x/archivo.md", "*.md")  -> ERROR #49: Not a directory
    Dir("/tmp/x/no-existe", "*.md")   -> ERROR: File or directory does not exist

Este fue el bug raíz de siete funciones del proyecto: recibían la ruta de un `.md` donde esperaban una carpeta, `Exist()` decía True, y el `Dir()` siguiente mataba la función sin mensaje visible.

`File.RealPath()` devuelve cadena vacía para una ruta inexistente, y la ruta real para una existente. El idiom `If Not File.RealPath(x) Then` funciona como test de existencia.

`"/a/b" &/ ""` devuelve `"/a/b"`. Concatenar con cadena vacía no agrega barra. Consecuencia: una property que devuelve `Ruta &/ Nombre` con `Nombre` vacío devuelve la carpeta y no un archivo, lo que puede hacer que un código roto funcione de casualidad.

`Dir(dir, "*.*")` omite los archivos sin extensión. Es un modismo de Windows. Para todos los archivos: `Dir(dir, "*", gb.File)`.

`File.Name()` devuelve el nombre CON extensión; `File.BaseName()` SIN extensión.

**Relaciones:** apoya:RC-GM-17

### GV-02 — Operadores lógicos: And If y Or If solo existen en If

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

`And If` y `Or If` existen SOLO en `If`. Dentro de un `While` dan error de compilación:

    While a.Count > 0 And If Trim$(a[a.Max]) = ""
                       ^ error: Unexpected And

Esto es un agregado a RC-GM-17: la regla dice separar en `If` anidados, y el reflejo natural es escribir `And If` en cualquier condición. En un `While` hay que abrir el bloque:

    Do
      If a.Count = 0 Then Break
      If Trim$(a[a.Max]) <> "" Then Break
      a.Remove(a.Max)
    Loop

El `While` con `And` común revienta con Out of bounds cuando el array se vacía, porque evalúa `a[a.Max]` con `Max = -1`. Verificado, y encontrado vivo en `ProcesarArchivoFootnote`.

### GV-03 — UTF-8 y cadenas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble y Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Lower()`, `LCase()` y `String.Lower()` no pliegan acentos de forma reproducible. Bajo locale C/POSIX son ASCII-only; bajo `es_AR.UTF-8` sí pliegan. Esa dependencia del entorno es PEOR que un comportamiento uniformemente roto: uno roto se detecta en la primera prueba, uno dependiente del entorno funciona en la máquina del desarrollador y falla en una instalación cliente con locale mínimo. Las máquinas de las universidades no se controlan.

    Lower("SEÑOR ÁRBOL")  = seÑor Árbol     (bajo C/POSIX)
    String.Comp("SEÑOR", "señor", gb.IgnoreCase) = 0 -> False

REGLA: donde la salida deba ser reproducible entre máquinas, NO usar `Upper` / `Lower` nativos. Usar las tablas explícitas de `m_FuncionesGenericas`, locale-independientes por construcción:

- `EsLetra(iCodigo)` — criterio de letra para partir palabras
- `PlegarAMayuscula(iCodigo)` / `PlegarAMinuscula(iCodigo)` — plegado por codepoint

Cobertura: ASCII y Latin-1 Supplement, salteando `×` (215) y `÷` (247), y sin plegar `ß` (223) ni `ÿ` (255), cuyas mayúsculas no siguen la regla de ±32. Alcanza para castellano, portugués, francés e italiano.

`String.IsValid()` responde si una cadena es UTF-8 válido. Es la única forma de detectar un archivo mal codificado.

`File.Load()` no decodifica ni valida. Un archivo en Latin-1 NO produce U+FFFD: produce codepoints basura y ceros que se comen el resto del contenido. Corolario: buscar U+FFFD no sirve como detector de codificación corrupta. Un U+FFFD literal sí es un hallazgo real, pero significa otra cosa: que una conversión anterior ya perdió datos.

`Mid()` con longitud en bytes puede cortar un carácter por la mitad; `String.Mid()` no.

`InStr` y `String.InStr` devuelven posiciones distintas sobre el mismo texto: bytes contra codepoints. Mezclarlas produce desfasajes silenciosos.

El bucle `String.Mid` + `String.Code` por codepoint escala LINEALMENTE, no cuadráticamente: 5.000 codepoints en 0,003 s; 40.000 en 0,021 s. No hace falta optimizarlo.

**PENDIENTE:** String.Comp con gb.IgnoreCase tampoco plegó acentos en el contenedor, pero esa medición arrastra sesgo de locale. Reverificar en Mint antes de confiar en ella.

### GV-04 — Las claves de Collection son case-sensitive

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

`c["Nota"] = "A"` y después `c.Exist("nota")` devuelve False.

Coincide con Pandoc, donde `[^Nota]` y `[^nota]` son dos identificadores distintos.

### GV-05 — Sintaxis de cierre de funciones

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

Un `Sub` con tipo de retorno debe cerrar con `End`, no con `End Sub`.

    Public Sub PruebaSub() As Boolean
      Return True
    End Sub          -> error: END FUNCTION expected

`Public Sub` sin retorno cierra bien con `End Sub`, y `Public Function` con `End Function`.

Las declaraciones `Const` y `Private` a mitad de módulo, después de otras funciones, compilan y funcionan. No hace falta moverlas arriba, aunque conviene por estilo.

**Relaciones:** vinculo:GV-11

### GV-06 — Quote() no escapa para shell

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

`Quote()` es el escapado de Gambas: devuelve el texto entre comillas DOBLES, y dentro de comillas dobles `sh` sigue expandiendo `$(...)` y backticks.

    Quote("http://x.com/$(id)")  =  "http://x.com/$(id)"

Una URL pegada en un TextBox con esa forma ejecutaba el comando. `Shell$()` sí escapa con comillas simples, pero lo correcto según SC-05 es `Exec` con array, que no pasa por `sh -c`.

`Exec` acepta un `String[]` construido en una variable, no solo un array literal. La restricción de "una sola línea" aplica al literal, no a un array armado con `.Add()`.

Para pasar nombres a un script de shell sin interpolarlos, usar `$@`:

    aComando.Add("sh")
    aComando.Add("-c")
    aComando.Add(sScript)   ' EL SCRIPT USA "$@", NO CONCATENA NOMBRES
    aComando.Add("sh")      ' $0; LOS ARGUMENTOS ARRANCAN EN $1

### GV-07 — Consultas a dpkg

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

`dpkg -l NOMBRE` sin comodines es exacto, no matchea prefijos: `dpkg -l gambas3-gb-form` no incluye a `gambas3-gb-form-editor`.

`dpkg-query -W` acepta todos los paquetes en una sola llamada y devuelve la versión:

    30 × sh + dpkg + grep   0,468 s
    1 × dpkg-query          0,014 s

Los no encontrados van a STDERR, no a stdout, y la salida viene ordenada alfabéticamente y no en el orden pedido: hay que parsear a una `Collection`, no a un array paralelo. Solo cuenta como instalado el estado `install ok installed`.

Para recuperar la versión de un ejecutable, `dpkg -S` acepta varias rutas en una llamada. Hay que resolver el symlink antes: `/usr/bin/java` es un enlace de alternatives y `dpkg -S` no lo encuentra, pero `readlink -f` llega a `openjdk-21-jre-headless`. Igual `lualatex`, que resuelve a `luahbtex` y de ahí a `texlive-binaries`.

`java -version` escribe en stderr, no en stdout. Un `Exec ... To` devolvería cadena vacía.

`command -v` es preferible a `which`: es builtin de POSIX sh, mientras que `which` vive en debianutils y puede no estar.

**Relaciones:** vinculo:GV-20

### GV-08 — Empaquetado en Ubuntu y Mint

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-08

El paquete `lua` no existe: `apt-cache policy lua` devuelve `Candidate: (none)`. `lua5.4` instala `/usr/bin/lua5.4`, no `/usr/bin/lua`. Para tener el nombre corto hace falta un `update-alternatives`.

El servidor de base de datos NO debe verificarse en el cliente. gbpublisher es multiusuario contra una base compartida que normalmente vive en otra máquina, así que buscar `mysqld` en el PATH local da fallo en toda instalación cliente. Lo que el cliente necesita es el driver (`gambas3-gb-db2-mysql`); que el servidor responda lo prueba la conexión real.

### GV-09 — Nombres reservados

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Log` es una función interna de Gambas —el logaritmo natural— y no puede usarse como nombre de un `Sub`. La declaración compila sin quejarse; el error aparece en el PUNTO DE LLAMADA como incompatibilidad de tipos, porque el compilador resuelve a la función matemática.

    Private Sub Log(sTexto As String)   ' COMPILA
    ...
    Log("hola")                          ' ERROR DE TIPO: espera un número

Del mismo tenor: `Exp`, `Abs`, `Int`, `Sgn`, `Str`, `Val`, `Left`, `Right`, `Mid`, `Len`, `Space`, `Format`, `Timer`, `Point`, `Line`.

REGLA: para funciones internas de un módulo, nombres de dos palabras o con prefijo del módulo. Viene de VB, donde no hay colisión.

### GV-10 — Conversión de Boolean a texto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`CStr(True)` devuelve `"T"` y `CStr(False)` devuelve CADENA VACÍA. No `"True"` / `"False"`.

Esto es peor que una convención rara: un False se vuelve INDISTINGUIBLE de un campo vacío, de un NULL o de un dato que nunca se calculó. En una grilla o en un informe, "no cumple" se renderiza como nada.

Y engancha con RC-GM-01: MySQL devuelve `TINYINT(1)` como Boolean, así que cualquier campo booleano de la base que pase por `CStr()` para mostrarse tiene este comportamiento.

REGLA: nunca `CStr()` sobre un Boolean para salida. Conversión explícita, `IIf(bValor, "sí", "no")` o un helper.

**Relaciones:** apoya:RC-GM-01

### GV-11 — Ámbito de Const

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Const` no se puede declarar dentro de un `Sub` o `Function`. Es declaración de módulo o de clase; un `Const` local es error de compilación.

Combinado con lo ya verificado —que `Const` y `Private` a mitad de módulo compilan y funcionan— la regla práctica es: la constante va inmediatamente antes de la función que la usa si es de uso interno, o en `m_Constantes` si la comparten varias.

Otra herencia de VB/.NET, donde el `Const` local sí existe.

### GV-12 — Precedencia de Not

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Not` es unario y liga antes que los operadores de comparación de cadenas.

    If Not sNombre Begins "auditoria-" Then    ' SE LEE (Not sNombre) Begins "..."
                                              ' -> ERROR DE TIPO

Es la misma familia que RC-GM-17, con otra causa: allí el problema es que `And`/`Or` no cortocircuitan; acá es la precedencia. La salida es la misma en los dos casos: SEPARAR.

    For Each sNombre In aTodos
      If sNombre Begins "auditoria-" Then Continue
      aFiltrados.Add(sNombre)
    Next

REGLA: no encadenar un operador lógico con otro operador en la misma expresión.

### GV-13 — Array.Insert no inserta un elemento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Insert()` empalma OTRO ARRAY dentro del array. Para insertar un elemento en una posición se usa `Add(Valor, Índice)`.

    aOrdenados.Insert(oHallazgo, j)   ' ERROR DE TIPO: espera un array
    aOrdenados.Add(oHallazgo, j)      ' CORRECTO

### GV-14 — Arrays de clases propias: guardan referencias

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Dim a As New CMiClase[]` compila y funciona, y el array guarda REFERENCIAS, no copias.

    aHallazgos[0].iOcurrencias = 999
    For Each o In aHallazgos : Print o.iOcurrencias   ' 999 -> son referencias

Consecuencia práctica: una vista filtrada puede ser un segundo array con punteros a los mismos objetos. Filtrar es barato y no duplica datos.

`Remove(i)` reindexa, así que nunca borrar dentro de un `For` ascendente sobre el mismo array.

### GV-15 — El GridView es virtual y no cachea

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

El evento `Data` solo se dispara para las celdas visibles. Medido con 5.000 filas × 3 columnas: 15.000 celdas declaradas, 72 disparos de `Data` en el primer pintado.

Pero NO cachea. Vuelve a pedir cada celda en cada repintado, para siempre: los incrementos observados fueron +18, +18, +18, +39, +21 con cada click.

Consecuencia dura: el handler `Data` es ruta caliente. No puede tener concatenación, formateo, búsqueda en `Collection` ni resolución contra un catálogo en disco. Solo indexar un array ya formateado.

La celda se escribe con `gvNombre.Data.Text` dentro del evento. Y `ColumnClick(Column As Integer)` existe y devuelve el índice de la columna, así que el ordenamiento por encabezado se cuelga de ahí.

### GV-16 — Dialog.SelectDirectory() devuelve True al CANCELAR

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Convención de Gambas, al revés de lo que sugiere el instinto. `Dialog.Path` conserva la ruta elegida, y preasignarlo antes fija la carpeta inicial.

    Dialog.Title = "Seleccionar carpeta"
    Dialog.Path = $sUltimaCarpeta
    If Dialog.SelectDirectory() Then Return   ' TRUE = EL USUARIO CANCELÓ

### GV-17 — Process.Wait() y los eventos son incompatibles

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Mientras se ejecuta un procedimiento, el intérprete NO entra al bucle de eventos.

Por lo tanto `hProceso.Wait()` bloquea el procedimiento y los eventos `Read` y `Error` no se disparan nunca. Nadie drena las tuberías del proceso hijo, y si el hijo escribe lo suficiente para llenar el búfer del sistema queda bloqueado escribiendo. Espera mutua: la aplicación espera al proceso y el proceso espera a que alguien lea. La aplicación se cuelga sin ningún mensaje.

La forma correcta usa la SENTENCIA `Wait`, que es el mecanismo documentado para forzar la entrada al bucle de eventos, con una señal levantada por el evento `Kill`:

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

El vencimiento de plazo no es opcional cuando la entrada viene de terceros: una herramienta puede colgarse con un archivo patológico.

Y como la sentencia `Wait` deja correr los eventos de la interfaz, durante la espera los botones son pulsables: hace falta una bandera de reentrada.

**Relaciones:** vinculo:GV-18, vinculo:GV-20

### GV-18 — Las firmas de los handlers de eventos no son uniformes

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Y se validan al LANZAR, no al compilar.

    Read   sin parámetros; se lee con Line Input #Last o Read #Last, sVar, Lof(Last)
    Error  CON parámetro: Error(sDatos As String)
    Kill   sin parámetros; el código de salida en Last.Value

Una firma equivocada compila perfectamente y hace fallar el `Exec` en tiempo de ejecución:

    ERROR AL LANZAR: Bad event handler in Modulo.ProcX_Error(): Not enough arguments

Esto obliga a `Try` + `If Error` sobre el propio `Exec` (RC-GM-02), y a que ese error se informe a algún lado: en nuestro caso el mensaje existía pero se escribía en el canal de stderr, que el llamador descartaba cuando el código de salida no era cero. El síntoma visible fue "todos los archivos aparecen como no válidos", a metros de la causa.

**Relaciones:** apoya:RC-GM-02

### GV-19 — stderr llega fragmentado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Los datos del evento `Error` llegan en trozos de 256 bytes que parten líneas al medio, e incluso pueden partir un carácter multibyte:

    [STDERR] largo=256 -> ...Premature end of data in tag a line 1\n<a><b>sin cerrar</a>\n
    [STDERR] largo=18  -> ^\n

REGLA: el handler SOLO ACUMULA. Nunca parsear ahí. Concatenar primero y recién después usar `String.*`; validar o cortar trozo por trozo rompería la codificación.

Lo mismo vale para stdout cuando la salida es larga.

**Relaciones:** vinculo:RC-GM-12

### GV-20 — Exec ... To para stdout, eventos para stderr

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Exec ... To` NO captura stderr. Verificado: con un XML mal formado, `xmllint` reportó el error y la variable quedó con largo 0.

Pero sí captura stdout, y eso alcanza y sobra cuando la herramienta entrega su resultado por la salida estándar:

    ' RESULTADO POR STDOUT: FORMA SÍNCRONA, CINCO LÍNEAS
    Try Exec ["xmllint", "--nonet", "--xpath", sExpresion, sRuta] To sSalida

    ' DIAGNÓSTICOS POR STDERR: HACE FALTA EL MECANISMO DE EVENTOS

REGLA: el aparato asíncrono, con su bucle de espera, su drenaje y su vencimiento de plazo, se reserva para cuando hay que leer la salida de ERROR. Para todo lo demás, la forma síncrona.

### GV-21 — Saxon-HE no expone ninguna función de extensión saxon:

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

No es que falte `saxon:line-number()`: es el namespace entero.

    XPST0017  Cannot find a 1-argument function named Q{http://saxon.sf.net/}line-number().
    Saxon extension functions are not available under Saxon-HE

Verificado con `-l:on` y sin él.

Vale para todos los XSLT del proyecto, no solo para el auditor: cualquier `saxon:evaluate()`, `saxon:serialize()` o `saxon:parse()` de un ejemplo de internet está fuera de alcance.

### GV-22 — xmllint --xpath no conoce los namespaces del documento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Aunque el documento declare `xmlns:xlink`, la expresión falla:

    xmllint --xpath '//graphic/@xlink:href' archivo.xml
      -> XPath error : Undefined namespace prefix

La forma agnóstica funciona y además sirve para los archivos que declaran el mismo namespace con otro prefijo:

    xmllint --xpath "//graphic/@*[local-name()='href']" archivo.xml

Consecuencia para el auditor: los XPath que se muestran como ubicación de un hallazgo deben escribirse así y no con el prefijo. Si no, el proveedor de la revista los pega en su editor y no funcionan.

### GV-23 — El Try con Return silencioso es un canal mudo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

No es un comportamiento de Gambas sino una consecuencia de varios de ellos, y merece quedar escrito:

Un `Try` seguido de un `Return` silencioso es un canal mudo. Si el `If Error` no informa a algún lado —ni siquiera con un `Print` durante el desarrollo— el fallo se manifiesta lejos de su causa, como un resultado vacío que parece un dato legítimo.

Los tres casos de la sesión que lo produjeron: el `Exec` que fallaba por una firma de handler y devolvía su mensaje por un canal que el llamador descartaba; el `Line Input` que perdía la salida sin salto de línea final y devolvía cadena vacía; y los `Return Null` de `AnalizarArchivo`, que hacían desaparecer archivos de la grilla sin explicación.

RC-GM-02 no pide solo verificar el error: pide HACER ALGO con él.

### GV-24 — ByRef no existe en la práctica: los primitivos van siempre por valor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

Verificado en seis variantes:

    Sub con ByRef Integer                       no propaga
    Function con ByRef Integer                  no propaga
    Function con ByRef String                   no propaga
    parámetro sin la palabra ByRef              no propaga
    función pública llamada desde otro módulo   no propaga
    array como parámetro                        SÍ PROPAGA

    Private Sub PonerEnDiez(ByRef iSalida As Integer)
      iSalida = 10
    End

    iValor = 0
    PonerEnDiez(iValor)
    Print iValor        ' -> 0, NO 10

En Gambas los tipos primitivos se pasan SIEMPRE por valor, con `ByRef` o sin él. Los objetos —arrays y clases— se pasan SIEMPRE por referencia. No hay forma de devolver un `Integer` o un `String` por parámetro.

Es herencia de VB, donde `ByRef` no solo existe sino que es el modo POR DEFECTO. Por eso el error es tan fácil de cometer y tan difícil de ver: compila, no da ningún aviso, y la variable del llamador simplemente queda como estaba.

En este proyecto había seis funciones así, y las seis estaban rotas en silencio: una convertía posiciones a línea y columna para el corrector ortográfico, dos extraían el nombre de un shortcode, una leía configuración de un XSLT, y dos devolvían la salida de procesos externos.

Y produjo un síntoma que costó tres intentos diagnosticar: una función auxiliar que devolvía la posición de avance por `ByRef` dejaba el índice en cero, `InStr` volvía a encontrar la primera coincidencia y el bucle no terminaba nunca, con la interfaz congelada y sin ningún mensaje.

REGLA: nunca usar un parámetro como canal de salida para un primitivo. Alternativas por orden de preferencia:

1. Invertir el retorno. Si la función devuelve Boolean más un dato, que devuelva el dato y que el vacío signifique falso.
2. Una clase pequeña, cuando los datos tienen sentido juntos: una posición es línea y columna, no dos enteros sueltos.
3. Un array como canal, que sí funciona por ser objeto.
4. Variable de módulo con accesor, cuando el dato es un subproducto y no el resultado.

**Relaciones:** vinculo:GV-23, vinculo:GV-14

### GV-25 — Saxon 12 resuelve la DTD por red y no se lo puede impedir

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Un XML de 70 KB con DOCTYPE de JATS tarda OCHO SEGUNDOS en parsear con Saxon. El desglose ubica la causa sin ambigüedad:

    arranque de la JVM sin hacer nada            0,24 s
    ese XML con una plantilla que no hace nada  12,87 s
    una regla real sobre un XML mínimo           0,57 s
    el mismo comando sin red (unshare -rn)       0,42 s, y falla

No es la JVM ni son las reglas: es PARSEAR ESE XML. `strace` confirma dos conexiones salientes. Saxon va a buscar la DTD a `jats.nlm.nih.gov` en cada archivo.

Ninguna opción lo evita. Se probaron `-Djavax.xml.accessExternalDTD`, `-Djavax.xml.accessExternalSchema`, `-dtd:off`, `-Dxml.catalog.ignoreMissing` y `-Dxmlresolver.properties`: el tiempo no cambió en ningún caso. El resolvedor de Saxon 12 ignora las propiedades estándar de JAXP.

SOLUCIÓN: cuando la DTD no hace falta para la transformación, entregarle a Saxon una copia SIN DOCTYPE. Verificado: 0,43 s en lugar de 8,1 s, con resultados idénticos.

Al recortar el DOCTYPE hay que CONTAR CORCHETES: el de JATS trae declaraciones de entidades entre `[` y `]`, que contienen sus propios `>`. Cortar en el primero rompe el documento; un `sed` ingenuo dejó el prefijo `ali` sin enlazar.

Esto es la contracara de RC-XJ-03, y las dos reglas deben leerse juntas: allí el problema era que Saxon no conseguía la DTD y la solución fue permitirle buscarla; acá la busca cuando no hace falta.

Vale para todo el proyecto: cualquier cadena XSLT que reciba un JATS con DOCTYPE remoto está pagando esos ocho segundos por archivo.

### GV-26 — Los Schematron de JATS4R no se ejecutan tal como se distribuyen

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SchXslt 1.10.1 / SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Cuatro problemas distintos, todos verificados:

El `.xsl` publicado en el repositorio está MAL COMPILADO. Un `<xsl:function>` quedó sin `@name`, con lo que tres de las cuatro funciones `j4r:` no se declaran y Saxon aborta con `XPST0017`.

`compile-for-svrl.xsl` de SchXslt 1.10.1 copia SOLO LA PRIMERA `<xsl:function>` del `<schema>` y descarta las demás. De las cuatro de `jats4r.sch` sobrevive una.

Los archivos temáticos NO son documentos Schematron completos. Empiezan en `<pattern>` y están pensados para entrar por `<include>`. Sueltos dan "this document contains more than one top-level element". Necesitan un envoltorio con las declaraciones de namespace del maestro.

Y hay reglas que abortan con estructuras normales. Una regla sobre `<sec>` llama a `normalize-space()` sobre un conjunto de títulos y falla con `XPTY0004` en cuanto un artículo tiene subsecciones. En el corpus de referencia, doce secciones de un solo artículo tenían más de un título. Como Saxon aborta, se pierde el análisis del ARCHIVO ENTERO, no solo esa regla.

COMBINACIÓN QUE FUNCIONA: `include.xsl` de SchXslt para resolver los includes, esqueleto ISO `iso_svrl_for_xslt2.xsl` para compilar. Cada implementación aporta lo que la otra rompe.

REGLA: compilar y ejecutar temático por temático, nunca el maestro completo, y verificar cada grupo contra un corpus real antes de darlo por bueno. Que una regla compile no garantiza que ejecute.

**Relaciones:** vinculo:GV-28

### GV-27 — El SVRL no trae identificador por aserción

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SchXslt 1.10.1 / SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Un `<svrl:failed-assert>` trae `@test`, `@role` y `@location`, pero NO `@id`. La clave estable para identificar una regla es el par PATRÓN + TEST:

    <svrl:active-pattern id="general-citations-errors"/>
    <svrl:fired-rule context="element-citation|mixed-citation"/>
    <svrl:failed-assert test="@publication-type" role="error"
                        location="/article[1]/back[1]/ref-list[1]/ref[3]/mixed-citation[1]"/>

El `@location` viene RESUELTO, con predicados numéricos y sin prefijos de namespace, así que se puede pegar en cualquier editor XML y funciona.

Dos detalles del parseo:

- La severidad se lee del `@role` de la aserción y NO de la fase ejecutada: la fase `errors` de JATS4R activa un patrón de advertencias, así que fiarse de la fase da severidades equivocadas.
- Los `<successful-report>` TAMBIÉN llevan `<svrl:text>`. Un parseo que emita un mensaje cada vez que ve esa etiqueta cuenta reportes informativos como errores.

**Relaciones:** vinculo:GV-22

### GV-28 — pipeline-for-svrl.xsl de SchXslt compila pero no ejecuta

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SchXslt 1.10.1 / SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Invocado con `document=archivo.xml`, produce el XSLT COMPILADO, no el informe SVRL. La raíz de la salida es `<xsl:transform>` y los atributos aparecen como plantillas sin evaluar: `location="{schxslt:location(.)}"`.

Consecuencia práctica: durante un tiempo se contaron los `<failed-assert>` de ese archivo creyendo que eran incumplimientos. Eran LAS REGLAS, así que el resultado era idéntico para cualquier XML de entrada.

REGLA: verificar siempre que la salida contenga `schematron-output` antes de parsearla. Es una comprobación de dos líneas que habría ahorrado el diagnóstico entero.

El pipeline correcto es de tres pasos: `include.xsl` → esqueleto ISO para compilar → ejecutar el `.xsl` resultante sobre el documento. Y los dos primeros se hacen UNA SOLA VEZ, en la compilación del paquete.

**Relaciones:** apoya:GV-23
