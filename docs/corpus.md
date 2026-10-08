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
Para conversación (entrevista, historia oral): `<qandaset>`, que sí está en la base (SC-43, GV-82). El viejo `<para role="speech">` con `<emphasis role="speaker">` se retiró: tomaba solo el primer párrafo de cada intervención.

**Relaciones:** vinculo:SC-43,vinculo:GV-82

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

DECISIÓN CERRADA. Todo cambio de estructura de la base de gbpublisher sobre una instalación en uso se aplica con un script `actualizar-esquema-X.Y.Z.sh`, con las reglas de `BBDD_LEEME.md` §5. Cadena: 1.1.0 (bibtex: trazabilidad y FULLTEXT), 1.2.0 (licencias), 1.3.0 (idiomas), 1.4.0 (primeras del libro, SC-25), 1.5.0 (leyenda de autoría, SC-25), 1.6.0 (autoría en la apertura de capítulo, SC-26), 1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (refactor de bibtex) pendiente.

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

**Relaciones:** vinculo:GV-58,vinculo:GV-63,vinculo:RC-GM-04,vinculo:GV-67,vinculo:SC-26,vinculo:SC-34

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

Las ayudas se escriben en gbAyudas, un programa aparte con base SQLite, al estilo de gbCorpus. A diferencia de gbCorpus, da de alta y de baja: es el editor de las ayudas. Cada ayuda guarda su clave, un título legible en texto plano, las tres secciones en campos separados y su estado.

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

**Relaciones:** vinculo:SC-11,vinculo:GV-64,vinculo:SC-22,vinculo:GV-56,vinculo:SC-05,vinculo:GV-20

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
- El sumario se emite DESPUÉS de la última primera. Hoy `AbrirZona(ZONA_FRONT)` lo escribe al abrir la zona, y una primera declarada quedaría detrás de él.
- EPUB: la tapa (`cover`) va siempre, en `front-tapa.xhtml`; hasta SC-25 era `front-portada.xhtml`. La portada (`titlepage`, `front-portada.xhtml`) va solo si el libro la declara, con autoría, leyenda, título, subtítulo y logo de portada. Los créditos (`copyright-page`) van siempre: con logo de colección y textos digitales si el libro declara la pieza y tiene al menos uno de los dos textos; si no, el bloque genérico (`ArmarCreditos`), el mismo criterio que el colofón no declarado.
- EPUB sin versalitas: los nombres van en mayúsculas y minúsculas, como están en la base. Noto Serif las tiene, pero los lectores de EPUB no las respetan de forma pareja.
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

**Relaciones:** vinculo:SC-22,vinculo:GV-66,vinculo:SC-05,apoya:GV-23,vinculo:RC-GM-18,vinculo:SC-21,vinculo:GV-68,vinculo:SC-26

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

Título y subtítulo de artículo, de libro, de capítulo y de parte. El título traducido no: si trae la marca, sale un espacio.

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

**Relaciones:** vinculo:SC-25,vinculo:SC-26

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

**Relaciones:** vinculo:SC-29,apoya:GV-71

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

**Relaciones:** vinculo:SC-14,vinculo:SC-26,vinculo:SC-28,vinculo:SC-25,vinculo:SC-30,vinculo:SC-40

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

Un filtro que detiene la conversión ya no deja un capítulo vacío: `GenerarBodyCapituloXML` escribe una marca de fallo en lugar del fragmento y lo informa (GV-23).

EN REVISTAS NO HAY REFERENCIA CRUZADA

Un artículo es autónomo: no remite a figuras ni tablas de otro artículo, ni siquiera dentro de un dossier, porque sus autores no están conectados. Dentro del propio artículo, la mención («figura 2») la escribe el autor como texto, con el número que usó; si se cambia, lo decide el editor o el corrector. Por eso en revistas no hay `@fig-`: `cite-to-xref.lua` detiene la conversión con un mensaje ante una clave `fig-`, `tbl-`, `eq-` o `lst-` (SC-42), que antes salía como una cita bibliográfica a una referencia inexistente.

LA FIGURA DE REVISTA

