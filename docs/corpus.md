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

Si se agregaron o reemplazaron archivos desde fuera del IDE (por ejemplo, desde el gestor de archivos), primero hay que RECARGAR el proyecto: el IDE no los ve hasta entonces, y Limpiar + Compilar no alcanza. El orden completo es Recargar, Limpiar, Compilar.

### RC-GM-06 — Firmas de Goto y Select en TextEditor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.editor

TextEditor usa el orden `(Column, Line)` en TODOS los métodos de posicionamiento, igual que `Goto`. NO seguir la convención semántica "línea primero, columna después" que sugieren las propiedades de lectura (`Line`, `Column`, `SelectionLine`, `SelectionColumn`).

Firmas confirmadas:

    Goto(Column As Integer, Line As Integer)
    Select(Column1 As Integer, Line1 As Integer, Column2 As Integer, Line2 As Integer)

Síntoma de inversión en archivos largos: la selección abarca múltiples líneas en lugar del rango intra-línea esperado.

Síntoma en archivos cortos: la selección queda vacía por clamp a `Max`, lo que enmascara el bug. Probar SIEMPRE en archivos largos.

**Relaciones:** vinculo:RC-GM-21

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

**Relaciones:** apoya:GV-03, vinculo:SC-02, vinculo:GV-41

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

### RC-GM-21 — Firmas de posicionamiento de TextEdit: no son las de TextEditor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

`TextEdit` (gb.qt5.ext) y `TextEditor` (gb.form.editor) son controles distintos y sus firmas de posicionamiento NO coinciden. Confundirlas es fácil porque los dos editan texto y los nombres de método se parecen.

En `TextEdit`:

    Pos                      posicion absoluta del cursor
    Select(Posicion, Largo)  DOS argumentos, no cuatro

`Pos` y `Select` cuentan CARACTERES del texto plano, y se corresponden uno a uno con `String.Mid` sobre `.Text`. Verificado: una linea de cinco letras acentuadas avanza la columna de 1 a 6, no a 11.

Corolario operativo: las posiciones que se calculen para alimentar a `Select` deben salir de `String.Len` y `String.InStr`, nunca de `Len` e `InStr`, que operan en bytes y desfasan con el primer acento (RC-GM-12, SC-02).

La firma de cuatro coordenadas `(Column1, Line1, Column2, Line2)` de RC-GM-06 es del `TextEditor` y NO aplica acá.

RESUELTO EL PENDIENTE ANTERIOR: `ToPos` cuenta desde el bloque del cursor y suma un carácter de más por párrafo (GV-45). Sigue sin usarse.

Y ESCRIBIR `Pos` falla en silencio cuando el documento creció (GV-44): el cursor se mueve con `Select(Posicion, 0)`. Leer `Pos` sí es confiable.

**Relaciones:** vinculo:RC-GM-06, vinculo:RF-03, vinculo:SC-02, vinculo:GV-44, vinculo:GV-45

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

## RC-BL — Reglas críticas biblatex

Modelo de relaciones entre entradas y su comportamiento según el estilo

### RC-BL-01 — related_type gana sobre related_string y no hay aviso

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex / biber / estilo verona · **Verificado:** 2026-09

Una entrada con `related` cargado admite dos formas de describir la relación: el código de `related_type`, que biblatex traduce con su cadena localizada, y `related_string`, con redacción propia.

Si los dos campos están presentes, se imprime el de `related_type` y `related_string` NO SALE EN NINGUNA PARTE. Biber no avisa: el dato queda escrito en la base y nunca llega a la salida.

`related_string` solo, con `related_type` vacío, SÍ funciona: se imprime la redacción propia. Es el modo de trabajo habitual del proyecto.

Verificado con `translatedas`, tipo predefinido de biblatex, bajo estilo verona.

CONSECUENCIA PARA gbpublisher: los dos campos son mutuamente excluyentes en la interfaz. FRelacionarBib bloquea uno cuando el otro tiene contenido, exige que haya exactamente uno, y escribe NULL en el que no se usa para que la base distinga "no aplica" de "se escribió algo vacío".

Es la versión biblatex de GV-23: un dato que se guarda bien y se pierde en silencio lejos de donde se cargó.

**Relaciones:** vinculo:RC-BL-02,apoya:GV-23

### RC-BL-02 — El modelo de relaciones depende del estilo de bibliografía

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex / biber · **Verificado:** 2026-09

No todos los estilos de biblatex implementan `related`. verona y el estilo por defecto lo imprimen; apa e ieee lo IGNORAN: la construcción no produce error ni aviso en el log, simplemente no aparece en la bibliografía.

Dos consecuencias que no son del mismo orden:

La relación sigue siendo un dato correcto aunque el estilo del momento no la imprima. Bloquear la carga según el estilo activo sería subordinar el modelo a una decisión de presentación, que además es reversible.

El estilo puede cambiar DESPUÉS de que la relación fue construida. En gbpublisher el estilo se elige por revista, en `estilo_cita`, así que una relación que hoy se imprime puede dejar de imprimirse mañana sin que nadie toque el registro.

DECISIÓN: el formulario de relaciones no consulta el estilo y no advierte nada. Es conocimiento del editor. Si alguna vez hace falta la advertencia, el lugar es la generación de la salida —donde el estilo se conoce y donde se ve también el cambio posterior— y no el momento de la carga.

ALCANCE: en revistas el modelo de relaciones no se usa. Es de libros.

**Relaciones:** vinculo:RC-BL-01

**PENDIENTE:** Solo están medidos verona, el estilo por defecto, apa e ieee. Falta relevar el resto de los estilos en uso antes de afirmar nada general.

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

**Relaciones:** vinculo:GV-53

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

### SC-11 — Modelo de recursos: sistema inmutable, copia local de trabajo

**Estado:** vigente · **Evidencia:** inferida

Los recursos que la aplicación distribuye viven en dos lugares con roles distintos.

`/usr/share/gbpublisher/` es la fuente de verdad INMUTABLE. Se sobrescribe por completo en cada actualización del paquete. Nadie la edita: ni el usuario ni el departamento de sistemas.

`~/.gbpublisher/` es la copia efectiva de trabajo. Es la que la aplicación LEE, y la única que se ajusta. NO se sobrescribe nunca. Si una actualización cambia alguno de esos archivos, se avisa para que se borren y el arranque los vuelve a escribir desde el sistema.

La copia la realiza `m_InicioCierre.DirectorioOcultoApp()` recorriendo una lista de carpetas. Agregar una carpeta de recursos nueva OBLIGA a agregarla a esa lista; si no, la aplicación leerá del sistema y el recurso quedará fuera del modelo sin que nada lo advierta.

QUÉ NO SE COPIA

Lo que, modificado, invalidaría algo que la aplicación afirma. Hoy: `engine/`, el motor de expresiones regulares, y las reglas compiladas de Schematron. Un informe que dice "no cumple una recomendación de JATS4R" solo se sostiene si las reglas son las que vinieron en el paquete.

CONTRAPARTIDA OBLIGATORIA

Todo recurso que sí se copia y que afecte lo que la aplicación afirma sobre un archivo ajeno debe poder DECLARAR si fue modificado. La comparación es directa contra `/usr/share/`, que por definición del modelo conserva siempre el original: no hace falta guardar ni versionar sumas de verificación. Es lo que hace `m_AuditarJats.EstadoRecurso()` con el catálogo de mensajes y la hoja de estilo del informe de auditoría.

RAZÓN DEL MODELO

Divide según haya o no departamento de sistemas. Donde lo hay, los cambios se hacen sobre la copia local y se distribuyen a las estaciones; donde no lo hay, el usuario es a la vez administrador y necesita poder ajustar sin privilegios de root. En los dos casos el punto de intervención es el mismo, y la actualización del paquete nunca pisa lo ajustado.

**Relaciones:** vinculo:SC-05

**PENDIENTE:** Los XSLT de salida se copian a local y hoy no declaran si fueron modificados. Bajo el criterio de la contrapartida deberían hacerlo, sobre todo si el auditor llega a auditar la producción propia. Pendiente de decisión.

### SC-12 — Editor de bibliografia: el formato de trabajo es HTML, no RTF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5.ext / LibreOffice 24.2 · **Verificado:** 2026-09

DECISION CERRADA. El panel de bibliografia de FMain trabaja sobre archivos `.html` y no sobre `.rtf`, aunque el original llegue en RTF.

FLUJO

    .docx de la bibliografia
      -> LibreOffice, a mano, fuera de la aplicacion
    .rtf en /originales
      -> importacion de la aplicacion, una sola vez por libro
    .html de trabajo, que la aplicacion posee de ahi en mas

El combo lista `.rtf` y `.html`. Un `.rtf` que ya tiene su `.html` hermano no se lista: cada bibliografia aparece una sola vez. No se listan `.docx`: /originales guarda todos los originales del libro y el combo se llenaria de ruido.

POR QUE HTML

1. Es el formato nativo del control: la propiedad `RichText` del `TextEdit` es un subconjunto de HTML y no el formato RTF. Cargar y guardar son una linea cada uno.
2. Serializar a RTF exigiria recorrer el documento leyendo `Format` en cada posicion, porque no hay forma de detectar uniformidad de formato (GV-35). Medido: 2,8 s por cada 100.000 caracteres, en CADA guardado.
3. El archivo no se comparte con nadie, asi que nadie del otro lado espera RTF.

QUE LLEVA EL ARCHIVO

Estructura de parrafos, negrita, italica y dos semaforos de cotejo: fondo amarillo para la entrada ya volcada en la base, letras rojas para la entrada ausente del .md. No lleva familia ni cuerpo tipografico: la tipografia es ajuste de pantalla y se quita al guardar (GV-37).

Los semaforos son el registro de avance de varios dias de trabajo, no decoracion. De ahi el guardado atomico con respaldo y el contador de marcas por parrafo.

**Relaciones:** vinculo:GV-40, vinculo:GV-35, vinculo:GV-37, vinculo:RC-GM-21

**PENDIENTE:** Falta la bandera de reentrada durante la importacion: la sentencia Wait deja correr los eventos y los botones siguen siendo pulsables (GV-17).

### SC-13 — Trabajo pesado con herramientas externas: script propio y terminal embebido

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.terminal / bash / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. Cuando una tarea depende de una herramienta externa que ya sabe hacer el trabajo, la lógica va en un script propio en `engine/`, invocado desde un `TerminalView`, y no se reimplementa en Gambas.

El caso que fijó la regla: un importador de scripts SQL para gbCorpus. La versión en Gambas obligaba a inventar un formato de archivo —separador de bloques, cabecera obligatoria, detección de bloques vacíos— solo para no escribir un parser de SQL. `sqlite3` es un parser de SQL. Delegarle el trabajo no simplificó el código: eliminó el problema.

CRITERIO DE DECISIÓN

Lo determina LA FORMA DE LO QUE VUELVE, no la duración ni la cantidad de pasos.

1. Si Gambas necesita de vuelta UNA DECISIÓN —si funcionó o no—: script más terminal embebido. El contrato es el código de salida y Gambas no parsea nada.

2. Si Gambas necesita de vuelta DATOS ESTRUCTURADOS: el script sigue conviniendo, pero el parseo hay que pagarlo igual y el patrón es el de SC-05 —el proceso externo encuentra y calcula, Gambas escribe— con un canal legible por máquina.

3. Si alcanza con una salida corta por stdout: `Exec ... To` en cinco líneas (GV-20). No hay script que valga.

QUÉ SE GANA

El aparato asíncrono de GV-17, GV-18 y GV-19 —bucle de espera, drenaje, vencimiento, firmas de handler, los trozos de 256 bytes— no se usa: el script escribe a un pty que el control pinta solo.

El informe lo compone el script, que es quien tiene los datos, y se lee en la pestaña.

Y la herramienta queda utilizable a mano. Eso no es comodidad: cuando la parte de Gambas se trabó, el script seguía funcionando desde una terminal y por eso se lo pudo diagnosticar.

INTÉRPRETES ADMITIDOS

`bash` y `perl-base`, que son Essential en Debian y Ubuntu. `python3` solo declarándolo como dependencia. `lua` NO: el paquete no existe con ese nombre y `lua5.4` no instala `/usr/bin/lua` (GV-08).

LO QUE NO SE VA DEL PROBLEMA

