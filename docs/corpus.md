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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-09

Las variables `Public` declaradas en un form NO sirven como canal de retorno si el form se cierra después de escribirlas. Al hacer `Me.Close()` la instancia se destruye y el valor se pierde. Cuando el llamador intenta leer la variable, Gambas instancia un form nuevo, con la variable en su valor inicial.

Para canal de retorno entre formularios usar siempre variables globales en un módulo (`m_FuncionesGenericas.X`, `m_Metadatos.X`, etc.).

Patrón canónico ya en uso: `m_FuncionesGenericas.sCreditSeleccionado` (FCreditRoles) y `m_FuncionesGenericas.iAutorSeleccionadoEnFAutores` (FAutores).

Síntoma del bug: el modal se cierra normalmente pero el llamador "no ve" el resultado.

CASO CON INSTANCIA EXPLÍCITA (verificado en 3.22.1, FMain:8438, y medido en banco 3.19)

Con `hForm = New FCandidatosBib` y `hForm.ShowModal()`, leer `hForm.Accion` después del cierre NO devuelve el valor inicial: da «Invalid object» (#29), porque la variable apunta a un objeto destruido (`Object.IsValid(hForm)` = False). Con la instancia automática (`FForm.Accion`) no hay error: se crea una instancia nueva, como describe esta regla.

ALTERNATIVA PARA UNA DECISIÓN SIMPLE

`ShowModal` devuelve el valor pasado a `Me.Close(valor)`, 0 si se cierra sin valor. La decisión vuelve así; los datos elegidos van a un módulo. Aplicado en FCandidatosBib: `iAccion = hCandidatos.ShowModal()` con las constantes `m_BuscarBib.ACCION_*`, y la fila elegida en `m_BuscarBib.RegistrarEleccion`.

**PENDIENTE:** FEstructuraResultados lee FAplicarCrossRef.bAplicado después de ShowModal con la instancia automática: por esta regla, siempre lee el valor inicial. Revisar.

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

### RC-GM-22 — El marcado que arma Gambas escapa cada valor de la base

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22 / gbpublisher · **Verificado:** 2026-10

Todo valor que viene de la base o de un formulario y entra a un XML, XHTML, HTML u OPF armado por concatenación en Gambas pasa por `m_XML.EscaparXML`. Sin eso, un «&» en el título de una revista o un «<» en un apellido dejan el archivo mal formado, y el fallo aparece lejos: en epubcheck, en el lector o en el navegador.

    ' MAL
    sXhtml &= "<p>" & sTituloRevista & "</p>"
    ' BIEN
    sXhtml &= "<p>" & m_XML.EscaparXML(sTituloRevista) & "</p>"

Vale también para los atributos (`alt`, `href`) y para los nombres de archivo que se usan como texto.

Si el valor lleva una marca que se traduce a marcado —el corte de título de SC-28—, el escape va sobre cada tramo y no sobre el texto entero: partir, escapar, unir.

Corregido en `m_GenerarEpub` (portada, sumario, índice de autores, `content.opf`, `nav.xhtml`, cabecera de los XHTML de Pandoc) y en `m_GenerarHTML.GenerarIndiceHtml`. `m_GenerarEpubLibro` y `m_XML` ya escapaban.

**Relaciones:** vinculo:SC-28

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

**Relaciones:** ,vinculo:SC-57

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

Para verso (SC-49): `<blockquote role="verso">` con un `<literallayout role="verse">` por estrofa y un `<phrase role="linea">` por verso, con dos espacios por nivel de sangría delante y el fin de verso como `&#10;` (GV-95). En un epígrafe, los `<literallayout>` van sueltos dentro de `<epigraph>`, que no admite `<blockquote>`.
Para conversación (entrevista, historia oral): `<qandaset>`, que sí está en la base (SC-43, GV-82). El viejo `<para role="speech">` con `<emphasis role="speaker">` se retiró: tomaba solo el primer párrafo de cada intervención.

**Relaciones:** vinculo:SC-43,vinculo:GV-82,vinculo:SC-49

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

### RC-DB-09 — info admite un solo title: los títulos alternativos van en bibliomisc con role

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** DocBook 5.2 / RNG del repositorio / xmllint · **Verificado:** 2026-10

En DocBook 5.2, `<info>` admite un solo `<title>`. Un segundo `<title role="...">` invalida el canónico contra el RNG; xmllint lo informa como «Extra element title in interleave».

DocBook 5.2 no tiene elemento propio para el título traducido de un capítulo ni para el título original de un libro traducido. Van en `<bibliomisc>` con `role` y su `xml:lang`:

    <bibliomisc role="titulo-traducido" xml:lang="en">...</bibliomisc>
    <bibliomisc role="titulo-original" xml:lang="en">...</bibliomisc>

Es el patrón del canónico para todo dato sin elemento propio (`tipo-capitulo`, `mes-publicacion`, `url-libro`). El dato queda en el XML, que sigue siendo autónomo (RC-XJ-02), y una derivación futura como BITS lo encuentra ahí.

Verificado contra `schemas/docbook/docbook.rng` del repositorio: con el segundo `<title>`, el capítulo y el libro no validan; con `<bibliomisc>`, validan. Ninguna hoja leía esos `<title role>`: las de HTML y EPUB ya filtraban `title[not(@role)]`.

Hasta la corrección, `m_XML` emitía el segundo `<title>` con un comentario que afirmaba lo contrario («DOCBOOK 5.2 PERMITE MÚLTIPLES <title> EN <info>»).

**Relaciones:** vinculo:RC-XJ-02,vinculo:SC-28

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** perl / -CSD / Gambas 3.22

DECISIÓN CERRADA: gbpublisher NO usa `gb.pcre` para expresiones regulares. El motor es perl invocado como proceso externo. Razones verificadas empíricamente:

- `gb.pcre` (PCRE2) tiene siete limitaciones duras para texto en castellano y para uso desde UI: offsets en BYTES y no en caracteres, sin constante UCP expuesta (`\w` `\b` `\d` rompen con acentos), `Exec` sin start-offset (obliga a truncar y rompe `\b` y lookbehind), match vacío que cuelga el proceso, sin timeout, sin grupos nombrados accesibles.
- Un match in-process no se puede cancelar (Gambas es single-thread en el loop de eventos); un proceso externo sí (`Process.Kill`).
- Hace falta el paquete `perl` completo, NO solo `perl-base`. `perl-base` es Essential, pero no trae `PerlIO` ni `Encode`, y el script abre los archivos con `:encoding(UTF-8)`, que los necesita (GV-90). En el `.deb`: `Depends: perl`, sin versión. `IntegridadSistema` verifica el paquete `perl`, no el binario, que también lo trae `perl-base`.
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

**Relaciones:** vinculo:GV-06, vinculo:GV-20, vinculo:GV-90,vinculo:SC-51

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

**Estado:** vigente · **Evidencia:** inferida · **Verificado:** 2026-10

Los recursos que la aplicación distribuye viven en dos lugares con roles distintos.

`/usr/share/gbpublisher/` es la fuente de verdad INMUTABLE. Se sobrescribe por completo en cada actualización del paquete. Nadie la edita: ni el usuario ni el departamento de sistemas.

`~/.gbpublisher/` es la copia efectiva de trabajo. Es la que la aplicación LEE, y la única que se ajusta. NO se sobrescribe nunca. Si una actualización cambia alguno de esos archivos, se avisa para que se borren y el arranque los vuelve a escribir desde el sistema.

La copia la realiza `m_InicioCierre.DirectorioOcultoApp()` recorriendo una lista de carpetas. Agregar una carpeta de recursos nueva OBLIGA a agregarla a esa lista; si no, la aplicación leerá del sistema y el recurso quedará fuera del modelo sin que nada lo advierta.

QUÉ NO SE COPIA

Lo que, modificado, invalidaría algo que la aplicación afirma. Hoy: `engine/`, el motor de expresiones regulares, y las reglas compiladas de Schematron. Un informe que dice "no cumple una recomendación de JATS4R" solo se sostiene si las reglas son las que vinieron en el paquete.

La ayuda contextual (`ayudas/`, SC-24) tampoco se copia, por otra razón: en ella no hay nada que ajustar, y como la copia local no se sobrescribe, cada actualización dejaría al usuario con la ayuda vieja.

El catálogo de shortcodes (`shortcodes/`, SC-34) tampoco se copia, por la misma razón.

CONTRAPARTIDA OBLIGATORIA

Todo recurso que sí se copia y que afecte lo que la aplicación afirma sobre un archivo ajeno debe poder DECLARAR si fue modificado. La comparación es directa contra `/usr/share/`, que por definición del modelo conserva siempre el original: no hace falta guardar ni versionar sumas de verificación. Es lo que hace `m_AuditarJats.EstadoRecurso()` con el catálogo de mensajes y la hoja de estilo del informe de auditoría.

COTEJO AL ARRANCAR

`m_InicioCierre.VerificarRecursosLocales`, después de `DirectorioOcultoApp`, compara cada archivo de `xslt`, `filters`, `latex`, `assets/css`, `assets/js`, `themes` y `ott` de la copia local con su par instalado. `ott` entra por el documento de referencia del ODT, que trae los estilos del epígrafe (SC-35); la comparación con `File.Load` sirve para un binario (GV-77). Si alguno difiere, lo lista y ofrece reemplazarlo: el actual se guarda en `~/.gbpublisher/respaldo/recursos-AAAAMMDD-HHMMSS/` y se copia el instalado. Un archivo que solo existe en la copia local no se mira: puede ser del usuario.

El caso que lo motivó: después de una actualización, una hoja nueva de la copia local corrió con un script viejo de `/usr/share/gbpublisher/engine/` y Saxon frenó por un parámetro que el script no pasaba. El caso inverso no da error: Saxon ignora un parámetro que la hoja vieja no declara, y la salida sale con la regla anterior.

Desde el IDE los recursos son los de `.hidden/`, y el cotejo avisa igual cuando el repositorio avanzó y la copia local quedó atrás.

Las personalizaciones de salida en uso se hacen con scripts que procesan lo que la aplicación entrega, no editando la copia local (decisión de Alberto): una copia local distinta de la instalada es, en la práctica, una copia vieja.

RAZÓN DEL MODELO

Divide según haya o no departamento de sistemas. Donde lo hay, los cambios se hacen sobre la copia local y se distribuyen a las estaciones; donde no lo hay, el usuario es a la vez administrador y necesita poder ajustar sin privilegios de root. En los dos casos el punto de intervención es el mismo, y la actualización del paquete nunca pisa lo ajustado.

**Relaciones:** vinculo:SC-05,vinculo:SC-24,vinculo:SC-34,vinculo:SC-35,vinculo:GV-77

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

ES LA DIRECCIÓN DEL CÓDIGO, NO SOLO UN CRITERIO PARA CADA CASO

Decisión de Alberto (2026-10). Lo que pueda ir a `engine/` va a `engine/`, preferentemente en bash; en Gambas queda solo lo que la relación entre costo, complejidad y seguridad justifique. Una función nueva no se escribe en Gambas si podría ser un script.

Queda en Gambas:

- Lo que lee o escribe la base. Los scripts no la tocan: antes del lanzamiento, Gambas escribe como archivo todo lo que el script necesita de ella (el info y la bibliografía de cada capítulo, el manifiesto del libro, la lista de un lote).
- Lo que toca la interfaz: el editor, las grillas, los diálogos y el guard de cambios sin guardar (SC-06).
- Lo que como script costaría más de lo que ahorra, o sería menos seguro. El encabezado de la función dice por qué se quedó.

Una función de Gambas que tipea en la terminal con `Input()` fuera de la lanzadora (SC-53) es deuda de migración: si la terminal está ocupada el comando se encola y corre fuera de contexto, Gambas no recibe código de salida, y la espera por la aparición de un archivo da por terminado lo que recién empezó a escribirse.

El primer caso migrado con este criterio: los canónicos de capítulo. `engine/generar_canonicos_capitulos.sh` reemplazó a `FMain.btnGenerarDocBookcanonico_Click` y a `m_XML.GenerarBodyCapituloXML`. El segundo, la salida PDF de libros: `compilar_pdf_libro.sh` pasó a la lanzadora y la preparación de los archivos LaTeX salió de Gambas a `preparar_latex_libro.sh` (SC-53).

INTÉRPRETES ADMITIDOS

`bash` y `perl-base`, que son Essential en Debian y Ubuntu. `python3` solo declarándolo como dependencia. `lua` NO: el paquete no existe con ese nombre y `lua5.4` no instala `/usr/bin/lua` (GV-08).

LO QUE NO SE VA DEL PROBLEMA

Mover la lógica fuera de Gambas no exime de RC-GM-02 ni de GV-23. En bash, un `&&` cuyo lado izquierdo es falso devuelve 1, y bajo `set -o pipefail`, si es el último comando de un grupo, contamina el estado de la tubería entera. En la sesión que originó esta regla, esa línea hizo que el informe declarara un rollback que no había ocurrido: la importación se había aplicado.

De ahí la regla operativa: UN INFORME NO AFIRMA LO QUE NO VERIFICÓ. Si va a decir que la base quedó como estaba, que lo consulte antes de decirlo.

BASE COMPARTIDA

Si el proceso externo escribe en la misma base que la aplicación tiene abierta, la conexión se cierra antes de lanzarlo y se reabre después por un ÚNICO camino explícito, invocado tanto en el éxito como en el fallo. `Finally` no sirve para esto (RC-GM-20).

**Relaciones:** vinculo:SC-05, vinculo:SC-11, vinculo:GV-17, vinculo:GV-20, apoya:GV-23, vinculo:GV-42,vinculo:SC-53

**PENDIENTE:** Inventario de las funciones que todavía tipean en la terminal con Input() fuera de la lanzadora, para ordenar la migración. Por grep, al 2026-10: FMain, las salidas de revista (m_GenerarEpub, m_GenerarSCIELO, m_GenerarDOAJ, m_GenerarHTML, m_GenerarODT, m_GenerarCROSSREF, m_GenerarPDF), m_XML, m_GitHub, m_OrdenTaller, m_FuncionesGenericas, m_InicioCierre. La salida PDF de libros ya no tiene nada fuera de la lanzadora.

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

**Relaciones:** vinculo:RF-09, vinculo:RC-BL-01, vinculo:RC-BL-02, vinculo:SC-12,vinculo:SC-56,vinculo:RF-12,vinculo:SC-57,vinculo:RF-13,vinculo:RF-14

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

**Estado:** deprecada · **Evidencia:** empirica · **Entorno:** gbCorpus / engine/importar_corpus.sh / SQLite · **Verificado:** 2026-09

DEPRECADA. Reemplazada por SC-50, que extiende el contrato a todas las aplicaciones satélite (gbCorpus, gbShortcodes y gbAyudas) y reúne lo que estaba repartido en esta entrada, RF-08, RF-11 y SC-24.

Texto histórico:

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

El `corpus.md` adjunto al proyecto de trabajo con Claude se coteja con `docs/corpus.md` del repositorio de gbpublisher, clonado con `git clone --depth 1`: mismas entradas, mismos estados y pasajes testigo idénticos. Si difieren y el del repositorio es el más reciente, se adopta sin consultar: pasa a ser la copia de trabajo, y se dice en una línea que se actualizó. Si el más reciente es el adjunto al proyecto —caso raro, porque el repositorio recibe cada exportación—, se avisa antes de hacer nada y se espera la respuesta. Más reciente es el que tiene entradas, estados o textos que el otro no tiene; si cada uno tiene algo que el otro no, o no se puede decidir, también se avisa antes de hacer nada. Es lo que garantiza que un código nuevo esté libre y que un texto a reemplazar exista tal como se lo cita.

**Relaciones:** reemplazada_por:SC-50,vinculo:RF-08, vinculo:SC-13

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

Un formulario sin botón de cerrar necesita una salida propia en la interfaz: un botón, la tecla Escape, o las dos. Excepción consciente: `FMetadatosCapitulos` deshabilita su botón mientras el orden del libro esté roto (SC-55).

**Relaciones:** vinculo:GV-50, vinculo:GV-11,vinculo:SC-55

**PENDIENTE:** WAYLAND: sin verificar, ver GV-50. Tampoco está verificada la variante FijarBotones(Me, True), que conserva el botón de cerrar.

### SC-21 — Snippets del editor: un archivo por snippet en ~/.gbpublisher/snippets/

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

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

VERIFICADO EN USO (Gambas 3.22.1 / Linux Mint, 2026-09)

- Ctrl+Tab llega al `KeyPress` del `TextEdit`: `Key.Control` en True y `Key.Code = Key.Tab` (16777217, el código de Tab en Qt). Apretar Ctrl solo ya dispara un `KeyPress` propio, con código 16777249: el handler tiene que filtrar por las dos condiciones.
- `Stop Event` alcanza: el Tab no se inserta en el texto ni mueve el foco. El handler lo aplica siempre, se expanda o no, y devuelve el foco al editor al final (RC-GM-07).
- Un snippet de bloque escrito a mitad de línea no se expande y muestra el mensaje; escrito solo en su línea, se expande con sus saltos de línea.

DOS PROTECCIONES DE Expandir

- Antes de escribir, comprueba que el texto en la posición calculada (`Pos` menos 3) sea la abreviatura. La columna sale de `Index` y la posición de `Pos`: si alguna vez no coincidieran, se reemplazaría otro tramo.
- Si `ReemplazarTramo` rechaza el tramo, devuelve False sin avisar; `Expandir` avisa por su cuenta, para que no sea un canal mudo (GV-23).

LÍMITE ACEPTADO

`m_FuncionesGenericas.EsLetra` reconoce ASCII, Latin-1, Latin Extended A y B y los diacríticos combinantes (GV-03). Una letra griega o cirílica pegada delante de la abreviatura no la frena.

**Relaciones:** vinculo:SC-17, vinculo:SC-11, vinculo:SC-18, vinculo:SC-02, vinculo:RC-GM-07, vinculo:RC-GM-12, vinculo:SC-20, vinculo:GV-39

**PENDIENTE:** Queda por medir con un snippet de bloque: (1) cuántos Ctrl+Z deshacen una expansión (Select + Insert); (2) que el texto vuelva idéntico por .Text después de expandir (la separación en líneas se vio bien a simple vista); (3) si las líneas vacías del cuerpo salen con el color por omisión hasta el guardado en un tema oscuro (GV-54).

### SC-22 — Cambio de esquema de la base de gbpublisher: un script por versión y el lote completo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / bash / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. Todo cambio de estructura de la base de gbpublisher sobre una instalación en uso se aplica con un script `actualizar-esquema-X.Y.Z.sh`, con las reglas de `BBDD_LEEME.md` §5. Cadena: 1.1.0 (bibtex: trazabilidad y FULLTEXT), 1.2.0 (licencias), 1.3.0 (idiomas), 1.4.0 (primeras del libro, SC-25), 1.5.0 (leyenda de autoría, SC-25), 1.6.0 (autoría en la apertura de capítulo, SC-26), 1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (valores de los formatos de sistema Estudio 2A); 1.9.0 (`libros_md.estilo_cita` al identificador del estilo biblatex); 1.10.0 (notas internas, SC-60); 1.11.0 (tipos de pieza `indice_concepto` e `indice_autores`); 1.12.0 (retiro de la tabla `postits`, SC-60). El refactor de bibtex tomará el número que le corresponda.

QUÉ HACE CADA SCRIPT

- Exige la versión anterior en `esquema_version`.
- Decide por el estado REAL del esquema (information_schema), no por las filas de `esquema_version`: es idempotente, y una corrida interrumpida se retoma aplicando solo lo que falta.
- Respaldo con `mysqldump` verificado antes de tocar nada: archivo no vacío, marca final y presencia de una tabla testigo.
- Verificación posterior y registro en `esquema_version` solo si pasa.
- Informe de control SOLO DE LECTURA al final: lista los datos existentes que no cumplen lo nuevo. No los corrige.
- Usa la cuenta administrativa (`sudo mysql`): el usuario de la aplicación no puede modificar estructuras.

EL LOTE COMPLETO: EN LA MISMA ENTREGA QUE EL SCRIPT

1. El conteo de columnas de `hEsquema` en `m_ConexionBD`, y la tabla nueva si la hay. Sin eso la validación de arranque rechaza la base.
2. Los `Columns.Count` fijos de las grillas que cargan esa tabla (GV-58).
3. Las exportaciones e importaciones que recorren todas las columnas (en 1.1.0: `ExportarBibTeX`, `ExportarBibTeX2JSON`, `ImportarJSON`): una columna de control o de trazabilidad se excluye explícitamente.
4. Las columnas nuevas van AL FINAL de la tabla: hay código que lee por posición.
5. Una tabla que se retira sale de `hEsquema` en la misma entrega, y el script se aplica DESPUÉS de instalar la aplicación nueva. `ValidarEsquemaBD` ignora una tabla que sobra y rechaza una esperada que falta: la versión anterior no arranca sin la tabla. El script lo advierte al empezar.

DETALLES VERIFICADOS

- Un `ALTER TABLE … MODIFY` se arma desde information_schema con colación, NULL, DEFAULT y COMMENT de la columna: un MODIFY sin COMMENT lo borra.
- Esas sentencias se leen con `mysql -N -B -r`: sin `-r`, el modo batch duplica las barras que `QUOTE()` pone en un comentario con apóstrofo y el ALTER sale mal formado.
- En los informes con CTE, los `CAST(… AS CHAR)` llevan `COLLATE` explícito: sin él toman la colación de la conexión y el `UNION` falla por mezcla de colaciones.
- Una columna `DATETIME` nueva que no debe fechar las filas existentes se agrega en dos pasos: primero NULL, después el DEFAULT.
- El respaldo de `mysqldump` se restaura con `--init-command="SET SESSION innodb_strict_mode=0"`: sin eso, la restauración borra `articulos` y falla al recrearla (GV-67).

PUNTO DE RUPTURA: BASELINE 2.0.0 CON EL REFACTOR DE BIBTEX

Decisión de Alberto (20/10). El baseline no se regenera con cada versión de la cadena. El 2.0.0 se genera junto con el refactor de bibtex y lo incorpora: las instalaciones nuevas parten de ahí. Las existentes siguen su cadena hasta ese mismo punto. Hasta entonces, una instalación nueva restaura `baseline-1.0.0` y corre la cadena completa (BBDD_LEEME.md §5, «Cuándo conviene rebasear»).

**Relaciones:** vinculo:GV-58,vinculo:GV-63,vinculo:RC-GM-04,vinculo:GV-67,vinculo:SC-26,vinculo:SC-34,vinculo:SC-60

### SC-23 — Vocabularios de metadatos: el catálogo en la base alimenta el formulario, el registro guarda su valor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / babel 24.1 / Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. Los vocabularios que vivían repetidos en el código de los formularios de metadatos (artículos, capítulos, libros, revistas) pasan a tablas de la base. El catálogo ALIMENTA los formularios; cada registro sigue guardando su propio valor. Lo publicado queda como se publicó aunque el catálogo cambie después: es la reproducibilidad del proyecto.

LICENCIAS (actualización 1.2.0)

Tabla `licencias`: etiqueta, url, spdx, abierta, para_contenido, para_codigo, orden, activo. Dos booleanas de ámbito en lugar de una columna: MIT, GPL v3, Apache 2.0 y CC0 valen para contenido y para código. `spdx` en NULL para GPL, LGPL y AGPL: la etiqueta no dice si es «only» u «or-later». Sin fila «Otra»: los combos de licencia son editables.

`m_Licencias`: `LlenarCombo`, `CompletarUrl` (una etiqueta fuera del catálogo no toca la URL) y `EsAbierta`, que busca POR URL y no por nombre. El `license-type="open-access"` de JATS depende de `EsAbierta`: una URL vacía o desconocida no se declara abierta.

IDIOMAS (actualización 1.3.0)

Tabla `idiomas`: codigo (BCP 47), nombre, nombre_ingles, babel, nivel, activo, orden. Se GENERA desde los `babel-*.ini` de la instalación de TeX Live con `generar-idiomas-babel.sh`: la tabla coincide con el babel que compone y ningún dato se escribe de memoria. Columnas de idioma a VARCHAR(20).

`m_Idiomas` es el único punto de conversión: `Babel` (código a nombre de babel), `Normalizar` (código o nombre a código; si no lo reconoce devuelve vacío y NUNCA inventa «es»), `LlenarCombo`, `ListaValida` e `IdiomaAsignado`.

REGLAS DE INTERFAZ

- Vocabulario cerrado de un solo valor: ComboBox de solo lectura, con el código. Lo usan correctores que manejan códigos.
- Varios valores (idiomas de publicación): códigos separados por coma, validados al guardar. `;` se rechaza.
- Par texto + idioma (título traducido, resúmenes, palabras clave): si el texto está cargado, su idioma es obligatorio.
- El idioma principal de libro y de artículo es obligatorio.

REGLAS OPERATIVAS

- No desactivar un valor en uso: el combo de solo lectura lo pierde al abrir el formulario (GV-59).
- Cada migración de vocabulario trae un informe de control de los datos existentes, que se corrige ANTES de abrir los formularios.

**Relaciones:** vinculo:GV-59,vinculo:SC-22,vinculo:RC-XJ-01

### SC-24 — Ayuda contextual: un HTML por ayuda en /usr/share/gbpublisher/ayudas/, producido fuera de la aplicación

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. La ayuda contextual deja la base de datos (`manual_ayudas`) y pasa a archivos HTML que se distribuyen con el paquete. Solo en español. Lo que excede la ayuda de un campo va al manual.

QUÉ ES UNA AYUDA

Describe un DATO, no un widget. Tiene siempre tres secciones, en este orden: qué es, para qué sirve y cómo se usa en las salidas. Sin imágenes y sin enlaces entre ayudas.

PRODUCCIÓN: gbAyudas, FUERA DE gbpublisher

Las ayudas se escriben en gbAyudas, una aplicación satélite que sigue el modelo de SC-50. Es la excepción a su alcance: da de alta y de baja, porque es el editor de las ayudas. Cada ayuda guarda su clave, un título legible en texto plano, las tres secciones en campos separados y su estado.

Las secciones se escriben en Markdown. Pueden escribirlas otras personas; se revisan y se pegan en gbAyudas.

La clave admite solo minúsculas, dígitos, `_` y un único `.` (el de `tabla.columna`). gbAyudas rechaza cualquier otra. Así ningún nombre de clave choca con los archivos de servicio, que empiezan con `_`.

CONVERSIÓN: PANDOC CON PLANTILLA Y FILTRO PROPIOS

gbAyudas arma un Markdown por ayuda —los tres títulos de sección fijos y el texto de cada campo— y lo convierte en una sola llamada:

    pandoc -s --template=plantilla.html --lua-filter=ayuda.lua ...

- La plantilla es una plantilla de Pandoc: un HTML completo con el `<style>` de la ayuda y el título en `<title>`. Se usa una propia porque la de Pandoc agrega CSS de navegador que el `TextEdit` no necesita.
- El filtro `ayuda.lua` detiene la conversión, con un mensaje, si encuentra un título, una imagen, una nota o HTML crudo. Quedan admitidos párrafos, negrita, cursiva, código y listas, que son lo verificado en GV-64. Las tablas quedan fuera del texto hasta probarlas.
- La llamada es `Exec` sobre un array, sin shell (SC-05). La entrada va por archivo temporal y la salida se lee de stdout (GV-20).
- Plantilla y filtro son archivos de la carpeta de gbAyudas, editables con cualquier editor, no filas de la base.

ESTADO: BORRADOR O REVISADA

Se exportan todas las ayudas, en cualquier estado. Cada página muestra el suyo en una franja de color con letras blancas, como el «Final» / «Beta» de la ayuda de componentes del IDE de Gambas. Las plantillas de Pandoc no comparan valores, así que el estado llega como dos variables:

    -V estado=Borrador -V estado_clase=borrador

La franja es una tabla de una celda a todo el ancho con la clase del estado; su color está en el `<style>`. De las variantes probadas es la que mejor proporciona la letra con la altura (GV-64).

    <table width="100%" cellpadding="4" cellspacing="0">
    <tr><td class="$estado_clase$">$estado$</td></tr>
    </table>

CONDICIÓN PARA EXPORTAR

Las tres secciones tienen que tener texto. Puede ser provisorio —«En desarrollo» o lo que se decida—, pero ninguna vacía. El estado dice en qué punto está la ayuda; esta condición asegura que ninguna página se publique con un hueco.

EXPORTACIÓN

Escribe en `.hidden/ayudas/` del proyecto gbpublisher:

- `<clave>.html`, una página por ayuda;
- `_indice.tsv`, una línea por ayuda: clave, tabulador, título; ordenado por título. Se regenera completo en cada exportación, también en la parcial, así que no puede quedar desfasado de los HTML;
- `_sin-ayuda.html`, la página genérica, hecha con la misma plantilla.

Por omisión exporta solo lo modificado desde la última exportación. Hay además una exportación completa, obligatoria cuando la plantilla cambió después de la última completa. Deja la carpeta igual a la base: un HTML sin registro se borra o se informa, porque todo lo que está en `.hidden/ayudas/` entra al paquete.

DISTRIBUCIÓN

El paso 8 de la construcción del `.deb` incluye `.hidden/ayudas/`, que se instala en `/usr/share/gbpublisher/ayudas/`.

La carpeta NO entra en la lista de `m_InicioCierre.DirectorioOcultoApp()`: la aplicación la lee directamente del sistema. Es una excepción a SC-11, con una razón distinta de la de `engine/`: en la ayuda no hay nada que ajustar, y como la copia local nunca se sobrescribe, cada actualización dejaría al usuario con la ayuda vieja. Que falte en esa lista es deliberado, no un olvido.

CLAVE: EL Tag DEL CONTROL

El control que tiene ayuda lleva la clave en `Tag`: el nombre de la columna (`arxiv_id`) o, cuando la misma columna existe en varias tablas y sus salidas difieren, `tabla.columna` (`autores.clasificacion_oecd`). Se busca el archivo de la clave del `Tag`; si es `tabla.columna` y no existe, el de la columna sola.

No se usa el nombre del control. Con los prefijos de widget de la convención de nomenclatura nunca coincide con la columna, y tampoco dice a qué tabla pertenece. Así era antes: `MostrarAyuda` buscaba `Application.ActiveControl.Name` tal cual, y solo encontraban ayuda los controles llamados igual que su columna; la de `clasificacion_oecd` era inalcanzable. Al tomar esta decisión, el `Tag` de los controles de datos no tenía otro uso.

CONTROL DE COBERTURA

gbAyudas lee los `.form` del proyecto, donde el `Tag` está como texto (`Tag = "…"`), y lista los `Tag` sin HTML y los HTML que ningún `Tag` usa.

VISOR

Un solo formulario, `FAyuda`, con el modelo de la ayuda del IDE de Gambas: a la izquierda la lista de todas las ayudas, leída de `_indice.tsv`; a la derecha la elegida. Ctrl+F1 lo abre con la ayuda del control activo seleccionada; desde el menú, sin selección. Sin navegación dentro del texto.

Si el control no tiene ayuda —no tiene `Tag`, o su `Tag` no tiene HTML—, Ctrl+F1 abre `FAyuda` igual y muestra `_sin-ayuda.html`, que dice que ese control todavía no tiene ayuda. La página lleva un marcador que `FAyuda` reemplaza por el `Tag` o, si no hay, por el nombre del control.

La ayuda se muestra en un `TextEdit` con `ReadOnly` y `Wrap = True`, cargada por `RichText` (GV-64).

LO QUE SE RETIRA

`FAyudas`, `FAyudaABM`, `m_EstilosHTML` (solo lo usaban las ayudas), los seis idiomas con su detección, y la tabla `manual_ayudas`. La tabla se elimina con una actualización de esquema (SC-22), recién cuando la ayuda nueva funcione.

**Relaciones:** vinculo:SC-11,vinculo:GV-64,vinculo:SC-22,vinculo:GV-56,vinculo:SC-05,vinculo:GV-20,vinculo:SC-50

**PENDIENTE:** Sin decidir: (1) lista plana o árbol por tabla; (2) el filtro de la lista, solo por título o también por contenido; (3) prefijo de widget para TextEdit, que la convención no tiene; (4) esquema de la base de gbAyudas y su ubicación: irá en una RF, como RF-08 para gbCorpus. Aparte: pasar FAvisoLegal y FDiccionario a TextEdit y retirar HtmlView del proyecto (FDiccionario, probado antes con una respuesta real de la RAE); renombrar los cinco controles que hoy se llaman como su columna (arxiv_id, book_author, handle_system, sponsors, tipo_sujetos_investigacion), cotejando antes sus usos (GV-56).

### SC-25 — Primeras del libro: piezas sin cuerpo, datos de la base y textos en Markdown

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1 / LuaLaTeX / poppler 24.02 / EPUB 3.3 · **Verificado:** 2026-09

DECISIÓN CERRADA. Las primeras del libro —portadilla, portada y créditos— son PIEZAS SIN CUERPO, igual que el colofón: una fila en `capitulos` con su `nombre_archivo` en el espacio reservado `fm-00` a `fm-09`, sin .md ni canónico. El nombre da la posición; cada salida la resuelve según la matriz de `m_PiezasLibro`.

POR QUÉ NO LaTeX EN EL .md

Pandoc descarta el LaTeX crudo al escribir DocBook: un bloque crudo `{=latex}` no llega al canónico (verificado). Y aunque llegara, la página de créditos cambia con el formato —el EPUB tiene otro ISBN y otra ficha, y no lleva tirada ni imprenta—, y los datos que repite (título, autoría, ISBN) ya están en la base.

POR QUÉ NO SHORTCODE

Un shortcode vive dentro de un .md, y estas piezas no lo tienen: la fila en la base ya fija la posición. `TRATAMIENTO_SHORTCODE` se reservó para la autoría en la apertura de capítulo y después se retiró: esa autoría también sale de la base (SC-26).

TIPOS

`portadilla`, `portada` y `creditos` en `tipo_capitulo`. Orden estándar: cortesía (i–ii), portadilla (iii), blanca (iv), portada (v), créditos (vi).

MATRIZ

    pieza        PDF                          EPUB              HTML
    portadilla   \gbPortadilla (impar)        omitida           omitida
    portada      \gbPortada (impar)           titlepage         omitida
    creditos     \gbCreditos (par)            copyright-page    omitida

- Las blancas las ponen `\gbclearrecto` y `\gbclearverso`; nunca `\newpage\hbox{}` a mano.
- Macros nuevas: el contrato sube a la versión 2. El aspecto va en la estética.
- El sumario se emite DESPUÉS de la última pieza del espacio reservado `fm-00` a `fm-09`: las primeras y las piezas sueltas, como la dedicatoria (SC-45). Antes de esta regla `AbrirZona(ZONA_FRONT)` lo escribía al abrir la zona, y una primera declarada quedaba detrás de él.
- EPUB: la tapa (`cover`) va siempre, en `front-tapa.xhtml`; hasta SC-25 era `front-portada.xhtml`. La portada (`titlepage`, `front-portada.xhtml`) va solo si el libro la declara, con autoría, leyenda, título, subtítulo y logo de portada. Los créditos (`copyright-page`) van siempre: con logo de colección y textos digitales si el libro declara la pieza y tiene al menos uno de los dos textos; si no, el bloque genérico (`ArmarCreditos`), el mismo criterio que el colofón no declarado.
- EPUB sin versalitas: los nombres van en mayúsculas y minúsculas, como están en la base. Noto Serif las tiene, pero los lectores de EPUB no las respetan de forma pareja. Excepción: la bibliografía con Verona lleva versalitas por CSS sobre el texto con su caja original, que degrada a mayúsculas y minúsculas si el lector no las respeta (SC-56).
- `titlepage`, `copyright-page` y `halftitlepage` están definidos en EPUB 3 Structural Semantics Vocabulary.

DATOS EN libros_md

- `texto_catalogacion` y `texto_legal`: impreso.
- `texto_catalogacion_digital` y `texto_legal_digital`: EPUB. Si están vacíos va el bloque genérico; NUNCA se recurre al texto impreso, que trae tirada e imprenta.
- `logo_portada` y `logo_coleccion`: nombre normalizado en `media/` (`logo-portada.EXT`, `logo-coleccion.EXT`), con el mismo mecanismo que la tapa (`btnBuscarTapa_Click`). El nombre de la colección y el del director son parte de la imagen.
- `numero_paginas`, ya existente: se carga a mano. No se usa `\ztotpages`.
- `url_libro`, ya existente: va como texto. Sin QR.
- `leyenda_autoria` (1.5.0): la línea debajo de los nombres en la portada, tal como debe salir («coordinadores», «compiladora»). La escribe el editor: el género y el número no se deducen de la base (`autores.genero` es texto libre y ningún código lo usa). Vacía, no hay línea.

AUTORÍA

En la portada, cada nombre va dentro de `\gbNombrePortada` —la estética decide versalitas o mayúsculas— y se unen con comas e «y» o «e» en letra normal (SC-26); debajo, `\gbleyendaautoria`. `\gbNombrePortada` es vocabulario que emite el generador: contrato versión 3.

En la ficha, `{autoria}` une los nombres igual y agrega el rol abreviado una sola vez: «Adrián Cammarota y Astrid Dahhur (coords.)». La abreviatura no tiene género; su plural agrega una s antes del punto. Si los roles difieren entre sí, cada nombre lleva el suyo.

MARCADO DE LOS TEXTOS

Markdown de línea, convertido con `pandoc -f markdown+hard_line_breaks` a `latex` para el PDF y a `html` para el EPUB. Verificado: `^a^` da `\textsuperscript{a}` y `<sup>`; `*x*`, `\emph` y `<em>`; cada salto de línea, `\\` y `<br />`. Nunca LaTeX en la base: el EPUB no lo puede usar. La llamada es `Exec` sobre un array (SC-05).

MARCADORES

Gambas los reemplaza ANTES de Pandoc: así Pandoc escapa los caracteres especiales de LaTeX que traiga el valor.

    {autoria} {titulo} {subtitulo} {edicion} {ciudad} {anio} {editorial}
    {coleccion} {director_coleccion} {isbn_impreso} {isbn_digital}
    {url_libro} {paginas} {formato}

- Un marcador desconocido detiene la generación y se lo nombra (GV-23).
- Un valor vacío sale como `??`, igual que una referencia no resuelta. Es el caso de `{paginas}` en la primera compilación.
- `{paginas}` y `{formato}` solo valen en los textos del impreso; en un texto digital detienen la generación.
- No hay `{isbn}` a secas: ningún texto depende de adivinar en qué salida está.
- `{url_libro}` se reemplaza como autoenlace `<url>`: Pandoc da `\url{}`, que corta la línea en las barras, y `<a href>` en el EPUB. Una URL desnuda sale como texto común y no se corta (verificado).

PLANTILLAS

Cada campo de texto tiene un botón que abre `FPlantillaCreditos` con la plantilla de la editorial: un archivo por campo en `~/.gbpublisher/plantillas/<campo>.md`, contenido del usuario como los snippets (SC-21) y fuera de la copia de SC-11. Si no hay, se muestra la base de gbpublisher, que no trae datos de ningún sello. Aplicar copia al campo y pregunta si ya tiene texto; los reemplazos de cada libro se hacen después, con el editor ampliado.

CANTIDAD DE PÁGINAS

Después de compilar, la aplicación lee las páginas del PDF con `pdfinfo` y AVISA si difieren de `numero_paginas`. No escribe: el número lo carga el editor. Cuenta páginas físicas, cortesía incluida.

LOGOS

Solo PNG o JPG: el mismo archivo sirve al PDF y al EPUB, sin conversión. Un logo en PDF obligaba a generar un SVG para el EPUB, que no admite PDF como imagen; se descartó. Centrados a ancho fijo, definido en `preambulo-estetica.tex`: el de portada (logo de la editorial) a 20 mm (`\gbAnchoLogoPortada`) y el de colección a 110 mm (`\gbAnchoLogoColeccion`), nunca más anchos que la caja (`\gbLogo`). El logo de colección se diseña sobre un lienzo de 110 mm de ancho: el blanco a los costados iguala las colecciones cuyo nombre o dirección ocupan distinto ancho. La resolución del archivo no interviene, así que GV-66 no afecta a los logos y el diálogo no la controla; solo tiene que alcanzar en píxeles (a 300 ppp, unos 240 px para 20 mm y 1300 px para 110 mm). En el EPUB, la misma proporción sobre el ancho de pantalla: 18 % y 100 % (`gbpublisher-epub-libro.css`). El PDF y el EPUB frenan con un mensaje si el logo cargado no es PNG o JPG o no está en `media/`. `pdfinfo` (poppler-utils) entra en `integridad.sh`.

Del resto de `media/`, el EPUB toma solo las imágenes que admite —jpg, jpeg, png, gif, svg y webp—, con la misma lista en `m_GenerarEpubLibro.EsImagenEpub` y en `engine/generar_epub_libro.sh`. Antes copiaba todo y declaraba lo desconocido como `image/jpeg`: un PDF en `media/` dejaba el paquete inválido.

ESQUEMA

Por un script de actualización (SC-22). El `enum` de `tipo_capitulo` se reescribe partiendo del REAL, leído en information_schema: el baseline no tiene `indice_concepto` ni `indice_autores`, que el código usa, y `MODIFY` reemplaza la lista entera. Los handlers nuevos de logo declaran sus variables al principio (RC-GM-18), a diferencia de `btnBuscarTapa_Click`.

**Relaciones:** vinculo:SC-22,vinculo:GV-66,vinculo:SC-05,apoya:GV-23,vinculo:RC-GM-18,vinculo:SC-21,vinculo:GV-68,vinculo:SC-26,vinculo:SC-45,vinculo:SC-56

**PENDIENTE:** PDF implementado y probado con un libro real. EPUB implementado: las páginas generadas por el código real pasan epubcheck en el contenedor; falta probarlo con un libro real y verlo en un lector. Esquema: actualizar-esquema-1.4.0.sh y 1.5.0.sh.

### SC-26 — Autoría en la apertura de la pieza: solo en libros colectivos, desde la base

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.19 (gbc3, gbs3) / LuaLaTeX / Saxon-HE 12.5 / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-09

DECISIÓN CERRADA. En un libro colectivo, debajo del título de cada pieza van sus autores, y también en el sumario. En un libro de autor no van, porque la autoría ya está en el folio de todas las páginas, salvo en la pieza que firma otra persona: un prólogo ajeno.

COLECTIVO O DE AUTOR

Lo decide `libros_md.tipo_libro`, con una sola lista: `m_GenerarPDFLibro.EsLibroColectivo` (obra_colectiva, compilacion, actas, referencia). De la misma lista depende `RolesDeAutoriaSegunTipo`, que fija quién firma el libro en la portada, la ficha y el OPF.

En un libro de autor, una pieza muestra sus autores si los tiene en `capitulo_autor` y no son exactamente los del libro (`libro_autor`, rol «autor»): se comparan los conjuntos de id (`EsDeOtraAutoria`). Una pieza del autor del libro no los muestra aunque tenga su fila; una pieza de uno solo de dos coautores, sí.

DE DÓNDE SALEN LOS NOMBRES

De la base, como el folio, y no de un shortcode en el .md:

- `capitulos.autoria_apertura` (actualización 1.6.0): la forma de cada nombre tal como debe salir, en orden y separadas por punto y coma: `A. Moyano; J. Sotelo` o `Moyano; Sotelo; Campanaro`. La escribe el editor cuando los nombres completos no entran, y elige la forma en cada capítulo.
- Vacío: los nombres completos, «Nombre Apellido», de `capitulo_autor` con rol «autor», en `orden_autoria`.

Es solo presentación. El folio, el EPUB, el HTML y los metadatos (DocBook, OPF, Crossref) siguen saliendo de `autores`, que es lo que controla la autoridad.

El punto y coma no es estética: le dice al generador dónde termina cada nombre, para que ponga las comas y la conjunción y las deje FUERA de las versalitas. Por eso no se guarda la línea terminada.

PDF (CONTRATO 4)

- El generador emite `\gbAperturaPieza{LÍNEA}` antes de cada `\include`, aunque vacía. La línea ya trae cada nombre en `\gbNombreApertura{}` y las comas y la conjunción en letra normal.
- `\gbComponerApertura` la compone con `\gbDisenoApertura` y la vacía. La estética lo llama en el after-code de `\titleformat{\chapter}`, que corre también con `\chapter*`: la Introducción de un libro colectivo lleva sus autores.
- Se vacía al usarla porque la bibliografía de biblatex y los índices también abren con `\chapter*` sin pasar por el generador: sin eso repetirían los autores de la pieza anterior.
- Estética: `\gbNombreApertura` es `{\scshape\MakeLowercase{#1}}`, como `\nombreautor` del legacy; `\gbDisenoApertura` deja 30 pt, centra la línea en cuerpo normal, y los 30 pt de `\titlespacing` quedan entre los nombres y el texto.

SUMARIO (CONTRATO 5)

La entrada de cada pieza que muestra autores (ver arriba) lleva arriba sus autores, en negrita, y debajo el título, como en el legacy. El sumario lleva partes y piezas, sin secciones: `tocdepth` en 0, en la estética.

- Siempre los nombres completos de `capitulo_autor`, nunca la forma declarada en `autoria_apertura`: el sumario tiene lugar para dos líneas (decisión de Alberto). `m_GenerarPDFLibro.NombresCompletosPieza` los da a la apertura y al sumario.
- El generador emite `\gbIndicePieza{LÍNEA}` antes de cada `\include`, aunque vacía.
- El contrato envuelve `\addcontentsline` en `\AtBeginDocument`, para tomar la versión de hyperref: cuando la entrada es `toc/chapter`, escribe antes `\gbAutoresIndice{LÍNEA}` en el .toc y vacía la línea. Así el dato queda delante de la entrada, tanto con `\chapter` como con `\chapter*` más `\addcontentsline`, y la bibliografía y los índices no se quedan con autores ajenos.
- La estética lo compone en `\titlecontents{chapter}` con `\gbComponerAutoresIndice` y `\gbDisenoAutoresIndice`. El número queda a la altura de los autores. Una pieza sin número no retrocede: va a 1.5pc, alineada con los títulos y los autores de las numeradas, tenga o no autores.
- Los marcadores del PDF siguen llevando solo el título.

EPUB Y HTML

Nombres completos debajo del título, desde el canónico. No usan `autoria_apertura`: la pantalla no tiene el problema del ancho. Antes unían con comas y sin «y» («Duek, Moguillansky»); ahora con la plantilla `separador-autoria` de `docbook-to-epub.xsl` y `docbook-to-html.xsl`.

«y» O «e»

Regla de la RAE (DPD, «y»): «e» ante palabra que empieza por i- o hi- con sonido de vocal («Pérez e Ibáñez», «Ana e Hilda», «Ana e Íñigo»); «y» si esa i, sin tilde, forma diptongo con la vocal siguiente («Ana y Iolanda», «agua y hielo»). La palabra que decide es la que sigue a la conjunción: el nombre de pila o la forma declarada.

Una sola regla en tres lugares: `m_PrimerasLibro.Conjuncion` (portada, ficha y apertura del PDF, portada del EPUB) y la plantilla `separador-autoria` de las dos hojas XSLT. `Conjuncion` compara mayúsculas y minúsculas por separado y no usa `String.LCase`, que bajo locale C/POSIX no pasa «Í» a «í» (GV-03).

LO QUE SE RETIRA

`TRATAMIENTO_SHORTCODE` (el 4 de `m_PiezasLibro`): estaba reservado para esta autoría. El número no se reusa.

**Relaciones:** vinculo:SC-25,vinculo:SC-22,vinculo:GV-03

**PENDIENTE:** Apertura, conjunción y sumario probados por Alberto con libros reales. Pieza de otra autoría en un libro de autor, tocdepth 0 y sangría de las piezas sin número: probados en el contenedor; falta probarlos con un libro real.

### SC-27 — Refresco en caliente de un combo que lista archivos: sondeo por firma sin recargar lo abierto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 / Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA. Un combo que lista los archivos de una carpeta del proyecto se mantiene al día con un `Timer` que sondea la carpeta. Aplicado en `cmbVerPDF` (`m_RevisarPDF`, `hTimerRefrescarPDF`) y en `cmbImagenes` (`m_GestionImagenes`, `hTimerRefrescarMedia`).

POR QUÉ SONDEO

Varias salidas se generan escribiendo comandos en `TerminalViewProyecto` (`m_GenerarPDF`, `m_XML`, `m_OrdenTaller`): Gambas no se entera de cuándo terminan, así que no hay evento del que colgar el refresco. Los archivos también cambian por fuera: el gestor de archivos, otros procesos. El costo es un `Dir` sobre una carpeta cada 3 s.

PIEZAS

- Una sola función lista la carpeta (`ListarPDFs`, `ListarFiguras`). La usan el poblado inicial y el refresco.
- La firma son los nombres ordenados unidos con `Chr(10)`, en una variable del módulo. Se compara la lista completa y no la cantidad: detecta renombrados y una alta con una baja entre dos ticks.
- La firma la escribe un solo lugar, la función que llena el combo, y se reinicia al abrir proyecto y al cerrar sesión (`ResetVisorPDF`, `ResetearEstado`). Si no, el primer tick compara contra la foto del proyecto anterior.
- El `Timer` va en el formulario con `Delay = 3000` y `Enabled = True`. Un `Timer` recién agregado en el diseñador queda con `Enabled = False`. El handler es una llamada delegada al módulo, que sale sin hacer nada si no hay proyecto abierto.
- Si `Dir` falla, el módulo devuelve `Null` y el tick se saltea sin aviso: corre cada 3 s. No es un canal mudo (GV-23): el `Null` impide que una lista vacía por error vacíe el combo y cierre lo abierto.

VOLVER A LLENAR SIN RECARGAR LO ABIERTO

- Se vacía el combo, se vuelve a llenar y se repone la selección POR NOMBRE: una entrada nueva puede quedar antes en el orden, y `Add` en posición no corre el índice (GV-69).
- Se conserva lo que está ABIERTO —el archivo cargado en el visor o en memoria—, no el texto del combo.
- Reponer el `Index` dispara `Click` (GV-53). Una bandera, activa solo alrededor de esa asignación, hace salir al handler antes de cargar. El handler TIENE QUE CONSULTARLA: en `m_GestionImagenes` la bandera se escribía y nadie la leía, y según el código cada refresco recargaba la figura en memoria, vaciaba su deshacer o preguntaba por cambios sin guardar.

LO QUE NO DETECTA

Un archivo regenerado con el mismo nombre no cambia la firma. Lo abierto queda con la versión vieja hasta que se lo vuelve a elegir en el combo, que lo recarga porque el `Click` se dispara aunque el índice no cambie. Agregar la fecha de modificación a la firma queda descartado mientras no se mida si LuaLaTeX escribe el PDF de a poco: el refresco podría abrir un archivo a medio escribir.

SI LO ABIERTO DESAPARECE DEL DISCO

- Visor de PDF: se limpia el visor. El combo queda en el primer ítem, sin cargarlo (GV-69).
- Retocador de figuras: el combo queda sin selección (-1), para que no muestre una figura distinta de la que está en memoria; `BorrarImagenDisco` actúa sobre el texto del combo. Sin cambios sin guardar, se limpia el retocador. Con cambios, la figura se conserva y se avisa una sola vez; `Guardar` la vuelve a escribir en `/media` y el tick siguiente la repone.

Probado por Alberto en 3.22.1: primer PDF de un proyecto nuevo, PDF nuevo con otro abierto, PDF borrado, PDF regenerado; figura agregada, renombrada y borrada.

**Relaciones:** vinculo:GV-53, vinculo:GV-69, vinculo:GV-59, vinculo:SC-06, apoya:GV-23

**PENDIENTE:** hTimerRefrescarProyecto (cmbArticulosRevista) sigue con su propio modelo: compara cantidades y no firma, y resuelve el Click de la selección repuesta dentro del handler (GV-53). Unificarlo con este patrón queda por decidir.

### SC-28 — Corte de línea en títulos: una marca en la base, traducida en cada destino

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / JATS 1.4 / DocBook 5.2 / SaxonJ-HE 12.5 y SaxonC-HE 13.0 / LuaLaTeX + hyperref + titlesec / TeX Live 2023 / xmllint / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. El editor indica dónde cortar un título o un subtítulo escribiendo `\\` en el campo. El corte se cumple solo en el título compuesto del PDF; en cualquier otro destino la marca es un espacio.

LA MARCA NO ES LaTeX

`\\` es vocabulario de gbpublisher: «corte sugerido de título». Se eligió porque es lo que el editor ya escribe y porque no aparece en ningún título real. Exactamente dos barras; una barra sola sigue siendo texto y se escapa como hasta ahora. Es la misma regla de SC-25: nunca LaTeX en la base. La marca se traduce al salir, en cada destino.

ALCANCE

Título y subtítulo de artículo, de libro, de capítulo y de parte. El título traducido no: si trae la marca, sale un espacio. Los títulos de sección que se escriben en el .md siguen la misma regla, con su propio filtro y sus plantillas (SC-63).

DÓNDE CORTA Y DÓNDE NO

    corta                               espacio
    portada y portadilla del PDF        sumario del PDF
    apertura de capítulo y de parte     folio, marcadores, pdftitle
    cabecera del artículo               ficha de catalogación
                                        EPUB y HTML, también tapa, portada y créditos
                                        Crossref, DOAJ, SciELO, Redalyc, OPF, JSON

En el sumario el corte es el natural del armado de la página (decisión de Alberto).

UNA SOLA REGLA DE PARTICIÓN

`m_CorteTitulo` parte el texto en la marca y devuelve los tramos recortados. Quien llama escapa cada tramo con su propio escape y los une con el separador de su destino:

    JATS       Uno <break/> dos
    DocBook    Uno <?gb-corte?> dos
    LaTeX      Uno\gbCorteTitulo dos
    plano      Uno dos

El orden es obligatorio: partir, escapar, unir. Escapar primero rompe la marca, porque `EscaparTeX` la convierte en `\textbackslash{}`.

Los espacios a los dos lados del separador también son obligatorios: el valor de texto del separador es vacío, y sin ellos las salidas que leen el título como cadena pegan las palabras.

EVIDENCIA

- JATS 1.4: `<break/>` es hijo válido de `article-title`, `subtitle` y `trans-title`. En Publishing lo declara `%article-title-elements;` en `JATS-common1-4.ent`; en Archiving, el DTD que trae el proyecto, `JATS-archivecustom-models1-4.ent` lo redefine y conserva `%break.class;`. Validado con xmllint contra el DTD Publishing 1.4.
- DocBook 5.2 no tiene elemento de corte en `title` ni en `subtitle`. La documentación lo dice: «DocBook does not offer any mechanism for indicating where a line break should occur in long titles». Una instrucción de procesamiento dentro del título valida contra `schemas/docbook/docbook.rng` del repositorio (xmllint).
- El DocBook no se puede saltear: el título de capítulo del PDF sale de la base, pasa por el canónico y llega a `\chapter` por `docbook-to-latex.xsl`. Un espacio en el canónico perdería el corte justo donde hace falta.
- XSLT: el valor de texto de `<break/>` y de una instrucción de procesamiento es vacío, y la regla incorporada para instrucciones no produce nada. Medido: `Uno <?gb-corte?> dos` da `Uno dos` con `normalize-space` y `Uno  dos` con `value-of` y con `apply-templates` por defecto; `Pegado<?gb-corte?>mal` da `Pegadomal`. Lo mismo `<break/>`. Medido con SaxonJ-HE 12.5, la versión del proyecto, y con SaxonC-HE 13.0.
- Consecuencia: `jats-to-html`, `jats-to-epub`, `jats-to-crossref`, `jats-to-doaj`, `docbook-to-html` y `docbook-to-epub` no se tocan.
- `jats-to-scielo` y `jats-to-redalyc` sí: parten de una plantilla identidad y copiaban el `<break/>` tal cual al paquete del indexador. Llevan una plantilla para `article-title` y `subtitle` de `title-group` con `<break/>`, que escribe el título con `normalize-space`. Por eso no hace falta pasar el `<break/>` por packtools: no llega a SciELO.
- LuaLaTeX con hyperref: `\newcommand{\gbCorteTitulo}{\\}` y `\pdfstringdefDisableCommands{\def\gbCorteTitulo{ }}`. Cortan la apertura de capítulo, la de parte y el título compuesto con `\LARGE`; el sumario, el folio corrido y los marcadores salen en una línea porque toman el argumento opcional; `pdftitle` sale con un espacio y hyperref no avisa.

EN LaTeX, DOS VERSIONES DEL TÍTULO

`\gbCorteTitulo` nunca va en lo que alimenta el sumario, el folio o los marcadores. El generador emite la versión plana en el argumento opcional: `\chapter[plano]{compuesto}`, y `\addcontentsline{toc}{chapter}{plano}` con `\chapter*`. Es el patrón `\chapter[sumario]{título}` que Alberto usa a mano, y es el lugar donde irá la composición de autor y título del sumario.

- `docbook-to-latex.xsl` y `jats-to-latex.xsl` arman las dos versiones recorriendo los nodos del título: la compuesta traduce la instrucción o el `break` a `\gbCorteTitulo`; la plana, a un espacio.
- Contrato versión 6:
  - `\gbCorteTitulo`. hyperref se carga en la última capa, así que la desactivación se registra con `\AddToHook{package/hyperref/after}`: corre apenas termina la carga y antes del `\hypersetup{pdftitle=...}` de esa capa. En `\AtBeginDocument` sería tarde.
  - `\gbCapitulo{plano}{compuesto}{subtítulo}` y `\gbCapituloSinNumero{plano}{compuesto}{subtítulo}`: los emite `docbook-to-latex.xsl`. La sin número es `\chapter*` más `\addcontentsline` con la plana.
  - `\gbParte{plano}{compuesto}{subtítulo}`, `\gbEncabezadoPieza{plano}{compuesto}` y `\gbIndice{plano}{compuesto}{índice}`.
  - `\gbDisenoSubtituloCapitulo`: el aspecto del subtítulo, con un valor por omisión que la estética puede redefinir.
- La opción `newlinetospace` de titlesec, que usa la estética, cambia `\\` por espacio solo en las marcas y en el sumario; no toca la apertura. Leído en `titlesec.sty`.
- `\gbtitulo` y `\gbsubtitulo` van compuestos: sirven a la portada y a `pdftitle`/`pdfsubject`, y la desactivación los deja planos en los metadatos. `\gbtituloabreviado` va plano.
- Revistas: el preámbulo del artículo lo arma `m_XML`, no el contrato, y define también `\gbCorteTitulo`.

SUBTÍTULOS QUE NO LLEGABAN AL PDF

Al relevar los destinos apareció que `docbook-to-latex.xsl` no emite el `<subtitle>` del capítulo (`\gbCapitulo` estaba definido y sin uso) y que `\articulosubtitulo` se define pero ninguna plantilla lo compone. Se resuelven en el mismo lote.

PRUEBA DE PUNTA A PUNTA

En el contenedor, con TeX Live 2023, las fuentes de la estética y las cuatro capas reales del preámbulo: un canónico armado por `ensamblar-capitulo-canonico.xsl` con la instrucción en el título y el subtítulo, pasado por `docbook-to-latex.xsl`, con portadilla, portada, una introducción sin número, una parte, un capítulo y un índice. Cortan la portadilla, la portada, las dos aperturas, la parte y el encabezado del índice; el sumario y los marcadores salen en una línea; `pdftitle` y `pdfsubject` con un espacio; ni errores ni avisos de hyperref. Un JATS con `<break/>` valida contra el DTD Archiving 1.4 del proyecto y pasa por las ocho hojas JATS: solo `jats-to-latex` conserva el corte.

**Relaciones:** vinculo:SC-25,vinculo:SC-26,vinculo:SC-63

**PENDIENTE:** Probar con un libro y una revista reales en Mint: la prueba fue en el contenedor, sin la base. Del PDF de revista se verificó el .tex que emite jats-to-latex, sin compilar el artículo entero.

### SC-29 — Notas al pie en títulos de sección: marca numérica y dos versiones del título

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / DocBook 5.2 / JATS 1.4 / SaxonJ-HE 12.5 / LuaLaTeX + titlesec + hyperref + biblatex / TeX Live 2023 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Un título de sección (`##` y siguientes) puede llevar una nota al pie. El título de la pieza, del libro o de la revista no: es una decisión editorial del modelo de trabajo.

LA MARCA ES NUMÉRICA

La nota del título se numera con las demás, en el orden del texto. Se renuncia a la marca con asterisco u otro signo que en LaTeX da `\Footnote{}{}` (consejo de la AMS: no poner números en títulos ni fórmulas). Markdown no tiene forma de expresarla, y la confusión que se buscaba evitar la compensan los corchetes del PDF y el hipervínculo de EPUB y HTML.

EL CANÓNICO YA ESTABA BIEN

Pandoc con los filtros del proyecto deja la nota dentro del título, y los dos vocabularios la admiten:

    DocBook   <title>…<footnote><para>…</para></footnote></title>   valida contra el RNG
    JATS      <title>…<fn><p>…</p></fn></title>                     valida contra el DTD Archiving 1.4

La falla estaba en las hojas que leían el título de sección con `normalize-space(title)`: el texto de la nota quedaba pegado al título y se perdía la marca. Afectaba a `docbook-to-latex`, `docbook-to-html` y `jats-to-latex`. `docbook-to-epub`, `jats-to-epub` y `jats-to-html` ya recorrían los nodos del título. El mismo aplanado borraba la cursiva y las citas de cualquier título de sección.

HTML Y EPUB

El encabezado se arma recorriendo los nodos del título. La nota toma la plantilla de nota de cada hoja: marca numerada con vínculo, y en el HTML, el panel de notas.

PDF: DOS VERSIONES DEL TÍTULO

Como en SC-28, las hojas LaTeX arman el título de sección dos veces, con el parámetro de túnel `notasTitulo` que lee la plantilla de nota:

    \subsection[SUMARIO]{APERTURA}

- Apertura: el título con su formato y cada nota como `\gbNotaTitulo{…}`.
- Sumario (argumento opcional; va al sumario, al folio y a los marcadores): el título con su formato y sin notas.
- Si el título lleva una cita, el opcional va envuelto en `\texorpdfstring{SUMARIO}{TEXTO}`: hyperref no puede pasar una cita a cadena PDF, borra el comando y deja la clave en el marcador («Con cita a en el título», verificado). TEXTO es el título sin notas ni citas.
- El argumento de un título no admite `\par`: los párrafos de una nota de título se separan con `\endgraf`.

`\gbNotaTitulo` es vocabulario del contrato 7: vale `\footnote` al componer y nada cuando titlesec mide el título (GV-70). Si la estética no carga titlesec, el contrato provee `\iftitlemeasuring` y siempre compone. El preámbulo de revista, que arma `m_XML`, la define igual.

Verificado en el contenedor con las capas reales del preámbulo de libro: las notas de título y de párrafo salen [1], [2], [3]; el sumario y los marcadores, sin nota; la cursiva, en el sumario; la cita, en la apertura y en el sumario, y fuera del marcador. En revista, con titlesec con y sin `calcwidth`.

NIVEL DE LOS ENCABEZADOS DE REVISTA

Al relevar apareció que `jats-to-html` y `jats-to-epub` emitían todas las secciones como `<h2>`. Ahora el nivel sigue la profundidad (h2 a h6). No cuentan las secciones cuyo título se suprime —introducción, editorial, la que repite el título del artículo—: si contaran, sus hijas saltarían un nivel. El aspecto del HTML no cambia: lo da la clase `sec-title`.

PANEL DE NOTAS DEL HTML

El HTML de libro y el de revista muestran las notas en un panel lateral que arma el JS con lo que trae el atributo `data-fn-text` de cada marca, insertado con `innerHTML`. Ese atributo llevaba la nota como texto plano: el panel perdía la bastardilla, la negrita y los enlaces —en todas las notas, no solo en las de título—, y un «<» del texto se leía como marcado.

Ahora lleva el HTML de la nota, serializado con `serialize()`. Lo arma el modo `nota-panel` de `docbook-to-html` y `jats-to-html`:

- conserva bastardilla, negrita, superíndice, subíndice, código y enlaces;
- cada párrafo de la nota va en su `<p>`;
- la cita sale como texto resuelto, «(Autor, año)», sin el enlace con `onclick`: el ítem del panel ya tiene el suyo;
- los supresores de separadores entre citas valen también en este modo.

En `docbook-to-html` los elementos del modo van con `xmlns=""`: la hoja declara XHTML como espacio de nombres por omisión, y sin eso la serialización escribe `xmlns` en cada elemento. El JS no cambia.

Verificado en Chromium: la bastardilla se ve en el panel, y «a < b» y «<algo>» salen como texto.

ENLACES EN EL HTML Y EL EPUB DE REVISTA

`jats-to-html` y `jats-to-epub` no tenían plantilla para `<ext-link>`: la regla incorporada dejaba solo el texto y el enlace se perdía, en el cuerpo y en las notas. Ahora es un `<a href>`, con `target="_blank"` en el HTML.

**Relaciones:** vinculo:SC-28,apoya:GV-70

**PENDIENTE:** Probar con un libro y una revista reales en Mint.

### SC-30 — Comillas y formato en línea: el mismo resultado en las seis salidas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / SaxonJ-HE 12.5 / Pandoc 3.1 / LuaLaTeX + ulem + hyperref / TeX Live 2023 / Chromium / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Lo que el editor marca en línea en el .md sale igual en el PDF, el EPUB y el HTML, de libro y de revista. Se armó una matriz de casos y se corrigió todo lo que no coincidía.

1. SIN SANGRÍA EN LA SERIALIZACIÓN XML

Las hojas que escriben XML lo hacen con `indent="no"`: los tres ensamblados del canónico (`ensamblar-capitulo-canonico`, `ensamblar-libro-canonico`, `ensamblar-canonico`), los dos EPUB (`docbook-to-epub`, `jats-to-epub`) y los cuatro indexadores (`jats-to-crossref`, `jats-to-doaj`, `jats-to-scielo`, `jats-to-redalyc`). Con `indent="yes"` metían un espacio donde un elemento quedaba pegado a otro (GV-71):

    «esta es una prueba de «texto»»   →   …“texto” »
    «*Cursiva* al inicio»             →   « Cursiva…
    *cursiva con **negrita***.        →   …negrita .
    *texto*[^1]                       →   texto ¹

El canónico conserva la sangría que traen Pandoc y Gambas: las hojas copian esos nodos de espacio. Las salidas HTML siguen con `indent="yes"`: el método html de Saxon no sangra dentro del texto en línea (verificado).

2. COMILLAS ANIDADAS EN REVISTAS

En el .md toda cita va con « », y el nivel lo decide el anidamiento: « » → “ ” → ‘ ’, y vuelve a « » en el cuarto. En libros lo resuelve `quote.xsl` sobre el `<quote>` del DocBook. JATS 1.4 no tiene cita en línea: en revistas lo resuelve el filtro `quoted-a-nivel-jats.lua` en caracteres, después de `guillemets-to-quoted-db.lua`, con la misma regla. Una nota dentro de una cita sigue contando la profundidad, igual que en libros. También las comillas rectas, que Pandoc convierte en cita, toman el carácter de su nivel.

3. FORMATO EN LÍNEA

    .md                 DocBook                          JATS          PDF              HTML / EPUB
    [x]{.smallcaps}     emphasis role="smallcaps"        <sc>          \textsc          <span class="versalitas">
    ~~x~~               emphasis role="strikethrough"    <strike>      \gbTachado       <del>
    [x]{.underline}     emphasis role="underline"        <underline>   \gbSubrayado     <u>
    x^2^ / H~2~O        superscript / subscript          sup / sub     \textsuperscript  <sup> / <sub>

Antes, en libros, versalitas, tachado y subrayado salían en bastardilla en las tres salidas, y superíndice y subíndice se perdían en HTML y EPUB. En revistas, HTML y EPUB perdían los tres primeros y el PDF perdía el tachado. Los elementos HTML son los que usa el escritor HTML de Pandoc. La clase `versalitas` está en las cuatro hojas de estilo (libro HTML y EPUB, revista HTML y EPUB). El panel de notas del HTML (SC-29) los conserva.

Versalitas: `\textsc` y `font-variant: small-caps` sobre lo que escribió el editor. Para un siglo en versalitas se escribe en minúscula: `[xix]{.smallcaps}`.

4. TACHADO Y SUBRAYADO EN EL PDF (CONTRATO 8)

`\gbTachado` y `\gbSubrayado` sobre ulem (`\sout`, `\uline`), que cortan la línea; `\underline` arma una caja y no corta. ulem se carga con `[normalem]`: sin eso cambia `\emph` por subrayado en todo el documento. Son `\DeclareRobustCommand` porque pueden ir en un título de sección, y en los marcadores del PDF dejan el texto solo. El preámbulo de revista, que arma `m_XML`, los define igual. ulem es parte de TeX Live (colección plain-generic, incluida en texlive-full, que es lo que pide la verificación de dependencias).

5. ESPACIO ENTRE DOS ELEMENTOS EN EL PDF DE REVISTA

`jats-to-latex` tenía `strip-space elements="*"`: el espacio entre `*Una* **nota**` es un nodo de solo espacio y se perdía, y las palabras salían pegadas. Ahora `preserve-space` nombra los elementos con texto en línea (`p`, `title`, `td`, `italic`, `bold`, `xref`…), que ganan sobre el comodín. `docbook-to-latex` ya listaba solo los estructurales.

FUERA DE ESTE LOTE

Las fórmulas en libros (`inlineequation`): hoy abortan el PDF con «vocabulario no previsto» y el EPUB las aplana. Decisión de Alberto: lote aparte, con diseño propio.

`~` sigue siendo el subíndice (`H~2~O`). El espacio fijo del .md es `¬` (SC-68).

**Relaciones:** vinculo:SC-29,apoya:GV-71,vinculo:SC-54,vinculo:SC-68

**PENDIENTE:** Probar con un libro y una revista reales en Mint.

### SC-31 — Diseño de las salidas de lectura: manda el PDF

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** gbpublisher / salidas PDF, EPUB y HTML de libro y de revista · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). En todo lo que es diseño —composición, numeración, orden de los elementos, aspecto de cada uno— la referencia es el PDF. El EPUB y el HTML replican lo que hace el PDF; no diseñan un modelo propio.

ALCANCE

Las salidas de lectura: PDF, EPUB y HTML, de libro y de revista. Quedan afuera los sabores XML —el canónico JATS o DocBook, Crossref, DOAJ, SciELO, Redalyc, el OPF—: responden a su esquema y a lo que pide su destino, no al diseño.

EXCEPCIONES

Solo dos, y se nombran al tomar la decisión:

1. Lo crítico en el medio digital: la accesibilidad (el texto alternativo de una figura), que un enlace funcione, la validez ante epubcheck.
2. Lo que no tiene sentido fuera de la página impresa: folio, páginas blancas, cortes de página, el corte de línea de un título (SC-28), las versalitas que los lectores de EPUB no respetan de forma pareja (SC-25).

Cada excepción queda escrita en la entrada que la toma, con su razón. Una diferencia sin excepción escrita es un error de la salida digital.

CONSECUENCIAS

- Ante una divergencia entre salidas, se corrige el EPUB o el HTML, no el PDF.
- Una decisión de diseño se toma mirando el PDF y después se lleva a las otras dos salidas. No al revés.
- Lo que el PDF resuelve con LaTeX —numeración de figuras, tablas y ecuaciones, referencias cruzadas, orden de las piezas— el EPUB y el HTML lo reproducen con el mismo resultado visible, aunque el mecanismo sea otro.

LaTeX COMO BASE

El PDF se compone con LaTeX, y por eso muchas decisiones de diseño de gbpublisher toman su base en LaTeX (decisión de Alberto): cómo numera, cómo arma el sumario, cómo resuelve una referencia cruzada, cómo compone la bibliografía con biblatex. Cuando un problema tiene una solución establecida en LaTeX, esa es la forma de partida, y apartarse de ella se escribe como cualquier excepción.

Vale también para la entrada: el .md se teclea con las convenciones de LaTeX para los signos que LaTeX escribe en ASCII (SC-40).

Es el principio que ya aplicaban SC-14 (la bibliografía replica el estilo biblatex del libro), SC-26 y SC-30 (el mismo resultado en las seis salidas). Esta entrada lo deja escrito como regla general.

**Relaciones:** vinculo:SC-14,vinculo:SC-26,vinculo:SC-28,vinculo:SC-25,vinculo:SC-30,vinculo:SC-40,vinculo:SC-45,vinculo:SC-56

### SC-32 — Figuras de libro y revista: una sola forma en el .md, número del PDF y referencia cruzada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1.3 / SaxonJ-HE 12.5 / LuaLaTeX + hyperref + caption / TeX Live 2023 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Una figura se escribe de una sola forma, en libros y en revistas:

    ::: {.fig #fig-mapa}
    ![Pie de la figura, con *formato* y citas [@clave]](media/fig-mapa.png)
    :::

Con texto alternativo propio para el EPUB accesible: `::: {.fig #fig-mapa alt="..."}`. En revistas, `.fullwidth` la lleva al ancho completo; en libros no se usa.

LA CLASE ES .fig

Es la que escribe el shortcode y la que usan las revistas en producción. El botón de la barra escribía `.figure`, que ningún filtro reconocía: en revistas salía `<boxed-text>` con la figura adentro. Ahora botón y shortcode van por un solo camino, `FMain.InsertarFigura`: diálogo de imagen, copia a `/media` e id tomado del nombre de la imagen (`fig-mapa.png` da `#fig-mapa`).

EL FILTRO DE LIBRO ARMA EL <figure>

El escritor DocBook de Pandoc 3.1 descarta el id de una figura (GV-72), así que `fenced-divs-to-elements-db.lua` emite el `<figure xml:id>` con el pie en `<title>` y el alternativo en `textobject`. Detiene la conversión con un mensaje si falta el id, si falta el pie (RC-DB-03) o si el bloque tiene algo más que la imagen: antes, el párrafo que seguía a la imagen se perdía sin aviso.

Un filtro que detiene la conversión ya no deja un capítulo vacío (GV-23). En libros, `engine/generar_canonicos_capitulos.sh` no arma el fragmento, muestra el motivo del filtro y borra el canónico anterior del capítulo, para que el ensamblado no tome uno que ya no corresponde al .md. En revistas, `m_XML.GenerarBodyXML` escribe una marca de fallo en lugar del fragmento y lo informa.

EN REVISTAS NO HAY REFERENCIA CRUZADA

Un artículo es autónomo: no remite a figuras ni tablas de otro artículo, ni siquiera dentro de un dossier, porque sus autores no están conectados. Dentro del propio artículo, la mención («figura 2») la escribe el autor como texto, con el número que usó; si se cambia, lo decide el editor o el corrector. Por eso en revistas no hay `@fig-`: `cite-to-xref.lua` detiene la conversión con un mensaje ante una clave `fig-`, `tbl-`, `eq-` o `lst-` (SC-42), que antes salía como una cita bibliográfica a una referencia inexistente.

LA FIGURA DE REVISTA

`cite-to-xref.lua` arma el `<fig>`, la normal y la de ancho completo (`.fullwidth` → `specific-use="fullwidth"`); `figure-to-end.lua`, que hacía la segunda por separado, se retiró. Con las mismas reglas que el libro: el pie conserva formato y citas, `alt="..."` va a `<alt-text>` dentro de `<graphic>`, y frena sin id, sin pie o con contenido además de la imagen. El id no sirve para referir: es el ancla estable de la figura, que el HTML pone en el contenedor y el EPUB conserva (antes la renumeraba). En las dos salidas el pie conserva formato y el texto alternativo es el declarado o, si falta, el pie. Antes el pie se aplanaba a texto: perdía la bastardilla y la cita entera. Verificado en el contenedor: el JATS valida contra la DTD 1.4 y las cinco formas incorrectas frenan.

REFERENCIA CRUZADA: @fig-mapa (SOLO LIBROS)

Pandoc la lee como cita. En libros, `cite-to-biblioref-db.lua` la desvía a `<xref linkend>` por el prefijo: ninguna clave bibliográfica empieza con letra, porque empiezan con el id numérico del registro. Produce solo el número, como `\ref`; la palabra la escribe el editor. Un grupo que mezcla referencias y citas detiene la conversión. `@tbl-` y `@eq-` también la detienen, hasta que tablas y ecuaciones tengan su lote: antes salían como cita a una referencia inexistente.

Los id `fig-*` no se prefijan con el del capítulo en `ensamblar-capitulo-canonico.xsl` (`db:es-id-global`, como `bib-*`): con el prefijo, la referencia a una figura de otro capítulo apuntaba al propio. Son únicos en el libro por convención. El canónico de una pieza que remite a otra no valida suelto (IDREF); el del libro, sí. Por eso `generar_canonicos_capitulos.sh` no cuenta esos errores como aviso (SC-53).

NUMERACIÓN (SC-31: LA DEL PDF)

    capítulo numerado     2.3
    apéndice              A.1
    pieza sin número      1, 2, 3 dentro de la pieza

Contrato 9: `\gbCapituloSinNumero` reinicia notas, figuras, cuadros y ecuaciones (`\gbReiniciarPieza`) y enciende `\ifgbPiezaSinNumero`, que `\thefigure`, `\thetable` y `\theequation` consultan para omitir el prefijo; `\gbCapitulo` lo apaga. El ancla de hyperref lleva el contador de pieza: con book y hyperref solos, dos «Figura 1» compartían el ancla y el enlace iba a la primera. La estética actual carga caption, cuyas anclas ya son únicas; el ajuste garantiza lo mismo con otra estética.

`docbook-to-latex.xsl`: un `<appendix>` con role (sobre_autores, cronologia) no se numera.

EPUB y HTML calculan el mismo número con `numeracion-libro.xsl`, incluido por las dos hojas. El EPUB transforma pieza por pieza: el script le pasa la lista del libro y la pieza en curso. La referencia a otra pieza enlaza a su archivo. Un destino inexistente sale «??» y se avisa; un id repetido se avisa.

`compilar_pdf_libro.sh` informa al final las referencias sin destino y los id repetidos que deja el registro de LaTeX.

VERIFICADO EN EL CONTENEDOR

Libro de prueba con Introducción, dos capítulos, Conclusiones y un apéndice, con referencias cruzadas entre todas las piezas, una en una nota y una cita en un pie. PDF, HTML y EPUB dan los mismos números: 1, 1.1, 1.2, 2.1, 1, A.1. El canónico del libro valida contra el RNG. Los casos de error del filtro detienen Pandoc con el mensaje.

**Relaciones:** vinculo:SC-31,vinculo:SC-28,vinculo:SC-25,vinculo:RC-DB-03,apoya:GV-23,vinculo:GV-72,vinculo:GV-73,vinculo:SC-35,vinculo:SC-42,vinculo:SC-53

**PENDIENTE:** Probar en Mint con el libro nuevo que tiene figuras y con una revista. Tablas y ecuaciones siguen el mismo camino en lotes propios: prefijos tbl- y eq- en cite-to-biblioref-db.lua y en db:es-id-global.

### SC-33 — Cierre nombrado de los bloques: [/clase]: # () antes del :::

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / filtros Lua del proyecto / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Todo bloque (fenced div) cierra con un ancla que lo nombra, antes del `:::` final y después de una línea en blanco:

    ::: epigraph

    El conocimiento es poder.

    [/epigraph]: # ()
    :::

EL PROBLEMA

En un capítulo largo con bloques anidados aparecen varios `:::` seguidos y no hay forma de saber qué cierra cada uno. El ancla lo dice, y es lo que va a permitir seleccionar el contenido entero de un shortcode, como ya se hace con las comillas y los signos de pregunta.

POR QUÉ FUNCIONA

`[/epigraph]: # ()` es una definición de referencia de enlace que nada usa. Pandoc la consume al leer y no llega al árbol: no la ven ni los filtros Lua ni las hojas XSLT. Medido con Pandoc 3.1.3:

- un bloque con su ancla da el `Div` solo, sin rastro del ancla;
- dos bloques iguales en un capítulo, cada uno con su ancla: sin aviso;
- anidados, cada uno con su ancla: correcto;
- una figura con ancla pasa por `fenced-divs-to-elements-db.lua` (libro) y por `cite-to-xref.lua` (revista) como sin ella.

LA LÍNEA EN BLANCO ES OBLIGATORIA

Sin línea en blanco antes, el ancla sale como texto del párrafo anterior, sin ningún aviso (medido). Quien inserta un bloque la escribe siempre; un ancla agregada a mano tiene que respetarla.

ALTERNATIVAS DESCARTADAS (MEDIDAS)

- Texto en la línea de cierre (`::: /epigraph`): no es un cierre; el bloque entero se vuelve párrafo.
- Largo distinto de los dos puntos: no empareja. Un `::::` cierra el bloque más interno aunque se haya abierto con `:::`.
- Comentario HTML (`<!-- /epigraph -->`): entra al árbol como bloque crudo. El filtro de figuras de libro lo rechaza como contenido de más, y todo filtro tendría que ignorarlo.

QUIÉN LO ESCRIBE

gbpublisher, desde la clase de Pandoc de la apertura: `m_Shortcodes.AnclaCierre(clase)` es el único lugar con el formato, y lo usan `InsertarShortcode` e `InsertarFigura`. El campo `cierre` del catálogo de shortcodes queda en `:::`: un error en una fila no puede romper el emparejamiento. Los ejemplos de bloque del catálogo muestran el ancla, porque la ayuda enseña lo que inserta el botón (RF-11).

El nombre es la CLASE, no el nombre del shortcode: `sec-intro` escribe `{.intro}` y cierra con `[/intro]`. Es la columna `clase` del catálogo.

Solo los bloques. Un shortcode en línea cierra en la misma línea (`[texto]{.clase}`).

El corrector ortográfico saltea `[/…]` (m_Hunspell).

Hasta esta entrada, el comentario de `m_Shortcodes` citaba la convención como RC-MD-01, una regla que no existía en el corpus.

**Relaciones:** vinculo:SC-32,vinculo:RF-11,vinculo:SC-18,vinculo:SC-21

**PENDIENTE:** Sin implementar: el verificador de cierres (empareja aperturas y anclas con una pila: ancla sin línea en blanco, ancla con otra clase, apertura sin ancla) y la selección del contenido de un shortcode, que usa el mismo emparejamiento. Los .md escritos antes, sin ancla, no se corrigen solos.

### SC-34 — gbpublisher lee el catálogo exportado por gbShortcodes: sin tabla en MySQL

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / Linux Mint, instalado y desde el IDE; Gambas 3.19 / gbx3 con xvfb / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA. El catálogo de shortcodes de gbpublisher es la exportación de gbShortcodes (RF-11): `shortcodes/_catalogo.tsv` más un `<nombre>.html` (ayuda) y un `<nombre>.md` (ejemplo) por shortcode. La tabla `shortcodes` de MySQL se retira en la actualización 1.7.0 (SC-22).

DÓNDE SE LEE

`m_InicioCierre.RutaRecursos() &/ "shortcodes"`: `.hidden/shortcodes` del proyecto desde el IDE, `/usr/share/gbpublisher/shortcodes` instalado. La carpeta va en Archivos extra del proyecto (`.project`, ExtraFiles); sin eso el paquete sale sin catálogo.

No se copia a `~/.gbpublisher` (SC-11): no hay nada que ajustar, y una copia local vieja dejaría el panel con los shortcodes de otra versión.

UN SOLO DICCIONARIO

`m_CatalogoShortcodes` lee el catálogo una vez por sesión y lo indexa por nombre y por clase (`PorNombre`, `PorClase`; la clase no es única: `fig` tiene dos filas, `table` tres). Es la única fuente: lo que necesite saber qué shortcodes existen —el panel, la inserción, el futuro verificador de cierres (SC-33)— pregunta ahí.

El catálogo no se carga a medias. Una cabecera distinta de la del contrato, o una fila sin los doce campos, se informa con el archivo y la línea, y el catálogo no se usa.

QUÉ SE MUESTRA

Para validar sirve el catálogo entero, en cualquier estado. Para mostrar, `Visibles`: instalado, solo lo `liberado` para el tipo de proyecto (libro o revista); desde el IDE, también los `borrador`, marcados como tales, para probarlos antes de liberarlos. `EsDesarrollo` lo decide por `RutaRecursos`.

EL PANEL

- El combo elige bloques o marcas en línea, y `txtDescripcion` explica qué es cada tipo.
- La lista separa por grupo (comunes, estructura del producto, disciplinares y composición) y, dentro de los disciplinares, por perfil. Composición, al final, son las instrucciones que solo afectan al PDF (SC-38).
- La ayuda es un TextEdit en modo RichText (GV-64). Toma el fragmento `<nombre>.html` y pone el ejemplo en el lugar de `<!--gb:ejemplo-->`, coloreado con la gramática Markdown del editor y sobre el fondo del tema, en una tabla de una celda. Se repinta al cambiar el tema o la fuente.

LA INSERCIÓN, SEGÚN EL MODO

- `figura`: delega en `FMain.InsertarFigura` (SC-32).
- `envolver`: exige una selección.
- `plantilla`: inserta con el marcador de los snippets (SC-21) y lo deja seleccionado.
- `dos-partes`: como `envolver`, si la selección tiene la forma `{primera}{segunda}`; si no, avisa qué falla y no inserta (SC-35).
- `separador`: inserta el bloque vacío con su ancla si no hay selección y el cursor está al principio de una línea vacía (`m_EditorPrincipal.CursorEnLineaVaciaAlInicio`); si no, avisa y no inserta (SC-36).
- `separador-valor`: los semáforos del separador, con una línea para el valor que lleva el marcador seleccionado; lo valida el filtro al generar (SC-39).
- Un bloque queda separado por líneas en blanco de lo que tenga antes y después, porque Pandoc no lo reconoce sin ellas (medido), y cierra con el ancla nombrada (SC-33).

REGLA DE LIBERACIÓN

Un shortcode se libera terminado: para libros y revistas, o para uno solo cuando es específico de ese producto. Nunca con pendientes a medias. El esquema 3 de gbShortcodes lo hace cumplir (RF-11): un shortcode liberado no tiene pendiente, y no puede estar liberado en un producto y en borrador en el otro (en el otro es liberado o `no_aplica`).

RESALTADO

`Markdown.highlight` reconoce la apertura, el ancla, el cierre y las marcas en línea con el estilo `Function`; cada tema define `Function` en su sección `[Markdown]`. Los patrones escriben el espacio como `\x20` o `\s` (GV-76).

**Relaciones:** vinculo:RF-11,vinculo:SC-11,vinculo:SC-22,vinculo:SC-33,vinculo:SC-32,vinculo:SC-21,vinculo:GV-64,vinculo:GV-76,vinculo:SC-24,vinculo:SC-35,vinculo:SC-36,vinculo:SC-38,vinculo:SC-39

**PENDIENTE:** Verificado en Mint con 3.22.1 (2026-10): instalado, el panel muestra solo lo liberado (la figura); desde el IDE, también los borradores, marcados. La figura se inserta con la línea en blanco y el ancla, se guarda y se colorea. Falta probar en Mint la inserción de dos-partes (el epígrafe), plantilla y en línea. En cinco temas el color de Function coincide con otro estilo de Markdown (gruvbox, monokai, pen-paper-coffee, solarizado-claro y solarizado-oscuro): a decidir. El verificador de cierres no está implementado.

### SC-35 — Epígrafe: {texto}{atribución}, a la derecha, 60 % de la columna, con filete

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / LuaLaTeX / LibreOffice / Gambas 3.19 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. El epígrafe se escribe en dos partes entre llaves, pegadas, dentro del bloque:

    ::: epigraph

    {El conocimiento es *poder*.}{Francis Bacon, *Meditationes sacrae*}

    [/epigraph]: # ()
    :::

Replica `\epigraph{texto}{atribución}` de LaTeX. Las dobles llaves son el semáforo: el corte entre texto y atribución lo dan ellas, no una raya, así que las dos partes admiten rayas, además de bastardilla, negrita y citas. La atribución puede quedar vacía: `{texto}{}`. El texto admite varios párrafos (una línea en blanco dentro de las llaves); la atribución, uno solo, porque `<attribution>` (DocBook) y `<attrib>` (JATS) solo admiten texto en línea.

QUIÉN ESCRIBE LAS LLAVES

Quien marca. Selecciona `{…}{…}` y aplica el shortcode, que es de modo `dos-partes` (SC-34): antes de insertar controla la forma y, si falla, avisa qué falla y no inserta (`m_Shortcodes.ProblemaDosPartes`, probado con 13 casos).

UNA SOLA REGLA PARA LAS TRES CADENAS

`dos-partes.lua` corre en revista (antes de `cite-to-xref.lua`), libro (antes de `fenced-divs-to-elements-db.lua`) y ODT (antes de `epigrafe-odt.lua`). Cuenta las llaves del nivel del párrafo: Pandoc las deja como texto y las de adentro, balanceadas, son texto (medido con Pandoc 3.1.3). Deja el bloque con dos hijos, `.epigrafe-texto` y `.epigrafe-atrib`, y cada filtro solo serializa. Frena la conversión con un mensaje que cita el comienzo del bloque si falta una llave, si hay texto fuera, si las partes no van pegadas, si hay más de dos, si la primera está vacía o si la atribución tiene más de un párrafo.

- Revista: `<disp-quote specific-use="epigraph">` con `<p>` y `<attrib>` (valida contra la DTD 1.4).
- Libro: `<epigraph>` con `<attribution>` primero y los `<para>` (DocBook 5.2).

Antes, el filtro de revista aplanaba el epígrafe a texto (perdía la bastardilla y pegaba los párrafos) y el de libro perdía la atribución en un párrafo propio y todo párrafo después del primero.

DISEÑO (EL LEGADO LaTeX DE ALBERTO)

Bloque a la derecha, del 60 % de la columna, en letra menor (`\small`) y sin corte de palabra. El texto, alineado a la izquierda; un filete de 0,6 pt; la atribución, alineada a la derecha. Sin atribución no hay filete. Igual en libros y revistas, y en el PDF, el EPUB y el HTML.

- PDF: `\gbepigrafe{texto}{atribución}`, macro propia y no el paquete `epigraph`, que no permite omitir el filete. Está en `preambulo-contrato.tex` (libros) y en `m_XML.ObtenerPreambuloEmbebido` (revistas), gemelas: un cambio en una va en la otra. `jats-to-latex.xsl` reconoce el epígrafe por `@specific-use`, no por tener `<attrib>`.
- HTML y EPUB: `div.epigrafe` con `p.epigrafe-texto` y `p.epigrafe-atrib`; el filete es el borde superior de la atribución. Mismas reglas en `gbpublisher.css`, `gbpublisher-epub-libro.css`, `jats-to-html.xsl` y `m_GenerarEpub`. La atribución conserva sus marcas y no lleva raya.
- ODT: los estilos de párrafo `gbEpigrafe` y `gbEpigrafeAtrib` de `ott/reference.ott`, que Pandoc aplica por `custom-style`. Con margen izquierdo fijo de 6,6 cm (el 60 % de la caja del documento de referencia).

- Dedicatoria (SC-45): el mismo bloque sin atribución, sin filete. En el PDF, el entorno `gbdedicatoria` del contrato es gemelo de `\gbepigrafe`: un cambio de diseño del epígrafe va en los dos.

EL TEXTO PUEDE SER UN VERSO (SC-49)

La primera parte puede ser un bloque `::: verse`, solo, con las llaves en su propio párrafo y líneas en blanco alrededor (GV-92). `dos-partes.lua` lo acepta (`verso1` en su tabla, sin gemelo en `m_Shortcodes.ProblemaDosPartes`, que controla las llaves y no los bloques) y lo marca con la clase `en-epigrafe`. Libro: los `<literallayout>` del verso dentro de `<epigraph>`. Revista: el `<verse-group>` dentro del `<disp-quote>`. PDF: el entorno `gbversoepigrafe` dentro de `\gbepigrafe`. HTML y EPUB: `div.verso.verso-epigrafe` dentro de `div.epigrafe`, con su letra y sin bastardilla.

UN FILTRO QUE FRENA SE VE

En revistas, `GenerarBodyXML` sigue ahora el patrón de los capítulos: si Pandoc termina con error no se arma el `<body>`, se escribe una marca de fallo y el motivo queda en la terminal. Antes un epígrafe mal formado dejaba un `<body>` a medias sin aviso (GV-23).

**Relaciones:** vinculo:SC-34,vinculo:SC-33,vinculo:SC-31,vinculo:SC-30,vinculo:RF-11,vinculo:SC-11,apoya:GV-23,vinculo:SC-45,vinculo:SC-49

**PENDIENTE:** Probado en el contenedor: los filtros, las cinco hojas que se pueden correr sueltas (las de HTML y EPUB de libro, con la plantilla aislada), el PDF y el ODT. Falta en Mint, con un libro y una revista reales, y epubcheck sobre un EPUB completo.

### SC-36 — Froufrou: separador ornamental de libros, modo separador

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / LuaLaTeX / Chromium / Gambas 3.19 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Separador ornamental entre dos tramos de un texto, el `\froufrou` del legado LaTeX de Alberto. Es casi exclusivo de libros y obedece a una forma de escribir: en revistas no aplica.

    ::: froufrou

    [/froufrou]: # ()
    :::

El bloque es vacío; el ancla la consume Pandoc (SC-33), así que llega un `Div` sin contenido.

FORMAS DESCARTADAS (MEDIDAS)

- Una sola línea, `::: froufrou` sin cierre: Pandoc no la lee como bloque, sino como un párrafo con ese texto (Pandoc 3.1.3).
- Llaves con contenido, `{froufrou}`: el bloque no tiene contenido, y las llaves quedaron como el semáforo de las dos partes (SC-35).
- `* * *` en el .md: Pandoc lo lee como `HorizontalRule`, una regla temática genérica. El shortcode dice qué es y lo controla.

SEMÁFOROS

Modo `separador` del catálogo (SC-34), que desde la versión 4 de gbShortcodes es una fila de la tabla `modos` (RF-11): no admite una selección y exige el cursor al principio de una línea vacía, para no partir un párrafo. Las líneas en blanco que falten alrededor las agrega la inserción, como en todo bloque.

Libro o revista lo decide el tipo de proyecto (`FMain.TipoProyectoActual`), no el prefijo del nombre: el panel de una revista no muestra lo que está en `no_aplica`. Un bloque escrito a mano en un artículo lo frena `cite-to-xref.lua`. Un froufrou con contenido lo frena `fenced-divs-to-elements-db.lua`: lo de adentro se perdería.

SALIDAS

- Canónico: `<para role="froufrou">* * *</para>`. DocBook no tiene elemento de separación; el texto hace que cualquier lector sin nuestras hojas muestre el corte. Valida contra el RNG de DocBook 5.2.
- PDF: `\froufrou`, con `\usepackage{froufrou}` en `preambulo-contrato.tex` (carga `tikz` y `fourier-orns`; el ornamento queda incrustado). Compilado con LuaLaTeX.
- HTML y EPUB: tres asteriscos centrados a 1 cm, sin depender de la fuente, en `div.froufrou` con `role="separator"` y un `span` por asterisco. En el HTML, `display: flex` con `column-gap: 1cm`: la salida está indentada y, con márgenes, el espacio entre los `span` se sumaba al centímetro (medido en Chromium: 41,8 px en lugar de 37,8). En el EPUB, sin indentar (GV-71), basta el margen izquierdo de 1 cm desde el segundo `span`.
- ODT de libros: todavía no existe.

**Relaciones:** vinculo:SC-34,vinculo:SC-33,vinculo:SC-35,vinculo:RF-11,vinculo:GV-71

**PENDIENTE:** Probado en el contenedor: filtros, RNG, las tres hojas de libro (HTML y EPUB con la plantilla aislada), la macro y la medida del HTML. Falta en Mint con un libro real.

### SC-37 — Búsqueda en el editor principal: buscar de nuevo en cada paso, foco al editor y F3 para avanzar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint; código fuente de gb.gui.base y gb.qt5 (etiqueta 3.22.1) · **Verificado:** 2026-10

DECISIÓN CERRADA. La búsqueda del editor principal (`txtEditorProyecto`) sigue el modelo de TeXstudio: buscar, revisar cada coincidencia y escribir directamente sobre la que hay que cambiar, sin diálogo de reemplazo. Vive en FMain: `EjecutarBusqueda`, `IrAResultadoBusqueda`, `gvResultados_Click` y `ColumnaTrasEdicion`.

CADA BÚSQUEDA BUSCA DE NUEVO

No se conservan posiciones entre una búsqueda y la siguiente. Cada llamada vuelve a buscar sobre el texto actual del editor y salta a la primera coincidencia posterior a la referencia: el inicio de la selección, o el cursor si no la hay (`InicioSeleccion`, GV-65). Con selección se exige estrictamente mayor, porque la selección es la coincidencia actual; sin ella, cuenta una que empiece justo en el cursor. Si no hay ninguna más adelante, vuelve a la primera y lo avisa con sonido y mensaje; con una sola coincidencia no hay aviso.

El caso que fijó la regla: un botón «siguiente» anterior guardaba las posiciones de la búsqueda. Al escribir MMMM sobre XX en la primera coincidencia, la segunda se seleccionaba corrida dos caracteres. Se descartó.

Las posiciones absolutas se calculan con el inicio de cada línea en un solo recorrido sobre `.Text`, no con `PosicionDe` por coincidencia, que parte el texto entero en cada llamada. Todo en caracteres (RC-GM-21).

EL FOCO TERMINA EN EL EDITOR

`EjecutarBusqueda` decide el foco final; quien la llama no lo toca:

    hubo salto                          editor, con la coincidencia seleccionada
    sin coincidencias o sin término     cuadro de búsqueda, para corregirlo

Con el foco en el editor, escribir o pegar reemplaza la coincidencia, y se deshace con Ctrl+Z. Va al final del evento y después de cualquier `Message` (RC-GM-07).

Sin esta regla el foco quedaba donde se había hecho el click: en el botón o en la grilla, que no atienden ni el teclado de edición ni F3. Verificado por Alberto: Ctrl+V después de un click en el botón o en la grilla no pegaba en ningún lado.

F3 ES LA ÚNICA TECLA PARA AVANZAR

F3 en el editor o en el cuadro, Enter en el cuadro, el botón y Ctrl+F con una selección de una línea llaman todos a `EjecutarBusqueda`. Enter solo lanza la búsqueda: después el foco está en el editor, y un segundo Enter reemplazaría la coincidencia por un salto de línea. `Key.F3` existe en `gb.qt5/src/CKey.cpp` (etiqueta 3.22.1).

LA GRILLA: VUELVE A BUSCAR SI EL TEXTO CAMBIÓ

La grilla guarda las posiciones de la última búsqueda, y ahí volvería el defecto del botón descartado. Por eso la búsqueda guarda una foto del texto (`$sBusqTextoBase`), y `gvResultados_Click`:

- si el texto no cambió, salta a la fila;
- si cambió, traduce la posición de la fila al texto actual y llama a `EjecutarBusqueda` con esa posición como referencia, que rearma la grilla y la marca.

La traducción (`ColumnaTrasEdicion`) compara la línea vieja con la nueva: prefijo y sufijo comunes delimitan la zona editada. Una columna antes de la zona no se mueve; después, se corre por la diferencia de largo; dentro, va al comienzo de la zona y se busca desde ahí. Es exacta para una edición dentro de la línea, que es el caso de escribir sobre una palabra.

La fila se marca asignando `Row`, que no dispara `Click` (GV-78). El `Click` de la grilla llega diferido, después de que la grilla tomó el foco: el `SetFocus` al editor del handler gana.

LÍMITES ACEPTADOS

- Si cambió la cantidad de líneas desde la búsqueda, no hay correspondencia segura: se busca desde el comienzo de la línea con el mismo número.
- Si se cambió el término en el cuadro sin buscar, un click en la grilla con el texto editado busca con el término nuevo.

Probado por Alberto en 3.22.1: avance con F3, Enter, botón y grilla; escritura sobre una coincidencia y click en otra de la misma línea.

**Relaciones:** vinculo:SC-18,vinculo:GV-78,vinculo:RC-GM-07,vinculo:RC-GM-21,vinculo:GV-65

### SC-38 — Instrucciones de composición: solo PDF, instrucción de procesamiento gb- con ficha propia

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / LuaLaTeX / contenedor; W3C XML 1.0 (instrucciones de procesamiento) · **Verificado:** 2026-10

DECISIÓN CERRADA. Una instrucción de composición dice cómo y dónde va algo en una página concreta del PDF, no qué es: un espacio, un salto de página, una línea más en la página. LaTeX es un lenguaje de composición tipográfica además de marcado, y llevar su uso al .md trae instrucciones que no tienen equivalente en las otras salidas. Esta entrada fija las reglas comunes, para que cada instrucción nueva no se decida desde cero.

QUÉ LAS DISTINGUE

- Solo afectan al PDF. En un EPUB que reacomoda el texto no hay página que agrandar: no es una omisión de la salida digital, es la segunda excepción de SC-31.
- Pierden validez cuando cambia el texto. Una instrucción de estructura vale aunque se reescriba el párrafo; una de página deja de valer si se corre una línea arriba. Son de la última pasada.
- Habrá instrucciones dentro de la línea (un corte de línea forzado, un corte de palabra, un párrafo que pierde una línea). El mecanismo de abajo sirve también para ellas.

DE UN PUNTO Y DE UN TRAMO

- De un punto: van entre dos bloques y no tienen texto. `espaciov` (SC-39). Pierden validez cuando cambia el texto de arriba.
- De un tramo: rodean párrafos del cuerpo y dicen cómo se componen. La alineación (SC-61). No pierden validez cuando se reescribe el texto: una fecha a la derecha sigue a la derecha. Tienen en común con las de un punto que solo afectan al PDF.
- La ficha de un tramo va al comienzo de cada párrafo, no en un par apertura/cierre: el grupo de LaTeX nunca queda desbalanceado (SC-61).

LAS REGLAS

1. En el canónico van como INSTRUCCIÓN DE PROCESAMIENTO con prefijo `gb-`, nunca como elemento: `<?gb-corte?>` (SC-28, en DocBook) y `<?gb-espacio …?>` (SC-39). El estándar XML las define para eso: indicaciones para una aplicación, fuera del modelo del documento. El canónico sigue validando contra el RNG de DocBook 5.2 y la DTD de JATS 1.4 (verificado), y el PDF se puede regenerar idéntico porque la instrucción queda en él. Una instrucción de procesamiento también puede ir dentro de un párrafo.
2. Lleva una FICHA propia, no LaTeX: `bigskip`, `vspace* 2baselineskip`. Solo las hojas LaTeX la traducen (en `tex-comun.xsl` cuando la ficha es igual en JATS y en DocBook), y frenan ante una ficha que no conocen.
3. Las hojas de HTML y EPUB no hacen nada: la regla incorporada de XSLT para una instrucción de procesamiento no escribe nada (medido en SC-28 y en SC-39). Una hoja que copie con `xsl:copy-of` o con una identidad sobre `node()` sí las copiaría: hay que mirarlo en cada hoja nueva.
4. Los indexadores las quitan todas de una vez. `jats-to-scielo.xsl` y `jats-to-redalyc.xsl` parten de una identidad sobre `@* | node()`, que incluye las instrucciones de procesamiento (verificado: copiaban `<?gb-espacio?>` al paquete). Una sola plantilla vacía, `processing-instruction()[starts-with(name(), 'gb-')]`, las quita: una instrucción nueva no se filtra por olvido.
5. Diccionario cerrado, en un solo filtro Lua por instrucción, que corre en las tres cadenas (revista, libro, ODT) con el patrón de `dos-partes.lua` (SC-35). En el ODT la quita. Lo que no está en el diccionario frena la conversión con un mensaje que dice qué falla y qué se admite.
6. En el catálogo de shortcodes, grupo propio: `composicion`, «Composición (solo PDF)», al final de la lista. El editor ve en el panel que son instrucciones de página y no de contenido. El grupo entró con el esquema 5 de gbShortcodes. El modo dice qué es cada una: las de un punto se insertan como separador (`separador-valor`); las de un tramo, con `envolver`. `m_AnalizarProyecto` cuenta como cuerpo el texto de las de un tramo y no cuenta las de un punto.
7. En una hoja LaTeX, la instrucción solo se alcanza donde se la pide: `*` selecciona elementos, no instrucciones de procesamiento. `docbook-to-latex.xsl` la agrega en unión, `(* except info) | processing-instruction('gb-espacio')`, que conserva el orden del documento; `jats-to-latex.xsl` ya recorría todos los nodos de `body` y `sec`.

Una salida digital que algún día necesite una de estas instrucciones la lee del canónico igual que el PDF: la ficha no depende de LaTeX.

**Relaciones:** vinculo:SC-28,vinculo:SC-31,vinculo:SC-35,vinculo:SC-34,vinculo:SC-39,vinculo:SC-61

### SC-39 — Espacio vertical: espaciov, diccionario cerrado de comandos del PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / LuaLaTeX / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA. Primer caso de las instrucciones de composición (SC-38). Agrega o quita espacio vertical, o fuerza un salto de página, en un punto del texto. Solo PDF, de libros y de revistas.

    ::: espaciov

    \bigskip

    [/espaciov]: # ()
    :::

EL VALOR VA DIRECTO, SIN CORCHETES NI LLAVES

Medido con Pandoc 3.1.3: un comando de LaTeX solo en su línea llega como `RawBlock "tex"` con el texto exacto (`\bigskip`, `\vspace*{2\baselineskip}`). Entre corchetes llega como texto, y se confunde con el ancla de SC-33; entre llaves, el comando queda partido en tres, y las llaves son el semáforo de las dos partes (SC-35). Sin la barra es un párrafo común, y el filtro lo dice.

DICCIONARIO (espacio-vertical.lua)

    \smallskip  \medskip  \bigskip          ficha: smallskip, medskip, bigskip
    \newpage  \clearpage                    ficha: newpage, clearpage
    \cleardoublepage                       solo libros
    \vspace{L}  \vspace*{L}                 ficha: vspace L, vspace* L
    \enlargethispage{L}                    ficha: enlargethispage L

L es un número con unidad (`pt`, `mm`, `cm`, `em`, `ex`) o `N\baselineskip` (ficha `Nbaselineskip`; sin número vale 1). Puede ser negativa. El decimal va con punto: TeX admite la coma, pero se fija una sola forma.

`\vspace*` importa: un `\vspace` común desaparece al principio de una página. `\enlargethispage{\baselineskip}` gana una línea en la página, para salvar una viuda.

FRENA LA CONVERSIÓN (CÓDIGO 83, CON MENSAJE)

Un valor fuera del diccionario, una longitud mal formada, `\cleardoublepage` en una revista, un bloque vacío, con más de un bloque adentro, o sin la barra. Y un bloque que no esté en el primer nivel: dentro de otro bloque, una lista, una cita, una tabla o una nota. En revista el filtro corre después de `unwrap-structural-divs.lua`, así que dentro de una sección estructural (`::: intro`) vale. En el ODT no se controla el nivel, porque esa cadena no desenvuelve las secciones: la revista ya lo controla en la del XML.

SALIDAS

- Canónico: `<?gb-espacio bigskip?>` entre los párrafos, en JATS y en DocBook.
- PDF: la plantilla de `tex-comun.xsl` escribe el comando. Compilado con LuaLaTeX.
- HTML, EPUB, Crossref, DOAJ: nada. SciELO y Redalyc: la plantilla vacía de SC-38.
- ODT: el bloque se quita.

INSERCIÓN: MODO separador-valor

Los semáforos del separador (SC-36): sin selección y con el cursor al principio de una línea vacía. Inserta el bloque con el marcador `•` (SC-21) seleccionado en la línea del valor. Al insertar el valor todavía no existe: lo valida el filtro, que es además el único que ve lo escrito a mano. El modo es una fila de la tabla `modos` de gbShortcodes (dato, no esquema).

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de revista y de libro; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, `docbook-to-latex.xsl`, `jats-to-latex.xsl` y las seis hojas de revista; el capítulo ensamblado valida contra el RNG y el artículo contra la DTD Archiving 1.4; los comandos compilan con LuaLaTeX; gbpublisher y gbShortcodes compilan con gbc3 3.19; la migración de gbShortcodes y el alta pasaron por `importar_shortcodes.sh`.

**Relaciones:** vinculo:SC-38,vinculo:SC-33,vinculo:SC-34,vinculo:SC-35,vinculo:SC-36,vinculo:SC-21

**PENDIENTE:** Probar en Mint con un libro y una revista reales: inserción con el modo separador-valor, PDF compilado, y HTML y EPUB sin rastro. Las hojas de HTML y EPUB de libros no se corrieron sueltas (piden el manifiesto del libro): el resultado se apoya en la regla incorporada y en que no tienen identidad ni copy-of sobre el contenido.

### SC-40 — Rayas, puntos suspensivos y elisión en el .md

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1.3 / engine/limpiar_docx.lua 1.3 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). En el .md, la semirraya, la raya y los puntos suspensivos se escriben como en LaTeX:

    --     semirraya (U+2013)
    ---    raya (U+2014)
    ...    puntos suspensivos (U+2026)

Nunca el carácter Unicode. Los lectores `--from markdown` del proyecto (`m_XML`, `m_GenerarEpub`, `m_GenerarODT`) tienen `smart` activo por omisión y los vuelven a U+2013, U+2014 y U+2026 (GV-79): el canónico JATS o DocBook y todas las salidas reciben el carácter tipográfico.

POR QUÉ

Es la convención del PDF, que es la base del diseño (SC-31). Y una sola forma en el .md hace predecibles la búsqueda y el reemplazo: lo que entrega Word es impredecible, porque cada autor deja lo que tecleó o lo que el procesador autocorrigió.

INGRESO DESDE WORD

Lo normaliza `engine/limpiar_docx.lua`, desde la versión 1.2 del filtro, en una pasada sobre los `Str` del AST y no sobre el texto del .md: el código, las URL de los enlaces y la matemática no son `Str` y no se tocan. Un reemplazo sobre el .md ya escrito no tendría cómo distinguirlos.

    U+2026           ->  ...
    U+2013           ->  --
    U+2014           ->  ---
    guion aislado    ->  --     un Str que es solo «-»: entre espacios o al abrir el párrafo

El guion aislado nunca es un guion de unión: es una semirraya mal tecleada.

El escritor sigue siendo `--to=markdown-smart`. Con `+smart` el propio Pandoc haría la conversión, pero aplanaría el apóstrofo curvo, que el filtro deja a propósito, y escaparía los `--` y `...` tecleados (GV-79).

RANGOS NUMÉRICOS: GUION SIMPLE, NUNCA SEMIRRAYA

Norma de la editorial (decisión de Alberto): los rangos de páginas y de años se escriben con un solo guion, `pp. 23-55`, `1990-2000`. No es la semirraya de arriba: un guion simple no lo convierte el `smart` de Pandoc, y todas las salidas imprimen un guion.

El filtro no lo resuelve: pasa U+2013 a `--` en cualquier lugar, también entre cifras, y un guion entre cifras lo cuenta como aviso (`aviso_guion_entre_digitos`), porque sin contexto no distingue un rango de una fecha, un ISBN o un teléfono. Los rangos se llevan al guion simple con los patrones `rango-paginas` y `rango-anios` de la búsqueda con expresiones regulares (SC-51), revisando la grilla antes de reemplazar.

LLAMADA DE NOTA: DESPUÉS DEL SIGNO DE CIERRE

Norma de la editorial (decisión de Alberto), que se aparta de la RAE: la llamada de nota va después de cualquier signo de cierre, `texto.[^a]`, `«cita».[^b]`. Detrás de una llamada solo puede haber un espacio o un fin de línea.

Lo corrige el patrón `nota-despues-del-signo` de la búsqueda con expresiones regulares (SC-51), con el flag `m`:

    (?<!^)((?:\[\^[^\]\s]+\])+)((?:[.,;:!?»)\]’”*_]|-{2,3})+)   ->  $2$1

- Mueve juntos todos los signos de cierre que siguen (`[^a]».` → `».[^a]`) y todas las llamadas seguidas (`[^a][^b].` → `.[^a][^b]`). Una segunda pasada no encuentra nada.
- Signos de cierre: `. , ; : ! ? » ) ] ’ ”`, los cierres de énfasis `*` y `_`, y la raya de cierre `--` o `---`.
- No toca la definición (`[^a]:` al comienzo de línea) ni una llamada pegada a una letra o a un signo de apertura (`[^a]palabra`, `[^a](véase)`): ahí falta un espacio, y mover el carácter rompería la palabra.
- No cubre las notas en línea de Pandoc, `^[texto]`.

ELISIÓN: (...), NUNCA [...]

Norma de la editorial (decisión de Alberto): la supresión dentro de una cita se marca con puntos suspensivos entre paréntesis, `(...)`. Los corchetes quedan para las expresiones del editor, como `[sic]` o `[risas]`, que el filtro no toca.

Desde la versión 1.3, el filtro convierte la elisión entre corchetes en todas sus formas: «[...]», «[…]» (después de pasar U+2026 a `...`), pegada a la palabra o a la puntuación («palabra[…].») y con espacios adentro («[ … ]»), que el lector parte en varios `Str` y se une en uno. Vale también dentro de una cursiva o de una nota; el código en línea no se toca.

LO QUE NO SE CONVIERTE: AVISOS

El filtro cuenta, el informe de la conversión lo muestra y el texto queda como llegó:

- `aviso_guion_entre_digitos`: «10-20» puede ser un rango, pero también una fecha, un ISBN o un teléfono. Cuenta casos, no palabras.
- `aviso_guion_pegado`: un guion pegado a una palabra en posición de inciso, «-inciso-». Es una corrección mal hecha. Cuenta también el prefijo suspendido («pre- y posguerra»), que es correcto.
- `aviso_enumeracion_punto_guion`: «4.-», «a.-». Es una corrección mal hecha: en la editorial se elimina.
- `aviso_corchetes_con_puntos`: corchetes con dos puntos o con cuatro o más, «[..]», «[....]». Puede ser un error de tipeo o una marca propia del autor.

Las conversiones también tienen su clave en el informe: `elipsis_a_tres_puntos`, `semirraya_a_dos_guiones`, `raya_a_tres_guiones`, `guion_aislado_a_semirraya` y `elision_corchetes_a_parentesis`.

EXCEPCIÓN: el espacio fijo se escribe `¬`, no `~`: en Pandoc `~` es el subíndice (SC-68, GV-130).

**Relaciones:** vinculo:SC-31,apoya:GV-79,vinculo:GV-47,vinculo:SC-51,vinculo:SC-68

**PENDIENTE:** Probado en el contenedor con un .docx armado a mano, no con uno real en Mint. El contrato rige el ingreso desde Word: un carácter Unicode tecleado después en el editor no se detecta. Decidir si el escáner UTF-8 lo informa.

### SC-42 — Código: bloque cercado, listado y código en línea; el color lo pone cada salida

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1.3 (skylighting) / SaxonJ-HE 12.5 / LuaLaTeX TeX Live 2023 / Chromium / Gambas 3.19 / contenedor / Mint con Gambas 3.22.2 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisiones de Alberto). Libros y revistas.

EN EL .md

    ~~~ python
    for i in range(3):
        print(i)
    ~~~

Un bloque cercado con su lenguaje, de una lista cerrada: python, r, sql, bash, javascript, json, yaml, markdown, latex, html, xml, xslt, css, lua, docbook y jats (los dos últimos se colorean como xml) y texto, sin color. Con pie numerado, dentro de un listado:

    ::: {.listado #lst-factorial}

    ~~~ python
    …
    ~~~

    Pie del listado, con *formato* y citas.

    [/listado]: # ()
    :::

El código en línea es el de Pandoc, `así`. El viejo `::: {.code language=""}` se retiró.

CORTE MANUAL

Una línea que termina en ↩ (U+21A9) sigue en la siguiente, que sale sin número. IBM Plex Mono tiene ↩ y ↪, y no ↵ ni ⏎ (medido). El corte no es automático.

EN EL CANÓNICO

`codigo.lua` (las tres cadenas) controla y escribe: JATS `<code language>`, DocBook `<programlisting language>`; texto sin `language`. El listado: `<fig fig-type="listado">` con `<caption>` y `<code>` (cite-to-xref.lua), y `<example role="listado">` con `<title>` y `<programlisting>` (fenced-divs-to-elements-db.lua), que validan contra la DTD Archiving 1.4 y el RNG de DocBook 5.2. `<example>` y no `<figure>`: el patrón de los formales, y sin mezclarse con la cuenta de las figuras. Frena con un mensaje: bloque sin lenguaje, con más de uno o fuera de la lista; bloque suelto con #id; listado sin #lst-, sin bloque y pie, con algo más, o con el marcador • en el pie; el viejo `.code`. La referencia `@lst-` frena en libros y en revistas (SC-32), hasta su lote.

EL COLOR NO VA AL CANÓNICO

Lo pone cada salida, con el resaltador de Pandoc (skylighting), en un paso previo: `engine/colorear_codigo.sh` corre `extraer-codigo.xsl` (un `codigo-N.txt` por bloque, N la posición en el documento) y `pandoc lua colorear_codigo.lua`, que escribe `codigo-N.html` o `codigo-N.tex` con las líneas numeradas. La hoja los lee con el parámetro `codigo_dir`; si falta un archivo, se corta: no se degrada en silencio. Las seis hojas comparten las reglas en `codigo-comun.xsl` (número, texto, lenguaje, rótulo, partido en líneas y el bloque HTML) y las de LaTeX además `f:codigo-latex` en `tex-comun.xsl`. Ni listings ni minted: listings no conoce JavaScript, JSON, YAML ni Lua, y `language=JavaScript` cortaba la compilación (medido); minted exige `--shell-escape`. highlight.js, que se cargaba de un CDN en el HTML de revistas, se retiró.

POR SALIDA

- PDF de pantalla y HTML: caja oscura con la paleta Gruvbox del tema de la aplicación, rótulo del lenguaje arriba, números de línea y ↩ en gris. En el HTML el número y el ↩ los dibuja el CSS y no se copian con el código.
- PDF de libro en estado «Imprenta» (valor `publicado`; el combo decía «Publicado»): fondo blanco, texto negro, sin color; la negrita y la bastardilla de los tokens quedan. Es la quinta prestación de `PrestacionesDeSalida`, `codigocolor`. Las revistas no van a imprenta: su PDF va siempre en color.
- EPUB: fondo negro, texto blanco, sin color, número y ↩ como texto (los lectores no siempre dibujan contenido generado).
- ODT (revistas): el bloque con el resaltado claro de Pandoc; el listado, bloque y pie sin número.

EL PIE

«Código N», debajo como en las figuras. Libros: por capítulo como las figuras (contador `gbcodigo` del contrato 11, `nl:numero-listado`); revistas: 1, 2, 3. Las figuras de revista dejaron de contar los listados en HTML y EPUB.

GEMELOS

La paleta está en la sección 8 de `preambulo-contrato.tex`, su gemela en `m_XML.ObtenerPreambuloEmbebido`, el CSS de `jats-to-html.xsl` y `gbpublisher.css`; el EPUB en `gbpublisher-epub-libro.css` y `m_GenerarEpub`. La lista de lenguajes en `codigo.lua`, `codigo-comun.xsl` y `FCodigo`. La regla del ↩ en `colorear_codigo.lua` y `codigo-comun.xsl`.

INSERCIÓN

Modo `codigo` (gbShortcodes `datos-v5-005`): con selección; en bloque, `FCodigo` pide el lenguaje y, en el listado, el nombre, y la cerca lleva una tilde más que la racha más larga de adentro; el listado deja el marcador • del pie seleccionado (SC-21) y avisa si el nombre ya existe. En línea, comillas inversas, una más que las de adentro.

LOS SCRIPTS DE LIBRO SALEN DE RutaRecursos

`m_GenerarSalidasLibro` tenía fija la carpeta `/usr/share/gbpublisher/engine`: desde el IDE corría el `generar_html_libro.sh` y el `compilar_pdf_libro.sh` del paquete instalado, de otra versión. Así el HTML de libro salió sin color en la primera prueba (la hoja no recibió `codigo_dir`). Ahora la carpeta sale de `m_InicioCierre.RutaRecursos()`, como en el resto de la aplicación, y las hojas de HTML avisan si corren sin `codigo_dir`.

PROBADO EN MINT (2026-10)

PDF de pantalla y de imprenta, HTML, EPUB y ODT, en libros y en revistas; inserción desde el panel; los casos que frenan. Los tres shortcodes se liberan con `datos-v5-006` de gbShortcodes.

**Relaciones:** vinculo:SC-32,vinculo:SC-33,vinculo:SC-21,vinculo:SC-31,vinculo:SC-30,vinculo:SC-34,vinculo:RF-11,vinculo:GV-80,vinculo:RC-GM-13,vinculo:SC-57

**PENDIENTE:** Sabores JATS de revista, en la fase de revistas: SciELO (el listado como <fig> con <preformat>; validado contra el DTD Publishing 1.0 en el contenedor, falta packtools) y Redalyc (el <code> pasa tal cual; DTD sin verificar).

### SC-43 — Conversación: qandaset en libros, speech dentro de disp-quote en revistas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** DocBook 5.2 / JATS Archiving y Publishing 1.4 / Pandoc 3.1.3 / SaxonJ-HE 12.5 / pdfLaTeX TeX Live 2023 / xmllint (libxml 2.9.14) / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA (decisiones de Alberto). Libros y revistas. Entrevistas, reportajes, historia oral: todo intercambio de preguntas y respuestas con hablante. No es para obras teatrales.

EN EL .md

    ::: conversacion

    ::: {.pregunta quien="Ana Pérez"}

    ¿Cuándo empezó?

    [/pregunta]: # ()
    :::

    ::: {.respuesta quien="Juan Gómez"}

    En 1990.

    Segundo párrafo de la misma respuesta.

    [/respuesta]: # ()
    :::

    ::: acotacion

    [Se interrumpe la grabación]

    [/acotacion]: # ()
    :::

    ::: pregunta

    ¿Y después?

    [/pregunta]: # ()
    :::

    [/conversacion]: # ()
    :::

Todos los bloques con `:::` y su ancla (SC-33), también los anidados. La acotación en línea, como [risas], es texto entre corchetes sin marca: Pandoc la deja tal cual (GV-83).

LA ETIQUETA LA DECIDE EL TEXTO

Los originales suelen dar el nombre la primera vez y seguir con P. y R. El modelo es literal: el turno lleva `quien=` cuando el texto da el nombre; sin `quien`, la etiqueta por omisión, P. o R. No se configura por obra ni por colección.

EN EL CANÓNICO

- Libro: `<qandaset defaultlabel="qanda" role="conversacion">`. Cada pregunta abre una `<qandaentry>`; las respuestas que siguen son `<answer>` de esa misma entrada (varias respuestas = varios `answer`, historia oral con más de dos voces). `quien` → `<label>` del turno; sin `quien`, no hay `label` y la etiqueta la pone la hoja según `defaultlabel`. Acotación: `<para role="acotacion">`, antes de la primera entrada o como último párrafo del turno anterior: el esquema no la admite entre entradas (GV-82). Un turno admite cualquier bloque.
- Revista: `<disp-quote content-type="conversacion">`, SIEMPRE, también cuando todo el artículo es una entrevista. Cada turno, `<speech content-type="pregunta|respuesta">` con `<speaker>` = `quien` o la etiqueta por omisión: nunca vacío (GV-81). Acotación: `<p content-type="acotacion">` entre turnos. `<speaker>` en texto plano: el DTD Publishing no admite marcado de frase adentro.

QUÉ SE PIERDE EN JATS

- No hay contenedor de conversación: `disp-quote` es la aproximación.
- La distinción pregunta/respuesta no es del estándar: vive en `content-type`. Las hojas la usan; los indexadores la ignoran.
- La identidad del hablante de un turno sin nombre: `<speaker>` dice «P.», como el texto.
- Un turno solo admite párrafos (GV-81).

FRENA CON UN MENSAJE

Lo controla `conversacion.lua`, con la misma regla en las tres cadenas:

- El viejo `.speech`: se retiró; el mensaje indica pasar a `.conversacion`.
- Una conversación vacía, sin ningún turno (solo acotaciones), dentro de otra, o con algo que no sea `::: pregunta`, `::: respuesta` o `::: acotacion` (el texto suelto va dentro de un turno).
- Una respuesta sin pregunta antes (`qandaentry` exige `question`; xmllint daría un mensaje que no orienta, GV-82). En las dos cadenas: la forma del .md es una. Una acotación sí puede ir antes de la primera pregunta.
- Un turno o una acotación vacíos, con otro turno, otra acotación u otra conversación adentro, o fuera de `::: conversacion`.
- `quien=""` escrito pero vacío; `quien` en una acotación.
- Una acotación con algo que no sea un párrafo.
- Revista: un turno con algo más que párrafos (lista, cita, figura). En libro un turno admite cualquier bloque.

LA CITA BREVE NO SE MARCA

Dentro de un párrafo es tipografía: «bla bla, y Juan aseveró: «esto es lo que dijo Juan»». No hay shortcode para un turno suelto.

SE RETIRA .speech

Filtros (cite-to-xref.lua, fenced-divs-to-elements-db.lua), las seis plantillas de `speech` y `para role="speech"`, el CSS (`.speech`, `.speech-item`, `.speech-speaker`), `gbparlamento` y `\gblocutor` de `preambulo-contrato.tex`, la plantilla muerta `disp-quote[@content-type='interview']` de jats-to-latex.xsl (ningún filtro la producía) y la fila del catálogo de gbShortcodes. RC-DB-04 deja de prescribir el parlamento.

DISEÑO DE LAS SALIDAS (decisiones de Alberto)

La etiqueta va siempre en MAYÚSCULAS, en las tres salidas: ANA PÉREZ, P., R. El .md y el canónico la guardan como la escribe el texto; la pasa a mayúsculas cada hoja. En línea: la etiqueta abre el turno y el texto sigue en el mismo renglón, sin sangría francesa.

- PDF (libros y revistas): toda la conversación en sans, `\small`, corrida 14 pt a la izquierda, el mismo margen que la cita (`quote` del proyecto), sin margen a la derecha; sin sangría de primera línea. Etiqueta de peso normal. El margen es `\leftskip` y no una lista como la cita: dentro de una lista el espacio entre párrafos es `\parsep`, no `\parskip`; las notas no lo heredan (`\@parboxrestore` lo pone en cero, verificado en latex.ltx). Un espacio chico entre turnos y entre los párrafos de un mismo turno: sin sangría, es lo único que los separa. `\medskip` al abrir la conversación y al cerrarla, que da la sensación de bloque; lo pone el entorno, no se escribe a mano. La pregunta no queda sola al pie de la página (lo que daba `\paragraph` en revistas).
- HTML: la tipografía del texto, sin sangría. Etiqueta en negrita y en el azul de las hojas (`--color-accent`, #2d5a8e), la de quien pregunta y la de quien responde. Sin espacio extra al abrir y al cerrar: la interlínea, la negrita y el color hacen el trabajo.
- EPUB: como el HTML, todo en negro.

IDIOMA DE LA ETIQUETA POR OMISIÓN (decisión de Alberto: español por omisión)

Tabla cerrada: español P. y R.; inglés Q. y A. Cualquier otro idioma, o ninguno, da español. Se compara el código principal, sin región (`es-AR` es `es`).

- Revista y ODT: la etiqueta la escribe el filtro, y el idioma está en la base (`articulos.idioma_principal`). `m_XML.ArgumentoIdiomaPandoc` lo pasa como `-M gb-idioma=xx`: solo letras ASCII y guiones, si no `es`. Clave propia y no `lang`: en el ODT, `lang` cambiaría además el idioma de citeproc y del documento. `conversacion.lua` lo lee en su función `Pandoc`, con el documento entero: en una función `Div` de la misma tabla, `Meta` todavía no habría corrido (GV-84).
- Libro: nada que pasar. Sin `quien` no hay `label`, y la hoja pone la etiqueta según `defaultlabel` y el `xml:lang` más cercano al turno.

IMPLEMENTACIÓN

- `conversacion.lua`, filtro nuevo, corre en las tres cadenas: revista, después de `codigo.lua` y antes de `cite-to-xref.lua`; libro, antes de `fenced-divs-to-elements-db.lua`; ODT, después de `codigo.lua`. Controla la forma (los frenos de arriba). Busca los turnos sueltos recorriendo el documento de arriba hacia abajo sin entrar en las conversaciones (GV-85). En revista y ODT escribe en cada turno el atributo `etiqueta` (`quien` o la de la tabla).
- `cite-to-xref.lua` y `fenced-divs-to-elements-db.lua` solo serializan; frenan si `conversacion.lua` no corrió antes.
- ODT: la conversación se resuelve en párrafos; la etiqueta en negrita y mayúsculas abre el primer párrafo de cada turno; la acotación queda tal cual.
- Hojas: `conversacion-comun.xsl`, incluida por las seis, da la etiqueta (`gbv:etiqueta`, ya en mayúsculas), si el turno es pregunta y sus bloques. PDF: entorno `gbconversacion` y `\gbetiqueta` (contrato 12); después de cada pregunta, `\nopagebreak[4]` en modo vertical. HTML y EPUB: `div.conversacion`, `div.turno` con `turno-pregunta` o `turno-respuesta`, `span.turno-etiqueta` y `p.acotacion`. Un turno de libro que empieza con una lista lleva la etiqueta sola en su párrafo.
- Medido en contenedor (pdfLaTeX, 60 pares de largo variable, con `\raggedbottom`, `\clubpenalty=10000` y `\widowpenalty=10000`, como los preámbulos del proyecto): ninguna página termina con una pregunta completa; una pregunta larga puede partirse entre páginas, con dos líneas al menos de cada lado, y la respuesta sigue a su final.

GEMELOS

- La tabla de etiquetas: `conversacion.lua` y `conversacion-comun.xsl`.
- El entorno: `preambulo-contrato.tex` (contrato 12) y `m_XML.ObtenerPreambuloEmbebido`.
- El CSS: `jats-to-html.xsl` y `gbpublisher.css` (etiqueta en negrita y azul, en los dos turnos); `gbpublisher-epub-libro.css` y `m_GenerarEpub` (negrita, negro).

PROBADO EN MINT (2026-10)

PDF, HTML y EPUB, en libros y en revistas. Dos ajustes salieron de esa prueba: en el HTML la etiqueta de quien responde también va en azul, y en el PDF el bloque va corrido 14 pt a la izquierda. Los cuatro shortcodes —conversacion, pregunta, respuesta y acotacion— se liberan para libros y revistas con datos-v5-009 de gbShortcodes, por decisión de Alberto, con el ODT y el XML JATS todavía sin probar (ver el pendiente).

ALTERNATIVA DESCARTADA: LA CLASE Q-and-A

Q-and-A (Jinwen Xu, CTAN, 2023/12/19) es una CLASE de documento, no un paquete: carga einfart (ProjLib) con LuaLaTeX y no entra en el `book` de libros ni en el `article` de revistas. Lee el cuerpo como texto y lo interpreta con expresiones regulares de LaTeX3 según su propio pseudo-markdown (`##`, `::`, `==`, `>>`, comillas inversas, `[` y `"` al comienzo de párrafo), que choca con el LaTeX que escriben las hojas; su documentación advierte que no admite `\verb` y que SyncTeX no funciona. El diseño es de chat (cada turno en un tcolorbox). Leído en el .cls y el README de CTAN. Se tomó su modelo: pregunta, respuesta y nota; hablante declarado; P. y R. en español.

TAMPOCO BITS question-answer: es para evaluaciones, no para entrevistas.

**Relaciones:** vinculo:RC-DB-04,apoya:GV-81,apoya:GV-82,apoya:GV-83,vinculo:SC-33,vinculo:SC-32,vinculo:SC-31,vinculo:RF-11,apoya:GV-84,apoya:GV-85,apoya:GV-86

**PENDIENTE:** Probar el ODT (revistas) y el XML JATS: validación del canónico, sabores (SciELO, Redalyc) y packtools. Los shortcodes ya están liberados (datos-v5-009).

### SC-44 — Orden editorial de las piezas: por nombre de archivo, desde m_OrdenPiezas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.1 / MariaDB 10.11 · **Verificado:** 2026-10

DECISIÓN CERRADA. Libros y revistas. Las piezas se ordenan por su nombre de archivo, nunca por id ni por fecha de alta. El criterio está escrito en un solo lugar, `m_OrdenPiezas`, y toda consulta que liste piezas en orden editorial lo llama. Ninguna escribe su propio `CASE` por prefijo.

LA CONVENCIÓN

El nombre da la posición: `prefijo-NN-resto` (`fm-10-prologo`, `a-03-…`, `bm-99-colofon`). El prefijo fija la familia —preliminares, cuerpo, finales— y NN el lugar dentro de ella. Con dos dígitos, el orden alfabético dentro de cada familia equivale al numérico. El espacio `fm-00` a `fm-09` está reservado para las primeras (SC-25) y las piezas sueltas, como la dedicatoria (SC-45): es todo lo que va antes del sumario. `bm-00` a `bm-09`, para las piezas sueltas de finales. La regla, en Gambas, es `m_OrdenPiezas.EnEspacioReservado(sNombre)`: solo la forma de dos dígitos.

POR QUÉ NO EL ORDEN ALFABÉTICO SOLO, NI EL id

El alfabético da `a-` < `bm-` < `fm-`, exactamente el inverso del orden de lectura. El id refleja cuándo se cargó la pieza, no dónde va: las piezas no llegan juntas ni en orden.

EL MÓDULO

- `ClausulaOrden(sColumna)` devuelve el criterio sin la palabra ORDER BY: `CASE` por prefijo (`fm-` 1, `a-` 2, `bm-` 3, resto 9) y después la columna. Recibe la columna como se escribe en la consulta (`nombre_archivo`, `c.nombre_archivo`).
- `ExpresionCodigo(sColumna)` devuelve `SUBSTRING_INDEX(col, '-', 2)`: el código de posición (`fm-10-prologo` → `fm-10`). Con la columna NULL da NULL.
- Un nombre NULL o sin prefijo conocido cae en el 9: queda al final y sigue a la vista. Las consultas de salida lo excluyen con `nombre_archivo IS NOT NULL`; las grillas no, porque la pieza recién creada tiene que poder editarse.
- No va en `m_PiezasLibro`: esa es la matriz de piezas del libro por salida, y este orden vale también para los números de revista.

Lo usan `m_GenerarPDFLibro.ArmarInsumosLaTeX`, `m_GenerarEpubLibro.ListaPiezasEpub`, el manifiesto del canónico en `m_XML`, `m_GitHub.ObtenerManifiestoCapitulos` y las dos grillas de metadatos.

GRILLAS DE METADATOS

`gbCapitulos` (`FMetadatosCapitulos`) y `gbArticulos` (`FMetadatosArticulos`) siguen la misma forma:

- Columnas: id oculto (ancho 0, lo usa el `Click`), Código y Título. Tipo, Estado y Fecha no se muestran.
- El estado se lee en la consulta aunque no se muestre: `PintarEstado` colorea la celda del código con la paleta de estados que antes tenía la columna Estado.
- `gbArticulos` filtra por `id_proyecto`, el número abierto, y no por `id_revista`: con el orden por prefijo, los `a-01` de cada número quedarían mezclados.

Verificado: el orden y la extracción del código, en MariaDB 10.11 con nombres reales, un NULL y uno sin prefijo; las dos grillas, por Alberto en gbpublisher.

**Relaciones:** vinculo:SC-25,vinculo:SC-45,vinculo:SC-55

**PENDIENTE:** `m_GenerarEpub` y `m_GenerarHTML` (revistas) ordenan solo por `nombre_archivo ASC`: si un número tiene un `fm-`, queda después de los `a-`. Revisar si esos módulos ven solo artículos o si tienen que pasar a `m_OrdenPiezas`. La copia del CASE en `FMain` está comentada y no se tocó.

### SC-45 — Dedicatoria: pieza suelta de fm-00 a fm-09, antes del sumario, con el bloque del epígrafe sin filete

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / LuaLaTeX (TeX Live 2023) / SaxonJ-HE 12.5 / epubcheck 4.2.6 / Gambas 3.19 (gbc3, gbs3) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). La dedicatoria es una pieza suelta: va en el espacio reservado de preliminares, `fm-00` a `fm-09`, después de las primeras (SC-25) y ANTES del sumario. No lleva título visible ni entra al sumario.

ANTES O DESPUÉS DEL SUMARIO

Antes. Las dos tradiciones de referencia coinciden. El orden de The Chicago Manual of Style (§1.4), tomado de guías que declaran seguirlo (Pressbooks), es portadilla, portada, créditos, dedicatoria, epígrafe y recién después el sumario. En la tradición hispana (Mariana Eguaras, «Las partes de un libro»), la dedicatoria va en la pág. 7, detrás de la página legal, y el lema en la 9. La fuente que la pone después del sumario (OQLF, «pages liminaires») trata de informes y tesis, no de libros. Dedicatoria y epígrafe son el umbral personal del autor; el sumario, el comienzo del aparato del libro.

LA POSICIÓN LA DA EL NÚMERO

El espacio `fm-00` a `fm-09` es todo lo que va antes del sumario: las primeras y las piezas sueltas (dedicatoria, foto a página entera, recordatorio). `m_GenerarPDFLibro.ArmarInsumosLaTeX` (7.1b) emite `\tableofcontents` antes de la primera pieza de preliminares que no es una primera ni está en el espacio reservado. La regla del espacio, en Gambas, es `m_OrdenPiezas.EnEspacioReservado` (SC-44); en `docbook-to-latex.xsl`, `$especial`, que lee el NN del canónico.

EL CONTROL

Una dedicatoria fuera de `fm-00` a `fm-09` sale como `\chapter*`, con título, después del sumario y con entrada en él. Nada lo avisaba. Ahora `m_PiezasLibro.ProblemaPosicion(nombre, tipo)` es la regla, y la aplican dos lugares con el mismo mensaje:

- `m_Metadatos.GuardarMetadatosDeCapitulo` (apartado 2b): no guarda.
- `m_GenerarPDFLibro.VerificarPosiciones`, después de `VerificarPrimeras`: no genera.

Solo se acepta la forma de dos dígitos de la convención: `fm-4-dedicatoria` frena.

PDF (CONTRATO 13)

El tipo elige el diseño dentro del espacio reservado. La señal es el elemento `<dedication>` del canónico, que `ensamblar-capitulo-canonico.xsl` escribe para `tipo_capitulo = dedicatoria`: `docbook-to-latex.xsl` emite el entorno `gbdedicatoria` en lugar de `gbpaginaespecial`.

- Página: la de `gbpaginaespecial`. Recto, sin folio ni encabezado, vuelta en blanco; sin título y fuera del sumario.
- Bloque: el de `\gbepigrafe` sin atribución, que es el que no lleva filete (SC-35): 60 % de la columna, a la derecha, `\small`, en bandera, sin corte de palabra. `gbdedicatoria` es gemela de `\gbepigrafe`: un cambio de diseño del epígrafe va en las dos.
- Bajada: `\gbBajadaDedicatoria`, de la estética (30 mm), con el mismo recurso que la portadilla (`\hbox{}\vspace`). Medida: la primera línea queda 34,8 mm por debajo de la primera línea de una página corriente, es decir 30 mm más una línea; idéntico a `\vspace*{30mm}`.
- La minipage va con `[t]`: la bajada se mide igual con una línea que con cinco.

LA UBICACIÓN VA EN EL CANÓNICO DE LA PIEZA

`docbook-to-latex.xsl` decide la página suelta con `seccion-libro` y `orden-seccion` del `<info>`. El PDF transforma el canónico de CADA PIEZA (`jats/c-….xml`), y esos datos solo los escribía `ensamblar-libro-canonico.xsl` en el canónico del LIBRO: la rama de página suelta no se activaba nunca, para ninguna pieza de fm-0N o bm-0N. La primera prueba no lo mostró porque usó un canónico armado a mano.

Ahora `m_XML.GenerarInfoCapituloXML` (bloque 2b) escribe en el `<info>` de cada pieza `seccion-libro` y `orden-seccion`, derivados del nombre con la misma regla que el ensamblador del libro (`prefijo-NN-resto`), y `tipo-capitulo` si no es NULL ni vacío (RC-XJ-02). `ensamblar-libro-canonico.xsl` los descarta al copiar el `<info>` y los vuelve a escribir desde el manifiesto: sin ese filtro quedan dos de cada uno y `normalize-space()` sobre dos nodos frena las hojas de salida.

`tipo-capitulo` en el canónico de la pieza no cambia la numeración: `docbook-to-latex.xsl` y `numeracion-libro.xsl` lo prefieren al elemento, y `ensamblar-capitulo-canonico.xsl` deriva el elemento y su role del mismo `tipo_capitulo`.

Al instalar hay que regenerar los canónicos de las piezas: los viejos no traen la ubicación.

EPUB

- `docbook-to-epub.xsl`: plantilla propia para la raíz `<dedication>`, como la bibliografía. `section` con `epub:type="dedication"` (EPUB SSV 1.1) y `role="doc-dedication"` (DPUB-ARIA 1.1, superclase section, nombre del autor permitido). Sin `<h1>`: el título del canónico queda en `aria-label` y en el `<title>`. Adentro, `div.epigrafe` con `p.epigrafe-texto`.
- `gbpublisher-epub-libro.css`: `.dedicatoria { padding-top: 8.5em }`. Son los 30 mm del PDF sobre un cuerpo de 10 pt. En em y no en mm ni vh: la pantalla no tiene tope de caja y los lectores paginados no respetan vh de forma pareja. Va en la sección y no en `.epigrafe`, donde el em sería el de la letra menor.
- Sigue en el spine, después de los créditos, pero no en el nav: `m_GenerarEpubLibro.ArmarNav` la salta con `m_PiezasLibro.VaEnIndice`.

HTML

- La dedicatoria no tiene página propia: el HTML se recorre desde el índice de la página de entrada, y una página fuera del índice quedaría sin enlace. Va en `index.html`, antes del índice, como en el PDF va antes del sumario: `section.dedicatoria` con `role="doc-dedication"` y `aria-label`, y el mismo `div.epigrafe`.
- El índice de preliminares la excluye por `@tipo_capitulo` del manifiesto: la misma regla que `m_PiezasLibro.VaEnIndice`.
- Sin la bajada: en una página que se desplaza no hay tope de caja (excepción 2 de SC-31).

FUERA DE ESTA DECISIÓN

Las otras piezas sueltas (foto, recordatorio) siguen saliendo con título en EPUB y HTML (decisión de Alberto).

**Relaciones:** vinculo:SC-25,vinculo:SC-44,vinculo:SC-35,vinculo:SC-31

**PENDIENTE:** Probado en el contenedor con la cadena real: GenerarInfoCapituloXML contra MariaDB 10.11, Pandoc 3.1.3 con los filtros del proyecto, ensamblar-capitulo-canonico.xsl y docbook-to-latex.xsl; el PDF compilado con los preámbulos reales (dedicatoria en vii sin título ni entrada en el sumario, vuelta en blanco, sumario después). El canónico de la pieza y el del libro validan contra el RNG de DocBook 5.2 (jing). El EPUB mínimo pasa epubcheck 4.2.6; el index.html de un libro de prueba; gbc3 compila el proyecto. Falta en Mint con un libro real.

### SC-46 — Análisis del proyecto: el conteo sale del AST de Pandoc, sin los filtros de producción

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / Pandoc 3.1.3 · **Verificado:** 2026-10

DECISIÓN CERRADA para la solapa «Escanear» de FMain (`gvAnalizarProyecto`, `btnAnalizarProyecto`, `btnCancelarAnalizar`).

QUÉ CUENTA CADA PARTE

- `engine/analizar_proyecto.lua` recorre el AST y emite un registro por línea, campos separados por NUL. No modifica el documento. El protocolo está en la cabecera del filtro y no se cambia de un lado solo.
- `m_AnalizarProyecto` lanza Pandoc, agrega los registros, decide el destino de cada texto con el catálogo de shortcodes (RF-11), cruza las claves con el `.bib` y arma la grilla. `CAnalisisArchivo` guarda los conteos de un archivo o del total.
- perl queda para la parte léxica (oraciones, frecuencias): en Lua no se puede (GV-88). El control de cercanía de `m_EscanerTipografico` ya cubre los ecos.

POR QUÉ EL AST Y NO EL TEXTO

Es el mismo lector que genera el XML: un título que el análisis no cuenta tampoco se publica. Con regex, sobre el Markdown o en Gambas, habría que reimplementar el parser.

POR QUÉ SIN LOS FILTROS DE PRODUCCIÓN

`cite-to-xref`, `cite-to-biblioref-db` y `fenced-divs-to-elements-db` serializan el contenido con `pandoc.write` y dejan XML crudo, sin palabras que contar. `dos-partes`, `recuadros`, `codigo` y `conversacion` frenan ante un bloque mal formado, y el análisis se usa sobre borradores. Que un bloque esté bien formado lo controla la producción. Los shortcodes no son un preproceso: son divs y spans con clase, y el lector solo ya los trae.

INVOCACIÓN

- Un proceso por archivo: Pandoc concatena las entradas y se perdería la columna.
- `pandoc ARCHIVO --from markdown --to plain --lua-filter <filtro> --output /dev/null`, con `Exec` y array (SC-05).
- La bibliografía, aparte: un YAML temporal con `nocite` como entrada, `--bibliography referencias/ref-<proyecto>.bib` y `--metadata gb-analisis=bib` (GV-87).
- Asíncrono y cancelable con el patrón de `m_AuditarJats.EjecutarHerramienta`: la sentencia `Wait` entra al bucle de eventos.
- La lista de archivos es `m_BuscarRegex.ObtenerArchivosMD()`, la definición única del proyecto.

CRITERIOS

- Palabra: un `Str` con al menos una letra o un dígito. No cuentan fórmulas, código, el texto de las citas ni el alt de las imágenes (GV-89).
- Destino por la clase del div que contiene el texto: grupo `estructura` del catálogo, cuerpo; `fig` y `table`, pie; grupo `composicion` (`espaciov`), no se cuenta; cualquier otra clase, «bloque especial».
- Párrafo: `Para` del cuerpo. No lo son los ítems de lista, los párrafos de notas y citas en bloque, ni los de bloques especiales.
- Índice de Price: entradas citadas, presentes en el `.bib` y con año, publicadas en los últimos cinco años calendario contando el en curso.

ESTIMACIÓN DE PÁGINAS

Dato empírico del editor, medido sobre muchos libros: 2200 caracteres con espacios por página de libro. En un mismo libro hay páginas de 2400 (llena, da el mínimo) y de 1900 (rala, da el máximo). Pliego de 32 páginas, 16 por cara. Redondeo hacia arriba. Es estimación de texto solo: no reserva lugar para figuras ni tablas, y la grilla lo dice. Las constantes viven en un solo lugar del módulo; pasan a la configuración solo si una colección con otra caja las necesita.

Verificado: compilado con gbc3 3.19 y ejecutado con el módulo, el catálogo y el filtro reales (archivo ilegible y cancelación incluidos); el editor generó el .deb, lo instaló y la prueba sobre un proyecto real funcionó en 3.22.

ESPACIO FIJO: un Str se parte en `¬` y en U+00A0 antes de contar (SC-68): «siglo¬XX» son dos palabras y un espacio impreso.

**Relaciones:** vinculo:SC-05,vinculo:SC-11,vinculo:RF-11,vinculo:GV-85,vinculo:SC-47,vinculo:SC-68

### SC-47 — Análisis léxico: oraciones y variantes en perl, sobre el texto que separó el AST

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / Pandoc 3.1.3 / Perl 5.38 · **Verificado:** 2026-10

DECISIÓN CERRADA. Segunda parte del análisis del proyecto (SC-46): ORACIONES del cuerpo y VARIANTES de una misma palabra en todo el proyecto.

QUIÉN HACE QUÉ

- `engine/analizar_proyecto.lua`, con `--metadata gb-texto=RUTA`, escribe además el texto de cada bloque en RUTA, una línea por bloque: `ctx TAB clase TAB parrafo TAB texto`. Perl NO vuelve a leer el Markdown: recibe el texto que el AST ya separó, sin citas, notas, fórmulas ni código.
- `engine/analizar_lexico.pl` corre UNA SOLA VEZ sobre todos los archivos, al final: las variantes se comparan entre capítulos. Recibe `abreviaturas tildes clases_cuerpo` y luego pares `nombre texto`.
- `m_AnalizarProyecto` arma la carpeta temporal, pasa como clases de cuerpo las presentes en el proyecto que `Destino()` clasifica como cuerpo (el mismo criterio de párrafo que la grilla), lee la salida y la borra.
- Lua no sirve para esto: sus patrones no reconocen letras fuera de ASCII (GV-88).

ORACIONES

Una oración termina en . ? ! o … (con cierres « » ” ’ ) ] detrás) SOLO si la palabra que sigue empieza con mayúscula; admite antes ¿ ¡ « “ ( [ —. No cortan:

- las abreviaturas de `engine/analizar_lexico_abreviaturas.txt` (tratamientos y remisiones que suelen ir seguidos de mayúscula: Dr., Sra., cf., ed., EE. UU.);
- las iniciales de una letra (J. L. Borges);
- un número o una minúscula detrás (p. 23, vol. 3, a. C.): no hace falta listarlas.

La lista es PROPIA DEL PROYECTO: el apéndice de abreviaturas del DPD, que era la fuente prevista, ya no está en línea (la dirección redirige a la portada). «etc.» no se lista a propósito: al final de oración su punto también la cierra.

Se miden solo las oraciones de los párrafos del cuerpo. La mediana va por dos (`mediana_x2`), siempre entera, para no depender del separador decimal regional.

VARIANTES: TRES CLASES, CON FILTROS

Quitar las tildes y agrupar NO sirve en castellano: medido sobre `docs/corpus.md`, dio 99 grupos de tilde y 773 de mayúscula, casi todos pares correctos (como/cómo, el/él, cambio/cambió) o mayúsculas de comienzo de oración.

- Guion: on-line/online. Clave: la forma sin guiones.
- Mayúscula dentro de la oración: Estado/estado. No cuentan la primera palabra de la oración, las palabras escritas todas en mayúsculas ni los títulos.
- Tilde: SOLO la lista cerrada de `engine/analizar_lexico_tildes.txt`. Optativas (solo, demostrativos): se informan si aparecen las dos formas. Suprimidas (esto, eso, aquello; guion, truhan y los demás monosílabos de la Ortografía 2010): se informa toda aparición con tilde. Fuentes en la cabecera del archivo: RAE, Libro de estilo, «Acentuación», y Ortografía, «Palabras con diptongo».
- La falta de tilde en general (boton/botón) NO es variante: la detecta el corrector ortográfico.
- Las citas en bloque NO se analizan: respetan la grafía del original.

No se usa `Unicode::Normalize`: con la lista cerrada no hace falta quitar tildes.

SALIDA Y PRESENTACIÓN

Registros por línea, campos por NUL: `O` por archivo, `OT` total, `V` por forma de cada grupo, `X` por oración de ejemplo (hasta 8 por forma). La grilla suma la sección LÉXICO; las variantes van a `FVariantes` (SC-48).

DEPENDENCIA: el paquete `perl` completo (GV-90).

Verificado: banco con el módulo, el formulario, el filtro y el script reales; el editor lo probó en 3.22 sobre un libro real.

**Relaciones:** vinculo:SC-46,vinculo:SC-05,vinculo:GV-88,vinculo:GV-90,vinculo:SC-48

### SC-48 — Ir de un resultado al editor: buscar en el texto actual, no guardar posiciones

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 · **Verificado:** 2026-10

DECISIÓN CERRADA. Para llevar al usuario desde un resultado al lugar en el editor, se BUSCA en el texto que el editor tiene en ese momento. No se guardan posiciones al analizar: mientras se corrige, quedarían viejas. Además, lo que sale del AST no tiene número de línea (GV-91).

EL PATRÓN, como lo aplica `m_AnalizarProyecto.IrAEjemplo`:

1. Abrir el archivo SOLO si no es el que está en el editor, con `m_Estructura.AbrirArchivo(sRel)`: pasa por el combo, con el aviso de cambios sin guardar (SC-06) y sin la recarga inútil de GV-53. Si ya está abierto no se la llama: preguntaría sin motivo. Es pública para esto: es la única forma de abrir un archivo del proyecto desde otro módulo.
2. Buscar con `m_FuncionesGenericas.BuscarEnTexto` sobre `m_EditorPrincipal.Texto()`, distinguiendo mayúsculas y como palabra completa.
3. Si hay varias apariciones, elegir la del párrafo que contiene el comienzo del contexto (las cuatro primeras palabras de la oración de ejemplo). Si ninguno lo contiene —una cursiva o una cita `[@clave]` en el medio cambian el texto del `.md`—, la primera.
4. Saltar con `m_EditorPrincipal.IrA(PosicionDe(línea, columna), largo)`, dejar la forma en `txtBuscarPalabra` para seguir con F3, y poner el foco en el editor.

LA VENTANA

No modal y encima del principal: `Show` y `TopOnly = True`, como `FOrtografia`. Una sola: el módulo guarda la referencia y la suelta cuando la ventana avisa que se cerró. Muestra la hora del análisis y tiene «Actualizar». Se recarga al terminar un análisis nuevo y se cierra al cancelarlo o al cerrar o cambiar de proyecto. Cada análisis crea arrays NUEVOS en lugar de vaciar los viejos: una ventana abierta conserva los suyos hasta que se la recarga.

El salto va en `Click` de la grilla de ejemplos, no en `Select`: asignar `Row` dispara `Select` pero nunca `Click` (GV-78), así que llenar la grilla no mueve el editor.

Verificado en banco con las funciones reales (`AbrirArchivo`, `BuscarEnTexto`, `PosicionDe`): mismo archivo sin aviso, otro archivo con un aviso, elección de la segunda aparición por el contexto, cierre con `Detener`. El editor lo probó en 3.22.

**Relaciones:** vinculo:SC-47,vinculo:GV-91,vinculo:SC-06,vinculo:GV-53,vinculo:GV-78

### SC-49 — Verso: estrofas, versos y sangría por patrón; el paquete verse en el PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / LuaLaTeX, TeX Live 2023, verse 2.4a / xmllint (RNG DocBook 5.2, DTD JATS Archiving 1.4) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). El verso se escribe con un verso por línea y las estrofas separadas por una línea en blanco. La sangría se da con un PATRÓN en la apertura, no con espacios en el texto:

    ::: {.verse patron="01"}

    Caminante, son tus *huellas*
    el camino y nada más;

    caminante, no hay camino,
    se hace camino al andar.

    [/verse]: # ()
    :::

EL PATRÓN

- Un dígito por verso: cuántas sangrías lleva, de 0 a 9.
- Un grupo vale para todas las estrofas, empezando de nuevo en cada una. Varios, separados por espacio, van uno por estrofa (un soneto: `patron="0110 0110 010 010"`). Otra cantidad de grupos frena.
- Los versos que exceden su grupo van sin sangría, como en `patverse`.
- `patron="alterno"`: los versos pares de cada estrofa, una sangría (el `altverse` del paquete).
- A diferencia de `patverse`, el primer dígito CUENTA: el paquete lo ignora siempre; acá no se usa `patverse` (ver PDF).
- Sin patrón, todo a cero.

El patrón es solo la forma de escribir. El canónico guarda el nivel de cada verso, y ninguna salida interpreta patrones.

Se descartó el bloque de líneas de Pandoc (`| ` al principio de cada verso): obliga a marcar cada línea y a fijar cuántos espacios son un nivel.

QUIÉN HACE QUÉ

- `verso.lua` controla y normaliza, con una sola regla para las tres cadenas (revista, libro y ODT), después de `conversacion.lua`. Deja un Div `.estrofa` por estrofa y un Div `.linea` por verso con el atributo `nivel`. Una marca que cruza versos (una bastardilla de dos versos) se parte en dos marcas iguales: ningún elemento del canónico cruza un fin de verso. Las notas, las citas, el código y las fórmulas no se parten.
- `cite-to-xref.lua` (revista) y `fenced-divs-to-elements-db.lua` (libro) solo serializan.
- `verso-comun.xsl`, incluido en las seis hojas como `conversacion-comun.xsl`, dice cuáles son las estrofas de un poema, los versos de una estrofa y el nivel de cada verso. Devuelve los nodos del canónico, no copias: las notas y las citas se numeran y resuelven en su lugar.

FRENA LA CONVERSIÓN, CON UN MENSAJE QUE CITA EL BLOQUE

- Algo que no es una estrofa: una lista, un título, una cita. El caso típico es una estrofa que empieza con «- », «# », «> » o «1. »; se escribe `\-`, `\#`, `\>` o `1\.`. En medio de la estrofa no pasa: Pandoc no abre una lista dentro de un párrafo (medido).
- Un verso dentro de otro, un verso vacío.
- Un identificador, otra clase u otro atributo que `patron` (un «patrón» con tilde también): se perderían sin aviso.
- Un patrón que no es `alterno` ni grupos de dígitos, o con una cantidad de grupos que no es uno ni la de estrofas.

EL CANÓNICO

- DocBook 5.2 base no tiene `<poetry>` ni `<line>` (RC-DB-04): `<blockquote role="verso">` con un `<literallayout role="verse">` por estrofa; cada verso, un `<phrase role="linea">`, con dos espacios por nivel delante. `<literallayout>` reproduce los espacios tal cual, así que cualquier procesador DocBook muestra la sangría. El `<phrase>` permite tomar el verso con sus marcas. El fin de verso se escribe `&#10;` y no como salto: el escritor DocBook de Pandoc sangra cada línea de un RawBlock según la profundidad de la sección, y esa sangría se sumaría a la del verso (GV-95). Valida contra el RNG de 5.2, con una nota adentro.
- JATS 1.4: `<verse-group>` (el poema) con un `<verse-group>` por estrofa, aunque haya una sola; cada verso, un `<verse-line>` con `indent-level` si lleva sangría. Valida contra la DTD Archiving 1.4; `<verse-line>` admite énfasis, `<xref>` y `<fn>`.
- Un canónico de libro anterior a esta decisión (`<literallayout role="verse">` sin `<phrase>`) frena las hojas con un mensaje: hay que regenerar el XML.

PDF (CONTRATO 14)

El paquete `verse` de Peter Wilson (en Mint, la 2.4a de 2009; lo que se usa existe desde la 2.2). Lo carga el contrato de libros y el preámbulo de revistas (`m_XML.ObtenerPreambuloEmbebido`), gemelos; en revistas reemplaza el `verse` que se redefinía ahí.

- Cada verso termina en `\\`; el último de cada estrofa, en `\\!`, que deja `\stanzaskip` (0,75 de línea); el último del poema, en nada.
- La sangría es `\vin` (`\vgap`, 1,5 em) una vez por nivel, delante del verso. Un verso que no entra sigue a `\vindent` (3 em) del margen del poema.
- Cada verso empieza con `\relax`: `\\` lee el carácter que sigue, y un verso que empieza con [, * o ! se rompería (GV-93).
- `gbverso`: el poema, en bastardilla, a `\leftmargini` del margen (2,5 em en libros; 14 pt en revistas, como la cita).
- `gbversoepigrafe`: el verso de un epígrafe, dentro del primer argumento de `\gbepigrafe`, con la letra del epígrafe y sin margen ni `\topsep` propios (GV-94).
- `\poemtitle` y la numeración no se usan (ver DIFERIDO).

HTML Y EPUB

`div.verso` con un `div.estrofa` por estrofa y un `span.verso-linea` por verso; la sangría es la clase `nivel-N`. El CSS reproduce el PDF: bastardilla, 0,75 em entre estrofas, cada verso un bloque con `padding-left: 3em` y `text-indent` de -3 em más 1,5 em por nivel, así que la primera línea queda en su sangría y la continuación a 3 em. En un epígrafe, `div.verso.verso-epigrafe`: la letra del epígrafe, sin bastardilla ni margen. Mismas reglas en `gbpublisher.css`, `gbpublisher-epub-libro.css`, `jats-to-html.xsl` y `m_GenerarEpub`; las clases son las mismas en libros y revistas. Antes eran `verse-group` y `verse-line` en revistas, con diseños distintos en cada salida y un filete a la izquierda en libros.

ODT

`verso.lua` lo resuelve en un párrafo por estrofa, con salto de línea entre versos y la sangría como un espacio eme y uno ene por nivel (1,5 em). Sin estilo propio: el ODT es para revisar.

EN UN EPÍGRAFE

El verso puede ser la primera parte del epígrafe (SC-35), solo, con las llaves en su propio párrafo y líneas en blanco alrededor (GV-92):

    ::: epigraph

    {

    ::: {.verse patron="01"}

    Versos…

    [/verse]: # ()
    :::

    }{Atribución}

    [/epigraph]: # ()
    :::

`dos-partes.lua` lo acepta y lo marca con la clase `en-epigrafe`: con ella `fenced-divs-to-elements-db.lua` emite los `<literallayout>` sin el `<blockquote>`, que `<epigraph>` no admite. JATS no cambia: `<disp-quote>` admite `<verse-group>`. Frena si el verso va con prosa al lado, si hay dos, si quedó fuera de las llaves o si está en la atribución.

DIFERIDO (decisión de Alberto: se encara más adelante)

    función                    PDF          HTML/EPUB              JATS                    DocBook base
    numeración de versos       \poemlines   contar en el XSLT;     sin lugar: verse-line   sin lugar: no hay
    y primer número                         margen angosto en EPUB no admite label         elemento por verso
    remisión a un verso        \label/\ref  ancla y enlace         id en verse-line + xref anchor en el phrase
    \flagverse (marca de       nativo       posible                label del verse-group   sin lugar
    estrofa)                                                       de la estrofa
    \\> (un verso en dos       nativo       br con sangría         no se puede expresar    no se puede expresar
    renglones)
    título y atribución del    \poemtitle*  h o p con clase        verse-group/title       blockquote/title y
    poema suelto                                                   y attrib                attribution
    poema en el sumario        \poemtitle   nav                    —                       —                (choca con SC-25)

El título y la atribución en Markdown pedirían el formato de dos partes (un atributo no admite bastardilla). Hoy la atribución la da el epígrafe, y en el cuerpo la referencia va en la prosa.

FUERA DE ESTA DECISIÓN

La dedicatoria en verso (SC-45). Es un caso casi atípico en libros y revistas científicos: si aparece, se resuelve en ese momento con una solución puntual, sin redefinir el modelo (decisión de Alberto).

Los saltos de línea manuales en prosa (barra invertida o dos espacios al final de la línea) NO sirven hoy para eso. Medido con Pandoc 3.1.3:

    libro (DocBook)     el párrafo entero sale como <literallayout> sin role:
                        el PDF lo compone en verbatim y el HTML en <pre>
    revista (JATS)      el salto se pierde: queda un espacio
    epígrafe            el salto se pierde en los dos productos

Queda registrado para no usar ese camino creyendo que funciona.

**Relaciones:** vinculo:RC-DB-04,vinculo:SC-35,vinculo:SC-33,vinculo:SC-34,vinculo:SC-43,vinculo:SC-45,vinculo:SC-25,vinculo:RF-11,vinculo:GV-92,vinculo:GV-93,vinculo:GV-94,vinculo:GV-95,vinculo:GV-85,vinculo:GV-86

**PENDIENTE:** Probado en Mint (2026-10) con prueba-verso.md: PDF, HTML y EPUB en libros y revistas, correctos; el shortcode se liberó (gbShortcodes datos-v5-011). Falta: el ODT; la inserción desde el panel; los casos que frenan (prueba/frena); epubcheck sobre un EPUB completo. El XML JATS, sus sabores (SciELO, Redalyc) y packtools con un verse-group se prueban en la fase de JATS, cuando estén todos los shortcodes desarrollados (decisión de Alberto).

### SC-50 — Aplicaciones satélite de gbpublisher: un solo modelo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbCorpus 0.0.8 / gbShortcodes 0.0.5 (esquema 5) / Gambas 3.22.1 / Linux Mint; código de los dos repositorios · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). gbCorpus, gbShortcodes y gbAyudas son aplicaciones satélite de gbpublisher y siguen un solo modelo, descrito acá. Lo propio de cada una —su base y su contrato de exportación— está en su entrada de referencia: RF-08, RF-11 y SC-24.

QUÉ SON

Programas aparte, en Gambas 3 y SQLite, que mantienen fuera de la base MySQL datos que gbpublisher consume o que gobiernan su desarrollo. Cada uno tiene su repositorio en GitHub (`albertomoyano/gbCorpus`, `albertomoyano/gbShortcodes`), su paquete `.deb` y licencia GPL v3.

    aplicación     base                                 exporta a gbpublisher
    gbCorpus       ~/.gbcorpus/corpus.sqlite            docs/corpus.md (perfil documental)
    gbShortcodes   ~/.gbshortcodes/shortcodes.sqlite    .hidden/shortcodes/
    gbAyudas       a definir (SC-24)                    .hidden/ayudas/

gbAyudas todavía no existe: cuando se construya, sigue esta entrada.

LA BASE

- Un archivo SQLite en una carpeta oculta del usuario: la aplicación puede instalarse en `/usr/bin` y la base sigue en un lugar escribible. Para moverla entre máquinas se copia la carpeta; una sola copia válida por vez.
- La tabla `esquema_version`. La aplicación la compara con su `m_Base.VERSION_ESQUEMA` y no abre una base de otra versión.
- En el primer arranque la aplicación crea la base: gbCorpus con las familias sembradas; gbShortcodes vacía, y ofrece la carga inicial.
- `PRAGMA foreign_keys = ON` en cada apertura, en la aplicación y en el importador (GV-30): sin eso las claves foráneas no se controlan.

ALCANCE: LA APLICACIÓN LEE, PULE Y EXPORTA

La aplicación consulta, navega, pule los textos y exporta. No da de alta ni elimina, y no cambia el comportamiento de lo que guarda. Las altas, las bajas, los cambios de estado y de comportamiento se acuerdan en la conversación y se aplican por script SQL. Una herramienta que crea reglas con un botón termina llena de reglas que nadie decidió.

La excepción está decidida en SC-24: gbAyudas da de alta y de baja, porque es el editor de las ayudas.

EL IMPORTADOR

`engine/importar_<aplicación>.sh` (`importar_corpus.sh`, `importar_shortcodes.sh`). Se lanza con «Importar UPDATE SQL» y corre en la pestaña Terminal (SC-13); también funciona en una terminal cualquiera. Correr el `.sql` a mano con `sqlite3` saltea el respaldo y todas las verificaciones: no se hace.

Lo que el importador ya garantiza, y el script no repite:

- Antes de escribir: `sqlite3` presente, base legible e íntegra (`integrity_check`) y `esquema_version` igual a la que maneja el importador.
- Respaldo con `VACUUM INTO` en la carpeta `respaldos` junto a la base, con rotación de 20.
- Antepone `PRAGMA foreign_keys = ON`, `.bail on` y `.changes on`: el primer error detiene todo y SQLite deshace la transacción abierta.
- Después: integridad y `foreign_key_check`. gbCorpus revisa además los vínculos de `relaciones` a códigos inexistentes y lista las entradas escritas en la corrida; gbShortcodes compara una huella del contenido antes y después, no solo la cantidad de filas.
- Código de salida: 0 aplicado, 1 no aplicado. Tras un fallo comprueba si la base quedó como estaba; no lo afirma sin mirar (SC-13).

EL SCRIPT

Lo que debe traer:

- Una cabecera de comentarios que diga qué hace, qué da de alta y qué modifica. El importador la muestra antes de pedir confirmación. Sin instrucciones para correrlo por línea de comando.
- La línea `-- Esquema: N`, con la versión de la base para la que se escribió (hoy, 1 en gbCorpus y 5 en gbShortcodes). Si falta, el importador avisa; si no coincide con la base, aborta.
- Su propia transacción, `BEGIN TRANSACTION;` … `COMMIT;`, para que las verificaciones propias queden dentro.
- Verificaciones de lo que el importador no puede saber: que un código o un nombre nuevo esté libre, que un texto a reemplazar exista exactamente una vez, que un `UPDATE` se haya aplicado. Patrón: tabla temporal con `CHECK (ok = 1)`; un `INSERT` que da 0 hace fallar la sentencia, `.bail` la detiene y la transacción se deshace.
- `fecha_alta` y `fecha_modificacion` con `datetime('now','localtime')`. El importador aísla lo escrito en la corrida comparando contra un sello de ese mismo reloj; con `date('now')` no puede.
- Las convenciones de la base de destino: en gbCorpus, las de RF-08 (`orden = numero * 10`; `cuerpo` y `relaciones` nunca NULL; relaciones como pares `tipo:CODIGO`); en gbShortcodes, las restricciones de RF-11.
- Literales con las comillas simples duplicadas, generados con un programa y no a mano: un apóstrofe sin duplicar corta la sentencia.

Se admite un `SELECT` final de resumen: su salida aparece en el informe.

Lo que no debe traer: `PRAGMA foreign_keys`, que el importador ya emite y que dentro de una transacción no tiene efecto, ni una comprobación de `esquema_version`, que el importador hace contra la cabecera.

MIGRACIONES DE ESQUEMA

Una migración lleva en la cabecera, además de `-- Esquema: N` (la versión de partida),

    -- Migración: N a M

El importador la acepta solo si la base está en N y él maneja M, y al terminar comprueba que la base quedó en M. Un importador maneja una sola versión: rechaza un script declarado para otra. Por eso los scripts de datos de una versión se aplican antes de migrar a la siguiente, y un cambio de datos que la migración necesita va dentro de la migración.

La aplicación no abre una base de una versión anterior. Si está una versión atrás, ofrece «Migrar» y corre su propio importador con su propio script de migración en la pestaña Terminal. Al abrir una base vacía, ofrece la carga inicial.

Hoy solo gbShortcodes cambió de esquema (va por la 5; el detalle de cada migración está en RF-11). gbCorpus sigue en la 1 y su importador no tiene migraciones: si sube de versión, adopta este mismo mecanismo.

NOMBRES Y LUGARES DE LOS SCRIPTS

    gbCorpus       gbcorpus-act-NN.sql                    raíz del repositorio
    gbShortcodes   datos/datos-vN-NNN.sql                 cambios de datos
                   .hidden/esquema/esquema-vN-a-vM.sql    migraciones
                   .hidden/esquema/carga-inicial.sql      catálogo completo para una base nueva

- En gbCorpus el número es un contador simple, independiente de los códigos de las entradas.
- En gbShortcodes el número va dentro de su versión de esquema: el nombre dice a qué versión va y en qué orden. La diferencia con gbCorpus es deliberada: gbShortcodes cambia de esquema y su importador rechaza los scripts de otra versión.
- `datos/` no viaja en el paquete y la aplicación no lo lee: un script de datos se importa a mano. `.hidden/esquema/` sí viaja: la aplicación lee de ahí la migración y la carga inicial.
- La carga inicial se regenera en cada versión de esquema: una base nueva no puede aplicar scripts de una versión anterior.
- Los scripts aplicados quedan en el repositorio. El número más alto es el último aplicado, y de ahí sale el siguiente.
- Los nombres anteriores (`corpus-alta-*.sql`, `gbshortcodes-act-*.sql`, `gbshortcodes-migrar-*.sql`) son históricos y no se usan más.

RECURSOS QUE VIAJAN CON EL PROGRAMA

El importador, las migraciones y la carga inicial se buscan primero en `.hidden/` del proyecto y después en `/usr/share/<aplicación>/`. Desde el IDE, `Application.Path` es la carpeta del proyecto y se usa el recurso del proyecto; instalada, es `/usr/bin`, la búsqueda en el proyecto falla y se usa el del sistema. Así siempre corren los de la versión en ejecución: con el orden inverso, el IDE usaría el del paquete instalado, que puede ser de otra versión. Si no está en ninguno de los dos lugares, el mensaje muestra las dos rutas. Es el criterio de SC-11, y estos recursos no se copian a la carpeta del usuario.

Todo lo que la aplicación instalada busca en `/usr/share/<aplicación>/` tiene que estar en los archivos extra del paquete (`ExtraFiles` del `.project`), una carpeta de `.hidden/` por línea, con el formato de gbpublisher:

    ExtraFiles=*:"engine\t/usr/share/gbshortcodes\nesquema\t/usr/share/gbshortcodes"

EXPORTACIÓN

Determinista: orden fijo y sin fecha de generación. Dos exportaciones del mismo contenido dan archivos idénticos, y el diff de git muestra solo lo que cambió. Cada aplicación exporta además un volcado SQL restaurable, en texto, como respaldo que se puede comparar en git.

La carpeta de destino dentro de gbpublisher entra entera al `.deb`. Por eso la exportación la deja igual a la base: gbShortcodes ofrece borrar lo que no es del catálogo, y gbAyudas hace lo mismo (SC-24).

COTEJO ANTES DE ESCRIBIR UN SCRIPT

El estado vigente se lee de dos lugares, según la aplicación:

- gbpublisher: el repositorio de GitHub, clonado con `git clone --depth 1`. Antes de leerlo, Claude pregunta si está al día; un sí lo habilita como copia de trabajo, sin más cotejo, y un no obliga a esperar el push. De ahí salen el corpus (`docs/corpus.md`) y el catálogo de shortcodes (`_catalogo.tsv` en `.hidden/shortcodes/`). El `corpus.md` adjunto al proyecto de trabajo con Claude no se coteja ni se usa.
- gbCorpus y gbShortcodes: la carpeta local de cada una en la máquina de Alberto, a la que Claude tiene acceso. No se consulta GitHub: los scripts se aplican en local y pueden no estar subidos. De ahí salen los scripts aplicados (`gbcorpus-act-NN.sql` en la raíz de gbCorpus, `datos/` de gbShortcodes).
- El número del script nuevo sale del más alto en la carpeta local de la aplicación.

Es lo que garantiza que un código nuevo esté libre y que un texto a reemplazar exista tal como se lo cita.

FLUJO DE TRABAJO

Claude entrega los archivos completos. Alberto los incorpora en el IDE y publica en GitHub, que es la copia que se consulta.

CADA APLICACIÓN

- gbCorpus: la base en RF-08. Tres exportaciones: el corpus completo, con todos los estados (va a `docs/corpus.md` de gbpublisher); las reglas vigentes de las familias marcadas como operativas; el volcado SQL.
- gbShortcodes: la base, el contrato de exportación y cada migración en RF-11. gbpublisher lee el catálogo según SC-34.
- gbAyudas: el diseño de las ayudas, la conversión, los estados, la exportación y el visor en SC-24. La entrada de referencia de su base se escribe cuando se construya.

**Relaciones:** vinculo:SC-19,vinculo:RF-08,vinculo:RF-11,vinculo:SC-24,vinculo:SC-34,vinculo:SC-13,vinculo:SC-11,vinculo:GV-30,vinculo:SC-52

**PENDIENTE:** Dos correcciones de código derivadas de esta entrada, entregadas con gbcorpus-act-17: (1) gbCorpus busca el importador primero en el sistema y después en «engine/» del proyecto (FMain.RutaImportador), al revés de lo que fija «Recursos que viajan con el programa»; (2) el .project de gbShortcodes declara en ExtraFiles solo «engine», y la aplicación instalada busca en /usr/share/gbshortcodes también esquema/carga-inicial.sql y las migraciones. Verificar las dos en Mint y quitar este pendiente.

### SC-51 — Búsqueda con expresiones regulares: biblioteca personal de patrones

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.19, proyecto completo compilado y flujo probado con gbx3 bajo xvfb / perl 5.38, engine/buscar_regex.pl / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). La pestaña RegExp tiene una biblioteca de patrones personales: lo que se probó en el banco de pruebas se guarda con un nombre y se vuelve a cargar desde `cmbPatrones`. Los datos y el formato viven en `m_PatronesRegex`; la pestaña la gobierna `m_BuscarRegex`; nombre, descripción y texto de prueba los pide `FGuardarPatron`. El motor no cambia (SC-05).

PERSONALES, SIN JUEGO DE LA CASA

Cada usuario desarrolla sus patrones sobre sus propios textos. No viajan patrones en el paquete y no hay nada en la base.

- Carpeta `~/.gbpublisher/regex/`. La crea vacía `m_InicioCierre.DirectorioOcultoApp()`. No entra en la lista de copia de SC-11: no hay nada que copiar desde el sistema (el criterio de los snippets, SC-21).
- La carpeta es de la cuenta de Linux, no de la máquina: dos usuarios de gbpublisher que entran con la misma cuenta comparten los patrones; dos cuentas, no. Entre cuentas o entre máquinas se pasan con Compartir e Importar.

UN ARCHIVO POR PATRÓN

`<nombre>.json`, con un solo patrón dentro. El nombre es el del archivo: `a-z`, `0-9` y guion, de 1 a 60 caracteres. El nombre inválido se rechaza con un mensaje, no se convierte en silencio. Lo legible va en la descripción.

Al cargar se ignora en silencio todo archivo cuyo nombre no sea un nombre de patrón (respaldos con `~`, ajenos). Uno con nombre de patrón que no se puede usar —JSON roto, versión más nueva, más de un patrón, nombre interno distinto del archivo— se lista en un solo aviso, para que no desaparezca sin explicación (GV-23). La biblioteca se relee del disco en cada apertura de proyecto: un patrón corregido con un editor externo aparece al día.

FORMATO

    { "formato": "gbpublisher-regex",
      "version": 1,
      "patrones": [
        { "nombre": "...", "descripcion": "...", "patron": "...",
          "reemplazo": "...", "flags": "...", "texto_prueba": "..." } ] }

- `version` es un entero. Una más nueva que la que entiende la instalación se rechaza diciendo cuál es.
- Obligatorios: `nombre` y `patron`. Los demás, si faltan, valen "". Se leen siempre con `m_PatronesRegex.Campo`, que devuelve "" si la clave no está o no es texto: una clave con "" no existe en una `Collection` (GV-68), y un `null` de JSON tampoco (GV-98).
- `flags`: solo `i`, `m`, `s`, `x`, y se guardan en ese orden.
- Las claves desconocidas se ignoran.
- Se escribe a mano, con sangría y un `JSON.Encode` por valor, para que el archivo se pueda leer y corregir en un editor de texto. Van siempre los seis campos.

EL MISMO FORMATO PARA GUARDAR, COMPARTIR E IMPORTAR

- Compartir escribe SOLO el patrón elegido, y lo guardado: con cambios sin guardar, pide guardar antes. La sobrescritura del destino la pregunta el diálogo; el código pregunta solo si cambia la ruta después, al agregar la extensión `.json` que faltaba (GV-97, RC-GM-19).
- Importar acepta uno o varios patrones. Cada elemento se controla por separado: uno malo no invalida a los demás. Después pasa por el modo `validar` del motor: un solo motor decide la sintaxis (SC-05). Mismo nombre y mismo contenido: «ya estaba». Mismo nombre y otro contenido: pregunta si reemplazar u omitir, mostrando los dos patrones. Un nombre repetido dentro del archivo: vale el primero. Al final, un informe con las cuentas y los descartados con su motivo.
- Un patrón ajeno no es un riesgo: RC-PL-01 cubre el reemplazo, y perl rechaza `(?{...})` en un patrón que viene de variable.

LA PESTAÑA

- El primer ítem del combo es «(patrón libre)». Elegirlo conserva lo que hay en los campos.
- Elegir un patrón completa patrón, reemplazo y flags. Su texto de prueba entra en `areaEditor` solo si el área está vacía: así no se pisa un fragmento real pegado para probar varios patrones.
- `lblDescripcionPatron` muestra la descripción y la marca «modificado, sin guardar». La marca compara patrón, reemplazo y flags con lo guardado; la descripción y el texto de prueba no cuentan. Se compara contra lo guardado, no se siguen eventos: no importa qué asignación dispara qué.
- Reemplazar los campos con otro patrón pregunta si se perdería algo: un patrón libre escrito, o uno cargado con cambios. Es SC-06 aplicado a la pestaña. Volver a elegir el mismo patrón es volver a la versión guardada.
- Reponer el combo desde el código pasa por una bandera: asignar `Index` dispara `Click` (GV-53); `Clear` y `Add` no (GV-69).
- Guardar exige un patrón que el motor aceptó. `FGuardarPatron` propone el nombre cargado, su descripción y el contenido de `areaEditor` como texto de prueba, para recortarlo. Si el nombre existe, confirma: actualizar el mismo, o reemplazar otro distinto. Un nombre nuevo es «guardar como»: el anterior queda. No hay renombrar: se guarda como y se borra.
- Borrar deja los campos como patrón libre.

PRIMEROS PATRONES (DE ALBERTO, ERRORES QUE LLEGAN DE WORD A LAS REFERENCIAS)

    pagina-sin-espacio   (?<![\p{L}\p{N}])p\.(\d+)(?!\d|\s*(?:---|--|-|–|—)\s*\d)     ->  p. $1
    rango-paginas        (?<![\p{L}\p{N}])(?!pp\. \d+-\d)pp?\.\s*(\d+)\s*(?:---|--|-|–|—)\s*(\d+)   ->  pp. $1-$2
    rango-anios          (?<![\p{L}\p{N}])(\d{4})(?:\s*(?:---|--|–|—)\s*|\s+-\s*|-\s+)(\d{4})(?![\p{L}\p{N}])   ->  $1-$2

El lookbehind exige que delante de la `p` no haya letra ni dígito, en cualquier alfabeto: quedan fuera `Exp.2` y `ap.3`, y entra `(p.135)`. El primero deja los rangos para el segundo, así que el orden no importa. Los dos de rango llevan el rango a un GUION SIMPLE, la norma de la editorial (SC-40), desde cualquier forma en que llegue de Word: dos o tres guiones, semirraya o raya Unicode, con o sin espacios. Ninguno toca la forma ya correcta (`pp. 20-24`, `1990-2000`). El de años exige cuatro cifras de cada lado y nada pegado: deja afuera `12345--67890`, `199--200` y un ISBN, pero un número de cuatro cifras separado por un guion entre espacios (un teléfono, por ejemplo) coincide igual; la grilla está para revisarlo antes de reemplazar. Delante de `pp.` o entre dos años, el contexto confirma el rango que `limpiar_docx.lua` solo puede avisar (`aviso_guion_entre_digitos`). Probados con `engine/buscar_regex.pl`, modo `probar`, y cargados con `m_PatronesRegex`.

EL EDITOR MUESTRA LAS COINCIDENCIAS Y SE RECARGA AL REEMPLAZAR (decisión de Alberto)

`FRegexResultados` es MODAL a propósito: mientras está abierto nadie escribe a mano en el editor. Con eso, el editor puede mostrar cualquier coincidencia sin riesgo de posiciones viejas.

- Antes de abrir el formulario, el editor tiene que ser igual al disco. El aviso de SC-06 ya pidió guardar o descartar, pero «Descartar» solo mueve el punto de control (`MarcarGuardado`): el texto descartado sigue en el editor. Si difiere del disco, `m_BuscarRegex.BuscarRegex` lo relee con `FMain.RecargarArchivoAbierto`.
- Un click en una fila de la grilla lleva el editor a la coincidencia (`m_BuscarRegex.MostrarCoincidencia`). Va en `Click`, no en `Select` (GV-78): la primera versión navegaba desde `Select` y el editor no cambiaba de archivo en Mint. El preview de `txtContexto` va en `Change`, que también sigue a las flechas: abre su archivo si no es el abierto (`m_Estructura.AbrirArchivo`, por el combo, GV-53) y la deja seleccionada con su párrafo arriba de la vista (`m_EditorPrincipal.IrA`, GV-52), por línea y columna base 0, como las da el script. «Resaltar» es seleccionar: colorear con `Format` entraría en el deshacer (GV-46). Medido en banco: la selección se ve con el modal encima. No hace falta desplazar el editor a mano: el párrafo queda arriba.
- Después de escribir, `FRegexResultados` llama en el acto a `m_BuscarRegex.TrasReemplazo` con los archivos efectivamente escritos, también si la escritura se cortó a mitad. Para cada uno: árbol de estructura y referencias citadas en la base (`m_Bibtex.ExtraerYGuardarReferenciasDelEditor`), lo mismo que hace un guardado. Si uno es el abierto: `FMain.RecargarArchivoAbierto` (editor, árbol, comentarios y contador). Después se vuelve a buscar, así que las posiciones de la grilla vuelven a valer.
- Recargar es el punto de refresco 2 de SC-18: corta el deshacer. No se pierde nada: lo escrito por el reemplazo se deshace con git, que el guard del formulario exige o advierte.
- Después de reemplazar, el editor queda en el ÚLTIMO archivo cambiado (orden de la grilla, que es el editorial), con su PRIMER cambio seleccionado y el párrafo arriba (decisión de Alberto). Ese cambio no se corrió: los reemplazos van de atrás para adelante. Al volver a llenar la grilla, el editor no se mueve: la navegación cuelga de `Click`, que el código nunca dispara (GV-78). La bandera `$bRepoblando` solo evita que el preview se actualice con una fila movida por el código.
- Al cerrar, el editor queda donde estaba —la última coincidencia vista o el último cambio—, con el foco.
- `MostrarCoincidencia` no tiene salidas mudas (GV-23): si no puede mover el editor, lo dice.

NO SE RECARGA POR EL COMBO

La primera versión recargaba al cerrar el formulario disparando `cmbArticulosRevista_Click`. Ese handler sale sin hacer nada si la ruta es la del archivo abierto (GV-53), así que el reemplazo quedaba en disco y el editor con el texto viejo: un Ctrl+S lo pisaba. Releer un archivo abierto desde el disco se hace con `FMain.RecargarArchivoAbierto`, nunca con el Click del combo.

**Relaciones:** vinculo:SC-05,vinculo:RC-PL-01,vinculo:SC-21,vinculo:SC-11,vinculo:SC-06,vinculo:SC-40,vinculo:GV-53,vinculo:GV-69,vinculo:GV-68,vinculo:GV-97,vinculo:GV-98,vinculo:RC-GM-19,vinculo:GV-23,vinculo:SC-18,vinculo:GV-46,vinculo:GV-52,vinculo:GV-78

**PENDIENTE:** Verificar en Linux Mint con Gambas 3.22.1 el flujo completo en la aplicación (guardar, elegir, marca de modificado, compartir, importar); el mini-test de JSON ya pasó (GV-98). Después, quitar este pendiente y poner el entorno de Mint.

### SC-52 — Verificación en XML, JATS y DocBook: lo que no pasa el validador no está verificado

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** JATS Archiving 1.4 / DocBook 5.2 / SaxonJ-HE 12.5

DECISIÓN CERRADA (decisión de Alberto). Cómo se trabaja cuando Claude propone XML, XPath o XSLT para JATS o DocBook.

POR QUÉ

El riesgo no es la ignorancia sino el error verosímil: un atributo, un valor o un orden de hijos que suena correcto y que el esquema no admite, dicho con la misma seguridad que lo verificado. La estructura general suele estar bien; el error está en el detalle de qué va dentro de qué y en qué orden.

1. LO QUE NO PASA EL VALIDADOR NO ESTÁ VERIFICADO

Todo fragmento JATS o DocBook propuesto viene con una instancia mínima de prueba y el comando que la valida contra el esquema del repositorio. Una estructura se da por buena cuando el validador la acepta, no cuando parece correcta.

2. EL ESQUEMA ESTÁ EN EL REPOSITORIO, NO EN LA MEMORIA

Ante una duda de modelo de contenido —qué hijos admite un elemento, en qué orden, qué valores toma un atributo— la respuesta sale del esquema:

    JATS 1.4 Archiving   .hidden/dtd/JATS-archivearticle1-4.dtd y sus módulos
    DocBook 5.2          .hidden/schemas/docbook/docbook.rng

Si en la sesión no hay acceso al esquema, se dice y se pide el fragmento.

3. ORIGEN DECLARADO DE CADA AFIRMACIÓN

Las afirmaciones técnicas que no son triviales llevan su origen:

    [esquema]   verificado contra la DTD, el RNG o el Schematron
    [doc]       documentación oficial: Tag Library, especificación W3C, manual de Saxon
    [memoria]   conocimiento sin verificar; se verifica antes de usarlo

4. CAPAS DE VALIDEZ SEPARADAS

Válido para el esquema JATS no quiere decir que pase SciELO PS (packtools), PMC o el esquema de depósito de Crossref. Válido para el RNG de DocBook no quiere decir que lo procese bien una hoja del proyecto. Cada regla dice a qué capa pertenece.

5. LO QUE DEPENDE DE LA VERSIÓN SE PRUEBA CON EL PROCESADOR ANCLADO

El comportamiento de XSLT, XPath y los validadores se prueba con la versión anclada del proyecto, no se deduce. Caso abierto en el pendiente de esta entrada.

6. LO VERIFICADO SE ACUMULA EN GV-XML

Todo comportamiento comprobado de XML, XPath, XSLT, Saxon, xmllint, jing, Schematron, packtools y los esquemas JATS y DocBook entra como GV-XML-NN, con entorno y fecha. Las entradas anteriores sobre esos temas (GV-21, GV-22, GV-25, GV-26, GV-28, GV-71, GV-81, GV-82) quedan en GV con su código: están citadas en el código y en otras entradas, y renumerarlas rompería esas citas.

**Relaciones:** vinculo:GV-21,vinculo:GV-22,vinculo:GV-25,vinculo:GV-26,vinculo:GV-28,vinculo:GV-71,vinculo:GV-81,vinculo:GV-82,vinculo:SC-50

**PENDIENTE:** Mini-test: si SaxonJ-HE 12.5 acepta construcciones de XSLT 3.0 en una hoja declarada version="2.0". El resultado entra como GV-XML-01 y se quita este pendiente.

### SC-53 — Lanzadora de scripts de engine/: un solo camino, código de salida por archivo de estado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / gb.form.terminal / bash / Linux Mint; generar_canonicos_capitulos.sh probado en contenedor Ubuntu 24.04 con Pandoc 3.1.3, SaxonJ-HE 12.5 y jing, y el proyecto compilado con gbc3 3.19 · **Verificado:** 2026-10

DECISIÓN CERRADA. Todo script de `engine/` que Gambas lanza en la terminal del proyecto pasa por `m_GenerarSalidasLibro.EjecutarScriptSalida`. Es el contrato del criterio 1 de SC-13: Gambas recibe una decisión, el código de salida, y no parsea nada.

POR QUÉ NO Exec

`TerminalView.Exec()` responde «Terminal already in use»: el control ya tiene un bash interactivo corriendo (GV-42). Así que se sigue tipeando con `Input()`, pero cambia lo que Gambas espera.

QUÉ TIPEA

Una sola línea: el script con sus argumentos y, a continuación, la escritura de su código de salida en un archivo de estado.

    bash <script> <args…> ; echo $? > tmp/.estado-…tmp && mv -f tmp/.estado-…tmp tmp/.estado-…

- `;` y no `&&` después del script: el estado se escribe aunque el script falle, que es cuando más hace falta.
- `mv` dentro de la misma carpeta es atómico: el archivo de estado aparece completo y solo cuando el script terminó. Gambas espera ESE archivo, no el producto, que aparece con el primer byte.
- El nombre es único por lanzamiento. Si una línea anterior sigue encolada, cada una espera su propio estado y ninguna lee el código de la otra.
- Los argumentos van con `Shell$()`, no con `Quote()`: dentro de las comillas dobles de `Quote()` el shell sigue expandiendo `$(…)` y los backticks (GV-06). Ninguno va vacío: el que no aplica se pasa como «-», porque un argumento vacío que se pierde corre de posición a los siguientes.

MIENTRAS ESPERA

Gambas no tipea nada en la terminal. Los controles que podrían hacerlo se deshabilitan (`BloquearSalidas`), y nunca un contenedor ancestro del TerminalView, que lo apagaría con ellos (GV-42). `HayScriptEnCurso()` sirve a los guards que no pasan por esos controles: abrir otro proyecto, cerrar la aplicación. Si vence el plazo, se pregunta si seguir esperando; nunca se escribe un echo. Bloqueo, espera y desbloqueo están en la lanzadora y en ningún otro lado, con un solo camino de salida (RC-GM-20).

QUÉ VE QUIEN OPERA

Mientras espera, la lanzadora muestra que está trabajando. Sin eso, una composición LaTeX de varios minutos parecía una máquina colgada.

- El puntero ocupado en toda la aplicación: `Inc Application.Busy` al bloquear y `Dec` al desbloquear, en el mismo único camino de salida. `Inc` y no `= 1`: si otra cosa ya lo tenía en uso, vuelve a ese valor. Los diálogos de `Message`, incluida la pregunta del plazo, lo ponen en cero y lo restauran solos (GV-100).
- `FMain.lblMensajes`, sobre la terminal: qué se está generando —el parámetro opcional `sQue` de `EjecutarScriptSalida`, o el nombre del script si falta— y el tiempo transcurrido, una vez por segundo. Es tiempo, no un porcentaje: solo dice que el proceso sigue vivo. Se vacía al desbloquear.

Al dejar de esperar también se desbloquea y se vuelve al puntero normal: el script sigue corriendo, pero la aplicación ya no lo sigue y no puede seguir diciendo que trabaja.

CÓDIGOS

Los fija `engine/comun.sh` y los replica `m_GenerarSalidasLibro`:

    0  SALIDA_OK       el producto se generó y lo verificado dio bien
    3  SALIDA_AVISOS   se generó, pero algo merece revisión
    1  SALIDA_FALLO    no se generó

Los resultados propios de la lanzadora son negativos, para no confundirse con ningún código de proceso: en curso, no lanzado, abandonado, ilegible. `InformarResultado` los traduce a un mensaje que solo afirma lo que el script verificó.

LO QUE TODO SCRIPT TRAE

- `source comun.sh`: los colores, `paso`, `ok`, `aviso`, `tenue`, `morir`. `aviso()` cuenta, y `terminar()` es la única salida normal: elige 0 o 3 según haya habido avisos, así ningún script puede olvidarse de informarlos.
- No toca la base. Lo que necesita de ella llega como archivo (SC-13).
- Escribe cada producto en un temporal de la misma carpeta, verifica que esté bien formado y recién entonces lo renombra con `mv -f`. En disco hay siempre una versión completa, nunca una a medio escribir. Es `mv` de bash y no la sentencia `Move` de Gambas, que no pisa el destino (GV-39).
- Un script que llama a otro exporta `GBP_ANIDADO=1`, y el llamado se presenta como un paso más del llamador.

LOTES

Varias unidades del mismo trabajo van en UN lanzamiento con una lista, no en un bucle de lanzamientos desde Gambas: un solo bloqueo, una sola espera, un solo código. El script sigue con las unidades que quedan cuando una falla y al final lista todas las que fallaron, porque el editor necesita ver todo lo que hay que corregir, no solo lo primero que falló. Caso: `generar_canonicos_capitulos.sh`, que recibe `tmp/lote-canonicos.tsv`.

VALIDACIÓN DE UNA PIEZA SUELTA

Un script que valida una parte del libro por separado —hoy, el canónico de cada capítulo— no cuenta como aviso los errores `IDREF "…" without matching ID` de jing. Son remisiones a algo que está fuera de la pieza: las citas a la bibliografía consolidada, cuyos `bib-*` entran recién al ensamblar, y las remisiones a figuras o secciones de otra pieza (SC-32). Contadas como aviso, daban código 3 en todo libro con bibliografía consolidada, y un aviso que sale siempre tapa a los que importan.

Se informan en tenue, con su cantidad, como remisiones que se verifican al ensamblar. Cualquier otro error de jing sigue siendo aviso. Si solo hubo remisiones, el informe no dice «válido»: dice que no hay errores de esquema propios de la pieza. Un IDREF colgado de verdad lo marca la validación del libro en `ensamblar_libro.sh`, que lo cuenta como aviso. Es la separación de capas de SC-52: válido como pieza no es válido como libro.

El patrón sale de la salida real de jing en Linux Mint: `69:1130: error: IDREF "bib-4308-TOCHO2020" without matching ID`.

LOS USOS

`ensamblar_libro.sh`, `generar_html_libro.sh`, `generar_epub_libro.sh`, `generar_canonicos_capitulos.sh`, `preparar_latex_libro.sh` y `compilar_pdf_libro.sh`. Este último fue el último en pasar: se tipeaba en la terminal, Gambas no sabía cuándo terminaba y no informaba el resultado; además tenía su propia copia de las funciones de salida, con un `aviso` que no contaba. Ahora carga `comun.sh` y sus avisos (citas sin entrada en el .bib, entradas de índice descartadas, referencias cruzadas sin destino o repetidas, falta del .bib) llegan como código 3.

`preparar_latex_libro.sh` hace lo que antes hacía `m_GenerarPDFLibro.GenerarMainTeX` con `Exec` síncronos: colorear y transformar cada pieza (`colorear_codigo.sh` y `docbook-to-latex.xsl`), borrar los `c-*.tex` huérfanos y poner el `main.tex` en su lugar. Mientras eso corría en Gambas, la interfaz no se repintaba (GV-17) y no había señal de vida antes de que empezara la compilación. Gambas conserva lo que sale de la base, en `m_GenerarPDFLibro.ArmarInsumosLaTeX`: preámbulo derivado, `.bib`, la lista de piezas con cuerpo (`tmp/latex-piezas.txt`) y el `main.tex` propuesto (`latex/.main.tex.tmp`). «Solo generar» lanza `preparar_latex_libro.sh`; «Generar y compilar» lanza `compilar_pdf_libro.sh`, que lo llama anidado primero y no compila si falla.

El `main.tex` sigue yendo último (criterio de SC-07): el script lo pone con `mv` solo si todas las piezas salieron bien, y si alguna falla el anterior queda intacto. Como `mv` conserva la fecha del temporal, anterior a las piezas, un `touch` lo deja como el archivo más nuevo. Una pieza que falla no corta el resto: se listan todas y no se pone el `main.tex`. El preámbulo derivado y el `.bib` los sigue escribiendo Gambas antes del script: si una pieza falla quedan nuevos junto al `main.tex` anterior, lo que se aceptó porque no son declarativos y la próxima corrida los reescribe. Decisión de Alberto.

**Relaciones:** vinculo:SC-13,vinculo:SC-06,vinculo:SC-11,vinculo:GV-06,vinculo:GV-39,vinculo:GV-42,vinculo:RC-GM-20,apoya:GV-23,vinculo:SC-32,vinculo:SC-52,vinculo:SC-54,vinculo:GV-100,vinculo:SC-07

**PENDIENTE:** Probado en Mint con un libro real: «Canónico archivo en curso», «Todos los canónicos» y «Ensamblar». Falta un lote en el que un capítulo falla (su canónico anterior se borra y «Ensamblar» se niega hasta regenerarlo), y volver a correr «Todos los canónicos» en un libro con bibliografía consolidada para ver las remisiones en tenue y el código 0. Hecho eso, quitar este pendiente.

### SC-54 — Controles de corrección del .md: un filtro en engine/ con niveles declarados

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / bash / contenedor Ubuntu 24.04: controles_md.lua solo y dentro de generar_canonicos_capitulos.sh; los controles de notas, en Linux Mint con un libro real · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Lo que el Markdown deja pasar sin error y llega mal al impreso —un error que se le puede pasar a la corrección— se controla al generar el canónico de cada capítulo, en un solo lugar donde los controles se van sumando a medida que el uso los muestra. El caso que lo originó: una llamada a nota sin su definición salió como «[^3]» literal en el PDF (GV-99).

DÓNDE

`engine/controles_md.lua`, en una pasada de pandoc propia que `generar_canonicos_capitulos.sh` corre antes de la conversión:

    pandoc ARCHIVO.md --from markdown --to plain
           --lua-filter engine/controles_md.lua
           --metadata gb-controles=tmp/controles-{base}.tsv
           --metadata gb-proyecto=RAIZ --output /dev/null

- Pasada aparte y sin los filtros de producción, por el criterio de SC-46: `fenced-divs` serializa los divs a XML crudo y después ya no hay texto que revisar, y otros filtros frenan. Así el control ve el documento como lo escribió la corrección, también adentro de un recuadro.
- En `engine/` y no en `filters/`: un control que dice «este capítulo está bien» no se ajusta localmente (SC-11).

EL CONTRATO

- El informe va a un archivo, no a stderr, para no mezclarse con los mensajes de pandoc. Un hallazgo por línea: `nivel TAB control TAB mensaje`.
- El filtro lo escribe siempre, vacío si no hay hallazgos. Si falta, el control no corrió y el capítulo falla: no se da por revisado lo que no se revisó.
- `error`: el capítulo no se genera y su canónico anterior se borra (SC-53), así que «Ensamblar» se niega hasta corregirlo. `aviso`: se genera y el lote termina con código 3.
- El script no conoce ningún control por su nombre: lee el nivel. Un nivel que no conoce es un fallo.
- Los `[WARNING]` del lector de pandoc en esta pasada son también aviso. En la de conversión se omiten las líneas idénticas, para no informarlos dos veces.

CÓMO SE SUMA UN CONTROL

1. Una línea en la tabla `CONTROLES` del filtro, con su nombre y su nivel.
2. Una función que llama a `registrar(nombre, mensaje)`.
3. Su llamada en `Pandoc()`.

Cambiar el nivel de un control es cambiar esa tabla.

LOS CONTROLES

    llamada_sin_nota          error   [^3] en el texto sin su definición
    nota_vacia                error   una nota sin texto (\footnote{})
    definicion_sin_texto      error   [^3]: con la línea vacía, sobre el texto
                                      fuente; informa el número de línea
    imagen_inexistente        error   una imagen del .md que no está en media/:
                                      borrada o renombrada
    imagen_fuera_de_media     error   una imagen que apunta fuera de media/
    comillas_desbalanceadas   aviso   « » que no cierran en su lista de inlines
    latex_en_linea            error   una orden de LaTeX en el texto que no es
                                      de las admitidas: \sptext, \num, \SI,
                                      \SIrange (GV-116); o una de ellas
                                      incompleta (GV-124)
    latex_suelto              error   una orden de LaTeX sola entre párrafos,
                                      fuera de ::: espaciov
    html_crudo                error   HTML escrito en el .md, menos los
                                      comentarios <!-- … -->
    corte_fuera_de_titulo     error   \\ fuera de un título: sale como una
                                      barra (SC-63); para un salto, espaciov
    porcentaje_suelto         aviso   88% o 88 % escrito suelto (SC-64, SC-65)
    cifra_fuera_de_num        aviso   una cifra con punto o coma de miles fuera
                                      de \num (SC-64, SC-65)
    [WARNING] de pandoc       aviso   entre ellos, nota definida y nunca llamada

`definicion_sin_texto` lee el archivo fuente (`PANDOC_STATE.input_files`) porque en el AST el caso ya no existe (GV-99), y saltea los bloques de código cercados con ``` o ~~~. Una definición de nota vacía al final del archivo la informan dos controles, `definicion_sin_texto` (con la línea) y `nota_vacia`: es el mismo error.

IMÁGENES

Se controla cada nodo `Image` del .md, suelto o dentro de un `::: fig`, contra la raíz del proyecto que recibe el filtro (`gb-proyecto`): las rutas se escriben relativas a ella (`media/fig-mapa.png`, SC-32). El nombre se compara exacto, con mayúsculas. Una dirección con esquema (`http:`, `https:`, `data:`) no es un archivo del proyecto y se saltea. Fuera de `media/` es error aunque el archivo exista, porque el EPUB y el HTML solo copian `media/`. NO se controla lo inverso: que `media/` tenga imágenes que ningún .md usa es normal (la tapa, los logos, figuras que se sacaron del texto). Decisión de Alberto.

COMILLAS

`comillas_desbalanceadas` aplica el mismo criterio que `guillemets-to-quoted-db.lua`, que es el que decide si arma la cita o deja los caracteres literales: cada lista de inlines se mira sola, solo cuentan los « » de sus `Str` directos, y está mal si un » cierra sin nada abierto o si al final queda un « abierto. Así el aviso coincide con lo que el filtro de producción no pudo resolver, incluida su limitación (`«un *texto» citado*` no cierra en ninguna de las dos listas). Si cambia el criterio del filtro, cambia el control. Verificado: sobre el mismo .md, los dos marcan las mismas cuatro listas.

El filtro de producción sigue escribiendo su mensaje por stderr porque revistas, que todavía no pasa por los controles, depende de él. En libros, `generar_canonicos_capitulos.sh` lo omite en la conversión: ya lo informó el control.

LaTeX Y HTML CRUDOS

Lo que Pandoc lee como LaTeX o HTML crudo se pierde en las tres salidas: los escritores de XML lo descartan sin aviso (GV-116). Decisión de Alberto: los tres controles son `error`, y por ahora solo en libros, como los demás (pendiente 1).

- En el texto, las órdenes de LaTeX admitidas son `\sptext{…}`, que traduce `volada.lua` (SC-62), y `\num`, `\SI` y `\SIrange`, que traduce `cifras.lua` (SC-65); su forma la valida cada filtro y no este control. El texto de la orden se escribe en el informe sin saltos de línea: puede traerlos (GV-124). El mensaje nombra la orden y muestra el contexto con el texto crudo a la vista: `stringify` lo descarta, y sin eso quedaban huecos.
- Suelto entre párrafos, el LaTeX solo vale dentro de `::: espaciov`, que valida `espacio-vertical.lua` (SC-39). El recorrido es de arriba abajo (`traverse = "topdown"`) y no baja a un `espaciov`.
- Los comentarios HTML `<!-- … -->`, en línea o en bloque, también de varias líneas, no son texto y no se informan. Un `<div>` no es HTML crudo: Pandoc lo lee como un `Div`.
- Como `revisar_inlines`, el recorrido en línea no baja al contenido de una nota: sus párrafos los visita el walk de bloques, y así no se informan dos veces.

MEDIDO: un título, un párrafo, una bastardilla, una nota y una celda con órdenes de LaTeX; `<sup>`, `</sup>` y `<br>`; `\newpage` suelto; un comentario de dos líneas y uno en línea; `\bigskip` dentro de `espaciov`. Salen los diez hallazgos esperados, los comentarios y el `espaciov` no; un .md limpio deja el informe vacío. Sobre los ejemplos del catálogo, el único hallazgo es `paleographic`: sus `<ue>`, `<iem>` y `<er>` hoy se pierden (una de las filas con pendiente).

EL CORTE FUERA DE UN TÍTULO

`corte_fuera_de_titulo` busca la barra que deja `\\` (GV-121) en los `Str` de los párrafos, las celdas, las líneas de un bloque de líneas y las notas, también las de un título. No mira los títulos, que traduce `corte-titulo.lua` (SC-63), ni el código ni la matemática, que no son `Str`. Medido: un párrafo, una nota y una celda con `\\` dan tres hallazgos; el título y el código, ninguno. Una barra seguida de letras no es un corte: es una orden que Pandoc dejó como texto porque le faltan argumentos (GV-124), y se informa como `latex_en_linea`.

LAS CIFRAS SUELTAS

Dos controles de nivel `aviso` (decisión de Alberto: informan, y la salida se genera) buscan en los `Str` de los párrafos, las celdas, los títulos, las líneas de un bloque de líneas y las notas lo que la norma de SC-64 escribe con siunitx. No bajan a un enlace ni a una cita: un DOI no es una cifra.

- `porcentaje_suelto`: un dígito seguido de `%`, pegado o con un espacio duro o fino en el mismo `Str`, o un `Str` que termina en dígito, un espacio y otro que empieza con `%`. El mensaje recuerda la forma `\SI{…}{\percent}` y que con una sola cifra va en letras.
- `cifra_fuera_de_num`: un dígito, un punto o una coma y tres dígitos (`1.500`, `12,345`). Un `Str` con barra se saltea: «decreto 2.345/26». Los números de identidad sin barra («ley 34.555») se informan igual: por eso es aviso.

Un decimal suelto (`2.5`, `3,14`) no se informa.

MEDIDO: un .md con `\num{12000}` y «3.500» en un título, «88%», «88 %», «88» con espacio duro y «77» con espacio fino, «1.500», «12,345», «ley 34.555», «decreto 2.345/26», un DOI en un enlace, «2.5» y «3,14», y una nota con «4.000» y «5%»: diez avisos, los esperados; el decreto, el DOI y los decimales, ninguno.

**Relaciones:** vinculo:SC-53,vinculo:SC-46,vinculo:SC-11,vinculo:SC-13,apoya:GV-99,vinculo:SC-30,vinculo:SC-32,vinculo:GV-116,vinculo:SC-62,vinculo:SC-39,vinculo:SC-63,vinculo:SC-65,apoya:GV-124

**PENDIENTE:** (1) Revistas: usar el mismo filtro, con los controles de LaTeX y HTML crudos, cuando su cadena se migre a engine/ (SC-13); entonces sacar el mensaje de comillas de guillemets-to-quoted-db.lua, que hoy queda solo por revistas. (2) Probar en Mint con un libro real los controles de notas, imágenes y comillas.

### SC-55 — Orden de los finales: la bibliografía antes de los índices, el colofón último; aviso en el ABM, freno en el PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.19 (gbc3, gbs3) / contenedor Ubuntu / MySQL 8.0.46 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Libros, salida PDF. El orden de las piezas sale del nombre de archivo (SC-44), y hay errores de orden en los finales que compilan sin fallar y dan un libro equivocado. Esos se controlan; el resto del orden de los finales no.

EL CASO QUE LO ORIGINÓ

Un libro de autor con bibliografía consolidada sacó el índice de autores antes de la bibliografía. Con bibliografía por capítulo no se ve: cada pieza trae la suya y el índice después del último capítulo es lo correcto. Dos caminos llevan al error:
- La bibliografía consolidada sin pieza declarada: `ArmarInsumosLaTeX` (apartado 8) emite `\printbibliography[heading=bibintoc]` al final, después de TODAS las piezas declaradas, índices incluidos.
- La pieza declarada pero numerada después del índice (`bm-20-indice-autores`, `bm-21-referencias`).

LAS REGLAS

La función es `m_PiezasLibro.ProblemaOrdenFinales(aNombre, aTipo, bConsolidada)`: recibe las piezas en el orden del libro y devuelve vacío o el mensaje del PRIMER problema, con qué está mal y cómo corregirlo.
- R1. Ningún `indice_*` (onomastico, concepto, autores) antes de la pieza `bibliografia`. Si hay más de una, manda la primera, como en el EPUB.
- R2. Bibliografía consolidada, sin pieza `bibliografia` y con algún índice declarado: hay que declararla. Sin índices no se exige: el respaldo del apartado 8 da el orden correcto y los libros anteriores siguen compilando.
- R3. Si hay pieza `colofon`, es la última.

No se controlan `glosario`, `sobre_autores` ni `cronologia`: su lugar es tradición editorial, no error, y una regla rígida frenaría libros bien compuestos.

POR QUÉ UN SEMÁFORO

Es una regla del LIBRO, no de una pieza, y por eso no va en `ProblemaPosicion` (la de la dedicatoria, que con el nombre de la pieza alcanza). Al renumerar dos piezas hay un estado intermedio inválido que no se puede evitar; un freno al guardar obligaría a pasar por un nombre provisorio.
- Amarillo: `m_Metadatos.GuardarMetadatosDeCapitulo` (apartado 7), DESPUÉS de guardar, lee todas las piezas con nombre del libro abierto en el orden de `m_OrdenPiezas.ClausulaOrden` (`ProblemaOrdenLibroAbierto`) y muestra `Message.Warning`. Un fallo de lectura no se informa: el aviso es ayuda.
- Rojo: `m_GenerarPDFLibro.ArmarInsumosLaTeX` (apartado 2b, después de `VerificarPosiciones`) frena con `Message.Error` antes de escribir nada.

La regla está escrita una sola vez, en `m_PiezasLibro`; los dos lugares la llaman.

CÓDIGOS REPETIDOS

Dos piezas con el mismo código de posición (`bm-20-indice-autores` y `bm-20-referencias`) quedan ordenadas por el resto del nombre, alfabéticamente, y no por el número: el orden puede salir bien por casualidad. Vale para TODO el libro —preliminares, cuerpo y finales— y para todas las salidas, porque todas ordenan por nombre (SC-44).

- La función es `m_PiezasLibro.ProblemaCodigoRepetido(iIdLibro)`. Agrupa por `m_OrdenPiezas.ExpresionCodigo`, la misma definición del código que usan las grillas: no se reescribe en Gambas. `GROUP BY` sobre el alias lo admite MySQL (manual 8.0, B.3.4.4). Lista TODOS los códigos repetidos con sus piezas: renumerar uno puede chocar con otro. Un fallo de lectura devuelve vacío: los generadores leen la misma tabla y fallan con su propio mensaje.
- Va ANTES que `ProblemaOrdenFinales`: con un código repetido, el control de los finales podría dar bien por casualidad.
- Amarillo al guardar: `m_Metadatos.ProblemaOrdenLibroAbierto` (pública) es el control completo del libro abierto: primero los repetidos, después R1 a R3. El aviso anuncia que el formulario no se va a poder cerrar.
- Rojo al cerrar `FMetadatosCapitulos`, para TODAS las reglas —repetidos y R1 a R3—: `ActualizarCierre` deja `btnCerrar.Enabled` en False, con el motivo en el `Tooltip`, mientras `ProblemaOrdenLibroAbierto` devuelva un problema. Se llama al principio de `RefrescarGbCapitulos`, por donde pasan la apertura, el alta, la baja y el guardado: un solo punto. Es el único camino de cierre, porque `Form_Close` bloquea la X con `Stop Event`; la ventana no tiene X (SC-20), así que `Form_Close` es solo defensa y conserva su aviso original. Si el libro ya llega con el orden roto, `Form_Open` (apartado 9) muestra el motivo apenas se abre el formulario: sin eso el botón aparecería apagado sin explicación hasta pasar el puntero. `btnCerrar_Click` repite el control como defensa. Al guardar no se frena: al renumerar hay estados intermedios inválidos; al cerrar ya no. Un fallo de lectura de la base deja el botón habilitado: un problema de la base no encierra en un formulario modal.
- Rojo en las salidas: `m_GenerarPDFLibro.ArmarInsumosLaTeX` (2b), `m_GenerarSalidasLibro.PrepararInsumosLibro` (canónico del libro y HTML) y `m_GenerarEpubLibro.GenerarEpubLibro` (2).
- Por qué siguen los frenos de las salidas, si el formulario ya no deja salir con el orden roto: son la última barrera, no la principal. Cubren lo que no pasa por el formulario: los libros cargados antes de este control y nunca reabiertos, los cambios en `capitulos` hechos fuera de él (SQL directo, scripts de actualización, otra herramienta) y el fallo de lectura al cerrar, que a propósito deja el botón habilitado. Cuestan una consulta por salida.

EXCEPCIÓN A LA CONTRAPARTIDA DE SC-20

SC-20 exige que un formulario sin X tenga una salida propia. Deshabilitar `btnCerrar` la quita a propósito, y se acepta por dos razones: la salida vuelve sola al corregir el orden, y un fallo de lectura de la base deja el botón habilitado, así que nunca se queda encerrado por un problema que no se puede resolver desde el formulario. Decisión de Alberto.

FUERA DEL ALCANCE

EPUB y HTML: los índices no se generan (`m_PiezasLibro.Tratamiento`), así que el orden respecto de la bibliografía no cambia nada. El EPUB ubica su colofón solo.

**Relaciones:** vinculo:SC-44,vinculo:SC-45,vinculo:RC-GM-17,vinculo:SC-20,vinculo:GV-102

### SC-56 — Bibliografía con Verona en HTML y EPUB: nombre en cada entrada, versalitas por CSS, tipografía con smcp y c2sc

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-philosophy v1.9.8g / biber 2.19 / TeX Live 2023 / make4ht v0.3m / contenedor Ubuntu 24.04; Noto Serif de gbpublisher en Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Libros con el estilo Verona: philosophy-modern con `cita-verona-modern-config.tex`. Vale para HTML y EPUB; el PDF no cambia.

Es una excepción a SC-31 y la explica esta entrada. SC-14 se sigue cumpliendo: el texto de cada referencia lo arma el estilo, y cambia solo cómo se dispone el bloque del nombre y el año.

1. EL NOMBRE EN CADA ENTRADA (EXCEPCIÓN 2 DE SC-31)

philosophy-modern escribe el nombre una sola vez y apila debajo los años de sus obras, en una columna de ancho fijo (`\bibhang`). Es un recurso para leer en papel. En pantalla el ancho cambia y el lector elige el cuerpo de letra: la columna le quita ancho al texto y no ayuda a leer.

En HTML y EPUB va la disposición classic del mismo estilo: `\printbibliography[restoreclassic]` con `dashed=false`. Cada entrada lleva su nombre y el año entre paréntesis:

    Abós, Álvaro (1984), Las organizaciones sindicales y el poder militar (1976-1983), Buenos Aires: Centro Editor de América Latina.
    Abós, Álvaro (1986), El posperonismo, Buenos Aires: Editorial Legasa.

MEDIDO con `ref-l-MOLINARO.bib` (222 entradas): en todas, lo que sigue a «Nombre (año), » es el mismo texto que el PDF. Las letras del año se conservan (1988a y 1988b, 2023a y 2023b).

`\bibnamedash` no interviene. En modern el autor repetido no lleva guion: la macro `author` de `philosophy-modern.bbx` no imprime nada en `bbx:dashcheck`. El guion es de classic y verbose, y con `dashed=false` tampoco aparece. Por eso `cita-verona-modern-config.tex` no redefine `\bibnamedash`.

2. VERSALITAS POR CSS, SOBRE EL TEXTO CON SU CAJA

En el PDF, `scauthorsbib` y `lowscauthors` dan `\textsc{\MakeLowercase{...}}`: el texto queda en minúscula y la fuente lo pone en versalitas. Llevado tal cual a HTML, un lector que no respete las versalitas mostraría «abdala, omar».

En HTML y EPUB va `lowscauthors=false`: el texto conserva sus mayúsculas, «Abdala, Omar», y las versalitas las pone el CSS con `font-variant-caps: all-small-caps` (CSS Fonts Module Level 3). Se ve como en el PDF. Si el lector ignora el CSS, el nombre degrada a mayúsculas y minúsculas, como está en la base. Es la razón de SC-25 y por eso la bibliografía de Verona puede llevar versalitas.

3. TIPOGRAFÍA: smcp Y c2sc

`all-small-caps` usa dos rasgos OpenType: `c2sc` para las mayúsculas y `smcp` para las minúsculas. Si la fuente no los trae, el navegador fabrica versalitas falsas achicando mayúsculas.

REGLA: para usar Verona en HTML y EPUB, la tipografía tiene que traer `smcp` y `c2sc`. La que entrega la aplicación los trae. Verificado por Alberto en Mint con `otfinfo -f /usr/share/gbpublisher/fonts/NotoSerif-Regular.ttf`, que lista `c2sc` y `smcp`. Quien cambie la tipografía lo comprueba con el mismo comando (`otfinfo`, paquete lcdf-typetools).

FUERA DE ESTA DECISIÓN

- Cómo se genera el texto de la bibliografía para HTML y EPUB: lo arma biblatex con tex4ht (SC-57).
- Los otros estilos (APA, ISO 690, IEEE, Vancouver).

**Relaciones:** vinculo:SC-14,vinculo:SC-25,vinculo:SC-31,vinculo:RF-12,vinculo:SC-57,vinculo:GV-104

**PENDIENTE:** Medido en el contenedor sobre el HTML que da make4ht: la disposición classic con dashed=false, el texto de las 222 entradas contra el PDF y el marcado de las versalitas con lowscauthors=false. Sin probar: cómo responden los lectores de EPUB a all-small-caps, y si degradan a mayúsculas y minúsculas como se espera. Sin implementar en la aplicación: va con SC-57.

### SC-57 — Bibliografía de libro en HTML y EPUB: la arma biblatex con tex4ht, con el mismo estilo que el PDF (Verona, APA, ISO 690, IEEE)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / biblatex-philosophy v1.9.8g / make4ht v0.3m / TeX Live 2023 / Saxon-HE 12.9 / epubcheck 4.2.6 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Libros con Verona. El texto de las citas y de las referencias que van a HTML y EPUB no lo escribe una hoja XSLT: lo escribe biblatex, con el mismo estilo y la misma configuración que el PDF, a través de tex4ht (make4ht). Es la forma más directa de cumplir SC-14: el estilo no se replica, se usa.

POR QUÉ

Lo difícil de un estilo autor-año no es la puntuación, es lo que calcula biber: el orden, la letra del año (2020a, 2020b), la unicidad de nombres y de listas (`uniquelist=minyear`). Las hojas actuales no lo hacen en ningún estilo: el «iso690» de `docbook-to-html.xsl` ni siquiera sigue a `iso-authoryear`. La CSL nunca formó una referencia: era la etiqueta del selector.

Se descartó bblxml de biber: trae el cálculo pero no el formato, y está declarado obsoleto desde biber 2.15 («será quitado en la versión 4»; sigue en 2.23).

MEDIDO con `ref-l-MOLINARO.bib` (222 entradas): las 222 referencias del HTML tienen el mismo texto que el PDF, y las citas del cuerpo y de las notas también.

QUIÉN DECIDE EL CAMINO

Gambas, en un solo lugar: `m_GenerarSalidasLibro.PrepararCitasPantalla`. Si el estilo tiene archivo de pantalla, `~/.gbpublisher/latex/cita-<estilo>-html.tex`, el modo es `tex4ht`: escribe los insumos de la pasada (`m_GenerarPDFLibro.EscribirInsumosCitas`: la lista de piezas, `tmp/citas-proyecto.tex` y el `.bib`, con las mismas funciones que el PDF) y pasa el modo a `generar_html_libro.sh` y a `generar_epub_libro.sh`. Si no lo tiene, el modo es `xslt` y siguen las plantillas por estilo de las hojas. Los scripts reciben el modo y no lo vuelven a decidir.

Un estilo sin archivo de pantalla y sin plantillas en la hoja (hoy, cualquiera fuera de apa, iso690, ieee y vancouver) corta el HTML y el EPUB. Antes caía en un autor-año genérico que no es el del PDF.

LAS PIEZAS

1. `docbook-to-latex-citas.xsl`. Importa la hoja del PDF y sobrescribe solo la plantilla de pieza: escribe los mismos `refsection` que el PDF y cada grupo de citas como `\gbcita{id}{comando}`, con el comando que arma la plantilla de `biblioref` del PDF. Así las citas son las del PDF por construcción. Una cita de una nota va dentro de `\footnote`. Antes de `\gbImprimirBibliografia`, la marca `\gbbibliografia{sección-orden}`.
2. `cita-comun.xsl`. La regla del agrupamiento de citas (`gbct:grupo-desde`, `gbct:es-continuacion` y sus auxiliares), `gbct:comando-cita` (era `f:comando-cita` de `tex-comun.xsl`) y el id de cada grupo (`gbct:id-cita`). La incluyen el PDF, la pasada de citas y las hojas de HTML y EPUB: una sola regla. El estilo llega como parámetro explícito y no como variable global. Medido: los `.tex` del PDF de Duek salen idénticos byte a byte después de la mudanza.
3. `engine/preparar_citas_libro.sh`. Corre la hoja de citas por pieza, arma el documento mínimo `citas.tex` y lo compila con make4ht. Verifica el producto: XML bien formado, sin errores de biber, una marca `gbcita-` por cada `\gbcita` y una `gbbib-` por cada bibliografía. Salida: `tmp/bib/html-libro-<nombre>` y `tmp/bib/epub-libro` (carpeta fija: el proyecto tiene un solo EPUB, y el nombre de su archivo puede llevar espacios). `referencias/` queda para los datos canónicos.
4. `cita-fragmentos.xsl`. La lectura de `citas.html` para las hojas de HTML y EPUB: declara el parámetro `bib_dir`, busca cada grupo por su id y cada bibliografía por su marca, y copia el marcado a la salida en el espacio de nombres de XHTML. Cada hoja define la plantilla `gbct:enlace-cita`, porque el enlace de una cita no es igual en HTML (panel) y en EPUB (href).
5. `docbook-to-html.xsl` Y `docbook-to-epub.xsl`. Con `bib_dir`, el primer `biblioref` de cada grupo dibuja el texto de biblatex y los demás no emiten nada; el separador entre dos citas se suprime solo si la segunda quedó en el grupo de la primera (la regla del PDF). Las referencias son las que imprimió biblatex, en su orden, y cada una se une con su `biblioentry` por la clave: el `xml:id` es el destino de los enlaces. Sin `bib_dir`, la salida es la misma que antes (medido: idéntica byte a byte en las dos hojas).
6. EL CSS. `font-variant-caps: all-small-caps` para `.versalitas-todas` en `gbpublisher.css` y `gbpublisher-epub-libro.css` (SC-56). Sangría francesa: el EPUB ya la tenía en `.ref-item`; en el HTML va en `.ref-item.ref-biblatex`, solo para estas entradas, porque la hoja es común con revistas. Esas entradas van además en `--font-serif` (Noto Serif), la tipografía del texto, que trae `smcp` y `c2sc` (GV-104; decisión de Alberto).
7. EL SELECTOR DE ESTILOS lista los `cita-*-config.tex` de `~/.gbpublisher/latex/`, con la etiqueta de su primera línea (`% ESTILO: …`). `libros_md.estilo_cita` guarda el identificador (`apa`, `verona-modern`); la conversión de los `.csl` viejos la hace `actualizar-esquema-1.9.0.sh`.
8. LA CONFIGURACIÓN DE tex4ht, `cita-tex4ht.cfg`, viaja en `.hidden/latex/`, con las de estilo.

EL id DE CADA CITA

`gbcita-{sección}-{orden}-{n}`: sección y orden salen del `<info>` de la pieza; n es la posición, dentro de la pieza, del primer `biblioref` del grupo, contando los de las notas. Se cuenta dentro de la pieza y no en el libro: así es el mismo en el canónico de la pieza (PDF, pasada de citas, EPUB) y en el del libro ensamblado (HTML). Medido en Duek.

LA BIBLIOGRAFÍA DE CADA PIEZA

tex4ht numera las `refsection` (`cite.1@clave`, `cite.2@clave`). Para no repetir ese conteo, cada bibliografía lleva antes su marca: `<span id="gbbib-a-01">`, y `gbbib-libro` la consolidada. La lista de una pieza es la primera que sigue a su marca, si no hay otra marca en medio: una `refsection` sin citas no imprime lista. La unión cita-referencia es por pieza y clave, nunca solo por clave.

LA PASADA HTML USA LA MISMA CONFIGURACIÓN

Se carga `cita-verona-modern-config.tex` y después un archivo propio del estilo, `cita-verona-modern-html.tex`, con lo que cambia en pantalla:

    \ExecuteBibliographyOptions{backref=false,lowscauthors=false,dashed=false}
    \newcommand*{\gbImprimirBibliografia}{\printbibliography[heading=none,restoreclassic]}

Las tres opciones se aplican después de cargar biblatex (medido). `restoreclassic` no se puede fijar con `\DeclarePrintbibliographyDefaults` («keyval Error: restoreclassic undefined», medido). Por eso va en una macro que define cada estilo, y la hoja de citas emite siempre `\gbImprimirBibliografia`. Lo que es del estilo queda en el archivo del estilo, no en la hoja.

LA CONFIGURACIÓN DE tex4ht (medido)

- La cursiva de biblatex (`\emph`) sale como `<em>`; `\textsc`, como `<span class="versalitas-todas">`; el ordinal de babel-spanish (`n.º`), como punto y `<sup>`. `\bibfont` y `\footnotesize` se vacían: sin eso, cada tamaño de letra da un `<span>` con el nombre de la fuente (`ec-lmr-9`).
- `\gbcita{id}{...}` sale como `<span id="gbcita-id">` y `\gbbibliografia{x}` como `<span id="gbbib-x">`. En una compilación común no escriben nada.
- En babel-spanish `<` y `>` son activos: el marcado que inserta la configuración va con `\string<` y `\string>`. Sin eso: «Argument of \language@active@arg has an extra }».
- Las notas, en la misma página (`fn-in`): si no, cada nota sale en un archivo aparte.
- Un ancho de 500 cm: sin cortes de renglón no aparecen espacios espurios antes de una URL.

QUÉ PASA DE citas.html A LA SALIDA

Una lista cerrada: `em`, `strong`, `sup`, `del`, `u`, `span.versalitas-todas`, los enlaces externos y los enlaces de cita, que se vuelven el enlace de la hoja. Las anclas de tex4ht se descartan. Cualquier otro elemento corta la hoja con su nombre (GV-23): es un cambio de tex4ht o del estilo que hay que mirar. También cortan: `citas.html` ausente, un id de cita o una marca de bibliografía que no está, una referencia sin `biblioentry` en el canónico y una bibliografía cuyas etiquetas no son las del estilo: `[n]` en cada `<dt>` en un estilo numérico (`gbct:estilo-numerico`, hoy solo IEEE), ninguna en un autor-año.

LÍMITE CONOCIDO

Con tex4ht, biblatex no detecta las notas al pie («Patching footnotes failed»). En Verona no importa: philosophy solo lo usa en `scauthors=citefn` y `bibcitefn`, y la configuración usa `scauthors=bib`. La cita dentro de una nota salió igual que en el PDF. Un estilo que se comporte distinto en las notas, como los verbose, no entra por este camino sin medirlo antes.

EL ESTILO EN EL CANÓNICO DE CADA PIEZA

El agrupamiento depende del estilo en un caso: `suppress` con afijos en un estilo numérico. El PDF y la pasada de citas transforman el canónico de cada pieza, que no traía `csl-style`: `docbook-to-latex.xsl` agrupaba siempre como `apa`. Desde este lote (decisión de Alberto, cuatro puntos):

1. `m_XML.GenerarInfoCapituloXML`, BLOQUE 2c, escribe `<bibliomisc role="csl-style">` en el `<info>` de cada pieza, con el `estilo_cita` de su libro: el mismo valor que el bloque 15 del canónico del libro (RC-XJ-02: el dato de la base va en el canónico, no por parámetro).
2. `ensamblar-libro-canonico.xsl` lo descarta al copiar la pieza, como los tres marcadores de ubicación: el libro lo trae una vez en su propio `<info>` (medido: uno solo en el canónico ensamblado).
3. `preparar_latex_libro.sh` y `preparar_citas_libro.sh` cotejan el `csl-style` de cada canónico con el `\estandar` del preámbulo o de las definiciones (`estilo_canonico`, en `comun.sh`). Si falta o no coincide, la pieza falla con «el canónico declara el estilo «…» y el libro usa «…»: regenerá el canónico». Así un cambio de estilo sin regenerar no compone con un estilo y agrupa con otro. HTML y EPUB por las plantillas de la hoja agrupan con el estilo que pasa Gambas, que es el de la base; por tex4ht, la pasada de citas ya cotejó.
4. Los canónicos anteriores a este lote no traen el dato: la primera generación de cada libro corta hasta regenerarlos (GV-23: mejor cortar que tomar `apa` en silencio).

MEDIDO con Duek: con los canónicos viejos, las nueve piezas fallan con el mensaje; con el dato, los `.tex` del PDF salen idénticos byte a byte a los anteriores (para un autor-año el agrupamiento no cambia); con el estilo del libro distinto del canónico, la pasada de citas corta.

APA

`cita-apa-html.tex` no cambia ninguna opción: `cita-apa-config.tex` ya carga `backref=false`, y biblatex-apa repite el nombre en cada entrada y no usa versalitas. Solo define `\gbImprimirBibliografia` como `\printbibliography[heading=none]`.

MEDIDO con el libro de Duek, contra el PDF que Alberto compuso en Mint con APA: las 132 citas y las 113 referencias de `citas.html` tienen el mismo texto que el PDF (las únicas diferencias de la comparación son cortes de página del PDF). HTML: vnu sin errores. EPUB: epubcheck 4.2.6 sin errores.

En las notas no hay límite: `\iffootnote`, que tex4ht no puede responder, en `apa.cbx` solo lo usa `\smartcite`, y la aplicación no lo emite.

Lo que reemplaza: las plantillas de APA de las hojas ordenaban las referencias como el canónico y no como el estilo, repetían el título de la obra en las partes de libro («La juventud es más que una palabra. La juventud es más que una palabra, 13-30») y unían dos autores con «y» donde biblatex-apa pone «&».

ISO 690

`cita-iso690-html.tex` cambia solo los nombres: en el PDF van `\textsc{\MakeLowercase{...}}`; en pantalla, `\textsc{...}` con la caja de la base, y las versalitas las pone el CSS. Es la decisión de Verona (SC-56). Las nuevas definiciones se agregan después de las del PDF (`\familynameformat` y un `\AtBeginBibliography`) y las pisan. Define `\gbImprimirBibliografia` como `\printbibliography[heading=none]`. RF-13.

MEDIDO con el libro de Duek, contra el PDF que Alberto compuso en Mint con ISO 690: las 132 citas y las 113 referencias de `citas.html` tienen el mismo texto que el PDF, sin distinguir caja, que es lo único que cambia a propósito (las dos diferencias de la comparación son cortes de página del PDF). HTML: vnu sin errores. EPUB: epubcheck 4.2.6 sin errores.

IEEE

`cita-ieee-html.tex` no cambia nada: solo define `\gbImprimirBibliografia` como `\printbibliography[heading=none]`. RF-14.

La etiqueta `[n]` de cada entrada llega en el `<dt>` de `citas.html` y sale como `span.ref-numero`, la marca del camino por plantillas. Sangría (decisión de Alberto, opción b): la etiqueta ocupa una columna del ancho de la más ancha de su lista (`ref-etiqueta-1`, `-2` o `-3`, por las cifras) y todas las líneas del texto arrancan después, como en `thebibliography` del PDF. Columnas de 1,8, 2,4 y 3 em: anchos medidos en Chromium, con IBM Plex Sans Bold en el panel del HTML y Noto Serif Bold en el EPUB. La hoja descarta el salto de línea con que tex4ht abre cada `<dd>`: detrás de la etiqueta se veía como un espacio y corría la primera línea.

MEDIDO con el libro de Duek, contra el PDF que Alberto compuso en Mint con IEEE: las 132 citas de `citas.html` tienen el texto del PDF; de las 113 referencias, 102 son iguales, diez difieren solo por la extracción del PDF (guiones de URL al cortar la línea, una URL partida por el cambio de página) y una por la cadena `presentedat` sin traducir del PDF (GV-106, SC-59). Alineación medida en Chromium: en todas las entradas de varias líneas, la segunda arranca donde arranca el texto de la primera. HTML: vnu sin errores. EPUB: epubcheck 4.2.6 sin errores. ISO 690 por el mismo camino: la salida no cambia salvo espacios en blanco.

El camino viejo por plantillas numeraba IEEE de corrido en todo el libro («[20, p. 47]» donde el PDF dice «[1, p. 47]»): por tex4ht la numeración vuelve a 1 en cada pieza, como en el PDF.

ALCANCE

Verona, APA, ISO 690 e IEEE. Los demás estilos siguen con sus hojas hasta que se releven (SC-14: un estilo sin RF no se implementa), y cuando entren lo hacen por este mismo camino, con su archivo `-html.tex`.

**Relaciones:** vinculo:SC-14,vinculo:SC-56,vinculo:SC-31,vinculo:SC-42,vinculo:RF-12,vinculo:GV-102,apoya:GV-23,vinculo:GV-103,vinculo:GV-104,vinculo:SC-58,vinculo:GV-105,vinculo:RF-13,vinculo:RF-14,vinculo:SC-59

**PENDIENTE:** Implementado y medido en el contenedor con el libro de Duek (132 citas, 113 referencias): el texto de cada cita del HTML y del EPUB es el de citas.html, y las referencias de cada pieza son las mismas y en el mismo orden; los enlaces de cita del EPUB no tienen destinos rotos; vnu sin errores en el HTML; epubcheck 4.2.6 sin errores en el EPUB; bibliografía consolidada simulada (103 referencias) en HTML y EPUB; los cortes de la hoja con un citas.html incompleto. Falta: la prueba en Mint con un libro real; cómo responden los lectores de EPUB a all-small-caps; la fuente del panel de referencias del HTML (GV-104).

### SC-58 — Órdenes de LaTeX en las referencias: solo \enquote, \sptext, \emph y el signo \&

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** TeX Live 2023 / biblatex 3.19 / biblatex-apa v9.17 / make4ht v0.3m / Gambas 3.19 / jing, DocBook 5.2 / Chromium / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). En los campos de una referencia se admiten tres órdenes de LaTeX y ninguna otra:

    \enquote{…}   cita entre comillas; el nivel lo decide el anidamiento (ver NIVELES)
    \sptext{…}    ordinal de babel-spanish: n\sptext{o} es «n.º»
    \emph{…}      énfasis; dentro de un título en cursiva da redonda (el «enroque»)

Los puntos suspensivos se escriben `...`, como en el Markdown: Markdown no es LaTeX.

EL SIGNO &

Va escapado, `\&`: aparece en algunos nombres de revista («Población \& Sociedad», en el `.bib` de Duek). Sin la barra, LaTeX lo toma como separador de columnas y el PDF corta («Misplaced alignment tab character &», medido); por eso un `&` sin barra se rechaza con su mensaje. `\&` da «&» en el PDF y `&amp;` en tex4ht (medido); en el canónico es el carácter, escapado (`&amp;`).

LOS CAMPOS LITERALES

`doi`, `eprint`, `file` y `url` no pasan por la regla (`m_Bibtex.EsCampoLiteral`): biblatex los toma sin interpretar LaTeX (tipos `verbatim` y `uri` de `blx-dm.def`, 3.19), y una URL puede llevar `&` sin escapar.

NIVELES DE \enquote

csquotes admite dos niveles de comillas (`maxlevel`, por omisión 2; manual §2.1); el tercero corta el PDF. Algunos estilos ponen entre comillas el título de ciertos tipos de entrada, y ese es ya el primer nivel. La regla (decisión de Alberto; `m_Bibtex.NivelesEnquote`):

- EN EL TÍTULO Y EL SUBTÍTULO de article, conference, inbook, incollection, inproceedings, inreference, online, patent, report, thesis y unpublished: un solo nivel de `\enquote`. El subtítulo va dentro de las mismas comillas que el título (medido con Verona).
- EN CUALQUIER OTRO CAMPO O TIPO (el título de un libro, en cursiva; el nombre de la revista): hasta dos niveles. `\enquote{huelga \enquote{general}}` en el título de un libro es correcto.
- TRES NIVELES: nunca.

La lista es la unión de los estilos de la aplicación y no la del estilo del libro: el estilo se puede cambiar después (el criterio de RC-BL-02). Con APA o ISO 690, un artículo no puede llevar dos niveles en el título aunque esos estilos no le pongan comillas; son casos muy raros y aislados. Sale del fuente:

    biblatex.def (3.19, línea 580)   article inbook incollection inproceedings patent thesis unpublished
    philosophy-standard.bbx (290)    article inreference (287: thesis en cursiva)
    ieee.bbx (51)                    online report
    apa.bbx (482), iso.bbx (182)     ninguno

`conference` es el alias de `inproceedings` en biber.

MEDIDO: con Verona, `\enquote{huelga \enquote{general}}` en el título de un artículo corta el PDF («Package csquotes Error: Unbalanced groups or invalid nesting») y el HTML de tex4ht sale con «huelga __general__». Sin biblatex, `\enquote{a \enquote{b \enquote{c}}}` da el mismo error. Con un solo nivel, Verona compone «El 1.º de mayo y la “huelga general”».

Se descartaron dos caminos. `maxlevel=3` es documentado y compila, pero el tercer nivel reusa los signos exteriores («a “b «c»”», medido) y no da las ‘ ’ de SC-30: el manual no tiene un comando para un tercer par de signos (`\DeclareQuoteStyle`, §8.1, recibe un par exterior y uno interior). Las ‘ ’ en el tercer nivel solo se lograrían con macros internas de csquotes, sin documentar. Las llaves de BibTeX siguen siendo legítimas: agrupan un nombre (`{de la Fuente}`) o protegen una mayúscula (`{I}'ve`).

POR QUÉ HACE FALTA UNA REGLA

Los mismos campos van al `.bib`, que interpreta biblatex, y al `<bibliography>` del canónico, que no es LaTeX. Antes, el canónico quitaba las llaves y nada más: `\enquote{cuestión militar}` llegaba como «\enquotecuestión militar».

LA REGLA ES UNA SOLA: `m_Bibtex.ProblemaOrdenesLatex`

Solo las tres órdenes, cada una con su llave pegada, y las llaves balanceadas. La usan tres controles:

1. EL FORMULARIO, al guardar una referencia nueva, al guardar cambios y al guardar un título repetido (`VerificarOrdenesLatex`). Si un campo no cumple, avisa con un mensaje y la referencia no se guarda.
2. LA EXPORTACIÓN DEL `.bib` (`ExportarBibTeX`): lo que ya estaba en la base o llegó sin pasar por el formulario. Con una sola entrada que no cumple, el `.bib` no se escribe y el mensaje lista todas, con su clave y su campo.
3. EL CANÓNICO (`m_XML.TextoBibDocBook`): si un `.bib` viejo trae una orden no admitida, corta con `Error.Raise`.

EL CANÓNICO DE LIBROS

`m_XML.TextoBibDocBook` reemplaza a `EscaparXML(QuitarLlavesBib(...))` en los campos de texto de `<biblioentry>`:

    \enquote{x}   ->  <quote>x</quote>          (los niveles: quote.xsl)
    \emph{x}      ->  <emphasis>x</emphasis>
    \sptext{x}    ->  .<superscript>x</superscript>

El punto de `\sptext` es el que pone babel-spanish (`\es@orddot`): así el canónico dice lo mismo que el PDF. Los nombres siguen con `QuitarLlavesBib`.

MEDIDO: los tres elementos son válidos en `title`, `citetitle`, `bibliomisc`, `publishername`, `city`, `edition` y `orgname` (jing con el Relax NG de DocBook 5.2, con un control negativo). Con las 16 referencias de Molinaro que usan `\enquote` o `\emph`, el resultado valida; las 2 con `\dots` se rechazan, como corresponde.

EN LAS SALIDAS (medido)

    .bib                                   PDF                    HTML y EPUB (tex4ht)
    \enquote{huelga \enquote{general}}     «huelga “general”»     «huelga “general”»
    El 1\sptext{o} de mayo                 1.º                    1.<sup>o</sup>
    Revista \emph{Nueva} (en cursiva)      Nueva en redonda       <em>Revista <em>Nueva</em></em>

Para el enroque en pantalla, `em em { font-style: normal; }` en `gbpublisher.css` y `gbpublisher-epub-libro.css`: es lo que hace `\emph` en LaTeX. Verificado en Chromium.

ALCANCE

Libros. Revistas arman su `element-citation` de JATS desde el mismo `.bib` sin traducir ni escapar; se resuelve cuando se encare revistas entero, después de libros (decisión de Alberto). Molinaro, que trae `\dots`, sale por legacy y no se corrige.

**Relaciones:** vinculo:SC-57,vinculo:SC-30,vinculo:SC-14,apoya:GV-23,vinculo:SC-62

**PENDIENTE:** Resuelto en act-46: IEEE va por tex4ht y las comillas salen de biblatex. Las plantillas por estilo de las hojas (las que leen el título con normalize-space y pierden las comillas de un <quote>) solo quedan para un libro sin la pasada de citas. \sptext es de babel-spanish: un libro cuyo idioma principal no sea el español no lo tiene definido. Probado por Alberto en Mint con APA: las tres salidas y los tres controles. Medido en el contenedor con Verona: \sptext y \emph bien en el PDF y en tex4ht.

### SC-59 — Cadenas en castellano comunes a todos los estilos de biblatex: cita-cadenas-es.tex

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biblatex-philosophy / biblatex-apa / biblatex-iso690 v0.4.1 / biblatex-ieee v1.3f / LuaLaTeX / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Las cadenas de biblatex se reparten en dos clases (decisión de Alberto, 17/10):

A. LAS QUE NI biblatex (`spanish.lbx`) NI EL ESTILO TRAEN. Son la traducción de los códigos del catálogo de la aplicación (tabla `cmb_biblatex`: `editor_type`, `thesis_type`, `pubstate`) y los agregados de la editorial (cine, `\sq`, `\sqq`, `documentjob`, `origpubbare`). Van en `.hidden/latex/cita-cadenas-es.tex`, uno solo para todos los estilos. Una cadena así solo aparece si una entrada la usa: en un estilo que no la necesita no cambia nada.

B. LAS QUE `spanish.lbx` YA TRAE Y UN ESTILO REDEFINE (meses, `url`, `urlseen`, `phdthesis`, `compiler`, `nodate`…). Son decisiones de cada estilo y quedan en su `cita-<estilo>-config.tex`. MEDIDO: las de Verona aplicadas a IEEE cambian «comp.» por «compilador», «dirección:» por «recuperado de:» y «oct.» por «octubre».

Las cadenas propias de un estilo (`presentedat` y `patentjp` de IEEE, RF-14) van en su config.

QUIÉN LO CARGA

El que carga el estilo, inmediatamente después de `cita-<estilo>-config.tex` (`\NewBibliographyString` exige biblatex cargado): `preambulo-contrato.tex` (PDF de libros) y el documento mínimo de `preparar_citas_libro.sh` (pasada de tex4ht), por nombre; `m_XML.ObtenerPreambuloEmbebido` (revistas), con ruta absoluta. No lo carga el config: `\input` resuelve contra la carpeta de la compilación, no contra la del archivo que lo pide, y en revistas el config se carga por ruta absoluta desde otra carpeta. Sin biblatex (vancouver, que va por bibtex) el archivo termina sin definir nada.

Llega al proyecto con `CopiarRecursosLatex`, que copia todos los `.tex` de `~/.gbpublisher/latex/`; `preparar_citas_libro.sh` lo copia a la carpeta de la pasada y corta si falta.

LOS CÓDIGOS DEL CATÁLOGO SON EL CONTRATO

Antes de este lote cada config tenía su lista, y se habían separado: ISO 690 usaba claves propias (`licenciaturathesis`, `tifthesis`, `organizator`…) que el catálogo no ofrece, y no tenía catorce de las que sí ofrece. El código `self-published` del catálogo no tenía cadena en ningún estilo (la configuración traía `edauthor`). Las claves heredadas de ISO 690 quedan como alias, para un `.bib` escrito a mano.

ERRATAS CORREGIDAS EN EL MISMO LOTE

- Verona: `phdthesis` dice «Tesis de Doctorado», como ISO 690 (decisión de Alberto).
- ISO 690: «con introdución de» → «con introducción de»; `prepublished` estaba dos veces; `bytranslatorfo` va en su propio bloque con `\makeatletter`, como en Verona: dentro del bloque general `\lbx@lfromlang` se leía `\lbx` seguido de texto.

MEDIDO en el contenedor con el `.bib` de Duek y un banco de 50 entradas (todos los códigos del catálogo, una traducción con prólogo e introducción, un congreso, una obra sin fecha, `\sq` y `\sqq`), antes y después, en los cuatro estilos de libro:
- Verona: un solo cambio, «Tesis Doctoral» → «Tesis de Doctorado».
- ISO 690: los catorce tipos de tesis que salían como código salen traducidos.
- APA: los tipos de tesis salen traducidos; `\sq` y `\sqq`, que no estaban definidos, funcionan.
- IEEE: «coord.», «coords.», «dir.», «dirs.», los tipos de tesis, «mimeo», «fotocopia», «impresión digital», «presentado en», `\sq` y `\sqq`.
- Ningún error ni cadena sin traducir en el `.log` de los cuatro.

Con `\sq` la postnota deja de ser un número y biblatex no le antepone «p.» ni «pág.» («25 y sig.»): es el comportamiento de biblatex, el mismo que ya tenía Verona.

**Relaciones:** vinculo:SC-14,vinculo:SC-57,vinculo:RF-09,vinculo:RF-12,vinculo:RF-13,vinculo:RF-14,vinculo:GV-106

**PENDIENTE:** Falta la prueba en Mint: el PDF de un libro con cada estilo y una revista. La diferencia de `nodate` entre Verona («s/f») e ISO 690 («sin fecha») queda como decisión de cada estilo, sin revisar.

### SC-60 — Notas internas: temas con ciclo de vida, por proyecto o 1 a 1

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / Gambas 3.22 / Linux Mint (prueba de Alberto, 20/10) · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, octubre de 2026). Reemplaza a `postits`, retirada en la 1.12.0. Se evaluó un chat al estilo Zulip y se descartó: el equipo necesita temas que se notifican, se siguen y se cierran, no conversación en caliente.

MODELO

- Una nota es 1 a 1 (a otro usuario o a uno mismo) o de proyecto (al grupo del proyecto). Tiene una cosa o la otra (`CHECK chk_notas_destino`).
- El grupo de un proyecto es único (`notas_grupos`).
  - Lo crea un usuario con el proyecto abierto, y queda como creador y miembro.
  - Solo el creador suma y da de baja miembros. La baja es lógica, y cada alta y cada baja queda registrada.
  - Un miembro nuevo ve todo lo activo del grupo, pero no lo archivado antes de su alta.
- Las respuestas van dentro de la nota, como hilo. El texto de una nota no se edita.
- Cerrar = archivar: lo hace solo el autor, y nada se borra. La hora de despacho opcional (`desde`) oculta la nota a los destinatarios hasta esa hora.
- Archivadas: las ve quien participó, es decir, autor, destinatario, quien respondió o quien la abrió (`notas_vistas`). Leer cuenta como participar.
- Sin roles en `usuarios`: el administrador actúa desde FSysAdmin (pestaña «Notas», `hConnServidor`).
  - Transfiere el rol de creador de un grupo con creador inactivo.
  - Cierra las notas de un usuario inactivo.
  - Al archivar un proyecto, cierra las notas de su grupo en la misma transacción.
  - Lo que cierra queda firmado en `cierre_sistema`.

INTERFAZ

- La pestaña «Notas» de FMain (`TabStrip1`, índice 8), con `m_Notas` como módulo dueño. Los handlers de FMain solo delegan.
- El indicador: `pbNotas` más `lblNotas` en `HBox3`.
- Alcance común: pestaña e indicador solo existen con sesión y proyecto abierto. Muestran las notas 1 a 1 del usuario más las del grupo del proyecto abierto.
- Índice de días corridos sin actividad: 0–3 verde, 4–6 ámbar, 7 o más rojo. En el indicador, rojo gana sobre verde.

SONDEO

- Lo dispara el latido de `TimerRed` (30 s), y solo con la red en verde.
- Usa una conexión propia, con plazo de lectura (GV-110).
- Hace una consulta por tick. Su firma incluye las notas, las respuestas, los cierres y el estado del grupo; la pestaña se recarga solo si cambió.
- Horas: las fechas viajan como segundos transcurridos según el servidor y se muestran con el reloj local. La hora de despacho viaja como segundos desde ahora, así que sirve con usuarios en otro huso horario (Argentina–Colombia).

ESQUEMA

- La 1.10.0 crea `notas`, `notas_grupos`, `notas_miembros`, `notas_respuestas` y `notas_vistas`, con claves `RESTRICT` (GV-111), y migra `postits` con el mismo id.
- La 1.12.0 retira `postits`.

**Relaciones:** vinculo:SC-22,vinculo:GV-110,vinculo:GV-111,vinculo:GV-112,vinculo:GV-107,vinculo:GV-78,vinculo:GV-57

### SC-61 — Alineación de párrafos en el PDF: alinear-izq, alinear-centro, alinear-der

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / LuaLaTeX (TeX Live 2023) / gbc3 3.19 / contenedor Ubuntu 24.04; gbpublisher en Linux Mint (prueba de Alberto, 21/10) · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 21/10). Segundo caso de las instrucciones de composición (SC-38) y primero de un tramo: alinea uno o más párrafos a la izquierda, al centro o a la derecha. Solo PDF, de libros y de revistas. En el EPUB y el HTML el párrafo sale como cualquier otro: una fecha y un lugar se leen mejor a la izquierda en una pantalla, y a la derecha en la página impresa.

    ::: alinear-der

    19 de octubre de 2026, Ciudad de México

    [/alinear-der]: # ()
    :::

TRES CLASES Y NO UNA CON ATRIBUTO

`alinear-izq`, `alinear-centro` y `alinear-der`. Con el modo `envolver`, el panel inserta el bloque directo sobre la selección, sin escribir nada a mano. Un atributo hubiera pedido un modo nuevo o escribirlo en la apertura, como `patron` en el verso (SC-49), que además significa otra cosa.

UNA FICHA POR PÁRRAFO

`alinear.lua` desenvuelve el bloque y pone `<?gb-alinear izq|centro|der?>` como primer nodo de cada párrafo, en JATS y en DocBook (GV-115). No es un par apertura/cierre alrededor del tramo: el grupo de LaTeX abre y cierra dentro del mismo párrafo y nunca queda desbalanceado, aunque el canónico se edite. Un par de instrucciones hermanas se habría partido con cualquier cosa que se metiera entre ellas (en libro, un título, porque Pandoc arma las secciones al escribir).

PDF

La plantilla de párrafo de cada hoja (`para` en `docbook-to-latex.xsl`, `p` en `jats-to-latex.xsl`) toma la ficha con `f:alinear-ficha`, no se la pasa a `apply-templates` y envuelve el párrafo con `f:alinear-abre` y `f:alinear-cierra` (`tex-comun.xsl`):

    izq      \begingroup\raggedright\noindent TEXTO\par\endgroup
    centro   \begingroup\centering\noindent TEXTO\par\endgroup
    der      \begingroup\raggedleft\noindent TEXTO\par\endgroup

- El `\par` va dentro del grupo: TeX lee `\leftskip` y `\rightskip` al cerrar el párrafo.
- Declaraciones y no los entornos `flushleft`, `center` y `flushright`. Los entornos son listas (`trivlist`) y agregan espacio arriba y abajo. El aire lo pone `espaciov` (SC-39): cada shortcode hace una sola cosa.
- `\noindent` en las tres, también en `izq` (decisión de Alberto).
- Sin corte de palabra en las tres (decisión de Alberto). Las declaraciones ya no parten (GV-113). No se agregan penalidades: una nota al pie del párrafo las heredaría y perdería su corte (GV-114). La alineación, en cambio, no le llega a la nota.

Una ficha desconocida en `f:alinear-abre`, o una `gb-alinear` que llegue a la plantilla de la instrucción (a mitad de un párrafo, en una nota, un pie, un ítem, un resumen), corta la transformación con un mensaje. El filtro ya lo impide; esto cubre un canónico armado por otro camino.

FRENA LA CONVERSIÓN (CON MENSAJE)

Un bloque vacío; algo que no sea un párrafo (título, lista, figura, cita, otro bloque); un salto de línea manual en un párrafo (SC-49: hoy no sirve en prosa, y en libro volvería el párrafo un `<literallayout>`, donde la ficha quedaría fuera de un `<para>`); dos clases en la apertura; un identificador o un atributo; una alineación dentro de otra; un bloque que no esté en el primer nivel (dentro de otro bloque, una lista, una tabla o una nota). Como en `espaciov`, en revista el filtro corre después de `unwrap-structural-divs.lua`, así que dentro de una sección estructural vale.

Cada renglón es su propio párrafo, separado por una línea en blanco. Por eso un lugar, una fecha o una firma en varios renglones no necesitan el salto manual.

SALIDAS

- Canónico: la ficha al comienzo de cada `<para>` o `<p>` del bloque.
- PDF: el párrafo en su grupo, como arriba.
- HTML y EPUB, de libros y de revistas: el párrafo común. La regla incorporada de XSLT no escribe nada para la instrucción (SC-38).
- SciELO y Redalyc: la plantilla vacía de SC-38. Crossref y DOAJ no llevan el cuerpo.
- ODT: los párrafos, sin el bloque ni la ficha.

CADENAS

`alinear.lua` corre justo después de `espacio-vertical.lua` en las tres: `generar_canonicos_capitulos.sh` (libro, antes de `fenced-divs-to-elements-db.lua`), `m_XML` (revista, después de `unwrap-structural-divs.lua` y antes de `cite-to-xref.lua`) y `m_GenerarODT`.

ANÁLISIS DEL PROYECTO

`m_AnalizarProyecto.Destino` dejaba fuera de los conteos todo el grupo `composicion`. El texto de un bloque de alineación es cuerpo. Ahora decide por el modo del catálogo: `envolver` es cuerpo, el resto (`separador-valor`, `espaciov`) no se cuenta (SC-38).

CATÁLOGO

Tres filas de gbShortcodes, grupo `composicion`, modo `envolver`, después de `espaciov`.

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de libro y de revista, incluidos los casos que frenan; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, `docbook-to-latex.xsl`, `jats-to-latex.xsl`, `jats-to-html.xsl`, `jats-to-epub.xsl`, `jats-to-scielo.xsl` y `jats-to-redalyc.xsl`; el capítulo valida contra el RNG de DocBook 5.2 y el artículo contra la DTD Archiving 1.4; el cuerpo del .tex compila con LuaLaTeX en la clase book y se ve alineado (no con el preámbulo del proyecto); gbpublisher compila con gbc3 3.19.

PROBADO EN MINT

Alberto, 21/10, con un libro y una revista reales: las tres alineaciones, con negrita, bastardilla, una referencia y una nota al pie que lleva otra referencia, junto a `espaciov` y al froufrou. PDF: cada párrafo en su lugar, sin sangría; un párrafo centrado pasa bien de página; la nota sale justificada y con corte, como cualquier otra (GV-114). HTML y EPUB: el párrafo común, a la izquierda y con la separación de los párrafos.

**Relaciones:** vinculo:SC-38,vinculo:SC-39,vinculo:SC-33,vinculo:SC-34,vinculo:SC-49,vinculo:GV-113,vinculo:GV-114,vinculo:GV-115

**PENDIENTE:** ODT: se encara cuando estén terminadas las salidas PDF (decisión de Alberto, 21/10). Sin confirmar en Mint: la inserción desde el panel, el conteo de m_AnalizarProyecto y el mensaje de un caso que frena (probados solo en el contenedor, los casos que frenan). Las hojas de HTML y EPUB de libros no se corrieron sueltas en el contenedor; en Mint salieron bien.

### SC-62 — Letra volada en el texto: n\sptext{o}

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / LuaLaTeX (TeX Live 2023) / babel-spanish 5.0q / hyperref / qpdf / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 21/10). La letra volada de los ordinales y las abreviaturas (n.º, 1.ª, 3.er, C.ía, V.º B.º) se escribe en el .md como en LaTeX y como en las referencias (SC-58): `n\sptext{o}`. Una sola notación en todo el proyecto. Los Word de los autores la traen de todas las formas (nº, n°, Nº, n.º, superíndice de Word); esta es la que se fija.

    El n\sptext{o} 3, la 1\sptext{a} edición, el 3\sptext{er} piso.

No es un bloque `:::` ni un span: va pegada a su base, dentro del texto. Sin un filtro, Pandoc la descartaba en las tres salidas (GV-116).

LA REGLA, ABIERTA (decisión de Alberto)

- Adentro, una o más minúsculas, con o sin tilde, diéresis o virgulilla: `o`, `a`, `er`, `os`, `ía`.
- Antes, pegada, una letra (también mayúscula o con tilde) o una cifra: `n`, `1`, `21`, `V`, `D`. Nunca un punto: el punto lo pone `\sptext` (babel-spanish, `\es@orddot`), y `n.\sptext{o}` saldría «n..º».
- Solo en texto en español: `\sptext` es de babel-spanish y en otro idioma el PDF no compila (GV-105). Frena (decisión de Alberto): el editor o el corrector deben saber que es exclusiva del español.

Vale en cualquier lugar del texto: párrafos, títulos de sección, notas, pies, celdas, recuadros, versos, epígrafes, conversaciones, bloques alineados.

FRENA LA CONVERSIÓN (CON MENSAJE)

`volada.lua`, en las tres cadenas: una volada vacía, con mayúsculas, cifras u otros signos adentro; sin base pegada (un espacio, un comienzo de párrafo, una bastardilla antes); con un punto antes; en un artículo cuyo `-M gb-idioma` no es español; dentro de un tramo marcado en otro idioma (`[…]{lang=en}`).

Las hojas LaTeX repiten dos controles sobre el canónico: el idioma, con `fn:lang` sobre el `xml:lang` más cercano, y el punto antes. En el libro, el del idioma es el único: la cadena del libro no le pasa el idioma del capítulo a Pandoc, y no se puede usar `gb-idioma`, porque `conversacion.lua` lo usa para otra cosa. Un capítulo en otro idioma con una volada se genera en HTML y EPUB y frena en el PDF.

CANÓNICO, COMO SC-58

    JATS      n.<sup specific-use="volada">o</sup>
    DocBook   n.<superscript role="volada">o</superscript>

El punto queda en el texto: un indexador o un lector de pantalla lee «n.º». En JATS, `<sup>` admite `specific-use` y no `content-type` (DTD 1.4, `JATS-format1-4.ent`).

PDF

`f:volada-latex` (`tex-comun.xsl`) devuelve `\sptext{o}`. La plantilla del texto que precede a la volada le quita el punto final (`f:sin-punto-final`). Las dos plantillas, la de la volada y la del texto, van en `docbook-to-latex.xsl` y en `jats-to-latex.xsl`, no en `tex-comun.xsl`: una importada pierde contra `text()`, `superscript` y `sup` de la hoja (GV-117).

En el argumento opcional de un título, que va a los marcadores (`notasTitulo = sumario`), sale `\texorpdfstring{\sptext{o}}{.º}` (GV-118).

HTML Y EPUB

`n.<sup>o</sup>`, con las plantillas de superíndice que ya existen. SciELO y Redalyc copian el `<sup specific-use="volada">`, que es JATS válido.

ODT

El punto y la volada en superíndice.

CADENAS

`volada.lua` corre antes de todo filtro que serialice con `pandoc.write`, que la descartaría (GV-116). Libro: segundo, después de `guillemets-to-quoted-db.lua` y antes de `cite-to-biblioref-db.lua`, que serializa las notas. Revista: después de `alinear.lua` y antes de `cite-to-xref.lua`. ODT: después de `alinear.lua`.

CATÁLOGO

Una fila de gbShortcodes: `sptext`, en línea, grupo `comun`, modo `plantilla`. El panel inserta `\sptext{•}` con el marcador seleccionado.

RESALTADO

`Markdown.highlight`: el estado `latex.sptext`, con el estilo `Function` de los shortcodes, que los nueve temas ya definen en `[Markdown]`. El patrón se escribe una vez con `$(sptext)` y se repite como hijo dentro de la bastardilla, la negrita y el tachado (GV-119). En un título la línea queda entera en `Header`.

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de libro, revista y ODT, en todos los lugares de arriba, incluidos los casos que frenan; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, las dos hojas LaTeX, HTML, EPUB, SciELO y Redalyc; el capítulo valida contra el RNG de DocBook 5.2 y el artículo contra la DTD Archiving 1.4; el cuerpo del .tex compila con LuaLaTeX en la clase book, con hyperref y el sumario; los marcadores leídos con qpdf; el control del idioma frena con un capítulo y un artículo en inglés; gbpublisher compila con gbc3 3.19.

FUERA DE ESTA DECISIÓN

- DESCARTADO (decisión de Alberto, 21/10): la normalización al ingresar el Word (`limpiar_docx.lua`). Se resuelve sobre el .md. Lo que se había evaluado: «nº», «Nº», «n.º» y el superíndice de Word se podrían escribir como `n\sptext{o}`, pero «n°» y «1°» llegan con el signo de grado, que también es legítimo («20 °C»).
- El control general de las órdenes de LaTeX en línea que se pierden (GV-116): hecho en SC-54, en libros.

PROBADO EN MINT

Alberto, 21/10, con un libro y una revista reales: PDF, HTML y EPUB bien.

Los casos que frenan, también en Mint (Alberto, 21/10): `n.\sptext{e}` (punto antes) y `n\sptext{K}` (mayúscula) cortan la generación del canónico con su mensaje; `n\sptext{k}` genera. La inserción desde el panel deja `\sptext{•}` con el marcador para escribir encima. Liberada con gbShortcodes `datos-v5-015.sql`.

**Relaciones:** vinculo:SC-58,vinculo:GV-105,vinculo:GV-116,vinculo:GV-117,vinculo:GV-118,vinculo:SC-29,vinculo:SC-21,vinculo:GV-119,vinculo:SC-54

**PENDIENTE:** El ODT, cuando se encare (decisión de Alberto, 21/10).

### SC-63 — Corte de línea en los títulos de sección del .md: \\, como en la base

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / LuaLaTeX (TeX Live 2023) / titlesec / hyperref / qpdf / gbc3 3.19 / contenedor Ubuntu 24.04; gbpublisher en Linux Mint (prueba de Alberto, 21/10) · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 21/10). La regla de SC-28 vale también para los títulos de sección que se escriben en el .md (`##` y siguientes en libros; todos los niveles en revistas): el editor marca el corte con `\\` y el corte se cumple solo en la apertura del PDF.

    ## Corte de\\ subtítulo

En el sumario, el folio, los marcadores, el HTML, el EPUB, el ODT y los indexadores, el corte es un espacio. En libros el `#` del .md no llega al canónico: el título del capítulo sale de la base y ya tiene su regla (SC-28).

LA REGLA

- Varios cortes por título (decisión de Alberto): `Uno\\ dos\\ tres`.
- Frena si un corte queda al principio o al final del título, si hay dos seguidos o si va dentro de una bastardilla, una negrita u otra marca. Un `<break/>` dentro de `<italic>` partiría la marca en el PDF.
- El espacio después de `\\` es opcional: `Pegado\\sin` corta igual.
- Fuera de un título no hay corte: el control `corte_fuera_de_titulo` (SC-54) lo informa. Para un salto fuera de un título está `espaciov` (SC-39).

CANÓNICO, EL DE SC-28

`corte-titulo.lua` (GV-121) escribe la marca de SC-28 con UN espacio, antes:

    JATS      <title>Corte de <break/>subtítulo</title>
    DocBook   <title>Corte de <?gb-corte?>subtítulo</title>

SC-28 pone un espacio a cada lado porque sus títulos van planos a muchos destinos. Acá basta uno: el valor de texto de la marca es vacío, así que una salida que lee el título como cadena ve «Corte de subtítulo», y una plantilla vacía para la marca no deja dos espacios. El `<break/>` dentro del `<title>` de un `<sec>` valida contra la DTD Archiving 1.4 (medido). La instrucción de procesamiento, contra el RNG de DocBook 5.2.

PDF

Las plantillas de título de sección de las dos hojas arman el título dos veces (SC-29): la apertura y el argumento opcional que va al sumario, al folio y a los marcadores (`notasTitulo`).

- `docbook-to-latex.xsl`: una plantilla para `processing-instruction('gb-corte')` escribe `\gbCorteTitulo` en la apertura y nada en el sumario. Los títulos que vienen de la base no pasan por ella: los arman `f:titulo-compuesto` y `f:titulo-plano`.
- `jats-to-latex.xsl`: `sec/title/break` hace lo mismo. La plantilla general de `break` escribe `\\` sin mirar el contexto, y en un título habría ido también al sumario y a los marcadores.

`\gbCorteTitulo` ya está en el contrato del libro (versión 6) y en el preámbulo de la revista (`m_XML`): no hay contrato nuevo.

MEDIDO: el .tex compila con LuaLaTeX, titlesec (`newlinetospace`) y hyperref, sin errores ni avisos. La apertura corta en dos y en tres líneas; el sumario y los marcadores (leídos con qpdf) salen en una línea. Con una nota en el título (SC-29) y una volada (SC-62), también.

HTML, EPUB E INDEXADORES

`jats-to-html` y `jats-to-epub` no tienen plantilla para `break`, y la regla incorporada no escribe nada para una instrucción de procesamiento: sale «Corte de subtítulo». `jats-to-scielo` y `jats-to-redalyc` quitan `sec/title/break` con una plantilla vacía. No usan `normalize-space`, como en el `article-title` de SC-28, porque un título de sección puede llevar bastardilla.

ODT

Un espacio.

CADENAS

`corte-titulo.lua`, justo después de `volada.lua` en las tres: libro, tercero, antes de `cite-to-biblioref-db.lua`; revista, antes de `cite-to-xref.lua`; ODT.

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de libro, revista y ODT, incluidos los casos que frenan; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, las dos hojas LaTeX, HTML, EPUB, SciELO y Redalyc; el capítulo valida contra el RNG de DocBook 5.2 y el artículo contra la DTD Archiving 1.4; gbpublisher compila con gbc3 3.19.

PROBADO EN MINT

Alberto, 21/10, con un libro y una revista reales: el PDF corta en la apertura del título de sección; el HTML y el EPUB, sin corte.

**Relaciones:** vinculo:SC-28,vinculo:SC-29,vinculo:SC-39,vinculo:SC-54,vinculo:SC-62,vinculo:GV-121

**PENDIENTE:** Falta en Mint: un caso que frene (corte al final, dos seguidos o dentro de una bastardilla) y el control corte_fuera_de_titulo. El ODT, cuando se encare (decisión de Alberto, 21/10).

### SC-64 — Cifras y unidades: la norma internacional, escrita con siunitx

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel-spanish 5.0q / siunitx 3.3.10 / contenedor Ubuntu 24.04; SI Brochure 9.ª ed. (BIPM); Resolución 10 de la 22.ª CGPM · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 22/10). Las cifras y las unidades siguen la norma internacional. En dos puntos se aparta de la práctica que Alberto usaba en LaTeX: el porcentaje va separado de la cifra, y las cifras de cuatro dígitos no se agrupan.

LA NORMA

    tema                     norma                                   fuente
    separador decimal        punto o coma, el habitual del contexto  CGPM 2003, Res. 10; SI Brochure §5.4.4
                             (el proyecto: punto)
    grupos de miles          de a tres, con un espacio; nunca con    SI Brochure §5.4.4; RAE (espacio fino)
                             punto ni coma
    cuatro dígitos           no se aísla un solo dígito: 1000        SI Brochure §5.4.4; DPD «2458 (no 2 458)»
    porcentaje               separado de la cifra: 25 %              SI Brochure §5.4.7
    unidad                   siempre separada de la cifra            SI Brochure §5.4.3
    grado de ángulo          pegado: 30° 22′ 8″                      SI Brochure §5.4.3
    grado Celsius            separado: 30.2 °C                       SI Brochure §5.4.3

EL MODELO DE ESCRITURA (decisión de Alberto)

La cifra se normaliza en el .md; el formato lo pone cada salida. Una cifra que es una cantidad se escribe con la entrada de siunitx: dígitos sin separador de miles, punto decimal, `e` para el exponente. En el texto: `\num{1000}`, `\SI{2.5}{\hour}`, `\SIrange{50}{51}{\degree}`; en una columna numérica de un cuadro, la cifra sola: `9000.00`. El Word no se respeta: el editor lo pasa a esta forma. El punto queda solo en los números que lo llevan por identidad, como texto común: «decreto 2.345/26», «ley 34.555».

LA CONFIGURACIÓN DE siunitx

    \sisetup{output-decimal-marker={.},
      group-separator={\hspace{0.15em}},
      group-minimum-digits=5,
      table-text-alignment=center,
      detect-all,
      per-mode=symbol}
    \DeclareSIUnit\euro{€}

- `detect-all` sostiene el punto decimal frente a babel-spanish: sin ella, los decimales salen con coma (GV-123).
- `group-minimum-digits=5`: «1000», «12 345» (la práctica anterior era 3).
- `per-mode=symbol`: «48 km/h» en una línea; la fracción vertical agrandaba la línea (decisión de Alberto).
- `\euro`: no hacía falta todavía, pero cuesta una línea (decisión de Alberto). La fuente tiene que tener el signo €.
- El porcentaje: se separa, así que no se usa `\spanishplainpercent` (GV-122). `\SI{25}{\percent}` es la forma de escribirlo.

EL DICCIONARIO CERRADO DEL TEXTO

Órdenes: `\num`, `\SI`, `\SIrange`, con los nombres que Alberto usa (siguen funcionando en siunitx 3). Unidades: `\hour`, `\metre`, `\gram`, `\tonne`, `\degree`, `\percent`, `\euro`, con el prefijo `\kilo` y los modificadores `\square`, `\cubic` y `\per`. Lo que no está en el diccionario frena la conversión con un mensaje.

EL HTML Y EL EPUB

El PDF compone con siunitx, que es la base del diseño (SC-31). El HTML y el EPUB usan un formateador chico que aplica las mismas reglas: punto decimal, grupos de a tres desde cinco dígitos, «× 10ⁿ» con superíndice, los símbolos del diccionario y la palabra del rango según el idioma. El espacio de los grupos y el de la unidad es U+202F (espacio fino que no corta la línea): una cifra no se parte entre dos renglones (decisión de Alberto). Un mini-test compara las dos salidas sobre la misma lista de casos.

LAS TABLAS: EL PLAN (decisión de Alberto)

Tres lotes, cada uno probado en Mint antes del siguiente:

1. Las cifras: el filtro de `\num`, `\SI` y `\SIrange`, el `\sisetup` en el contrato del libro y en el preámbulo de la revista, el formateador del HTML.
2. La cadena del cuadro: el archivo del cuadro en su carpeta, con las decisiones de composición en el encabezado, incluido desde el .md; el canónico (la rotación como atributo, la columna numérica alineada por carácter, los cortes como instrucción `gb-`); el PDF, con un flotante `[!ht]` por tramo, la cabecera repetida y los textos de continuación, y `sidewaystable` si rota; el HTML y el EPUB, con la tabla completa y derecha. El corte y la rotación los decide siempre el maquetador: nunca el compilador.
3. `FTabla` para el editor y no para el autor: la lista de los cuadros de la carpeta, la edición de las decisiones y una vista previa compilada con el mismo filtro, las mismas plantillas y el mismo preámbulo que el libro (sin la capa de hyperref), con `showframe` y el veredicto leído del log. La vista previa se abre con el visor de PDF del sistema: abrir, mirar y cerrar (decisión de Alberto).

**Relaciones:** vinculo:SC-31,vinculo:SC-38,vinculo:SC-62,vinculo:GV-122,vinculo:GV-123,vinculo:SC-65,vinculo:SC-66,vinculo:SC-67

**PENDIENTE:** Lote 1 (cifras) probado en Mint (SC-65). Lote 2 (cadena del cuadro) probado en Mint (SC-66). Lote 3 (formulario y vista previa) implementado en SC-67: falta probarlo en Mint.

### SC-65 — Cifras y cantidades: implementación (lote 1 de SC-64)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / Saxon-HE / xmllint / LuaHBTeX 1.17.0, TeX Live 2023, babel-spanish 5.0q, siunitx 3.3.10 / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

IMPLEMENTACIÓN del lote 1 de SC-64: las cifras y las cantidades en el texto, con `\num`, `\SI` y `\SIrange`, en el libro, la revista y el ODT. Las decisiones de diseño (a)–(g) son de Alberto (22/10).

LA CADENA

El filtro `cifras.lua` corre en las tres cadenas antes de todo filtro que serialice con `pandoc.write`: sin él, el escritor descarta la orden y la cifra se pierde (GV-116).

    libro     4.° de la lista de generar_canonicos_capitulos.sh: después de
              corte-titulo, antes de cite-to-biblioref-db
    revista   m_XML.GenerarBodyXML: después de corte-titulo, antes de recuadros
              y de cite-to-xref
    ODT       m_GenerarODT.GenerarODTunaColumna: después de corte-titulo

EL CANÓNICO (decisión a)

El elemento lleva el texto ya formateado, y la entrada tal como se escribió va en un atributo, la ficha:

    JATS     <named-content content-type="cantidad" specific-use="SI 2.5 kilo metre per hour">2.5 km/h</named-content>
    DocBook  <phrase role="cantidad" remap="SI 2.5 kilo metre per hour">2.5 km/h</phrase>
    ODT      el texto formateado, sin marca

La ficha es la orden y sus argumentos separados por espacios, con las unidades sin barra: `num 1500`, `SI 88 percent`, `SIrange 50 51 degree`. Sin LaTeX en el canónico (SC-38). Validado: `named-content` en `p`, `title`, `td` y `caption` contra la DTD de JATS 1.4; `phrase` con `remap` contra el RNG de DocBook 5.2.

EL PDF

`f:cifra-latex` (`tex-comun.xsl`) rearma la orden desde la ficha, y frena si la ficha no es una de las conocidas. Las plantillas están en cada hoja, no en `tex-comun` (GV-117): `phrase[@role=''cantidad'']` en `docbook-to-latex.xsl` y `named-content[@content-type=''cantidad'']` en `jats-to-latex.xsl`. En el argumento opcional de un título va dentro de `\texorpdfstring`, con el texto formateado para el marcador (GV-118).

El `\sisetup` de SC-64 y `\DeclareSIUnit\euro{€}` están en el contrato del libro (`preambulo-contrato.tex`, versión 15; `CONTRATO_VERSION = 15` en `m_GenerarPDFLibro`) y en el preámbulo de la revista (`m_XML`), con los mismos valores.

EL HTML, EL EPUB Y EL ODT

El texto lo arma el formateador de `cifras.lua` con las reglas de SC-64: punto decimal, grupos de a tres desde cinco dígitos de un lado del punto, signo menos U+2212, exponente «× 10ⁿ» con superíndice, U+202F entre los grupos y entre la cifra y la unidad, el grado pegado, `/` para `\per`. Las hojas de HTML y EPUB no necesitan plantilla: muestran el texto del elemento.

MEDIDO: los veinticinco casos de la lista de Alberto, compuestos con siunitx 3.3.10 y el `\sisetup` de SC-64, coinciden con el formateador (comparados con `pdftotext`; la única diferencia es el superíndice, que `pdftotext` da como cifra común). De punta a punta, un capítulo con cifras en un párrafo, un título, una nota, una celda y un pie de cuadro, en español y en inglés: canónico válido (RNG y DTD), PDF compilado con el bloque de siunitx del contrato (marcadores «Cifras en 12 000 casos», «Rango de 50° to 51°»), HTML, EPUB, SciELO, Redalyc y ODT con el mismo texto.

EL IDIOMA DEL RANGO (decisión b)

La palabra del rango sale del idioma de la pieza: en la revista, `-M gb-idioma` (`ArgumentoIdiomaPandoc`); en el libro, `-M gb-idioma-pieza`, que el script pasa con el idioma del capítulo solo a la conversión (no `gb-idioma`, que `conversacion.lua` usa con otro fin). Se toman las dos primeras letras. La tabla es la de siunitx 3.3.10 (clave `to (numerical range)`): ca a, de bis, en to, es a, fr à, it a, pl do, pt a, sl do. Otro idioma frena, solo si la pieza tiene un `\SIrange`.

EL DICCIONARIO

Cerrado, el de SC-64. Una cifra con otra forma (coma, punto de miles, letras), una unidad fuera de la lista, un prefijo o una potencia que no van con su unidad, más de un `\per`, el grado o el porcentaje acompañados, o una orden incompleta, frenan la conversión con un mensaje que nombra la orden y dice qué falla. La orden incompleta se busca también en los `Str` (GV-124).

LOS CONTROLES (decisiones c, e, g)

En `controles_md.lua` (SC-54): `latex_en_linea` admite las tres órdenes; `porcentaje_suelto` y `cifra_fuera_de_num` son `aviso`: informan y la salida se genera (decisión de Alberto).

EL PANEL Y EL RESALTADO (decisiones d, f)

Tres filas en línea, modo plantilla, en gbShortcodes (`datos-v5-016`): `\num{•}`, `\SI{•}{}` y `\SIrange{•}{}{}`. En `Markdown.highlight`, el patrón de `\sptext` pasa a ser el de las órdenes admitidas (`$(orden)`), con el estado `latex.orden`; los estados hijos de la bastardilla, la negrita y el tachado lo usan igual (GV-119). Medido con el banco de gb.highlight: las tres órdenes se resaltan sueltas y dentro de la bastardilla y la negrita; los seis archivos de prueba anteriores dan el mismo resultado que antes.

LO QUE NO CUBRE

- El libro no cambia el idioma de babel por capítulo: un capítulo en inglés compone su `\SIrange` con la palabra del idioma principal en el PDF y con «to» en el HTML. Es anterior a este lote: `docbook-to-latex.xsl` no usa el `xml:lang` del capítulo.
- En la revista, los controles todavía no corren (SC-54, pendiente 1): una cifra suelta no avisa. `cifras.lua` frena igual.
- La columna numérica de un cuadro (`S`) es del lote 2.

PROBADO EN MINT (Alberto, 22/10)

Un libro real (preliminares de «El Atlántico de los exilios»): cifras en un título, un párrafo, una nota y una celda, en el PDF, el HTML y el EPUB; el marcador del PDF; la inserción desde el panel; el resaltado; el aviso de un «88%» suelto, con el capítulo generado igual; y un caso que frena, `\SI{88}{\per}`. Las filas `num`, `si` y `si-rango` se liberan con `datos-v5-017`.

EL MOTIVO QUE NO SE VEÍA

En esa prueba la terminal mostró el final del mensaje de `cifras.lua` y no su primera línea, la que dice qué falla: Pandoc agrega al mensaje de un filtro que frena una o dos «stack traceback:» (medido con pandoc 3.1.3: veinte líneas, el motivo en la tercera), y `mostrar_cola` de `engine/comun.sh` mostraba las últimas quince. Ahora `mostrar_cola` corta la salida desde la primera «stack traceback:»: vale para todos los filtros y todos los scripts de `engine/`.

**Relaciones:** vinculo:SC-64,vinculo:SC-38,vinculo:SC-54,vinculo:SC-62,vinculo:SC-63,apoya:GV-116,apoya:GV-117,apoya:GV-118,vinculo:GV-119,apoya:GV-123,apoya:GV-124,vinculo:GV-125

**PENDIENTE:** El cambio de idioma por capítulo en el PDF del libro, que no existe (ver LO QUE NO CUBRE), cuando se encare; con él, probar un capítulo en inglés con \SIrange. El ODT y la revista en Mint, con la fase de salidas que les corresponde.

### SC-66 — Cuadros: el archivo del cuadro, el estilo de la casa y la cadena (lote 2 de SC-64)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / Saxon-HE / xmllint / LuaHBTeX 1.17.0, TeX Live 2023, siunitx 3.3.10 / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisiones de Alberto, 22/10), y lo implementado en la entrega 1. Es el lote 2 de SC-64: la cadena del cuadro. El diseño de los cuadros del libro manda también en las revistas. Todo lo anterior sobre tablas se revisa contra este.

EL ARCHIVO DEL CUADRO

Cada cuadro vive en un archivo propio, `cuadros/tbl-nombre.md`, en la raíz del proyecto, como `media/`, en libros y revistas. El .md solo lo nombra:

    ::: {.cuadro #tbl-procedencia}
    [/cuadro]: # ()
    :::

El id lleva el prefijo `tbl-`, el de las referencias cruzadas (`[@tbl-procedencia]` en libros), y es el nombre del archivo. El archivo tiene un encabezado YAML con las decisiones y, debajo, la tabla y nada más:

    ---
    titulo: Procedencia de los tesistas por décadas
    nota: "Nota: este cuadro y los que siguen son de elaboración propia."
    cuerpo: normal        # normal = \footnotesize · chico = \scriptsize
    separacion: normal    # normal = 4 pt · estrecha = 2 pt
    rotar: no
    agrupar: no           # sí: la primera celda vacía continúa el grupo
    cortes: []            # filas del cuerpo tras las que corta
    columnas:
      - {tipo: texto}
      - {tipo: cifra}
      - {tipo: texto, ancho: 2.4, alinear: centro}
    ---

    | | 1890-1899 | Observaciones |
    |---|---|---|
    | Capital Federal | 42 | … |

- `titulo` es obligatorio y puede ir vacío. `titulo` y `nota` van separados (decisión de Alberto): en JATS, `caption/title` y `table-wrap-foot`; en DocBook, `title` y `caption`. En el PDF se componen juntos en el `\caption`, como hasta ahora. A la lista de cuadros va solo el título. Los dos admiten Markdown en línea, cifras y citas: pasan por la cadena como el resto del texto (medido: una cita de la nota sale `<biblioref>`).
- `columnas`, una entrada por columna. `cifra` da una columna `S` con su `table-format` calculado de los datos. `texto` con `ancho` (en centímetros, con punto decimal) da `m{ancho}` con `\raggedright` o, con `alinear: centro`, `\centering`. Sin ancho da `l` o `c`. Anchos en centímetros, la práctica de Alberto: el control lo da la vista previa con `showframe` (lote 3).
- La tabla es pipe table, o grid table cuando hay celdas unidas (GV-126). El encabezado sale en negrita sin marcarlo. Una fila de total es una fila común.
- En una columna de cifras, una celda que es solo una cifra se escribe con la entrada de siunitx (SC-64); lo que no es una cifra («—», «s/d») sale entre llaves, como texto.

EL ESTILO DE LA CASA (decisión de Alberto: «es una marca del diseño de la editorial»)

Letra sin serifa; `[!ht]`; centrado; `\toprule`, `\midrule` entre todas las filas, `\bottomrule`; filete vertical entre todas las columnas; encabezado en negrita; pie debajo; la letra y el cuerpo alcanzan también al pie. Lo que una editorial puede cambiar va en macros del contrato (versión 16) y del preámbulo de la revista, gemelas: `\gbCuadroLetra`, `\gbCuadroCuerpoNormal`, `\gbCuadroCuerpoChico`, `\gbCuadroSepNormal`, `\gbCuadroSepEstrecha`. booktabs deja aire en los cruces de los filetes verticales: se acepta.

LIBROS Y REVISTAS

El mismo diseño y el mismo criterio: el maquetador decide dónde corta y si rota, nunca el compilador. La única diferencia es el ancho: en libros hay uno, el de la caja; en revistas, dos: el de la columna y el total (columna, calle y columna derecha). En revistas el maquetador decide además si usa el ancho total (decisión de Alberto, 22/10).

LA CADENA

- `cuadro-leer.lua`, PRIMERO en las tres cadenas: trae el archivo (con `-M gb-proyecto`), controla el encabezado y la tabla, y deja un Div `.cuadro` con las decisiones en sus atributos, el título, la nota y la tabla. Así el contenido pasa por todos los filtros: comillas, volada, cifras, citas. Una cifra sola en una columna de cifras pasa a `\num{…}`, que traduce `cifras.lua` (SC-65). Frena el viejo `::: {.table}`.
- `cuadro-armar.lua` escribe el cuadro: en libros, antes de `fenced-divs-to-elements-db.lua`; en revistas, después de `cite-to-xref.lua`; en el ODT, antes de `--citeproc`. Lo escribe el filtro y no Pandoc porque el escritor DocBook pierde las celdas unidas (GV-126) y ninguno lleva la nota ni las decisiones.
- `table-to-end.lua` sale de la cadena de la revista: solo marcaba el viejo `.table`.

EL CANÓNICO

    DocBook  <table xml:id="tbl-…"><title>…</title>
             <?gb-cuadro cuerpo="normal" separacion="normal" columnas="texto cifra texto:2.4:centro"?>
             <tgroup> <colspec align="left|center|char" char="."/> … </tgroup>
             <caption><para>NOTA</para></caption></table>
    JATS     <table-wrap id="tbl-…"><caption><title>…</title></caption> <?gb-cuadro …?>
             <table> <col align="…"/> … <th|td align="…" char="."> … </table>
             <table-wrap-foot><p>NOTA</p></table-wrap-foot></table-wrap>

Las decisiones de composición van en la instrucción `gb-cuadro`, sin LaTeX (SC-38); SciELO y Redalyc la quitan como a toda `gb-`. La columna de cifras va alineada por el punto (`align="char"`). Validado: DocBook contra el RNG 5.2; JATS contra la DTD 1.4.

LAS SALIDAS

- PDF: plantillas en `docbook-to-latex.xsl` y `jats-to-latex.xsl` (GV-117); funciones en `tex-comun.xsl`: `f:pi-valor`, `f:cuadro-columna`, `f:cuadro-formato` (el `table-format`: signo si hay una cifra negativa, los enteros y decimales más largos) y `f:cuadro-pie`. Una cifra sola va como la lee la columna `S`; el encabezado de una columna de cifras va entre llaves.
- HTML y EPUB: la tabla completa y derecha; debajo, en un solo párrafo como en el PDF, «Cuadro N», el título y, a continuación, la nota, con punto seguido si el título no termina en . ? ! (decisión de Alberto, 22/10: el PDF es el modelo). El número es el del PDF (`nl:numero-cuadro`, misma regla que la figura). Los navegadores no aplican `align="char"`: la columna de cifras va a la derecha, con cifras tabulares.
- Referencias cruzadas en libros: `cite-to-biblioref-db.lua` admite `tbl-`, y `ensamblar-capitulo-canonico.xsl` no le pone el prefijo del capítulo a un id `tbl-` (`db:es-id-global`, como `fig-`): así una referencia a un cuadro de otro capítulo funciona (medido: en la prueba de Alberto salía «??»). El id es único en el proyecto porque es el nombre del archivo; el HTML y el EPUB muestran el número del cuadro. En revistas no hay referencias cruzadas (SC-32).
- ODT: el título en negrita, la tabla y la nota.

QUÉ FRENA

TODA TABLA VA EN SU ARCHIVO (decisión de Alberto, 22/10: «rigidez estructural para evitar caos»). Una tabla escrita en el .md de un capítulo o de un artículo, suelta o dentro de otro bloque, frena en las tres cadenas: `cuadro-leer.lua` la busca antes de traer los cuadros y nombra su encabezado para encontrarla.

EL HTML TOMA EL MODELO DEL EPUB (decisión de Alberto, 22/10, que reemplaza la de conservar el estilo web: con celdas unidas, las filas alternas no se entendían): un filete entre todas las celdas y el encabezado con fondo; el fondo es el gris azulado de la casa (`--color-tabla-header`), no el gris del EPUB; sin filas alternas. En libros (`gbpublisher.css`) y en revistas (`jats-to-html.xsl`). El modelo es el PDF, que Alberto viene desarrollando en sus libros.

Un id sin `tbl-`; el bloque con contenido o con otros atributos; el archivo que no existe; una clave desconocida; `titulo` ausente; un valor fuera de la lista; `columnas` que no coincide con la tabla; un ancho con coma; ancho o alineación en una columna de cifras; algo más que una tabla debajo del encabezado; el pie de Pandoc (`: pie`); una nota al pie (decisión de Alberto: un flotante no la lleva); HTML; una orden de LaTeX que no es de las admitidas; una cifra con coma o con punto de miles en una columna de cifras.

ENTREGA 1 (IMPLEMENTADA)

El cuadro simple, en libros y revistas: el archivo, el canónico, las columnas de texto y de cifras, el PDF con el estilo de la casa, el HTML, el EPUB y el ODT. Probada en Mint por Alberto (22/10): el PDF, «perfecto».

MEDIDO: un cuadro con cifras enteras, negativas y decimales, «—» en una columna de cifras, volada, comillas, `\SI` y una cita en la nota; un `\num` en el título. Libro: canónico válido (RNG), PDF compilado (`l | S[table-format=3.0] | S[table-format=5.0] | S[table-format=-2.2] | >{\centering\arraybackslash}m{3cm}`), «Cuadro 1.1» en el pie y en la referencia del HTML y del EPUB. Revista: JATS válido (DTD), PDF, HTML, EPUB, SciELO y Redalyc. ODT. Un cuadro dentro de un bloque `::: intro`. Los casos que frenan, uno por uno.

ENTREGA 2 (IMPLEMENTADA)

Dos claves más en el encabezado: `bloques: [11, 22]`, las filas del cuerpo tras las que va el filete doble (decisión de Alberto: «una división lógica dentro del cuadro», un caso raro); y, solo en revistas, `ancho: columna | total` (en el libro, `total` frena: hay un solo ancho).

- CELDAS UNIDAS. Con grid table. `cuadro-leer.lua` ubica cada celda en su columna (atributo `gb-col`, porque con celdas unidas la posición en la fila no la dice); `cuadro-armar.lua` escribe `namest`/`nameend`/`morerows` en CALS (y `colname` en la celda simple, para que las salidas digitales sepan su columna) y `colspan`/`rowspan` en JATS. En el PDF: la celda que une columnas es `\multicolumn{n}{c|}{…}` (sin filete si llega a la última); la que une filas lleva el texto en la primera fila en el cuerpo y en la última en el encabezado, y las filas que ocupa quedan vacías, como en los cuadros de la casa. El filete entre dos filas es `\midrule` si ninguna celda sigue unida; si no, un `\cmidrule` por cada tramo de columnas libres (el `\cmidrule{2-n}` de la casa). En el HTML y el EPUB, `colspan` y `rowspan`; la celda que une columnas, centrada.
- ENCABEZADO DE VARIAS FILAS. Con grid table (`===` debajo del encabezado). Se repite en cada tramo.
- `agrupar: sí`. La celda vacía de la primera columna continúa el grupo: la primera celda del grupo pasa a unir esas filas. La primera columna no puede traer ya celdas unidas.
- `cortes`. Un flotante por tramo, todos `[!ht]` (o `sidewaystable`): el encabezado repetido; al final de cada tramo menos el último, «Continúa en la página siguiente» a la derecha; al principio de cada tramo menos el primero, «Viene de la página anterior» a la izquierda, los dos en bastardilla; el pie y la etiqueta solo en el último, así el número es uno. Los textos son macros del contrato 17 y del preámbulo de la revista: `\gbCuadroContinua`, `\gbCuadroViene`. El HTML y el EPUB muestran la tabla completa.
- `bloques`. `\midrule` doble entre esas filas. El HTML conserva su estilo y no lo marca.
- `rotar: sí`. `sidewaystable`, uno por tramo (contrato 17: el paquete `rotating`). En el canónico, `orient="land"` / `orientation="landscape"`.
- `ancho: total` (revistas). El entorno `gbcuadrototal` del preámbulo de la revista, el mismo `adjustwidth` que la figura de ancho completo. Con `rotar` frena: el cuadro apaisado ya ocupa la página.
- La composición del cuadro es una plantilla con nombre en `tex-comun.xsl`, `gb-cuadro-latex`, común a libros y revistas; la plantilla de cada hoja solo junta las filas, el pie y la rotación (GV-117). Funciones: `f:cuadro-span`, `f:cuadro-grilla`, `f:cuadro-abajo`, `f:cuadro-filete`, `f:cuadro-cantidad`.

FRENAN, ADEMÁS: un corte o un bloque que no es un número de fila, que deja la última sin filas después, repetido o fuera de orden, o que parte una celda unida o un grupo; la misma fila en cortes y en bloques; una fila con más celdas que columnas o con un hueco.

MEDIDO: el cuadro de los tesistas (cuadro4-3 de la casa) con `agrupar` y un corte entre grupos; uno de dos niveles de encabezado con subtotales unidos, `bloques` y `rotar` (como el cuadroX2); el mismo con `ancho: total` en una revista. Libro: canónico válido (RNG), PDF compilado: los dos tramos con sus textos, el pie solo en el último, `\cmidrule{2-4}` entre las filas de un grupo, `\cmidrule{2-5}` bajo la fila de grupos del encabezado, «Período» en la fila de abajo, el filete doble. Revista: JATS válido (DTD), PDF compilado con `gbcuadrototal`, HTML, EPUB, SciELO y Redalyc. ODT con celdas unidas. Los casos que frenan, uno por uno.

**Relaciones:** vinculo:SC-64,vinculo:SC-65,vinculo:SC-38,vinculo:SC-32,vinculo:SC-31,vinculo:SC-54,apoya:GV-126,apoya:GV-117,apoya:GV-116,apoya:GV-124,vinculo:SC-67

**PENDIENTE:** Los controles de avisos (SC-54) sobre el archivo del cuadro.

### SC-67 — Cuadros: el formulario y la vista previa (lote 3 de SC-64)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbc3 3.19 / pandoc 3.1.3 / Saxon-HE 12.5 / LuaHBTeX 1.17.0, TeX Live 2023 / contenedor Ubuntu 24.04, xvfb · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto acepta las tres recomendaciones, 23/10) y lo implementado. Es el lote 3 de SC-64: el formulario de los cuadros y la vista previa con `showframe`. El archivo del cuadro y su cadena son de SC-66.

LAS TRES DECISIONES

a) LA GRILLA PARA LA PIPE TABLE, EL TEXTO PARA LA GRID TABLE. Una pipe table se edita celda por celda, con el texto de cada celda en Markdown tal cual. Una tabla con celdas unidas (grid table) se edita como texto, con el resaltado del proyecto. No hay conversión automática: «La tabla como texto» pasa de la grilla al texto, para unir celdas; «Pasar a la grilla» vuelve si el texto es una pipe table simple con las columnas del diseño, y si no, no cambia nada.

b) LA NOTA EN UNA LÍNEA. El formulario la edita en un campo de una línea. Un archivo con una nota de varias líneas —o cualquier encabezado que este lector no lea igual que YAML— se abre entero como texto, con el motivo; el diseño queda deshabilitado.

c) LA VISTA PREVIA ARMA EL PREÁMBULO EN EL MOMENTO. No hace falta haber corrido «Solo generar» antes: en libros copia los preámbulos (`CopiarRecursosLatex`) y escribe `preambulo-proyecto.tex` desde la base, como el PDF.

EL FORMATO QUE ESCRIBE GAMBAS

Pandoc no puede escribir el archivo (GV-127): lo lee y lo escribe `m_Cuadros`, con un formato fijo:

    ---
    titulo: 'Procedencia de los tesistas'
    nota: 'Fuente: elaboración propia.'
    cuerpo: normal
    separacion: normal
    rotar: sí              (solo si sí; agrupar, igual)
    cortes: [12]           (solo si hay; bloques, igual)
    ancho: total           (solo si es total)
    columnas:
      - {tipo: texto, ancho: 2.4, alinear: centro}
      - {tipo: cifra}
    ---

    | … | … |
    |---|---|

`titulo` y `nota` van entre comillas simples: adentro la barra es literal (`\num{…}` llega entero) y la comilla se duplica; entre comillas dobles, `\n` sería un salto de línea para YAML. La pipe table va sin alinear con espacios: una celda que crece no cambia las otras líneas del diff. La barra de una celda va escapada (`\|`). La alineación `izq` no se escribe: es la de omisión.

El lector acepta las claves en cualquier orden, los valores sin comillas o con comillas dobles sin barras, y las líneas en blanco. NO ENCAJA, y el archivo se abre como texto: un comentario, un « #» o un «: » en un valor sin comillas, una lista en bloque, una nota de varias líneas, una clave desconocida o repetida, un valor fuera de la lista, `columnas` con otra cantidad que la tabla. Al abrir, lo que difiere solo en la forma (comillas, orden) no cuenta como cambio: el archivo se reescribe en el formato de Gambas recién al guardar.

EL FORMULARIO (FTabla)

A la izquierda, los cuadros de `cuadros/`, con Nuevo (una plantilla de dos columnas) y Duplicar; el nombre lleva `tbl-` y letras sin tilde, cifras o guiones, como lo pide `cuadro-leer.lua`. Dos pestañas:

- Datos: la grilla. La fila «enc.» es el encabezado de la tabla; las demás, el cuerpo, numeradas. El menú de la fila (botón o clic derecho) inserta, quita y marca el corte (✂) o el filete doble (═) después de la fila; el de la columna inserta y quita. Al insertar o quitar una fila, los cortes y los bloques de las filas de abajo se corren y siguen marcando la misma fila de datos. En el modo texto, «Colorear» vuelve a colorear: a pedido y no al escribir (GV-46, SC-18).
- Diseño: título, nota, cuerpo, separación, ancho (columna o total), rotar, agrupar; cortes y bloques como números de fila separados por comas (los mismos que marca el menú); y la grilla de las columnas: tipo, ancho en centímetros (la coma del teclado pasa a punto) y alineación. Una columna de cifras no lleva ancho ni alineación.

Guardar, Vista previa, Insertar y Cerrar; se cierra solo por los botones (SC-20). Cambiar de cuadro, Insertar y Cerrar con cambios sin guardar preguntan: guardar, descartar o quedarse (SC-06). Insertar pone en el cursor el bloque que nombra el cuadro (`::: {.cuadro #tbl-…}`, con su cierre nombrado, SC-33), con la misma validación de la posición que antes; el id vuelve a FMain por `m_Cuadros` (RC-GM-13).

LA VISTA PREVIA

Compone el cuadro solo, con todo lo de la pieza: los mismos filtros en el mismo orden, la misma plantilla de composición y el mismo preámbulo, con la caja a la vista. Lo que se ve es lo que sale; no hay otra composición del cuadro.

- Gambas escribe lo que sale de la base, `tmp/vista-cuadro/preambulo-vista.tex`: en libros, las capas del `main.tex` con `\gbshowframetrue` y sin `preambulo-hyperref` (el contrato se engancha a hyperref con `\AddToHook{package/hyperref/after}` y no lo necesita; la capa registra el .bib, que el cuadro solo no usa): `m_GenerarPDFLibro.PreambuloVistaCuadro`. En revistas, el del PDF en borrador, sin el .bib y sin `\begin{document}`: `m_XML.PreambuloVistaCuadro`. La revista CONSERVA hyperref: va embebido a mitad del preámbulo y seguido de `\pdfstringdefDisableCommands`. El estilo de cita lo lee `m_XML.EstiloCitaRevista`, la misma función que ahora usa `m_GenerarPDF.GenerarPDFunaColumna`.
- `engine/vista_cuadro.sh` (SC-13, lanzado por `EjecutarScriptSalida`, SC-53) hace el resto: el .md mínimo que nombra el cuadro, pandoc con la cadena de la pieza (`FILTROS_LIBRO` y `FILTROS_REVISTA` en `comun.sh`; la de libros la usa también `generar_canonicos_capitulos.sh`, la de revistas es gemela de `m_XML.GenerarBodyXML`), Saxon con `vista-cuadro-libro.xsl` o `vista-cuadro-revista.xsl` (importan la hoja del PDF y solo cambian la raíz), una pasada de LuaLaTeX y el veredicto. El idioma es el de la pieza abierta en el editor.
- EL VEREDICTO (`veredicto.txt`, una línea por hallazgo, `nivel<TAB>mensaje`): por tramo, el ancho y el alto contra la caja, en milímetros (info); un tramo más ancho o más alto que la caja, una celda que se sale de su columna, «Float too large» (el alto con el pie) y un error de LaTeX en el cuadro: error. Un error de LaTeX del preámbulo: aviso, porque no es del cuadro y sale igual en el PDF de la pieza. Las medidas las toma `engine/vista_cuadro_medir.lua` (GV-128): en el libro, linebreaker calla los Overfull y el .log no las daría. Código 0, el cuadro entra; 3, hay observaciones; 1, no salió el PDF, con el motivo del filtro que frenó también en el veredicto.
- El formulario muestra el veredicto y abre `vista.pdf` con el visor del sistema (`Desktop.Open`, sin espera).

LO QUE LA VISTA NO DICE: la paginación real (los tramos caen donde caen junto al texto de la pieza) y el número del cuadro (sale «Cuadro 1»).

SE RETIRAN las filas `table-wrap`, `table-fullwidth` y `table-landscape` de gbShortcodes (`datos-v5-018`): las reemplazan el archivo del cuadro y este formulario.

MEDIDO en el contenedor (gbc3 3.19, LuaHBTeX 1.17.0, Saxon-HE 12.5, pandoc 3.1.3): la vista de libro con el preámbulo que escribe Gambas, y la de revista con el de `ObtenerPreambuloEmbebido` reproducido desde el código (la función necesita FMain y la base); un cuadro que entra, uno más ancho que la caja (13,7 mm), uno más alto (174,2 mm), uno que se pasa solo con el pie (3,0 mm), una celda que desborda (20,3 mm), uno rotado y uno con `ancho: total`, y uno que frena en la cadena (`ancho: total` en un libro). El lector y el escritor sobre los cuadros de prueba: la ida y vuelta da el mismo texto; y siete casos que no encajan, cada uno con su motivo. El formulario bajo xvfb: la lista, la grilla, una grid table en texto, la edición de una celda con una barra, un corte por el menú, una fila insertada con los cortes corridos (también con la edición a medio escribir), guardar, la ida y vuelta grilla–texto, un archivo que no encaja e Insertar.

DE PASO: la revista ya tenía dos errores de LaTeX en su preámbulo, ajenos a los cuadros, que la vista muestra como aviso: «Command \theHpoemline already defined» (verse después de hyperref) y «biblatex Error: \chapter not provided by class» (`citereset=chapter` en `cita-apa-config.tex` con la clase article). Medidos en el contenedor; falta ver si salen igual en Mint.

**Relaciones:** vinculo:SC-66,vinculo:SC-64,vinculo:SC-13,vinculo:SC-53,vinculo:SC-15,vinculo:SC-18,vinculo:SC-20,vinculo:SC-06,vinculo:SC-33,vinculo:RC-GM-13,apoya:GV-127,apoya:GV-128,apoya:GV-129,apoya:GV-46

**PENDIENTE:** Probar en Mint: el formulario (3.22) y la vista previa en un libro y en una revista. Ver si los dos errores del preámbulo de la revista salen también en Mint y, si salen, resolverlos aparte.

### SC-68 — Espacio fijo en el .md: ¬ como el ~ de LaTeX, y las abreviaturas por el lector

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / pandoc 3.1.3 / SaxonJ-HE 12.5 / gbc3 3.19 / contenedor Ubuntu 24.04; TextEdit en Mint con Gambas 3.22 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 24/10). Escribir un espacio que no se corta tiene que ser tan simple como en LaTeX. Dos capas:

1. LA MARCA. `¬` (U+00AC) entre dos palabras, como el `~` de LaTeX:

    siglo¬XX    Felipe¬II    art.¬3,¬inc.¬b    20¬de¬mayo

En el teclado latinoamericano es AltGr + la tecla a la izquierda del 1 (GV-131).

2. LAS ABREVIATURAS, SIN MARCA. El lector de Pandoc pone el espacio duro detrás de cada abreviatura de `filters/abreviaturas-espacio-fijo.txt` (GV-133): «pág. 22», «cap. 3», «n.º 5», «Lic. Pérez», «EE. UU.» se escriben con un espacio común. Es lo que hace biblatex con `\cite[22]{clave}`.

POR QUÉ ¬ Y NO ~

`~` es el subíndice de Pandoc (SC-30), y arma uno sin aviso con dos `~` sin espacio entre ellos (GV-130). `\ ` no se ve en el editor; `|` corta una celda; `_`, `=` y `+` dependen del contexto o aparecen en la prosa (GV-131). `¬` no es sintaxis de Pandoc en ninguna posición, no aparece en la prosa y el editor lo conserva (GV-132). El carácter U+00A0 sigue sin escribirse en el .md (GV-47).

EXCEPCIÓN A SC-40: es la única marca del .md que no es ASCII. La convención ASCII de LaTeX, `~`, no está disponible.

LA CADENA

- `filters/espacio-fijo.lua` cambia `¬` por U+00A0 en los Str: también en el prefijo y el sufijo de una cita, las notas, las celdas, los pies, el texto de un enlace y los metadatos. En el código, la matemática y las URL queda literal.
- Va SEGUNDO: después de `cuadro-leer`, que inserta el texto del cuadro, y antes de todo filtro que serializa. Está en FILTROS_LIBRO y FILTROS_REVISTA (`engine/comun.sh`), en `m_XML.GenerarBodyXML` y en `m_GenerarODT`; solo, sin los demás filtros, en `m_GenerarEpub.ConvertirMdAXhtml` (el front y el back matter de la revista) y en `m_PrimerasLibro.ConvertirMarkdown`.
- `--abbreviations` en esos mismos lectores y en `vista_cuadro.sh`. La ruta está en `comun.sh` (`RUTA_ABREVIATURAS`) y en `m_Constantes` (`SUBRUTA_ABREVIATURAS`, con `SUBRUTA_FILTRO_ESPACIO_FIJO`). `generar_canonicos_capitulos.sh` y `vista_cuadro.sh` frenan si falta la lista.
- `cuadro-leer.lua` lee el archivo del cuadro con `pandoc.read`, pasándole solo la lista (GV-133).
- La lista viaja en `filters/`: se copia a `~/.gbpublisher/filters/` y se coteja con la instalada, como los filtros.

LAS SALIDAS

- Canónico JATS o DocBook, HTML, EPUB y ODT: el carácter U+00A0.
- PDF: `f:mapa-tex` (`tex-comun.xsl`) pasa U+00A0 a `~`, así el resultado no depende de cómo traten el carácter la fuente o LuaLaTeX. En una cita llega a la postnota: `\autocite[p.~22]{…}`.
- Primeras: Pandoc escribe `~` en LaTeX y el carácter en HTML.

EL LOCATOR IMPLÍCITO

`[@clave, 22]` da «p. 22» (`cite-to-biblioref-db.lua` y `cite-to-xref.lua`). El prefijo iba separado por un Space y la línea podía partirse entre «p.» y el número; ahora va en el mismo Str, con U+00A0. Un sufijo con letras («pág. 40») no pasa por ahí: lo une la lista.

CONTROLES Y ANÁLISIS

- `controles_md.lua`: control nuevo `espacio_fijo_suelto` (aviso), un `¬` que toca un espacio común o el borde de la línea («siglo ¬XX», «siglo¬ XX»). Pegado a otro inline está bien (`siglo¬*XX*`). `porcentaje_suelto` cubre también «20¬%».
- `analizar_proyecto.lua` parte cada Str en `¬` y en U+00A0: «siglo¬XX» son dos palabras y un espacio impreso, y perl recibe un espacio común. Por eso el análisis y los controles no llevan `--abbreviations`: cuentan igual con la lista o sin ella.

ALCANCE

El .md y las primeras, que pasan por Pandoc. El `.bib` sigue con el `~` de biblatex. Un campo de la base que no pasa por Markdown imprime `¬` tal cual. No hay escape para un `¬` literal en el texto: va en código, o en matemática como `\neg`. La lista es de la casa y se edita como dato: una abreviatura por línea, con sus formas con mayúscula.

MEDIDO en el contenedor (pandoc 3.1.3, SaxonJ-HE 12.5, gbc3 3.19 con gb.db en lugar de gb.db2, que 3.19 no trae): las cadenas de libro y de revista sobre un capítulo con `¬`, abreviaturas, el locator implícito, una nota y un cuadro: el canónico lleva U+00A0 donde corresponde y `H~2~O` sigue siendo subíndice. `f:latex` da `siglo~XX`, `pág.~22` y `p.~22`. Los escritores HTML y ODT dejan el carácter. Las primeras en LaTeX dan `siglo~XX` y `vol.~2`. El control y el análisis, sobre un .md de prueba. El proyecto compila.

**Relaciones:** vinculo:SC-40,vinculo:SC-30,vinculo:SC-31,vinculo:SC-54,vinculo:SC-46,vinculo:SC-66,vinculo:GV-47,vinculo:GV-88,apoya:GV-130,apoya:GV-131,apoya:GV-132,apoya:GV-133

**PENDIENTE:** Probar en Mint con un libro y una revista reales: el PDF (una cita con «p.~22» en la postnota), el HTML, el EPUB, el ODT y las primeras; el aviso espacio_fijo_suelto al generar los canónicos.

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

CÓMO FUNCIONA LA APLICACIÓN

El alcance, el importador, los scripts y la exportación son los de todas las aplicaciones satélite: SC-50.

**Relaciones:** vinculo:RF-07, vinculo:GV-29,vinculo:SC-50

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

**PENDIENTE:** RC-BL-02 afirma que apa ignora related; el fuente lo contradice en general. Relevar tipo por tipo qué relaciones imprime apa y reformular RC-BL-02. La versión anclada es la del repositorio (9.20); la que compone en Mint y en el contenedor es la de TeX Live 2023, biblatex-apa v9.17 (2023/03/20). Una afirmación tomada del fuente de 9.20 se verifica contra 9.17 antes de aplicarla.

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

### RF-11 — Estructura de la base de gbShortcodes y contrato de exportación

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbShortcodes / SQLite 3.45 / Pandoc 3.1.3 / Gambas 3.19 (gb.db) en contenedor · **Verificado:** 2026-10

Programa aparte, con el modelo de gbCorpus (RF-08), que mantiene el catálogo de shortcodes de gbpublisher. Reemplaza a la tabla `shortcodes` de MySQL, retirada en la actualización 1.7.0 de la base de gbpublisher (SC-22, SC-34).

ESTA ENTRADA DESCRIBE LA VERSIÓN 5 DEL ESQUEMA Y DEL CONTRATO DE EXPORTACIÓN. La 2 agrega `clase`; la 3, el modo `dos-partes` y la regla de liberación; la 4, la tabla `modos`; la 5, el grupo `composicion`. El contrato de exportación no cambia desde la 2.

Cómo funciona la aplicación —alcance, importador, migraciones, nombres de los scripts, recursos y exportación— está en SC-50, común a todas las aplicaciones satélite.

BASE

`~/.gbshortcodes/shortcodes.sqlite`, con `esquema_version`. La aplicación la crea en el primer arranque con el DDL de `m_Base.SentenciasDDL`, igual al de `shortcodes_esquema.sql` (verificado comparando `.schema`).

TABLA `shortcodes`

    nombre          TEXT NOT NULL UNIQUE   minúsculas, dígitos y guion: nombre de archivo
    clase           TEXT NOT NULL          la clase de Pandoc del .md: {.fig}, ::: epigraph, ]{.gloss}
    etiqueta        TEXT NOT NULL          lo que se ve en la lista de gbpublisher
    tipo            bloque | linea
    grupo           comun | estructura | disciplinar | composicion
    perfil          TEXT                   solo y siempre en disciplinar (CHECK)
    orden           INTEGER NOT NULL       dentro de grupo y perfil, de 10 en 10
    estado_libro    no_aplica | borrador | liberado
    estado_revista  no_aplica | borrador | liberado
    modo            el par (modo, tipo) es clave foránea a `modos`
    apertura        TEXT NOT NULL          puede tener saltos (el bloque de código)
    cierre          TEXT NOT NULL
    que_es          TEXT                   Markdown; NULL si no hay texto
    ejemplo         TEXT                   el ejemplo tal como se escribe en el .md
    como_sale       TEXT                   Markdown; NULL si no hay texto
    mapeo_docbook, mapeo_jats, notas, pendiente   internos: no se exportan
    fecha_alta, fecha_modificacion          datetime('now','localtime')

La clase es la clave con que gbpublisher valida un .md y empareja los cierres (SC-33). No es única: las variantes comparten clase (`figure` y `fig-fullwidth` son `fig`; las tres tablas, `table`). Para validar se usa el catálogo entero, en cualquier estado; para mostrar, solo lo liberado.

Restricciones: un shortcode no puede ser no_aplica en los dos; el par (modo, tipo) tiene que estar en `modos` (la figura, por ejemplo, solo existe como bloque); lo liberado tiene `que_es`, `ejemplo` y `como_sale`, y no tiene `pendiente`; un shortcode no puede estar liberado en un producto y en borrador en el otro (la regla de liberación de SC-34).

Los tres textos de la ayuda admiten NULL y no cadena vacía (`CHECK (x <> '')`): Edit + Update escribe la cadena vacía como NULL (GV-74), y con NOT NULL guardar una sección vacía fallaba.

MODOS

Desde la versión 4 son filas de la tabla `modos` (modo, tipo, descripción), una por cada par permitido. Agregar un modo es un script de datos, no una migración; lo que hace cada modo al insertar lo decide gbpublisher (`m_Shortcodes.InsertarShortcode`). Las claves foráneas valen porque la aplicación y el importador abren la base con `PRAGMA foreign_keys = ON`; sin eso, SQLite no las controla (verificado).

- envolver: rodea la selección con apertura y cierre.
- plantilla: inserta apertura, marcador y cierre, sin selección (la sigla).
- figura: el camino de `FMain.InsertarFigura` (SC-32).
- dos-partes: envolver, con el control de la forma `{primera}{segunda}` antes de insertar (SC-35).
- separador: un bloque vacío, sin selección y con el cursor al principio de una línea vacía (SC-36). Se agrega con `datos-v4-001`.
- codigo: en bloque, pide el lenguaje (y en el listado, el nombre) y cerca la selección con `~~~ lenguaje`; en línea, la envuelve en comillas inversas (SC-42). Se agrega con `datos-v5-005`, para bloque y para línea.

COMPORTAMIENTO

En gbShortcodes, el comportamiento de un shortcode es su nombre, tipo, grupo, perfil, orden, estados, modo, apertura y cierre. La aplicación no lo cambia: se aplica por script (SC-50), después de probarlo. Sí pule la etiqueta, la ayuda, los mapeos, las notas y el pendiente.

EXPORTACIÓN AL PAQUETE (CONTRATO CON gbpublisher)

A la carpeta `.hidden/shortcodes/` del proyecto gbpublisher. Van todos los shortcodes, en cualquier estado: gbpublisher filtra (instalado, solo lo liberado; desde el IDE, también los borradores).

- `_catalogo.tsv`: una cabecera fija, que hace de versión del contrato,

      nombre clase etiqueta tipo grupo perfil orden estado_libro estado_revista modo apertura cierre

  separada por tabuladores, y una línea por shortcode en el orden del catálogo: grupo (comun, estructura, disciplinar, composicion), perfil, orden, nombre. Escapes: `\\` por barra, `\t` por tabulador, `\n` por salto.
- `<nombre>.html`: fragmento, no documento. Tres secciones fijas, `<h3>Qué es</h3>`, `<h3>Cómo se escribe</h3>` y `<h3>Cómo sale</h3>`, y en la segunda la marca `<!--gb:ejemplo-->`, donde gbpublisher pone el ejemplo coloreado con su resaltador. El estilo lo pone quien lo muestra. Una sección vacía de un borrador sale «Sin completar.».
- `<nombre>.md`: el ejemplo tal cual, con salto final.

Las secciones se convierten con `pandoc -f markdown -t html --wrap=none` (Exec sobre un array, SC-05). La exportación se detiene, sin escribir nada, si una sección trae títulos, imágenes o tablas: el TextEdit de la ayuda solo tiene probados párrafos, listas, énfasis y código (GV-64). Antes de escribir exige una carpeta vacía o con `_catalogo.tsv`, y después ofrece borrar los .html y .md que no son del catálogo: todo lo que hay en la carpeta entra al .deb.

Salida determinista: dos exportaciones del mismo contenido dan archivos idénticos (verificado con diff).

OTRAS SALIDAS

- Documento de prueba, de libros o de revistas: un `.md` con un título y el ejemplo de cada shortcode que aplica, liberado o en borrador. Es lo que se compone en PDF, EPUB y HTML antes de liberar.
- Volcado SQL restaurable (verificado: restaura las 77 filas sobre una base vacía).

CARGA INICIAL

`.hidden/esquema/carga-inicial.sql`: el catálogo completo al empezar la versión de esquema en curso, para una base nueva y vacía. La de la versión 5 es la carga original de los 77 shortcodes de MySQL más `datos-v3-001` (el epígrafe), `datos-v3-002` (la figura de ancho completo) y `datos-v4-001` (el modo separador y el froufrou): 79 filas, con epigraph, figure, fig-fullwidth y froufrou liberados. Los `datos-v5-*` se aplican después. Los ejemplos de bloque llevan el cierre nombrado (SC-33).

MIGRACIONES DE ESQUEMA

El mecanismo es el de SC-50. Lo propio de cada una:

`gbshortcodes-migrar-1-a-2.sql` rehace la tabla con la columna `clase` en su lugar (las columnas y restricciones quedan iguales a las de una base creada en v2, verificado) y pone el cierre nombrado en los ejemplos que siguen iguales a los de la carga inicial; uno editado se conserva y se lista.

`gbshortcodes-migrar-2-a-3.sql` rehace la tabla con las restricciones nuevas (SQLite no cambia un CHECK en su lugar) y copia las filas sin cambiarlas, salvo la figura: si sigue como en la carga, le quita el pendiente que pedía referencia cruzada en revistas, que no existe (SC-32). Antes de copiar comprueba la regla de liberación y frena si una fila la viola. Verificado: la base migrada tiene el mismo esquema que una creada en v3, y el DDL de la aplicación es igual al de `shortcodes_esquema.sql`.

`esquema-v3-a-v4.sql` crea `modos` con sus filas, comprueba que todos los shortcodes usen un par existente y rehace la tabla con la clave foránea. Verificado: la base migrada tiene el mismo esquema que una creada en v4, y el DDL de la aplicación es igual al de `shortcodes_esquema.sql`. Con la aplicación bajo xvfb, una base v3 queda en v4 con sus 77 filas, y una base nueva se carga.

`esquema-v4-a-v5.sql` rehace la tabla con el grupo `composicion` en su CHECK, para las instrucciones de composición que solo afectan al PDF (SC-38, SC-39); va al final del catálogo. Los datos no cambian. La corre la aplicación al abrir una base v4.

`User.Home` no sigue la variable `HOME`: una prueba con otra `HOME` abre igual la base del usuario real (medido en 3.19).

**Relaciones:** vinculo:RF-08,vinculo:SC-50,vinculo:SC-24,vinculo:SC-11,vinculo:SC-32,vinculo:GV-74,vinculo:GV-64,vinculo:SC-33,vinculo:SC-35,vinculo:SC-36,vinculo:SC-42,vinculo:SC-38,vinculo:SC-39

**PENDIENTE:** Versiones 2 y 3 verificadas en Mint con 3.22.1. La 4 se probó en el contenedor (Gambas 3.19, gb.db, aplicación bajo xvfb). La 5 está en uso en Mint: los datos-v5-* se aplicaron y probaron ahí (datos-v5-011).

### RF-12 — Fuente de biblatex-philosophy (Verona)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-philosophy v1.9.8g (2022/09/16) / biber 2.19 / TeX Live 2023 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Paquete en CTAN: `macros/latex/contrib/biblatex-contrib/biblatex-philosophy`. Autor: Ivan Valbusa.

VERSIÓN ANCLADA

v1.9.8g (2022/09/16). Es la de CTAN y la de TeX Live 2023 (`texlive-bibtex-extra`), que es lo que trae la base de Mint 22. Biber 2.19 en la máquina de Alberto y en el contenedor.

ACCESO

`https://mirrors.ctan.org/macros/latex/contrib/biblatex-contrib/biblatex-philosophy.zip` descarga con `curl -L`. Algún espejo puede responder con un certificado vencido: se reintenta y la redirección lleva a otro. Con TeX Live instalado, los archivos ya están en `texmf-dist/tex/latex/biblatex-philosophy/`.

ORDEN DE CONSULTA

1. `philosophy-modern.bbx` — referencias de la disposición modern. Carga `philosophy-classic.bbx`.
2. `philosophy-classic.bbx` — la disposición classic, la de HTML y EPUB (SC-56). Carga `philosophy-standard.bbx`.
3. `philosophy-standard.bbx` — opciones del estilo, formatos de campo, relaciones (`related`), campos `orig*`.
4. `philosophy-modern.cbx` — citas.
5. `spanish-philosophy.lbx` — cadenas en español.
6. `biblatex-philosophy.dtx` — fuente documentado del que salen los anteriores. Informa la intención; si contradice al código instalado, gana el código.

La configuración de la aplicación: `.hidden/latex/cita-verona-modern-config.tex`.

DATOS DEL FUENTE QUE USA EL PROYECTO

- `\printbibliography[restoreclassic]` (definida en `philosophy-modern.bbx`) vuelve a la disposición classic: `\bibhang` igual a `\parindent`, año entre paréntesis después del nombre, guion de autor repetido según `dashed`.
- En modern el autor repetido no lleva guion: `bbx:dashcheck` no imprime nada. `\bibnamedash` solo actúa en classic y verbose.
- `lowscauthors` hace que `\mkbibsc` sea `\textsc{\MakeLowercase{#1}}`.
- `scauthorsbib` está declarada por compatibilidad: la forma vigente es `scauthors=bib`.
- Los campos `orig*` y la opción `origfields` también son compatibilidad: el mecanismo vigente es `related`. La macro `transorigstring` que redefine la configuración pertenece al mecanismo viejo.
- `refsection=chapter` no se usa: la bibliografía por capítulo la arma el generador, y con la consolidada la opción vacía la lista en silencio (GV-102). La configuración de la aplicación no la trae.

BANCO DE PRUEBAS

`ref-l-MOLINARO.bib` (222 entradas: 81 book, 73 article, 58 incollection, 8 thesis, 2 misc), más casos de choque: mismo autor y año, dos autores con el mismo apellido, listas que coinciden en el primer autor. Compilado con la configuración de la aplicación, es la salida esperada contra la que se verifican HTML y EPUB.

**Relaciones:** vinculo:SC-14,vinculo:SC-56,vinculo:RC-BL-02,vinculo:GV-102,vinculo:SC-57

**PENDIENTE:** Falta fijar dónde se guarda el banco de pruebas: el .bib de Molinaro y el de los casos de choque.

### RF-13 — Fuente de biblatex-iso690 (ISO 690)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-iso690 v0.4.1 (2022/03/20) / repositorio, commit 7231d7a / biblatex 3.19 / TeX Live 2023 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Repositorio: https://github.com/michal-h21/biblatex-iso690. Paquete en CTAN: `macros/latex/contrib/biblatex-contrib/biblatex-iso690`. Autor: Michal Hoftich.

VERSIÓN ANCLADA

v0.4.1 (2022/03/20). Es la de TeX Live 2023, la que compone en Mint 22 y en el contenedor. El repositorio (commit 7231d7a, 2025-09-28) trae los mismos archivos: `iso.bbx`, `iso-authoryear.bbx`, `iso-authoryear.cbx` y `spanish-iso.lbx` son idénticos byte a byte a los instalados (medido con diff). La aplicación usa la variante autor-año: `style=iso-authoryear`.

ACCESO

`git clone --depth 1 https://github.com/michal-h21/biblatex-iso690.git` funciona. Con TeX Live instalado, los archivos ya están en `texmf-dist/tex/latex/biblatex-iso690/`.

ORDEN DE CONSULTA

1. `iso.bbx` — opciones del estilo, formatos de campo, formato de los nombres. Fuente de verdad del comportamiento.
2. `iso-authoryear.bbx` — la variante autor-año de las referencias: orden `nyt`, `nameyeardelim`, fechas.
3. `iso-authoryear.cbx` — citas: `maxcitenames=1`, sobre `authoryear.cbx` de biblatex y `iso-fullcite.cbx`.
4. `spanish-iso.lbx` — cadenas en español; hereda las de `spanish.lbx` de biblatex.
5. `biblatex-iso690.tex` y su PDF — documentación. Informa la intención; si contradice al código, gana el código.

La configuración de la aplicación: `.hidden/latex/cita-iso690-config.tex`; la de pantalla, `cita-iso690-html.tex`.

BANCO DE PRUEBAS

`biblatex-iso690-examples.bib` (42 entradas) e `iso-example.tex`.

DATOS DEL FUENTE QUE USA EL PROYECTO

- `iso.bbx` fija `autolang=other`: cada entrada en el idioma de su `langid`. La aplicación lo cambia por `autolang=hyphen` (GV-105). El estilo trae también `currentlang` (las cadenas en el idioma del documento), que no se usa: con `autolang=other`, babel igual apaga los extras del español en una entrada en otro idioma.
- Los apellidos: `\familynameformat` va en mayúsculas (`\MakeUppercase`) o, con `familynamesc`, en `\textsc`. Se aplica con `\AtBeginBibliography`, solo en la bibliografía. La configuración de la aplicación lo reemplaza por versalitas parejas, `\textsc{\MakeLowercase{...}}`, en los cuatro componentes del nombre.
- `\mkbibacro` (DOI, ISBN, ISSN): `\textsc{\MakeLowercase{...}}` solo con `bibacrosc`, que el estilo trae desactivada.
- Títulos: `\DeclareFieldFormat*{title}{#1}`. ISO 690 no pone comillas a ningún título (SC-58).
- Citas: `\iffootnote` solo aparece en `\smartcite` (de `authoryear.cbx`), que la aplicación no emite. La detección de notas que tex4ht no responde no afecta a ISO 690 (SC-57).

**Relaciones:** vinculo:SC-14,vinculo:SC-57,vinculo:SC-58,vinculo:GV-105

### RF-14 — Fuente de biblatex-ieee (IEEE)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-ieee v1.3f (2021/12/06) / repositorio, commit ea2ebc7 (v1.4f) / biblatex 3.19 / TeX Live 2023 / contenedor Ubuntu 24.04; PDF de Duek en Mint · **Verificado:** 2026-10

Repositorio: https://github.com/josephwright/biblatex-ieee. Paquete en CTAN: `macros/latex/contrib/biblatex-contrib/biblatex-ieee`. Autor: Joseph Wright.

VERSIÓN ANCLADA

v1.3f (2021/12/06). Es la de TeX Live 2023, la que compone en Mint 22 y en el contenedor. La aplicación usa `style=ieee`.

EL REPOSITORIO YA ES OTRO

El repositorio (commit ea2ebc7, 2026-01-21) trae v1.4f (2025-08-01), y cambia lo que se ve:

- `ieee.cbx` pasa de `numeric-comp` a `numeric-verb`; la compresión queda en un archivo nuevo, `ieee-comp.cbx`.
- `ieee.cbx` pasa de `maxcitenames=3, minnames=3` a `maxcitenames=2, minnames=1`, y agrega `sortcites`. En v1.3f el `minnames=3` del cbx pisa el `minnames=1` del bbx, porque se ejecuta después: por eso el PDF de Duek pone tres nombres antes de «et al.» («G. Krichesky, P. Pogré, K. Benchimol et al.»). Con v1.4f sería uno.
- `ieee.bbx`: 115 líneas de diferencia.

Una actualización de TeX Live cambia las citas y las referencias de un libro ya compuesto: hay que medir antes de actualizar.

ACCESO

`git clone --depth 1 https://github.com/josephwright/biblatex-ieee.git` funciona. Con TeX Live instalado, los archivos ya están en `texmf-dist/tex/latex/biblatex-ieee/`.

ORDEN DE CONSULTA

1. `ieee.bbx` — formatos de campo, cadenas propias, opciones. Requiere `numeric-comp`. Fuente de verdad del comportamiento.
2. `ieee.cbx` — citas. En v1.3f, sobre `numeric-comp.cbx` de biblatex, con `sorting=none`: las referencias se numeran en el orden de cita.
3. `biblatex-ieee.tex` y su PDF — documentación. Informa la intención; si contradice al código, gana el código.

La configuración de la aplicación: `.hidden/latex/cita-ieee-config.tex`; la de pantalla, `cita-ieee-html.tex`.

BANCO DE PRUEBAS

`biblatex-ieee.bib`, en el repositorio.

DATOS DEL FUENTE QUE USA EL PROYECTO

- Cadenas propias: `ieee.bbx` declara `presentedat` y `patentjp` y las define solo en inglés. En castellano salen en negrita (GV-106); `cita-ieee-config.tex` las define (SC-59).
- Puntuación: `ieee.bbx` llama a `\uspunctuation` sin distinguir idioma (línea 34), la convención norteamericana que mete la coma y el punto dentro de las comillas: «título,». En castellano van después: «título»,. `cita-ieee-config.tex` agrega `\DefineBibliographyExtras{spanish}{\stdpunctuation}`: `\stdpunctuation` (`biblatex.def`) deshace lo de `\uspunctuation`, y como extra del español solo actúa en un libro en español; uno en inglés conserva la convención de IEEE. Ningún otro estilo de la aplicación llama a `\uspunctuation` (philosophy, apa, iso690: medido con grep). MEDIDO con el `.bib` de Duek: 87 comas y 5 puntos pasan detrás de la comilla, sin ningún otro cambio en el texto; la pasada de tex4ht hereda la corrección (69 «»,» en `citas.html`, ninguna «,»»); vnu y epubcheck sin errores. Hallazgo de Alberto en las tres salidas de Duek.
- La numeración vuelve a 1 en cada `refsection`: en un libro, en cada pieza con bibliografía, como en el PDF.
- Citas: `\iffootnote` solo aparece en `\smartcite` (de `numeric-comp.cbx`), que la aplicación no emite. La detección de notas que tex4ht no responde no afecta a IEEE (SC-57).
- Una cita con varias claves sale con un corchete por clave («[1], [2]») y un rango con tres o más seguidas («[22]-[24]»).

**Relaciones:** vinculo:SC-14,vinculo:SC-57,vinculo:SC-59,vinculo:GV-106

---

## GV — Comportamientos verificados

Evidencia empírica de Gambas, Pandoc y el resto del pipeline. Desde la actualización 24, lo de XML, XSLT y sus validadores va a GV-XML; las entradas anteriores quedan acá con su código

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

DESDE SC-68 la marca de espacio fijo del .md es `¬` (U+00AC), que TextEdit conserva (GV-132). El .md sigue sin U+00A0: el espacio duro lo ponen el filtro y el lector de Pandoc, después de leer el archivo.

**Relaciones:** vinculo:SC-02, vinculo:GV-03, vinculo:SC-16,vinculo:SC-68,vinculo:GV-132

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, ComboBox.class (etiqueta 3.22.1); uso en Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-10

En `gb.qt5` el `ComboBox` es el de `gb.gui.base`, escrito en Gambas: el componente no trae uno propio en C++. `Index_Write` termina en `Raise Click` sin comparar con el valor anterior, así que asignar el índice que ya está elegido también dispara `Click`.

Es el efecto colateral que SC-06 neutraliza con `bAbriendoProyecto`, pero la bandera solo suprime el aviso de cambios sin guardar. Si el handler carga el archivo, reasignar el mismo `Index` lo recarga, y en un `TextEdit` eso reasigna `RichText` y vacía el historial de deshacer (GV-46).

REGLA: antes de asignar `Index` desde el código, compararlo con el actual. Si es el mismo, no se asigna.

CASO EN EL PROYECTO: el temporizador de archivos llama a `CargarListaArticulosMD(True)`, que vacía el combobox y repone la selección asignando `Index`. Eso recargaba el archivo abierto: preguntaba por cambios sin guardar y vaciaba el deshacer. Como ahí la asignación no se puede evitar, `cmbArticulosRevista_Click` sale sin hacer nada si la ruta elegida es la del archivo ya abierto, antes del aviso de SC-06.

MÁS CASOS: los refrescos en caliente de `cmbVerPDF` y `cmbImagenes` (SC-27) reponen el `Index` con una bandera que el handler consulta. Lo que hacen `Clear` y `Add` al volver a llenar un combo de solo lectura está en GV-69.

**Relaciones:** vinculo:SC-06, vinculo:GV-46, vinculo:SC-18, vinculo:SC-27, vinculo:GV-69

**PENDIENTE:** Leído en el fuente (etiqueta 3.22.1). En uso, en 3.22.1, se probaron las correcciones que dependen de este comportamiento (SC-27), no el disparo aislado. Mini-test: con un ítem elegido, asignar el mismo Index y contar los Click (esperado 1).

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

### GV-56 — Una referencia a un miembro inexistente de otro módulo compila: la falla queda para la ejecución

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-09

Caso de la sesión que implementó los snippets (SC-21). `m_Snippets.Expandir` usaba `m_Constantes.SNIPPET_MARCADOR` antes de que la constante existiera en `m_Constantes`. Limpiar y Compilar no dio ningún error; la aplicación arrancó y el formulario de snippets funcionó.

La falla en ejecución no se llegó a observar: la constante se agregó antes de que esa línea corriera.

POR QUÉ IMPORTA

Que el proyecto compile no prueba que existan los miembros que un módulo usa de otro. El error aparece recién cuando la línea se ejecuta, que puede ser mucho después y lejos de donde está la causa. Es la misma familia que GV-32 y GV-23.

REGLA

Un parche que agrega una referencia a un miembro de otro módulo —constante, variable, función— entra en el MISMO lote que el alta de ese miembro, y el lote se aplica entero antes de recompilar. Ante la duda, buscar el nombre en `.src` antes de dar el parche por aplicado: no alcanza con que compile.

**Relaciones:** vinculo:GV-32, apoya:GV-23, vinculo:SC-03, vinculo:SC-21

**PENDIENTE:** Falta provocar la falla a propósito, ejecutando la línea sin el miembro, para registrar el mensaje exacto de ejecución.

### GV-57 — Visibilidad de los controles de un formulario: la decide la opción ControlPublic del proyecto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble (gbc3 con y sin -f public-control); gbpublisher en Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-09

Por omisión, los controles de un `.form` son privados salvo que lleven `#Public = True` (en el archivo, además, un `!` delante del nombre). Usarlos desde otro módulo compila y falla recién al ejecutar la línea:

    Unknown symbol 'privado' in class 'Container' (#11)

Medido en banco en tres situaciones, las tres con el mismo error: formulario sin mostrar (instancia automática), formulario mostrado, y dentro de `With Formulario`.

LA OPCIÓN DEL PROYECTO LO CAMBIA TODO

`ControlPublic=1` en el `.project` hace públicos TODOS los controles de todos los formularios, lleven o no `#Public`. El compilador la recibe como `-f public-control`. Medido en banco: con esa opción, las tres situaciones anteriores funcionan.

gbpublisher tiene `ControlPublic=1` (y también `ModulePublic=1`). Por eso `FMetadatosRevista.numero_especial`, que no tenía `#Public`, abría y guardaba bien desde `m_Metadatos` en 3.22.1 (verificado por Alberto). En este proyecto, el `#Public` de cada control no decide nada.

CORRECCIÓN

La primera versión de esta entrada decía que un control sin `#Public` fallaba al usarse desde otro módulo, y lo aplicaba a gbpublisher. Se había medido en un banco que no copiaba las opciones del `.project`. El error real de la sesión fue otro: un control BORRADO desde el diseñador (`idioma_titulo_traducido`, en FMetadatosCapitulos) que `m_Metadatos` seguía usando. Es el caso de GV-56.

REGLA

- Antes de razonar sobre la visibilidad de un control, mirar `ControlPublic` en el `.project`.
- Un banco de pruebas reproduce el proyecto solo si copia sus opciones de compilación.
- Después de editar un formulario en el diseñador, lo que se coteja es la EXISTENCIA: que los controles que usan otros módulos sigan estando, con el mismo nombre y del mismo tipo.

**Relaciones:** vinculo:GV-56,apoya:GV-23

### GV-58 — GridView: escribir una celda fuera de Columns.Count da «Bad column index» dentro de gb.gui.base

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble; Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-09

    ' GRILLA CON Columns.Count = 2
    Try g[0, 2].Text = "x"
    -> Bad column index | [gb.gui.base].GridView._CheckCell.1428

Medido en banco. El error ocurre dentro del código Gambas del componente, no en el del proyecto.

EL DIÁLOGO QUE CONFUNDE

En 3.22.1 (Mint), ejecutando desde el IDE, el mismo error apareció como un diálogo «Localizar el proyecto para el componente: gb.gui.base», con un selector de carpetas. No es un pedido de instalar nada ni un conflicto con gb.qt5: el depurador quiere abrir el fuente del componente donde ocurrió el error para mostrar la línea. Cancelar el diálogo deja ver el error.

CASO DEL PROYECTO

`ConfigurarTableViewBibtexEnCurso` fija la grilla en 112 columnas. La actualización 1.1.0 llevó `bibtex` a 113, y `CargarDatosResultados` recorría `resultado.Fields.Count`: falló al mostrar un duplicado en la grilla, y también afectaba a las búsquedas que usan esa función. La grilla principal no fallaba porque ajusta `Columns.Count` a `Fields.Count`.

REGLA

Un volcado de un `Result` a una grilla de columnas fijas recorre `Min(resultado.Fields.Count, Grid.Columns.Count)`. Y todo cambio de esquema revisa los `Columns.Count` fijos de las grillas de esa tabla (SC-22).

**Relaciones:** vinculo:GV-15,vinculo:SC-22

### GV-59 — ComboBox: qué pasa al asignar Text, según sea de solo lectura o editable

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble · **Verificado:** 2026-09

Medido en banco:

    ReadOnly, valor fuera de la lista   se pierde en silencio: Index -1, Text vacío, sin Click
    ReadOnly, valor de la lista         se selecciona
    editable, valor de la lista         se selecciona y DISPARA Click
    editable, valor fuera de la lista   queda escrito; no dispara Click
    asignar .List                       selecciona el primer ítem, sin Click
    Find                                distingue mayúsculas

CONSECUENCIAS

Un combo de solo lectura valida por construcción, pero pierde sin aviso un dato heredado que no esté en su lista: al abrir el formulario el valor desaparece y al guardar se escribe vacío o NULL. Antes de pasar un campo a solo lectura, un informe de control revisa los datos existentes; y un valor en uso no se retira de la lista (SC-23).

En un combo editable con un `Click` que completa otro campo —licencia que escribe su URL—, cargar un registro dispara el handler y reescribe el campo dependiente con el valor del catálogo. Es el mismo efecto colateral que GV-53 con `Index`.

**Relaciones:** vinculo:GV-53,vinculo:SC-23

### GV-60 — Integer[] no tiene Join, y el error aparece recién al ejecutar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu noble · **Verificado:** 2026-09

`Join` es de `String[]`. Sobre un `Integer[]` compila y falla en ejecución:

    Unknown symbol 'Join' in class 'Integer[]' (#11)

Para armar una lista de ids, por ejemplo para un `IN (...)`, se pasa por un `String[]`:

    For Each iId In aIds
      aTextos.Add(CStr(iId))
    Next
    sLista = aTextos.Join(",")

Verificado en la misma sesión: un arreglo en línea con una función que devuelve Integer, `[m_BuscarBib.ElegidoId()]`, es un `Integer[]` y se puede pasar a un parámetro de ese tipo. `Min(a, b)` existe como función.

Otro caso de la familia de GV-56: compila, y la falla queda para la ejecución.

**Relaciones:** vinculo:GV-56

### GV-61 — gb.settings lee True y False sin comillas como Boolean; CBool("False") es True

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.settings / contenedor Ubuntu noble · **Verificado:** 2026-09

En un archivo leído con `Settings`, una clave `Busqueda=True` sin comillas se devuelve como Boolean, no como cadena: pasarla por `CStr` da `"T"` (GV-10), y un código que la trate como texto falla.

Y el camino inverso tampoco sirve: `CBool("False")` devuelve True, porque toda cadena no vacía es verdadera.

REGLA: para leer un booleano de un `.conf`, preguntar primero `TypeOf(vValor) = gb.Boolean` (GV-33) y recién después, si llegó como texto, compararlo con los literales esperados.

Caso del proyecto: `m_LLM.TieneBusqueda` leía el campo `Busqueda` de los `.conf` de proveedores.

**Relaciones:** vinculo:GV-10,vinculo:GV-33

### GV-62 — RadioButton: Click solo en el que queda marcado, también al asignar Value

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble · **Verificado:** 2026-09

`Click` se dispara únicamente en el RadioButton que QUEDA marcado, no en el que se desmarca. Pasa igual al asignar `Value = True` desde el código. Si el botón ya estaba marcado, no se dispara nada.

Consecuencia: un grupo de modos se atiende con un handler por botón que actúe sobre el que quedó marcado; no hace falta atender el desmarcado. Y fijar el modo inicial por código dispara el handler una vez, lo que sirve para dejar la interfaz coherente sin llamarlo aparte.

Caso del proyecto: `rdbFormatear` / `rdbConsultar` del análisis de referencias con LLM.

**Relaciones:** vinculo:GV-55

### GV-63 — Create + Update: el INSERT lleva solo los campos asignados

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.db / MySQL 8.0.46 / Linux Mint; código fuente de CResult.c · **Verificado:** 2026-09

Con el patrón `Create` + asignaciones + `Update`, el `INSERT` que arma el driver incluye solo los campos a los que se asignó un valor. Los demás no van en la sentencia y toman el DEFAULT de la columna.

Leído en el fuente de gb.db (`CResult.c`, `Result_Update`, etiqueta 3.22.1) y coherente con lo observado en MySQL: después de la actualización 1.1.0, las filas nuevas de `bibtex` recibieron sola la fecha de `fecha_modificacion DEFAULT CURRENT_TIMESTAMP`, y las previas quedaron en NULL.

Consecuencias:
- Un DEFAULT de la base funciona sin que el código lo conozca: no hace falta asignar la columna.
- Asignar `Null` explícito SÍ va en la sentencia y escribe NULL, por encima del DEFAULT (GV-34).
- Una columna NOT NULL sin DEFAULT que no se asigne hace fallar el alta.

**Relaciones:** vinculo:GV-34,vinculo:RC-GM-15

### GV-64 — TextEdit.RichText: respeta un bloque <style> con selectores de etiqueta y de clase, y no muestra el <title>

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

Medido con un HTML completo, con `<title>` y `<style>` en la cabecera, asignado a `RichText`, al lado del mismo contenido con los estilos en línea. Los dos se ven iguales.

LO QUE SE APLICA

- Selectores de etiqueta (`h3`, `h4`, `p`, `li`, `code`) y de clase (`.nota`) de un bloque `<style>`.
- `color`, `font-size`, `font-weight`, `font-style`, `font-family` (monoespaciada incluida), `margin-left` y `line-height`.
- Listas, negrita y cursiva.

LO QUE NO

- El `<title>` no se muestra: el documento puede llevar su título sin que aparezca en el visor.
- El `background-color` de un `code` en línea no se vio.

FONDO DE BLOQUE: SÍ

El `background-color` de un elemento de bloque sí se ve, a todo el ancho: en un `p`, por clase o en línea, y en la celda de una tabla con `width="100%"`, por `bgcolor` o por clase. Con letra blanca sirve de franja. La celda de tabla da mejor proporción entre la letra y la altura de la franja; es la que usa la ayuda (SC-24).

HTML NORMALIZADO

Leer `RichText` después de asignarlo devuelve el HTML reescrito por Qt, con los estilos resueltos en línea en cada `p` y `span` (por ejemplo `margin-left:10px; -qt-block-indent:0`). Sirve para ver qué conservó.

AJUSTE DE LÍNEA

`Wrap` vale False por omisión. Sin `Wrap = True` los párrafos no se parten y aparece la barra de desplazamiento horizontal.

Una página completa generada por Jekyll, mucho más cargada, también se vio bien; una imagen que no se encuentra aparece como un icono roto.

CONSECUENCIA

Un HTML hecho para mostrarse en `TextEdit` puede llevar una sola hoja de estilo en la cabecera: no hace falta repetir los estilos en cada elemento.

**Relaciones:** vinculo:GV-37,vinculo:GV-52,vinculo:SC-24

**PENDIENTE:** No se miró en la consola si Qt conserva el background-color del code en línea. No se probaron enlaces ni tablas con varias filas o columnas.

### GV-65 — TextEdit.Selection: Start es el extremo menor y cuenta caracteres; String.Mid es lineal en los dos sentidos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

`Selection.Start` y `Selection.Length` de `TextEdit` existen y cuentan CARACTERES del texto plano, igual que `Select` y `Pos` (RC-GM-21). Verificado con «¿» y «»», de dos bytes cada uno: `Length` vale 1, y `String.Mid(.Text, Start + 1, Length)` coincide con `Selection.Text`.

`Start` es siempre el extremo MENOR de la selección, se haya hecho hacia la derecha o hacia la izquierda. `Pos` es el extremo que se movió:

    selección hacia la derecha     Start = 10   Pos = 11
    selección hacia la izquierda   Start = 25   Pos = 25

REGLA: para operar sobre una selección se leen `Start` y `Length`, nunca `Pos`.

Hacer click en un botón no borra la selección del `TextEdit`: el handler del botón la lee intacta.

RECORRIDO CON String.Mid EN LOS DOS SENTIDOS

GV-03 midió el recorrido hacia adelante. Hacia atrás, desde el final, también es lineal. Capítulo real de 49.940 caracteres:

    caracteres   hacia adelante   hacia atrás
    10.000       0,006 s          0,006 s
    20.000       0,013 s          0,009 s
    40.000       0,025 s          0,016 s

`String.InStr` recorre el capítulo entero en 1 ms y cuenta lo mismo que `InStr` por bytes: no hace falta bajar a bytes para buscar rápido, y no se toca RC-GM-12.

Banco: `MBanco` (selección de pares). Aplicado en `m_ParesDelimitadores`.

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-03, vinculo:GV-44, vinculo:SC-18

**PENDIENTE:** La selección de dos caracteres (espacio + raya) no se midió en el banco; queda cubierta al probar m_ParesDelimitadores.

### GV-66 — Imágenes sin escala: el tamaño lo da el archivo, y un PNG sin resolución sale cuatro veces más grande

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 / poppler 24.02 / contenedor Ubuntu 24.04 · **Verificado:** 2026-09

`\includegraphics` sin `width` ni `height` compone la imagen a su tamaño natural. Medido con un logo de 30 mm de ancho en tres formatos:

    PDF de 30 mm                              85,36 pt  (30 mm exactos)
    PNG de 355 px con resolución de 300 ppp   85,52 pt
    el mismo PNG sin resolución declarada    356,33 pt

Sin el bloque `pHYs`, que declara la resolución, LuaTeX supone 72 ppp: 355 px dan 125 mm. No hay aviso. `pdftocairo -png -r 300` escribe `pHYs`; un PNG exportado por otra herramienta puede no traerlo.

REGLA: una imagen que se compone sin escala se acepta en PDF, o en PNG con resolución declarada. Los logos de las primeras no entran en esta regla: se componen a ancho fijo (SC-25), que ignora la resolución.

PDF A SVG

`pdftocairo -svg` convierte el texto del PDF en trazos, así que el SVG no depende de fuentes, y conserva el tamaño. Pero escribe `width` y `height` SIN UNIDAD:

    <svg ... width="85.039" height="34.016" viewBox="0 0 85.039 34.016">

Un valor sin unidad son píxeles CSS, no puntos: en un navegador o en un lector de EPUB el logo sale al 75 %. Hay que agregarles `pt`.

EPUB 3.3 admite como imagen gif, jpeg, png, svg+xml y webp. PDF no.

**Relaciones:** vinculo:SC-25

**PENDIENTE:** Medido en contenedor, no en Mint. Sin medir: un JPG sin densidad declarada, y el SVG corregido con pt en epubcheck y en un lector.

### GV-67 — Un respaldo de mysqldump de gbpublisher no se restaura con el comando directo: articulos supera el tamaño de fila

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-09

Restaurar un respaldo con el comando directo falla en la tabla `articulos`:

    sudo mysql gbpublisher < respaldo.sql
    ERROR 1118 (42000) at line 194: Row size too large (> 8126).

Y falla DESPUÉS de haberla borrado: el volcado trae un `DROP TABLE IF EXISTS` antes de cada `CREATE TABLE`, y el cliente se detiene en el primer error. La base queda sin `articulos`, con las tablas anteriores en orden alfabético ya restauradas y las siguientes sin tocar: una mezcla de dos momentos, peor que antes de intentarlo. Verificado: después del intento, `articulos` no existía.

CAUSA

Con `innodb_strict_mode` activo —el valor por omisión en MySQL 8—, InnoDB rechaza un `CREATE TABLE` cuyo peor caso teórico de tamaño de fila supera el límite, aunque ninguna fila real lo alcance. `articulos` tiene 220 columnas. El baseline desactiva el chequeo en su cabecera (`SET SESSION innodb_strict_mode=0`); `mysqldump` no escribe esa línea.

RESTAURACIÓN CORRECTA

    sudo mysql --init-command="SET SESSION innodb_strict_mode=0" gbpublisher < respaldo.sql

Verificado: restaura la base completa, `esquema_version` incluida.

ALCANCE

Los mensajes «Para volver atrás» de `actualizar-esquema-1.1.0.sh` a `1.3.0.sh` dan el comando directo. Los respaldos que dejaron en `~/gbpublisher-respaldos` están bien; lo que cambia es cómo se restauran. `actualizar-esquema-1.4.0.sh` ya trae el comando correcto.

**Relaciones:** vinculo:SC-22

**PENDIENTE:** Corregir el mensaje de restauración en actualizar-esquema-1.1.0.sh a 1.3.0.sh. Sin verificar en MariaDB.

### GV-68 — Asignar "" a una clave de Collection no la crea, y si existía la borra

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbs3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-09

Asignar una cadena vacía a una clave de `Collection` no la crea, y si la clave ya existía, la borra:

    c["a"] = ""        c.Exist("a")  ->  False
    c["b"] = "x"       c.Exist("b")  ->  True
    c["b"] = ""        c.Exist("b")  ->  False, c.Count baja

La razón es que en Gambas la cadena vacía ES Null (`IsNull("")` da True), y asignar Null a un elemento de una `Collection` lo elimina.

CONSECUENCIA

`Exist` no sirve para saber si una clave «está definida con valor vacío». Un código que arma una `Collection` de valores leídos de la base, con claves que pueden venir vacías, pierde esas claves sin aviso; si después decide con `Exist` qué claves son válidas, trata un dato vacío como uno desconocido.

REGLA

La lista de claves válidas se escribe aparte —un `Select Case`, una constante—, no se deduce de la `Collection`. Para leer, una función que devuelva "" si la clave no está.

Un OBJETO sí se conserva aunque esté vacío: un `String[]` sin elementos asignado a una clave la crea.

Caso del proyecto: `m_PrimerasLibro`, marcadores de los textos de créditos (SC-25): `EsMarcadorConocido` y `ValorDe`.

**Relaciones:** vinculo:SC-25,vinculo:GV-24

**PENDIENTE:** Medido en 3.19, no en 3.22.1.

### GV-69 — ComboBox de solo lectura: Clear y Add mueven el índice sin disparar Click

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, ComboBox.class (etiqueta 3.22.1 y rama principal 41d9348) · **Verificado:** 2026-10

Leído en el fuente de `gb.gui.base` (`ComboBox.class`), idéntico en la etiqueta 3.22.1 y en la rama principal (`41d9348`). Completa a GV-53 y GV-59 para el caso de volver a llenar un combo de solo lectura.

    Clear                              Index -> -1, sin Click
    Add sobre el combo vacío           Index -> 0, sin Click (ResetIndex)
    Add con un ítem elegido            Index no cambia
    Add(Item, Posición)                Index NO se corre
    Index = -1 con un ítem elegido     Index -> -1, y SÍ dispara Click
    Index = -1 con Index ya en -1      no hace nada, sin Click

`ResetIndex` tiene el `Raise Click` comentado en el fuente.

CONSECUENCIAS

- Después de poblarlo, un combo de solo lectura muestra el primer ítem sin que su handler haya corrido: el combo dice una cosa y lo que depende del `Click` (un visor, una imagen) sigue vacío. Coincide con lo que GV-59 midió para `.List`.
- Insertar en posición delante del ítem elegido deja el índice apuntando a otro ítem. Para conservar lo abierto no se inserta: se vacía, se vuelve a llenar y se repone la selección por nombre (SC-27).
- Dejar el combo sin selección (`Index = -1`) también pasa por el `Click`: se suprime igual que al reponer la selección.

**Relaciones:** vinculo:GV-53, vinculo:GV-59, vinculo:SC-27

**PENDIENTE:** Leído en el fuente, no medido aislado. Mini-test: combo con ReadOnly = True; Clear, Add("a"), Print .Index (esperado 0) contando los Click (esperado 0); después Index = -1 (esperado 1 Click). Lo probado en uso en 3.22.1 son los dos refrescos de SC-27, que dependen de este comportamiento.

### GV-70 — titlesec con calcwidth compone el título dos veces: un contador en el título avanza doble

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** titlesec (TeX Live 2023) / LuaLaTeX / contenedor; manual de titlesec §2.9 · **Verificado:** 2026-10

Con la opción `calcwidth`, titlesec compone cada título dos veces: una para medir su ancho y otra para componerlo. Lo que el título haga con un contador ocurre dos veces.

Medido con la estética de libros, que carga titlesec con `calcwidth`: `\section[…]{Título\footnote{…}}` numera las notas 2, 3, 5 en lugar de 1, 2, 3. Sin `calcwidth`, 1, 2, 3.

El manual de titlesec lo documenta (§2.9: «if you increase a counter globally, you are increasing it twice») y da la salida:

    \iftitlemeasuring{MIDIENDO}{COMPONIENDO}

`\gbNotaTitulo` (contrato 7, SC-29) la usa: al medir no emite nada. La medición del ancho pierde la marca, que es despreciable.

Vale para cualquier cosa que avance un contador o escriba en un archivo auxiliar desde un título: un `\index`, un `\label` propio, un contador del proyecto.

**Relaciones:** vinculo:SC-29

### GV-71 — Saxon con indent="yes" mete espacio en el contenido mixto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / contenedor · **Verificado:** 2026-10

Con `method="xml"` e `indent="yes"`, Saxon agrega un salto de línea con sangría entre dos etiquetas contiguas aunque estén dentro de un párrafo, cuando no hay texto entre ellas:

    <quote>esta es una prueba de <quote>texto</quote></quote>

sale como

    <quote>esta es una prueba de <quote>texto</quote>
             </quote>

Ese salto es contenido: llega a la salida como un espacio. Pasa al abrir (`<quote><emphasis>`), al cerrar (`</emphasis></quote>`), entre una marca y su nota (`</emphasis><footnote>`) y dentro de enlaces y negritas.

Medido con SaxonJ-HE 12.5 en los ensamblados del canónico y en los EPUB. Con el método html, Saxon no sangra dentro del texto en línea: el HTML salía limpio con el mismo canónico.

Regla: una hoja que escribe XML con texto en línea usa `indent="no"`. Si hace falta legibilidad, la alternativa es `suppress-indentation` con la lista de elementos de contenido mixto, que hay que mantener.

El parche de fechas de `jats-to-scielo` («PACKTOOLS RECHAZA SALTOS DE LÍNEA») venía de esta misma causa.

**Relaciones:** vinculo:SC-30

### GV-72 — Pandoc 3.1: el escritor DocBook descarta el id de una figura

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Con `--to docbook5`, un `Figure` sale como `<figure>` sin `xml:id`, cualquiera sea la forma del .md:

    ![Pie](media/x.png){#fig-x}              <figure> sin id
    ::: {#fig-x}  ![Pie](media/x.png)  :::   <anchor xml:id="fig-x"/> y después <figure> sin id
    ::: {.fig #fig-x} ...                    <figure> sin id (el id del div se pierde)

Un atributo `fig-alt` tampoco llega. Asignar el identifier al `Figure` desde un filtro Lua no cambia la salida. Con `--to jats` el id sí llega (`<fig id>`).

Consecuencia: sin `xml:id` no hay `\label` ni referencia cruzada. El filtro de libro arma el `<figure>` como RawBlock (SC-32).

Un `error(mensaje, 0)` en un filtro Lua detiene Pandoc con código 83 y escribe en stderr «Error running filter …» seguido del mensaje.

**Relaciones:** vinculo:SC-32,apoya:GV-23

### GV-73 — tocdepth en 0 vacía el índice de figuras y el de cuadros en book

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** book.cls / LuaLaTeX / TeX Live 2023 / contenedor · **Verificado:** 2026-10

book.cls compone las entradas del índice de figuras con `\@dottedtocline{1}`, y `\@dottedtocline` descarta una entrada cuyo nivel supera `tocdepth`. Con `tocdepth` en 0 —el sumario de SC-26 lleva solo partes y piezas— el `.lof` tiene todas las entradas y la página del índice de figuras sale solo con el título. Lo mismo el de cuadros, que usa la misma definición (`\let\l@table\l@figure`).

Corregido en `preambulo-estetica.tex`, junto al `tocdepth`: `\l@figure` pasa a nivel 0, con la sangría y el ancho de número de la clase, y `\l@table` lo copia. El sumario no cambia.

Verificado: antes, página vacía; después, las seis figuras del libro de prueba con su número y su página.

**Relaciones:** vinculo:SC-32,vinculo:SC-26

### GV-74 — Edit + Update: asignar una cadena vacía escribe NULL

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.db.sqlite3 / SQLite 3.45.1 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Con el patrón Edit + Update (RC-GM-15), asignar una cadena vacía a un campo escribe NULL, no ''. Sobre una columna NOT NULL, el Update falla:

    rE = hConn.Edit("shortcodes", "nombre = &1", "verse")
    rE!como_sale = "x"      ->  Update ok
    rE!como_sale = ""       ->  Cannot modify record: Abort due to constraint violation

Es la misma raíz que GV-68: en Gambas la cadena vacía es Null, y GV-34 ya registró que asignar Null escribe NULL.

CONSECUENCIA

Una columna de texto que la interfaz puede dejar vacía no lleva NOT NULL: lleva `CHECK (columna <> '')`, y «sin texto» es NULL, nunca ''. Así está el esquema de gbShortcodes (RF-11).

Al leer, el NULL vuelve como cadena vacía a una variable String, y al escribir un volcado SQL, un campo NOT NULL vacío llega como Null: el volcado tiene que emitir '' para esos campos y NULL solo para los nulables.

CASO DE gbCorpus

`entradas.cuerpo` y `entradas.relaciones` son NOT NULL con DEFAULT '', y `GuardarEntrada` los asigna tal cual. Por esta regla, guardar una entrada sin relaciones fallaría; y `ArmarVolcado` emite NULL para un `relaciones` vacío, con lo que el volcado no se restauraría. Ver el pendiente.

**Relaciones:** vinculo:GV-34,vinculo:GV-68,vinculo:RC-GM-15,apoya:GV-23,vinculo:RF-11,vinculo:RF-08

**PENDIENTE:** Sin verificar en 3.22.1 con gb.db2. Mini-test: en gbCorpus, abrir una entrada sin relaciones (RC-GM-03), cambiar una letra del título y Guardar. Si falla, corregir GuardarEntrada y ArmarVolcado de gbCorpus.

### GV-75 — Prefijo de tipo más una letra: puede ser palabra clave

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbc3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El compilador no distingue mayúsculas en las palabras clave, así que un nombre de variable con el prefijo de tipo de la convención y una sola letra puede ser una palabra clave:

    Dim iN As Integer      ->  Unexpected In
    Dim oF As CShortcode   ->  Syntax error. Identifier expected (en For Each oF In ...)

Verificado los dos al escribir el banco de pruebas de gbShortcodes. Por la misma regla deberían caer `iS`, `aS`, `iF`, `oR`, `tO` y `aNd`; no están verificados.

REGLA: el nombre después del prefijo tiene al menos dos letras con sentido (`iCant`, `oElem`), que es además lo que pide la convención de nomenclatura.

**Relaciones:** vinculo:GV-09

### GV-76 — gb.highlight: un espacio literal en un patrón match es error de sintaxis

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.highlight / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

En un archivo `.highlight` de gb.highlight, un patrón `match` con un espacio literal no carga. Tampoco dentro de una clase de caracteres:

    match /^\[\/[a-z]+\]: # \(\)$/       error
    match /^\[\/[a-z]+\]:[ ]#[ ]\(\)$/   error
    match /^\[\/[a-z]+\]:\x20#\x20\(\)$/ carga y reconoce la línea

El error no señala el espacio:

    Cannot load highlighter '…': [gb.highlight].TextHighlighter.CreateCustomHighlighter.520: Syntax error at line 2

La línea es la del patrón dentro del archivo.

REGLA

En los patrones, el espacio se escribe `\x20`, o `\s` cuando sirve cualquier blanco.

Medido con un programa de prueba que registra la gramática con `TextHighlighter.Register` y corre `Run` línea por línea.

Caso del proyecto: el ancla de cierre `[/clase]: # ()` (SC-33) en `Markdown.highlight`.

**Relaciones:** vinculo:SC-34,vinculo:SC-33

**PENDIENTE:** Medido en 3.19, no en 3.22.1.

### GV-77 — File.Load y <> comparan bien un archivo binario, con bytes nulos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbx3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

`File.Load` devuelve el archivo entero aunque tenga bytes nulos, y `<>` compara las cadenas por su largo y su contenido, no hasta el primer nulo:

    b1 = "ab\0cd"   b2 = "ab\0ce"   b3 = copia de b1
    Len(File.Load(b1))                       ->  5
    File.Load(b1) <> File.Load(b2)           ->  True
    File.Load(b1) <> File.Load(b3)           ->  False

CONSECUENCIA

El cotejo de recursos de SC-11 sirve también para un binario, como el `.ott` del ODT, sin sumas de verificación.

**Relaciones:** vinculo:SC-11

**PENDIENTE:** Medido en 3.19, no en 3.22.1.

### GV-78 — GridView: asignar Row emite Change y Select, nunca Click

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, GridView.class (etiqueta 3.22.1); uso en Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-10

`Row_Write` llama a `MoveTo`, que emite `Change` y, en modo `Select.Single`, `Select`. `Click` no sale de ahí: solo lo emite `ScrollArea_MouseDown`, diferido con `After Do RaiseClick`, y solo si el mouse cayó sobre una celda (`$bInCell`). Leído en `GridView.class` de `gb.gui.base`, etiqueta 3.22.1. `gb.qt5` no trae un `GridView` propio en C++: usa ese, como con el `ComboBox` (GV-53).

    asignar Row (o Column)          Change; Select en Select.Single; nunca Click
    click del mouse sobre celda     Click, diferido con After Do

Dos detalles de `MoveTo`:

- Si la fila y la columna pedidas son las actuales, sale sin emitir nada.
- Una fila fuera de rango (`>= Rows.Count`) se ignora en silencio: ni error ni evento.

`Change` se puede cancelar: si su handler hace `Stop Event`, la fila vuelve a la anterior.

REGLA: la navegación cuelga de `Click`, como en `TreeView` (GV-51). Así, marcar desde el código la fila que corresponde a la posición del editor no navega y no hay realimentación. Si alguna vez un handler de `Select` o `Change` navega, asignar `Row` sí provoca el salto.

CASO EN EL PROYECTO: `EjecutarBusqueda` marca con `gvResultados.Row` la coincidencia a la que saltó; el salto desde la grilla vive en `gvResultados_Click`.

EN Select.Multiple, Select NO ES «SE ELIGIÓ UNA FILA»

En modo `Select.Multiple`, `MoveTo` emite `Change` pero no `Select`. `Select` sale de `_RaiseSelect`, cuando cambia el CONJUNTO de filas seleccionadas, y se suprime o se difiere al soltar el botón mientras el mouse arrastra una selección (`$bDoNotRaiseSelect`, `$bMoveRaiseSelect`). Un click sobre una fila que ya está seleccionada —por ejemplo después de Ctrl+A, o al volver a la fila marcada— no cambia la selección y no emite `Select`. Leído en `GridView.class` de `gb.gui.base`, etiqueta 3.22.1 (`ScrollArea_MouseDown`, `AfterMouseUp`). En 3.19, en el banco, un click sobre una fila NO seleccionada sí emitió `Select`: el fallo depende del estado de la selección, y por eso no siempre aparece.

CASO EN EL PROYECTO (2): `FRegexResultados`, que es `Select.Multiple` para elegir qué reemplazar, navegaba desde `gvResultados_Select` y en Mint el editor no cambiaba de archivo. Pasó a `gvResultados_Click`, con el preview en `gvResultados_Change` (SC-51).

**Relaciones:** vinculo:GV-51,vinculo:GV-53,vinculo:GV-15,vinculo:GV-58,vinculo:GV-69,vinculo:SC-51

**PENDIENTE:** Leído en el fuente; en uso en 3.22.1 se probó la búsqueda con la fila marcada, no el disparo aislado. Mini-test: Debug en gvResultados_Click, buscar con Enter o F3 con varias coincidencias; asignar Row desde el código no debe imprimir nada.

### GV-79 — Pandoc: smart en el escritor Markdown aplana y escapa; en el lector convierte

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor · **Verificado:** 2026-10

Tres comportamientos de la extensión `smart`, medidos con Pandoc 3.1.3.

EN EL ESCRITOR MARKDOWN, +smart APLANA Y ESCAPA

    d’Annunzio              ->  d'Annunzio
    —                       ->  ---
    – y …                   ->  -- y ...
    -- y ... tecleados      ->  \-- y \...

EN EL ESCRITOR MARKDOWN, -smart NO ESCAPA

Con `--to=markdown-smart`, el de `convertir_docx.sh`, cada carácter de un `Str` sale tal cual: un `--`, un `---` o un `...` que deja un filtro Lua no se escapa, tampoco al comienzo de un párrafo. Un `Str` que es solo «-» al comienzo de un párrafo sí sale escapado, `\-`, para que no se lea como lista.

EN EL LECTOR MARKDOWN, smart CONVIERTE

`--from markdown` tiene `smart` por omisión: `--` da U+2013, `---` U+2014 y `...` U+2026, también entre dígitos («10--20»).

DE PUNTA A PUNTA

Un .docx con U+2026, U+2013, U+2014, un guion aislado y un espacio duro delante de una semirraya, pasado por `convertir_docx.sh` con el filtro 1.2: sale `...`, `--` y `---`, y el guion aislado da `--`. El código en línea y la URL de un enlace conservan el carácter Unicode: no son `Str`.

**Relaciones:** vinculo:SC-40

### GV-80 — Pandoc: un carácter como • en el identificador de un Div deshace el bloque sin aviso

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor · **Verificado:** 2026-10

Un Div cuyo identificador lleva un carácter que Pandoc no admite en un id deja de ser un Div: la apertura y el cierre quedan como párrafos de texto, y el contenido suelto. Pandoc no avisa.

    ::: {.listado #lst-•}      →  Para [ ":::" "{.listado" "#lst-•}" ], el bloque suelto, Para [ ":::" ]
    ::: {.listado #lst-x}      →  Div ("lst-x", ["listado"])

REGLA

El marcador de los snippets (•, SC-21) no va en un identificador ni en una clase: un filtro ya no ve el bloque, y no puede frenar. Por eso el listado de código pide el nombre en un diálogo y deja el marcador en el pie (SC-42).

Medido con Pandoc 3.1.3 (`-t native`).

**Relaciones:** apoya:SC-42,vinculo:SC-21

### GV-81 — JATS 1.4: speech exige speaker y solo admite p; disp-quote admite speech

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** JATS Archiving y Publishing 1.4 / xmllint (libxml 2.9.14) / contenedor · **Verificado:** 2026-10

Modelo en `JATS-para1-4.ent`:

    speech   ((object-id)*, speaker, p+)
    speaker  (#PCDATA | person-name.class | simple-link.class)*

En el DTD Archiving (`JATS-archivecustom-models1-4.ent`) `speaker` admite además todo el marcado de frase; en el módulo base, que es el de Publishing, no.

`speech` está en `rest-of-para.class`, así que entra donde entra un párrafo, también dentro de `disp-quote`. `p` y `speech` tienen `content-type`.

MEDIDO CON xmllint CONTRA EL DTD ARCHIVING 1.4 DEL REPO

- `disp-quote content-type` con `p content-type`, varios `speech content-type` y un `speech` de dos párrafos: valida.
- `speech` sin `speaker` (lo que escribía cite-to-xref.lua con `speaker=""`): «expecting (object-id* , speaker , p+), got (p)».
- `speech` con una lista: «got (speaker list)».

MEDIDO CON xmllint CONTRA EL DTD PUBLISHING 1.4 OFICIAL (jats.nlm.nih.gov, octubre de 2024)

- La salida de cite-to-xref.lua para una conversación (un `disp-quote content-type="conversacion"` con acotaciones, cuatro `speech`, uno de dos párrafos, una nota y bastardilla): el cuerpo valida.
- `<speaker><italic>…</italic></speaker>`: «Element italic is not declared in speaker list of possible children». En Publishing, `speaker` va en texto plano.

**Relaciones:** apoya:SC-43

**PENDIENTE:** packtools (reglas de SciELO) en la máquina de Alberto.

### GV-82 — DocBook 5.2: qandaset está en la base, empareja, y el error de xmllint no orienta

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** DocBook 5.2 RNG / xmllint (libxml 2.9.14) / contenedor · **Verificado:** 2026-10

Modelo en `docbook.rng-5.2`:

    qandaset    info?, (bloques)*, (qandadiv+ | qandaentry+)
    qandaentry  info?, question, answer*
    question    label?, (bloques)+
    answer      label?, (bloques)+
    defaultlabel  none | number | qanda

MEDIDO CON xmllint --relaxng

- `qandaset defaultlabel="qanda"` con un `para` antes de las entradas, `question` y `answer` con `label`, dos `answer` en la misma entrada, varios párrafos y una lista en un `answer`: valida, suelto en el capítulo y dentro de `blockquote`.
- `qandaentry` sin `question` (una respuesta sin pregunta): no valida.
- `para` entre dos `qandaentry`: no valida.

En los dos casos xmllint informa «Expecting element formalgroup, got chapter», sobre el capítulo y no sobre el elemento culpable. Quien escribe el XML tiene que frenar antes, con su propio mensaje.

**Relaciones:** apoya:SC-43,vinculo:RC-DB-04

### GV-83 — Pandoc: conversación anidada con ::: y anclas; los corchetes sueltos quedan como texto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor · **Verificado:** 2026-10

Medido con Pandoc 3.1.3 (`-t native`).

- `::: conversacion` con turnos `::: {.pregunta quien="…"}`, `::: respuesta` y `::: acotacion` adentro, todos con `:::` y su ancla (SC-33): un `Div` contenedor con los turnos como `Div` hijos, cada uno con su clase y sus atributos; una respuesta de dos párrafos da dos `Para`.
- `[risas]` en medio de un párrafo, sin referencia que lo defina: `Str "[risas],"`, con los corchetes.
- `[Risas]{.acotacion}`: un `Span` cuyo texto es «Risas», sin corchetes.

**Relaciones:** apoya:SC-43,vinculo:SC-33

### GV-84 — Pandoc: en una sola tabla de filtro, Meta corre después de Div

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor · **Verificado:** 2026-10

Un filtro Lua que define `Meta` y `Div` como funciones globales, en una sola tabla, recorre los bloques antes que los metadatos: dentro de `Div` el valor que guarda `Meta` todavía no existe.

Si el filtro devuelve una LISTA de tablas, Pandoc las aplica en orden, y la primera puede leer los metadatos antes de que la segunda vea los bloques:

    local idioma = nil
    return {
      { Meta = function (m) idioma = m.lang and pandoc.utils.stringify(m.lang) or nil end },
      { Div  = function (el) … usa idioma … end }
    }

MEDIDO CON Pandoc 3.1.3 (`-t jats`, `-M lang=…`)

- Lista de dos tablas: con `-M lang=en`, `Div` ve «en»; con `es`, «es»; sin `-M`, `nil`.
- Una sola tabla, `Meta` y `Div` globales, con `-M lang=en`: `Div` ve el valor inicial de la variable, sin leer.

Caso del proyecto: la etiqueta por omisión de la conversación en revistas (SC-43).

**Relaciones:** apoya:SC-43

### GV-85 — Pandoc: walk de arriba hacia abajo; «return el, false» no entra en los hijos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor · **Verificado:** 2026-10

Por omisión `doc:walk` recorre de abajo hacia arriba: una función `Div` ve los Div de adentro antes que el que los contiene, y no sabe dentro de qué está cada uno.

Con `traverse = 'topdown'` en la tabla de filtro, el recorrido va de arriba hacia abajo, y una función que devuelve el elemento y `false` deja sin recorrer sus hijos:

    doc:walk({ traverse = 'topdown', Div = function (el)
      if el.classes:includes('conversacion') then return el, false end
      …
    end })

MEDIDO CON Pandoc 3.1.3

Un `::: conversacion` con un `::: pregunta` adentro, y un `::: respuesta` suelto después: la función ve «conversacion» y «respuesta». La pregunta de adentro no pasa.

Caso del proyecto: `conversacion.lua` encuentra así los turnos sueltos, fuera de una conversación (SC-43).

**Relaciones:** apoya:SC-43

### GV-86 — Lua: una función que termina en gsub devuelve dos valores, y un constructor de tabla toma los dos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 (Lua 5.4) / contenedor · **Verificado:** 2026-10

`string.gsub` devuelve la cadena y la cantidad de reemplazos. Una función que termina en `return s:gsub(…)` devuelve también los dos. En una asignación simple sobra el segundo y no se nota; como último elemento de un constructor de tabla o de una lista de argumentos, entran los dos.

    local t = { blocks_a_docbook(bloques) }      -- { "<para>…</para>", 0 }
    local t = { (blocks_a_docbook(bloques)) }    -- { "<para>…</para>" }

Los paréntesis reducen el resultado a un solo valor.

MEDIDO CON Pandoc 3.1.3

En `fenced-divs-to-elements-db.lua`, `blocks_a_docbook` e `inlines_a_docbook` terminan en `gsub`. Usado sin paréntesis dentro de `{ }`, el `table.concat` de la conversación escribió un «0» suelto después de cada turno en el DocBook. Con paréntesis, nada.

Caso del proyecto: la serialización de la conversación (SC-43).

**Relaciones:** apoya:SC-43

### GV-87 — Pandoc: pandoc.utils.references solo devuelve las entradas citadas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Con `--bibliography`, un filtro Lua puede leer las entradas del `.bib` con `pandoc.utils.references(doc)`: cada una trae `id` y, si tiene fecha, `issued`. No hace falta citeproc ni un lector de BibTeX propio.

PERO DEVUELVE SOLO LAS CITADAS. Con un `.bib` de tres entradas y dos citadas en el documento, devuelve dos. Para obtenerlas todas, el documento tiene que llevar `nocite` con `@*`:

    ---
    nocite: |
      @*
    ---

Ese YAML tiene que ir EN UN ARCHIVO de entrada. Pasado como `-M nocite='@*'` (o `--metadata`) NO funciona: llega como texto y no como cita, y la función sigue devolviendo solo las citadas.

El lector toma el formato por la extensión: `.bib` se lee como biblatex.

Forma de la fecha, medida:

- `date={2020}` y `year={2019}` dan `issued["date-parts"][1][1]` = el año.
- `date={2018/2020}` da DOS fechas en `date-parts`: la primera es el comienzo del rango.
- Sin `date` ni `year`, y con `year={s.f.}`, no hay `date-parts`: el año queda vacío.

Lo usa el análisis del proyecto (SC-46) para cruzar las claves citadas con el `.bib` y detectar las entradas sin citar.

**Relaciones:** apoya:SC-46

### GV-88 — Lua: los patrones no reconocen letras fuera de ASCII

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / Lua 5.4 (pandoc lua) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El Lua de Pandoc es Lua 5.4 (`_VERSION`). Sus patrones trabajan por BYTES: las clases `%a`, `%w` y `%p` solo conocen ASCII. Medido:

    ("análisis"):match("^%a+$")   ->  nil
    ("año"):find("%w+")           ->  1  1      (solo la «a»)
    #"análisis"                   ->  13        (bytes)
    utf8.len("análisis")          ->  9         (caracteres)

La biblioteca `utf8` SÍ está disponible: `utf8.len` cuenta caracteres y `utf8.codes` recorre por punto de código. Para clasificar un carácter fuera de ASCII hay que hacerlo a mano sobre el punto de código.

Es el mismo problema que llevó a descartar `gb.pcre` (SC-05). En un filtro, lo que exija reconocer letras en castellano —palabras, frecuencias, repeticiones— no se resuelve con patrones de Lua: va a perl con `-CSD`.

`engine/analizar_proyecto.lua` decide si un `Str` es palabra recorriendo `utf8.codes` y tratando como puntuación el ASCII no alfanumérico, ¡ « · » ¿, el espacio duro y el bloque U+2000–U+206F.

**Relaciones:** vinculo:SC-05,apoya:SC-46

### GV-89 — Pandoc: el texto de un Cite, una nota o el alt de una imagen también son Str

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Contar todos los `Str` del documento con el recorrido por defecto (`typewise`) no da las palabras del texto. En un párrafo de unas veinte palabras dio 32. Entran:

- el texto crudo de cada cita: `[@perez2020; @gomez2019, p. 3]` deja `Str "[@perez2020;"`, `Str "@gomez2019,"`… dentro del `Cite`;
- el contenido de las notas al pie (`Note`), que es otro texto;
- el texto alternativo de la imagen de una figura: en Pandoc 3, `![Pie](x.png)` solo en su párrafo da un `Figure` cuyo `caption` y cuyo `Image` interior traen EL MISMO texto.

Para contar hay que recorrer el árbol a mano o con `topdown` (GV-85) y cortar en `Cite` e `Image`, y medir `Note` aparte.

Cómo parte el texto el lector, medido:

- Un `Str` es lo que va entre espacios. La puntuación queda pegada: `Str "«claro»."`.
- «socio-económico» es UN `Str`; la raya de inciso pegada también: `Str "—según"`.
- El espacio duro une: `p.~3` da `Str "p.\160\&3"`.
- El YAML del encabezado va a `meta`, no a `blocks`.
- Una lista compacta da `Plain`, no `Para`.

El documento se manda a `--output /dev/null`, así en stdout queda solo lo que escribe el filtro con `io.write`, NUL incluidos.

**Relaciones:** vinculo:GV-85,apoya:SC-46

### GV-90 — perl-base no trae PerlIO ni Encode: :encoding(UTF-8) necesita el paquete perl

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Perl 5.38 / Linux Mint (base Ubuntu 24.04) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

SC-05 afirmaba que alcanzaba con `perl-base`, que es Essential. No es así para los scripts del proyecto: abren los archivos con `:encoding(UTF-8)`, y ese layer necesita `PerlIO` y `Encode`, que `perl-base` NO trae.

Medido limitando `@INC` a la carpeta de `perl-base`:

    Can't locate PerlIO.pm in @INC (you may need to install the PerlIO module)

Falla igual `buscar_regex.pl` (modo `probar`) que `analizar_lexico.pl`. Con `perl` completo, los dos andan.

De qué paquete viene cada módulo, medido en la máquina del editor (Linux Mint, base Ubuntu 24.04, Perl 5.38):

    PerlIO.pm            perl-modules-5.38
    PerlIO/encoding.pm   libperl5.38t64
    Encode.pm            libperl5.38t64 (y también libencode-perl, si está)

El paquete `perl` depende de `perl-base`, `perl-modules-5.38` y `libperl5.38t64`.

`libencode-perl` es una versión más nueva de Encode que se distribuye aparte y que instala como dependencia algún otro programa. Si está, perl la prefiere, porque su carpeta va antes en `@INC`; si no está, usa la de `libperl5.38t64`, que también trae `Encode.pm` (verificado con `dpkg -L`). No hace falta declararla.

CONSECUENCIA: en el `.deb`, `Depends: perl`, SIN versión. Los paquetes de los módulos llevan la versión de Perl en el nombre y cambian de una versión de Mint a otra; `perl` es el nombre estable que trae los que correspondan. En `IntegridadSistema` se verifica el PAQUETE `perl` (`DEP_PAQUETE`), no el comando: el binario `perl` lo trae también `perl-base` y la verificación daría verde sin servir.

**Relaciones:** vinculo:SC-05,apoya:SC-47

### GV-91 — Pandoc: la extensión sourcepos no existe para el lector markdown

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

La extensión `sourcepos`, que anota en el AST la posición de cada elemento en el archivo fuente, NO está disponible para el lector `markdown` de Pandoc, que es el que usa gbpublisher. Medido:

    pandoc -f markdown+sourcepos ...
    The extension sourcepos is not supported for markdown

    pandoc --list-extensions=markdown | grep sourcepos    -> -sourcepos  (no se puede activar)
    pandoc --list-extensions=commonmark | grep sourcepos  -> -sourcepos  (existe, desactivada)

Existe para la familia CommonMark, pero cambiar de lector para obtenerla cambiaría el parseo de todo el proyecto.

CONSECUENCIA: lo que se calcula sobre el AST (SC-46, SC-47) no puede decir en qué línea del `.md` está. Para llevar al usuario al lugar, se busca en el texto (SC-48).

**Relaciones:** apoya:SC-48

### GV-92 — Pandoc: un bloque entre las llaves de un bloque de dos partes pide líneas en blanco alrededor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Un bloque cercado (`:::`) dentro de las llaves de un epígrafe (SC-35) solo se lee como bloque si tiene una línea en blanco antes y después, y la llave de apertura y la de cierre van en su propio párrafo.

MEDIDO CON Pandoc 3.1.3

Con las líneas en blanco:

    ::: epigraph

    {

    ::: {.verse patron="01"}

    Versos…

    [/verse]: # ()
    :::

    }{Atribución}

    [/epigraph]: # ()
    :::

da `Div epigraph [ Para "{", Div verse […], Para "}{Atribución}" ]`: el verso es un bloque, con su atributo, y las dos anclas desaparecen del árbol.

Sin ellas (`{` pegado a `::: {.verse …}`, y `:::` pegado a `}{…}`):

- `::: {.verse patron="0101"}` queda como texto del párrafo de la llave;
- el `:::` del verso cierra el epígrafe;
- el cierre del epígrafe queda suelto, como un párrafo «:::».

No pasa en silencio: la llave de cierre quedó fuera del bloque y `dos-partes.lua` frena con «hay una llave de apertura sin cerrar».

Es la misma regla que SC-33 (la línea en blanco antes del ancla es obligatoria), aplicada a un bloque dentro de las llaves.

**Relaciones:** apoya:SC-49,vinculo:SC-35,vinculo:SC-33

### GV-93 — verse: \\ lee el carácter que sigue; un verso que empieza con [, * o ! se rompe

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX / TeX Live 2023 / verse 2.4a / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Dentro del entorno `verse` del paquete `verse`, `\\` mira el carácter siguiente para decidir su forma: `\\!` (fin de estrofa), `\\*` (sin corte de página), `\\>` (verso partido) y `\\[…]` (espacio extra). El salto de línea del archivo no lo impide: `\@ifnextchar` saltea los espacios.

MEDIDO (verse 2.4a, LuaLaTeX), con el verso anterior terminado en `\\`:

    [sic] dos     ! Missing number, treated as zero / Illegal unit of measure;
                  sale «sicdos»: lo que estaba entre corchetes se perdió
    *seis         sin error: el asterisco se pierde (lo tomó como \\*)
    !el camino    sin error: el signo se pierde y se abre una estrofa nueva

Los dos últimos son pérdidas silenciosas.

REGLA: cada verso empieza con `\relax` (`\relax[sic] dos`, `\relax\vin seis`). `\@ifnextchar` ve `\relax`, no el texto, y `\relax` no hace nada. Medido: los tres casos salen bien. Lo escriben `docbook-to-latex.xsl` y `jats-to-latex.xsl` (SC-49).

**Relaciones:** apoya:SC-49

### GV-94 — verse dentro de \gbepigrafe: el margen y el \topsep se quitan redefiniendo \@listi

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX / TeX Live 2023 / verse 2.4a / poppler 24.02 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

`verse` es una lista: toma el margen de `\leftmargini` y deja `\topsep` antes y después. Dentro de la minipágina de `\gbepigrafe` (SC-35) el verso tiene que alinearse con el bloque y quedar a la misma distancia del filete que un epígrafe en prosa.

MEDIDO (verse 2.4a, LuaLaTeX, coordenadas con pdftotext -bbox):

- `verse` sin cambios: arriba bien (al comienzo de una minipágina LaTeX no pone el `\topsep`); abajo, el `\topsep` separa el último verso del filete más que en prosa.
- `\vspace{-\topsep}` antes y después: abajo, el último verso queda 2 pt más cerca del filete que en prosa; arriba, el bloque sube sobre el texto anterior. Descartado.
- `\@listi` redefinido local al entorno, con `\leftmargin`, `\topsep`, `\partopsep`, `\itemsep` y `\parsep` en cero: del cuerpo al primer verso, 2,22 pt, igual que en prosa; del último verso a la atribución, 2,11 pt, igual que en prosa.

POR QUÉ \@listi: `\list` la ejecuta al abrir, antes de las declaraciones de `verse`. `verse` suma `\vindent` al margen y pone después `\parsep` = `\stanzaskip`, así que el espacio entre estrofas se conserva.

`\setlength{\leftmargini}{…}` antes de `\begin{verse}` también funciona para el margen (medido: 14 pt en revistas, `gbverso`), pero no toca el `\topsep`.

Aplicado en `gbversoepigrafe` (preambulo-contrato.tex, contrato 14, y su gemelo en m_XML).

**Relaciones:** apoya:SC-49,vinculo:SC-35

### GV-95 — Pandoc: el escritor DocBook sangra las líneas de un RawBlock según la profundidad de la sección

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Un `RawBlock` que devuelve un filtro no sale tal cual en el DocBook: el escritor de Pandoc lo mete en la sangría de la sección que lo contiene, dos espacios por nivel, en CADA línea del texto crudo menos la primera. `--wrap=none` no lo cambia: es la sangría del documento, no el corte de línea.

MEDIDO CON Pandoc 3.1.3, un verso con dos espacios delante del segundo verso:

    sin título antes (sin <section>):
    <literallayout role="verse"><phrase role="linea">Uno</phrase>
      <phrase role="linea">dos</phrase>

    después de un ## (dentro de una <section>):
      <literallayout role="verse"><phrase role="linea">Uno</phrase>
        <phrase role="linea">dos</phrase>

El segundo verso pasó de dos espacios a cuatro: en un `<literallayout>`, donde el espacio es contenido, la sangría del documento se suma a la del texto.

En un elemento donde el espacio no es contenido no importa. Donde sí lo es, el salto va como la referencia `&#10;`: el texto crudo queda en una sola línea, el escritor no tiene dónde sangrar, y el parser XML convierte la referencia en el salto. Medido: con `&#10;`, los espacios quedan iguales con y sin sección.

Caso del proyecto: `fenced-divs-to-elements-db.lua` (6.5) escribe así el verso (SC-49).

**Relaciones:** apoya:SC-49,vinculo:RC-DB-04

### GV-96 — Val y Str dependen del locale; CFloat y CStr no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbs3 / contenedor Ubuntu 24.04 / locales C.UTF-8 y es_AR.UTF-8 · **Verificado:** 2026-10

`Val` y `Str` usan el separador decimal y el de miles del locale. `CFloat` y `CStr` usan siempre el punto. Con `es_AR.UTF-8`, el locale de Mint en la editorial, la diferencia rompe la lectura de números escritos con punto.

MEDIDO (Gambas 3.19, contenedor)

    entrada          C.UTF-8          es_AR.UTF-8
    Val("15.5")      15.5             Null
    Val("15,5")      Null             15.5
    Val("1.234")     1.234            1234 (Integer)
    Val("")          Null             Null
    CFloat("15.5")   15.5             15.5
    CFloat("15,5")   Type mismatch    Type mismatch
    CFloat("")       Type mismatch    Type mismatch
    Str(15.5)        "15.5"           "15,5"
    CStr(15.5)       "15.5"           "15.5"

Las tres trampas:

- Asignar el Null de `Val` a un Float lanza «Type mismatch: wanted Float, got Null instead». El error aparece en la asignación, no en `Val`.
- `Val("1.234")` con `es_AR` devuelve 1234 sin error: el punto se lee como separador de miles. Es el peor caso, porque el número es válido y está mal.
- Lo que funciona en la máquina del desarrollador con un locale falla en otra con el otro: la misma dependencia del entorno que GV-03.

CASO QUE LO DESCUBRIÓ

`FSysAdmin.LeerNumero` normalizaba la coma a punto y llamaba a `Val`, con un comentario que lo creía locale-independiente. En Mint, guardar un formato PDF nuevo con decimales fallaba siempre; con un campo vacío, en cualquier locale.

REGLA

Para leer un número que escribe una persona: normalizar la coma a punto, descartar el vacío y convertir con `CFloat` dentro de un `Try`, con `If Error Then` inmediatamente después (RC-GM-02). Para escribir un número en un archivo, una consulta o un parámetro: `CStr`, no `Str`. `Str` y `Val` solo para mostrar o leer en el formato del usuario, sabiendo que dependen del locale.

`Str` al mostrar y `CFloat` al leer, después de normalizar la coma, son compatibles: el formulario muestra «15,5» y lo vuelve a leer como 15.5.

**Relaciones:** vinculo:GV-03,vinculo:RC-GM-02

**PENDIENTE:** Repetir el mini-test en Mint con Gambas 3.22.2 y el locale real. Revisar los demás Val sobre texto de usuario: m_Metadatos (numero_paginas, numero_figuras, numero_tablas, numero_ecuaciones, copyright_year) y FAutores (h_index, i10_index, numero_publicaciones) son enteros, pero «1.234» da 1234.

### GV-97 — Dialog.SaveFile con gb.form.dialog: la pregunta de sobrescritura la hace gb.form

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.form.dialog (FFileDialog.class) y gb.form (FDirChooser.class), etiquetas 3.19.0 y 3.22.1; medido en Gambas 3.19 / gb.qt5 con xvfb / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Con `gb.form.dialog` cargado —lo está en gbpublisher—, la clase `Dialog` es la del componente, escrita en Gambas (`Class.Load("Dialog").Component.Name` da `gb.form.dialog`, medido). `SaveFile` abre `FFileDialog`, que usa el `FileChooser` de `gb.form`.

LA PREGUNTA EXISTE, Y LA HACE gb.form

`FDirChooser.CheckFile` pregunta antes de aceptar un archivo existente: «This file already exists. Do you want to overwrite it?», con Overwrite y Cancel. Cancel deja el diálogo abierto. Leído en el fuente (etiqueta 3.22.1) y medido bajo xvfb: aparece con el nombre escrito tal cual y también con «Extensión automática», porque el campo ya muestra la extensión del filtro.

En `FFileDialog.fchChoose_Activate` hay otra copia del mismo control, COMENTADA (en 3.19.0, en 3.22.1 y en la rama principal). No significa que falte la pregunta: es un resto, y la que vale es la de `FDirChooser`.

CONSECUENCIAS

- No repetir la pregunta en el código después de `SaveFile`: saldría dos veces.
- Sí preguntar si el código cambia la ruta después del diálogo, por ejemplo al agregar una extensión que faltaba: esa ruta el diálogo no la vio.
- `SaveFile` y `OpenFile` devuelven True al cancelar (`Return Not Me.ShowModal()`), la misma convención que `SelectDirectory` (GV-16).

Caso del proyecto: `m_BuscarRegex.CompartirPatron` (SC-51).

**Relaciones:** vinculo:GV-16,vinculo:RC-GM-19,vinculo:SC-51

### GV-98 — JSON.Decode: las listas llegan como Variant[] y un null no crea la clave

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gbs3 / gb.util.web / Linux Mint (mini-test json-patrones.gbs); antes, Gambas 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Cómo entrega `JSON.Decode` (gb.util.web) lo que lee, medido:

    objeto JSON              Collection
    lista JSON               Variant[] (Object.Type), no Collection[]
    elemento objeto          Collection
    entero                   Integer (TypeOf = gb.Integer)
    null                     la clave NO se crea (Exist da False)
    raíz que es una lista    asignarla a una Collection falla: Type mismatch
    JSON mal formado         error («Incorrect token», «String expected»)

Asignar el `Variant[]` a una variable `Collection[]` no da error (lo hace `m_Json.ImportarJSON`), pero para controlar un JSON ajeno conviene mirar `TypeOf` y `Object.Type` de cada valor antes de usarlo, en `If` separados: `Object.Type` sobre algo que no es objeto da error (RC-GM-17).

`JSON.Encode` de un texto devuelve el literal JSON con sus escapes. La ida y vuelta conserva barras invertidas, comillas, tabulador, salto de línea, NBSP, `ñ`, `«»` y el carácter 0x1F, con la misma cantidad de caracteres. Codificar valor por valor permite escribir a mano un JSON con sangría.

Lo mismo que GV-68 para una clave con cadena vacía: al armar una `Collection` para `JSON.Encode`, una clave con "" no se crea y no sale en el JSON.

Caso del proyecto: `m_PatronesRegex` (SC-51).

**Relaciones:** vinculo:GV-68,vinculo:RC-GM-17,vinculo:SC-51

### GV-99 — Pandoc 3.1.3: las notas mal armadas pasan sin error y la mayoría sin aviso

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04; el caso de la llamada suelta, en Linux Mint con un libro real · **Verificado:** 2026-10

Medido con Pandoc 3.1.3, lector markdown, sin filtros:

    en el .md                              resultado                                ¿avisa?
    [^3] sin definición                    texto literal «[^3]»; no hay nota         no
    [^3]: sin contenido, al final          Note [] — una nota vacía                  no
    [^3]: vacía y debajo un párrafo        el párrafo pasa a ser el contenido de     no
                                           la nota y desaparece del texto
    [^2]: definida y nunca llamada         la nota se descarta                       sí, [WARNING]

El tercer caso es el grave: un párrafo se pierde sin ningún mensaje. En el AST ya no queda rastro (`Para "Antes."`, `Para "Después."` y nada entre los dos), así que solo se detecta sobre el texto fuente.

La llamada suelta llega como parte de un `Str` (`Str "Texto.[^3]"`): se puede buscar en el AST, y los bloques de código, que no tienen `Str`, quedan fuera solos.

El `[WARNING]` de la nota sin llamar lo emite el lector: sale igual en cualquier pasada sobre el mismo archivo, con o sin filtros.

Es el equivalente de `\footnote{}` en LaTeX, que compila sin error y deja la marca al pie vacía; según Alberto, no hay forma de hacer que el compilador falle con eso.

**Relaciones:** apoya:SC-54,vinculo:SC-46

### GV-100 — Application.Busy en gb.qt5: cursor de espera global, y Message lo suspende solo

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Código fuente de Gambas 3.22.1 (gb.qt4/src/CScreen.cpp, enlazado por gb.qt5; comp/src/gb.gui.base/.src/Message/FMessage.class) · **Verificado:** 2026-10

Leído en el código fuente de Gambas 3.22.1.

`Application.Busy` lo implementa `APPLICATION_set_busy` en `gb.qt4/src/CScreen.cpp`, que `gb.qt5` enlaza:

    al pasar de 0 a más de 0    qApp->setOverrideCursor(Qt::WaitCursor)
    al volver a 0               qApp->restoreOverrideCursor()
    un valor negativo           se toma como 0

Es un cursor de anulación de Qt: vale para todas las ventanas y queda puesto hasta que se restaura, aunque el bucle de eventos siga corriendo (`Wait`). Lo que cuenta es el paso por cero, así que `Inc` / `Dec` anidan bien y `= 1` pisaría a otro que ya lo tuviera en uso.

`Message` (`comp/src/gb.gui.base/.src/Message/FMessage.class`) guarda `Application.Busy`, lo pone en 0 mientras muestra el diálogo y lo restaura al cerrarlo: el cuadro aparece con el puntero normal sin que el llamador haga nada.

En el proyecto ya se usaba alrededor de bloques que no ceden el control (FEstadisticas, m_Estructura, CVisorResaltado); en la lanzadora se usa por primera vez durante una espera con `Wait` (SC-53).

**Relaciones:** apoya:SC-53,vinculo:GV-17

**PENDIENTE:** Confirmar en Mint, con la lanzadora, que el puntero queda ocupado durante toda la espera y vuelve al terminar, y que la pregunta del plazo aparece con el puntero normal. Hecho eso, pasar la evidencia a empirica y quitar este pendiente.

### GV-101 — hyperxmp 5.12: corta pdfauthor en las comas, quita Author y Keywords de Info, keeppdfinfo es clave de \hypersetup

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX / TeX Live 2023 (Debian) / hyperxmp 5.12 / exiftool 12.76 / poppler 24.02 / Linux Mint · **Verificado:** 2026-10

Medido con exiftool sobre l-CALIFA.pdf y leído en hyperxmp.sty v5.12 (2023/09/10) y en el manual v5.13.

1. LA COMA SEPARA AUTORES. El manual: «hyperxmp splits the pdfauthor and pdfkeywords lists at commas». Cada elemento es un `dc:creator`. Con la forma invertida «Califa, Juan Sebastián; Millán, Mariano», el XMP salió:

    ["Califa", "Juan Sebastián; Millán", "Mariano"]

Con la forma directa separada por comas, «Juan Sebastián Califa, Mariano Millán», salió `["Juan Sebastián Califa","Mariano Millán"]`. Para una coma literal el manual da `\xmpquote{…\xmpcomma…}`; en gbpublisher no sirve porque `EscaparTeX` escapa la cadena entera, y `ObtenerAutoresLibro` quita la coma del dato.

2. Author Y Keywords NO VAN A Info. Desde la v5.0 hyperxmp los quita del diccionario Info y los deja solo en el XMP. Medido: `pdfinfo` no mostraba Author. Los vuelve a poner `keeppdfinfo`.

3. keeppdfinfo ES CLAVE DE \hypersetup, NO OPCIÓN DEL PAQUETE. El .sty la define con `\define@key{Hyp}{keeppdfinfo}[true]`. Como opción de `\usepackage` la compilación frena:

    ! LaTeX Error: Unknown option `keeppdfinfo' for package `hyperxmp'.

La supresión corre en `\AtEndPreamble` (línea 427), así que `\hypersetup{keeppdfinfo}` en cualquier lugar del preámbulo, después de cargar el paquete, alcanza.

4. dc:source ES \jobname.tex. Por eso decía `main.tex`. Con `pdfsource={}` no se emite: el .sty lo salta con `\ifx\@pdfsource\@empty`. Medido: ausente.

5. pdfcreator LLEGA A LOS DOS LUGARES. El manual no lo enumera entre las claves que lee, pero medido: `pdfcreator={gbpublisher \gbversion}` da el mismo valor en Info Creator y en `xmp:CreatorTool`. Producer queda en el motor (LuaHBTeX y TeX Live).

6. prism:byteCount ES FALSO CON LuaLaTeX. Medido: 2421 en un archivo de 690 755 bytes. El manual lo advierte: con LuaLaTeX toma el tamaño de la compilación anterior, y lo corrige un script aparte (`hyperxmp-add-bytecount`).

CÓMO VERIFICARLO: exiftool sin `-j` une los elementos de una lista con «, », y una lista de dos autores se ve igual que un autor con una coma. Para contar elementos: `exiftool -j -XMP-dc:Creator`.

Aplicado en la sección 2 de `preambulo-hyperref.tex` y en `ObtenerAutoresLibro` (m_GenerarPDFLibro).

**PENDIENTE:** Medir pdfisbn (prism:isbn) y pdfdoi (prism:doi) cuando un libro tenga ISBN electrónico y DOI cargados, incluido un DOI con guion bajo: \gbdoi pasa por EscaparTeX. Decidir qué hacer con prism:byteCount (avisar en el validador o no emitirlo). Hecho eso, quitar este pendiente.

### GV-102 — biblatex: refsection=chapter con bibliografía consolidada deja solo el último capítulo, sin aviso

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 (2023/03/05) / biber 2.19 / biblatex-philosophy v1.9.8g / LuaLaTeX, TeX Live 2023 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

La opción de carga `refsection=chapter` abre una sección bibliográfica nueva en cada `\chapter`. Un `\printbibliography` al final del libro imprime solo la sección en curso, que es la del último capítulo.

Medido con `cita-verona-modern-config.tex` y dos capítulos, una cita en cada uno (Falco en el 1, Amelang en el 2):

    modo                                       sin la opción          con refsection=chapter
    por capítulo, como lo arma la aplicación   Falco / Amelang        igual
    consolidada, \printbibliography final      Amelang y Falco        solo Amelang

En la consolidada se pierden las referencias de todos los capítulos menos el último. No hay error y el log no trae ningún «biblatex Warning». Es la versión biblatex de GV-23: compila y da un libro equivocado.

En el modo por capítulo la opción no cambia nada, porque ya lo resuelve el generador. `docbook-to-latex.xsl` envuelve en `\begin{refsection}`…`\end{refsection}` cada pieza que trae `<bibliography>`. El canónico la trae solo cuando `libros_md.lugar_bibliografia` es `por_capitulo`.

CONSECUENCIA: la bibliografía por capítulo la arma el generador, nunca una opción del estilo. Las configuraciones de `.hidden/latex/` no llevan `refsection=chapter`, ni siquiera comentada: comentada, invita a activarla. Decisión de Alberto.

Para tex4ht (SC-56): el documento mínimo que genere `docbook-to-latex.xsl` tiene los mismos `refsection` que el PDF. Los id de tex4ht llevan el número de sección: `cite.0@clave`, `cite.1@clave`.

**Relaciones:** vinculo:SC-55,vinculo:RF-12,apoya:GV-23,vinculo:SC-57

### GV-103 — Gambas Like: la clase negada es [^…]; [!…] no niega

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 (gbs3) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

En un patrón de `Like`, la clase de caracteres negada se escribe con circunflejo: `[^a-z]`. La forma con signo de exclamación, `[!a-z]`, que es la del glob de bash y la de Visual Basic, NO niega: Gambas la lee como una clase que contiene el propio `!` y el rango.

MEDIDO con `gbs3`:

    "abc"  Like "*[!a-z]*"    True     (cualquier letra entra en la clase)
    "abc"  Like "*[^a-z]*"    False
    "a/b"  Like "*[^a-z]*"    True

El error no da aviso: el patrón compila y responde, con el resultado contrario al esperado. Un control de forma escrito con `[!…]` deja pasar todo. Así pasaba en el primer borrador de `m_GenerarSalidasLibro.EstiloLibroExiste`, que tiene que rechazar un identificador con `/` o `..` antes de armar una ruta: con `[!a-z0-9-]` aceptaba `a/b` y `../x`.

REGLA: en `Like`, la negación va con `[^…]`. Si la línea existe por esta entrada, citarla.

Es otra de las diferencias con Visual Basic que rompen código (CONTEXTO, punto 4).

**Relaciones:** vinculo:SC-57,apoya:GV-23

**PENDIENTE:** Medido en Gambas 3.19. Repetir en Mint con la versión instalada, con este script de gbs3: Print "abc" Like "*[!a-z]*", "abc" Like "*[^a-z]*" — tiene que dar True y False.

### GV-104 — IBM Plex Sans no trae smcp ni c2sc; Noto Serif sí

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** fontTools 4.65 / fuentes de gbpublisher (.hidden/fonts) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Las versalitas de la bibliografía de Verona en HTML y EPUB las pone el CSS con `font-variant-caps: all-small-caps`, que usa los rasgos OpenType `smcp` y `c2sc` (SC-56). Sin ellos el navegador fabrica versalitas falsas achicando mayúsculas.

MEDIDO con fontTools sobre las fuentes de `.hidden/fonts/` (tabla GSUB):

    IBMPlexSans-Regular.otf    sin smcp, sin c2sc
    NotoSerif-Regular.ttf      smcp y c2sc

CONSECUENCIA PARA EL EPUB: el libro embebe Noto Serif (`@font-face` de `gbpublisher-epub-libro.css`). Cumple la regla de SC-56.

CONSECUENCIA PARA EL HTML: el panel de referencias (`.ref-item`) se compone con `--font-sans`, que es IBM Plex Sans, y `gbpublisher.css` no embebe fuentes: usa las que tenga instaladas el lector. Con Plex, las versalitas del panel son falsas. Con la serif tampoco hay garantía, porque Noto Serif no se embebe y el respaldo es Georgia.

DECISIÓN DE ALBERTO: las referencias del HTML van en Noto Serif, la tipografía del texto (`.ref-item.ref-biblatex` con `--font-serif`). Vale lo mismo que para el texto: la fuente no se embebe y la toma del sistema del lector.

**Relaciones:** vinculo:SC-56,vinculo:SC-57

### GV-105 — biblatex-iso690 con autolang=other: \sptext indefinido en una entrada que no es del idioma del libro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biblatex-iso690 (TeX Live 2023) / babel-spanish 5.0q / LuaLaTeX / contenedor Ubuntu 24.04; PDF de Duek en Mint · **Verificado:** 2026-10

`iso.bbx` trae `autolang=other`: cada entrada se compone en el idioma de su `langid`. En un libro en español con babel cargado solo con el español (`\gbidiomas`), una entrada `english` con número de revista corta el PDF:

    ! Undefined control sequence.
    \abx@sstr@number ->n\sptext {o}

Al entrar en la entrada, babel apaga los extras del español, y con ellos `\sptext`. La cadena que imprime biblatex para «número» sigue siendo la española, `n\sptext{o}`.

MEDIDO con `ref-l-DUEK.bib`, compilando entrada por entrada: fallan las dos en inglés que llevan `number` (4203-SMITH2007, 4205-HEID2021); la portuguesa, que no lo lleva, no falla. APA y Verona no fallan porque no activan `autolang`.

Cargar `english` en babel tampoco sirve: la entrada sale mezclada, con «no. 1» en inglés y «págs.» y «Disp. desde» en español.

DECISIÓN DE ALBERTO: `autolang=hyphen` en `cita-iso690-config.tex`, como opción de carga (le gana al valor del estilo; medido). Las cadenas van en el idioma del libro y solo el corte de palabras sigue al de la entrada, como en APA y Verona. El PDF de Duek compiló sin errores ni avisos de biblatex.

**Relaciones:** vinculo:SC-57,vinculo:SC-58,apoya:GV-23

### GV-106 — biblatex: una cadena sin traducción sale en negrita; un editortype, un type o un pubstate sin cadena, tal cual

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biblatex-ieee v1.3f / biblatex-iso690 v0.4.1 / biblatex-philosophy / LuaLaTeX / contenedor Ubuntu 24.04; PDF de Duek en Mint · **Verificado:** 2026-10

Dos comportamientos distintos de biblatex ante una cadena que falta en el idioma del libro:

1. Una cadena DECLARADA (`\NewBibliographyString`) y sin definir en ese idioma: biblatex imprime la clave en negrita y avisa en el `.log` («Package biblatex Warning: Bibliography string 'presentedat' untranslated»). MEDIDO en el PDF de Duek con IEEE: «presentedatX Congreso…». Bajo tex4ht la negrita llega como `<span class="ec-lmbx-10">`, que no está en la lista cerrada de `cita-fragmentos.xsl`: la hoja corta (SC-57, GV-23).

2. El valor de `editortype`, `type` o `pubstate` que no es una cadena DECLARADA: biblatex imprime el código tal cual y no avisa. MEDIDO con IEEE: «J. Marcus, coordinator», «C. Kaplan, direction», «Tesis…» como «gradothesis»; con ISO 690, los catorce tipos de tesis del catálogo que su configuración no tenía; con Verona e IEEE, «self-published».

El segundo es el peligroso: no hay aviso, y el PDF sale. Por eso los códigos del catálogo de la aplicación tienen su cadena en un archivo común a todos los estilos (SC-59).

`\NewBibliographyString` con una cadena que ya existe no hace nada; una clave con guion (`self-published`) es válida (medido).

**Relaciones:** vinculo:SC-59,vinculo:SC-57,vinculo:RF-14,apoya:GV-23

### GV-107 — TextEdit.InsertRichText: fusiona el fragmento con el párrafo del cursor y no aplica el <style> del documento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu 24.04 (Xvfb, Fusion), banco gbPruebaChat; el mismo banco corrido por Alberto en Gambas 3.22.2 / Linux Mint · **Verificado:** 2026-10

`InsertRichText(Text)` (`CTextEdit.cpp`, 3.22.1) inserta un fragmento HTML en la posición del cursor. Antes se lleva el cursor al final con `Select(posición, 0)`, nunca con `Pos` (GV-44).

Medido en banco, con tres formas de armar el fragmento:

    <p> tal cual                     se pega al final del párrafo anterior: Qt fusiona
                                     el primer párrafo del fragmento con el del cursor
    salto de párrafo + <p>           queda separado, pero hereda el formato del anterior:
                                     un fondo se corre a todo lo que se inserta después
    <p> en una tabla de una celda    separado y sin herencia; el fondo va en la celda (GV-64)

Ningún fragmento insertado aplica las clases del `<style>` del documento: los estilos van en línea. Con la tabla de una celda y estilos en línea, un mensaje cuesta alrededor de 1 ms con 300 en pantalla.

En el proyecto, el hilo de una nota se carga entero por `RichText` (`m_Notas`, SC-60): un hilo es corto y se lee completo.

**Relaciones:** vinculo:GV-64,vinculo:GV-44,vinculo:GV-37,vinculo:GV-52,vinculo:SC-60

**PENDIENTE:** En Mint, el banco confirmó que TextEdit es rápido; las tres variantes se compararon solo en 3.19.

### GV-108 — HtmlView: asignar Html no mueve la vista; solo Load con ancla desplaza

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.form.htmlview / contenedor (banco gbPruebaChat); fuente de HtmlView.class y c_htmldocument.cpp (3.22.1); banco corrido por Alberto en Gambas 3.22.2 / Linux Mint · **Verificado:** 2026-10

- `Html`: `Html_Write` (`HtmlView.class`) reemplaza el documento y no toca el desplazamiento. MEDIDO: la vista se queda donde estaba. Con 300 mensajes, cada reasignación costó entre 45 y 120 ms.
- `Load(archivo#ancla)`: es lo único que procesa un ancla. Busca el elemento por `id` o `name` (`find_anchor`, `c_htmldocument.cpp`) y desplaza hasta él; el documento tiene que pasar por un archivo temporal. LEÍDO en el fuente.
- El control no expone su desplazamiento: no hay forma de «bajar solo si ya estaba al final».

Por eso se descartó para el hilo de las notas (SC-60), y es una razón más para retirar HtmlView del proyecto (pendiente de SC-24).

**Relaciones:** vinculo:SC-24,vinculo:GV-107,vinculo:SC-60

**PENDIENTE:** Load con ancla no se midió en ejecución.

### GV-109 — WebView: SetHtml es asíncrono y ExecJavascript deja correr los eventos mientras espera

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5.webview / contenedor (banco gbPruebaChat); fuente de c_webview.cpp (3.22.1); banco corrido por Alberto en Gambas 3.22.2 / Linux Mint · **Verificado:** 2026-10

- `SetHtml` vuelve enseguida: la página queda lista recién en el evento `Finish`. En el banco, `Finish` llegó a los 74 ms.
- `ExecJavascript` espera el resultado con `GB.Wait(-1)` (LEÍDO en `c_webview.cpp`): los eventos siguen corriendo durante la espera.
  - Un `Timer` puede volver a entrar a mitad de la llamada.
  - Una segunda llamada antes de que vuelva la primera da «Pending asynchronous method» (LEÍDO en el fuente).
  - Quien lo use desde un timer necesita una guarda de reentrada.
- Agregar un mensaje con `ExecJavascript` costó entre 2 y 12 ms, y la vista sigue al final.

En Mint fue el que mejor se vio. No se adoptó para las notas (SC-60): el hilo es corto y TextEdit alcanza, sin otro componente ni otro motor.

**Relaciones:** vinculo:GV-107,vinculo:GV-108,vinculo:SC-60

**PENDIENTE:** La reentrada no se provocó: con un mensaje automático por segundo no apareció.

### GV-110 — gb.db2 / MySQL: Exec congela la interfaz; Timeout solo acota la apertura; READ_TIMEOUT acota la lectura y deja la conexión muerta

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.2 / gb.db2.mysql / Linux Mint (banco gbPruebaChat, Alberto); Gambas 3.19 / gb.db.mysql / MySQL 8.0.46 / contenedor; fuente de gb.db2.mysql (options.h) · **Verificado:** 2026-10

- `Connection.Exec` es sincrónico: la interfaz no se redibuja hasta que vuelve. MEDIDO en Mint: con `SELECT SLEEP(2)`, el reloj del banco se congeló y el tick siguiente se corrió un segundo.
- `Connection.Timeout` acota solo `Open`. Una consulta lenta sobre una conexión abierta no tiene plazo.
- `Options["READ_TIMEOUT"]` acota cada lectura. El driver la pasa a `MYSQL_OPT_READ_TIMEOUT` (`options.h`). Se asigna ANTES de `Open`: las opciones se leen al abrir.
  - MEDIDO en 3.19 con `READ_TIMEOUT = 2`: `SELECT SLEEP(5)` falla a los 2,00 s con «Lost connection».
  - La conexión queda muerta: la consulta siguiente también falla. Hay que descartarla y abrir otra.
- Las claves de `Options` no distinguen mayúsculas, y una clave desconocida se ignora sin aviso (LEÍDO en el fuente del driver). Un `READ_TIMOUT` mal escrito deja la conexión sin plazo y nadie avisa.

PATRÓN EN EL PROYECTO

`m_ConexionBD.AbrirConexionSondeo` abre una conexión aparte, con plazo de lectura, para el sondeo periódico de las notas (`m_Notas`, SC-60).

- La consulta del sondeo no pasa por `mConn`, que no tiene plazo.
- Tras un fallo, `m_Notas` descarta esa conexión y el tick siguiente abre otra.
- Con el semáforo de red en rojo, ni siquiera consulta.

**Relaciones:** vinculo:GV-23,vinculo:SC-60

**PENDIENTE:** El plazo se midió con gb.db en 3.19; en Mint, con gb.db2, el sondeo funciona pero el vencimiento no se provocó. Mini-test: abrir con AbrirConexionSondeo(2) y ejecutar SELECT SLEEP(5); debe fallar a los 2 s.

### GV-111 — MySQL 8: una columna con CHECK no admite una acción referencial que la modifique (error 3823)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Una columna que aparece en un `CHECK` no puede llevar, en su clave foránea, una acción que cambie su valor. Medido:

    ON UPDATE CASCADE      ERROR 3823
    ON UPDATE SET NULL     ERROR 3823
    ON DELETE SET NULL     ERROR 3823
    ON DELETE SET DEFAULT  ERROR 3823
    ON DELETE CASCADE      aceptada (borra la fila, no cambia la columna)
    RESTRICT / NO ACTION   aceptadas

    Column 'pid' cannot be used in a check constraint 'chk': needed in a foreign key constraint 'fk' referential action.

Un `CHECK` sobre OTRA columna de la misma tabla no tiene restricción.

CASO EN EL PROYECTO: la 1.10.0 (notas, SC-60) tiene `CHECK` sobre columnas con clave foránea (`chk_notas_destino` sobre `id_destinatario` e `id_grupo`). Por eso sus catorce claves son `ON DELETE RESTRICT ON UPDATE RESTRICT`. En el proyecto ningún id cambia, así que `ON UPDATE CASCADE` no aporta nada.

**Relaciones:** vinculo:SC-22,vinculo:SC-60

### GV-112 — GridView: volver Rows.Count a 0 no borra el formato de las celdas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor (arnés de m_Notas) · **Verificado:** 2026-10

Una grilla se vació con `Rows.Count = 0` y se volvió a llenar. Las celdas a las que no se les asignó `Background` en la carga nueva mostraron el fondo de la carga anterior: una nota cerrada heredaba el verde del índice de días.

REGLA: una carga que pinta celdas asigna el fondo en TODAS las celdas de la columna, también `Color.Default` en las que no llevan color. Aplicado en `m_Notas.CargarLista` y en `FSysAdmin.CargarNotasAdmin`.

**Relaciones:** vinculo:GV-58,vinculo:SC-60

**PENDIENTE:** No se miró si pasa lo mismo con Foreground, Font y Alignment, ni si Clear lo evita. Falta confirmarlo en 3.22.

### GV-113 — LaTeX: \raggedright, \centering y \raggedleft no parten palabras

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel spanish / poppler pdftotext / contenedor Ubuntu 24.04; gbpublisher en Linux Mint (prueba de Alberto, 21/10) · **Verificado:** 2026-10

Las tres declaraciones de LaTeX ponen pegamento infinito (`0pt plus 1fil`) en `\rightskip`, en `\leftskip` o en los dos. Con ese pegamento, cualquier corte de línea es aceptable en la primera pasada de TeX, que no intenta partir palabras. La segunda pasada, la que sí parte, no llega a correr.

MEDIDO (LuaLaTeX, babel spanish, `book` 11 pt), un párrafo largo con palabras largas y una compuesta con guion (`socio-económicamente`), en cada declaración y justificado, a 4,5 cm, 6 cm y 9 cm de caja, contando los guiones a fin de línea con `pdftotext -raw`:

    justificado                     4,5 cm: 42 guiones; 6 cm: 32; 9 cm: 17
    \raggedright, \centering
      o \raggedleft                  0 guiones y 0 líneas desbordadas en los tres anchos
    las mismas con \hyphenpenalty=10000
      y \exhyphenpenalty=10000        0 guiones (4,5 cm)

El guion de una palabra compuesta tampoco se usa como corte.

LÍMITES

- Depende de que `\pretolerance` no sea negativo: con `-1`, TeX saltea la primera pasada. El proyecto no lo toca (ni `preambulo-*.tex` ni `m_XML`).
- Una palabra más ancha que la línea no tiene corte posible en la primera pasada, y la segunda la partiría. Con la caja del proyecto no ocurre.

Por esto SC-61 no agrega penalidades de corte: no hacen falta y tienen un costo (GV-114).

Confirmado en Mint con el preámbulo del proyecto (Alberto, 21/10): en un libro y en una revista, los párrafos alineados no parten.

**Relaciones:** apoya:SC-61,vinculo:GV-114

### GV-114 — LaTeX: una nota al pie hereda las penalidades de corte del párrafo, no su alineación

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel spanish / poppler pdftotext / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El texto de `\footnote` se compone dentro de un `\insert`, con los parámetros vigentes en el lugar de la llamada. `\@parboxrestore`, que LaTeX ejecuta al abrir la nota, devuelve a su valor `\leftskip`, `\rightskip` y `\parfillskip`, pero no toca `\hyphenpenalty` ni `\exhyphenpenalty`.

MEDIDO (LuaLaTeX, babel spanish, caja de 6 cm), una nota larga dentro de `\begingroup\centering … \par\endgroup`:

    sin penalidades en el grupo              la nota sale justificada, 12 guiones
    con \hyphenpenalty=10000
      y \exhyphenpenalty=10000               la nota sale justificada, 0 guiones

En el segundo caso la nota se justifica sin poder partir: líneas flojas.

CONSECUENCIA: una declaración de alineación dentro de un grupo no le llega a una nota del párrafo, y la nota sale como cualquier otra. Una penalidad de corte, sí le llega. SC-61 no las usa (GV-113).

**Relaciones:** apoya:SC-61,vinculo:GV-113

### GV-115 — Pandoc: un RawInline al comienzo de un Para llega intacto a <para> y a <p>

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Un filtro que inserta `pandoc.RawInline('docbook', '<?gb-alinear der?>')` como primer elemento de un `Para` (o `'jats'` en la cadena de revista) obtiene, sin cambios en el texto crudo:

    DocBook   <para>
                <?gb-alinear der?>19 de octubre de 2026, Ciudad de México
              </para>
    JATS      <p><?gb-alinear der?>19 de octubre de 2026, Ciudad de México</p>

A diferencia de un `RawBlock` (GV-95), el escritor DocBook no toca el texto de un `RawInline`. Sí indenta el contenido del `<para>`: antes de la instrucción queda un nodo de texto en blanco. Quien busque la instrucción como primer hijo tiene que saltear ese nodo (`node()[not(self::text()[normalize-space() = ''])][1]`).

La instrucción pasa intacta por `cite-to-xref.lua` (revista) y por `ensamblar-capitulo-canonico.xsl` (libro). El capítulo valida contra el RNG de DocBook 5.2 con xmllint y el artículo contra la DTD Archiving 1.4: una instrucción de procesamiento dentro de un párrafo no cambia la validez.

**Relaciones:** apoya:SC-61,vinculo:GV-95,vinculo:SC-38

### GV-116 — Pandoc: una orden de LaTeX en línea se pierde sin aviso en JATS, DocBook y HTML

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El lector `markdown` de Pandoc tiene activa la extensión `raw_tex`: una orden de LaTeX dentro de un párrafo (`n\sptext{o}`) llega como `RawInline (Format "tex") "\\sptext{o}"`, pegada al `Str` anterior. Los escritores que no son LaTeX descartan un `RawInline` de otro formato, sin advertencia.

MEDIDO:

    .md         El n\sptext{o} 3 y la 1\sptext{a} edición
    JATS        <p>El n 3 y la 1 edición</p>
    DocBook     <para>El n 3 y la 1 edición</para>
    HTML        <p>El n 3 y la 1 edición</p>

Como el PDF del proyecto sale del canónico, la orden también se pierde en el PDF.

Lo mismo vale para cualquier orden de LaTeX en línea que no traduzca un filtro. Para `\sptext` la traduce `volada.lua` (SC-62). Las demás las informan, en libros, los controles `latex_en_linea`, `latex_suelto` y `html_crudo` de `controles_md.lua` (SC-54).

El orden de los filtros importa: un filtro que serializa con `pandoc.write` (las notas en `cite-to-biblioref-db.lua`, los bloques en `fenced-divs-to-elements-db.lua`) hace la misma pérdida dentro de lo que serializa. Medido: con `volada.lua` después de `cite-to-biblioref-db.lua`, la nota decía «la 2 edición».

**Relaciones:** apoya:SC-62,vinculo:SC-58,vinculo:SC-46,vinculo:SC-54

### GV-117 — XSLT: una plantilla importada pierde contra la de la hoja que importa, aunque tenga más prioridad

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Cuando dos plantillas coinciden con el mismo nodo, XSLT mira primero la precedencia de importación y después la prioridad. Una plantilla de una hoja importada con `xsl:import` tiene menos precedencia que cualquiera de la hoja que importa.

MEDIDO con SaxonJ-HE 12.5:

    imp-base.xsl (importada)   match="text()[ends-with(., '.')]" priority="10"
    imp-main.xsl               match="text()"           (prioridad por omisión)
    entrada <a>n.</a>          gana imp-main.xsl

CONSECUENCIA EN EL PROYECTO: `tex-comun.xsl` se importa desde `docbook-to-latex.xsl` y `jats-to-latex.xsl`, que tienen su propia plantilla `text()`, `superscript` y `sup`. Una plantilla que tenga que ganarles va en cada hoja; `tex-comun.xsl` solo puede aportar funciones o plantillas para lo que las hojas no atrapan, como las instrucciones `gb-espacio` y `gb-alinear`. Así está la letra volada (SC-62).

**Relaciones:** apoya:SC-62

### GV-118 — hyperref: \sptext en un título rompe el marcador; \texorpdfstring lo resuelve

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel spanish / hyperref / qpdf / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El argumento opcional de `\section` va al sumario, al folio y a los marcadores del PDF. hyperref convierte el título en cadena PDF y no sabe convertir `\sptext`: avisa «Token not allowed in a PDF string (Unicode)» y deja restos de la definición de babel.

MEDIDO (LuaLaTeX, babel spanish, hyperref), leyendo los marcadores con qpdf:

    \section{Capítulo sobre el n\sptext{o} 1}
        marcador: «Capítulo sobre el n.8-1.5ex o 1»
    \section[Capítulo sobre el n\texorpdfstring{\sptext{o}}{.º} 1]{…}
        marcador: «Capítulo sobre el n.º 1», sin avisos

En el sumario y en el título compuesto, `\sptext` sale bien. La o y la a voladas tienen su carácter en Unicode (º U+00BA, ª U+00AA); para las otras, el marcador lleva el punto y las letras sin volar.

**Relaciones:** apoya:SC-62,vinculo:SC-29

**PENDIENTE:** Medido con la clase book: confirmar en Mint con el preámbulo del proyecto.

### GV-119 — gb.highlight: $(nombre)=valor define una sustitución; un estado hijo de un from … to se busca dentro del tramo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gb.highlight 3.19 / gb.pcre / contenedor Ubuntu 24.04; fuente de gb.highlight 3.22.2 (gitlab.com/gambas/gambas); gbpublisher en Linux Mint con Gambas 3.22 (Alberto, 21/10) · **Verificado:** 2026-10

Dos recursos de los archivos `.highlight`, leídos en el fuente de gb.highlight 3.22.2 (`TextHighlighter.CreateCustomHighlighter`, `CState.Subst`, `CCommandFrom.Compile`) y medidos con 3.19.

SUSTITUCIÓN

Una línea `$(nombre)=valor`, sin sangría, define una sustitución. `CState.AddCommand` la aplica a cada argumento de un comando, así que el patrón se escribe una vez y se usa en varios estados:

    $(sptext)=/\\sptext\{[^}\n]*\}/
    …
      match $(sptext)

ESTADOS HIJOS

Un estado con más sangría que el anterior es su hijo. En un `from … to`, `CCommandFrom.Compile` prueba los hijos en cada posición del tramo, antes de buscar el cierre. Sin un hijo, todo lo que está entre `*` y `*` toma el color de la bastardilla, sin ninguna regla de adentro.

    italic.star{Comment}:
      from * to *
      latex.sptext.dentro{Function}:
        match $(sptext)

Varios hijos con el mismo nombre, uno en cada estado, no chocan. Un `match` no busca hijos adentro: sus hijos se prueban después del tramo. Por eso un título (`header`, `match /^#{1,6}.*$/`) queda entero en `Header`.

MEDIDO con un banco que registra la gramática con `TextHighlighter.Register` y corre `Run` línea por línea, como `m_ResaltadoSintaxis`:

    El n\sptext{o} 3                [Function:\sptext{o}]
    *con el 3\sptext{er} piso*      [Comment:*con el 3][Function:\sptext{er}][Comment: piso*]
    **la C\sptext{ía}**             [Keyword:**la C][Function:\sptext{ía}][Keyword:**]
    # Título del n\sptext{o} 1      [Header:# Título del n\sptext{o} 1]

Recordar GV-76: un espacio literal en un patrón no carga, porque `AddCommand` separa los argumentos por espacio.

Confirmado en Mint con 3.22 (Alberto, 21/10): \sptext se colorea suelto y dentro de las marcas.

**Relaciones:** apoya:SC-62,vinculo:GV-76,vinculo:SC-15,vinculo:GV-48,vinculo:GV-120

### GV-120 — gb.highlight: el primer estado que coincide gana; un lookbehind no ve lo anterior a la posición

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gb.highlight 3.19 / gb.pcre / contenedor Ubuntu 24.04 (banco de GV-119); el síntoma, en gbpublisher con Gambas 3.22 / Linux Mint (Alberto, 21/10); confirmado por Alberto en Mint · **Verificado:** 2026-10

En cada posición del texto, gb.highlight prueba los estados en el orden del archivo y se queda con el primero que coincide. Un `from … to` sin cerrar deja el estado abierto: en Mint con 3.22 el color sigue en las líneas siguientes (lo vio Alberto); en el banco con 3.19, hasta el fin de la línea.

EL CASO: ***texto***

    bold.double  from ** to **    abre en los dos primeros asteriscos y cierra en
                                  los dos primeros del final; el tercero abre una
                                  bastardilla que no cierra
    MEDIDO (antes):  [Keyword:***negrita y bastardilla**][Comment:* después normal.]

Remedio: `bold.italic.star` (`from *** to ***`) y `bold.italic.underscore` (`from ___ to ___`) ANTES de la negrita. Medido después: `[Keyword:***negrita y bastardilla***]`.

LOOKBEHIND Y LOOKAHEAD

Un patrón `/…/` se prueba sobre el texto desde la posición actual: un lookahead (`(?=\S)`) funciona, un lookbehind (`(?<=\S)`, `(?<![…])`) no ve lo anterior. Medido: con `to /(?<=\S)\*/` la bastardilla no cerraba. Las clases `\p{L}` y `\p{N}` sí reconocen letras con tilde y la ñ (`año_ñandú`).

LOS OTROS DOS CASOS DEL MISMO TIPO (corregidos en el mismo lote)

- Un `*` suelto abría bastardilla: `* ítem` (la lista, que va después en el archivo) y `5 * 3`. Ahora `italic.star` abre con `/\*(?=\S)/`. Medido: `* ítem` sale como lista (`Operator`) y `5 * 3` normal.
- Un guion bajo dentro de una palabra abría bastardilla (`palabra_con_guiones`, `snake_case`). Pandoc no la lee como énfasis (extensión `intraword_underscores`). Como el lookbehind no sirve, un estado anterior, `palabra.guion.bajo{Normal}`, consume la palabra entera: `match /[\p{L}\p{N}]+(_[\p{L}\p{N}]+)+/`. Medido: sin color; `_otra_` y `(_entre_)` siguen en bastardilla.

Las combinaciones anidadas (`**_x_**`, `*__y__*`, `_**z**_`) ya funcionaban: el tramo de afuera toma el color y el de adentro no se distingue.

Confirmado en Mint con 3.22 (Alberto, 21/10): ***texto*** se colorea entero y el texto que sigue queda normal.

**Relaciones:** vinculo:GV-119,vinculo:GV-76,vinculo:SC-15

### GV-121 — Pandoc: \\ en el .md es una barra literal en un Str

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

En el lector `markdown` de Pandoc, `\\` es una barra escapada: llega como una `\` dentro del `Str`, pegada al texto que la rodea. No es un salto de línea (el salto es la barra al final de la línea) ni LaTeX crudo.

MEDIDO (Pandoc 3.1.3):

    ## Corte de\\ subtítulo      Str "Corte", Space, Str "de\", Space, Str "subtítulo"
    ## Pegado\\sin espacio       Str "Pegado\sin", Space, Str "espacio"
    *bastardilla*\\ y            Emph […], Str "\", Space, Str "y"

Los escritores la escriben como una barra: «Corte de\ subtítulo» en las tres salidas. En cambio, una barra sola delante de letras (`\sin`) es LaTeX crudo (GV-116), y delante de un espacio es un espacio duro.

El identificador que Pandoc arma para un título no lleva la barra («corte-de-subtítulo», «pegadosin-espacio»).

**Relaciones:** apoya:SC-63,vinculo:GV-116,vinculo:SC-28

### GV-122 — babel-spanish: \% pone un espacio fino antes del signo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel-spanish 5.0q / poppler pdftotext / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Con el español activo, babel-spanish redefine `\%`. Leído en `spanish.ldf` (5.0q):

    \def\es@sppercent{% See tex.stack 435216 @egreg
      \leavevmode
      \ifnum\gluestretchorder\lastskip=\z@\unskip\fi
      \textormath{$\m@th\,$}{\,}}
    \def\spanishplainpercent{\let\es@sppercent\@empty}
    \addto\textspanish{%
      \let\percentsign\%%
      \es@sDRC\%{\es@sppercent\percentsign{}}}

Antes del signo pone `\,` y quita el espacio que hubiera. Sigue la recomendación de separar la cifra del signo (SI Brochure §5.4.7).

EN EL PROYECTO: un `88%` del .md llega al PDF como «88 %», aunque esté pegado, porque `tex-comun.xsl` escapa `%` como `\%` (en LaTeX, `%` abre un comentario) y ese `\%` es el que babel redefinió. El HTML y el EPUB muestran «88%»: las salidas difieren hoy.

MEDIDO (LuaLaTeX, posición de cada palabra con `pdftotext -bbox`):

    sin \spanishplainpercent    «88» «%»     separados
    con \spanishplainpercent    «88%»        pegados

`\SI{25}{\percent}` sale «25 %» en los dos casos: ese espacio lo pone siunitx, entre cifra y unidad.

`\spanishplainpercent` lo desactiva. Con la decisión de SC-64 (el porcentaje separado) no se usa.

**Relaciones:** apoya:SC-64

### GV-123 — siunitx 3.3.10 con babel-spanish: el punto decimal depende de detect-all

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / babel-spanish 5.0q / siunitx 3.3.10 / poppler pdftotext / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con LuaLaTeX, babel-spanish 5.0q y siunitx 3.3.10 (TeX Live 2023, la de Mint 22), leyendo el PDF con `pdftotext`.

EL PUNTO DECIMAL DEPENDE DE detect-all

babel-spanish convierte en coma todo punto decimal en modo matemático (`es-nodecimaldot` lo desactiva). siunitx compone la cifra en modo matemático, salvo que se le pida seguir al texto:

    output-decimal-marker={.}, sin detect-all    \num{12.5} → «12,5»   \SI{2.5}{\hour} → «2,5 h»
    output-decimal-marker={.}, con detect-all    \num{12.5} → «12.5»   \SI{2.5}{\hour} → «2.5 h»

Con `detect-all`, una fórmula común (`$3.5$`) sigue saliendo «3,5»: lo hace babel, no siunitx. SACAR `detect-all` CAMBIA LOS DECIMALES A COMA SIN AVISO.

`detect-all` es una opción de siunitx 2. En la 3.3.10 está deprecada: deja un aviso informativo en el log y se traduce, leído en `siunitx.sty`, a `mode = match, propagate-math-font = true, reset-math-version = false, reset-text-family = false, reset-text-series = false, reset-text-shape = false, text-family-to-math = true, text-series-to-math = true`. Escribir esas opciones en su lugar da lo mismo.

LA ENTRADA

El punto es el separador decimal de la entrada: `\num{16.000}` es dieciséis (sale «16,000» o «16.000» según el marcador de salida). Una cifra con el formato del Word se lee mal; por eso la entrada en el .md es la de siunitx (SC-64).

AGRUPACIÓN

`group-minimum-digits` es la cantidad mínima de dígitos de un lado del separador decimal para que se agrupe. Con 5 (el valor por omisión): «1000», «12 345», «1234.5678», «0.123 45». Con 3: «1 000», «9 000.00».

UNIDADES

- `per-mode=fraction` compone «km/h» como fracción vertical y agranda la línea; `per-mode=symbol` da «48 km/h» en una línea; el valor por omisión da «48 km h⁻¹».
- `\euro`, `\perthousand` y `\pertenthousand` no existen: «Undefined control sequence». `\DeclareSIUnit\euro{€}` da «450 €/m²» y «1 250.5 €», sin aviso de carácter faltante.
- `\SIrange{50}{51}{\degree}` da «50° a 51°»: la palabra del rango la pone el idioma.
- `\SI`, `\SIrange` y `\num` funcionan en la 3.3.10; los nombres actuales son `\qty`, `\qtyrange` y `\num`.

COLUMNA S

`S[table-format=4.2]` alinea `9000.00`, `6.4` y `12.25` en el punto; una celda de texto va entre llaves (`{--}`).

**Relaciones:** apoya:SC-64,vinculo:GV-122

### GV-124 — pandoc 3.1.3: una orden de siunitx incompleta queda como texto, o se traga lo que sigue

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3 (la de Ubuntu 24.04), leyendo el AST con `-t native`. El lector de Markdown reconoce `\SI`, `\SIrange` y `\num` como órdenes de LaTeX con una cantidad fija de argumentos, y cuando faltan no hace lo mismo que con una orden desconocida:

    Texto \SI{3}.                 Str "\\SI{3}."               texto común
    Texto \SIrange{1}{2}.         Str "\\SIrange{1}{2}."       texto común
    Texto \num 3.                 Str "\\num"                  texto común
    Texto \foo{3}.                RawInline tex "\\foo{3}"     LaTeX crudo (GV-116)
    Texto \SI{3}. Y \num{4}.      RawInline tex "\\SI{3}. Y \\num{4}"
    A \SI{3}.  (línea vacía)  Otra \\ barra.
                                  RawInline tex "\\SI{3}.\n\nOtra \\\\ barra"

- Una orden incompleta al final de su párrafo queda como TEXTO COMÚN: un filtro que mira solo los `RawInline` no la ve, y sale literal en las tres salidas.
- Si más adelante hay llaves, el lector las toma como los argumentos que faltan y se traga todo lo que hay en el medio, incluso una línea vacía: dos párrafos quedan unidos en un solo `RawInline`.
- El texto de ese `RawInline` puede traer saltos de línea.

EN EL PROYECTO: `cifras.lua` mira también los `Str` y frena si encuentra `\num` o `\SI` (SC-65); `controles_md.lua` informa como `latex_en_linea` una barra seguida de letras en un `Str` (no es un corte) y limpia los saltos del texto de la orden antes de escribirla en el informe, que es de una línea por hallazgo (SC-54).

**Relaciones:** apoya:SC-65,apoya:SC-54,vinculo:GV-116

### GV-125 — IBM Plex no tiene el espacio fino U+202F; Noto Serif sí

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** fontTools / tipografías de .hidden/fonts del repositorio (IBM Plex Sans y Mono, Noto Serif) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Leído el mapa de caracteres (`cmap`) de las tipografías que trae gbpublisher, con fontTools:

    IBM Plex Sans y Mono (las ocho)   sin U+202F; con U+2212, U+20AC, °, ³, ⁹, ×
    Noto Serif (las cuatro)           con todos

U+202F es el espacio fino que no corta la línea que usa `cifras.lua` entre los grupos de una cifra y entre la cifra y la unidad (SC-64).

EN EL PROYECTO: la hoja de estilo de la revista (`gbpublisher.css`) compone el cuerpo con IBM Plex Sans (`--font-sans: ''IBM Plex Sans'', system-ui, sans-serif`); el navegador toma ese carácter de la siguiente tipografía de la lista. El EPUB del libro compone con Noto Serif, que lo tiene. El PDF no usa U+202F: el espacio lo pone siunitx (`\hspace{0.15em}`). No se midió cómo lo muestra cada lector de EPUB.

**Relaciones:** vinculo:SC-65,vinculo:SC-64

### GV-126 — pandoc 3.1.3: el escritor DocBook pierde las celdas unidas; el de JATS las conserva

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3 sobre una grid table con celdas unidas: dos filas de encabezado, una celda que abarca dos columnas y una que abarca dos filas, en el encabezado y en el cuerpo.

    lector Markdown     las uniones llegan al AST: RowSpan y ColSpan en cada Cell
    escritor JATS       las conserva: <th rowspan="2">, <th colspan="2">, <td rowspan="2">
    escritor DocBook    las pierde: cada celda unida sale como una <entry> suelta y
                        se agregan <entry> vacías; la segunda fila del encabezado
                        pasa a <tbody>

La pipe table no admite celdas unidas: cada línea es una fila y cada `|`, una columna.

Una tabla con un pie de Pandoc (`: pie`) sale `<table><title>…</title>` en DocBook; sin pie, `<informaltable>`. Ninguno de los dos escritores lleva una nota debajo de la tabla.

EN EL PROYECTO: la tabla del cuadro la escribe `cuadro-armar.lua` y no el escritor de Pandoc (SC-66).

**Relaciones:** apoya:SC-66

### GV-127 — pandoc 3.1.3: el escritor markdown no devuelve el archivo del cuadro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3, leyendo y escribiendo markdown (`-f markdown -t markdown`):

    grid table con celdas unidas   sale simple table: las uniones se pierden y las
                                   dos filas del encabezado quedan en una
    pipe table                     sale simple table, con las columnas alineadas
    \num{12000} en una celda       sale `\num{12000}`{=tex}
    x \| y                         se conserva

Leer el archivo por el AST (`-t json`) da las celdas, pero ya no el texto que escribió el editor: la orden de LaTeX llega como RawInline, las comillas como Quoted.

EN EL PROYECTO: el archivo del cuadro (SC-66) no puede pasar por Pandoc para editarlo. Lo lee y lo escribe Gambas con un formato propio (`m_Cuadros`, SC-67); el que controla sigue siendo `cuadro-leer.lua`.

**Relaciones:** apoya:SC-67,vinculo:GV-126

### GV-128 — LuaLaTeX: linebreaker calla todos los Overfull \hbox; medir un cuadro sin el .log

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0, TeX Live 2023, linebreaker / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido en LuaHBTeX 1.17.0 (TeX Live 2023) con el preámbulo del libro (`preambulo-estetica.tex`).

LINEBREAKER CALLA LOS DESBORDES

`linebreaker` toma el callback `hpack_quality` (`linebreaker.sty`: «Our overfull box reporting function») y lo usa para su propia cuenta: no informa nada salvo en modo depuración. Con el preámbulo del libro, una celda `m{0.8cm}` con una palabra que no se puede cortar se sale de su columna 20,3 mm y el .log no dice nada; el mismo tabular sin linebreaker da «Overfull \hbox (99.43773pt too wide) in paragraph». No es que «bajen mucho», como decía el comentario de la estética: desaparecen todos. `\linebreakerdisable` no los devuelve: el callback sigue tomado.

LO QUE SÍ SE PUEDE MEDIR

- El ancho y el alto de un tabular: los ganchos del núcleo `env/tabular/before` y `env/tabular/after` lo meten en una caja (`lrbox`) y lo sueltan con `\usebox`; en el medio se lee `\wd`, `\ht` y `\dp`. No cambia la composición.
- El renglón que se sale de su columna: en `post_linebreak_filter`, `node.rangedimensions(renglón, renglón.head)` da el ancho real con el estiramiento que TeX le dio; si supera `renglón.width` en más de `\hfuzz`, desborda. Devolviendo `true`, el párrafo queda como estaba.
- El flotante más alto que la página: «LaTeX Warning: Float too large for page by Xpt», que linebreaker no toca. Es el alto con el pie, que la medida del tabular no ve.
- Dentro de `sidewaystable`, `\textwidth` vale `\textheight` (y `\linewidth` también): el ancho de la página se toma antes, en `\AtBeginDocument`.

EL .log NO SIRVE PARA MEDIDAS: corta las líneas en 79 caracteres y una línea con varias medidas llega partida. Las medidas se escriben en un archivo propio desde Lua.

EN EL PROYECTO: la vista previa de los cuadros (SC-67): `engine/vista_cuadro_medir.lua` y `medidas.txt`.

**Relaciones:** apoya:SC-67

### GV-129 — TableView (gb.form, 3.19): el editor no se cierra y repite su Save en otra fila

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.form / contenedor Ubuntu 24.04, xvfb · **Verificado:** 2026-10

Medido en Gambas 3.19 (contenedor, xvfb), con `Data` y `Save`, como en `FEditBookmark` de gb.form.

    Edit()                 abre un TextBox en la celda actual
    Edit(Lista, True)      abre un ComboBox de solo lectura con la lista
    Editor                 el control del editor; es Control: .Text va por un Object
    Save()                 lanza Save(Row, Column, Value) con la fila y la columna
                           donde se abrió; sin edición abierta no hace nada
    Cancel()               cierra sin guardar
    Rows[i].Title          se escribe y se lee; sin escribirlo, el número de fila
    Rows.Count + Refresh   alcanza para insertar en el modelo y repintar

LA TRAMPA: el editor no se cierra nunca. Después de `Save()` —y también después de `Cancel()`— sigue abierto (`Editor.Visible` da True siempre) y guarda la fila y la columna donde se abrió. Cuando la grilla cambia de filas (`Rows.Count` y `Refresh`), el próximo `Save()`, o el que dispara la propia grilla al ocultarse o rearmarse, vuelve a lanzar `Save` con el texto viejo en esa fila y esa columna, que ya es otra (medido: la fila insertada quedó con el texto de la de abajo). Y una edición a medio escribir NO se guarda sola cuando el foco sale de la grilla: se guarda recién cuando se abre otra edición, o se pierde.

PATRÓN: una marca propia. El clic que abre la edición anota la fila y la columna; el handler de `Save` descarta todo `Save` que no corresponda a una edición abierta, y la cierra. Antes de cambiar filas o columnas, de cambiar de modo o de leer el modelo: `Save()` solo si la marca está puesta (guarda en su celda lo que se estaba escribiendo) y después `Cancel()`. Medido con una edición sin guardar y una fila insertada: el texto quedó en su celda y la fila nueva, vacía.

DE PASO: `Integer[]` no tiene `Join` («Unknown symbol ''Join'' in class ''Integer[]''»): es de `String[]`. Y `GridView` admite `ColumnSpan` y `RowSpan` en una celda (medido en 3.19).

EN EL PROYECTO: `FTabla.CerrarEdicion`, `tvDatos_Save` y `tvColumnas_Save`, y `m_Cuadros.UnirEnteros` (SC-67).

**Relaciones:** apoya:SC-67,vinculo:GV-15,vinculo:RC-GM-03

**PENDIENTE:** Verificar en 3.22.1 (Mint) si el editor de TableView se comporta igual; el patrón sirve en los dos casos.

### GV-130 — Pandoc: ~ es el subíndice; dos ~ sin espacio entre ellos lo arman sin aviso

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3 (`-f markdown -t native`). La extensión `subscript`, activa en `markdown`, toma como subíndice el texto entre dos `~` si no tiene espacios:

    siglo~XX y siglo~XIX.   Str "siglo~XX" … Str "siglo~XIX."   (un ~ suelto queda literal)
    art.~3,~inc.~b          Str "art.", Subscript ["3,"], Str "inc.~b"
    n.º~5,~vol.~2           Str "n.º", Subscript ["5,"], Str "vol.~2."
    H~2~O                   Str "H", Subscript ["2"], Str "O"

No hay aviso: «3,» sale en subíndice en todas las salidas. Un filtro no lo puede deshacer: no distingue `H~2~O` de `art.~3,~inc.`.

EN EL PROYECTO: `~` no puede ser el espacio fijo del .md mientras el subíndice sea `H~2~O` (SC-30). El espacio fijo es `¬` (SC-68).

**Relaciones:** apoya:SC-68,vinculo:SC-30

### GV-131 — Pandoc: candidatos a marca en línea; | corta una celda, ¬ pasa en todas las posiciones

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 / xkb (latam, es) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3, cada candidato pegado entre dos palabras y en secuencia (`siglo|XX`, `art.|3,|inc.|b`):

    |      en un párrafo queda literal; en una celda de pipe table CORTA LA CELDA
           y el resto se pierde: «siglo|XX» da la celda «siglo»
    _      `siglo_XX` y `art._3,_inc._b` quedan literales (intraword_underscores),
           pero `_22_` da bastardilla: depende del contexto
    = +    quedan literales, pero aparecen en la prosa académica (n=30, C++, +5 %);
           una línea `===` debajo de un párrafo lo vuelve título
    ^      es el superíndice
    ¬      queda en el Str en todas las posiciones probadas

`¬` (U+00AC) pasó entre palabras, en secuencia (`art.¬3,¬inc.¬b`), en el sufijo y el prefijo de una cita (`[@a, pág.¬22]`), en una celda de tabla, pegado a una bastardilla (`*Felipe*¬II`), al principio y al final de una palabra, en el título de los metadatos, en una nota, en el pie de una imagen y en el texto de un enlace. En el código, la matemática y la URL de un enlace queda literal: no son Str.

`\ ` (barra y espacio) es el espacio duro que trae Pandoc (extensión `all_symbols_escapable`): `siglo\ XX` da `Str "siglo\160XX"`. Funciona, pero en el editor no se ve.

TECLADO (archivos xkb del contenedor): `¬` es AltGr + la tecla a la izquierda del 1 en `latam`, y AltGr+6 en `latam` y en `es`. Alberto usa la primera.

**Relaciones:** apoya:SC-68,vinculo:GV-130

### GV-132 — TextEdit conserva U+00AC (¬) al guardar y al reabrir

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.qt5 / Linux Mint (prueba de Alberto); código de m_Hunspell, m_FuncionesGenericas y m_EscanerUTF8 · **Verificado:** 2026-10

Prueba de Alberto en Mint (24/10): en `txtEditorProyecto`, que es un TextEdit, escribió `siglo¬XX`, guardó, cerró y volvió a abrir el archivo. El carácter se ve en el editor y en la terminal:

    grep -o $'\xc2\xac' l-CALIFA.md | wc -l    ->  1

GV-47 no lo había probado: lo que `.Text` transforma al leer es U+00A0, no U+00AC.

Tampoco lo tocan, leído en el código:

- el escáner UTF-8 (`m_EscanerUTF8`): el 172 no está en ninguno de sus rangos;
- `limpiar_docx.lua`: no lo nombra;
- el corrector: `m_Hunspell` separa las palabras con `m_FuncionesGenericas.EsLetra`, que toma como letras el 192–255 de Latin-1. `¬` es el 172: `siglo¬XX` se revisa como «siglo» y «XX».

**Relaciones:** apoya:SC-68,vinculo:GV-47

### GV-133 — Pandoc: --abbreviations pone un espacio duro detrás de cada abreviatura; pandoc.read no la toma sola

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 (Lua 5.4) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con pandoc 3.1.3. Con `smart` activo (lo está en `markdown`), el lector une una abreviatura de la lista con lo que sigue mediante U+00A0:

    la pág. 22, el n.º 5, Lic. Pérez, P. Bourdieu, EE. UU.
      ->  Str "pág.\160 22", "n.º\160 5", "Lic.\160 Pérez", "P.\160 Bourdieu", "EE.\160 UU."

- Coincidencia exacta: «Pág.» necesita su propia línea; «PÁG.» no está y no se une.
- Solo ante un espacio: una abreviatura al final de una línea del .md (SoftBreak) no se une con la siguiente.
- Pegada a otro inline: «pág. \num{1200}» da `Str "pág.\160"` y el RawInline; «cap. *tres*», `Str "cap.\160"` y la bastardilla.
- También en el sufijo de una cita: `[@a, pág. 40]` da `"pág.\160 40"`.
- El archivo REEMPLAZA la lista que trae Pandoc, no la amplía: con una lista sin «p.», «p. 4» deja de unirse. Sin la opción, Pandoc usa la suya (`pandoc --print-default-data-file=abbreviations`), que es inglesa pero trae p., pp., vol., fig., cf., ed. y n.: «p. 22» ya salía unido.
- Una abreviatura por línea, sin espacios.

pandoc.read EN UN FILTRO

`pandoc.read(texto, 'markdown')` NO usa la lista de la línea de órdenes: usa la de Pandoc. Con `PANDOC_READER_OPTIONS` entero la usa, pero también toma `columns` (72 en lugar de 80) y cambia el ancho relativo de las columnas de una grid table (`ColWidth 0.111…` en lugar de `0.1`). Pasando solo esa opción, la salida es idéntica salvo las abreviaturas (medido con una grid table y una pipe table):

    pandoc.read(texto, 'markdown', { abbreviations = PANDOC_READER_OPTIONS.abbreviations })

EL IDENTIFICADOR AUTOMÁTICO de un título quita el espacio duro, no lo vuelve guion: «# El siglo¬XX» da `el-sigloxx`.

**Relaciones:** apoya:SC-68,vinculo:SC-66

---

## GV-XML — Comportamientos verificados XML

Evidencia empírica sobre XML, XPath, XSLT, Saxon, los validadores y los esquemas JATS y DocBook