`cite-to-xref.lua` arma el `<fig>`, la normal y la de ancho completo (`.fullwidth` → `specific-use="fullwidth"`); `figure-to-end.lua`, que hacía la segunda por separado, se retiró. Con las mismas reglas que el libro: el pie conserva formato y citas, `alt="..."` va a `<alt-text>` dentro de `<graphic>`, y frena sin id, sin pie o con contenido además de la imagen. El id no sirve para referir: es el ancla estable de la figura, que el HTML pone en el contenedor y el EPUB conserva (antes la renumeraba). En las dos salidas el pie conserva formato y el texto alternativo es el declarado o, si falta, el pie. Antes el pie se aplanaba a texto: perdía la bastardilla y la cita entera. Verificado en el contenedor: el JATS valida contra la DTD 1.4 y las cinco formas incorrectas frenan.

REFERENCIA CRUZADA: @fig-mapa (SOLO LIBROS)

Pandoc la lee como cita. En libros, `cite-to-biblioref-db.lua` la desvía a `<xref linkend>` por el prefijo: ninguna clave bibliográfica empieza con letra, porque empiezan con el id numérico del registro. Produce solo el número, como `\ref`; la palabra la escribe el editor. Un grupo que mezcla referencias y citas detiene la conversión. `@tbl-` y `@eq-` también la detienen, hasta que tablas y ecuaciones tengan su lote: antes salían como cita a una referencia inexistente.

Los id `fig-*` no se prefijan con el del capítulo en `ensamblar-capitulo-canonico.xsl` (`db:es-id-global`, como `bib-*`): con el prefijo, la referencia a una figura de otro capítulo apuntaba al propio. Son únicos en el libro por convención. El canónico de una pieza que remite a otra no valida suelto (IDREF); el del libro, sí.

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

**Relaciones:** vinculo:SC-31,vinculo:SC-28,vinculo:SC-25,vinculo:RC-DB-03,apoya:GV-23,vinculo:GV-72,vinculo:GV-73,vinculo:SC-35,vinculo:SC-42

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

RESALTADO

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

UN FILTRO QUE FRENA SE VE

En revistas, `GenerarBodyXML` sigue ahora el patrón de los capítulos: si Pandoc termina con error no se arma el `<body>`, se escribe una marca de fallo y el motivo queda en la terminal. Antes un epígrafe mal formado dejaba un `<body>` a medias sin aviso (GV-23).

**Relaciones:** vinculo:SC-34,vinculo:SC-33,vinculo:SC-31,vinculo:SC-30,vinculo:RF-11,vinculo:SC-11,apoya:GV-23

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

LAS REGLAS

1. En el canónico van como INSTRUCCIÓN DE PROCESAMIENTO con prefijo `gb-`, nunca como elemento: `<?gb-corte?>` (SC-28, en DocBook) y `<?gb-espacio …?>` (SC-39). El estándar XML las define para eso: indicaciones para una aplicación, fuera del modelo del documento. El canónico sigue validando contra el RNG de DocBook 5.2 y la DTD de JATS 1.4 (verificado), y el PDF se puede regenerar idéntico porque la instrucción queda en él. Una instrucción de procesamiento también puede ir dentro de un párrafo.
2. Lleva una FICHA propia, no LaTeX: `bigskip`, `vspace* 2baselineskip`. Solo las hojas LaTeX la traducen (en `tex-comun.xsl` cuando la ficha es igual en JATS y en DocBook), y frenan ante una ficha que no conocen.
3. Las hojas de HTML y EPUB no hacen nada: la regla incorporada de XSLT para una instrucción de procesamiento no escribe nada (medido en SC-28 y en SC-39). Una hoja que copie con `xsl:copy-of` o con una identidad sobre `node()` sí las copiaría: hay que mirarlo en cada hoja nueva.
4. Los indexadores las quitan todas de una vez. `jats-to-scielo.xsl` y `jats-to-redalyc.xsl` parten de una identidad sobre `@* | node()`, que incluye las instrucciones de procesamiento (verificado: copiaban `<?gb-espacio?>` al paquete). Una sola plantilla vacía, `processing-instruction()[starts-with(name(), 'gb-')]`, las quita: una instrucción nueva no se filtra por olvido.
5. Diccionario cerrado, en un solo filtro Lua por instrucción, que corre en las tres cadenas (revista, libro, ODT) con el patrón de `dos-partes.lua` (SC-35). En el ODT la quita. Lo que no está en el diccionario frena la conversión con un mensaje que dice qué falla y qué se admite.
6. En el catálogo de shortcodes, grupo propio: `composicion`, «Composición (solo PDF)», al final de la lista. El editor ve en el panel que son instrucciones de página y no de contenido. El grupo entró con el esquema 5 de gbShortcodes.
7. En una hoja LaTeX, la instrucción solo se alcanza donde se la pide: `*` selecciona elementos, no instrucciones de procesamiento. `docbook-to-latex.xsl` la agrega en unión, `(* except info) | processing-instruction('gb-espacio')`, que conserva el orden del documento; `jats-to-latex.xsl` ya recorría todos los nodos de `body` y `sec`.