Mover la lógica fuera de Gambas no exime de RC-GM-02 ni de GV-23. En bash, un `&&` cuyo lado izquierdo es falso devuelve 1, y bajo `set -o pipefail`, si es el último comando de un grupo, contamina el estado de la tubería entera. En la sesión que originó esta regla, esa línea hizo que el informe declarara un rollback que no había ocurrido: la importación se había aplicado.

De ahí la regla operativa: UN INFORME NO AFIRMA LO QUE NO VERIFICÓ. Si va a decir que la base quedó como estaba, que lo consulte antes de decirlo.

BASE COMPARTIDA

Si el proceso externo escribe en la misma base que la aplicación tiene abierta, la conexión se cierra antes de lanzarlo y se reabre después por un ÚNICO camino explícito, invocado tanto en el éxito como en el fallo. `Finally` no sirve para esto (RC-GM-20).

**Relaciones:** vinculo:SC-05, vinculo:SC-11, vinculo:GV-17, vinculo:GV-20, apoya:GV-23, vinculo:GV-42

### SC-14 — Bibliografía en HTML y EPUB: se replica el estilo biblatex del libro

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** biblatex / biber · **Verificado:** 2026-09

DECISIÓN CERRADA. La bibliografía correcta es la que genera biblatex con el estilo que usa el libro. HTML y EPUB no diseñan un modelo propio: replican el modelo y la lógica de ESE estilo.

No se discrimina por tipo de salida. El PDF lo produce biblatex directamente y es la referencia; HTML y EPUB se verifican contra él.

CADA ESTILO TIENE SU PROPIO MODELO

APA, IEEE, Vancouver o ISO 690 no comparten lógica. Lo que se implemente para un estilo no se generaliza a otro sin verificarlo en el fuente del segundo.

CONSULTA OBLIGATORIA

Ante cualquier duda sobre cómo se forma una referencia o una cita —orden de elementos, puntuación, tratamiento de un campo, un tipo de entrada, una relación—, se consulta el FUENTE del estilo antes de proponer código. No se responde de memoria ni por la salida observada: una salida describe un caso, no el mecanismo.

Cada estilo en uso tiene su entrada RF con el repositorio, los archivos a consultar, la versión anclada y el banco de pruebas. Un estilo sin RF no se implementa: primero se releva.

VERSIÓN

Los estilos cambian. Toda afirmación derivada del fuente se ancla a la versión consultada. Si el repositorio avanzó, se vuelve a consultar antes de citar.

ALCANCE

Libros.

**Relaciones:** vinculo:RF-09, vinculo:RC-BL-01, vinculo:RC-BL-02, vinculo:SC-12

### SC-15 — Resaltado de sintaxis en controles TextEdit: HTML desde Run, temas como datos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / gb.highlight / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. Aplicada en el visor XML (`txtEditorXML`, solo lectura).

MECANISMO

El color no se aplica con `Format` (GV-46). `CVisorResaltado` corre `TextHighlighter.Run` una vez por párrafo (RF-10), guarda el resultado en un `Byte[][]` y arma un HTML: un `<p>` por párrafo con `white-space:pre-wrap` y un `<span>` con estilo por tramo. El párrafo vacío lleva el mismo estilo que los demás, con su color (GV-54). Lo asigna con `RichText`. Cambiar de tema rearma el HTML desde la caché sin volver a correr `Run`, salvo que el texto del control ya no coincida con la caché: en un control editable (SC-18) se analiza de nuevo antes de pintar. Sin esa comprobación, un cambio de tema devolvía el editor al texto del último análisis y se perdía lo escrito; verificado en banco.

La ida y vuelta es exacta: un capítulo de 392.713 caracteres volvió idéntico por `.Text`, con la salvedad de GV-47.

REPARTO

- `m_ResaltadoSintaxis`: registro de las gramáticas (con prefijo, GV-48), temas, tema elegido, tipografía, menú de temas y lista de visores.
- `CVisorResaltado`: un objeto por control, con su gramática y su caché.

TEMAS

Nueve archivos `.theme` en `themes/`, junto a los `.highlight`. Entre ellos, `gbpflexoki`: derivado de Flexoki para el trabajo editorial (fondo `#FAFAF9`, itálica en púrpura, referencias y marcas de nota en negrita); `flexoki` conserva la paleta original. Se copian a `~/.gbpublisher/themes` (SC-11) y se leen desde ahí.

Formato `Settings`: una sección `[Tema]` (Nombre, Orden, Fondo, Texto) y una sección por gramática (`[XML]`, `[Markdown]`), porque la misma clave significa cosas distintas en cada una: `Comment` es comentario en XML e itálica en Markdown. Cada valor es `"#RRGGBB"`, con `;bold` y `;italic` opcionales.

Un tema se identifica por el nombre de su archivo, no por el texto del menú. Por defecto: `gruvbox`.

PREFERENCIAS

En `gbpublisher.conf` (SC-17): `[Resaltado] Tema`, y la tipografía en `[Editor] FontName / FontSize`. La tipografía se reaplica después de cada carga (GV-37).

CURSOR

Después de cargar un archivo, `Select(0, 0)` y `ScrollY = 0`: asignar `RichText` deja el cursor al final (GV-37). Nunca se escribe `Pos` (GV-44).

COSTOS MEDIDOS (JATS de 392.465 caracteres)

Abrir y colorear: 1,3 s, con `Application.Busy`. Cambiar de tema: 0,35 s.

El editor principal adopta este mismo modelo, con refresco en puntos fijos (SC-18).

**Relaciones:** vinculo:SC-11, vinculo:GV-46, vinculo:GV-48, vinculo:RF-10, vinculo:SC-17, vinculo:GV-44, vinculo:SC-18, vinculo:GV-54

### SC-16 — El .md es autosuficiente

**Estado:** vigente · **Evidencia:** inferida · **Verificado:** 2026-09

Todo lo que la aplicación necesita para editar un .md se deriva del archivo al abrirlo, y nada de eso se persiste fuera de él.

Razón: el .md viaja solo. Se lo puede llevar a otra máquina, corregir con cualquier editor de texto y reponer, sin que la aplicación note ni pierda nada.

CONSECUENCIAS

- Las cachés de trabajo (estados del resaltador, análisis, índices) viven en memoria y se recalculan al abrir. No se guardan junto al .md ni en la base.
- Guardar desde la aplicación no altera ningún carácter que el usuario no editó (ver GV-47).

CONTRASTE DELIBERADO

El HTML de trabajo del editor de bibliografías (SC-12) es un artefacto de la aplicación, no una fuente. Por eso sí lleva datos de trabajo: los semáforos de cotejo.

**Relaciones:** vinculo:SC-12, vinculo:GV-47, vinculo:SC-02

### SC-17 — gbpublisher.conf es el único archivo de configuración

**Estado:** vigente · **Evidencia:** inferida · **Verificado:** 2026-09

Toda preferencia de la aplicación se guarda en `~/.gbpublisher/gbpublisher.conf`, abierto con `New Settings(ruta)` y con `Save()` explícito.

No se usa el objeto global `Settings`: escribe en otro archivo.

Secciones en uso: `[Editor]` (FontName, FontSize), `[EditorHTML]` (FontName, FontSize), `[Interface]` (FontSize) y `[Resaltado]` (Tema).

La ruta se obtiene siempre de `m_InicioCierre.RutaConfiguracion()`; no se escribe literal.

**Relaciones:** vinculo:SC-11, vinculo:SC-15

**PENDIENTE:** m_Traduccion guarda con el Settings global las claves de DeepL y Azure, la región y el motor predeterminado. Son credenciales: antes de migrarlas, decidir si van en gbpublisher.conf o en un archivo propio fuera de lo que se distribuye a las estaciones (SC-11).

### SC-18 — Editor principal de Markdown: TextEdit con refresco determinista

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. El editor principal de Markdown (`txtEditorProyecto`) pasa de `gb.form.editor` a `TextEdit` (gb.qt5.ext), con el resaltado de SC-15.

POR QUÉ

Con párrafos largos, `gb.form.editor` es duro de usar: el click al comienzo de una fila visual va al comienzo del párrafo (GV-49), y el scroll es brusco. Sin resaltado el scroll sigue igual de brusco, así que la causa está en el manejo del wrap y no tiene un arreglo acotado. `TextEdit` resuelve las dos cosas con el comportamiento nativo de Qt. Además la negrita y la itálica son reales: el texto se lee como prosa de libro o revista, no como código.

REFRESCO DETERMINISTA

El color se recalcula reasignando el HTML, y eso vacía el historial de deshacer (GV-46). Por eso el refresco ocurre solo en tres momentos, siempre los mismos:

- al abrir un archivo;
- al cambiar de archivo en el combobox;
- en cada guardado, y solo si la escritura se completó: si falla, el historial es lo único que queda del trabajo.

No hay refresco manual. Es una norma de trabajo: el guardado es el punto de control, y Ctrl+Z no cruza un guardado. Entre refrescos, lo que se escribe hereda el color del carácter vecino; el marcado nuevo se colorea al guardar.

Costo medido del refresco: alrededor de 0,1 s en 190.000 caracteres, reanalizando solo desde el primer párrafo cambiado hasta que el estado del resaltador coincide con el guardado. No se nota a la vista.

LO QUE REEMPLAZA A LO QUE NO TIENE TextEdit