Una salida digital que algún día necesite una de estas instrucciones la lee del canónico igual que el PDF: la ficha no depende de LaTeX.

**Relaciones:** vinculo:SC-28,vinculo:SC-31,vinculo:SC-35,vinculo:SC-34,vinculo:SC-39

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

### SC-40 — Rayas y puntos suspensivos en el .md: la convención de LaTeX

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1.3 / engine/limpiar_docx.lua 1.2 / contenedor · **Verificado:** 2026-10

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

LO QUE NO SE CONVIERTE: AVISOS

El filtro cuenta, el informe de la conversión lo muestra y el texto queda como llegó:

- `aviso_guion_entre_digitos`: «10-20» puede ser un rango, pero también una fecha, un ISBN o un teléfono. Cuenta casos, no palabras.
- `aviso_guion_pegado`: un guion pegado a una palabra en posición de inciso, «-inciso-». Es una corrección mal hecha. Cuenta también el prefijo suspendido («pre- y posguerra»), que es correcto.
- `aviso_enumeracion_punto_guion`: «4.-», «a.-». Es una corrección mal hecha: en la editorial se elimina.

Las cuatro conversiones también tienen su clave en el informe: `elipsis_a_tres_puntos`, `semirraya_a_dos_guiones`, `raya_a_tres_guiones` y `guion_aislado_a_semirraya`.

**Relaciones:** vinculo:SC-31,apoya:GV-79,vinculo:GV-47

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

**Relaciones:** vinculo:SC-32,vinculo:SC-33,vinculo:SC-21,vinculo:SC-31,vinculo:SC-30,vinculo:SC-34,vinculo:RF-11,vinculo:GV-80,vinculo:RC-GM-13

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

### RF-11 — Estructura de la base de gbShortcodes y contrato de exportación

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbShortcodes / SQLite 3.45 / Pandoc 3.1.3 / Gambas 3.19 (gb.db) en contenedor · **Verificado:** 2026-10

Programa aparte, con el modelo de gbCorpus (RF-08), que mantiene el catálogo de shortcodes de gbpublisher. Reemplaza a la tabla `shortcodes` de MySQL, retirada en la actualización 1.7.0 de la base de gbpublisher (SC-22, SC-34).

ESTA ENTRADA DESCRIBE LA VERSIÓN 4 DEL ESQUEMA Y DEL CONTRATO DE EXPORTACIÓN. La 2 agrega `clase`; la 3, el modo `dos-partes` y la regla de liberación; la 4, la tabla `modos`. El contrato de exportación no cambia desde la 2.

BASE

`~/.gbshortcodes/shortcodes.sqlite`, con `esquema_version`. La aplicación la crea en el primer arranque con el DDL de `m_Base.SentenciasDDL`, igual al de `shortcodes_esquema.sql` (verificado comparando `.schema`).