- Plegado por títulos: un árbol de estructura (`TreeView`, GV-51) en la pestaña «Estructura» del panel derecho (`tvEstructura`), a cargo de `m_Estructura`. Primer nivel: un nodo por .md de front-matter, articulos y back-matter, en el orden del combobox, con su título tomado de la base: `capitulos.titulo_capitulo` en libros, `articulos.titulo_articulo` en revistas, por `nombre_archivo` e `id_proyecto`; sin fila, el nombre del archivo. El archivo principal del proyecto no va, igual que en canónicos y compilación. Debajo, los títulos de cada archivo anidados por nivel.
  Títulos: solo ATX (`#` en la columna 0, de uno a seis, seguidos de un espacio), que es lo único que usan revistas y libros. Se saltean los bloques de código cercados (``` y ~~~) y el encabezado YAML inicial; un `#` sin espacio no es título. Se muestran sin el cierre de `#` ni el bloque de atributos `{…}`.
  Cada nodo guarda archivo y línea (`CTituloMD`). Se reconstruye completo al abrir el proyecto y cuando cambia la lista de archivos; al guardar se rehacen solo los títulos del archivo guardado; al cambiar de archivo no se reconstruye, se despliega ese capítulo y se pliegan los demás. Medido en banco: 32 archivos y 3,7 MB, 800 títulos, en 0,02 s.
  Un click pasa por el aviso de SC-06, cambia de archivo por el combobox si hace falta (GV-53), lleva el cursor al título, lo deja en la primera línea de la vista (GV-52) y devuelve el foco al editor. Solo mouse, como TeXstudio. Si el archivo abierto tiene cambios sin guardar, el título se reubica por su texto, buscando desde la línea guardada hacia afuera.
  El árbol sigue al cursor: marca el título de la sección donde está, 300 ms después del último movimiento. La sección se calcula sobre el texto del editor y el nodo se busca por texto y nivel.
  Filtros por `Visible`, sin reconstruir el árbol: profundidad (capítulo, `##`, `###`, todo) y, a prueba, alcance por prefijo (`fm-`, `a-`, `bm-`). Dos grupos de RadioButton, cada uno en su HBox (`hbProfundidad` y `hbAlcance`), uno debajo del otro: en fila, en la pantalla de una notebook se perdían los dos últimos (GV-55).
  No reemplaza a `VerificarEstructuraMD`, que sigue vigente: se usa apenas termina la conversión de Word a Markdown, cuando lo que llega de Word trae títulos sueltos y saltos de nivel. El árbol muestra la estructura; no la valida.
- Numeración al margen: número de párrafo del cursor en la barra de estado. Ir a la línea N (`tbGoTo`) se conserva calculando la posición sobre `.Text`.

REGLAS DEL CONTROL QUE APLICAN

Nunca escribir `Pos`; mover el cursor con `Select(Posicion, 0)` (GV-44). No usar `ToPos` (GV-45) ni `ToParagraph` / `ToIndex` (GV-44). `.Text` normaliza el espacio duro, y la política del proyecto es que los .md no lo lleven (GV-47).

MÓDULO m_EditorPrincipal

Todo acceso al editor que no sea trivial (foco, fuente, visibilidad) pasa por `m_EditorPrincipal`, y los formularios lo llaman desde sus handlers. Ahí viven las reglas del control; ningún formulario tiene que conocerlas.

- Carga y refresco: `Cargar` (puntos 1 y 2) y `Refrescar` (punto 3), sobre un `CVisorResaltado` con la gramática `markdown`.
- Escrituras, modelo mixto. El cambio global —reemplazar todo, aplicar todas las correcciones, reprocesar footnotes— usa `ReemplazarTodo`, que reasigna el HTML y corta el deshacer. El cambio puntual —una corrección, una footnote, una inserción— usa `ReemplazarTramo` o `Insertar` (`Select` + `Insert`), que conservan el deshacer; el texto nuevo hereda el color del vecino hasta el próximo guardado.
- Cambios sin guardar: `HayCambios` compara `.Text` con el del último punto de control (`MarcarGuardado`). No se usa el evento `Change`, que se dispara también al colorear (GV-46).
- Posiciones: `ParrafoActual` y `ColumnaActual` leen `Paragraph` e `Index`, equivalentes de `Line` y `Column` porque cada línea del .md es un párrafo (SC-15). `PosicionDe(línea, columna)` calcula sobre `.Text`.
- Saltos: `IrA` deja la primera línea del PÁRRAFO arriba de la vista (GV-52) y después selecciona: una palabra en la tercera fila visual queda a la vista sin nuevo desplazamiento. Excepción aceptada: un párrafo más alto que la vista. Reemplaza a `GotoCenter`.
- Ortografía: la palabra queda seleccionada, sin color. `HighlightString` no tiene equivalente, y colorear con `Format` entra en el deshacer (GV-46).
- Mayúsculas y minúsculas: `CambiarCaja`, con las tablas de GV-03 y no con `UCase` / `LCase`.
- Notas: «Ir a la otra marca de la nota» (`menuPopUp`, `m_FuncionesGenericas.IrAParFootnote`) salta entre la marca en el texto y su definición al final del capítulo. Alcanza con que el cursor esté sobre la marca; si la nota tiene varias marcas, desde la definición va a la primera y avisa.
- Las funciones no devuelven el foco: lo hace el handler al final del evento (RC-GM-07). Así sirven también desde los diálogos de búsqueda y ortografía.

**Relaciones:** vinculo:SC-15, vinculo:GV-46, vinculo:GV-49, vinculo:GV-44, vinculo:GV-45, vinculo:GV-47, vinculo:SC-16, vinculo:GV-51, vinculo:GV-52, vinculo:GV-53, vinculo:GV-54, vinculo:GV-55

**PENDIENTE:** Migración integrada y probada en 3.22.1: carga y cambio de archivo, guardado, búsqueda, notas, barra de herramientas, ortografía y cambio de tema. Árbol (m_Estructura): probado en 3.22.1 con un libro real. Refresco incremental no implementado: Refrescar recolorea todo, 1,2 s sobre 2.000 párrafos en el banco.

### SC-19 — Scripts de actualización del corpus: contrato con el importador

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbCorpus / engine/importar_corpus.sh / SQLite · **Verificado:** 2026-09

Los cambios al corpus se aplican con Importar SQL de gbCorpus, que ejecuta `engine/importar_corpus.sh`. Correr el .sql a mano con `sqlite3` se saltea el respaldo y todas las verificaciones: no se hace.

LO QUE EL IMPORTADOR YA GARANTIZA (el script no lo repite)

- Antes de escribir: `sqlite3` presente, base legible e íntegra (`integrity_check`) y `esquema_version` igual al que maneja el importador.
- Respaldo con `VACUUM INTO` en `~/.gbcorpus/respaldos`, con rotación de 20.
- Antepone `PRAGMA foreign_keys = ON`, `.bail on` y `.changes on`: el primer error detiene todo y SQLite deshace la transacción abierta.
- Después: integridad, `foreign_key_check`, vínculos de `relaciones` a códigos inexistentes y listado de las entradas escritas en esa corrida.
- Código de salida: 0 aplicado, 1 no aplicado. Tras un fallo comprueba contando si la base quedó como estaba; no lo afirma sin mirar (SC-13).

LO QUE EL SCRIPT DEBE TRAER

- Una cabecera de comentarios que diga qué hace, qué da de alta y qué modifica. El importador la muestra antes de pedir confirmación. Sin instrucciones para correrlo por línea de comando.
- La línea `-- Esquema: 1` en esa cabecera. Si falta, el importador avisa; si no coincide con la base, aborta.
- Su propia transacción: `BEGIN TRANSACTION;` … `COMMIT;`. Si no la trae el importador envuelve una, pero se escribe igual para que las verificaciones propias queden dentro.
- Verificaciones de lo que el importador no puede saber: que los códigos nuevos estén libres, que un texto a reemplazar exista exactamente una vez, que un `UPDATE` se haya aplicado. Patrón: tabla temporal con `CHECK (ok = 1)`; un `INSERT` que da 0 hace fallar la sentencia, `.bail` la detiene y la transacción se deshace.
- `fecha_alta` y `fecha_modificacion` con `datetime('now','localtime')`. El importador aísla lo escrito en la corrida comparando contra un sello de ese mismo reloj; con `date('now')` no puede.
- Las convenciones de RF-08: `orden = numero * 10`; `cuerpo` y `relaciones` nunca NULL, sino cadena vacía; relaciones como pares `tipo:CODIGO` separados por coma.
- Literales con las comillas simples duplicadas. Conviene generarlos con un programa y no a mano: un apóstrofe sin duplicar corta la sentencia.

Se admite un `SELECT` final de resumen: su salida aparece en el informe.

LO QUE EL SCRIPT NO DEBE TRAER

- `PRAGMA foreign_keys`: el importador ya lo emite, y dentro de una transacción no tiene efecto.
- Una comprobación de `esquema_version`: la hace el importador contra la línea `-- Esquema` de la cabecera.

COTEJO PREVIO A REDACTAR UN SCRIPT

El `corpus.md` adjunto al proyecto de trabajo con Claude se coteja con `docs/corpus.md` del repositorio de gbpublisher, clonado con `git clone --depth 1`: mismas entradas, mismos estados y pasajes testigo idénticos. Si difieren, se trabaja contra el más reciente y se avisa antes de escribir nada. Es lo que garantiza que un código nuevo esté libre y que un texto a reemplazar exista tal como se lo cita.

**Relaciones:** vinculo:RF-08, vinculo:SC-13

### SC-20 — Botones del marco de ventana: m_Ventana.FijarBotones desde Form_Show

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 / gb.desktop.x11 / Linux Mint Cinnamon X11 · **Verificado:** 2026-09

DECISIÓN CERRADA. Los formularios que no deben minimizarse, maximizarse ni cerrarse desde el marco llaman, en `Form_Show`, a:

    m_Ventana.FijarBotones(Me)          ' SIN LOS TRES BOTONES
    m_Ventana.FijarBotones(Me, True)    ' CONSERVA CERRAR

El mecanismo y su razón están en GV-50.

POR QUÉ UN MÓDULO

La lógica y la dependencia de gb.desktop.x11 quedan en un solo archivo. Si cambia el servidor gráfico (ver el PENDIENTE de GV-50), se toca ese archivo y ningún formulario.

POR QUÉ UNA LÍNEA POR FORMULARIO

No hay un evento global de «se mostró una ventana». Las alternativas no ahorran esa línea: un `Observer` también hay que registrarlo formulario por formulario, y además hay que retener su referencia; heredar de una clase base no se lleva bien con los formularios que tienen archivo `.form`.

POR QUÉ Form_Show Y NO Form_Open

`Open` se dispara una vez; `Show`, en cada muestra. Qt reescribe los hints cuando recrea la ventana (GV-50), y `Show` los repone.

QUÉ HACE LA FUNCIÓN

- Sale sin hacer nada si el formulario está embebido (`TopLevel = False`): no tiene marco propio.
- Las constantes Motif van a nivel de módulo, porque Gambas no admite `Const` local (GV-11).

CONTRAPARTIDA OBLIGATORIA

Un formulario sin botón de cerrar necesita una salida propia en la interfaz: un botón, la tecla Escape, o las dos.

**Relaciones:** vinculo:GV-50, vinculo:GV-11

**PENDIENTE:** WAYLAND: sin verificar, ver GV-50. Tampoco está verificada la variante FijarBotones(Me, True), que conserva el botón de cerrar.

### SC-21 — Snippets del editor: un archivo por snippet en ~/.gbpublisher/snippets/

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22.1 / gb.qt5 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. El editor principal (`txtEditorProyecto`) expande abreviaturas de tres caracteres en fragmentos de texto definidos por cada usuario. La lógica vive en `m_Snippets`; el acceso al editor pasa por `m_EditorPrincipal` (SC-18).

CONTENIDO, NO PREFERENCIA

Un snippet es contenido del usuario, como un `.csl`. Por eso no va en `gbpublisher.conf`, y esto no contradice SC-17, que rige solo las preferencias.

Son personales: cada usuario tiene sus propias lógicas de trabajo, y no hay juego de la casa. No se guarda nada en la base.

ALMACENAMIENTO

- Carpeta `~/.gbpublisher/snippets/`. La crea vacía `m_InicioCierre.DirectorioOcultoApp()` si no existe. NO entra en la lista de copia de SC-11, porque no hay nada que copiar desde el sistema. Si algún día existiera un juego base, recién entonces se agrega a la lista.
- Un archivo por snippet: `<abreviatura>.txt`. El nombre del archivo es la abreviatura y el contenido es el cuerpo, literal, en UTF-8 (`File.Load` / `File.Save`, SC-02). Sin metadatos, sin índice y sin formato propio.
- Guardar es `File.Save`, borrar es `Kill` y renombrar es `Move`. `Move` no pisa un destino existente (GV-39): renombrar hacia una abreviatura que ya existe se rechaza antes, con mensaje.
- Al leer se quita UN salto de línea final, si lo hay: los editores externos lo agregan al guardar.
- Se carga en memoria al arrancar y se recarga después de cada alta, cambio o baja desde el formulario. La expansión nunca lee el disco.
- Al cargar se ignora todo archivo cuyo nombre no cumpla el patrón, como los respaldos del tipo `sc1.txt~` o los archivos ajenos.

NOMBRE

Exactamente tres caracteres, cada uno en `0-9` o `a-z` ASCII. Se excluye todo lo demás, MAYÚSCULAS incluidas: Linux distingue mayúsculas de minúsculas, y `Sc1` y `sc1` serían dos snippets que en pantalla se confunden. El formulario RECHAZA el nombre inválido con un mensaje; no lo convierte en silencio.

Tres caracteres fijos, a propósito: permiten variantes numeradas (`sc1`, `sc2`) y hacen exacta la regla de recorte.

DISPARO: Ctrl+Tab

Se expande si se cumplen las dos condiciones:

1. Los tres caracteres inmediatamente anteriores al cursor forman una abreviatura existente.
2. El carácter anterior a esos tres NO es una letra ni un dígito, en cualquier alfabeto, o bien la abreviatura empieza en la columna 0. La comprobación usa `String.*` (RC-GM-12): con una comprobación que solo mire ASCII, en `Ésc1` se expandiría `sc1`.

Lo que protege contra las coincidencias casuales es esta regla, no que la tecla sea rara. La tecla necesita un modificador porque Tab solo sangra listas y bloques de código en Markdown.

BLOQUE O LÍNEA: LO DECIDE EL CUERPO

- Cuerpo de una sola línea: snippet EN LÍNEA. Se expande en cualquier punto donde se cumpla el disparo.
- Cuerpo con saltos de línea: snippet DE BLOQUE. Además, la línea tiene que contener SOLO la abreviatura, desde la columna 0 y sin nada después. Es la misma condición que ya usa la inserción de figuras y tablas.

No hay campo «tipo». Un bloque nunca parte un párrafo: un `:::` a mitad de línea es un error que Pandoc interpreta mal y que cuesta encontrar.

INSERCIÓN

La abreviatura se reemplaza con `m_EditorPrincipal.ReemplazarTramo`, que conserva el deshacer (SC-18). El texto nuevo hereda el color del vecino hasta el próximo guardado.

Marcador de posición: `•` (U+2022). Si el cuerpo lo tiene, al expandir queda seleccionado el primero; si no, el cursor queda al final de lo insertado.

FALLO

`m_Sonido.sonar("Error")` y `Message.Error` con el motivo exacto, no un aviso en la barra de estado: el usuario puede no advertir que escribió mal la abreviatura, o que la borró o la cambió y no lo recuerda.

    sc4: no existe ese snippet.
    sc1: es de bloque; tiene que estar sola en su línea.

Después del mensaje, el handler devuelve el foco al editor (RC-GM-07).

FORMULARIO

- `btnSnippets`, en el editor, abre el formulario.
- El nombre va en un campo de texto y el cuerpo en un `TextArea` (gb.qt5): texto plano, con tipografía monoespaciada. `TextEdit` no, porque traería formato al pegar.
- La lista es un `GridView` con la abreviatura, si es de bloque o en línea (calculado al cargar) y la primera línea del cuerpo como vista previa.
- Botones Nuevo, Guardar y Borrar. Guardar escribe por abreviatura; si se cambió el nombre de un snippet existente, pregunta si se renombra o se duplica. Borrar pide confirmación. No se guarda un cuerpo vacío.
- Escape cierra (contrapartida de SC-20).

**Relaciones:** vinculo:SC-17, vinculo:SC-11, vinculo:SC-18, vinculo:SC-02, vinculo:RC-GM-07, vinculo:RC-GM-12, vinculo:SC-20, vinculo:GV-39

**PENDIENTE:** Mini-test en banco, con un TextEdit dentro de un TabStrip y un tema oscuro, antes de escribir el módulo: (1) que Ctrl+Tab llegue a KeyPress, y cómo leerlo (Key.Code / Key.Control); (2) que Stop Event impida que Qt use la tecla para mover el foco o cambiar de pestaña; si falla, elegir otra combinación y corregir esta entrada; (3) cuántos Ctrl+Z deshacen una expansión (Select + Insert); (4) que un Insert con saltos de línea cree párrafos y que .Text vuelva idéntico; (5) si las líneas vacías del cuerpo salen con el color por omisión hasta el guardado (GV-54); (6) qué función de Gambas distingue de forma fiable una letra Unicode multibyte de un signo (candidata: m_FuncionesGenericas.EsLetra, GV-03, que cubre ASCII y Latin-1).

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

### RF-07 — Estructura de la base de gbKumula

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** gbKumula / SQLite 3.45 / Gambas 3.22 · **Verificado:** 2026-09

Base local en `~/.gbkumula/kumula.sqlite`, con los PDF generados en `~/.gbkumula/pdfs/`. Lo que viaja entre máquinas es la CARPETA entera, no el archivo `.sqlite` suelto: la base guarda el nombre del PDF, nunca la ruta absoluta.

Esquema en versión 7: 22 tablas y 13 vistas, aplicadas por siete scripts numerados. Nivel registrado en `esquema_version`, igual que en gbCorpus y gbpublisher.

CUATRO GRUPOS DE TABLAS

Transversales, sin prefijo: `vocabulario`, `institucion`, `persona`, `persona_afiliacion`, `sesion`, `documento`, `documento_evento`, `esquema_version`.

Investigación, prefijo `inv_`: `inv_revista` (ficha de producción actual), `inv_revista_indexador`, `inv_revista_persona` (masthead fechado), `inv_auditoria`.

Relación, prefijo `rel_`: `rel_iniciativa`, `rel_iniciativa_revista` (alcance N:M), `rel_iniciativa_estado`, `rel_iniciativa_persona`, `rel_iniciativa_vinculo`, `rel_evento`, `rel_evento_participante`.

Producción, prefijo `pro_`: `pro_tarifa`, `pro_encargo`, `pro_cobro`.

DECISIONES DE MODELO QUE NO SE REDISCUTEN

El pipeline vive en la INICIATIVA, no en la revista ni en la institución. Una iniciativa abarca de una a muchas revistas: el caso de una editorial con dieciséis títulos y un solo interlocutor no entra de otra forma.

La revista es unidad de evidencia. Su ficha es corta a propósito: plataforma, periodicidad, artículos por número, páginas promedio, modo de producción, tres salidas y observaciones. Una ficha de quince campos no se completa y la base miente por omisión.

Las salidas (`tiene_pdf`, `tiene_html`, `tiene_xml`) son de TRES estados: 1 tiene, 0 no tiene, NULL no verificado. La distinción decide si hace falta volver a mirar.

Los estados se derivan de eventos fechados, no se guardan como atributo. El estado actual de una iniciativa sale del último registro de `rel_iniciativa_estado`.

`sesion` es la única medida de esfuerzo de las tres capas y cuelga de exactamente uno de tres objetos, con `CHECK` que lo garantiza. El vocabulario de actividad se elige por contexto con una columna generada con `CASE` (ver GV-30). Toda sesión lleva naturaleza económica: facturado, facturable no cobrado, o inversión.

Los documentos se numeran `AAAA-NNNN` con reinicio anual. El siguiente sale de `MAX(secuencia) WHERE anio = N` (RC-GM-09 con filtro de período), nunca del conteo ni del máximo global. Borrador editable con el PDF descartable; enviado congelado por trigger, y una corrección posterior emite un documento nuevo que referencia al anterior.

`PRAGMA foreign_keys = ON` en cada apertura, sin excepción (GV-30).

VISTAS

`v_tarifa_vigente`, `v_iniciativa_estado`, `v_esfuerzo`, `v_encargo_rentabilidad`, `v_revista_brecha`, `v_revista_valor`, `v_agenda`, `v_iniciativa_esfuerzo`, `v_prioridad_iniciativa`, `v_prioridad_revista`, `v_ejecucion`, `v_alcance_sin_relevar`, `v_iniciativa_cobertura`.

Medidas a escala de cinco años (400 revistas, 900 personas, 150 iniciativas, 3.000 sesiones): el panel de detalle de un objeto se arma en menos de 1 ms y el listado más caro tarda 11 ms. No hace falta caché ni precálculo.

ADVERTENCIA SOBRE LOS TOTALES

`v_iniciativa_esfuerzo` atribuye a cada iniciativa las horas de las revistas de su alcance. Si una revista está en dos iniciativas, sus horas aparecen en las dos: la columna es correcta leída de a una, pero SUMARLA da un total inflado. El total global se saca de `v_esfuerzo` sumando sesiones, nunca sumando por iniciativa.

**Relaciones:** vinculo:GV-30, vinculo:RC-GM-09, vinculo:RC-GM-15

### RF-08 — Estructura de la base de gbCorpus

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbCorpus / SQLite / esquema versión 1 · **Verificado:** 2026-09

Base local en `~/.gbcorpus/corpus.sqlite`. Tres tablas, sin vistas. Nivel registrado en `esquema_version`, igual que en gbpublisher y gbKumula.

ESTA ENTRADA DESCRIBE LA VERSIÓN 1 DEL ESQUEMA. Si `esquema_version` no dice 1, hay migraciones posteriores y esta descripción quedó vieja.

TABLA `entradas`

    id_entrada          INTEGER PRIMARY KEY
    prefijo             TEXT NOT NULL REFERENCES familias(prefijo)
    numero              INTEGER NOT NULL
    codigo              TEXT NOT NULL UNIQUE
    titulo              TEXT NOT NULL
    cuerpo              TEXT NOT NULL DEFAULT ''
    estado              TEXT NOT NULL DEFAULT 'vigente'
    evidencia           TEXT
    entorno             TEXT
    fecha_verificacion  TEXT
    relaciones          TEXT NOT NULL DEFAULT ''
    pendiente           TEXT
    orden               INTEGER NOT NULL
    fecha_alta          TEXT NOT NULL
    fecha_modificacion  TEXT NOT NULL
    UNIQUE (prefijo, numero)

Índices: `ix_entradas_estado`, `ix_entradas_familia`.

DOS CAMPOS QUE NO ADMITEN NULL Y SUELEN CONFUNDIRSE

`cuerpo` y `relaciones` son NOT NULL con DEFAULT cadena vacía. Un INSERT que les pase NULL falla, y el mensaje del driver no dice cuál de los dos fue (GV-29). Cuando no hay relaciones, va cadena vacía.

VALORES ADMITIDOS POR CHECK

    estado      vigente | corregida | deprecada | hipotesis
    evidencia   empirica | doc_oficial | inferida

Solo `vigente` obliga. `corregida`, `deprecada` e `hipotesis` están en la base como memoria, no como norma.

CONVENCIÓN DE `orden`

Dentro de cada familia, `orden = numero * 10`. Deja lugar para intercalar sin renumerar. No es una restricción del esquema: es convención, y hay que respetarla al insertar porque el campo es NOT NULL y no tiene default.

FORMATO DE `relaciones`

Texto libre, pares `tipo:CODIGO` separados por coma. Tipos en uso: `apoya`, `vinculo`, `contracara`, `reemplazada_por`. No hay integridad referencial: una relación a un código inexistente se guarda igual y nadie avisa.

TABLA `familias`

    prefijo         TEXT PRIMARY KEY
    nombre          TEXT NOT NULL
    descripcion     TEXT
    orden           INTEGER NOT NULL
    ancho_numero    INTEGER NOT NULL DEFAULT 2
    en_operativo    INTEGER NOT NULL DEFAULT 1

Las familias son extensibles: agregar una es un INSERT, no un cambio de esquema. `orden` fija la secuencia de los capítulos en la exportación; `en_operativo` decide si la familia entra en el perfil operativo, y hoy solo GV está en 0.

TABLA `esquema_version`

    version  INTEGER NOT NULL
    fecha    TEXT NOT NULL

ALCANCE DELIBERADO DE LA APLICACIÓN

gbCorpus NO da de alta ni elimina entradas ni familias. Solo lee, navega relaciones, edita texto y exporta. Las altas, bajas, cambios de estado y relaciones nuevas se acuerdan en conversación y se aplican por script SQL.

REGLA DE TRABAJO

Antes de pedir cambios sobre el corpus, exportar y compartir el `corpus.md` vigente, para que el trabajo se haga contra el estado real y no contra una copia vieja.

**Relaciones:** vinculo:RF-07, vinculo:GV-29

### RF-09 — Fuente de biblatex-apa

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-apa 9.20 (2025/08/27) / commit efb4437 · **Verificado:** 2026-09

Repositorio: https://github.com/plk/biblatex-apa

ACCESO

La lectura web de GitHub está bloqueada para acceso automatizado. Se accede con `git clone --depth 1`, que funciona.

ORDEN DE CONSULTA

1. `tex/latex/biblatex-apa/bbx/apa.bbx` — referencias. Fuente de verdad del comportamiento.
2. `tex/latex/biblatex-apa/cbx/apa.cbx` — citas.
3. `tex/latex/biblatex-apa/dbx/apa.dbx` — campos y tipos que el estilo agrega al modelo de datos.
4. `tex/latex/biblatex-apa/lbx/` — cadenas localizadas por idioma.
5. `tex/latex/biblatex-apa/lua/apa.lua` — procesamiento auxiliar.
6. `doc/biblatex-apa.tex` — documentación. Informa la intención; si contradice al código, gana el código.

BANCO DE PRUEBAS

`bibtex/bib/biblatex-apa-test-references.bib`, `biblatex-apa-test-citations.bib` y `biblatex-apa-test-misc.bib`. Cada entrada compilada en LaTeX es la salida esperada contra la que se verifican HTML y EPUB.

RELACIONES EN APA

`apa.bbx` implementa `related` con macros propias para `reviewof`, `commenton` y `reprintfrom`, y un toggle `bbx:related` que gobierna la expansión genérica de biblatex.

**Relaciones:** vinculo:SC-14, vinculo:RC-BL-02

**PENDIENTE:** RC-BL-02 afirma que apa ignora related; el fuente lo contradice en general. Relevar tipo por tipo qué relaciones imprime apa y reformular RC-BL-02.

### RF-10 — TextHighlighter.Run: resaltar texto fuera de un editor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 y 3.22.1 / gb.highlight; código fuente de TextHighlighter.class (rama principal) · **Verificado:** 2026-09

    TextHighlighter[Nombre].Run(Texto As String, Estado As Short[]) As Byte[]

Público. Resalta un texto sin ningún editor de por medio. Se llama una vez por línea, con la línea completa y su salto final, pasando el mismo `Short[]` de una llamada a la siguiente: lleva el estado de las construcciones multilínea.

RESULTADO: pares de bytes (estado, largo).

- `largo` va en CARACTERES, coherente con `String.Mid` y con `TextEdit.Select`.
- `largo` 0 es una marca de cambio de fondo y no ocupa texto.
- Un tramo de más de 255 caracteres se parte en varios pares con el mismo estado.
- La suma de los largos incluye el salto final agregado.
- `estado` indexa `TextHighlighterTheme.Styles`, que es global a todas las gramáticas registradas; el índice 0 es siempre `Normal`. El tema se crea DESPUÉS de registrar las gramáticas, para que incluya sus estados.

`CanRewrite = False` en la instancia: si no, los largos pueden no corresponder al texto original.

`ToRichText` también existe, pero une las líneas con `<br>`, que en Qt es un solo bloque, y convierte los espacios en `&nbsp;`: no sirve para un documento editable.

Costo medido: 1,7 s para 392.713 caracteres de Markdown real, unos 1,5 ms por línea en promedio.

**Relaciones:** vinculo:SC-15, vinculo:GV-48

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble y Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

`Lower()`, `LCase()` y `String.Lower()` no pliegan acentos de forma reproducible. Bajo locale C/POSIX son ASCII-only; bajo `es_AR.UTF-8` sí pliegan. Esa dependencia del entorno es PEOR que un comportamiento uniformemente roto: uno roto se detecta en la primera prueba, uno dependiente del entorno funciona en la máquina del desarrollador y falla en una instalación cliente con locale mínimo. Las máquinas de las universidades no se controlan.

    Lower("SEÑOR ÁRBOL")  = seÑor Árbol     (bajo C/POSIX)

gb.IgnoreCase HACE LO MISMO

`String.Comp` y `String.InStr` con `gb.IgnoreCase` se comportan igual que `Lower`: bajo C/POSIX no pliegan acentos, bajo `es_AR.UTF-8` sí. Verificado en Mint 2026-09 sobre el buscador del editor de texto: con el toggle de mayúsculas apagado, `DÉCADA` encontraba `década`. La medición anterior en el contenedor, que había dado negativo, no era un falso negativo: era la otra mitad del mismo comportamiento.

Es la trampa más peligrosa de las tres, porque la comparación parece una operación del lenguaje y no una función de locale.

REGLA: donde la salida deba ser reproducible entre máquinas, NO usar `Upper` / `Lower` nativos NI `gb.IgnoreCase`. Usar las tablas explícitas de `m_FuncionesGenericas`, locale-independientes por construcción:

    EsLetra(iCodigo As Integer) As Boolean
    PlegarAMayuscula(iCodigo As Integer) As String
    PlegarAMinuscula(iCodigo As Integer) As String
    PlegarCadenaAMinuscula(sTexto As String) As String

Las tres de plegado devuelven STRING, no Integer: reciben un codepoint y devuelven el carácter. Comparar su resultado contra un número no compila.

`PlegarCadenaAMinuscula` pliega una cadena entera y CONSERVA LA CANTIDAD DE CARACTERES, porque cada codepoint devuelve exactamente uno. Esa conservación es lo que permite buscar sobre la cadena plegada y usar las posiciones encontradas sobre la cadena original, sin ninguna corrección.

Cobertura: ASCII y Latin-1 Supplement, salteando `×` (215) y `÷` (247), y sin plegar `ß` (223) ni `ÿ` (255), cuyas mayúsculas no siguen la regla de ±32. Alcanza para castellano, portugués, francés e italiano. NO cubre Latin Extended-A, así que `ŽIŽEK` no matchea `Žižek`. Es una limitación conocida y acotada, no un fallo que cambie de máquina en máquina.

`String.IsValid()` responde si una cadena es UTF-8 válido. Es la única forma de detectar un archivo mal codificado.

`File.Load()` no decodifica ni valida. Un archivo en Latin-1 NO produce U+FFFD: produce codepoints basura y ceros que se comen el resto del contenido. Corolario: buscar U+FFFD no sirve como detector de codificación corrupta. Un U+FFFD literal sí es un hallazgo real, pero significa otra cosa: que una conversión anterior ya perdió datos.

`Mid()` con longitud en bytes puede cortar un carácter por la mitad; `String.Mid()` no.

`InStr` y `String.InStr` devuelven posiciones distintas sobre el mismo texto: bytes contra codepoints. Mezclarlas produce desfasajes silenciosos.

El bucle `String.Mid` + `String.Code` por codepoint escala LINEALMENTE, no cuadráticamente: 5.000 codepoints en 0,003 s; 40.000 en 0,021 s. No hace falta optimizarlo.

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

EL PAQUETE DEL BINARIO NO ES SIEMPRE EL PAQUETE DE LA CAPACIDAD

Resolver el enlace dice quién DISTRIBUYE el ejecutable, no quién provee lo que se necesita. Con `java` y con `lualatex` coinciden; con LibreOffice no:

    readlink -f $(command -v soffice)   ->  /usr/lib/libreoffice/program/soffice
    dpkg -S ...                         ->  libreoffice-common

`libreoffice-common` es datos y configuración compartida. El filtro «HTML (StarWriter)» que usa la importación de bibliografía (SC-12) vive en `libreoffice-writer`. Declarar la dependencia según lo que devuelve `dpkg -S` dejaría conforme a apt con una instalación que no convierte nada.

REGLA: para la dependencia declarada y para el panel de diagnóstico, nombrar el paquete que provee la CAPACIDAD, verificado a mano una vez. `dpkg -S` sirve para reportar la versión instalada, no para decidir qué exigir.

`java -version` escribe en stderr, no en stdout. Un `Exec ... To` devolvería cadena vacía.

`command -v` es preferible a `which`: es builtin de POSIX sh, mientras que `which` vive en debianutils y puede no estar. Es también la forma correcta de verificar en tiempo de ejecución que una herramienta externa está presente, antes de lanzarla: sin esa comprobación, la ausencia se manifiesta recién al vencer el plazo de espera y con un mensaje que no dice qué instalar (GV-23).

**Relaciones:** vinculo:GV-20, vinculo:SC-12, apoya:GV-23

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

### GV-29 — El driver colapsa todas las restricciones en un solo mensaje

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.db.sqlite3 / SQLite 3.45.1 / Linux Mint · **Verificado:** 2026-09

gb.db.sqlite3 devuelve el mismo texto para cinco clases de restricción distintas. Verificado con las cinco:

    FOREIGN KEY   -> Abort due to constraint violation
    CHECK         -> Abort due to constraint violation
    UNIQUE        -> Abort due to constraint violation
    RAISE(ABORT)  -> Abort due to constraint violation
    NOT NULL      -> Abort due to constraint violation

Lo único que varía es el prefijo según la vía: por `Exec` llega pelado; por `Edit` + `Update` llega como `Cannot modify record: Abort due to constraint violation`. Eso informa CÓMO falló, no POR QUÉ.

Tres consecuencias directas:

Un `RAISE(ABORT, 'mensaje redactado')` en un trigger NO le llega al usuario. El texto sobrevive para quien abra la base con el cliente `sqlite3` desde la consola, pero es inservible como mensaje de interfaz.

`Error.Text` no sirve para diagnosticar. Cualquier `InStr(Error.Text, "FOREIGN KEY")` para decidir qué salió mal está descartado de entrada.

Las restricciones no pierden valor: cambian de función. Dejan de ser fuente de mensaje y pasan a ser red de seguridad silenciosa, que impide que un error de la aplicación escriba datos malos. Por eso se mantienen todas, trigger incluido.

REGLA: toda operación con restricciones asociadas lleva su guarda previa en Gambas, con el mensaje propio, ANTES de tocar la base. El error del driver queda como último recurso y solo puede decir que la base rechazó el cambio.

Es la versión atenuada de GV-23: un error que se informa pero no dice nada.

**Relaciones:** apoya:GV-23, vinculo:RC-GM-02

**PENDIENTE:** Verificar si gb.db.mysql colapsa igual o propaga el mensaje del servidor, que sí distingue. Si propaga, la regla vale solo para SQLite y gbpublisher no está afectado.

### GV-30 — SQLite desde Gambas: el PRAGMA es por conexión y las columnas generadas no molestan

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.db.sqlite3 / SQLite 3.45.1 / Linux Mint · **Verificado:** 2026-09

Dos comportamientos verificados sobre el mismo esquema.

`PRAGMA foreign_keys = ON` se acepta por `Connection.Exec` y se aplica: un insert que viola una FK se rechaza. Pero es POR CONEXIÓN y no persiste en el archivo. Si no se emite después de cada `Open`, todas las `FOREIGN KEY` declaradas quedan decorativas y nada avisa. Va en la función de apertura, inmediatamente después del `Open`, con su `Try` + `If Error`.

Las columnas generadas (`GENERATED ALWAYS AS ... VIRTUAL`) conviven con el patrón `Edit` + `Update` de RC-GM-15: el driver no las incluye en el `UPDATE` y la operación pasa limpia. SQLite sí rechaza escribirlas por SQL directo, como corresponde.

Esto habilita un patrón útil: una sola tabla de vocabulario con clave primaria `(dominio, codigo)`, y cada tabla hija atando su `FOREIGN KEY` a un subconjunto mediante una columna generada con el dominio fijo:

    dom_tipo TEXT GENERATED ALWAYS AS ('tipo_institucion') VIRTUAL,
    FOREIGN KEY (dom_tipo, tipo_institucion)
      REFERENCES vocabulario (dominio, codigo)

Un código que existe pero pertenece a otro dominio es rechazado. La expresión admite `CASE`, así que el dominio puede elegirse según el contexto de la fila.

Dos requisitos: SQLite >= 3.31 para columnas generadas, y las definiciones de columna deben ir ANTES de las restricciones de tabla (`CHECK`, `FOREIGN KEY`, `UNIQUE`). Puestas al final, el error es `near "dom_tipo": syntax error`, que no dice nada sobre la causa.

**Relaciones:** vinculo:RC-GM-15, vinculo:GV-29

### GV-31 — Property en un módulo: sin Public y calificada desde adentro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

Dos comportamientos verificados al escribir `m_Conexion` en gbKumula.

NO ADMITE `Public`

`Public Property Read X As Tipo` es error de compilación: "Public inesperado". Una `Property` es pública por definición y el único modificador válido es `Private`. La forma correcta es:

    Property Read RutaBase As String

    Private Function RutaBase_Read() As String
      Return $sRuta
    End

SE ACCEDE CALIFICADA DESDE EL PROPIO MÓDULO

Dentro del mismo módulo donde está declarada, el identificador simple NO se resuelve: da "identificador desconocido". Hay que calificar con el nombre del módulo.

    ' MAL, DENTRO DE m_Conexion:
    If Not Exist(RutaBase) Then ...

    ' BIEN:
    If Not Exist(m_Conexion.RutaBase) Then ...

Razón: una `Property` no es un símbolo del ámbito del módulo, como sí lo es una variable `Public`. Es una entrada en la interfaz externa, cuyo valor produce la función `_Read`. En una clase el equivalente sería `Me.X`; un módulo no tiene `Me`, así que se califica con su propio nombre.

Consecuencia práctica: la ventaja de RC sobre usar `Function` —que evita el error de paréntesis olvidados— se paga con la calificación en cada uso interno. Vale igual, pero hay que saberlo antes de escribir el módulo entero.

**Relaciones:** vinculo:GV-05

### GV-32 — New con argumentos no puede ir anidado dentro de otra llamada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

Un constructor con parámetros no se puede usar como argumento de otra función. El compilador responde "Cannot use NEW operator here".

    ' MAL
    aFilas.Add(New CFilaLista(iId, iTipo, aCeldas))

    ' BIEN
    oFila = New CFilaLista(iId, iTipo, aCeldas)
    aFilas.Add(oFila)

LO PELIGROSO ES LA CORRECCIÓN EQUIVOCADA

Quitar el `New` hace que la línea COMPILE, porque `NombreClase(...)` es sintaxis válida para otra cosa. Pero falla en tiempo de EJECUCIÓN, al hacer click en la grilla, lejos de donde estaba el problema. Es GV-23 en estado puro: el fallo se manifiesta lejos de su causa, y el arreglo que hace compilar es peor que el error original.

DIAGNÓSTICO DE LA SESIÓN

Se atribuyó primero al array literal multilínea de SC-05, que también estaba presente. Eran dos cosas distintas: el literal se resolvió pasando a `String[]` con `.Add()`, y el `New` seguía fallando hasta sacarlo a una variable. Cuando dos causas se superponen, arreglar una y ver que el síntoma persiste no significa que la primera no fuera real.

REGLA: todo `New` con argumentos va a una variable primero. Sin excepción, aunque parezca que compila.

**Relaciones:** apoya:GV-23, vinculo:SC-05

### GV-33 — String.Repeat no existe

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

No hay función de repetición de cadena en la clase `String`. `String.Repeat("─", n)` da "Repeat es desconocido" en tiempo de ejecución.

Para armar separadores o rellenos, bucle explícito:

    sSubrayado = ""

    For iPos = 1 To String.Len(sTexto)
      sSubrayado &= "─"
    Next

`String.Len` y no `Len` (SC-02): con `Len` el subrayado queda más largo que el título cuando este lleva acentos, porque cuenta bytes.

VERIFICADO EN LA MISMA SESIÓN, POR CONTRASTE

`TypeOf(vValor) = gb.Boolean` SÍ funciona y sirve para distinguir un Boolean de un nulo antes de convertirlo a texto, que es lo que pide GV-10.

**Relaciones:** vinculo:SC-02, vinculo:GV-10

### GV-34 — Edit + Update escribe NULL de verdad

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.db.mysql / MySQL / Linux Mint · **Verificado:** 2026-09

Asignar `Null` a un campo dentro del patrón `Edit` + `Update` (RC-GM-15) escribe NULL en la columna, no cadena vacía. Verificado en MySQL sobre `bibtex.related_string`, comprobando la fila resultante en el cliente.

    rReg = hConn.Edit("tabla", "id = &1", iId)
    With rReg
      !campo_a = sValor
      !campo_b = Null
      Try .Update()
    End With

Importa porque hasta acá la única vía segura para escribir un NULL parecía ser un `Exec` con el literal en la sentencia, que es justamente lo que RC-GM-15 desaconseja. Con esto el patrón canónico cubre también el caso, y la distinción entre NULL —"no aplica"— y cadena vacía —"se escribió algo vacío"— se puede sostener desde la interfaz sin excepciones al patrón.

Aplicado en FRelacionarBib: de `related_type` y `related_string` se escribe uno y el otro va a NULL.

**Relaciones:** vinculo:RC-GM-15

### GV-35 — Leer Format en TextEdit: no distingue seleccion mixta, y cuanto cuesta recorrer

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

`Format.Font.Bold` sobre una seleccion que abarca texto con y sin negrita devuelve `True`, igual que sobre una seleccion integramente en negrita. NO hay valor indeterminado.

    parrafo sin negrita      -> False
    parrafo todo en negrita  -> True
    mitad y mitad            -> True

La propiedad informa el formato de UN punto de la seleccion, no el del conjunto. Consecuencia: no se puede resolver un parrafo uniforme con una sola lectura ni saltear tramos, porque un salto puede pasar por encima de una italica corta.

COSTO DEL RECORRIDO FINO

`Select(i, 1)` mas la lectura de `Font.Bold`, `Font.Italic`, `Color` y `Background`, por caracter:

    10.000 iteraciones           0,283 s
    proyectado a 100.000         2,8 s

Medido sobre texto sin formato; con muchos tramos puede ser mas. Es tolerable como costo de guardado ocasional, con `Application.Busy`, pero recordar que mientras corre el procedimiento el interprete no entra al bucle de eventos y la interfaz queda congelada (GV-17).

Por esto el editor de bibliografia no serializa a RTF (SC-12): el recorrido existiria solo para construir el archivo.

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-17, vinculo:SC-12

### GV-36 — Color.Default limpia el fondo del TextEdit pero hace invisible la letra

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

Las dos propiedades de color de `Format` no se comportan igual ante `Color.Default`.

    Format.Background = Color.Default   LIMPIA el fondo, correcto
    Format.Color = Color.Default        deja el texto INVISIBLE

El texto sigue ahi y se ve al seleccionarlo, pero no se lee. Para quitar un color de letra hay que asignar el color explicito que corresponda, tipicamente `Color.Black`.

Y ninguna de las dos devuelve al leer el valor que se asigno: despues de limpiar un fondo amarillo, `Format.Background` devuelve `rgba(255,255,255,0.000)` y no el valor asignado.

REGLA: nunca preguntar si un tramo tiene el color por omision. Preguntar si tiene exactamente la marca que la aplicacion escribe. Ademas de ser lo unico que funciona, es mas robusto: no depende de la semantica del canal alfa.

**Relaciones:** vinculo:GV-35, vinculo:SC-12

### GV-37 — La fuente del control y el documento cargado se pisan en las dos direcciones

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

Asignar `Font.Name` y `Font.Size` a un `TextEdit` no cambia como se ve un documento que ya esta cargado. El HTML del documento lleva su propia declaracion de familia y cuerpo, y esa le gana a la fuente del control.

Sintoma: el dialogo de tipografia funciona, la eleccion se recuerda al reabrirlo, y en el editor no pasa nada.

Para que el cambio tenga efecto hay que quitar del HTML toda declaracion de `font-family` y `font-size` y volver a cargarlo. Entonces el documento cae en la fuente del control. Reasignar `RichText` (y también `Text`) deja el cursor AL FINAL del documento. Medido en 3.22.1 y en 3.19; una versión anterior de esta entrada decía «al principio». Para llevarlo al principio, `Select(0, 0)`: nunca se escribe `Pos` (GV-44).

LA DIRECCION CONTRARIA

Asignar `RichText` rehace el documento entero, y con eso la vista vuelve al valor por omision del control: se lleva puesta la tipografia que estuviera aplicada. Es la misma mecanica, al reves.

Consecuencia operativa: una preferencia de vista no se repone una sola vez al abrir el proyecto. Hay que reponerla DESPUES DE CADA CARGA de documento, y por eso conviene que la preferencia viva en el modulo que carga —que la recuerda, la escribe en la configuracion y la reaplica— y no en el formulario, que no se entera de las recargas.

COROLARIO PARA EL ARCHIVO GUARDADO

Si la tipografia viaja dentro del archivo, queda atada a la fuente que tenia el editor el dia que se guardo, y al reabrirlo el boton de tipografia no tiene efecto. Donde la tipografia sea ajuste de pantalla y no contenido —el editor de bibliografia, SC-12— hay que quitarla TAMBIEN al guardar, no solo al aplicar.

**Relaciones:** vinculo:SC-12, vinculo:GV-35, vinculo:GV-44

### GV-38 — El As de Exec exige un literal: una constante da identificador desconocido

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

El nombre del observador de eventos de un proceso se resuelve al compilar y no acepta una constante ni una variable.

    Private Const NOMBRE As String = "ProcX"
    Try hProceso = Exec aComando For Read As NOMBRE     -> NOMBRE es desconocido

    Try hProceso = Exec aComando For Read As "ProcX"    -> correcto

Es incomodo porque invita a dejar el nombre escrito en cuatro lugares: la invocacion y los tres handlers `_Read`, `_Error` y `_Kill`. No hay forma de centralizarlo en una constante.

Y no hay red de contencion: un nombre mal escrito en el literal NO da error de compilacion, hace fallar el Exec en tiempo de ejecucion con un mensaje que habla de un handler incorrecto y no del nombre (GV-18). Por eso el `Try` con `If Error` sobre el propio `Exec` no es opcional.

**Relaciones:** vinculo:GV-18, apoya:RC-GM-02

### GV-39 — Move no pisa un destino existente

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

La sentencia `Move` falla con `File already exists` si el destino ya existe. No sobrescribe.

Importa en el patron de escritura atomica, que es justamente donde el destino SIEMPRE existe:

    Try File.Save(sRutaTemp, sContenido)     ' 1. TEMPORAL EN LA MISMA CARPETA
    Try Copy sRuta To sRutaRespaldo          ' 2. RESPALDO
    Try Kill sRuta                           ' 3. BORRAR EL DESTINO
    Try Move sRutaTemp To sRuta              ' 4. REEMPLAZO

El paso 3 abre una ventana en la que el archivo no existe. La cubre el respaldo del paso 2, que ya esta escrito en disco. Si el paso 4 falla, el mensaje debe decir donde quedo cada cosa —el contenido en el temporal, la version anterior en el respaldo— y NO borrar el temporal: es el unico lugar donde esta el trabajo.

El temporal va en la misma carpeta que el destino para que el reemplazo no cruce sistemas de archivos.

**Relaciones:** vinculo:GV-01, vinculo:SC-12

### GV-40 — Pandoc lee RTF pero descarta los colores; LibreOffice sin interfaz los conserva

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1 / LibreOffice 24.2 / Linux · **Verificado:** 2026-09

Pandoc tiene lector de RTF desde la version 3.0, marcado como alpha. Lee bien texto, acentos, comillas curvas, italicas y negritas. Pero su modelo interno NO representa color de letra ni color de fondo, asi que los descarta sin aviso.

Medido sobre un archivo real de 99 KB con 119 tramos de fondo amarillo y 7 de letra roja: la salida trajo 95 italicas y 11 negritas correctas, y CERO colores.

LibreOffice en modo sin interfaz si los conserva, y convierte tanto `.docx` como `.rtf` con el mismo comando:

    soffice --headless --norestore
            -env:UserInstallation=file:///tmp/perfil
            --convert-to "html:HTML (StarWriter)"
            --outdir CARPETA ARCHIVO

El perfil aparte no es opcional: sin el, soffice se conecta a la instancia de LibreOffice que el usuario pueda tener abierta y no convierte nada.

DOS DETALLES DEL RTF DE WRITER, por si alguna vez hay que parsearlo a mano:

El resaltado NO es `\highlight`: LibreOffice usa `\chcbpat`, fondo de patron de caracter. Un lector que busque `\highlight` no encuentra ni una marca.

No hay un solo `\b0` ni `\i0`: el alcance de la negrita y la italica viene dado por los grupos `{ }`, no por marcas de apagado. Un parser que solo mire `\b` y `\b0` deja todo en negrita desde la primera.

**Relaciones:** vinculo:SC-12

### GV-41 — El rescate accidental: un escaner byte a byte que parece funcionar en castellano

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

Caso real del corrector ortografico del proyecto, y vale como advertencia general sobre RC-GM-12.

Un recorrido de palabras escrito con `Mid` y `Asc` recibe un BYTE por vuelta, no un caracter. En UTF-8 toda letra acentuada ocupa dos bytes: uno inicial en 194-223 y uno de continuacion en 128-191. Un criterio de letra que acepte el rango 192-255 acepta el byte inicial y RECHAZA el de continuacion, con lo que parte la palabra al medio.

Pero el criterio tenia ademas dos lineas de rescate:

    If InStr("ÁÉÍÓÚÑÜ", sCaracter) > 0 Then Return True
    If InStr("áéíóúñü", sCaracter) > 0 Then Return True

Como `InStr` tambien opera en bytes, no compara caracteres: pregunta si ese byte aparece en cualquier posicion de esas dos cadenas. Y los bytes de continuacion de esas catorce letras estan literalmente ahi adentro. El conjunto rescatado resulta ser:

    0x81 0x89 0x8D 0x91 0x93 0x9A 0x9C 0xA1 0xA9 0xAD 0xB1 0xB3 0xBA 0xBC 0xC3

que es exactamente lo que hace falta para que las catorce letras del castellano sobrevivan enteras. El error de `Mid` y el error de `InStr` se cancelan, y SOLO para ese subconjunto.

QUE SI SE ROMPE

Las otras 34 letras latinas con diacritico: à â ã ä ç è ê ë ì ï ò ô õ ö ø ù û y sus mayusculas. En una bibliografia academica no es hipotetico: Goncalves, Sao Paulo, Böhm, Fernao.

Y dos caracteres tipograficos cuyo tercer byte coincide con el conjunto rescatado: la comilla curva izquierda (E2 80 9C, y 0x9C es la cola de Ü) y la semirraya (E2 80 93, y 0x93 es la cola de Ó). El escaner los pega a la palabra siguiente y produce fragmentos que no son UTF-8 valido.

EL SINTOMA ES UN FALSO NEGATIVO, NO UN FALSO POSITIVO

Una palabra partida llega a la herramienta externa como UTF-8 invalido, vuelve distinta de como se guardo, no coincide con la clave con que se indexo y se descarta EN SILENCIO. `camàra` mal escrita no aparecia como error. El corrector no avisaba de mas: avisaba de menos, y no habia forma de notarlo.

MORALEJA

Un recorrido byte a byte que funciona en las pruebas puede estar sostenido por una coincidencia de valores de bytes. Basta con que alguien agrega una letra a un literal, o que entre un apellido portugues, para que el comportamiento se corra sin aviso. `String.Len`, `String.Mid` y `String.Code` desde el principio.

**Relaciones:** apoya:RC-GM-12, vinculo:GV-03, vinculo:GV-23

### GV-42 — TerminalView: comportamiento y la trampa del árbol de contenedores

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.terminal / Qt5 / Linux Mint · **Verificado:** 2026-09

El componente es `gb.form.terminal`, no `gb.terminal`. Arrastra `gb.term` como dependencia.

`TerminalView.Exec(aComando)` devuelve un `Process` con `State` y `Value` utilizables. El sondeo va con la SENTENCIA `Wait` y no con `Process.Wait()`, que bloquearía el bucle de eventos (GV-17).

LA TRAMPA: UN TERMINAL APAGADO NO RECIBE TECLADO

Si para bloquear la interfaz durante la espera se apaga un contenedor que está POR ENCIMA del control en el árbol, se apaga también el terminal. Un proceso interactivo queda entonces esperando una respuesta que no puede llegar, y la aplicación parece colgada aunque el bucle de espera esté funcionando perfectamente.

Costó un cuelgue completo, con la aplicación imposible de cerrar porque el guard de cierre también estaba activo.

REGLA: el bloqueo va contenedor por contenedor, nunca sobre un ancestro del terminal. Y el foco se repone explícitamente después del `Exec`, o el prompt no se puede contestar (RC-GM-07).

PROCESOS INTERACTIVOS

El plazo máximo no puede ser corto: la espera incluye al usuario leyendo y contestando. Quince minutos, no treinta segundos.

Y la vía de escape tiene que existir. El cierre del formulario OFRECE interrumpir en lugar de negarse: matar el proceso deja al hijo morir con su transacción abierta, la base la deshace sola, y el bucle de espera sale por el camino normal.

ASPECTO

Fondo, letra y fuente se fijan explícitamente en el arranque; si se deja la fuente por omisión, Qt sintetiza el bold y se ve mal. Los colores ANSI que emita el script los pinta el emulador por su cuenta y no hay que hacer nada.

**Relaciones:** vinculo:SC-13, vinculo:GV-17, vinculo:RC-GM-07

**PENDIENTE:** Dos comportamientos provienen de fuentes secundarias (foros de Gambas) y no se verificaron en el proyecto: que el TerminalView no muere al cerrarse el formulario y deja un bash huérfano, y que devuelve «terminal already in use» si se lanza un segundo proceso sobre el mismo control. Confirmar antes de citarlos como hechos.

### GV-43 — Desktop.Open: sin espera no informa fallos, con espera congela la interfaz

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.desktop / código fuente del componente / Linux Mint · **Verificado:** 2026-09

Verificado en el fuente del componente, etiqueta 3.22.1 (`comp/src/gb.desktop/.src/Desktop.class` y `Main.module`), y en uso en Linux Mint.

Firma:

    Desktop.Open(Url As String, Optional Wait As Boolean)

QUÉ HACE

Pasa la ruta por `File.RealPath` y lanza `xdg-open` con `Exec` sobre un array: no hay `sh -c`, así que una ruta con espacios o metacaracteres no se interpreta (GV-06).

No depende del paquete `xdg-utils` del sistema: el componente trae su propia copia del script y la instala en un temporal en el primer uso.

Si el portal de escritorio está habilitado (`DesktopPortal.Enabled`), lo intenta primero y recién si falla cae en xdg-open.

LOS DOS MODOS NO INFORMAN LO MISMO

    Wait = False (omisión)   hProcess.Ignore = True; vuelve al instante
    Wait = True              hProcess.Wait; códigos 1 a 5 -> Error.Raise

Sin espera, un fallo de xdg-open —archivo inexistente, ningún visor asociado— NO llega nunca al llamador. El `Try` sobre `Desktop.Open` solo atrapa errores de lanzamiento. Es un canal mudo por construcción (GV-23).

Con espera, los fallos se traducen a errores atrapables (1 sintaxis, 2 archivo inexistente, 3 falta una herramienta, 4 la acción falló, 5 acceso prohibido), pero la espera es `Process.Wait` y la interfaz queda congelada mientras xdg-open no termine (GV-17). Si xdg-open cae en su modo genérico y lanza el visor directamente, no termina hasta que el usuario cierra el visor.

REGLA: usar sin espera, y hacer en Gambas, ANTES de la llamada, las verificaciones que se quieran informar. Como mínimo `Exist` sobre la ruta: es el único fallo que el usuario puede provocar entre que un archivo se lista y se lo abre.

Aplicado en `m_RevisarPDF.AbrirPDFEnVisorExterno`, que abre en el visor del sistema el PDF elegido en `cmbVerPDF`. Motivo: el `PictureBox` muestra páginas rasterizadas, y los hipervínculos del PDF solo se pueden usar y probar en un visor real. Verificado en Mint: abre el visor predeterminado sin bloquear la interfaz.

**Relaciones:** vinculo:GV-17, apoya:GV-23, vinculo:GV-06

**PENDIENTE:** Falta medir si xdg-open en Cinnamon vuelve de inmediato (delegando en gio open) o espera a que se cierre el visor. Mini-test: en una terminal, xdg-open archivo.pdf; echo $? — si el echo aparece recién al cerrar el visor, Wait = True queda descartado definitivamente. Hasta medirlo, no usar Wait = True.

### GV-44 — TextEdit.Pos: escribirlo manda el cursor al final

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint; código fuente de CTextEdit.cpp (rama principal) · **Verificado:** 2026-09

Escribir `Pos` en un `TextEdit` (gb.qt5.ext) falla en silencio cuando el documento creció desde la primera vez que se usó la propiedad.

La escritura compara la posición pedida contra una longitud en caché (`THIS->length`). La caché se calcula en el primer uso y NO SE INVALIDA NUNCA: la única asignación a -1 está en el constructor, y la que había en la propiedad `Text` está comentada (`CTextEdit.cpp`). Si la posición pedida es mayor o igual que esa longitud vieja, el cursor va al final del documento.

Síntomas en el proyecto: el editor de bibliografías reponía el cursor con `Pos` y lo dejaba al final; en el banco de pruebas, la posición 900 de un documento de 190.000 caracteres cayó en el último párrafo.

`TextArea` (gb.qt5) NO tiene el problema: invalida la caché en cada cambio (`CTextArea::changed`).

REGLA: en `TextEdit` nunca se escribe `Pos`. Para mover el cursor sin seleccionar:

    hControl.Select(iPosicion, 0)

`Select` usa `setPosition` directamente y no pasa por la caché. LEER `Pos` sí es confiable.

LA MISMA CACHÉ EN OTRAS DOS FUNCIONES

`ToParagraph(Pos)` y `ToIndex(Pos)` pasan por `from_pos`, que compara contra la misma longitud en caché: si la posición pedida la supera, devuelven el final del documento. No se usan.

`Paragraph` e `Index` en LECTURA no tienen el problema: leen `blockNumber()` y la posición del cursor menos la del bloque, en el momento. Verificados en banco como equivalentes de `Line` y `Column` de `TextEditor`.

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-45, apoya:GV-23

**PENDIENTE:** ToParagraph y ToIndex: leído en el fuente de CTextEdit.cpp, no medido en ejecución.

### GV-45 — TextEdit.ToPos cuenta mal

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.qt5.ext, CTextEdit.cpp (rama principal) · **Verificado:** 2026-09

`ToPos(Párrafo, Columna)` de `TextEdit` tiene dos errores en el fuente (`CTextEdit.cpp`, función `to_pos`, rama Qt5):

1. Empieza a contar desde el bloque donde está el cursor, no desde el principio del documento.
2. Suma `block.length() + 1` por cada párrafo recorrido, cuando `block.length()` ya incluye el separador: cuenta un carácter de más por párrafo.

Explica el síntoma que había quedado pendiente en RC-GM-21: seis caracteres de más sobre un texto de tres párrafos.

REGLA: no se usa `ToPos`. La posición absoluta del comienzo de un párrafo se calcula sobre `.Text`: la suma de `String.Len` de cada párrafo previo, más 1 por cada salto.

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-44

### GV-46 — TextEdit: Format entra en la pila de deshacer; la carga por RichText no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-09

Cambiar el color de una selección con `Format.Color` ES un paso de deshacer. Verificado: después de escribir una palabra y colorear otra, el primer Ctrl+Z quita el color y recién el segundo deshace la palabra.

Cada asignación a `Format` dispara además `Change`, y el `Select` previo dispara `Cursor`. Colorear un documento entero emitió 7.347 eventos `Change`: un recoloreo colgado de `Change` se realimenta, y una marca de «modificado» se enciende solo por colorear.

Cargar el documento con `RichText` NO deja rastro en la pila: tras cargar un HTML coloreado y editar, el primer Ctrl+Z quita la edición y conserva el color, y el segundo no hace nada. Asignar `Text` usa `setPlainText`, que según la documentación de Qt vacía la pila.

CONSECUENCIA: en un control editable, el resaltado de sintaxis no se aplica con `Format`. Se arma un HTML y se asigna con `RichText` (SC-15).

Costo medido de `Select` + `Format.Color`: alrededor de 0,6 ms por tramo.

REASIGNAR `RichText` VACÍA EL HISTORIAL DE DESHACER. Verificado en 3.22.1 (Mint) y en 3.19 (banco `gbPruebaEditor`, «Deshacer tras refresco»): con una edición antes de reasignar y otra después, el primer Ctrl+Z quita la posterior y el segundo no hace nada; la anterior ya no se puede deshacer.

Consecuencia: un modelo que recolorea reasignando el HTML corta el deshacer en cada refresco. Cuándo refrescar es una decisión de uso, no técnica (SC-18).

**Relaciones:** vinculo:GV-35, vinculo:SC-15, vinculo:SC-18

### GV-47 — TextEdit y TextArea: .Text no devuelve el texto exacto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 y gb.qt5.ext / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-09

`TextEdit.Text`, `TextArea.Text` y `TextEdit.Selection.Text` pasan por `QTextDocument::toPlainText` de Qt, que al LEER transforma:

    U+00A0 espacio duro     -> espacio común
    U+2028 / U+2029         -> salto de línea
    CR suelto               -> salto de línea
    CRLF                    -> LF (un solo salto, sin duplicar)

Conserva todo lo demás que se probó: guion blando U+00AD, espacios de ancho cero, U+202F, BOM, word joiner y caracteres de uso privado (U+E000). Qt tiene `toRawText` para conservar el espacio duro, pero Gambas no lo expone. `TextEditor` (gb.form.editor) devuelve el texto exacto.

Pandoc escribe el `&nbsp;` como U+00A0 literal en el .md y lo pasa a `~` en LaTeX: guardar desde un `TextEdit` lo convertiría en un punto donde LaTeX puede cortar la línea.

EN gbpublisher NO AFECTA, por política: los .md no llevan espacios duros. El contrato de ingreso los elimina (`engine/limpiar_docx.lua`) y el escáner UTF-8 detecta los que entren después (U+00A0, U+2028, U+2029). La normalización de CRLF a LF coincide con SC-02.

Si la política cambiara, la salida verificada es sustituir 1:1 el U+00A0 por U+E000 al cargar y restituirlo al leer: las posiciones no se corren. Quedarían por cubrir el tipeo (AltGr+Espacio), el pegado y el copiado.

**Relaciones:** vinculo:SC-02, vinculo:GV-03, vinculo:SC-16

### GV-48 — gb.highlight trae resaltadores incorporados: una gramática propia se registra con prefijo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble, Gambas 3.22.1 / Linux Mint y código fuente de gb.highlight (rama principal) · **Verificado:** 2026-09

`gb.highlight` registra al inicializarse los .highlight que trae el propio componente, y la lista cambia entre versiones. En 3.19: c, cplusplus, css, diff, gambas, highlight, html, javascript, sh, sql, webpage. La rama principal agrega, entre otros, `xml`, `json`, `csv` y `settings`.

Si una gramática propia se registra con el nombre de un incorporado, `TextHighlighter.List.Exist` da True, el registro propio no ocurre y `Run` usa la gramática incorporada, con otros nombres de estilo (`Markup`, `Attribute`, `Value`…). Síntoma en el proyecto: el visor XML mostraba solo el fondo y el color de letra. Y el viejo registro de `XML.highlight` en FMain tampoco se estaba usando en 3.22.

REGLA: las gramáticas propias se registran con prefijo, `gbp_xml` y `gbp_markdown`, aunque hoy no haya choque.

Otros datos verificados del componente:
- `Register` compila la gramática en tiempo de ejecución con `gbc3` (por `Shell`): necesita las herramientas de desarrollo de Gambas, y `gb.pcre` para las reglas `match /…/`.
- La primera consulta a `TextHighlighter.List` inicializa el componente y puede fallar: va con `Try`.
- `TextHighlighterStyle.Oblique` existe en 3.22 y no en 3.19.

**Relaciones:** vinculo:RF-10, vinculo:SC-15, apoya:GV-23

### GV-49 — gb.form.editor con Wrap: el click al comienzo de una fila visual va al comienzo del párrafo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.form.editor / Linux Mint; código fuente de TextEditor.class (rama principal) · **Verificado:** 2026-09

En `TextEditor` con `Wrap`, un párrafo largo es UNA línea real partida en filas visuales. Hacer click al comienzo de la tercera fila, que puede ser la columna 250 de la línea real, lleva el cursor a la columna 0: el comienzo del párrafo.

Causa, en `TextEditor.class`, función `PosToColumn`: el atajo `If PX < $MW Then Return 0` devuelve la columna 0 de la línea real sin mirar la fila visual, y la rama del margen hace lo mismo con `Goto(0, Y)`. Un poco más a la derecha, el redondeo hacia arriba da la columna siguiente: la correcta solo se alcanza con precisión de un píxel.

Otros rasgos de «dureza» leídos en el fuente:
- El click redondea al borde más cercano (resta medio ancho de espacio) y el arrastre no.
- No hay umbral de arrastre: un píxel de movimiento extiende la selección.
- El doble y el triple click no cambian la granularidad del arrastre.
- La rueda la maneja el `ScrollArea` de `gb.gui.base`, con un paso fijo de `30 × Desktop.Scale` píxeles por muesca.

Verificado a mano: el mismo texto partido en líneas cortas se mueve mucho mejor, así que el costo crece con el largo de la línea real. Contraste medido: `TextEdit` (gb.qt5.ext) cargó 392.713 caracteres, con párrafos de hasta 3.737, en 9 ms, con scroll y selección fluidos.

Alivio sin cambiar de control: la tecla Inicio sí respeta las filas visuales.

**Relaciones:** vinculo:RF-02, vinculo:SC-15

### GV-50 — Botones del marco de ventana: se quitan con _MOTIF_WM_HINTS, no con Border

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 / gb.desktop.x11 / Muffin / Linux Mint Cinnamon X11; código fuente de gb.qt4, gb.desktop.x11, Muffin y Qt 5.15 · **Verificado:** 2026-09

Gambas no tiene una propiedad que quite minimizar, maximizar o cerrar conservando el marco. `Border = False` (la opción del IDE) le pide al gestor de ventanas que no decore: se van la barra de título, el título y el arrastre. Solo toca la parte de decoración de `_MOTIF_WM_HINTS` (`X11_set_window_decorated`, `gb.qt4/src/x11.c`, compartido por gb.qt5).

LO QUE FUNCIONA

Escribir `_MOTIF_WM_HINTS` declarando solo las FUNCIONES permitidas, sin tocar la decoración, con `X11.SetWindowProperty` de gb.desktop.x11:

    ' [FLAGS, FUNCTIONS, DECORATIONS, INPUT_MODE, STATUS]
    X11.SetWindowProperty(Me.Handle, "_MOTIF_WM_HINTS", "_MOTIF_WM_HINTS", [1, 6, 0, 0, 0])

- FLAGS = 1 (`MWM_HINTS_FUNCTIONS`), sin el bit de decoraciones (2): el marco queda por omisión, con título.
- FUNCTIONS sin `MWM_FUNC_ALL` (1) habilita SOLO lo listado: MOVE (4) + RESIZE (2). MINIMIZE es 8, MAXIMIZE 16, CLOSE 32. Con el bit 1 encendido la lógica se invierte: los bits listados son los que se quitan.

Verificado en Mint: desaparecen los tres botones, el título se conserva y la ventana se arrastra. `Me.Handle` (Long) se pasa directo, sin conversión.

Muffin lee los hints en `reload_mwm_hints` (`src/x11/window-props.c`). `SetWindowProperty` convierte un `Integer[]` a `long` en 64 bits (`gb.desktop.x11/src/c_x11.c`), que es el formato 32 que espera la propiedad.

QT LOS PISA AL RECREAR LA VENTANA

Qt reescribe `_MOTIF_WM_HINTS` en `QXcbWindow::setWindowFlags` (Qt 5.15). Gambas llama a `setParent` con flags nuevos al cambiar `Utility`, `Resizable` o el contenedor padre (`doReparent`, `CWindow.cpp`). Después de cualquiera de esos cambios hay que volver a escribir los hints. Por eso van en `Form_Show` y no en `Form_Open`.

OTRAS VÍAS, SEGÚN EL FUENTE DE MUFFIN (`meta_window_recalc_features`, `src/core/window.c`)

    Utility = True        tipo DIALOG: sin minimizar ni maximizar; cerrar queda
    Resizable = False     mínimo = máximo: sin maximizar
    SkipTaskbar = True    sin minimizar, y fuera de la barra de tareas

Leídas en el fuente, no medidas. Ninguna quita el botón de cerrar.

Aplicado en SC-20.

**Relaciones:** vinculo:SC-20, vinculo:GV-11

**PENDIENTE:** WAYLAND: sin verificar, y hoy no se sabe qué pasará. Lo único leído en el fuente de Muffin, no medido: los hints Motif solo se aplican a ventanas de clientes X11; una ventana Wayland nativa se decora del lado del cliente. Así que el resultado dependería de si la aplicación corre por XWayland o como cliente Wayland nativo, y gb.desktop.x11 necesita un display X. Mientras el proyecto apunte exclusivamente a X11 no afecta; si eso cambia, esta entrada deja de valer hasta medirla. Tampoco está verificado si Alt+F4 sigue cerrando la ventana.

### GV-51 — TreeView: el click del mouse dispara Select y Click; asignar Key, solo Select

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.gui.base / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble; código fuente de _TreeView.class (etiqueta 3.22.1) · **Verificado:** 2026-09

`TreeView` y `ListView` son la misma clase interna, `_TreeView`, escrita en Gambas en `gb.gui.base`. Difieren en `Add`: el de `ListView` no tiene parámetro `Parent`, así que no anida. `ListBox` es una lista de cadenas sin clave por ítem.

    TreeView.Add(Key, Text, [Picture], [Parent], [After]) As _TreeView_Item

Cada ítem tiene `Tag` (Variant), `Depth` (0 en el primer nivel), `Expanded`, `Visible` y `EnsureVisible()`.

EVENTOS, MEDIDOS

    click con el mouse            Select, después Click
    asignar Key desde el código   solo Select

REGLA: la navegación cuelga de `Click`. Así, marcar desde el código el nodo que corresponde a la posición del editor no navega, y no hay realimentación.

KEY SOBRE UN NODO DE PADRE PLEGADO

No lo marca, y `Key` se lee vacío: el nodo no tiene fila (`_ItemToRow` devuelve -1). Primero `Item.EnsureVisible()`, que despliega los ancestros; después `Key`.

FILTRAR SIN RECONSTRUIR

`Item.Visible = False` oculta el nodo sin tocar la estructura: sirve para filtrar por profundidad. Detalle estético: un padre desplegado cuyos hijos se ocultaron conserva la flecha abierta.

**Relaciones:** vinculo:SC-18, vinculo:GV-52

**PENDIENTE:** El evento Filter(Key) y el método Filter() existen en el fuente y no se probaron.

### GV-52 — TextEdit: llevar un párrafo a la primera línea de la vista

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble; código fuente de CTextEdit.cpp (etiqueta 3.22.1) · **Verificado:** 2026-09

`Select(Posicion, 0)` pasa por `setTextCursor` de Qt, y `EnsureVisible()` llama a `ensureCursorVisible` (`CTextEdit.cpp`). Qt desplaza lo mínimo para que el cursor se vea: si el destino está más abajo de la vista, queda al PIE; si está más arriba, en la PRIMERA LÍNEA.

Para dejarlo siempre arriba se pasa antes por el final del documento:

    hEditor.Select(String.Len(hEditor.Text), 0)
    hEditor.EnsureVisible()
    hEditor.Select(iPos, 0)
    hEditor.EnsureVisible()

Medido con y sin `Wrap` sobre 2.000 párrafos: sin el paso previo, el título quedó al pie; con él, en la primera línea. La diferencia de `ScrollY` entre los dos casos es la altura de la vista.

`ScrollY` se puede escribir, pero va en píxeles, y `TextEdit` no expone la posición en píxeles de un carácter: no sirve para esto.

Nunca se escribe `Pos` (GV-44).

**Relaciones:** vinculo:GV-44, vinculo:RC-GM-21, vinculo:SC-18, vinculo:GV-51

**PENDIENTE:** Costo no medido en un documento real grande: String.Len(.Text) arma el texto plano entero en cada salto. Si pesa, alternativa a medir: guardar el largo al cargar.

### GV-53 — ComboBox: asignar Index dispara Click aunque el índice no cambie

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, ComboBox.class (etiqueta 3.22.1) · **Verificado:** 2026-09

En `gb.qt5` el `ComboBox` es el de `gb.gui.base`, escrito en Gambas: el componente no trae uno propio en C++. `Index_Write` termina en `Raise Click` sin comparar con el valor anterior, así que asignar el índice que ya está elegido también dispara `Click`.

Es el efecto colateral que SC-06 neutraliza con `bAbriendoProyecto`, pero la bandera solo suprime el aviso de cambios sin guardar. Si el handler carga el archivo, reasignar el mismo `Index` lo recarga, y en un `TextEdit` eso reasigna `RichText` y vacía el historial de deshacer (GV-46).

REGLA: antes de asignar `Index` desde el código, compararlo con el actual. Si es el mismo, no se asigna.

CASO EN EL PROYECTO: el temporizador de archivos llama a `CargarListaArticulosMD(True)`, que vacía el combobox y repone la selección asignando `Index`. Eso recargaba el archivo abierto: preguntaba por cambios sin guardar y vaciaba el deshacer. Como ahí la asignación no se puede evitar, `cmbArticulosRevista_Click` sale sin hacer nada si la ruta elegida es la del archivo ya abierto, antes del aviso de SC-06.

**Relaciones:** vinculo:SC-06, vinculo:GV-46, vinculo:SC-18

**PENDIENTE:** Leído en el fuente, no medido en ejecución.

### GV-54 — TextEdit: lo que se escribe en un párrafo vacío sin color sale con el color por omisión

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-09

Cuando el documento se carga como HTML (SC-15), lo que se escribe hereda el formato del carácter vecino. En un párrafo vacío no hay vecino: si su `<p>` no declara color, lo tipeado sale con el color por omisión de Qt, que es negro. En un tema oscuro no se lee.

Síntoma en el proyecto: con Dracula, escribir en una línea vacía daba letra negra, que tomaba el color del tema recién al guardar.

LO QUE NO LO ARREGLA: asignar `Foreground` al control. Probado en banco: el texto siguió saliendo negro.

LO QUE LO ARREGLA: que el párrafo vacío lleve el mismo estilo que los demás, con el color del tema:

    <p style='-qt-paragraph-type:empty; margin:0; white-space:pre-wrap; color:#…'><br /></p>

Verificado en 3.19 y en 3.22.1. La ida y vuelta por `.Text` sigue siendo exacta.

**Relaciones:** vinculo:SC-15, vinculo:SC-18

### GV-55 — RadioButton: la exclusión mutua es por contenedor directo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble y Gambas 3.22.1 / gb.qt5 / Linux Mint · **Verificado:** 2026-09

Los `RadioButton` se excluyen entre sí solo con sus hermanos del mismo contenedor. Uno que esté en otro contenedor, aunque sea hijo del mismo padre, no se desmarca.

Medido en banco:

    dos RadioButton en el mismo HBox           marcar el segundo desmarca el primero
    en dos HBox hijos del mismo HBox           los dos quedan marcados
    dos en el mismo HBox hijo                  se excluyen

CONSECUENCIA: dos grupos de opciones independientes necesitan un contenedor cada uno. Aplicado en la pestaña «Estructura»: `hbProfundidad` y `hbAlcance`, uno debajo del otro (SC-18).

**Relaciones:** vinculo:SC-18