TABLA `shortcodes`

    nombre          TEXT NOT NULL UNIQUE   minúsculas, dígitos y guion: nombre de archivo
    clase           TEXT NOT NULL          la clase de Pandoc del .md: {.fig}, ::: epigraph, ]{.gloss}
    etiqueta        TEXT NOT NULL          lo que se ve en la lista de gbpublisher
    tipo            bloque | linea
    grupo           comun | estructura | disciplinar
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

QUÉ HACE LA APLICACIÓN

Lee, filtra, pule los textos (etiqueta, ayuda, mapeos, notas, pendiente) y exporta. NO da de alta ni elimina, y no cambia nombre, tipo, grupo, perfil, orden, estados, modo, apertura ni cierre: eso es comportamiento, se decide después de probarlo y se aplica por script SQL con Importar UPDATE SQL (`engine/importar_shortcodes.sh`, el contrato de SC-19 con `-- Esquema: 4`). El importador compara antes y después una huella del contenido, no solo la cantidad de filas, para no afirmar que la base quedó como estaba sin comprobarlo.

EXPORTACIÓN AL PAQUETE (CONTRATO CON gbpublisher)

A la carpeta `.hidden/shortcodes/` del proyecto gbpublisher. Van todos los shortcodes, en cualquier estado: gbpublisher filtra (instalado, solo lo liberado; desde el IDE, también los borradores).

- `_catalogo.tsv`: una cabecera fija, que hace de versión del contrato,

      nombre clase etiqueta tipo grupo perfil orden estado_libro estado_revista modo apertura cierre

  separada por tabuladores, y una línea por shortcode en el orden del catálogo: grupo (comun, estructura, disciplinar), perfil, orden, nombre. Escapes: `\\` por barra, `\t` por tabulador, `\n` por salto.
- `<nombre>.html`: fragmento, no documento. Tres secciones fijas, `<h3>Qué es</h3>`, `<h3>Cómo se escribe</h3>` y `<h3>Cómo sale</h3>`, y en la segunda la marca `<!--gb:ejemplo-->`, donde gbpublisher pone el ejemplo coloreado con su resaltador. El estilo lo pone quien lo muestra. Una sección vacía de un borrador sale «Sin completar.».
- `<nombre>.md`: el ejemplo tal cual, con salto final.

Las secciones se convierten con `pandoc -f markdown -t html --wrap=none` (Exec sobre un array, SC-05). La exportación se detiene, sin escribir nada, si una sección trae títulos, imágenes o tablas: el TextEdit de la ayuda solo tiene probados párrafos, listas, énfasis y código (GV-64). Antes de escribir exige una carpeta vacía o con `_catalogo.tsv`, y después ofrece borrar los .html y .md que no son del catálogo: todo lo que hay en la carpeta entra al .deb.

Salida determinista: dos exportaciones del mismo contenido dan archivos idénticos (verificado con diff).

OTRAS SALIDAS

- Documento de prueba, de libros o de revistas: un `.md` con un título y el ejemplo de cada shortcode que aplica, liberado o en borrador. Es lo que se compone en PDF, EPUB y HTML antes de liberar.
- Volcado SQL restaurable (verificado: restaura las 77 filas sobre una base vacía).

CARGA INICIAL

`shortcodes-carga-inicial.sql`: las 77 filas de `gbpublisher-baseline-1.0.0.sql`. Liberada solo la figura, sin pendiente desde la versión 3; los ejemplos que Pandoc no lee como se espera llevan pendiente. Los scripts que cambian shortcodes después de la carga se numeran: `gbshortcodes-act-001.sql`, `-002`… (el primero libera el epígrafe, SC-35). Los ejemplos de bloque llevan el cierre nombrado (SC-33).

MIGRACIONES DE ESQUEMA

La aplicación no abre una base de una versión anterior: dice qué script aplicar. La migración la corre el importador desde una terminal, y se reconoce por una línea de su cabecera:

    -- Migración: 1 a 2

El importador la acepta solo si la base está en la versión de partida y la de llegada es la que él maneja, y al terminar comprueba que la base quedó en la de llegada. `gbshortcodes-migrar-1-a-2.sql` rehace la tabla con la columna `clase` en su lugar (las columnas y restricciones quedan iguales a las de una base creada en v2, verificado) y pone el cierre nombrado en los ejemplos que siguen iguales a los de la carga inicial; uno editado se conserva y se lista.

`gbshortcodes-migrar-2-a-3.sql` rehace la tabla con las restricciones nuevas (SQLite no cambia un CHECK en su lugar) y copia las filas sin cambiarlas, salvo la figura: si sigue como en la carga, le quita el pendiente que pedía referencia cruzada en revistas, que no existe (SC-32). Antes de copiar comprueba la regla de liberación y frena si una fila la viola. Verificado: la base migrada tiene el mismo esquema que una creada en v3, y el DDL de la aplicación es igual al de `shortcodes_esquema.sql`.

Para correr un script de una versión, el importador tiene que ser el de esa versión: `importar_shortcodes.sh` de la 3 rechaza un script declarado `-- Esquema: 2` (medido). Por eso un cambio de datos que la migración necesita va dentro de la migración, y los scripts de datos de una versión se aplican antes de migrar a la siguiente.

NOMBRES Y LUGARES (DESDE LA VERSIÓN 4)

- `esquema-vN-a-vM.sql`: las migraciones, en `.hidden/esquema/`, que viaja en el paquete.
- `carga-inicial.sql`: también en `.hidden/esquema/`. Es el catálogo completo en la versión del programa: al pasar a la 4 se regeneró desde la carga original más `datos-v3-001` y `datos-v3-002`, porque una base nueva no puede aplicar scripts de una versión anterior. Se regenera en cada versión de esquema. Verificado: una base nueva con esta carga tiene las mismas filas que la base migrada.
- `datos-vN-NNN.sql`: los cambios de datos, en `datos/` del repositorio, numerados dentro de su versión. El nombre dice a qué versión van y en qué orden; `gbshortcodes-act-001` y `-002` pasaron a `datos-v3-001` y `datos-v3-002`. `datos/` no viaja en el paquete y la aplicación no lo lee: un script de datos se importa a mano, con «Importar script SQL». Lo que la aplicación lee está en `.hidden/esquema/`: la migración desde la versión anterior y la carga inicial.

LA APLICACIÓN MIGRA Y CARGA SOLA

Al abrir una base una versión atrás, la aplicación ofrece «Migrar» y corre su propio importador con su propio script de migración, en la pestaña Terminal (que pide la confirmación `s`). Al abrir una base sin shortcodes, ofrece la carga inicial. Los dos archivos salen de `RutaRecurso`: desde el IDE, de `.hidden/` del proyecto; instalada, de `/usr/share/gbshortcodes`. Así siempre son los de la versión que está corriendo, sin terminal externa ni ruta que elegir. Una migración que no se aplica deja la ventana abierta y bloqueada para leer el terminal. El título muestra la versión de esquema. Verificado con la aplicación bajo xvfb: una base v3 queda en v4 con sus 77 filas, y una base nueva se carga.

`esquema-v3-a-v4.sql` crea `modos` con sus filas, comprueba que todos los shortcodes usen un par existente y rehace la tabla con la clave foránea. Verificado: la base migrada tiene el mismo esquema que una creada en v4, y el DDL de la aplicación es igual al de `shortcodes_esquema.sql`.

`User.Home` no sigue la variable `HOME`: una prueba con otra `HOME` abre igual la base del usuario real (medido en 3.19).

**Relaciones:** vinculo:RF-08,vinculo:SC-19,vinculo:SC-24,vinculo:SC-11,vinculo:SC-32,vinculo:GV-74,vinculo:GV-64,vinculo:SC-33,vinculo:SC-35,vinculo:SC-36,vinculo:SC-42

**PENDIENTE:** Versión 2 verificada en Mint con 3.22.1: exportación e importación, y la lectura en gbpublisher (SC-34). Versión 3 verificada en Mint. Versión 4 probada en el contenedor con Gambas 3.19 y gb.db, incluida la migración y la carga desde la aplicación bajo xvfb; falta en Mint.

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

**Relaciones:** vinculo:GV-51,vinculo:GV-53,vinculo:GV-15,vinculo:GV-58,vinculo:GV-69

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
