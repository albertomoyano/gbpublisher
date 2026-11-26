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

### RC-GM-03 — Guardar en el evento, no en el botón: en los formularios que graban fila por fila

**Estado:** vigente · **Evidencia:** inferida

Los campos críticos (por ejemplo `es_autor_correspondencia`) deben guardarse en el evento del control (`CheckBox_Click`) para evitar que una deselección previa al guardado deje el dato sin escribir en la base.

ALCANCE: vale para los formularios que graban fila por fila, donde cambiar de fila antes de «Guardar» pierde lo marcado.

No vale para los editores que trabajan en memoria y graban todo junto (SC-73): ahí la marca pasa al objeto en memoria al aceptar el diálogo, al cambiar de idioma o de fila, y se graba con el resto en la transacción del registro. Guardar en el evento rompería esa transacción: dejaría escrita una parte aunque el usuario cierre sin guardar.

**Relaciones:** contracara:SC-73

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

**Relaciones:** apoya:GV-03, vinculo:SC-02, vinculo:GV-41,vinculo:GV-150

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

CORREGIDO EN FAplicarCrossRef (18/11/2026). El caso que señalaba el pendiente era real: `FEstructuraResultados` leía `FAplicarCrossRef.bAplicado` después del `ShowModal`, siempre daba `False` y el formulario de resultados nunca se autocerraba después de aplicar. Ahora `FAplicarCrossRef` cierra con `Me.Close(APLICADO)` (una `Public Const` del formulario) y el llamador decide con `iResultado = FAplicarCrossRef.ShowModal()`. La variable `bAplicado` se retiró.

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

### RC-GM-19 — Dialog.Filter es cosmético, no un mecanismo de control

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / Qt5 / Linux Mint · **Verificado:** 2026-08

`Dialog.Filter` es case-insensitive en Qt5. Un patrón `r-*.md` lista también `r-03REVISTA.MD` y `r-03revista.md`.

El filtro del diálogo es comodidad visual, no validación: cualquier regla sobre el nombre de archivo debe verificarse en código después de `Dialog.Path`, sobre el nombre original y sin `LCase`.

**Relaciones:** vinculo:GV-16

### RC-GM-20 — No hay bloque Try/Catch: hay dos mecanismos de error de alcances distintos

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** gambaswiki.org/wiki/lang/try, /lang/catch, /lang/finally / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

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

MEDIDO (19/11/2026, banco gbBanco322, en 3.19 y en 3.22.2 de Mint): una función que sale con `Return` antes de su `Finally` no lo ejecuta; la misma función sin `Return` sí. Lo que decía la documentación se cumple.

**Relaciones:** apoya:RC-GM-02, vinculo:RC-GM-07, vinculo:SC-07

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

Se corrigió en `m_GenerarEpub` y `m_GenerarHTML`, el EPUB y el HTML viejos de revistas, que salieron el 18/11/2026 (SC-98). `m_GenerarEpubLibro` y `m_XML` ya escapaban.

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

DESDE LA 2.0.0 (SC-102). Los campos se llaman como en biblatex: `relatedtype` y `relatedstring`. El que no se usa no tiene par en `bibtex_campo` (sin dato, sin par); ya no se escribe NULL. `FRelacionarBib` borra los tres pares de la relación e inserta `related` y uno de los dos, en una transacción. `m_Bibtex.VerificacionBase` marca como error una entrada con los dos, que puede llegar por JSON o por la base.

**Relaciones:** vinculo:RC-BL-02,apoya:GV-23,vinculo:SC-102

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
- Shell: no se requiere `LANG` explícito.

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

**Relaciones:** vinculo:GV-11,vinculo:GV-220

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
- Hace falta el paquete `perl` completo, NO solo `perl-base`. `perl-base` es Essential, pero no trae `PerlIO` ni `Encode`, y el script abre los archivos con `:encoding(UTF-8)`, que los necesita (GV-90). En el `.deb`: `Depends: perl`, sin versión. Lo garantiza el `.deb` y no se vuelve a controlar (SC-95).
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

### SC-11 — Modelo de recursos: el paquete se lee en su lugar; ~/.gbpublisher guarda solo lo del usuario

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / Linux Mint, probado por Alberto con dos libros; gbc3 3.19 y bash en el contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 25/11/2026). Reemplaza el modelo de copia local de trabajo, vigente hasta esa fecha. Probado por Alberto en Mint con dos libros reales (Jensen y Duek).

LOS RECURSOS DEL PAQUETE SE LEEN EN SU LUGAR

Todo lo que la aplicación distribuye se lee de donde lo instala el paquete: `/usr/share/gbpublisher/` instalado, `.hidden/` del proyecto desde el IDE.

- En Gambas, `m_InicioCierre.RutaRecursos()`.
- En los scripts, `$DIR_RECURSOS`, que `comun.sh` calcula como la carpeta de arriba de `engine/` (`readlink -f` sobre el propio `comun.sh`). Sirve igual instalado y desde el IDE. Reemplaza a `DIR_GBP_LOCAL`.
- Nunca una ruta fija a `/usr/share`: haría correr al IDE con los recursos de otra versión (SC-75).

Una carpeta de recursos nueva no se agrega a ninguna lista: basta con que viaje en el paquete (`ExtraFiles` del `.project`).

POR QUÉ SE ABANDONÓ LA COPIA

Hasta el 25/11/2026, `~/.gbpublisher/` era la copia de trabajo: la aplicación la leía y no la sobrescribía nunca. Servía para que cada editorial ajustara sin privilegios de root.

El inventario de las tres instalaciones en producción dio unas 250 copias idénticas a las del paquete y ninguna personalización: las personalizaciones de salida se hacen con scripts que procesan lo que la aplicación entrega (decisión de Alberto). La copia solo producía copias viejas:

- una hoja nueva que corrió con un script viejo de `engine/`, y Saxon frenó por un parámetro que el script no pasaba;
- un `OpenApp.wav` nuevo que nunca llegó a la copia (30/10/2026);
- esquemas y Schematron copiados que nadie leía (SC-97).

El cotejo al arrancar (`VerificarRecursosLocales`) existía solo para tapar eso.

QUÉ QUEDA EN ~/.gbpublisher

Solo lo del usuario. `DirectorioOcultoApp` crea, si faltan, `scripts/`, `editorial/latex/`, `respaldo/`, `snippets/` (SC-21), `regex/` (SC-51) y `.ips.txt`, y no copia nada. Ahí viven además `gbpublisher.conf` (SC-17), `conexion.conf` (SC-106) y `plantillas/` (SC-25).

Se retiraron `VerificarRecursosLocales`, `ReemplazarRecursosLocales`, `CopiarIconosSVG` y `CopiarDirectorio`. Los nueve íconos de `fonts/*.svg` traen el color (`#2D5A8E`) puesto en el archivo: era lo único que `CopiarIconosSVG` cambiaba al copiar.

LOS SCRIPTS DEL COMBO

`CargarScripts` reúne los del paquete (`RutaRecursos()/scripts`) y los propios (`~/.gbpublisher/scripts`). `RutaScript(sNombre)` resuelve cuál corre: uno propio con el mismo nombre que uno del paquete lo reemplaza.

LA ESTÉTICA DE UNA EDITORIAL

Es el único punto de ajuste de las salidas dentro de la aplicación. La carpeta es `~/.gbpublisher/editorial/latex/`.

- Vacía, que es el caso por defecto, se compone con la estética del paquete.
- Con un archivo de nombre exacto `preambulo-estetica.tex` (libros) o `preambulo-revista-estetica.tex` (revistas), que son las capas de `m_InicioCierre.$aCapasEditorial`, `CopiarRecursosLatex` lo copia al `latex/` del proyecto encima del del paquete.
- El contrato y los demás preámbulos no se reemplazan: son el acuerdo con las hojas XSLT, con versión verificada (`\gbRequiereContrato`), y una editorial que los cambiara rompería la composición sin que nada lo explicara.
- Un archivo con otro nombre se nombra en la terminal del proyecto y no se usa: un nombre mal escrito no pasa en silencio.

CONTRAPARTIDA: LO AJUSTADO SE DECLARA

La capa de la editorial llega al proyecto con una primera línea que la declara: `% gbpublisher: estética de la editorial: <ruta>` (`m_InicioCierre.MARCA_EDITORIAL`). `compilar_pdf_libro.sh` y `generar_pdf_revista.sh` la leen con `avisar_estetica_editorial` (`comun.sh`) y lo dicen en la terminal. Quien abra el proyecto años después sabe que no es la del paquete. La marca está escrita en dos lugares: un cambio va en los dos.

`m_AuditarJats.EstadoRecurso` queda: el informe del auditor sigue declarando el estado del catálogo de mensajes y de su hoja. Instalado compara el archivo consigo mismo y da «original»; desde el IDE dice si `.hidden/` difiere de lo instalado.

INSTALACIONES PREVIAS

`limpiar-gbpublisher-local.sh` (entregado aparte; no viaja en el paquete):

- Sin `--aplicar` solo muestra lo que haría. Se detiene si gbpublisher está abierto.
- Archiva en `~/gbpublisher-respaldos/gbpublisher-local-AAAAMMDD-hhmmss.tar.gz` y verifica que el archivo tenga cada archivo antes de borrarlo.
- Saca las carpetas copiadas (`assets auditor chart dtd filters fonts github latex llm media schemas schematron themes xslt`) y los restos `csl` y `biblatex-old`. De `scripts/`, solo las copias idénticas a los scripts del paquete.
- No toca la configuración, la conexión, los respaldos, `regex/`, `snippets/`, `plantillas/`, `editorial/` ni los scripts propios.
- La variable de entorno `GBP_RECURSOS`, puesta en la terminal al correrlo, lo hace comparar contra `.hidden/` del repositorio y no contra lo instalado.

**Relaciones:** vinculo:SC-05,vinculo:SC-24,vinculo:SC-34,vinculo:SC-35,vinculo:GV-77,vinculo:SC-96,vinculo:SC-75,vinculo:SC-97,vinculo:SC-17,vinculo:SC-21,vinculo:SC-51,vinculo:SC-106

**PENDIENTE:** Correr limpiar-gbpublisher-local.sh --aplicar en cada instalación que todavía tenga las carpetas copiadas.

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

LA REENTRADA DURANTE LA IMPORTACIÓN (18/11/2026). Mientras LibreOffice convierte, la espera de `m_EditorHTML` deja correr los eventos (GV-17). `FMain.cmbArchivosHTML_Click` deshabilita el panel de bibliografía entero (`Panel2`, la pestaña del editor HTML) durante `m_EditorHTML.AbrirArchivo` y lo rehabilita siempre, antes de mirar el resultado. Cubre de una vez el combo, los botones de marca y el guardado, sin una bandera en cada uno.

**Relaciones:** vinculo:GV-40, vinculo:GV-35, vinculo:GV-37, vinculo:RC-GM-21

### SC-13 — Trabajo pesado con herramientas externas: script propio y terminal embebido

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.terminal / bash / Linux Mint · **Verificado:** 2026-11

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

El primer caso migrado con este criterio: los canónicos de capítulo. `engine/generar_canonicos_capitulos.sh` reemplazó a `FMain.btnGenerarDocBookcanonico_Click` y a `m_XML.GenerarBodyCapituloXML`. El segundo, la salida PDF de libros: `compilar_pdf_libro.sh` pasó a la lanzadora y la preparación de los archivos LaTeX salió de Gambas a `preparar_latex_libro.sh` (SC-53). El 21/11/2026, git: el empuje remoto (`empujar_remoto.sh`) y el commit local (`commit_local.sh`, que el remoto llama anidado) reemplazaron a `m_GitHub.EmpujarGitHubRemoto` y a `EmpujarGitLocal`, que tipeaban en la terminal sin recibir resultado y escapaban el mensaje a mano (SC-103). El mismo día se retiró `FSabores`, que corría un XSLT a elección buscando Saxon con `dpkg` y `find`: las universidades personalizan sobre `main.tex`, el CSS y sus scripts de `scripts/`, no sobre el canónico. El 22/11/2026, las consultas a Crossref, OpenCitations y OpenAIRE: `consultar_doi.sh`, por `m_Crossref` (SC-105), reemplazó a los `Shell` de `FAnalizarDOI` y de FMain, que además leían el JSON a mano o con `python3 -c` armado como string.

INTÉRPRETES ADMITIDOS

`bash` y `perl-base`, que son Essential en Debian y Ubuntu. `python3` solo declarándolo como dependencia. `lua` NO: el paquete no existe con ese nombre y `lua5.4` no instala `/usr/bin/lua` (GV-08).

LO QUE NO SE VA DEL PROBLEMA

Mover la lógica fuera de Gambas no exime de RC-GM-02 ni de GV-23. En bash, un `&&` cuyo lado izquierdo es falso devuelve 1, y bajo `set -o pipefail`, si es el último comando de un grupo, contamina el estado de la tubería entera. En la sesión que originó esta regla, esa línea hizo que el informe declarara un rollback que no había ocurrido: la importación se había aplicado.

De ahí la regla operativa: UN INFORME NO AFIRMA LO QUE NO VERIFICÓ. Si va a decir que la base quedó como estaba, que lo consulte antes de decirlo.

BASE COMPARTIDA

Si el proceso externo escribe en la misma base que la aplicación tiene abierta, la conexión se cierra antes de lanzarlo y se reabre después por un ÚNICO camino explícito, invocado tanto en el éxito como en el fallo. `Finally` no sirve para esto (RC-GM-20).

**Relaciones:** vinculo:SC-05, vinculo:SC-11, vinculo:GV-17, vinculo:GV-20, apoya:GV-23, vinculo:GV-42,vinculo:SC-53,vinculo:SC-103,vinculo:SC-105

**PENDIENTE:** Inventario al 21/11/2026 de Input() fuera de la lanzadora: solo quedan el cd y el clear de la terminal (FMain, m_InicioCierre), un echo de diagnóstico en m_InicioCierre y los scripts personales del combo (m_FuncionesGenericas.EjecutarScript). m_XML y m_GitHub ya no tipean. Candidatos con Exec en Gambas: la conversión con LibreOffice de m_EditorHTML (criterio 1) y la auditoría de JATS externos, m_AuditarJats y m_ValidacionSchematron (criterio 2, con el contrato de m_Validaciones). Detalle: claude/migracion-engine.md.

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

Nueve archivos `.theme` en `themes/`, junto a los `.highlight`. Entre ellos, `gbpflexoki`: derivado de Flexoki para el trabajo editorial (fondo `#FAFAF9`, itálica en púrpura, referencias y marcas de nota en negrita); `flexoki` conserva la paleta original. `m_ResaltadoSintaxis` los lee de `m_InicioCierre.RutaRecursos() &/ "themes"` (SC-11); hasta el 25/11/2026 se copiaban a `~/.gbpublisher/themes`.

Formato `Settings`: una sección `[Tema]` (Nombre, Orden, Fondo, Texto) y una sección por gramática (`[XML]`, `[Markdown]`), porque la misma clave significa cosas distintas en cada una: `Comment` es comentario en XML e itálica en Markdown. Cada valor es `"#RRGGBB"`, con `;bold` y `;italic` opcionales.

Un tema se identifica por el nombre de su archivo, no por el texto del menú. Por defecto: `gruvbox`.

PREFERENCIAS

En `gbpublisher.conf` (SC-17): `[Resaltado] Tema`, y la tipografía en `[Editor] FontName / FontSize`. La tipografía se reaplica después de cada carga (GV-37).

CURSOR

Después de cargar un archivo, `Select(0, 0)` y `ScrollY = 0`: asignar `RichText` deja el cursor al final (GV-37). Nunca se escribe `Pos` (GV-44).

COSTOS MEDIDOS (JATS de 392.465 caracteres)

Abrir y colorear: 1,3 s, con `Application.Busy`. Cambiar de tema: 0,35 s.

El editor principal adopta este mismo modelo, con refresco en puntos fijos (SC-18).

**Relaciones:** vinculo:SC-11, vinculo:GV-46, vinculo:GV-48, vinculo:RF-10, vinculo:SC-17, vinculo:GV-44, vinculo:SC-18, vinculo:GV-54,vinculo:GV-227

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

Secciones en uso: `[Editor]` (FontName, FontSize), `[EditorHTML]` (FontName, FontSize), `[Interface]` (FontSize), `[Resaltado]` (Tema), `[FileManager]` (Ancho, Alto: la ventana del gestor de archivos) y `[GitHub]` (Usuario: se guarda tras un empuje remoto exitoso). Las dos últimas, desde el 21/11/2026 (SC-103).

La ruta se obtiene siempre de `m_InicioCierre.RutaConfiguracion()`; no se escribe literal.

LAS CREDENCIALES NO VAN ACÁ (18/11/2026). Las claves de los servicios externos (Azure Translator y los demás) viven cifradas en la tabla `api_credenciales` de la base, por `m_ApiCredenciales`, y se cargan en el panel de administración. `m_Traduccion` y `FTraducir` ya no usan `Settings`, y DeepL salió del código. Verificado con grep: el último uso del `Settings` global era `m_LLM` (el modo elegido y el último proveedor por modo). El mismo día pasó a `gbpublisher.conf`, secciones `[LLM]` y `[LLM/Ultimo]`, con `LeerPreferencia` y `GuardarPreferencia` privadas del módulo. Los valores guardados antes no se migran: el proveedor se vuelve a elegir una vez.

**Relaciones:** vinculo:SC-11, vinculo:SC-15,vinculo:SC-103

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

- Plegado por títulos: un árbol de estructura (`TreeView`, GV-51) en la pestaña «Estructura» del panel derecho (`tvEstructura`), a cargo de `m_Estructura`. Primer nivel: un nodo por .md de front-matter, articulos y back-matter, en el orden del combobox, con su título tomado de la base: `capitulos.titulo_capitulo` en libros, por `nombre_archivo` e `id_proyecto`; `articulo.titulo` en revistas, por `nombre_archivo` en el número del proyecto (hasta el 18/11/2026 leía la tabla vieja `articulos`, y en un número nuevo mostraba el nombre del archivo: SC-98); sin fila, el nombre del archivo. El archivo principal del proyecto no va, igual que en canónicos y compilación. Debajo, los títulos de cada archivo anidados por nivel.
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

EL NOMBRE DE CADA ARCHIVO, AL DÍA Y EN UNA LÍNEA (18/11/2026). El árbol no se enteraba de un título cambiado en los metadatos hasta reabrir el proyecto. Ahora los formularios de metadatos de capítulo y de artículo llaman a `m_Estructura.RefrescarNombres` al guardar. Esa función relee los títulos de la base, con una consulta por tabla, y cambia solo el texto de los nodos de archivo, sin releer los `.md` ni tocar lo desplegado.

El texto del nodo pasa por `m_CorteTitulo.Plano` (SC-28), y cada salto o tabulación pasa a ser un espacio. El caso que lo motivó: un título pegado en la ventana extendida con un salto final (capítulo 67 de Jensen) dibujaba la línea del árbol vacía. Las salidas no lo notaban, porque normalizan los blancos.

La causa se cerró en `FTXTextendido`:
- siempre quita los blancos de los extremos;
- con `UnaLinea`, convierte en un espacio cada tramo de blancos con un salto. Lo activan los títulos, subtítulos y palabras clave de capítulo, libro y artículo, y el título y el título del libro de la bibliografía.

Los demás campos de la ventana (resúmenes, textos legales en Markdown por líneas, biografías, notas) conservan sus saltos internos.

**Relaciones:** vinculo:SC-15, vinculo:GV-46, vinculo:GV-49, vinculo:GV-44, vinculo:GV-45, vinculo:GV-47, vinculo:SC-16, vinculo:GV-51, vinculo:GV-52, vinculo:GV-53, vinculo:GV-54, vinculo:GV-55, vinculo:GV-212

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

ALCANCE: X11, como GV-50. En Wayland no está verificado.

**Relaciones:** vinculo:GV-50, vinculo:GV-11,vinculo:SC-55,vinculo:SC-103

**PENDIENTE:** Verificar en Mint la variante FijarBotones(Me, True), que conserva el botón de cerrar.

### SC-21 — Snippets del editor: un archivo por snippet en ~/.gbpublisher/snippets/

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5 / gb.qt5.ext / Linux Mint · **Verificado:** 2026-09

DECISIÓN CERRADA. El editor principal (`txtEditorProyecto`) expande abreviaturas de tres caracteres en fragmentos de texto definidos por cada usuario. La lógica vive en `m_Snippets`; el acceso al editor pasa por `m_EditorPrincipal` (SC-18).

CONTENIDO, NO PREFERENCIA

Un snippet es contenido del usuario, como un script de `scripts/`. Por eso no va en `gbpublisher.conf`, y esto no contradice SC-17, que rige solo las preferencias.

Son personales: cada usuario tiene sus propias lógicas de trabajo, y no hay juego de la casa. No se guarda nada en la base.

ALMACENAMIENTO

- Carpeta `~/.gbpublisher/snippets/`. La crea vacía `m_InicioCierre.DirectorioOcultoApp()` si no existe. Es contenido del usuario: desde el 25/11/2026, `~/.gbpublisher` guarda solo eso (SC-11).
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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / bash / Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA. Todo cambio de estructura de la base de gbpublisher sobre una instalación en uso se aplica con un script `actualizar-esquema-X.Y.Z.sh`, con las reglas de `BBDD_LEEME.md` §5. Cadena: 1.1.0 (bibtex: trazabilidad y FULLTEXT), 1.2.0 (licencias), 1.3.0 (idiomas), 1.4.0 (primeras del libro, SC-25), 1.5.0 (leyenda de autoría, SC-25), 1.6.0 (autoría en la apertura de capítulo, SC-26), 1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (valores de los formatos de sistema Estudio 2A); 1.9.0 (`libros_md.estilo_cita` al identificador del estilo biblatex); 1.10.0 (notas internas, SC-60); 1.11.0 (tipos de pieza `indice_concepto` e `indice_autores`); 1.12.0 (retiro de la tabla `postits`, SC-60); 1.13.0 a 1.17.0 (rediseño de revistas, SC-71: las 23 tablas nuevas, NULL en lugar de '', ROR de la afiliación, vocabulario controlado y dos términos CRediT); 1.18.0 (siglas, SC-78); 1.19.0 (contrato con gbWeb, SC-81); 1.20.0 (la licencia en el contrato con gbWeb, SC-81); 1.21.0 (el libro en tres idiomas, `libro_venta` y el contrato con gbWeb, SC-81); 1.22.0 (el destino del HTML del libro, SC-85). La 2.0.0 (la bibliografía en pares campo/valor, SC-102) cierra la cadena 1.x.

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
- El respaldo de `mysqldump` se restaura con `--init-command="SET SESSION innodb_strict_mode=0"`: sin eso, un respaldo anterior a la 1.32.0, que trae la tabla vieja `articulos`, la borra y falla al recrearla (GV-67). Un respaldo posterior a la 1.32.0 se restaura con el comando directo (medido, GV-67).
- `GROUP_CONCAT` corta en `group_concat_max_len` (1024 por omisión) sin error: una lista de columnas armada así aborta un control de orden. La cuenta administrativa del script lo sube con `--init-command="SET SESSION group_concat_max_len = 1073741824"` (2.0.0).
- `GROUP_CONCAT(… SEPARATOR CHAR(10))` es un error de sintaxis: el separador es un literal (`SEPARATOR '\n'`).
- Bajo `set -e`, una consulta de control que falla dentro de `$( )` corta el script sin la limpieza: se envuelve en `if ! X=$(…)` y la falla cuenta como falla del control (2.0.0).
- Un FULLTEXT de una tabla que se llena de una vez se crea después de la copia (GV-217).
- Restaurar el respaldo no borra lo que el script creó después: una VIEW nueva queda apuntando a una columna que ya no existe (GV-169). Desde 1.19.0, la vuelta atrás que imprime el script borra primero lo creado y después restaura.

PUNTO DE RUPTURA: BASELINE 2.0.0 CON EL REFACTOR DE BIBTEX

Decisión de Alberto (20/10). El baseline no se regenera con cada versión de la cadena. El 2.0.0 se genera junto con el refactor de bibtex y lo incorpora: las instalaciones nuevas parten de ahí. Las existentes siguen su cadena hasta ese mismo punto. Hasta entonces, una instalación nueva restaura `baseline-1.0.0` y corre la cadena completa (BBDD_LEEME.md §5, «Cuándo conviene rebasear»).

HECHO (20/11/2026, SC-102). El baseline 2.0.0 se genera con `generar-baseline.sh` desde una base instalada desde cero con la cadena completa, no desde la base de trabajo: así es igual a toda instalación actualizada. Una instalación nueva lo restaura y no corre ninguna actualización. Desde ahí, cada script acepta como antecesor la actualización anterior o el baseline que la incluye: la 2.0.0 sale sin hacer nada en una base `baseline-2.0.0`, la 1.23.0 (que repone los disparadores después de restaurar un respaldo de la aplicación) corre en ella, y la 2.1.0 acepta `actualizacion-2.0.0` o `baseline-2.0.0`.

LA 2.1.0 (21/11/2026, SC-104). Cambia solo el CHECK `chk_pieza_nombre` de `numero_pieza`: acepta la regla única del nombre de pieza y sigue aceptando la forma vieja, sin tocar ninguna fila. Va antes que la aplicación nueva, que graba la forma nueva. Se cambia con dos sentencias (quitar el viejo, poner el nuevo con el mismo nombre) y, si el nuevo falla, se repone el viejo: la tabla no queda sin control. El estado se lee de `information_schema.CHECK_CONSTRAINTS`. Una instalación nueva restaura el baseline 2.0.0 y corre la 2.1.0.

EL ESQUEMA PROPIO DE gbWeb

El esquema `gbweb` (SC-80) sigue las mismas reglas, con su cadena en el repositorio de gbWeb y su propia `gbweb.esquema_version`: 1.0.0 (portales y asociación, SC-80), 1.1.0 (logo e imagen destacada, SC-83), 1.2.0 (datos del portal y perfiles en las redes, SC-83).

CADENA DE LAS SALIDAS DE REVISTAS (7 A 14/11/2026)

1.23.0 (reapertura de un artículo publicado, `articulo_reapertura` y sus disparadores), 1.24.0 (`por_articulo` al final del ENUM de `revista.modelo_paginacion`: así MySQL no copia la tabla ni renumera los valores), 1.25.0 (la fila `disponibilidad_datos` de `tipo_declaracion`), 1.26.0 (editorial, créditos, órganos y preliminares; migra), 1.27.0 (borra de `revista` las columnas que pasaron a la editorial; su vuelta atrás las repone desde la editorial), 1.28.0 (`credit_roles.uri`, `credit_rol_nombre`, `licencia_texto`, `revista.logo`), 1.29.0 (`articulo.licencia_texto`, `contribuyente_credit.nombre_rol` y `uri_rol`; congela los publicados con el catálogo del momento). Cada uno con respaldo, PREVIO, idempotencia y vuelta atrás probados en la base de prueba; los que borran o migran dejan un `…-volver-atras.sql` junto al respaldo. `m_ConexionBD.ObtenerEsquemaEsperado` se actualiza con cada uno. Ver SC-71, SC-88 y SC-90.

LIBROS: LA EDITORIAL Y CROSSREF (25/11/2026)

- 2.2.0: `libro_editorial`, las editoriales de cada libro en orden, con coedición (SC-88). Migra una editorial por cada combinación de los cinco datos de identidad del libro (nombre, institución, ROR, ciudad y país), reusando la fila de `editorial` que ya los tenga. Es aditiva: la aplicación anterior sigue andando.
- 2.3.0: `libros_md.crossref_fecha_deposito`, el registro del depósito (SC-108).
- 2.4.0: borra de `libros_md` las ocho columnas que pasaron a la editorial (`editorial`, `institucion_editora`, `ror_editorial`, `ciudad_publicacion`, `pais_publicacion`, `pais_publicacion_codigo`, `direccion_editorial` y `doi_prefix`), `colecciones.doi_prefix` y `capitulos.crossref_estado` y `crossref_fecha_deposito`. Vacía `libros_md.email_editorial` cuando repite el de la editorial principal.

La 2.4.0 frena si una VIEW usa una columna a borrar o si una colección tiene prefijo cargado. Informa, sin frenar, los libros sin editorial que tenían datos viejos y las consultas guardadas (tabla `consultas`, columna `editor_consultas`) que nombran columnas borradas. Las FK que usan una columna se borran en el mismo `ALTER` que la columna: si no, MySQL da 1828 (GV-224). La cuenta de columnas de `ValidarEsquemaBD` es exacta: el script y la aplicación nueva se instalan juntos, en todos los puestos.

**Relaciones:** vinculo:GV-58,vinculo:GV-63,vinculo:RC-GM-04,vinculo:GV-67,vinculo:SC-26,vinculo:SC-34,vinculo:SC-60,vinculo:SC-71,vinculo:SC-78,vinculo:SC-81,apoya:GV-169,vinculo:SC-83,vinculo:SC-85,vinculo:SC-88,vinculo:SC-90,vinculo:SC-102,vinculo:GV-217,vinculo:SC-104,vinculo:SC-108,apoya:GV-224

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

La aplicación la lee de los recursos del paquete, `m_InicioCierre.RutaRecursos()`, como todo recurso desde el 25/11/2026 (SC-11). Hasta entonces era una excepción deliberada a la copia local: en la ayuda no hay nada que ajustar, y una copia que nunca se sobrescribía dejaba al usuario con la ayuda vieja.

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

`FAyudas`, `m_EstilosHTML` (solo lo usaban las ayudas), los seis idiomas con su detección, y la tabla `manual_ayudas`. La tabla se elimina con una actualización de esquema (SC-22), recién cuando la ayuda nueva funcione. `FAyudaABM` ya salió el 18/11/2026: nada lo abría (SC-97).

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

- HTML integrado al portal (SC-85): la portadilla se omite; la portada es `index.html`, adonde lleva «Leer en línea» desde el portal, y los créditos son `creditos.html`, con las mismas páginas que el EPUB (portada mínima si el libro no la declara). Son pasos de la lectura y no entran en el menú. El HTML autónomo sigue la matriz.
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
- `numero_paginas`, ya existente: lo escribe la composición (CANTIDAD DE PÁGINAS). No se usa `\ztotpages`.
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

Cada campo de texto tiene un botón que abre `FPlantillaCreditos` con la plantilla de la editorial: un archivo por campo en `~/.gbpublisher/plantillas/<campo>.md`, contenido del usuario como los snippets (SC-21): lo único que guarda `~/.gbpublisher` (SC-11). Si no hay, se muestra la base de gbpublisher, que no trae datos de ningún sello. Aplicar copia al campo y pregunta si ya tiene texto; los reemplazos de cada libro se hacen después, con el editor ampliado.

CANTIDAD DE PÁGINAS

Desde el 25/11/2026 las escribe la composición: un solo escritor (SC-109). Hasta esa fecha el editor cargaba el total y la aplicación solo avisaba si difería del PDF.

- Una composición completa y correcta guarda, en una transacción, `libros_md.numero_paginas` y `pagina_inicio`, `pagina_fin` y `numero_paginas` de cada pieza. El total es el de `pdfinfo`: páginas físicas, cortesía incluida.
- El formulario las muestra y no las deja editar. Una pieza sin folio muestra «(sin páginas)».
- Si el total cambió y `texto_legal` o `texto_catalogacion` usan `{paginas}`, avisa «volvé a componer»: la página legal salió con el número anterior.
- Libro publicado, agotado o descatalogado (`estado_publicacion`): la composición no escribe nada. Si dio otras páginas, lo avisa y muestra las diferencias. Una corrección de imprenta que mueve la paginación se registra pasando el libro a «en preparación» y componiendo de nuevo (caso real, Duek: de 150 a 152 páginas).
- Libro ya depositado en Crossref (SC-108) y páginas cambiadas: avisa que hay que redepositar.
- La salida PDF/A no escribe páginas.

LOGOS

Solo PNG o JPG: el mismo archivo sirve al PDF y al EPUB, sin conversión. Un logo en PDF obligaba a generar un SVG para el EPUB, que no admite PDF como imagen; se descartó. Centrados a ancho fijo, definido en `preambulo-estetica.tex`: los dos a 110 mm (`\gbAnchoLogoPortada` y `\gbAnchoLogoColeccion`), nunca más anchos que la caja (`\gbLogo`). El de portada fue de 20 mm hasta el 29/10/2026: en una coedición lleva los sellos de todas las editoriales y necesita el mismo ancho que el de colección. El logo de colección se diseña sobre un lienzo de 110 mm de ancho: el blanco a los costados iguala las colecciones cuyo nombre o dirección ocupan distinto ancho. La resolución del archivo no interviene, así que GV-66 no afecta a los logos y el diálogo no la controla; solo tiene que alcanzar en píxeles (a 300 ppp, unos 1300 px para 110 mm). En el EPUB, la misma proporción sobre el ancho de pantalla: 100 % los dos (`gbpublisher-epub-libro.css`). El PDF y el EPUB frenan con un mensaje si el logo cargado no es PNG o JPG o no está en `media/`. `pdfinfo` lo trae `poppler-utils`, dependencia del `.deb` (SC-95).

Del resto de `media/`, el EPUB toma solo lo que el libro usa, en los formatos que admite —jpg, jpeg, png, gif, svg y webp, `m_GenerarEpubLibro.EsImagenEpub`—: la lista es la del manifiesto, y el script copia exactamente esa (SC-76). Antes copiaba todo y declaraba lo desconocido como `image/jpeg`: un PDF en `media/` dejaba el paquete inválido.

ESQUEMA

Por un script de actualización (SC-22). El `enum` de `tipo_capitulo` se reescribe partiendo del REAL, leído en information_schema: el baseline no tiene `indice_concepto` ni `indice_autores`, que el código usa, y `MODIFY` reemplaza la lista entera. Los handlers nuevos de logo declaran sus variables al principio (RC-GM-18), a diferencia de `btnBuscarTapa_Click`.

**Relaciones:** vinculo:SC-22,vinculo:GV-66,vinculo:SC-05,apoya:GV-23,vinculo:RC-GM-18,vinculo:SC-21,vinculo:GV-68,vinculo:SC-26,vinculo:SC-45,vinculo:SC-56,vinculo:SC-76,vinculo:SC-85,vinculo:SC-104,vinculo:SC-109,vinculo:SC-108

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

Varias salidas se generan escribiendo comandos en `TerminalViewProyecto` (`m_XML`; antes también `m_GenerarPDF` y `m_OrdenTaller`, retirados el 18/11/2026: SC-98, SC-99): Gambas no se entera de cuándo terminan, así que no hay evento del que colgar el refresco. Los archivos también cambian por fuera: el gestor de archivos, otros procesos. El costo es un `Dir` sobre una carpeta cada 3 s.

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

**Relaciones:** vinculo:GV-53, vinculo:GV-69, vinculo:GV-59, vinculo:SC-06, apoya:GV-23,vinculo:SC-103

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
- Consecuencia: `jats-to-html`, `jats-to-epub`, `jats-to-crossref` y `jats-to-doaj` (estas dos retiradas: SC-97), `docbook-to-html` y `docbook-to-epub` no se tocan.
- `jats-to-scielo` y `jats-to-redalyc` (retiradas el 18/11/2026, SC-97: los paquetes salen de `jats-a-scielo` y `jats-a-marcalyc`, que importan `jats-a-epub-articulo`) sí: parten de una plantilla identidad y copiaban el `<break/>` tal cual al paquete del indexador. Llevan una plantilla para `article-title` y `subtitle` de `title-group` con `<break/>`, que escribe el título con `normalize-space`. Por eso no hace falta pasar el `<break/>` por packtools: no llega a SciELO.
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

LA BASTARDILLA (26/11/2026, SC-111). El título de la base tiene una segunda marca, `*…*`, que sigue esta misma regla: `m_CorteTitulo.Segmentos` parte cada tramo en el asterisco y cada destino la traduce (`<emphasis>`, `<italic>`, `\emph`, nada). `m_CorteTitulo.Plano` quita las dos marcas.

**Relaciones:** vinculo:SC-25,vinculo:SC-26,vinculo:SC-63,vinculo:SC-111

**PENDIENTE:** Probar con un libro y una revista reales en Mint: la prueba fue en el contenedor, sin la base. Del PDF de revista se verificó el .tex que emite jats-to-latex, sin compilar el artículo entero.

### SC-29 — Notas al pie en títulos de sección: una por título, marca numérica o con símbolo, y dos versiones del título

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / DocBook 5.2 / JATS 1.4 / SaxonJ-HE 12.5 / LuaLaTeX + titlesec + hyperref + biblatex / TeX Live 2023 / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Un título de sección (`##` y siguientes) puede llevar una nota al pie. El título de la pieza, del libro o de la revista no: es una decisión editorial del modelo de trabajo.

UNA NOTA POR TÍTULO

Un título de sección lleva una sola nota (decisión de Alberto, 11/11/2026): titlesec guarda una sola y las otras se pierden del PDF sin aviso (GV-190). Lo informa el control `nota_doble_en_titulo` (SC-54); lo que sobre es un tema de corrección con el autor.

LA MARCA

La nota del título se numera con las demás, en el orden del texto. Desde el 11/11/2026 puede llevar, en cambio, un símbolo de la secuencia de la AMS, `\footnote{*}{texto}` (SC-86). Acá se había renunciado a esa marca porque Markdown no tenía forma de expresarla; la tiene (GV-189).

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

**Relaciones:** vinculo:SC-28,apoya:GV-70,vinculo:SC-86,vinculo:GV-190

**PENDIENTE:** Probar con un libro y una revista reales en Mint.

### SC-30 — Comillas y formato en línea: el mismo resultado en las seis salidas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / SaxonJ-HE 12.5 / Pandoc 3.1 / LuaLaTeX + ulem + hyperref / TeX Live 2023 / Chromium / contenedor · **Verificado:** 2026-10

DECISIÓN CERRADA. Lo que el editor marca en línea en el .md sale igual en el PDF, el EPUB y el HTML, de libro y de revista. Se armó una matriz de casos y se corrigió todo lo que no coincidía.

1. SIN SANGRÍA EN LA SERIALIZACIÓN XML

Las hojas que escriben XML lo hacen con `indent="no"`: los tres ensamblados del canónico (`ensamblar-capitulo-canonico`, `ensamblar-libro-canonico`, `ensamblar-canonico`), los dos EPUB (`docbook-to-epub`, `jats-to-epub`) y los cuatro indexadores (`jats-to-crossref`, `jats-to-doaj`, `jats-to-scielo`, `jats-to-redalyc`; retirados el 18/11/2026, SC-97). Con `indent="yes"` metían un espacio donde un elemento quedaba pegado a otro (GV-71):

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

En un libro el texto alternativo es obligatorio y no se reemplaza con el pie (SC-76): el botón escribe la apertura `::: {.fig #fig-mapa ancho=100 alt=""}` (`FMain.BloqueFigura`), y un `alt` vacío, ausente o igual al pie lo señala gbp-alt al generar el canónico; el armado (`ensamblar-capitulo-canonico.xsl`) descarta el que repite el pie, a propósito. `ancho=NN`, un entero de 1 a 100, es el porcentaje del ancho de la columna (SC-76). En una revista el `alt` sigue siendo optativo: `::: {.fig #fig-mapa alt="..."}`, y el botón no cambió. En revistas, `.fullwidth` la lleva al ancho completo; en libros no se usa.

LA CLASE ES .fig

Es la que escribe el shortcode y la que usan las revistas en producción. El botón de la barra escribía `.figure`, que ningún filtro reconocía: en revistas salía `<boxed-text>` con la figura adentro. Ahora botón y shortcode van por un solo camino, `FMain.InsertarFigura`: diálogo de imagen, copia a `/media` e id tomado del nombre de la imagen (`fig-mapa.png` da `#fig-mapa`).

EL FILTRO DE LIBRO ARMA EL <figure>

El escritor DocBook de Pandoc 3.1 descarta el id de una figura (GV-72), así que `fenced-divs-to-elements-db.lua` emite el `<figure xml:id>` con el pie en `<title>`, el alternativo en `textobject` y el ancho en `imagedata/@width="NN%"`. Detiene la conversión con un mensaje si falta el id, si falta el pie (RC-DB-03), si el bloque tiene algo más que la imagen o si `ancho` no es un entero de 1 a 100: antes, el párrafo que seguía a la imagen se perdía sin aviso.

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

FÓRMULAS (26/11/2026, SC-110). `@eq-nombre` ya no frena en libros: va a `<xref linkend>` como `@fig-` y `@tbl-`, y los id `eq-` son globales. Escribe el número entre paréntesis, «(9.1)», como `\eqref` (decisión de Alberto); el de la figura y el del cuadro siguen sin paréntesis. En revistas sigue frenando.

FÓRMULAS EN REVISTAS (26/11/2026, SC-110). La numerada `[$$…$$]{#eq-nombre}` lleva número automático, «(1)», en el `<label>` del canónico, y no tiene remisión: `@eq-` sigue frenando, como `@fig-` y `@tbl-`. El id `eq-` queda para los sabores y los enlaces.

**Relaciones:** vinculo:SC-31,vinculo:SC-28,vinculo:SC-25,vinculo:RC-DB-03,apoya:GV-23,vinculo:GV-72,vinculo:GV-73,vinculo:SC-35,vinculo:SC-42,vinculo:SC-53,vinculo:SC-69,vinculo:SC-110

**PENDIENTE:** Probar en Mint con el libro nuevo que tiene figuras y con una revista.

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

Se lee del paquete, como todo recurso (SC-11). Antes del 25/11/2026 era una excepción a la copia local: una copia vieja habría dejado el panel con los shortcodes de otra versión.

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

`dos-partes.lua` corre en revista (antes de `cite-to-xref.lua`) y libro (antes de `fenced-divs-to-elements-db.lua`). Cuenta las llaves del nivel del párrafo: Pandoc las deja como texto y las de adentro, balanceadas, son texto (medido con Pandoc 3.1.3). Deja el bloque con dos hijos, `.epigrafe-texto` y `.epigrafe-atrib`, y cada filtro solo serializa. Frena la conversión con un mensaje que cita el comienzo del bloque si falta una llave, si hay texto fuera, si las partes no van pegadas, si hay más de dos, si la primera está vacía o si la atribución tiene más de un párrafo.

- Revista: `<disp-quote specific-use="epigraph">` con `<p>` y `<attrib>` (valida contra la DTD 1.4).
- Libro: `<epigraph>` con `<attribution>` primero y los `<para>` (DocBook 5.2).

Antes, el filtro de revista aplanaba el epígrafe a texto (perdía la bastardilla y pegaba los párrafos) y el de libro perdía la atribución en un párrafo propio y todo párrafo después del primero.

DISEÑO (EL LEGADO LaTeX DE ALBERTO)

Bloque a la derecha, del 60 % de la columna, en letra menor (`\small`) y sin corte de palabra. El texto, alineado a la izquierda; un filete de 0,6 pt; la atribución, alineada a la derecha. Sin atribución no hay filete. Igual en libros y revistas, y en el PDF, el EPUB y el HTML.

- PDF: `\gbepigrafe{texto}{atribución}`, macro propia y no el paquete `epigraph`, que no permite omitir el filete. Está en `preambulo-contrato.tex` (libros) y en `m_XML.ObtenerPreambuloEmbebido` (revistas), gemelas: un cambio en una va en la otra. `jats-to-latex.xsl` reconoce el epígrafe por `@specific-use`, no por tener `<attrib>`.
- HTML y EPUB: `div.epigrafe` con `p.epigrafe-texto` y `p.epigrafe-atrib`; el filete es el borde superior de la atribución. Mismas reglas en `gbpublisher.css`, `gbpublisher-epub-libro.css`, `jats-to-html.xsl` (y estaban en el CSS de `m_GenerarEpub`, el EPUB viejo de revistas, retirado el 18/11/2026: SC-98). La atribución conserva sus marcas y no lleva raya.

- Dedicatoria (SC-45): el mismo bloque sin atribución, sin filete. En el PDF, el entorno `gbdedicatoria` del contrato es gemelo de `\gbepigrafe`: un cambio de diseño del epígrafe va en los dos.

EL TEXTO PUEDE SER UN VERSO (SC-49)

La primera parte puede ser un bloque `::: verse`, solo, con las llaves en su propio párrafo y líneas en blanco alrededor (GV-92). `dos-partes.lua` lo acepta (`verso1` en su tabla, sin gemelo en `m_Shortcodes.ProblemaDosPartes`, que controla las llaves y no los bloques) y lo marca con la clase `en-epigrafe`. Libro: los `<literallayout>` del verso dentro de `<epigraph>`. Revista: el `<verse-group>` dentro del `<disp-quote>`. PDF: el entorno `gbversoepigrafe` dentro de `\gbepigrafe`. HTML y EPUB: `div.verso.verso-epigrafe` dentro de `div.epigrafe`, con su letra y sin bastardilla.

UN FILTRO QUE FRENA SE VE

En revistas, `GenerarBodyXML` sigue ahora el patrón de los capítulos: si Pandoc termina con error no se arma el `<body>`, se escribe una marca de fallo y el motivo queda en la terminal. Antes un epígrafe mal formado dejaba un `<body>` a medias sin aviso (GV-23).

**Relaciones:** vinculo:SC-34,vinculo:SC-33,vinculo:SC-31,vinculo:SC-30,vinculo:RF-11,vinculo:SC-11,apoya:GV-23,vinculo:SC-45,vinculo:SC-49

**PENDIENTE:** Probado en el contenedor: los filtros, las cinco hojas que se pueden correr sueltas (las de HTML y EPUB de libro, con la plantilla aislada) y el PDF. Falta en Mint, con un libro y una revista reales, y epubcheck sobre un EPUB completo.

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
4. Los indexadores las quitan todas de una vez. `jats-to-scielo.xsl` y `jats-to-redalyc.xsl` (retiradas el 18/11/2026, SC-97: los paquetes salen de `jats-a-scielo` y `jats-a-marcalyc`, que importan `jats-a-epub-articulo`) partían de una identidad sobre `@* | node()`, que incluye las instrucciones de procesamiento (verificado: copiaban `<?gb-espacio?>` al paquete). Una sola plantilla vacía, `processing-instruction()[starts-with(name(), 'gb-')]`, las quita: una instrucción nueva no se filtra por olvido. `jats-a-marcalyc` tampoco las deja pasar: arma el HTML con las plantillas del EPUB, que no copian instrucciones, y para una instrucción la regla incorporada de XSLT no escribe nada. Verificado el 18/11/2026 con `gb-espacio` y `gb-alinear` (SC-97).
5. Diccionario cerrado, en un solo filtro Lua por instrucción, que corre en las dos cadenas (revista y libro) con el patrón de `dos-partes.lua` (SC-35). Lo que no está en el diccionario frena la conversión con un mensaje que dice qué falla y qué se admite.
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

Un valor fuera del diccionario, una longitud mal formada, `\cleardoublepage` en una revista, un bloque vacío, con más de un bloque adentro, o sin la barra. Y un bloque que no esté en el primer nivel: dentro de otro bloque, una lista, una cita, una tabla o una nota. En revista el filtro corre después de `unwrap-structural-divs.lua`, así que dentro de una sección estructural (`::: intro`) vale.

SALIDAS

- Canónico: `<?gb-espacio bigskip?>` entre los párrafos, en JATS y en DocBook.
- PDF: la plantilla de `tex-comun.xsl` escribe el comando. Compilado con LuaLaTeX.
- HTML, EPUB, Crossref, DOAJ: nada. SciELO y Redalyc: la plantilla vacía de SC-38.

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

Nunca el carácter Unicode. Los lectores `--from markdown` del proyecto (los de las cadenas de `engine/` y `m_PrimerasLibro`; también `m_GenerarEpub` y `m_GenerarODT`, retirados: SC-96, SC-98) tienen `smart` activo por omisión y los vuelven a U+2013, U+2014 y U+2026 (GV-79): el canónico JATS o DocBook y todas las salidas reciben el carácter tipográfico.

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

EL PIE

«Código N», debajo como en las figuras. Libros: por capítulo como las figuras (contador `gbcodigo` del contrato 11, `nl:numero-listado`); revistas: 1, 2, 3. Las figuras de revista dejaron de contar los listados en HTML y EPUB.

GEMELOS

La paleta está en la sección 8 de `preambulo-contrato.tex`, su gemela en `m_XML.ObtenerPreambuloEmbebido`, el CSS de `jats-to-html.xsl` y `gbpublisher.css`; el EPUB en `gbpublisher-epub-libro.css` (y estaba en `m_GenerarEpub`, el EPUB viejo de revistas, retirado el 18/11/2026: SC-98). La lista de lenguajes en `codigo.lua`, `codigo-comun.xsl` y `FCodigo`. La regla del ↩ en `colorear_codigo.lua` y `codigo-comun.xsl`.

INSERCIÓN

Modo `codigo` (gbShortcodes `datos-v5-005`): con selección; en bloque, `FCodigo` pide el lenguaje y, en el listado, el nombre, y la cerca lleva una tilde más que la racha más larga de adentro; el listado deja el marcador • del pie seleccionado (SC-21) y avisa si el nombre ya existe. En línea, comillas inversas, una más que las de adentro.

LOS SCRIPTS DE LIBRO SALEN DE RutaRecursos

`m_GenerarSalidasLibro` tenía fija la carpeta `/usr/share/gbpublisher/engine`: desde el IDE corría el `generar_html_libro.sh` y el `compilar_pdf_libro.sh` del paquete instalado, de otra versión. Así el HTML de libro salió sin color en la primera prueba (la hoja no recibió `codigo_dir`). Ahora la carpeta sale de `m_InicioCierre.RutaRecursos()`, como en el resto de la aplicación, y las hojas de HTML avisan si corren sin `codigo_dir`.

PROBADO EN MINT (2026-10)

PDF de pantalla y de imprenta, HTML y EPUB (y el ODT, retirado: SC-96), en libros y en revistas; inserción desde el panel; los casos que frenan. Los tres shortcodes se liberan con `datos-v5-006` de gbShortcodes.

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

- Revista: la etiqueta la escribe el filtro, y el idioma está en la base (`articulo.idioma_principal`, desde el volcado del número: `idioma_pandoc` en `generar_canonicos_articulos.sh`). `m_XML.ArgumentoIdiomaPandoc` lo pasa como `-M gb-idioma=xx`: solo letras ASCII y guiones, si no `es`. Clave propia y no `lang`: se eligió por el ODT (retirado: SC-96), donde `lang` cambiaba además el idioma de citeproc y del documento. `conversacion.lua` lo lee en su función `Pandoc`, con el documento entero: en una función `Div` de la misma tabla, `Meta` todavía no habría corrido (GV-84).
- Libro: nada que pasar. Sin `quien` no hay `label`, y la hoja pone la etiqueta según `defaultlabel` y el `xml:lang` más cercano al turno.

IMPLEMENTACIÓN

- `conversacion.lua`, filtro nuevo, corre en las dos cadenas: revista, después de `codigo.lua` y antes de `cite-to-xref.lua`; libro, antes de `fenced-divs-to-elements-db.lua`. Controla la forma (los frenos de arriba). Busca los turnos sueltos recorriendo el documento de arriba hacia abajo sin entrar en las conversaciones (GV-85). En revista escribe en cada turno el atributo `etiqueta` (`quien` o la de la tabla).
- `cite-to-xref.lua` y `fenced-divs-to-elements-db.lua` solo serializan; frenan si `conversacion.lua` no corrió antes.
- Hojas: `conversacion-comun.xsl`, incluida por las seis, da la etiqueta (`gbv:etiqueta`, ya en mayúsculas), si el turno es pregunta y sus bloques. PDF: entorno `gbconversacion` y `\gbetiqueta` (contrato 12); después de cada pregunta, `\nopagebreak[4]` en modo vertical. HTML y EPUB: `div.conversacion`, `div.turno` con `turno-pregunta` o `turno-respuesta`, `span.turno-etiqueta` y `p.acotacion`. Un turno de libro que empieza con una lista lleva la etiqueta sola en su párrafo.
- Medido en contenedor (pdfLaTeX, 60 pares de largo variable, con `\raggedbottom`, `\clubpenalty=10000` y `\widowpenalty=10000`, como los preámbulos del proyecto): ninguna página termina con una pregunta completa; una pregunta larga puede partirse entre páginas, con dos líneas al menos de cada lado, y la respuesta sigue a su final.

GEMELOS

- La tabla de etiquetas: `conversacion.lua` y `conversacion-comun.xsl`.
- El entorno: `preambulo-contrato.tex` (contrato 12) y `m_XML.ObtenerPreambuloEmbebido`.
- El CSS: `jats-to-html.xsl` y `gbpublisher.css` (etiqueta en negrita y azul, en los dos turnos); `gbpublisher-epub-libro.css` (negrita, negro; y estaba en `m_GenerarEpub`, el EPUB viejo de revistas, retirado el 18/11/2026: SC-98).

PROBADO EN MINT (2026-10)

PDF, HTML y EPUB, en libros y en revistas. Dos ajustes salieron de esa prueba: en el HTML la etiqueta de quien responde también va en azul, y en el PDF el bloque va corrido 14 pt a la izquierda. Los cuatro shortcodes —conversacion, pregunta, respuesta y acotacion— se liberan para libros y revistas con datos-v5-009 de gbShortcodes, por decisión de Alberto, con el XML JATS todavía sin probar (ver el pendiente).

ALTERNATIVA DESCARTADA: LA CLASE Q-and-A

Q-and-A (Jinwen Xu, CTAN, 2023/12/19) es una CLASE de documento, no un paquete: carga einfart (ProjLib) con LuaLaTeX y no entra en el `book` de libros ni en el `article` de revistas. Lee el cuerpo como texto y lo interpreta con expresiones regulares de LaTeX3 según su propio pseudo-markdown (`##`, `::`, `==`, `>>`, comillas inversas, `[` y `"` al comienzo de párrafo), que choca con el LaTeX que escriben las hojas; su documentación advierte que no admite `\verb` y que SyncTeX no funciona. El diseño es de chat (cada turno en un tcolorbox). Leído en el .cls y el README de CTAN. Se tomó su modelo: pregunta, respuesta y nota; hablante declarado; P. y R. en español.

TAMPOCO BITS question-answer: es para evaluaciones, no para entrevistas.

**Relaciones:** vinculo:RC-DB-04,apoya:GV-81,apoya:GV-82,apoya:GV-83,vinculo:SC-33,vinculo:SC-32,vinculo:SC-31,vinculo:RF-11,apoya:GV-84,apoya:GV-85,apoya:GV-86

**PENDIENTE:** Probar el XML JATS: validación del canónico, sabores (SciELO, Redalyc) y packtools. Los shortcodes ya están liberados (datos-v5-009).

### SC-44 — Orden editorial de las piezas: por nombre de archivo, desde m_OrdenPiezas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.1 / MariaDB 10.11 · **Verificado:** 2026-10

DECISIÓN CERRADA. Libros y revistas. Las piezas se ordenan por su nombre de archivo, nunca por id ni por fecha de alta. El criterio está escrito en un solo lugar, `m_OrdenPiezas`, y toda consulta que liste piezas en orden editorial lo llama. Ninguna escribe su propio `CASE` por prefijo.

LA CONVENCIÓN

El nombre da la posición: `prefijo-NN-resto` (`fm-10-PROLOGO`, `a-03-…`, `bm-99-COLOFON`). Cómo se escribe el resto, en SC-104. El prefijo fija la familia —preliminares, cuerpo, finales— y NN el lugar dentro de ella. Con dos dígitos, el orden alfabético dentro de cada familia equivale al numérico. El espacio `fm-00` a `fm-09` está reservado para las primeras (SC-25) y las piezas sueltas, como la dedicatoria (SC-45): es todo lo que va antes del sumario. `bm-00` a `bm-09`, para las piezas sueltas de finales. La regla, en Gambas, es `m_OrdenPiezas.EnEspacioReservado(sNombre)`: solo la forma de dos dígitos.

POR QUÉ NO EL ORDEN ALFABÉTICO SOLO, NI EL id

El alfabético da `a-` < `bm-` < `fm-`, exactamente el inverso del orden de lectura. El id refleja cuándo se cargó la pieza, no dónde va: las piezas no llegan juntas ni en orden.

EL MÓDULO

- `ClausulaOrden(sColumna)` devuelve el criterio sin la palabra ORDER BY: `CASE` por prefijo (`fm-` 1, `a-` 2, `bm-` 3, resto 9) y después la columna. Recibe la columna como se escribe en la consulta (`nombre_archivo`, `c.nombre_archivo`).
- `ExpresionCodigo(sColumna)` devuelve `SUBSTRING_INDEX(col, '-', 2)`: el código de posición (`fm-10-PROLOGO` → `fm-10`). Con la columna NULL da NULL.
- Un nombre NULL o sin prefijo conocido cae en el 9: queda al final y sigue a la vista. Las consultas de salida lo excluyen con `nombre_archivo IS NOT NULL`; las grillas no, porque la pieza recién creada tiene que poder editarse.
- No va en `m_PiezasLibro`: esa es la matriz de piezas del libro por salida, y este orden vale también para los números de revista.

Lo usan `m_GenerarPDFLibro.ArmarInsumosLaTeX`, `m_GenerarEpubLibro.ListaPiezasEpub`, el manifiesto del canónico en `m_XML`, `m_GitHub.ObtenerManifiestoCapitulos` y las dos grillas de metadatos.

GRILLAS DE METADATOS

`gbCapitulos` (`FMetadatosCapitulos`) y `gbArticulos` (`FMetadatosArticulos`, del camino viejo de revistas, retirado el 18/11/2026: SC-98) siguen la misma forma:

- Columnas: id oculto (ancho 0, lo usa el `Click`), Código y Título. Tipo, Estado y Fecha no se muestran.
- El estado se lee en la consulta aunque no se muestre: `PintarEstado` colorea la celda del código con la paleta de estados que antes tenía la columna Estado.
- `gbArticulos` filtra por `id_proyecto`, el número abierto, y no por `id_revista`: con el orden por prefijo, los `a-01` de cada número quedarían mezclados.

Verificado: el orden y la extracción del código, en MariaDB 10.11 con nombres reales, un NULL y uno sin prefijo; las dos grillas, por Alberto en gbpublisher.

**Relaciones:** vinculo:SC-25,vinculo:SC-45,vinculo:SC-55,vinculo:SC-104

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

**Relaciones:** vinculo:SC-25,vinculo:SC-44,vinculo:SC-35,vinculo:SC-31,vinculo:SC-104

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

- `verso.lua` controla y normaliza, con una sola regla para las dos cadenas (revista y libro), después de `conversacion.lua`. Deja un Div `.estrofa` por estrofa y un Div `.linea` por verso con el atributo `nivel`. Una marca que cruza versos (una bastardilla de dos versos) se parte en dos marcas iguales: ningún elemento del canónico cruza un fin de verso. Las notas, las citas, el código y las fórmulas no se parten.
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

`div.verso` con un `div.estrofa` por estrofa y un `span.verso-linea` por verso; la sangría es la clase `nivel-N`. El CSS reproduce el PDF: bastardilla, 0,75 em entre estrofas, cada verso un bloque con `padding-left: 3em` y `text-indent` de -3 em más 1,5 em por nivel, así que la primera línea queda en su sangría y la continuación a 3 em. En un epígrafe, `div.verso.verso-epigrafe`: la letra del epígrafe, sin bastardilla ni margen. Mismas reglas en `gbpublisher.css`, `gbpublisher-epub-libro.css`, `jats-to-html.xsl` (y estaban en `m_GenerarEpub`, el EPUB viejo de revistas, retirado el 18/11/2026: SC-98); las clases son las mismas en libros y revistas. Antes eran `verse-group` y `verse-line` en revistas, con diseños distintos en cada salida y un filete a la izquierda en libros.

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

**PENDIENTE:** Probado en Mint (2026-10) con prueba-verso.md: PDF, HTML y EPUB en libros y revistas, correctos; el shortcode se liberó (gbShortcodes datos-v5-011). Falta: la inserción desde el panel; los casos que frenan (prueba/frena); epubcheck sobre un EPUB completo. El XML JATS, sus sabores (SciELO, Redalyc) y packtools con un verse-group se prueban en la fase de JATS, cuando estén todos los shortcodes desarrollados (decisión de Alberto).

### SC-50 — Aplicaciones satélite de gbpublisher: un solo modelo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbCorpus 0.0.10 (esquema 2) / gbShortcodes 0.0.5 (esquema 5) / Gambas 3.22.1 / Linux Mint; código de los dos repositorios · **Verificado:** 2026-10

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
- gbCorpus, desde el esquema 2, registra cada script aplicado en la tabla `importaciones`, con su número de la serie, la huella sha256 del archivo y el momento (RF-08). Antes de escribir vigila la serie `gbcorpus-act-NN`. Rechaza un archivo ya aplicado, por su huella, y un número ya registrado. Si el número no es el último más uno, dice cuáles faltan y se detiene; en una terminal interactiva sigue solo si se escribe «saltar», y sin terminal se detiene siempre. Un script fuera de la serie, como una migración, se registra sin número. Después comprueba que la fila haya entrado.

EL SCRIPT

Lo que debe traer:

- Una cabecera de comentarios que diga qué hace, qué da de alta y qué modifica. El importador la muestra antes de pedir confirmación. Sin instrucciones para correrlo por línea de comando.
- La línea `-- Esquema: N`, con la versión de la base para la que se escribió (hoy, 2 en gbCorpus y 5 en gbShortcodes). Si falta, el importador avisa; si no coincide con la base, aborta.
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

Las dos aplicaciones cambiaron de esquema con este mismo mecanismo: gbShortcodes va por la 5 (el detalle de cada migración está en RF-11) y gbCorpus por la 2, que agregó el registro de importaciones (RF-08).

NOMBRES Y LUGARES DE LOS SCRIPTS

    gbCorpus       gbcorpus-act-NN.sql                    raíz del repositorio
                   .hidden/esquema/esquema-vN-a-vM.sql    migraciones
    gbShortcodes   datos/datos-vN-NNN.sql                 cambios de datos
                   .hidden/esquema/esquema-vN-a-vM.sql    migraciones
                   .hidden/esquema/carga-inicial.sql      catálogo completo para una base nueva

- En gbCorpus el número es un contador simple, independiente de los códigos de las entradas.
- En gbShortcodes el número va dentro de su versión de esquema: el nombre dice a qué versión va y en qué orden. La diferencia con gbCorpus es deliberada: gbShortcodes cambia de esquema y su importador rechaza los scripts de otra versión.
- `datos/` no viaja en el paquete y la aplicación no lo lee: un script de datos se importa a mano. `.hidden/esquema/` sí viaja: la aplicación lee de ahí la migración y la carga inicial.
- La carga inicial se regenera en cada versión de esquema: una base nueva no puede aplicar scripts de una versión anterior.
- Los scripts aplicados quedan en el repositorio, y el número del siguiente sale del más alto de la carpeta. Que un script esté en la carpeta no prueba que se haya aplicado: el 29/10/2026 act-75 y act-76 estaban en la carpeta de gbCorpus y no en la base. En gbCorpus lo dice el registro de importaciones (RF-08); gbShortcodes no tiene registro.
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
- gbCorpus y gbShortcodes: la carpeta local de cada una en la máquina de Alberto, a la que Claude tiene acceso. No se consulta GitHub: los scripts se aplican en local y pueden no estar subidos. De ahí salen los scripts escritos (`gbcorpus-act-NN.sql` en la raíz de gbCorpus, `datos/` de gbShortcodes). Cuáles se aplicaron en gbCorpus lo dice la tabla `importaciones` de `~/.gbcorpus/corpus.sqlite`, y se coteja antes de escribir: si la última registrada no es la más alta de la carpeta, falta aplicar algo y se avisa antes de redactar.
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

- Carpeta `~/.gbpublisher/regex/`. La crea vacía `m_InicioCierre.DirectorioOcultoApp()`. Es contenido del usuario, como los snippets (SC-21, SC-11).
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

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** JATS Archiving 1.4 / DocBook 5.2 / SaxonJ-HE 12.9

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

El comportamiento de XSLT, XPath y los validadores se prueba con la versión anclada del proyecto, no se deduce. La versión anclada es SaxonJ-HE 12.9 (decisión de Alberto, 18/11/2026): en /opt/Saxon-HE con el enlace saxon-he.jar, que es la ruta que llama la cadena; engine/integridad.sh la instala y la controla por la huella del JAR (SC-95). Caso abierto en el pendiente de esta entrada.

6. LO VERIFICADO SE ACUMULA EN GV-XML

Todo comportamiento comprobado de XML, XPath, XSLT, Saxon, xmllint, jing, Schematron, packtools y los esquemas JATS y DocBook entra como GV-XML-NN, con entorno y fecha. Las entradas anteriores sobre esos temas (GV-21, GV-22, GV-25, GV-26, GV-28, GV-71, GV-81, GV-82) quedan en GV con su código: están citadas en el código y en otras entradas, y renumerarlas rompería esas citas.

**Relaciones:** vinculo:GV-21,vinculo:GV-22,vinculo:GV-25,vinculo:GV-26,vinculo:GV-28,vinculo:GV-71,vinculo:GV-81,vinculo:GV-82,vinculo:SC-50,vinculo:SC-95

**PENDIENTE:** Mini-test: si SaxonJ-HE 12.9 acepta construcciones de XSLT 3.0 en una hoja declarada version="2.0". El resultado entra como GV-XML-01 y se quita este pendiente.

### SC-53 — Lanzadora de scripts de engine/: un solo camino, código de salida por archivo de estado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / gb.form.terminal / bash / Linux Mint; generar_canonicos_capitulos.sh probado en contenedor Ubuntu 24.04 con Pandoc 3.1.3, SaxonJ-HE 12.5 y jing, y el proyecto compilado con gbc3 3.19 · **Verificado:** 2026-10

DECISIÓN CERRADA. Todo script de `engine/` que Gambas lanza en la terminal del proyecto pasa por `m_Lanzadora.EjecutarScript`. Es el contrato del criterio 1 de SC-13: Gambas recibe una decisión, el código de salida, y no parsea nada.

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
- `FMain.lblMensajes`, sobre la terminal: qué se está generando —el parámetro opcional `sQue` de `EjecutarScript`, o el nombre del script si falta— y el tiempo transcurrido, una vez por segundo. Es tiempo, no un porcentaje: solo dice que el proceso sigue vivo. Se vacía al desbloquear.

Al dejar de esperar también se desbloquea y se vuelve al puntero normal: el script sigue corriendo, pero la aplicación ya no lo sigue y no puede seguir diciendo que trabaja.

UN MÓDULO NEUTRO (decisión de Alberto, 07/11/2026)

La lanzadora nació en `m_GenerarSalidasLibro`, con las salidas del libro, y el resto de la aplicación llamaba ahí para lanzar algo que no era un libro: cuadros, gráficos, la tapa web. Con las salidas de revistas pasó a un módulo propio, `m_Lanzadora`, sin cambiar su comportamiento (el código es el mismo, comparado función por función). Los nombres son los de la lanzadora de gbWeb (SC-50, SC-84): `EjecutarScript`, `InformarResultado`, `HayScriptEnCurso`, `HabilitarValidacion` y `ValidacionHabilitada`, que lee el guard de `m_GenerarSalidasLibro.ValidarCanonico`.

Lo que es de un tipo de proyecto queda en su módulo. Las siglas que leen algunos scripts del libro las prepara `m_Siglas.PrepararParaScript`, dueño de la lista de esos scripts (`SCRIPTS_CON_SIGLAS`): la lanzadora la llama antes de cada lanzamiento y no sabe nada de libros (SC-78).

CÓDIGOS

Los fija `engine/comun.sh` y los replica `m_Lanzadora`:

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

La validación de una parte del libro por separado —hoy, el canónico de cada capítulo— la hace `validar_canonicos.sh` (SC-75), que no cuenta como aviso los errores `IDREF "…" without matching ID` de jing. Son remisiones a algo que está fuera de la pieza: las citas a la bibliografía consolidada, cuyos `bib-*` entran recién al ensamblar, y las remisiones a figuras o secciones de otra pieza (SC-32). Contadas como aviso, daban código 3 en todo libro con bibliografía consolidada, y un aviso que sale siempre tapa a los que importan.

Se informan en tenue, con su cantidad, como remisiones que se verifican al ensamblar. Cualquier otro error de jing sigue siendo aviso. Si solo hubo remisiones, el informe no dice «válido»: dice que no hay errores de esquema propios de la pieza. Un IDREF colgado de verdad lo marca la validación del libro, que `ensamblar_libro.sh` le pide al mismo validador y que lo cuenta como aviso. Es la separación de capas de SC-52: válido como pieza no es válido como libro.

El patrón sale de la salida real de jing en Linux Mint: `69:1130: error: IDREF "bib-4308-TOCHO2020" without matching ID`.

LOS USOS

`ensamblar_libro.sh`, `generar_html_libro.sh`, `generar_epub_libro.sh`, `generar_canonicos_capitulos.sh`, `preparar_latex_libro.sh`, `compilar_pdf_libro.sh`, `validar_canonicos.sh` (SC-75) y `tapa_web.sh` (SC-81). Desde el 21/11/2026, `empujar_remoto.sh` y `commit_local.sh` (SC-103), y `consultar_doi.sh` (SC-105). `compilar_pdf_libro.sh` fue el último en pasar: se tipeaba en la terminal, Gambas no sabía cuándo terminaba y no informaba el resultado; además tenía su propia copia de las funciones de salida, con un `aviso` que no contaba. Ahora carga `comun.sh` y sus avisos (citas sin entrada en el .bib, entradas de índice descartadas, referencias cruzadas sin destino o repetidas, falta del .bib) llegan como código 3.

`preparar_latex_libro.sh` hace lo que antes hacía `m_GenerarPDFLibro.GenerarMainTeX` con `Exec` síncronos: colorear y transformar cada pieza (`colorear_codigo.sh` y `docbook-to-latex.xsl`), borrar los `c-*.tex` huérfanos y poner el `main.tex` en su lugar. Mientras eso corría en Gambas, la interfaz no se repintaba (GV-17) y no había señal de vida antes de que empezara la compilación. Gambas conserva lo que sale de la base, en `m_GenerarPDFLibro.ArmarInsumosLaTeX`: preámbulo derivado, `.bib`, la lista de piezas con cuerpo (`tmp/latex-piezas.txt`) y el `main.tex` propuesto (`latex/.main.tex.tmp`). «Solo generar» lanza `preparar_latex_libro.sh`; «Generar y compilar» lanza `compilar_pdf_libro.sh`, que lo llama anidado primero y no compila si falla.

El `main.tex` sigue yendo último (criterio de SC-07): el script lo pone con `mv` solo si todas las piezas salieron bien, y si alguna falla el anterior queda intacto. Como `mv` conserva la fecha del temporal, anterior a las piezas, un `touch` lo deja como el archivo más nuevo. Una pieza que falla no corta el resto: se listan todas y no se pone el `main.tex`. El preámbulo derivado y el `.bib` los sigue escribiendo Gambas antes del script: si una pieza falla quedan nuevos junto al `main.tex` anterior, lo que se aceptó porque no son declarativos y la próxima corrida los reescribe. Decisión de Alberto.

LANZAR CON UN FORMULARIO MODAL ABIERTO (21/11/2026, SC-103)

`FFileManager` lanza `empujar_remoto.sh` sin cerrarse. Con un formulario abierto con `ShowModal` no se puede escribir en FMain: ni en sus campos ni en la terminal donde corre el script. Dos consecuencias:
- El script no puede esperar respuestas: corre `ssh` y `git` con `BatchMode=yes` y `GIT_TERMINAL_PROMPT=0`. Si la clave pide una frase de paso que el agente no tiene, falla y lo dice en lugar de quedarse esperando.
- `EjecutarScript` espera con `Wait`, y el formulario sigue recibiendo clics: el manejador apaga sus controles mientras espera, y `Form_Close` no deja cerrar con `m_Lanzadora.HayScriptEnCurso()`.
Un script puede llamar a otro anidado para un paso común: `empujar_remoto.sh` hace el commit con `commit_local.sh` (`GBP_ANIDADO=1`) y cuenta sus avisos para el código final.

**Relaciones:** vinculo:SC-13,vinculo:SC-06,vinculo:SC-11,vinculo:GV-06,vinculo:GV-39,vinculo:GV-42,vinculo:RC-GM-20,apoya:GV-23,vinculo:SC-32,vinculo:SC-52,vinculo:SC-54,vinculo:GV-100,vinculo:SC-07,vinculo:SC-75,vinculo:SC-78,vinculo:SC-84,vinculo:SC-103,vinculo:SC-105

### SC-54 — Controles de corrección del .md: un filtro en engine/ con niveles declarados

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / bash / contenedor Ubuntu 24.04: controles_md.lua solo y dentro de generar_canonicos_capitulos.sh; los controles de notas, en Linux Mint con un libro real · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Lo que el Markdown deja pasar sin error y llega mal al impreso —un error que se le puede pasar a la corrección— se controla al generar el canónico de cada capítulo, en un solo lugar donde los controles se van sumando a medida que el uso los muestra. El caso que lo originó: una llamada a nota sin su definición salió como «[^3]» literal en el PDF (GV-99).

DÓNDE

`engine/controles_md.lua`, en una pasada de pandoc propia que `generar_canonicos_capitulos.sh` corre antes de la conversión:

    pandoc ARCHIVO.md --from markdown --to plain
           --lua-filter engine/controles_md.lua
           --metadata gb-controles=tmp/controles-{base}.tsv
           --metadata gb-fuentes=tmp/fuentes-{base}.txt
           --metadata gb-proyecto=RAIZ --output /dev/null

- Pasada aparte y sin los filtros de producción, por el criterio de SC-46: `fenced-divs` serializa los divs a XML crudo y después ya no hay texto que revisar, y otros filtros frenan. Así el control ve el documento como lo escribió la corrección, también adentro de un recuadro.
- En `engine/` y no en `filters/`: un control que dice «este capítulo está bien» no se ajusta localmente (SC-11).

EL CONTRATO

- El informe va a un archivo, no a stderr, para no mezclarse con los mensajes de pandoc. Un hallazgo por línea: `nivel TAB control TAB mensaje`.
- El filtro lo escribe siempre, vacío si no hay hallazgos. Si falta, el control no corrió y el capítulo falla: no se da por revisado lo que no se revisó.
- En `gb-fuentes` escribe los `cuadros/{id}.md` que nombra el .md, uno por línea, con la misma regla id → archivo que `cuadro-leer.lua`. Mismo contrato: siempre escrito, vacío si no hay cuadros; si falta, el capítulo falla. No es un control y no registra nada: con esa lista `generar_canonicos_capitulos.sh` anota las huellas del canónico (SC-75). Va acá y no en `cuadro-leer.lua` porque este filtro está en `engine/` y no se modifica (SC-11).
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
                                      \SIrange, \index (GV-116, SC-77);
                                      \footnote{…} en un título (SC-86);
                                      o una de ellas incompleta (GV-124)
    latex_suelto              error   una orden de LaTeX sola entre párrafos,
                                      fuera de ::: espaciov
    html_crudo                error   HTML escrito en el .md, menos los
                                      comentarios <!-- … -->
    corte_fuera_de_titulo     error   \\ fuera de un título: sale como una
                                      barra (SC-63); para un salto, espaciov
    porcentaje_suelto         aviso   88% o 88 % escrito suelto (SC-64, SC-65)
    cifra_fuera_de_num        aviso   una cifra con punto o coma de miles fuera
                                      de \num (SC-64, SC-65)
    nota_doble_en_titulo      error   más de una nota en un título de sección,
                                      numerada o con símbolo (SC-29, SC-86,
                                      GV-190)
    [WARNING] de pandoc       aviso   entre ellos, nota definida y nunca llamada

`definicion_sin_texto` lee el archivo fuente (`PANDOC_STATE.input_files`) porque en el AST el caso ya no existe (GV-99), y saltea los bloques de código cercados con ``` o ~~~. Una definición de nota vacía al final del archivo la informan dos controles, `definicion_sin_texto` (con la línea) y `nota_vacia`: es el mismo error.

IMÁGENES

Se controla cada nodo `Image` del .md, suelto o dentro de un `::: fig`, contra la raíz del proyecto que recibe el filtro (`gb-proyecto`): las rutas se escriben relativas a ella (`media/fig-mapa.png`, SC-32). El nombre se compara exacto, con mayúsculas. Una dirección con esquema (`http:`, `https:`, `data:`) no es un archivo del proyecto y se saltea. Fuera de `media/` es error aunque el archivo exista, porque el EPUB y el HTML solo copian `media/`. NO se controla lo inverso: que `media/` tenga imágenes que ningún .md usa es normal (la tapa, los logos, figuras que se sacaron del texto). Decisión de Alberto.

COMILLAS

`comillas_desbalanceadas` aplica el mismo criterio que `guillemets-to-quoted-db.lua`, que es el que decide si arma la cita o deja los caracteres literales: cada lista de inlines se mira sola, solo cuentan los « » de sus `Str` directos, y está mal si un » cierra sin nada abierto o si al final queda un « abierto. Así el aviso coincide con lo que el filtro de producción no pudo resolver, incluida su limitación (`«un *texto» citado*` no cierra en ninguna de las dos listas). Si cambia el criterio del filtro, cambia el control. Verificado: sobre el mismo .md, los dos marcan las mismas cuatro listas.

El filtro de producción sigue escribiendo su mensaje por stderr porque revistas, que todavía no pasa por los controles, depende de él. En libros, `generar_canonicos_capitulos.sh` lo omite en la conversión: ya lo informó el control.

LaTeX Y HTML CRUDOS

Lo que Pandoc lee como LaTeX o HTML crudo se pierde en las tres salidas: los escritores de XML lo descartan sin aviso (GV-116). Decisión de Alberto: los tres controles son `error`, y por ahora solo en libros, como los demás (pendiente 1).

- En el texto, las órdenes de LaTeX admitidas son `\sptext{…}`, que traduce `volada.lua` (SC-62), `\num`, `\SI` y `\SIrange`, que traduce `cifras.lua` (SC-65), y `\index[…]{…}`, que traduce `indice.lua` (SC-77); su forma la valida cada filtro y no este control. `\index` se admite también sin el nombre del índice: lo frena `indice.lua`, con el mensaje de cómo se escribe. El texto de la orden se escribe en el informe sin saltos de línea: puede traerlos (GV-124). El mensaje nombra la orden y muestra el contexto con el texto crudo a la vista: `stringify` lo descarta, y sin eso quedaban huecos.
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

**Relaciones:** vinculo:SC-53,vinculo:SC-46,vinculo:SC-11,vinculo:SC-13,apoya:GV-99,vinculo:SC-30,vinculo:SC-32,vinculo:GV-116,vinculo:SC-62,vinculo:SC-39,vinculo:SC-63,vinculo:SC-65,apoya:GV-124,vinculo:SC-75,vinculo:SC-77,vinculo:SC-86

**PENDIENTE:** (1) Revistas: usar el mismo filtro, con los controles de LaTeX y HTML crudos, cuando su cadena se migre a engine/ (SC-13); entonces sacar el mensaje de comillas de guillemets-to-quoted-db.lua, que hoy queda solo por revistas. (2) Probar en Mint con un libro real los controles de notas, imágenes y comillas.

### SC-55 — Orden de los finales: la bibliografía antes de los índices, el colofón último; aviso en el ABM, freno en el PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.19 (gbc3, gbs3) / contenedor Ubuntu / MySQL 8.0.46 · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto). Libros, salida PDF. El orden de las piezas sale del nombre de archivo (SC-44), y hay errores de orden en los finales que compilan sin fallar y dan un libro equivocado. Esos se controlan; el resto del orden de los finales no.

EL CASO QUE LO ORIGINÓ

Un libro de autor con bibliografía consolidada sacó el índice de autores antes de la bibliografía. Con bibliografía por capítulo no se ve: cada pieza trae la suya y el índice después del último capítulo es lo correcto. Dos caminos llevan al error:
- La bibliografía consolidada sin pieza declarada: `ArmarInsumosLaTeX` (apartado 8) emite `\printbibliography[heading=bibintoc]` al final, después de TODAS las piezas declaradas, índices incluidos.
- La pieza declarada pero numerada después del índice (`bm-20-INDICE-AUTORES`, `bm-21-REFERENCIAS`).

LAS REGLAS

La función es `m_PiezasLibro.ProblemaOrdenFinales(aNombre, aTipo, bConsolidada)`: recibe las piezas en el orden del libro y devuelve vacío o el mensaje del PRIMER problema, con qué está mal y cómo corregirlo.
- R1. Ningún `indice_*` (onomastico, concepto, autores) antes de la pieza `bibliografia`. Si hay más de una, manda la primera, como en el EPUB.
- R2. Bibliografía consolidada, sin pieza `bibliografia` y con algún índice declarado: hay que declararla. Sin índices no se exige: el respaldo del apartado 8 da el orden correcto y los libros anteriores siguen compilando.
- R3. Si hay pieza `colofon`, es la última.

No se controlan `glosario`, `sobre_autores` ni `cronologia`: su lugar es tradición editorial, no error, y una regla rígida frenaría libros bien compuestos.

LAS ZONAS NO VUELVEN ATRÁS (1.18.0)

Independiente del tipo de cada pieza: en el orden del libro, ninguna puede obligar a volver a una zona anterior —preliminares, cuerpo, apéndices, posliminares—. `VerificarZonas` (m_GenerarPDFLibro, apartado 2b de `ArmarInsumosLaTeX`) frena antes de escribir nada y dice qué pieza está después de cuál. Sin el control, el recorrido del main.tex emitía otra vez `\frontmatter` o `\mainmatter` y el folio se reiniciaba sin aviso (GV-164): un prólogo nombrado `bm-` salía con folio romano después de los índices. La zona sale de `ZonaDePieza`, que es la del tipo salvo la lista de siglas, que va donde dice su prefijo (SC-78).

POR QUÉ UN SEMÁFORO

Es una regla del LIBRO, no de una pieza, y por eso no va en `ProblemaPosicion` (la de la dedicatoria, que con el nombre de la pieza alcanza). Al renumerar dos piezas hay un estado intermedio inválido que no se puede evitar; un freno al guardar obligaría a pasar por un nombre provisorio.
- Amarillo: `m_Metadatos.GuardarMetadatosDeCapitulo` (apartado 7), DESPUÉS de guardar, lee todas las piezas con nombre del libro abierto en el orden de `m_OrdenPiezas.ClausulaOrden` (`ProblemaOrdenLibroAbierto`) y muestra `Message.Warning`. Un fallo de lectura no se informa: el aviso es ayuda.
- Rojo: `m_GenerarPDFLibro.ArmarInsumosLaTeX` (apartado 2b, después de `VerificarPosiciones`) frena con `Message.Error` antes de escribir nada.

La regla está escrita una sola vez, en `m_PiezasLibro`; los dos lugares la llaman.

CÓDIGOS REPETIDOS

Dos piezas con el mismo código de posición (`bm-20-INDICE-AUTORES` y `bm-20-REFERENCIAS`) quedan ordenadas por el resto del nombre, alfabéticamente, y no por el número: el orden puede salir bien por casualidad. Vale para TODO el libro —preliminares, cuerpo y finales— y para todas las salidas, porque todas ordenan por nombre (SC-44).

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

**Relaciones:** vinculo:SC-44,vinculo:SC-45,vinculo:RC-GM-17,vinculo:SC-20,vinculo:GV-102,vinculo:SC-78,apoya:GV-164,vinculo:SC-104

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

Gambas, en un solo lugar: `m_GenerarSalidasLibro.PrepararCitasPantalla`. Si el estilo tiene archivo de pantalla, `RutaRecursos()/latex/cita-<estilo>-html.tex` (SC-11), el modo es `tex4ht`: escribe los insumos de la pasada (`m_GenerarPDFLibro.EscribirInsumosCitas`: la lista de piezas, `tmp/citas-proyecto.tex` y el `.bib`, con las mismas funciones que el PDF) y pasa el modo a `generar_html_libro.sh` y a `generar_epub_libro.sh`. Si no lo tiene, el modo es `xslt` y siguen las plantillas por estilo de las hojas. Los scripts reciben el modo y no lo vuelven a decidir.

Un estilo sin archivo de pantalla y sin plantillas en la hoja (hoy, cualquiera fuera de apa, iso690, ieee y vancouver) corta el HTML y el EPUB. Antes caía en un autor-año genérico que no es el del PDF.

LAS PIEZAS

1. `docbook-to-latex-citas.xsl`. Importa la hoja del PDF y sobrescribe solo la plantilla de pieza: escribe los mismos `refsection` que el PDF y cada grupo de citas como `\gbcita{id}{comando}`, con el comando que arma la plantilla de `biblioref` del PDF. Así las citas son las del PDF por construcción. Una cita de una nota va dentro de `\footnote`. Antes de `\gbImprimirBibliografia`, la marca `\gbbibliografia{sección-orden}`.
2. `cita-comun.xsl`. La regla del agrupamiento de citas (`gbct:grupo-desde`, `gbct:es-continuacion` y sus auxiliares), `gbct:comando-cita` (era `f:comando-cita` de `tex-comun.xsl`) y el id de cada grupo (`gbct:id-cita`). La incluyen el PDF, la pasada de citas y las hojas de HTML y EPUB: una sola regla. El estilo llega como parámetro explícito y no como variable global. Medido: los `.tex` del PDF de Duek salen idénticos byte a byte después de la mudanza.
3. `engine/preparar_citas_libro.sh`. Corre la hoja de citas por pieza, arma el documento mínimo `citas.tex` y lo compila con make4ht. Verifica el producto: XML bien formado, sin errores de biber, una marca `gbcita-` por cada `\gbcita` y una `gbbib-` por cada bibliografía. Salida: `tmp/bib/html-libro-<nombre>` y `tmp/bib/epub-libro` (carpeta fija: el proyecto tiene un solo EPUB, y el nombre de su archivo puede llevar espacios). `referencias/` queda para los datos canónicos.
4. `cita-fragmentos.xsl`. La lectura de `citas.html` para las hojas de HTML y EPUB: declara el parámetro `bib_dir`, busca cada grupo por su id y cada bibliografía por su marca, y copia el marcado a la salida en el espacio de nombres de XHTML. Cada hoja define la plantilla `gbct:enlace-cita`, porque el enlace de una cita no es igual en HTML (panel) y en EPUB (href).
5. `docbook-to-html.xsl` Y `docbook-to-epub.xsl`. Con `bib_dir`, el primer `biblioref` de cada grupo dibuja el texto de biblatex y los demás no emiten nada; el separador entre dos citas se suprime solo si la segunda quedó en el grupo de la primera (la regla del PDF). Las referencias son las que imprimió biblatex, en su orden, y cada una se une con su `biblioentry` por la clave: el `xml:id` es el destino de los enlaces. Sin `bib_dir`, la salida es la misma que antes (medido: idéntica byte a byte en las dos hojas).
6. EL CSS. `font-variant-caps: all-small-caps` para `.versalitas-todas` en `gbpublisher.css` y `gbpublisher-epub-libro.css` (SC-56). Sangría francesa: el EPUB ya la tenía en `.ref-item`; en el HTML va en `.ref-item.ref-biblatex`, solo para estas entradas, porque la hoja es común con revistas. Esas entradas van además en `--font-serif` (Noto Serif), la tipografía del texto, que trae `smcp` y `c2sc` (GV-104; decisión de Alberto).
7. EL SELECTOR DE ESTILOS lista los `cita-*-config.tex` de `RutaRecursos()/latex/` (SC-11), con la etiqueta de su primera línea (`% ESTILO: …`). `libros_md.estilo_cita` guarda el identificador (`apa`, `verona-modern`); la conversión de los `.csl` viejos la hace `actualizar-esquema-1.9.0.sh`.
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

El agrupamiento depende del estilo en un caso: `suppress` con afijos en un estilo numérico. El PDF y la pasada de citas transforman el canónico de cada pieza, que no traía el estilo: `docbook-to-latex.xsl` agrupaba siempre como `apa`. Desde este lote (decisión de Alberto, cuatro puntos):

1. `m_XML.GenerarInfoCapituloXML`, BLOQUE 2c, escribe `<bibliomisc role="estilo-cita">` (hasta el 29/10 se llamó `csl-style`, un nombre heredado de cuando el estilo era un `.csl`; se renombró como la columna `libros_md.estilo_cita`) en el `<info>` de cada pieza, con el `estilo_cita` de su libro: el mismo valor que el bloque 15 del canónico del libro (RC-XJ-02: el dato de la base va en el canónico, no por parámetro).
2. `ensamblar-libro-canonico.xsl` lo descarta al copiar la pieza, como los tres marcadores de ubicación: el libro lo trae una vez en su propio `<info>` (medido: uno solo en el canónico ensamblado).
3. `preparar_latex_libro.sh` y `preparar_citas_libro.sh` cotejan el `estilo-cita` de cada canónico con el `\estandar` del preámbulo o de las definiciones (`estilo_canonico`, en `comun.sh`). Si falta o no coincide, la pieza falla con «el canónico declara el estilo «…» y el libro usa «…»: regenerá el canónico». Así un cambio de estilo sin regenerar no compone con un estilo y agrupa con otro. HTML y EPUB por las plantillas de la hoja agrupan con el estilo que pasa Gambas, que es el de la base; por tex4ht, la pasada de citas ya cotejó.
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

REVISTAS (14/11/2026). El mismo camino, sobre el canónico JATS: `jats-a-latex-citas.xsl` (importa la hoja del PDF del artículo y escribe cada grupo como `\gbcita{archivo-n}{comando}`, con la regla de agrupamiento de `cita-jats-comun.xsl`, la misma del PDF), una `refsection` por artículo con su bibliografía, y el «cómo citar» como `\gbcita{archivo-comocitar}` en una `refsection` aparte. `engine/preparar_citas_revista.sh <proyecto> <bib> <carpeta>` lo junta para todo el número desde el volcado y verifica las marcas. Los cinco estilos de revista tienen versión de pantalla: Vancouver por biblatex-vancouver, con `cita-vancouver-html.tex` (la etiqueta «1.», GV-203). Medido con los cinco (mini-test E0): las citas de make4ht son las del PDF. Las hojas del EPUB y del HTML de revista (SC-91, SC-92) toman de `citas.html` las citas, las referencias y el «cómo citar».

**Relaciones:** vinculo:SC-14,vinculo:SC-56,vinculo:SC-31,vinculo:SC-42,vinculo:RF-12,vinculo:GV-102,apoya:GV-23,vinculo:GV-103,vinculo:GV-104,vinculo:SC-58,vinculo:GV-105,vinculo:RF-13,vinculo:RF-14,vinculo:SC-59,vinculo:SC-72,vinculo:SC-89,vinculo:SC-91,vinculo:SC-92,apoya:GV-203

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

ESTADO (act-46). IEEE va por tex4ht y las comillas salen de biblatex. Las plantillas por estilo de las hojas (las que leen el título con normalize-space y pierden las comillas de un <quote>) solo quedan para un libro sin la pasada de citas. Probado por Alberto en Mint con APA: las tres salidas y los tres controles. Medido en el contenedor con Verona: \sptext y \emph bien en el PDF y en tex4ht.

LÍMITE CONOCIDO: \sptext es de babel-spanish. Un libro cuyo idioma principal no sea el español no lo tiene definido.

**Relaciones:** vinculo:SC-57,vinculo:SC-30,vinculo:SC-14,apoya:GV-23,vinculo:SC-62

### SC-59 — Cadenas en castellano comunes a todos los estilos de biblatex: cita-cadenas-es.tex

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biblatex-philosophy / biblatex-apa / biblatex-iso690 v0.4.1 / biblatex-ieee v1.3f / LuaLaTeX / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Las cadenas de biblatex se reparten en dos clases (decisión de Alberto, 17/10):

A. LAS QUE NI biblatex (`spanish.lbx`) NI EL ESTILO TRAEN. Son la traducción de los códigos del catálogo de la aplicación (tabla `cmb_biblatex`: `editor_type`, `thesis_type`, `pubstate`) y los agregados de la editorial (cine, `\sq`, `\sqq`, `documentjob`, `origpubbare`). Van en `.hidden/latex/cita-cadenas-es.tex`, uno solo para todos los estilos. Una cadena así solo aparece si una entrada la usa: en un estilo que no la necesita no cambia nada.

B. LAS QUE `spanish.lbx` YA TRAE Y UN ESTILO REDEFINE (meses, `url`, `urlseen`, `phdthesis`, `compiler`, `nodate`…). Son decisiones de cada estilo y quedan en su `cita-<estilo>-config.tex`. MEDIDO: las de Verona aplicadas a IEEE cambian «comp.» por «compilador», «dirección:» por «recuperado de:» y «oct.» por «octubre».

Las cadenas propias de un estilo (`presentedat` y `patentjp` de IEEE, RF-14) van en su config.

QUIÉN LO CARGA

El que carga el estilo, inmediatamente después de `cita-<estilo>-config.tex` (`\NewBibliographyString` exige biblatex cargado): `preambulo-contrato.tex` (PDF de libros) y el documento mínimo de `preparar_citas_libro.sh` (pasada de tex4ht), por nombre; `m_XML.ObtenerPreambuloEmbebido` (revistas), con ruta absoluta. No lo carga el config: `\input` resuelve contra la carpeta de la compilación, no contra la del archivo que lo pide, y en revistas el config se carga por ruta absoluta desde otra carpeta. Sin biblatex (vancouver, que va por bibtex) el archivo termina sin definir nada.

Llega al proyecto con `CopiarRecursosLatex`, que copia todos los `.tex` de los recursos del paquete, `RutaRecursos()/latex/` (SC-11); `preparar_citas_libro.sh` lo copia a la carpeta de la pasada y corta si falta.

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

CADENAS

`alinear.lua` corre justo después de `espacio-vertical.lua` en las dos: `generar_canonicos_capitulos.sh` (libro, antes de `fenced-divs-to-elements-db.lua`), y `FILTROS_REVISTA` de `engine/comun.sh` (revista, después de `unwrap-structural-divs.lua` y antes de `cite-to-xref.lua`). Antes, la revista en `m_XML` y el ODT en `m_GenerarODT`, retirados (SC-96, SC-98).

ANÁLISIS DEL PROYECTO

`m_AnalizarProyecto.Destino` dejaba fuera de los conteos todo el grupo `composicion`. El texto de un bloque de alineación es cuerpo. Ahora decide por el modo del catálogo: `envolver` es cuerpo, el resto (`separador-valor`, `espaciov`) no se cuenta (SC-38).

CATÁLOGO

Tres filas de gbShortcodes, grupo `composicion`, modo `envolver`, después de `espaciov`.

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de libro y de revista, incluidos los casos que frenan; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, `docbook-to-latex.xsl`, `jats-to-latex.xsl`, `jats-to-html.xsl`, `jats-to-epub.xsl`, `jats-to-scielo.xsl` y `jats-to-redalyc.xsl`; el capítulo valida contra el RNG de DocBook 5.2 y el artículo contra la DTD Archiving 1.4; el cuerpo del .tex compila con LuaLaTeX en la clase book y se ve alineado (no con el preámbulo del proyecto); gbpublisher compila con gbc3 3.19.

PROBADO EN MINT

Alberto, 21/10, con un libro y una revista reales: las tres alineaciones, con negrita, bastardilla, una referencia y una nota al pie que lleva otra referencia, junto a `espaciov` y al froufrou. PDF: cada párrafo en su lugar, sin sangría; un párrafo centrado pasa bien de página; la nota sale justificada y con corte, como cualquier otra (GV-114). HTML y EPUB: el párrafo común, a la izquierda y con la separación de los párrafos.

**Relaciones:** vinculo:SC-38,vinculo:SC-39,vinculo:SC-33,vinculo:SC-34,vinculo:SC-49,vinculo:GV-113,vinculo:GV-114,vinculo:GV-115

**PENDIENTE:** Sin confirmar en Mint: la inserción desde el panel, el conteo de m_AnalizarProyecto y el mensaje de un caso que frena (probados solo en el contenedor, los casos que frenan). Las hojas de HTML y EPUB de libros no se corrieron sueltas en el contenedor; en Mint salieron bien.

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

CADENAS

`volada.lua` corre antes de todo filtro que serialice con `pandoc.write`, que la descartaría (GV-116). Libro: segundo, después de `guillemets-to-quoted-db.lua` y antes de `cite-to-biblioref-db.lua`, que serializa las notas. Revista: después de `alinear.lua` y antes de `cite-to-xref.lua`.

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

### SC-63 — Corte de línea en los títulos de sección del .md: \\, como en la base

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / LuaLaTeX (TeX Live 2023) / titlesec / hyperref / qpdf / gbc3 3.19 / contenedor Ubuntu 24.04; gbpublisher en Linux Mint (prueba de Alberto, 21/10) · **Verificado:** 2026-11

DECISIÓN CERRADA (decisión de Alberto, 21/10). La regla de SC-28 vale también para los títulos de sección que se escriben en el .md (`##` y siguientes en libros; todos los niveles en revistas): el editor marca el corte con `\\` y el corte se cumple solo en la apertura del PDF.

    ## Corte de\\ subtítulo

En el sumario, el folio, los marcadores, el HTML, el EPUB y los indexadores, el corte es un espacio. En libros el `#` del .md no llega al canónico: el título del capítulo sale de la base y ya tiene su regla (SC-28).

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

- `docbook-to-latex.xsl`: una plantilla para `processing-instruction('gb-corte')` escribe `\gbCorteSeccion` en la apertura y nada en el sumario. Los títulos que vienen de la base no pasan por ella: los arman `f:titulo-compuesto` y `f:titulo-plano`, con `\gbCorteTitulo`.
- `jats-to-latex.xsl`: `sec/title/break` hace lo mismo. La plantilla general de `break` escribe `\\` sin mirar el contexto, y en un título habría ido también al sumario y a los marcadores.

`\gbCorteSeccion` es `\newline` (contrato 23 del libro, 11/11/2026). Hasta entonces la hoja escribía `\gbCorteTitulo`, que es `\\`: en la forma `hang` de titlesec, con `\raggedright`, `\\` termina el párrafo del título, y la segunda línea caía debajo del número (GV-192). Con `\newline` queda alineada con el texto del título, como cuando LaTeX lo parte solo: lo que da la composición en LaTeX (decisión de Alberto). `\gbCorteTitulo` sigue siendo `\\` para los títulos centrados que vienen de la base. En el preámbulo de la revista, `jats-to-latex` sigue escribiendo `\gbCorteTitulo` (ver el pendiente).

MEDIDO: el .tex compila con LuaLaTeX, titlesec (`newlinetospace`) y hyperref, sin errores ni avisos. La apertura corta en dos y en tres líneas; el sumario y los marcadores (leídos con qpdf) salen en una línea. Con una nota en el título (SC-29) y una volada (SC-62), también.

HTML, EPUB E INDEXADORES

`jats-to-html` y `jats-to-epub` no tienen plantilla para `break`, y la regla incorporada no escribe nada para una instrucción de procesamiento: sale «Corte de subtítulo». `jats-to-scielo` y `jats-to-redalyc` (retiradas el 18/11/2026, SC-97: los paquetes salen de `jats-a-scielo` y `jats-a-marcalyc`, que importan `jats-a-epub-articulo`) quitaban `sec/title/break` con una plantilla vacía. No usan `normalize-space`, como en el `article-title` de SC-28, porque un título de sección puede llevar bastardilla.

CADENAS

`corte-titulo.lua`, justo después de `volada.lua` en las dos: libro, tercero, antes de `cite-to-biblioref-db.lua`; revista, antes de `cite-to-xref.lua`.

VERIFICADO EN EL CONTENEDOR

Pandoc 3.1.3 con las cadenas reales de libro, revista y ODT, incluidos los casos que frenan; SaxonJ-HE 12.5 con `ensamblar-capitulo-canonico.xsl`, las dos hojas LaTeX, HTML, EPUB, SciELO y Redalyc; el capítulo valida contra el RNG de DocBook 5.2 y el artículo contra la DTD Archiving 1.4; gbpublisher compila con gbc3 3.19.

EN EL PANEL

Desde el 11/11 (decisión de Alberto) el corte está en el panel de shortcodes, en las marcas en línea del grupo composición: `corte-titulo`, modo `marca` (gbShortcodes `datos-v5-023.sql`, en borrador). Se escribe como en LaTeX: pegado a la palabra anterior y con un espacio antes de la siguiente, `Hola\\ mundo`. Por eso la fila tiene apertura `\\` y cierre un espacio, y el panel los inserta juntos en lugar de los espacios que rodean al cursor: «Hola |mundo» y «Hola| mundo» dan «Hola\\ mundo», con el cursor antes de «mundo». El modo `marca` es un dato de la tabla `modos` (RF-11): no hubo migración del esquema.

Antes de insertar, `m_Shortcodes.InsertarMarca` mira la línea del cursor y, si no corresponde, avisa y no inserta: con una selección; fuera de un título ATX (uno a seis `#` y un espacio al comienzo de la línea); en un libro, en el `#` del capítulo; al principio o al final del título (después del corte tiene que seguir texto, no los atributos `{#id}` ni los `#` de cierre); dentro de una palabra; pegado a otra barra. Un corte dentro de una bastardilla o una negrita lo sigue frenando `corte-titulo.lua` al generar.

MEDIDO en el contenedor (gbc3 y gbx3 3.19): `InsertarShortcode` real, con un doble del editor, en veinte casos de libro y de revista: las inserciones dan `Hola\\ |mundo` (también con varios espacios, con un corte previo en el título, en la segunda línea del texto y con letras acentuadas); los demás avisan con su motivo. Lo que inserta el panel pasa por `corte-titulo.lua` (Pandoc 3.1.3) a `<break/>` y `<?gb-corte?>`. `datos-v5-023.sql`, aplicado con `importar_shortcodes.sh` sobre una copia de la base.

PROBADO EN MINT

Alberto, 21/10, con un libro y una revista reales: el PDF corta en la apertura del título de sección; el HTML y el EPUB, sin corte.

Alberto, 11/11, en un libro: el corte escrito a mano y el insertado desde el panel. El PDF corta; el HTML y el EPUB salen de corrido. Desde el panel, una inserción en un título de sección y dos avisos: con el cursor en un párrafo y con una palabra seleccionada. La fila sigue en borrador hasta probarla en una revista (gbShortcodes `datos-v5-024.sql`).

Alberto, 11/11, en el mismo libro, con el arreglo de GV-192 (contrato 23): la segunda línea del título de sección queda alineada con el texto del título en el PDF; el HTML y el EPUB, sin cambios. Liberado para libros con gbShortcodes `datos-v5-026.sql`. En revistas, la fila queda `no_aplica` hasta la refactorización del módulo de revistas, que la retoma (decisión de Alberto, 11/11).

**Relaciones:** vinculo:SC-28,vinculo:SC-29,vinculo:SC-39,vinculo:SC-54,vinculo:SC-62,vinculo:GV-121,vinculo:RF-11,vinculo:SC-34,vinculo:GV-192

**PENDIENTE:** Falta en Mint, en libros: un caso que frene en la conversión (corte al final, dos seguidos o dentro de una bastardilla), el control corte_fuera_de_titulo y los avisos del panel que no se vieron (# del capítulo, al principio, al final, dentro de una palabra, pegado a otro corte). Revistas, en la refactorización del módulo (otra conversación): `jats-to-latex.xsl` escribe `\gbCorteTitulo` en `sec/title/break` y la segunda línea cae debajo del número (GV-192), se corrige con `\gbCorteSeccion` como en el libro; después, la fila corte-titulo pasa de no_aplica a borrador y se prueba en una revista.

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

IMPLEMENTACIÓN del lote 1 de SC-64: las cifras y las cantidades en el texto, con `\num`, `\SI` y `\SIrange`, en el libro y la revista (y el ODT, retirado: SC-96). Las decisiones de diseño (a)–(g) son de Alberto (22/10).

LA CADENA

El filtro `cifras.lua` corre en las tres cadenas antes de todo filtro que serialice con `pandoc.write`: sin él, el escritor descarta la orden y la cifra se pierde (GV-116).

    libro     4.° de la lista de generar_canonicos_capitulos.sh: después de
              corte-titulo, antes de cite-to-biblioref-db
    revista   m_XML.GenerarBodyXML: después de corte-titulo, antes de recuadros
              y de cite-to-xref

EL CANÓNICO (decisión a)

El elemento lleva el texto ya formateado, y la entrada tal como se escribió va en un atributo, la ficha:

    JATS     <named-content content-type="cantidad" specific-use="SI 2.5 kilo metre per hour">2.5 km/h</named-content>
    DocBook  <phrase role="cantidad" remap="SI 2.5 kilo metre per hour">2.5 km/h</phrase>

La ficha es la orden y sus argumentos separados por espacios, con las unidades sin barra: `num 1500`, `SI 88 percent`, `SIrange 50 51 degree`. Sin LaTeX en el canónico (SC-38). Validado: `named-content` en `p`, `title`, `td` y `caption` contra la DTD de JATS 1.4; `phrase` con `remap` contra el RNG de DocBook 5.2.

EL PDF

`f:cifra-latex` (`tex-comun.xsl`) rearma la orden desde la ficha, y frena si la ficha no es una de las conocidas. Las plantillas están en cada hoja, no en `tex-comun` (GV-117): `phrase[@role=''cantidad'']` en `docbook-to-latex.xsl` y `named-content[@content-type=''cantidad'']` en `jats-to-latex.xsl`. En el argumento opcional de un título va dentro de `\texorpdfstring`, con el texto formateado para el marcador (GV-118).

El `\sisetup` de SC-64 y `\DeclareSIUnit\euro{€}` están en el contrato del libro (`preambulo-contrato.tex`, versión 15; `CONTRATO_VERSION = 15` en `m_GenerarPDFLibro`) y en el preámbulo de la revista (`m_XML`), con los mismos valores.

EL HTML Y EL EPUB

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

**PENDIENTE:** El cambio de idioma por capítulo en el PDF del libro, que no existe (ver LO QUE NO CUBRE), cuando se encare; con él, probar un capítulo en inglés con \SIrange. La revista en Mint, con la fase de salidas que le corresponde.

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

- `cuadro-leer.lua`, PRIMERO en las dos cadenas: trae el archivo (con `-M gb-proyecto`), controla el encabezado y la tabla, y deja un Div `.cuadro` con las decisiones en sus atributos, el título, la nota y la tabla. Así el contenido pasa por todos los filtros: comillas, volada, cifras, citas. Una cifra sola en una columna de cifras pasa a `\num{…}`, que traduce `cifras.lua` (SC-65). Frena el viejo `::: {.table}`.
- `cuadro-armar.lua` escribe el cuadro: en libros, antes de `fenced-divs-to-elements-db.lua`; en revistas, después de `cite-to-xref.lua`. Lo escribe el filtro y no Pandoc porque el escritor DocBook pierde las celdas unidas (GV-126) y ninguno lleva la nota ni las decisiones.
- `table-to-end.lua` sale de la cadena de la revista: solo marcaba el viejo `.table`. El archivo se borró el 18/11/2026 (SC-97).

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

- Gambas escribe lo que sale de la base, `tmp/vista-cuadro/preambulo-vista.tex`: en libros, las capas del `main.tex` con `\gbshowframetrue` y sin `preambulo-hyperref` (el contrato se engancha a hyperref con `\AddToHook{package/hyperref/after}` y no lo necesita; la capa registra el .bib, que el cuadro solo no usa): `m_GenerarPDFLibro.PreambuloVistaCuadro`. En revistas, el del PDF VIEJO en borrador (`m_XML.ObtenerPreambuloEmbebido`, y no el de capas del PDF nuevo: pendiente en SC-98), sin el .bib y sin `\begin{document}`: `m_XML.PreambuloVistaCuadro`. La revista CONSERVA hyperref: va embebido a mitad del preámbulo y seguido de `\pdfstringdefDisableCommands`. El estilo de cita lo lee `m_XML.EstiloCitaRevista`, de `revista.estilo_cita` desde el 18/11/2026 (antes, de la tabla vieja `revistas_md`; la usaba también `m_GenerarPDF`, retirado: SC-98).
- `engine/vista_cuadro.sh` (SC-13, lanzado por `m_Lanzadora.EjecutarScript`, SC-53) hace el resto: el .md mínimo que nombra el cuadro, pandoc con la cadena de la pieza (`FILTROS_LIBRO` y `FILTROS_REVISTA` en `comun.sh`; la de libros la usa también `generar_canonicos_capitulos.sh`, la de revistas es gemela de `m_XML.GenerarBodyXML`), Saxon con `vista-cuadro-libro.xsl` o `vista-cuadro-revista.xsl` (importan la hoja del PDF y solo cambian la raíz), una pasada de LuaLaTeX y el veredicto. El idioma es el de la pieza abierta en el editor.
- EL VEREDICTO (`veredicto.txt`, una línea por hallazgo, `nivel<TAB>mensaje`): por tramo, el ancho y el alto contra la caja, en milímetros (info); un tramo más ancho o más alto que la caja, una celda que se sale de su columna, «Float too large» (el alto con el pie) y un error de LaTeX en el cuadro: error. Un error de LaTeX del preámbulo: aviso, porque no es del cuadro y sale igual en el PDF de la pieza. Las medidas las toma `engine/vista_cuadro_medir.lua` (GV-128): en el libro, linebreaker calla los Overfull y el .log no las daría. Código 0, el cuadro entra; 3, hay observaciones; 1, no salió el PDF, con el motivo del filtro que frenó también en el veredicto.
- El formulario muestra el veredicto y abre `vista.pdf` con el visor del sistema (`Desktop.Open`, sin espera).

LO QUE LA VISTA NO DICE: la paginación real (los tramos caen donde caen junto al texto de la pieza) y el número del cuadro (sale «Cuadro 1»).

SE RETIRAN las filas `table-wrap`, `table-fullwidth` y `table-landscape` de gbShortcodes (`datos-v5-018`): las reemplazan el archivo del cuadro y este formulario.

MEDIDO en el contenedor (gbc3 3.19, LuaHBTeX 1.17.0, Saxon-HE 12.5, pandoc 3.1.3): la vista de libro con el preámbulo que escribe Gambas, y la de revista con el de `ObtenerPreambuloEmbebido` reproducido desde el código (la función necesita FMain y la base); un cuadro que entra, uno más ancho que la caja (13,7 mm), uno más alto (174,2 mm), uno que se pasa solo con el pie (3,0 mm), una celda que desborda (20,3 mm), uno rotado y uno con `ancho: total`, y uno que frena en la cadena (`ancho: total` en un libro). El lector y el escritor sobre los cuadros de prueba: la ida y vuelta da el mismo texto; y siete casos que no encajan, cada uno con su motivo. El formulario bajo xvfb: la lista, la grilla, una grid table en texto, la edición de una celda con una barra, un corte por el menú, una fila insertada con los cortes corridos (también con la edición a medio escribir), guardar, la ida y vuelta grilla–texto, un archivo que no encaja e Insertar.

DE PASO: la revista ya tenía dos errores de LaTeX en su preámbulo, ajenos a los cuadros, que la vista muestra como aviso: «Command \theHpoemline already defined» (verse después de hyperref) y «biblatex Error: \chapter not provided by class» (`citereset=chapter` en `cita-apa-config.tex` con la clase article). Medidos en el contenedor; falta ver si salen igual en Mint.

**Relaciones:** vinculo:SC-66,vinculo:SC-64,vinculo:SC-13,vinculo:SC-53,vinculo:SC-15,vinculo:SC-18,vinculo:SC-20,vinculo:SC-06,vinculo:SC-33,vinculo:RC-GM-13,apoya:GV-127,apoya:GV-128,apoya:GV-129,apoya:GV-46,vinculo:SC-69

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
- Va SEGUNDO: después de `cuadro-leer`, que inserta el texto del cuadro, y antes de todo filtro que serializa. Está en FILTROS_LIBRO y FILTROS_REVISTA (`engine/comun.sh`); solo, sin los demás filtros, en `m_PrimerasLibro.ConvertirMarkdown`. También estaba en `m_XML.GenerarBodyXML`, `m_GenerarODT` y `m_GenerarEpub.ConvertirMdAXhtml`, retirados (SC-96, SC-98).
- `--abbreviations` en esos mismos lectores y en `vista_cuadro.sh`. La ruta está en `comun.sh` (`RUTA_ABREVIATURAS`) y en `m_Constantes` (`SUBRUTA_ABREVIATURAS`, con `SUBRUTA_FILTRO_ESPACIO_FIJO`). `generar_canonicos_capitulos.sh` y `vista_cuadro.sh` frenan si falta la lista.
- `cuadro-leer.lua` lee el archivo del cuadro con `pandoc.read`, pasándole solo la lista (GV-133).
- La lista viaja en `filters/` y se lee del paquete, como el filtro: `m_Constantes.SUBRUTA_ABREVIATURAS` y `SUBRUTA_FILTRO_ESPACIO_FIJO` sobre `RutaRecursos()` (SC-11).

LAS SALIDAS

- Canónico JATS o DocBook, HTML y EPUB: el carácter U+00A0.
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

**PENDIENTE:** Probar en Mint con un libro y una revista reales: el PDF (una cita con «p.~22» en la postnota), el HTML, el EPUB y las primeras; el aviso espacio_fijo_suelto al generar los canónicos.

### SC-69 — Gráficos: el archivo, el formulario y las salidas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chart.js 4.4.1 / Chromium 153 headless / Saxon-HE 12.5 / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto acepta las recomendaciones, 25/10). El formulario de los gráficos pasa a trabajar como el de los cuadros (SC-67): del proyecto y no del artículo, con el archivo como fuente y las decisiones guardadas en él. Reemplaza a FFiguras y FFigurasEditar.

POR QUÉ

FFiguras dependía del artículo abierto en el combo de revistas (no servía para libros), no guardaba ninguna decisión (tipo, paleta, leyenda), numeraba contando archivos —y «Generar» escribía el PNG con un número distinto del CSV cargado— y armaba el JavaScript pegando texto: una comilla en una etiqueta o un «s/d» en una celda cortaban el gráfico. La torta salía de un solo color y cortada, y la dispersión vacía (GV-134). En `jats-to-html.xsl`, el criterio `starts-with($nombre, 'fi')` tomaba también `fig-*`, el prefijo de toda figura (SC-32): en modo interactivo, cada figura común era un iframe a un archivo inexistente.

EL ARCHIVO DEL GRÁFICO

Cada gráfico vive en `graficos/fig-nombre.md`, en la raíz del proyecto como `cuadros/`, en libros y revistas. El nombre lleva `fig-` y letras sin tilde, cifras o guiones. Las salidas van a `media/`, porque el EPUB y el HTML solo copian `media/` (SC-32): `media/fig-nombre.png` y `media/fig-nombre.html`.

    ---
    tipo: barras        # barras | barras-h | lineas | area | dispersion | torta | dona
    paleta: Set2        # ColorBrewer; la clase (cualitativa, secuencial, divergente) sale del nombre
    leyenda: sí
    series: [1, 3]      (solo si se eligen)
    eje-x: 'Década'     (solo si hay)
    eje-y: 'Tesistas'   (solo si hay)
    unidad: '%'         (solo si hay)
    apilado: sí         (solo si sí; barras, barras-h y area)
    cero: no            (solo si no; por omisión el eje arranca en cero)
    proporcion: 16:10   # 16:9 | 16:10 | 4:3 | 1:1
    ---

    | Década | Capital | Interior |
    |---|---|---|
    | 1890 | 42 | 13 |

- Los textos van entre comillas simples, con la comilla duplicada, como en el cuadro (SC-67). La pipe table, sin alinear con espacios. Lee y escribe `m_Graficos`, con el lector y el escritor de filas de `m_Cuadros`.
- La primera columna son las categorías; en `dispersion`, la x, numérica. Cada columna siguiente es una serie y su encabezado, el nombre.
- `series`: las columnas de datos que se dibujan, contadas desde la primera serie. Sin la clave, todas. `torta`: exactamente una; con más de una serie en la tabla y sin `series`, frena. `dona`: una o más, en anillos concéntricos (GV-134); la leyenda no nombra los anillos, así que el pie de la figura lo tiene que decir.
- Los números, con punto y sin separador de miles (SC-64). Se leen con `CFloat` (GV-96, GV-137). Una celda vacía es un dato que falta: `null`, y la línea se corta ahí.
- Sin título ni texto alternativo: el pie y el `alt` son de la figura en el .md (SC-32). El título dentro de la imagen repetía el pie.

LAS SALIDAS

- EL HTML. `m_Graficos` lee y controla el archivo y escribe la descripción del gráfico con `JSON.Encode`, con `</` cambiado por `<\/` (GV-137), en `tmp/vista-grafico/fig-nombre.json`. Un texto vacío no queda en la `Collection` (GV-68): la clave no se escribe, y la plantilla toma como vacío lo que falta. `engine/grafico.sh` (SC-13, lanzado por `m_Lanzadora.EjecutarScript`, SC-53) llena los seis huecos de la plantilla —el id del gráfico para el `<title>`, el idioma, las dos fuentes en base64, Chart.js 4.4.1 entero y la descripción—. La lee de `$DIR_RECURSOS/chart/`: `.hidden/chart/` desde el IDE, `/usr/share/gbpublisher/chart/` instalado (SC-11). La plantilla declara `<meta charset>` antes de su comentario de cabecera: la codificación tiene que estar en los primeros 1024 bytes, y un `<title>` vacío no es HTML válido. El validador del HTML del libro revisa también los `fig-nombre.html` de `docs/assets/media/`, y así aparecieron las dos faltas (29/10/2026). Después, controla con `chromium --dump-dom` que la plantilla haya dibujado (GV-141). La configuración de Chart.js la arma la plantilla: las funciones de las marcas y del tooltip no pueden ir en JSON. Cada `fig-nombre.html` funciona solo: lleva Chart.js y la fuente.
- LA FUENTE. Noto Serif, la del HTML (decisión de Alberto). Un subconjunto latino en woff2, Regular y Bold, embebido como data URI (unos 32 KB): el iframe es otro documento y no hereda la fuente de la página, y el PNG se saca sin red. La plantilla dibuja después de `document.fonts.load` (GV-135). Los subconjuntos se generan una vez con el comando de GV-135 y viven en `.hidden/chart/`.
- LO QUE LLEVA EL GRÁFICO. Las cifras de las marcas, del tooltip y de la tabla de datos con las reglas de SC-64, como el formateador de `cifras.lua` (SC-65): punto decimal, grupos de a tres con U+202F desde cinco dígitos, menos U+2212, «× 10ⁿ» con volado; títulos de ejes; apilado; `beginAtZero` salvo `cero: no`; la unidad en las marcas, el tooltip y la tabla, separada de la cifra con U+202F salvo el grado de ángulo (SC-64); tooltip de todas las series a la vez; `pointStyle` y `borderDash` distintos por serie, para que se distingan impresas en gris; en `torta` y `dona`, un color por porción. En las paletas secuenciales se omiten los dos tonos más claros: sobre blanco no se ven.
- ACCESIBILIDAD. El canvas va con `aria-hidden` y, al lado, la tabla de datos, en un `div` fuera de la vista y legible por un lector de pantalla. La clase que la oculta va en el `div` y no en la tabla: una tabla no se achica y agrandaba el alto de la página (GV-144). No se usa `role="img"` en el canvas: en WAI-ARIA 1.2 el rol img vuelve presentacional lo que tiene adentro, y la tabla de respaldo se perdería.
- EL PNG. Chromium headless sobre el mismo HTML, 844 px de ancho por el alto de la proporción, a escala 3 (GV-139). Es el que va al PDF, al EPUB y al HTML en borrador. Se genera en `tmp/vista-grafico/` del proyecto y se copia a `media/`.

EN EL .md

El gráfico entra como una figura común, por el camino de `FMain.InsertarFigura` sin el diálogo de imagen (SC-32): `media/fig-nombre.png`, con el id `fig-nombre`. Las cadenas no cambian.

EN EL HTML

- `jats-to-html.xsl` y `docbook-to-html.xsl` deciden si una figura es interactiva por la existencia de `fig-nombre.html` junto al PNG: `unparsed-text-available()` sobre la ruta absoluta de `media`, que reciben como parámetro, armada con `encode-for-uri` por segmento (GV-136). Se retira `starts-with($nombre, 'fi')`.
- En borrador, siempre el PNG; en final, el iframe si existe el HTML. La pregunta PNG o Chart.js de `m_GenerarHTML` se retira: cada figura sabe si tiene versión interactiva. En libros no hay modo de control: el HTML del libro es de publicación, y cada gráfico con su HTML va en iframe.
- Las reglas viven en `grafico-comun.xsl` (`gbg:interactivo`, `gbg:proporcion`, `gbg:iframe`), que incluyen las dos hojas. En `docbook-to-html.xsl` el iframe sale en el espacio de nombres de XHTML (`xsl:element`), como el resto de esa hoja: un elemento literal de la hoja común saldría sin espacio de nombres.
- El iframe ocupa el ancho del contenedor con el `aspect-ratio` de la proporción, en lugar de 844×520 fijos; la hoja lee la proporción de la descripción que lleva el HTML («"proporcion":1.6»). Medido en Chromium a 1280, 800 y 390 px: el iframe mide lo que el gráfico. Sin respaldo adentro: HTML5 no muestra el contenido de un iframe. El panel de figuras toma la miniatura del atributo `data-png` del contenedor, porque con un iframe no hay imagen de donde tomarla.
- El EPUB sigue con el PNG.

EL FORMULARIO (FGraficos)

Con la disposición y la lógica de FTabla (SC-67). A la izquierda, los gráficos de `graficos/`, con Nuevo (una plantilla), Borrar y Duplicar. Tres pestañas:

- Datos: la grilla editable, con los menús de fila y de columna; la primera columna, la de las categorías, no se quita. Importar CSV llena la grilla desde un archivo: el CSV ya no es la fuente. El separador es el que más aparece en la primera línea (coma, punto y coma o tabulador); las celdas van tal cual: una cifra con coma decimal se señala al generar, no se adivina.
- Diseño: las claves del encabezado; `series`, en una lista de selección múltiple con los encabezados (GV-138).
- Vista: el gráfico en un WebView, con la URL codificada como en GV-141 (`m_Graficos.UrlDeArchivo`). Al abrir un gráfico muestra el último generado (GV-142).

Guardar, Vista previa, Generar, Insertar y Cerrar; se cierra solo por los botones (SC-20). Cambiar de gráfico, Insertar y Cerrar con cambios sin guardar preguntan: guardar, descartar o quedarse (SC-06). Insertar devuelve el id a FMain por `m_Graficos` (RC-GM-13), y FMain escribe el bloque de la figura con `BloqueFigura`, la misma función que `InsertarFigura`. Lo que se inserta es el PNG: si falta o es anterior al archivo, Insertar ofrece generarlo antes. Borrar quita el archivo y sus dos salidas, y avisa si alguna pieza nombra la figura. El retocador de imágenes (`m_GestionImagenes`) no lista los `fig-*` que tienen fuente en `graficos/`: se regeneran, no se retocan.

QUÉ FRENA AL GENERAR

Una clave desconocida o repetida; un valor fuera de la lista; `series` con una columna que no existe, repetida o fuera de orden; `torta` con más de una serie elegida; `apilado` en un tipo que no lo admite; una celda de datos que no es un número con punto ni está vacía, nombrando la fila y la columna; en `dispersion`, una x que no es número; una tabla sin series.

CORREGIDO EL 25/10 (act-68), al hacer la plantilla: la primera versión pedía `locale` con el idioma de la pieza, que da coma decimal y punto de miles y contradice SC-64; y pedía `role="img"` con la tabla adentro del canvas, que la oculta. Las dos cosas quedaron como se lee arriba.

SE RETIRARON (25/10) FFiguras.form/.class, FFigurasEditar.form/.class, la convención `fd/fi/fh` y la edición del CSV en LibreOffice.

IMPLEMENTADO (25/10), en cinco pasos: la plantilla y la fuente; `m_Graficos`, `CGrafico` y `engine/grafico.sh`; FGraficos y `FMain`; las dos hojas de HTML, `m_GenerarHTML` y `m_GestionImagenes`; el retiro de FFiguras. MEDIDO en el contenedor: el módulo con un banco de prueba (ida y vuelta, lo que no encaja, lo que frena, las cifras, el CSV, vista y generación en una carpeta con espacio, ñ y #); el formulario bajo xvfb; las dos hojas con Saxon; el HTML de revista en Chromium.

**Relaciones:** vinculo:SC-32,vinculo:SC-66,vinculo:SC-67,vinculo:SC-64,vinculo:SC-06,vinculo:SC-20,vinculo:RC-GM-13,vinculo:GV-53,vinculo:GV-96,vinculo:GV-129,apoya:GV-134,apoya:GV-135,apoya:GV-136,apoya:GV-137,apoya:GV-138,apoya:GV-139,vinculo:SC-65,vinculo:SC-13,vinculo:SC-53,apoya:GV-141,vinculo:GV-68,apoya:GV-142,apoya:GV-143,apoya:GV-144

**PENDIENTE:** Probar en Mint: el formulario, la vista previa y la generación en un libro y en una revista, y el HTML final con un gráfico en los dos. Confirmar en Mint: chromium con --force-device-scale-factor (GV-139), JSON.Encode, ListBox múltiple y WebView en 3.22.1 (GV-137, GV-138, GV-142).

### SC-70 — Un módulo por formulario o función principal

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 25/10). Cada formulario, o cada función principal de la aplicación, tiene su propio módulo. El formulario tiene los controles y los manejadores; el módulo, las consultas, las validaciones y las grabaciones.

- Un formulario nuevo nace con su módulo: `FDossiers` + `m_Dossiers`, `FMetadatosNumero` + `m_Numero`, `FMetadatosArticulo` + `m_Articulo`, la pestaña «Revistas» de `FSysAdmin` + `m_Revistas`, la subpestaña «Vocabularios» de `FSysAdmin` + `m_Vocabularios`.
- Un catálogo que usan varios formularios tiene su módulo propio, aunque ningún formulario sea suyo (`m_Licencias`, `m_Idiomas`, `m_Vocabularios`).
- Los datos que viajan juntos entre el formulario y el módulo van en una clase chica (GV-24): `CContribuyente`, `CTextosArticulo`.

Ya estaba aplicado caso por caso: SC-20 (`m_Ventana`), SC-21 (`m_Snippets`), SC-66 y SC-67 (`m_Cuadros`), SC-69 (`m_Graficos`). Esta entrada lo hace regla general.

**Relaciones:** vinculo:SC-20,vinculo:SC-21,vinculo:SC-66,vinculo:SC-67,vinculo:SC-69,vinculo:GV-24,vinculo:SC-103

### SC-71 — Revistas: la pirámide N0-N3 y el esquema nuevo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 25 a 28/10; documento de trabajo `claude/rediseno-revistas.md`).

PIRÁMIDE

- N0 Revista (permanente; `FRevistas`, que se abre desde la pestaña «Editorial» de `FSysAdmin`, `m_Revistas`). La editorial es la madre de sus revistas (SC-88). N1 Número (uno por proyecto `r-*.md`; `FMetadatosNumero`, `m_Numero`). N2 Artículo (`FMetadatosArticulo`, `m_Articulo`). N3 bloques opcionales que activa cada revista (patrón de OJS: desactivar / habilitar / solicitar / exigir).
- Revistas no comparte tablas con libros. Las tablas hijas se nombran para que `capitulos` pueda adoptarlas después.

CRITERIOS DE ESQUEMA

- Un campo existe solo si lo consume una salida, una validación o una decisión del flujo.
- Estructura completa, columnas mínimas: todos los niveles y las tablas hijas desde el principio. Las declaraciones (COI, ética, ensayo, datos) son filas de una tabla por tipo, no columnas.
- Esquema nuevo, no transformación del viejo: la 1.13.0 creó 23 tablas sin tocar las viejas (`revistas_md`, `articulos`, `articulo_autor`), que se retiraron en la 1.32.0 con `articulo_revisor` y el camino viejo (SC-98). El 2.0.0 fue el de `bibtex` (SC-102).
- Los catálogos se guardan por valor (SC-23): `contribuyente_credit`, `articulo_declaracion`, `articulo_palabra_clave`.
- «Sin dato» es NULL con `CHECK (<> '')` (GV-74, GV-147). Una clave única sobre columnas nulables se apoya en una columna generada (`numero.clave_identidad`, `articulo_palabra_clave.clave_vocabulario`).
- Las hijas del artículo caen en cascada con él; todo lo demás es RESTRICT.

REGLAS DEL FLUJO

- Herencia viva hasta publicar (decisión 14): mientras el artículo no está publicado, un campo vacío toma el valor de la revista (licencia, titular del copyright, tipo de acceso). Al publicar se congela el valor efectivo.
- Un artículo publicado es de solo lectura (decisión 17): el formulario lo bloquea y el módulo se niega a grabarlo. Reabrir exige un permiso y queda registrado con motivo obligatorio en `articulo_reapertura` (`FReabrirArticulo`, esquema 1.23.0, implementado el 7/11/2026). Al republicar se vuelve a congelar.
- Secciones por revista (decisión 15), con título por idioma, orden, article-type por defecto y plantilla de resumen. El artículo guarda su propio article-type: `subj-group-type="heading"` y `@article-type` se separan.
- El dossier es una agrupación dentro del número, no una sección (`numero_dossier`), con título por idioma y personas a cargo (`numero_contribuyente` con `id_dossier`). Se borra solo sin artículos.
- El número se vincula al proyecto al abrirlo: vincular y confirmar siempre. Volumen y número quedan de solo lectura con artículos consignados; la revista se cambia solo sin artículos.
- La lista de artículos sale de los `a-*.md` de `articulos/` cruzados con la base por nombre de archivo: «sin metadatos» y «huérfana» se muestran.

CADENA DE ESQUEMA (SC-22): 1.13.0 (las 23 tablas), 1.14.0 (NULL en vez de '', GV-74), 1.15.0 (ROR de la afiliación, GV-153, GV-154), 1.16.0 (vocabulario controlado, SC-74), 1.17.0 (dos términos CRediT a la forma de JATS4R), 1.23.0 (reapertura), 1.24.0 (modelo `por_articulo`), 1.25.0 (declaración de disponibilidad de datos), 1.26.0 y 1.27.0 (editorial, órganos y preliminares, SC-88), 1.28.0 y 1.29.0 (catálogos de CRediT y licencias por idioma y congelado al publicar, logo de la revista, SC-90).

**Relaciones:** vinculo:SC-22,vinculo:SC-23,vinculo:GV-74,vinculo:SC-72,vinculo:SC-73,vinculo:SC-74,vinculo:SC-70,vinculo:SC-87,vinculo:SC-88,vinculo:SC-89,vinculo:SC-90,vinculo:SC-102

### SC-72 — Revistas: las salidas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / decisiones de diseño · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 25/10; documento de trabajo `claude/rediseno-revistas.md`, decisiones 6 a 13). IMPLEMENTADA del 7 al 14/11/2026 (documento de trabajo `claude/salidas-revistas.md`): el canónico (SC-87), la editorial y las preliminares (SC-88), el PDF (SC-89), los catálogos comunes (SC-90), el EPUB (SC-91), el HTML autónomo (SC-92) y la pinza entre ellas (SC-93). Las salidas leen solo el esquema nuevo. El camino viejo se retiró el 18/11/2026, sin migración: sus números eran de prueba (SC-98).

- ORDEN: primero las salidas de lectura (PDF, HTML, EPUB, también del número completo); después los sabores XML, en el orden de necesidad real: JATS4R (que valida el canónico, no es un sabor), Crossref y DOAJ antes que PMC. Vancouver se resuelve en las salidas de lectura.
- CITAS: SC-57 llega a revistas. biblatex escribe las citas de HTML y EPUB por tex4ht; el estilo de cita es atributo de la revista y sale del catálogo `cita-*-config.tex`.
- REFERENCIAS: el texto formateado alimenta `mixed-citation` en los sabores (SciELO, PMC), no en el canónico, que queda como dato.
- IBID. Y OP. CIT. son presentación, no dato: el `.md` lleva siempre la clave. El PDF conserva la tradición y el HTML lleva citas autosuficientes (`cita-<estilo>-html.tex`).
- EL NÚMERO es un manifiesto interno que ordena los JATS de cada artículo. No se inventa un JATS de número.
- PAGINACIÓN: es un dato que nace en la composición y vuelve a la base. CORREGIDO al implementar (SC-89): no se compone el número para partirlo; cada artículo se compone solo, en el orden del número, y el PDF del número junta los de los artículos. Modelo de paginación como atributo de la revista, con cuatro modelos: por número, por volumen, por artículo y continuo (`elocation-id`), todos implementados.
- PROCESOS EXTERNOS: rigen SC-13 y SC-53. Gambas lee la base y la escribe como archivos (front del artículo, manifiesto del número, `.bib`); los scripts de `engine/` hacen el resto. Los generadores actuales de revistas en Gambas son deuda de migración: se reemplazan por scripts, no se adaptan.

**Relaciones:** vinculo:SC-57,vinculo:SC-13,vinculo:SC-53,vinculo:SC-71,vinculo:SC-87,vinculo:SC-88,vinculo:SC-89,vinculo:SC-90,vinculo:SC-91,vinculo:SC-92,vinculo:SC-93

**PENDIENTE:** Los sabores XML (Crossref, DOAJ, SciELO, Redalyc, PMC), con mixed-citation para PMC y SciELO. El HTML integrado al portal, cuando gbWeb publique el portal R-. Mini-tests que siguen abiertos: philosophy-verbose bajo make4ht y griego politónico.

### SC-73 — Editores con tablas hijas: memoria, una transacción y reemplazo entero

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.1 / MySQL 8.0.46 / Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 25 a 28/10). Patrón de los editores del rediseño de revistas (`FMetadatosNumero`, `FDossiers`, `FMetadatosArticulo`, `FPlantillasResumen`).

- Lo que tiene filas hijas (títulos por idioma, contribuyentes con afiliaciones y CRediT, resúmenes, palabras clave, secciones de una plantilla) se edita EN MEMORIA y se graba con el botón «Guardar», en la misma transacción que el registro principal: o se graba todo o nada.
- Las hijas se reemplazan enteras (DELETE + INSERT) dentro de esa transacción. Solo se borra lo que el editor muestra: un tipo de fila que el editor no edita no se toca (por ejemplo, los resúmenes al grabar los títulos traducidos).
- Si algo que se iba a reemplazar no se pudo leer, o la pestaña no puede mostrarlo entero, el guardado se bloquea y la línea de estado dice por qué. Grabar lo borraría.
- Un diálogo edita una COPIA del objeto (`CContribuyente.Copia()`) y el llamador conserva la referencia. Al aceptar (`Me.Close(1)`), la copia reemplaza al original; al cerrar, no queda nada. La instancia automática del diálogo se destruye al cerrarse.
- El módulo valida con las mismas reglas que el diálogo (una sola función de aviso, usada por los dos).
- Pestañas con nombre, una por bloque (decisión 19). Textos por idioma con un selector de idioma (decisión 20): lo escrito pasa a memoria al cambiar de idioma y antes de grabar.
- Un artículo publicado se abre para ver: los campos de texto quedan en solo lectura y no apagados, y el selector de idioma sigue vivo.

**Relaciones:** vinculo:SC-71,vinculo:SC-70,vinculo:GV-68,vinculo:GV-74,vinculo:GV-24,contracara:RC-GM-03

### SC-74 — Vocabulario controlado: catálogo global, búsqueda sin tildes, término e identificador por valor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 28/10; entrega C3 del rediseño de revistas).

- CATÁLOGO GLOBAL: `vocabulario_termino` (vocabulario, idioma, término, identificador), común a todas las revistas. Un término por vocabulario, idioma y término; un identificador por vocabulario e idioma.
- COLACIÓN: la columna del término usa `utf8mb4_0900_as_ci` (no distingue mayúsculas; sí tildes y ñ) y la búsqueda, `COLLATE utf8mb4_0900_ai_ci` (GV-152). Los comodines del `LIKE` se escapan con `!` (SC-08).
- IDENTIFICADOR: el código del vocabulario (MeSH: D006801). La URI de JATS (`kwd/@vocab-term-identifier`; `kwd-group/@vocab` y `@vocab-identifier`, DTD 1.4) se arma al generar. MeSH: `http://id.nlm.nih.gov/mesh/` + código (MeSH RDF). DeCS: sin patrón de URI verificado.
- EN EL ARTÍCULO: sugerencias mientras se tipea (dos caracteres como mínimo); se agrega la sugerencia elegida o lo escrito. Si el catálogo ya tiene el término con otras mayúsculas, se usa su forma y su identificador. Un término nuevo entra al catálogo al guardar el artículo, en su transacción (`INSERT … ON DUPLICATE KEY UPDATE`, no `INSERT IGNORE`, que también callaría un CHECK).
- El artículo guarda término e identificador por valor (SC-23).
- CORRECCIÓN: solo desde la tercera subpestaña de «Catálogos» de `FSysAdmin` (desde el 14/11/2026; antes `FVocabularios`, que se borró). Una sola subpestaña con filtro por vocabulario e idioma, para que un vocabulario nuevo no obligue a tocar el formulario. Un vocabulario propio se crea escribiendo su nombre y guardando su primer término; en el canónico, `kwd-group-type` y `vocab` llevan ese nombre. Corregir un término corrige los artículos NO publicados que lo usan (herencia viva, SC-71); un publicado queda como salió. Se borra solo un término sin uso.
- Las palabras clave del autor siguen libres, una por línea.
- LICENCIAS: los datos de MeSH son de dominio público, con cita a NLM y versión declarada si se redistribuyen. Descargar DeCS exige un contrato de licencia gratuito con BIREME. Tipear términos no requiere nada.

**Relaciones:** vinculo:SC-23,vinculo:SC-08,vinculo:SC-71,vinculo:SC-73,vinculo:GV-152,vinculo:GV-145,vinculo:GV-215,vinculo:GV-150,vinculo:SC-90

### SC-75 — Validación del canónico DocBook de libros: un validador en engine/, huella de las fuentes y freno del desactualizado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / jing 20220510-3 / SaxonJ-HE 12.5 (contenedor) y 12.9 (Linux Mint) / Pandoc 3.1.3 / libxml 2.9.14 (contenedor y Linux Mint) / gbc3 3.19 / contenedor Ubuntu 24.04 y Linux Mint con Duek y Califa; LuaHBTeX 1.17.0 (TeX Live 2023) · **Verificado:** 2026-10

DECISIÓN CERRADA (Alberto, 29/10; documento de trabajo `claude/validador-docbook.md`). Entrega 1 implementada y probada en Linux Mint (29/10). Revistas y JATS4R quedan para la fase de artículos.

UN SOLO VALIDADOR

`engine/validar_canonicos.sh <ruta_proyecto> <modo> <lista_rel|->`. Lo usan el botón «Validar» del visor XML, la apertura del proyecto, `generar_canonicos_capitulos.sh` y `ensamblar_libro.sh`; estos dos dejan de validar por su cuenta y lo llaman anidado (`GBP_ANIDADO=1`, SC-53).

- Modo `completo`: todas las capas. Modo `vigencia`: solo la vigencia, sin JVM.
- La lista es un archivo de `tmp/` con una ruta de canónico por línea, relativa al proyecto. «-» es todos los `jats/c-*.xml`.
- Un lote es UNA llamada (SC-53): jing recibe todos los archivos juntos; el Schematron corre una vez sobre `tmp/validar/`, una carpeta de enlaces a la lista (GV-XML-03).
- El alcance lo da la raíz de cada archivo: `book` es libro; las raíces de pieza (`chapter`, `preface`, `appendix`, `dedication`, `acknowledgements`…) son pieza; `article` y cualquier otra, fallo.

LAS CAPAS

    [1] vigencia      las PI gb-fuente contra el disco
    [2] bien formado  xmllint; si falla, el resto «no ejecutado», nunca ✓
    [3] DocBook 5.2   jing más el Schematron del RNG compilado aparte
                      (GV-XML-02, GV-XML-03). En pieza, los IDREF sin ID
                      van en tenue (SC-53); en libro, son aviso
    [5] recursos      cada imagedata/@fileref, sin los ../ y ./ del
                      principio, es media/{nombre} y existe. Una subcarpeta
                      de media/ es aviso: LaTeX la encuentra, pero HTML y
                      EPUB se quedan con el nombre y lo buscan en media/.
                      Y tiene que ser png o jpg, lo único que sale en las
                      tres salidas: LuaLaTeX no admite svg, gif ni webp
                      (GV-155) y el EPUB y el HTML no muestran un pdf. Otro
                      formato es aviso y dice en qué salida se pierde.
                      Sin comprobar direcciones de red
    [6] proyecto      las reglas propias de gbpublisher
                      (schemas/gbpublisher/gbpublisher.sch), en la misma
                      hoja y la misma pasada que las de DocBook. Se separan
                      por el prefijo gbp- de su @id; cada una declara su
                      nivel en @role (tenue informa; cualquier otro valor
                      cuenta como aviso)

Entrega 1: las capas [1], [2], [3] y [5], las huellas, la función de vigencia, el botón y la apertura. Entrega 2: las reglas propias [6] y el formato de imagen en [5]; gbp-ancho se sumó con el ancho de la figura (SC-76, 29/10). Las dos, implementadas y probadas en Linux Mint (29/10). La capa [4] —remisiones que jing no ve— quedó repartida en las reglas propias de citas y de figuras sin remitir; lo que falta de ella está en el pendiente.

LAS REGLAS PROPIAS

Decididas una por una (Alberto, 29/10). El @id del patrón y de cada aserción empieza con gbp-.

    patrón          alcance        nivel   qué controla
    gbp-ubicacion   pieza, y cada  aviso   seccion-libro: uno, fm, a o bm;
                    pieza del               orden-seccion: uno, dos cifras;
                    libro                   tipo-capitulo: a lo sumo uno, no
                                            vacío. Un duplicado frena las
                                            hojas de salida
    gbp-estilo      pieza y libro  aviso   estilo-cita: uno en la pieza; uno
                                            en el <info> del libro y ninguno
                                            en sus capítulos.
                                            lugar-bibliografia: uno en el
                                            libro, por_capitulo o consolidada
    gbp-pi          todos          aviso   PI gb-* conocidas (gb-alinear,
                                            gb-corte, gb-cuadro, gb-espacio,
                                            gb-fuente, gb-sigla,
                                            gb-lista-siglas); gb-fuente solo
                                            en el prólogo
    gbp-cita        todos          aviso   un biblioref cuyo destino está en
                                            el documento apunta a una entrada
                                            de bibliografía. Destino ausente:
                                            nada (en pieza, remisión externa;
                                            en libro, lo dice jing)
    gbp-bib         libro          tenue   entrada que nadie cita
    gbp-remision    libro          tenue   figura o cuadro con id que nadie
                                            remite
    gbp-alt         todos          aviso   imagen sin texto alternativo, o con
                                            uno que repetía el pie y el armado
                                            descartó (SC-76); las de <info>,
                                            como la tapa, no
    gbp-idioma      raíz y piezas  aviso   xml:lang con forma de etiqueta de
                    del libro               idioma (BCP 47)
    gbp-ancho       todos          aviso   imagedata/@width: un entero de 1 a
                                            100 seguido de %. El RNG acepta
                                            cualquier texto en @width (SC-76)

- tipo-capitulo se controla solo en cantidad y xml:lang solo en la forma: los dos catálogos están en la base (tipos de pieza, m_Idiomas), y el validador no la toca (SC-13). Una lista copiada en el Schematron se desactualizaría sin aviso: la de la hoja de capítulo ya no tiene indice_concepto ni indice_autores.
- Una figura o una cita que remite a otra pieza no se juzga en la pieza: los fig-*, tbl-* y bib-* son globales (SC-32, SC-66), y esas reglas corren en el libro.
- Las reglas sobre instrucciones de procesamiento se escriben sobre la raíz del documento: con el esqueleto ISO, una regla con contexto en una PI solo se dispara para las del prólogo (GV-XML-04).
- Las raíces de pieza que las reglas nombran no incluyen bibliography: la bibliografía consolidada es hija del libro y no es una pieza.

CÓDIGOS

    0  corrieron todas las capas y no hubo hallazgos
    3  hubo hallazgos, o una capa no pudo correr (jing ausente, por ejemplo)
    1  no se pudo validar: mal formado, archivo ausente, raíz desconocida

Es la lectura de los códigos de SC-53 para un script que no genera nada. Los mensajes de Gambas no dicen «se generó»: dicen «válido», «con hallazgos» o «no se pudo validar».

EL INFORME

`tmp/validacion.tsv`, reescrito siempre, también vacío: `archivo TAB capa TAB nivel TAB mensaje`, con nivel `ok`, `aviso`, `tenue`, `fallo` o `no_ejecutado`. Lo leen los scripts que llaman al validador, para atribuir los avisos a cada capítulo. Gambas no lo lee (SC-53).

LA HUELLA DE LAS FUENTES

La vigencia es respecto de lo que se copia DENTRO del canónico: el .md y los `cuadros/{id}.md` que nombra (SC-66). Lo que solo se referencia —las imágenes— no deja viejo al canónico y lo cubre la capa de recursos. Lo que llega de la base (`tmp/info-*`, `tmp/biblio-*`) no lo cubre ninguna huella: el informe dice «vigente respecto de sus archivos fuente», no «vigente».

- sha256 y no fecha de modificación: una copia (el .md que vuelve de otra máquina) cambia la fecha sin cambiar el texto, o conserva una fecha vieja con texto nuevo.
- `controles_md.lua` lista los cuadros que nombra el .md en `tmp/fuentes-{base}.txt` (`-M gb-fuentes`), siempre escrito, vacío si no hay; si falta, el capítulo falla (el contrato de SC-54). Va en `controles_md.lua` y no en `cuadro-leer.lua` porque está en `engine/` y no se modifica (SC-11); repite la regla id → archivo de `cuadro-leer.lua`, con referencia cruzada en los dos.
- `generar_canonicos_capitulos.sh` calcula las huellas antes de pandoc, las escribe en `tmp/huellas-{base}.xml` y se las pasa a la hoja de capítulo, que escribe una `<?gb-fuente archivo="…" sha256="…"?>` por fuente antes de la raíz, con la ruta relativa al proyecto. Una ruta con comillas dobles se rechaza: el contenido de una PI no se escapa.
- La hoja del libro copia las PI de cada capítulo a su propio prólogo. Las PI del prólogo no las ve jing ni las toman las hojas de salida (GV-XML-02).

LAS SIGLAS (1.18.0, SC-78)

El desarrollo de una sigla se copia en el canónico y llega de la base: una corrección en el catálogo lo deja viejo sin que cambie ningún archivo fuente. Cada sigla usada deja en el cuerpo `<?gb-sigla clave="…" sha1="…"?>`, con la huella de su línea en `tmp/siglas-libro.tsv`, que Gambas escribe desde la base antes de los scripts que la leen. `vigencia_canonico` las busca con `//` (el canónico del libro trae las de todos sus capítulos) y da el canónico por desactualizado si una cambió («la sigla 44-oms cambió en el catálogo»), si ya no está en el libro o si falta el archivo. No cuentan como fuentes: un canónico sin gb-fuente sigue «sin huella».

La lista de siglas no tiene .md: no es huérfana por eso. Se reconoce por su `<?gb-lista-siglas claves="…"?>` y está vigente si ese conjunto es el que usan hoy los canónicos de las piezas (`claves_siglas_usadas`, la misma función con que se arma); es huérfana si ya no es una pieza del libro.

LOS ESTADOS

`vigencia_canonico` en `comun.sh` reemplaza a `avisar_md_posterior` y devuelve un estado, sin avisar por su cuenta:

    vigente         todas las fuentes coinciden
    desactualizado  alguna fuente falta o tiene otra huella
    huérfano        no existe el .md de la pieza (no aplica al libro)
    sin huella      el canónico no tiene PI gb-fuente

    estado           ensamblado   PDF        EPUB       validador   apertura
    desactualizado   FRENO        FRENO      FRENO      aviso       mensaje
    huérfano         FRENO*       FRENO*     FRENO*     aviso       mensaje
    sin huella       aviso        aviso      aviso      tenue       nada

    * solo si la pieza está en la lista del consumidor: un huérfano suelto
      en jats/ no entra en ninguna, y solo lo ven el validador y la apertura

- FRENO, decisión de Alberto, en los TRES consumidores de los canónicos de capítulo: `ensamblar_libro.sh` junta todos los capítulos desactualizados y no ensambla, y con él frena el HTML, que lo llama anidado; `preparar_latex_libro.sh` hace fallar la pieza, como ya hace con un estilo que no coincide (SC-57); `generar_epub_libro.sh`, que no ensambla y transforma cada capítulo por separado, lo cuenta como problema y no genera el EPUB. Frenar solo al ensamblar dejaba al PDF y al EPUB con la versión vieja.
- «Sin huella» es aviso y no freno mientras dure la transición: todos los canónicos anteriores a esta regla la tienen, y se resuelve regenerándolos.
- Un huérfano no se borra: un canónico se reconstruye desde su .md, y un huérfano no lo tiene. Lo borra el editor.

LA APERTURA

Al abrir un libro, `RevisarVigenciaLibro` lanza el validador en modo `vigencia` con «-», por `m_Lanzadora.EjecutarScript` (SC-53): toda la lógica queda en `engine/` y no hay JVM. Con código 0 no muestra nada; con 3 —que en este modo solo pueden dar desactualizados y huérfanos— avisa que el ensamblado y el PDF van a frenar y que el detalle está en la terminal. «Sin huella» no se informa al abrir: avisaría en cada apertura.

LOS RECURSOS DEL SISTEMA

El RNG y el Schematron compilado salen de los recursos del sistema, no de `~/.gbpublisher/` (SC-11): un informe que dice «válido» solo se sostiene con el esquema del paquete. En bash, `$DIR_ENGINE/..`; en Gambas, `m_InicioCierre.RutaRecursos()`, que es `.hidden/` desde el IDE y `/usr/share/gbpublisher/` instalado. No una ruta fija: haría correr al IDE con los recursos de otra versión.

El Schematron compilado (`schemas/schematron-canonico.xsl`) junta las reglas del RNG y las propias. Lo genera fuera de la aplicación `generar-schematron-canonico.sh`, en la raíz del repositorio, con la extracción y la compilación de GV-XML-03, y anota en su cabecera las huellas del RNG, de `gbpublisher.sch` y del esqueleto. Reemplazó a `generar-schematron-docbook.sh` y a `schemas/docbook/docbook-sch.xsl`, que solo tenían las de DocBook.

LA INTERFAZ

- `btnValidarXML`, en el visor XML (`TabPanelVisor`, índice 1), valida el archivo elegido en `cmbArchivosXML`.
- En un proyecto de revista está deshabilitado: se decide en la apertura con el tipo ya resuelto (`iTipoSeleccionado`), no mirando otra vez el prefijo.
- Entra en `BloquearSalidas` (SC-53); al desbloquear vuelve a habilitarse solo si el proyecto es un libro.

EN EL CÓDIGO

- `engine/validar_canonicos.sh`; en `comun.sh`, `vigencia_canonico`, que reemplazó a `avisar_md_posterior` y deja el resultado en `VIGENCIA_ESTADO` y `VIGENCIA_DETALLE`.
- La huella: `controles_md.lua` (`gb-fuentes`, SC-54), `generar_canonicos_capitulos.sh` (`tmp/huellas-{base}.xml`), `ensamblar-capitulo-canonico.xsl` (parámetro `huellas`, obligatorio) y `ensamblar-libro-canonico.xsl` (copia las PI de cada capítulo).
- El Schematron compilado lo genera `generar-schematron-canonico.sh`, con instancias de prueba que tienen que dar lo esperado antes de reemplazar la hoja: cuatro para DocBook (cantidad y mensaje exactos) y tres para las reglas propias, una limpia, una pieza y un libro, que comparan el conjunto exacto de @id que fallan.
- En Gambas: `m_Lanzadora.HabilitarValidacion` (apartado 20 de `FMain.AbrirProyectoMD`); en `m_GenerarSalidasLibro`, `ValidarCanonico` (`btnValidarXML_Click`), `RevisarVigenciaLibro` (apartado 23) e `InformarValidacion`, con textos propios: un validador no genera nada.

MEDIDO

- Las tres salidas del libro con y sin `<?gb-fuente?>` en el prólogo: LaTeX (8 piezas), HTML (9 archivos) y EPUB (8 páginas) idénticos byte a byte.
- Regenerar un canónico sin cambios en el .md reproduce el anterior salvo las PI. Un `touch` o una fecha vieja en el .md siguen dando «vigente»; cambiar el .md o un cuadro, o borrar un cuadro, da «desactualizado» en el capítulo y en el libro.
- En Linux Mint con Duek y Califa: el lote con las huellas, el ensamblado vigente y válido, el PDF, el freno del EPUB con seis capítulos modificados a propósito, el aviso al abrir y el botón.

**Relaciones:** vinculo:SC-52,vinculo:SC-53,vinculo:SC-54,vinculo:SC-11,vinculo:SC-13,vinculo:SC-66,vinculo:SC-32,vinculo:SC-57,vinculo:GV-XML-02,vinculo:GV-XML-03,vinculo:GV-XML-04,vinculo:GV-155,vinculo:SC-78,vinculo:SC-79

**PENDIENTE:** (1) La remisión a un destino que la salida no sabe numerar (un xref a un elemento sin número): leer antes qué tipos numeran las tres hojas. (2) Posible regla: una figura con pocos píxeles para el ancho de la caja sale pixelada en el PDF, que la compone siempre a \linewidth; HTML y EPUB la muestran a su tamaño natural. Se retoma con el shortcode de figuras.

### SC-76 — Imágenes en el EPUB y el HTML de libros: solo las usadas, y una copia para pantalla

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / ImageMagick 6.9.12-98 Q16 / libxml 2.9.14 / epubcheck 4.2.6 / gbc3 3.19 / contenedor Ubuntu 24.04 y Linux Mint, con Califa · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 29/10/2026). El EPUB y el HTML de un libro llevan solo las imágenes que usan, y cada una va tal cual o en una copia preparada para pantalla. El PDF sigue usando el original de `media/`.

QUÉ LLEVA CADA SALIDA

- EPUB: la tapa, el logo de portada, el logo de colección y las imágenes que nombran los canónicos de las piezas (el `@fileref` de cada `imagedata`), sin repetir. La lista la arma `m_GenerarEpubLibro.ImagenesUsadas` y es la del manifiesto: `generar_epub_libro.sh` copia exactamente las que el OPF declara en `images/`, sin volver a elegir. Una imagen declarada que no está en `media/` detiene el EPUB con su nombre.
- HTML: `docs/assets/media/` se vacía y recibe lo que usa el canónico del libro (que ya trae la tapa como `mediaobject`), la tapa que declara la base y el `.html` de cada gráfico interactivo: `fig-x.png` con `fig-x.html` al lado, el mismo patrón que `gbg:patron-png` (SC-69). Una imagen que el canónico nombra y no está en `media/` da aviso: el HTML sale igual.
- Antes las dos salidas copiaban `media/` entera, y cada lado del EPUB la recorría por su cuenta. En Califa viajaban `desconocido.png`, `falta-tapa.png`, `logo-cabecera.png` y `logo-revista.png` sin usarse.
- En pantalla la imagen sale a su tamaño natural con tope en el ancho de la columna (`max-width: 100%`).

LA COPIA PARA PANTALLA

`copiar_imagen_pantalla` en `engine/comun.sh`, que usan los dos scripts.

- En pantalla cuentan los píxeles, no los ppp: el navegador y el lector de EPUB ignoran la densidad que declara el archivo.
- Tope: 2000 px de lado mayor, y solo achica (`-resize 2000x2000>`). Con la grilla del HTML, la columna central mide unos 1070 px CSS en una pantalla de 1920; una pantalla de alta densidad la duplica. Es una decisión, no un estándar.
- Color, antes del tamaño. CMYK con perfil: de su perfil a sRGB. CMYK sin perfil: se asume FOGRA39 y de ahí a sRGB. RGB con un perfil que no es sRGB: a sRGB. Escala de grises: no se toca. Los perfiles son los de TeX Live (`sRGB.icc`, `FOGRA39L_coated.icc`), que se ubican con `kpsewhich`: texlive-full es dependencia del `.deb`.
- La copia se escribe siempre con `-strip`, que es lo que la hace reproducible (GV-156). Borra el perfil: por eso el color se convierte antes.
- La decisión de color está en `receta_color_srgb` (`comun.sh`), que comparte la tapa del portal (`tapa_web.sh`, SC-81): una sola receta de color. Se extrajo de `copiar_imagen_pantalla` el 04/11/2026 sin cambiar el resultado: medido sobre ocho casos, los mismos códigos, notas y bytes antes y después, también con los perfiles ausentes.
- Una copia que solo reduce y pesa más que el original se descarta, y va el original; el informe lo dice. El tope existe por el peso. Una conversión de color no se descarta nunca.
- Solo png y jpg, los formatos de las figuras (SC-75, GV-155) y de los logos. Cualquier otro formato se copia tal cual.
- Sin nada que hacer, el original byte por byte.
- Las copias quedan en `tmp/pantalla/`, con la huella sha256 del original en el nombre: se rehacen solo si el original cambia. `VERSION_PANTALLA` sube si cambia la receta y con ella se invalida el caché.

EL ANCHO DE LA FIGURA

- En el .md, `ancho=NN` en la apertura: un entero de 1 a 100, sin el signo. Otro valor detiene la conversión (`fenced-divs-to-elements-db.lua`), con el mensaje de cómo se escribe.
- En el canónico, `imagedata/@width="NN%"`, como define DocBook el porcentaje: una fracción del ancho disponible. El RNG acepta cualquier texto en `@width` (medido: `width="abc"` valida), así que lo repite la regla propia gbp-ancho del validador (SC-75), para un canónico editado a mano.
- En el PDF, `width=0.NN\linewidth`. Sin `@width`, `\linewidth`, que es igual a `\textwidth` en el cuerpo y se adapta dentro de un recuadro.
- En el HTML y el EPUB, `max-width: NN%` sobre la imagen: un tope sobre el tamaño natural, no un ancho fijo. El gráfico interactivo del HTML no tiene tamaño natural: el iframe va exactamente a ese ancho, centrado (`gbg:iframe`, parámetro `ancho`, que las revistas no pasan).
- El botón de figura escribe `ancho=100`, que es el ancho de siempre, a la vista para ajustarlo.

EL TEXTO ALTERNATIVO

En un libro es obligatorio y no se reemplaza con el pie (decisión de Alberto, 29/10/2026). El botón escribe `alt=""` vacío y no un texto provisorio: un `alt` vacío lo señala gbp-alt al generar el canónico, y un texto provisorio olvidado saldría publicado (el pie provisorio, «Pie de la figura», no lo detecta nadie). Si el `alt` falta, el filtro pone el pie como red de seguridad; el armado lo descarta por repetir el pie y gbp-alt avisa. Detalle en SC-32.

LOGOS

El de portada y el de colección van a 110 mm en el PDF y al 100 % en el EPUB (SC-25).

REVISTAS

`m_GenerarEpub` y `m_GenerarHTML`, que copiaban `media/` entera, eran el camino viejo de revistas y salieron el 18/11/2026 (SC-98).

REVISTAS (14/11/2026)

El mismo criterio en el EPUB y el HTML del número (SC-91, SC-92): solo las imágenes que usan los artículos (el `xlink:href` de cada `fig/graphic`, sin carpeta: `imagenes_canonico_jats` en `engine/revista_comun.sh`, la gemela de `imagenes_canonico` para DocBook) y la tapa del número, cada una por `copiar_imagen_pantalla`. En el EPUB la lista es la del OPF, que arma `numero-a-epub.xsl`; en el HTML, `docs/assets/media/` se vacía en cada corrida y recibe esas, con el `.html` de cada gráfico (SC-69). Una imagen que falta en `media/` frena en las dos.

**Relaciones:** vinculo:SC-25,vinculo:SC-32,vinculo:SC-69,vinculo:SC-75,apoya:GV-156,vinculo:GV-155,vinculo:GV-22,vinculo:SC-11,vinculo:SC-81,vinculo:SC-91,vinculo:SC-92

**PENDIENTE:** Revistas: el ancho proporcional de la figura. En una revista el botón de figura no escribe ancho ni alt.

### SC-77 — Índices onomástico y de conceptos: la marca en el .md, el canónico y el PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Pandoc 3.1.3 / LuaHBTeX 1.17.0, TeX Live 2023, babel-spanish, imakeidx, esindex, biblatex + biber, hyperref / xindy (Ubuntu 24.04) / qpdf / SaxonJ-HE 12.5 / jing / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-10

DECISIÓN CERRADA (decisión de Alberto, 30/10/2026). Los dos índices que carga el editor —onomástico y de conceptos— se marcan en el .md con la orden completa de LaTeX, como en el flujo legacy, y salen solo en el PDF de los libros. El tercero, el de autores de la bibliografía (`names`), lo sigue llenando biblatex con esindex y no lleva marca.

LA PIEZA

Ya existía: `tipo_capitulo` `indice_onomastico` e `indice_concepto`, pieza sin cuerpo en el espacio `bm-` (SC-55), `\gbIndice` en el contrato y `\makeindex[name=onomastico]` / `[name=concepto]` en la estética. Lo que faltaba era la marca: `controles_md.lua` frenaba `\index` como `latex_en_linea`, el escritor DocBook lo descartaba (GV-116) y `docbook-to-latex.xsl` no tenía plantilla de `indexterm`. Sin plantilla, la regla por omisión de XSLT copiaría el texto del término en el cuerpo.

LA MARCA

    \index[onomastico]{Borges, Jorge Luis!infancia}
    \index[onomastico]{Torre Lisandro de la@Torre, Lisandro de la}
    \index[concepto]{democracia!liberal|(}   …   \index[concepto]{democracia!liberal|)}
    \index[concepto]{universidad|see{educación superior}}
    \index[concepto]{educación superior|seealso{universidad}}
    \index[concepto]{educación superior|textbf}

- `!` nivel (hasta tres), `@` clave de orden, `|(` y `|)` rango, `|see{…}` y `|seealso{…}` remisiones, `|textbf` página principal. Es la sintaxis de makeindex y xindy, pero la lee `indice.lua`, no xindy: el canónico guarda el texto limpio y la hoja LaTeX lo vuelve a armar.
- El nombre del índice es obligatorio y de la lista cerrada: `onomastico` y `concepto`, los del `\makeindex` de la estética. Sin nombre, o con otro, frena: con dos índices manuales, un `\index{…}` sin nombre es ambiguo.
- Un `!`, `@` o `|` literal se escribe `\!`, `\@`, `\|`. La hoja LaTeX lo reescribe con la comilla de xindy (GV-160). No se usa la comilla en el .md: con babel-spanish es un atajo activo.
- Un `%` se escribe `\%` y las llaves van cerradas: si no, Pandoc parte la orden en texto común (GV-157). El filtro la busca también en el texto común y frena.
- Va pegada a la palabra que señala.
- No va en un título: pasaría al sumario y a los marcadores. Se escribe al comienzo del primer párrafo. Frena.
- Un rango se abre y se cierra en la misma pieza, con la entrada idéntica. Frena.
- Una marca dentro de una nota da «23 n.» (decisión de Alberto, 30/10/2026). Una página principal dentro de una nota frena: cada entrada lleva un solo formato.
- `indice.lua` corre antes de `cite-to-biblioref-db.lua`, que serializa las notas y borraría las marcas que estén adentro (como con la volada, SC-62).

POR QUÉ LA ORDEN DE LaTeX Y NO UN SPAN

Sigue el camino de `\sptext` (SC-62) y de las cifras (SC-65): Pandoc la lee como LaTeX en línea en cualquier lugar, sin interpretar lo de adentro (GV-157), y un filtro la traduce antes de que la descarte el escritor DocBook (GV-116). Un span `[Borges]{.indice …}` envuelve texto, y una entrada muchas veces señala algo que no está escrito tal cual: un pronombre, una paráfrasis. Además m_Hunspell saltea el texto entre corchetes.

EL CANÓNICO

`<indexterm type="onomastico|concepto" xml:id="…">` con `primary`, `secondary` y `tertiary`, `@sortas`, `class="startofrange"` / `class="endofrange"` con `startref`, `see`, `seealso` y `significance="preferred"` para la principal (DocBook 5.2, RNG del repo). Cada uno lleva su id aunque hoy nada lo use: es lo que deja abierto un índice con enlaces en EPUB y HTML.

EL PDF

- `docbook-to-latex.xsl` vuelve a escribir `\index[nombre]{…}` con el formato explícito: `|hyperpage`; `|(hyperpage` y `|)hyperpage`; `|gbIndNota` dentro de una nota (lo sabe por el ancestro `footnote`); `|gbIndPrincipal`; `|see{…}` y `|seealso{…}`.
- hyperref con `hyperindex=false` (GV-159). El índice `names` agrega `|hyperpage` desde su formato de nombre y conserva los enlaces.
- `\gbIndNota` y `\gbIndPrincipal` son del contrato: los escribe la hoja.
- xindy corre con `-L spanish-modern -C utf8` (GV-158), con el módulo `book-order` de xindy, que pone los romanos de los preliminares antes que los arábigos (GV-158), y con el módulo `gbindice.xdy`, que declara los dos formatos (GV-160). El script avisa también las páginas descartadas por un formato desconocido.

Presentación, con el criterio de Valbusa (decisión de Alberto, 30/10/2026: coma y minúscula siempre que se pueda):

    Alberdi, Juan Bautista, 1 n., 3
    democracia
       liberal, 1–3
    educación superior, 2, véase también universidad
    universidad, véase educación superior

La página principal, en negrita. Los romanos de los preliminares, primero: «Sarmiento, Domingo F., XIII n., 3 n.».

REGLAS DEL LOTE 1

Las propuso Claude al escribir el lote y quedaron en el código que Alberto probó en Mint (30/10/2026):

- Adentro de una entrada, la única orden admitida es `\emph{…}`, para los títulos de obras (`Borges, Jorge Luis!\emph{Ficciones}`). Sin clave `@`, xindy ordena por el texto plano. Cualquier otra orden frena.
- No va en el pie ni en la imagen de una figura, ni en el pie de un cuadro: el pie se copia a la lista de figuras o de cuadros, y desde ahí se indexaría otra vez con la página de la lista. Frena.
- No va sola en un párrafo: quedaría un párrafo vacío. Frena.
- Dos marcas de la misma entrada en la misma página dejan una sola (GV-160): principal y común, la página en negrita; común y en nota, la página sin «n.».
- El marcador • del panel que queda sin reemplazar frena (acordado con Alberto, 30/10/2026): si no, «•» saldría como una entrada.

EL PANEL

Dos filas de gbShortcodes, solo para libros (decisión de Alberto, 30/10/2026): `index-onomastico` e `index-concepto`, grupo `comun`, modo `plantilla`, liberadas en libros y `no_aplica` en revistas (`datos-v5-021`, `datos-v5-022`). Insertan `\index[onomastico]{•}` e `\index[concepto]{•}` con el marcador seleccionado. Se usan con el cursor pegado después de la palabra y SIN selección: la plantilla reemplaza lo seleccionado. Un modo que inserte la marca después de la selección, con la entrada ya cargada, queda como idea si el uso lo pide.

EPUB Y HTML

No llevan índices (decisión de Alberto, 30/10/2026): la plantilla de `indexterm` es vacía y la pieza se omite (matriz de `m_PiezasLibro`: «no se hace todavía»). Caminos estudiados para el día que se hagan con enlaces: anclas propias, con el orden calculado por Saxon y no por xindy (dos órdenes posibles para el mismo índice), o las páginas del PDF enlazadas, con el EPUB dependiendo de compilar antes el PDF y sin lista de páginas del impreso.

REVISTAS

No se usan índices (decisión de Alberto, 30/10/2026): `no_aplica` en gbShortcodes. JATS 1.4 Archiving tendría `<index-term>`.

FUERA DE ESTA DECISIÓN

- «23 n. 45», con el número de nota. DESCARTADO por costo (decisión de Alberto, 30/10/2026): las notas se reinician por pieza (SC-31), así que «nota 45» sola es ambigua, y xindy no lo da de forma nativa (GV-160).
- El código muerto de `ensamblar-capitulo-canonico.xsl` (`indice_tematico`, `indice_analitico`, quitados en el esquema 1.11.0): se limpió en el lote 1. Las piezas de índice no pasan por esa hoja; las marcas sí, y la hoja prefija el `@startref` del cierre de un rango como los demás id.

PROBADO EN MINT

Alberto, 30/10/2026, con «El Atlántico de los exilios»: el párrafo de prueba en el capítulo 1 y en la introducción (preliminares). Los dos índices en el PDF: orden español con la Ñ en su grupo, subentradas, `\emph` en una subentrada, clave `@`, `¡…!` con `\!`, rango, página principal en negrita, «véase» y «véase también», «n.» en las páginas de nota, los romanos antes que los arábigos (con `book-order`), y los enlaces. Después, el resaltado de `\index` en el editor, la inserción desde el panel, la ayuda y los casos que frenan con el marcador olvidado.

**Relaciones:** vinculo:SC-62,vinculo:SC-65,vinculo:SC-54,vinculo:SC-31,vinculo:SC-55,vinculo:GV-116,vinculo:GV-124,apoya:GV-157,apoya:GV-158,apoya:GV-159,apoya:GV-160,vinculo:SC-79

### SC-78 — Siglas del libro: catálogo de la editorial, la marca en el .md, el primer uso por pieza y la lista generada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher 1.18.0 / Pandoc 3.1.3 / SaxonJ-HE 12.5 (contenedor) y 12.9 (Linux Mint) / jing / LuaHBTeX 1.17.0, TeX Live 2023, babel / MySQL 8.0.46 / gbc3 3.19 (contenedor) y Gambas 3.22 (Linux Mint) / contenedor Ubuntu 24.04 y Linux Mint con Califa · **Verificado:** 2026-10

Solo libros (decisión de Alberto, 31/10/2026). En revistas, `no_aplica`, sin cerrar el camino a una lista de abreviaturas en el `<back>` de JATS si algún día la pide una biomédica.

EL DATO (ESQUEMA 1.18.0)

- `sigla_catalogo`: el catálogo de la EDITORIAL, común a todos los libros. Sigla `VARCHAR(32)` `utf8mb4_0900_as_cs` (LyF y LYF son distintas), desarrollo `VARCHAR(500)` `0900_as_ci`, plural e idioma opcionales (NULL, GV-74). Única (sigla, desarrollo): PO puede ser Partido Obrero y *Prensa Obrera*.
- `libro_sigla`: la copia en el libro, por valor (SC-23), con su `clave`. Corregir una entrada del catálogo corrige las copias de los libros no publicados (`libros_md.estado_libro`); un libro publicado queda como salió, como lo publicado en SC-23 y con el criterio de la herencia viva hasta publicar de SC-71.
- La clave es `<id_sigla>-<sigla normalizada>` («44-oms»), como en referencias. El catálogo no la guarda: una columna generada no puede usar una AUTO_INCREMENT (GV-165). El libro la guarda al adoptar y no cambia nunca: un libro que viaja por JSON a otra instalación conserva sus marcas.
- El desarrollo admite solo cursiva, `*…*`; todo lo demás es literal ($, &, %, #, _). Con idioma, el desarrollo ya sale en cursiva y no lleva asteriscos que lo envuelvan entero (`m_Siglas.AvisoIdioma`, GV-163). No admite tabulador ni salto de línea: rompería el archivo del filtro.
- Las abreviaturas («leg. 79/26», «f. 32») no se cargan ni se marcan: son texto.

LA MARCA EN EL .md

    [OMS]{.sigla}                  la sigla, sola en el libro
    [CI]{.sigla .plural}           el plural del desarrollo
    [CI]{.sigla .inicial}          mayúscula inicial (comienzo de oración)
    [PO]{.sigla clave=12-po}       solo cuando el libro tiene dos con esa sigla

Equivale al `\gls{OMS}` de glossaries. La inserta F2 (`FSiglaRapida`): busca por la sigla y dentro del desarrollo, sin tildes; elegir una la adopta en el libro; una sigla nueva se da de alta ahí mismo. Enter, Ctrl+Enter (plural) y Shift+Enter (inicial). Una selección corta de una línea es la búsqueda y la marca la reemplaza.

LA SINCRONÍA

Las siglas del libro son las de sus marcas: al abrir FSiglas, con su botón «Sincronizar» y antes de cada script que las lee, se adoptan las marcadas de un solo significado y se quitan las copias sin marca. No quita nada si el editor tiene cambios sin guardar o si un archivo no se pudo leer, y no toca un libro publicado. Motivo: adoptada no es usada, y mostrar como «en uso» una sigla que ya no tiene marcas confundía.

EL FILTRO: siglas.lua

4c° de FILTROS_LIBRO, después de indice.lua y antes de cite-to-biblioref-db.lua. Lee `tmp/siglas-libro.tsv` del proyecto: una línea por sigla, `clave TAB sigla TAB desarrollo TAB plural TAB idioma`, en el orden de la lista. Lo escribe `m_Siglas.EscribirParaFiltro`, llamada por `m_Siglas.PrepararParaScript` desde `m_Lanzadora.EjecutarScript`, la única lanzadora (SC-53), antes de los scripts que lo leen.

- Primer uso EN CADA PIEZA, sin importar la autoría: «Organización Mundial de la Salud (OMS)»; después, la sigla. Con idioma, el desarrollo va en `<foreignphrase xml:lang>`.
- La nota cuenta en el lugar de su llamada, como en glossaries: el recorrido es propio y en el orden del texto (un `walk` de Pandoc no lo garantiza).
- En el canónico: `<acronym xlink:title="desarrollo">OMS</acronym>`.
- Frena: una marca en un título, una cita en bloque, un epígrafe, un verso, una cita de fuente, una figura, un cuadro o una cita bibliográfica (ahí la sigla se escribe a mano; las comillas en línea sí la admiten); una sigla ambigua sin clave; una clave que el libro no tiene o que es de otra sigla; `.plural` sin plural; el desarrollo escrito a mano delante del primer uso (saldría dos veces); una marca partida, que Pandoc no leyó y saldría literal (GV-161).
- Al final de la pieza, `<?gb-sigla clave="…" sha1="…"?>` por sigla usada, con la huella de su línea del .tsv: una corrección en el catálogo deja viejo al canónico (SC-75).

LA LISTA DE SIGLAS (PIEZA lista_abreviaturas)

Un canónico SIN .md: lo arma `generar_canonicos_capitulos.sh` (`procesar_lista_siglas`) al final de cada lote, y Gambas la agrega a todo lote, también al generar un solo capítulo. Lleva las siglas que usan los CANÓNICOS de las piezas del libro (sus `gb-sigla`), no las marcas del .md: así coincide con el texto publicado. Las piezas salen de `tmp/siglas-piezas.txt` (`m_Siglas.EscribirPiezas`, desde la base: un canónico huérfano no aporta siglas).

- `<glossary role="abreviaturas">` con `<glosslist role="siglas">`, un `<glossentry>` por sigla, solo el desarrollo singular; una sigla con dos significados en el libro va en una entrada, con los desarrollos unidos por « / ».
- Orden: por la sigla, sin mayúsculas ni guiones (LyF después de LN); a igual sigla, por el desarrollo sin asteriscos.
- Al final, las `gb-sigla` y `<?gb-lista-siglas claves="…"?>`, el conjunto ordenado. La vigencia la da por vieja si los canónicos usan hoy otro conjunto (SC-75).
- Frena si ningún capítulo usa siglas: saldría vacía.
- Va donde dice su prefijo: `fm-` en preliminares, `bm-` en posliminares (`ZonaDePieza`, decisión de Alberto, 31/10/2026). Es la única pieza cuya zona decide el prefijo; con la zona del tipo, en `bm-` el PDF reabría `\frontmatter` y el folio volvía a «iii» (GV-164). Desde entonces el PDF frena si cualquier pieza obliga a volver a una zona anterior (SC-55).

LAS SALIDAS

- PDF: `acronym` es texto; `foreignphrase` es `\gbextranjero{en}{…}`, que en el contrato es `\foreignlanguage{\csname gbbabel@en\endcsname}{\emph{…}}` (GV-163). `DefinicionesCita` carga en babel los idiomas de las siglas (`m_Siglas.IdiomasDelLibro`, nombre por `m_Idiomas.Babel`) y define `gbbabel@<código>`; un idioma que babel no reconoce frena. La lista, en dos columnas alineadas (entorno `gbsiglas`): la primera mide la sigla más ancha, medida en LaTeX con `\gbSiglaMedir` (contar letras no sirve). Contrato 19.
- EPUB y HTML: `<abbr title>` y `<i lang>` (el EPUB también `xml:lang`); la lista, `<dl class="siglas">` en dos columnas con CSS grid, que sin grid se lee como lista de definiciones común. En el índice del HTML, «Siglas».

EL VALIDADOR

`gbpublisher.sch` reconoce `gb-sigla` y `gb-lista-siglas` como instrucciones conocidas (gbp-pi); hay que regenerar `schematron-canonico.xsl`.

**Relaciones:** vinculo:SC-23,vinculo:SC-71,vinculo:SC-13,vinculo:SC-75,vinculo:SC-55,vinculo:SC-77,vinculo:SC-79,vinculo:GV-74,vinculo:GV-116,apoya:GV-161,apoya:GV-162,apoya:GV-163,apoya:GV-164,apoya:GV-165,apoya:GV-166,apoya:GV-XML-05

### SC-79 — Glosario del libro: lista de definiciones en el .md, orden con letras, «véase» y párrafo francés

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher 1.18.0 / Pandoc 3.1.3 / SaxonJ-HE 12.5 (contenedor) y 12.9 (Linux Mint) / jing / LuaHBTeX 1.17.0 y XeTeX, TeX Live 2023 / contenedor Ubuntu 24.04 y Linux Mint con Califa · **Verificado:** 2026-10

Propio de cada libro, en el .md de la pieza `glosario`. No pasa por el formulario de siglas (decisión de Alberto, 31/10/2026).

LA ESCRITURA

La lista de definiciones de Pandoc, que Pandoc lee de forma nativa (el término admite cursiva; la definición, varios párrafos):

    Una introducción opcional.

    *Travelling*
    :   Desplazamiento de la cámara. Véase también [plano secuencia]{.vease}.

    Traveling
    :   [Travelling]{.vease}

El viejo bloque `::: {.glossary term="…"}` (un `<variablelist>` por entrada, shortcode en borrador, nunca liberado) se retiró: `fenced-divs-to-elements-db.lua` frena con un mensaje que dice cómo escribirlo.

EL FILTRO: glosario.lua

15°, el último de FILTROS_LIBRO: serializa las definiciones con `pandoc.write`, y lo que llevan adentro (citas, siglas, cifras) ya tiene que estar traducido. Actúa solo con `-M gb-tipo-pieza=glosario`, que `generar_canonicos_capitulos.sh` pasa desde 1.18.0; en las demás piezas una lista de definiciones sigue siendo `<variablelist>` y un `[x]{.vease}` frena, porque el escritor DocBook lo descartaría en silencio (GV-161).

- Sale `<glossdiv>` por letra con sus `<glossentry xml:id="gl-…">`, `<glossterm>` y `<glossdef>`.
- Orden alfabético sin mayúsculas ni tildes; la ñ, después de la n; los signos del comienzo (« ¿ ¡ " ( *) no cuentan; las cifras, antes de las letras, en «0–9».
- El «véase»: una definición que es solo `[x]{.vease}` es una remisión, `<glosssee otherterm>`, y sale «Traveling, véase Travelling», en minúscula y después de coma, como en los índices (SC-77). Dentro de un texto, `<glossterm linkend>`: un enlace a la entrada, con la redacción del autor. El término se busca sin mayúsculas ni tildes.
- Frena: un título (las letras las pone el filtro; `<glossary>` no admite secciones); texto después de las entradas; un término repetido; una remisión a un término que no existe o a sí mismo; un glosario sin entradas.
- Las huellas que dejan otros filtros (`gb-sigla`) van al final del cuerpo.
- `ensamblar-capitulo-canonico.xsl` prefija `@otherterm` como `@linkend`: es IDREF, y sin prefijo el «véase» apuntaba a un id que ya no existía (GV-XML-05).

LAS SALIDAS

Párrafo francés en las tres (decisión de Alberto, 31/10/2026): el término en negrita, « – » (semirraya entre espacios, el primero duro) y la definición; las líneas siguientes y los demás párrafos, sangrados.

- PDF: entorno `gbglosario`, `\gbGlosarioLetra`, `\gbGlosarioAncla` (`\phantomsection\label`), `\gbGlosarioTermino`, `\gbGlosarioSep` (`\nobreakspace–\space`, el carácter literal y no `--`, que depende de las ligaduras), `\gbGlosarioVease` y `\gbGlosarioRemite` (`\hyperref`). Contrato 20. La estética puede redefinir el aspecto; el contrato garantiza que existan.
- EPUB y HTML: `section.glosario-letra`, `div.glosario-entrada` con su id y `<dfn>`; las remisiones, `<a href="#id">` en la misma página.

**Relaciones:** vinculo:SC-77,vinculo:SC-78,vinculo:SC-75,vinculo:SC-55,apoya:GV-161,apoya:GV-XML-05

### SC-80 — gbWeb: el portal estático de la editorial o de la revista, cosido con lo que publica gbpublisher

**Estado:** vigente

Decisiones de Alberto, 02/11/2026. gbWeb es una aplicación aparte, en Gambas 3 y con su repositorio, que construye y mantiene el sitio estático de una editorial (libros) o de una revista (una sola). Es una ampliación de gbpublisher, como gbCorpus y gbShortcodes (SC-50), con una diferencia deliberada: no guarda datos que gbpublisher consume, sino que consume lo que gbpublisher publica. Lee la base MySQL de gbpublisher a través de un contrato (SC-81), y sus datos propios también van en MySQL, no en SQLite.

QUÉ ES

Una costurera: arma el portal —cabecera, páginas estáticas, imagen destacada, catálogo— y cose una lista indefinida de obras, cada una con su propio sitio. Ese sitio es una salida HTML más de gbpublisher, con los botones de descarga del EPUB y del PDF, publicada aparte (Netlify u otro). gbWeb no transforma el contenido de las obras: usa metadatos y enlaces.

El `L-ALGO.md` (portal de libros) o `R-ALGO.md` (portal de una revista) cumple el mismo papel que el `l-*.md` en gbpublisher: da nombre al proyecto y al repositorio, y sirve de anotador. No interviene en la construcción.

LA PUERTA DE ENTRADA

Solo gbpublisher. Una obra que no está en gbpublisher no existe para gbWeb: no hay alta de obras en gbWeb. El fondo editorial anterior a gbpublisher se da de alta en gbpublisher, a mano; cada libro con su proyecto mínimo, porque `libros_md.id_proyecto` es NOT NULL y único.

LOS PORTALES Y SUS OBRAS (decisiones de Alberto, 04/11/2026)

Dos mundos separados, unidos solo por la base:

- Los PROYECTOS de gbpublisher: un libro o un número cada uno, con `l-` o `r-` en minúscula (`l-CALIFA.md`). gbWeb no toca nunca sus carpetas.
- Los PORTALES de gbWeb: uno por editorial (`L-IMAGO.md`) o por revista (`R-MEDIEVALES.md`), con `L-` o `R-` en MAYÚSCULA. La mayúscula distingue a simple vista un portal de un proyecto. El portal no está asociado a ningún proyecto. Su carpeta puede llamarse de cualquier forma (SC-82): la identidad es el nombre del .md, que es también el del repositorio en GitHub o Netlify. gbWeb abre ese .md con un diálogo y escribe en su carpeta; qué lleva esa carpeta está en SC-83.

La ASOCIACIÓN es un dato de gbWeb. gbpublisher dice qué libros están publicados (`v_web_libro`); gbWeb, con un buscador sobre esa disponibilidad, asocia cada libro a una editorial, y lo mismo cada número de revista (volumen y número) a su revista. Hace falta porque en la misma base conviven los libros de Imago Mundi con los que Alberto edita para colegas.

- Un libro está en UN SOLO portal (decisión de Alberto): se puede pasar de un portal a otro, no estar en dos.
- El esquema propio de gbWeb, `gbweb`, en el mismo servidor MySQL: `portal` (`codigo` = nombre del .md sin extensión, `ascii_bin`; `tipo` libros o revista, atado a la letra por un CHECK) y `portal_libro` (clave `id_libro`, FK a `portal` con CASCADE). Lo crea `actualizar-esquema-1.0.0.sh` del repositorio de gbWeb, con las reglas de los scripts de esquema de gbpublisher (SC-22): versión en `gbweb.esquema_version`, decide por el estado real, respaldo verificado si ya había datos.
- SIN clave foránea hacia gbpublisher: ataría los dos esquemas y frenaría borrar un libro allá. Una asociación cuyo libro dejó de ser visible no sale en el sitio, y gbWeb la lista como huérfana para que se decida.
- La asociación de números de revista llega con la VIEW de números de gbpublisher, después del esqueleto de libros.

MEDIDO (contenedor, MySQL 8.0.46, con la cuenta de gbWeb): `l-IMAGO` en minúscula, un `L-` declarado como revista y un código repetido se rechazan; el mismo libro en dos portales se rechaza, pasarlo de uno a otro funciona; borrar un portal suelta sus libros; la cuenta no puede borrar tablas de `gbweb` ni leer las de gbpublisher.

LO QUE MUESTRA

- Visibilidad: `estado_publicacion` publicado, agotado o descatalogado. Solo `en_preparacion` queda afuera. Descatalogado se muestra: le sirve a las bibliotecas. Es la única condición; `estado_libro` no cuenta.
- Una ficha propia de cada obra en el portal, que enlaza al sitio completo cuando hay `url_libro`. Un libro del fondo no tiene sitio propio.
- Revista: la unidad que se cose es el número.
- La venta queda fuera del portal: un botón por tienda (`libro_venta`, SC-81) lleva a la página del libro en esa tienda, y la venta se resuelve ahí.
- Las marcas visuales salen de los datos, nunca se cargan a mano: agotado y descatalogado, con su etiqueta y sin botones de venta; acceso abierto, con la descarga (`tipo_acceso`).
- La imagen destacada la elige gbWeb, entre las de `media/` del portal, para lo que la editorial comunica por un tiempo (una promoción, un evento). Se activa a mano, nunca por fecha: con la fecha, el mismo estado daría sitios distintos según el día. Siempre hay una: sin elegir, va la imagen por defecto («Reemplazar esta imagen»).
- El sitio de cada obra lleva la cabecera y el pie COMPLETOS del portal cuando la obra se integra a él (SC-85). Corrige lo decidido el 02/11 (una cabecera mínima, para no reconstruir las obras al cambiar el portal): el costo se acepta porque el portal es estable (decisión de Alberto, 05/11/2026). Una obra autónoma conserva su propia cabecera.
- Idiomas: español, inglés y portugués. El español va en la raíz del sitio; el inglés y el portugués, en `en/` y `pt/`. Se traduce todo lo del portal (menús, etiquetas, nombres de los roles, páginas escritas); lo que viene de los metadatos se muestra tal cual. El título de cada obra lleva su `lang`, de `idioma_principal`.
- Buscador: título, ISBN, autor y palabras clave, en un índice JSON que genera gbWeb. Normaliza igual el índice y la consulta: el ISBN sin guiones ni espacios (impreso y electrónico); el autor por palabras en cualquier orden («Silvina Jensen» encuentra «Jensen, Silvina»); sin tildes ni mayúsculas (`normalize('NFD')`). Está plantado en la cabecera y todavía no busca: falta el índice.

LA PÁGINA (decisiones de Alberto, 02 al 04/11/2026)

- Contenedor de 1200 px. Noto Serif 400 y 600 en WOFF2, las del libro (SC-83: archivos fijos). La paleta de `gbpublisher.css` (el azul `#2d5a8e`).
- CABECERA, la misma en todas las páginas: una franja de unos 2 cm con el logo a la izquierda (sin logo, el nombre del portal) y el menú a la derecha, que despliega «Acerca de» solo con CSS; un filete; la línea del buscador, los 8 íconos para compartir la página abierta (Facebook, X, LinkedIn, WhatsApp, Telegram, Bluesky, Reddit, correo) y las 3 banderas, con un filete bajo la activa. Sin URL del sitio no hay botones de compartir ni vista previa (`og:`): necesitan direcciones completas.
- PIE, el mismo en todas las páginas: fondo azul con letra blanca, sin filete, siempre al fondo de la ventana aunque la página sea corta. Nombre, dirección, correo, «Desde <año>», licencia de los textos y los íconos de los perfiles en las redes (9: Facebook, X, LinkedIn, Bluesky, Telegram, Reddit, ResearchGate, Instagram, YouTube). Los datos son del portal (esquema `gbweb` 1.2.0, SC-83).
- Los íconos son de Font Awesome Free 7.2.0 (CC BY 4.0), copiados en la página con su comentario, que lleva la atribución; toman el color del texto.

INICIO Y CATÁLOGO

- INICIO: la imagen destacada al ancho del contenedor, con el alto de su propia proporción; un filete; «Últimos títulos», a la izquierda y en azul; los 4 libros más nuevos; «Ver el catálogo».
- CATÁLOGO: todos los libros, de a 8 por página, con flechas y el número de página; la que no tiene adónde ir queda apagada.
- Cada libro es una fila: la tapita a la izquierda y, al lado, título, subtítulo, personas, año, colección, ISBN y páginas, y la marca de agotado o descatalogado. El título lleva a la ficha.
- Las filas van en DOS COLUMNAS (2 × 2 en el inicio, 4 × 2 en el catálogo), sin filete vertical; cada libro con su filete abajo. En el teléfono, una columna.
- El orden es siempre el de SC-81: lo más nuevo primero.

LA FICHA

- Dos columnas: la tapa (unos 280 px, la del HTML del libro) y los datos.
- Personas agrupadas por rol, en el orden de autoría; la autoría sin rótulo; sin la dirección de la colección, que es de la colección. Quien tiene ORCID lleva el ícono, que es el enlace; el nombre no se enlaza.
- El resumen: una etiqueta con el triángulo, como en el HTML del libro; cerrado muestra tres líneas, para que quien ve el corte decida si lo abre. Es una casilla oculta con `line-clamp`, sin JavaScript: `<details>` cerrado no muestra nada de su contenido. Va el resumen en el idioma de la página si lo hay; si no, el del idioma principal, marcado con su `lang` (se compara el idioma base: `pt-BR` es `pt`).
- Los datos: Publicación (mes y año en el idioma de la página), Colección y su número, ISBN impreso y electrónico, Páginas, Idioma y Licencia (con su enlace si lo hay). El idioma se nombra en el de la página: español e inglés salen del catálogo `idiomas` de gbpublisher; el portugués, de una tabla corta en la XSLT; un idioma que no está en ella va en castellano.
- Las palabras clave no se muestran: sirven a los sugeridos y al buscador.
- LOS BOTONES salen de los datos, todos del mismo ancho: leer en línea si hay `url_libro`; las descargas (PDF, EPUB) con acceso abierto o mixto, si está la URL. Debajo, en otra fila, uno por tienda con su ícono y su nombre (Amazon, Apple Books, Google Play, Mercado Libre), solo con acceso de venta o mixto y estado publicado. Un libro de acceso abierto que se vende en papel se carga como mixto (confirmado por Alberto, 04/11/2026). Los íconos de Amazon, Apple y Google Play son de Font Awesome; Mercado Libre no está ahí y va su logo en PNG, en color.
- OTROS LIBROS SUGERIDOS, después de un filete y a todo el ancho, como en el inicio. Son 4 (decisión de Alberto: nunca menos, salvo que no haya más libros), por escalones: (1) los que comparten una persona, por `id_autor` y con cualquier rol salvo la dirección de la colección; (2) los que comparten una palabra clave, en cualquiera de los tres idiomas, sin tildes ni mayúsculas ni espacios de más; (3) los de la misma colección; (4) el resto. Cada escalón, lo más nuevo primero. Lo calcula la XSLT (`gbw:sugeridos`) con el orden de la secuencia, no el del documento (GV-183).

EL MENÚ Y LAS PÁGINAS ESCRITAS

- El menú es una matriz fija por clase de portal (`menu.xml`), con la lógica de OJS: libros, Inicio (el «Actual»), Catálogo (el «Archivos») y Acerca de (Sobre la editorial, Sobre las colecciones, Contacto); revista, Actual, Archivos y Acerca de (Sobre la revista, Envíos, Equipo editorial, Privacidad, Contacto). El blog quedó descartado.
- Las páginas de «Acerca de» se escriben en Markdown, en `paginas/<clave>.<idioma>.md` del portal. gbWeb crea las que faltan con «Acá va el texto» y nunca pisa una que existe. Una página sale si está su español; sin la traducción, va el español con `lang="es"`. El título es el nombre de la matriz, el mismo del menú.

CÓMO SE ARMA, EN OTRAS ENTRADAS

- El contrato con gbpublisher: SC-81.
- La construcción del sitio, el determinismo y el esquema `gbweb`: SC-83.
- La aplicación y el despliegue: SC-84.

**Relaciones:** vinculo:SC-50,vinculo:SC-81,vinculo:SC-82,vinculo:SC-22,vinculo:SC-83,vinculo:SC-84,apoya:GV-183,vinculo:SC-85

**PENDIENTE:** Precios en la ficha: la propuesta es no mostrarlos (cambian seguido y el precio vigente está en el punto de venta); falta la decisión. Carga del fondo con una semilla de los CSV de WooCommerce y de Mercado Libre, cruzados por ISBN: se trata después. Contrato de la revista: `numero` no tiene estado de publicación ni URL; falta la asociación de números. El buscador: el índice JSON. Una página por colección y `sitemap.xml`. Favicon y descripción del portal. Analítica: suspendida hasta elegir la herramienta (decisión de Alberto, 04/11/2026).

### SC-81 — Contrato gbpublisher → gbWeb: cinco VIEW, una cuenta de solo lectura y la tapa web en la base (esquemas 1.19.0 a 1.22.0)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher 1.19.0 a 1.22.0 (esquema) / MySQL 8.0.46 / Gambas 3.19 (gbc3, gbx3; gb.db.mysql) / ImageMagick 6.9.12-98 / contenedor Ubuntu 24.04 y Linux Mint (la tapa) / Gambas 3.22 (gb.db2), Linux Mint · **Verificado:** 2026-11

Decisiones de Alberto, 02/11/2026. gbWeb (SC-80) lee la base de gbpublisher solo a través de este contrato. Lo aplica `actualizar-esquema-1.19.0.sh` (SC-22); lo amplían la 1.20.0 (la licencia) y la 1.21.0 (los idiomas del libro y los puntos de venta).

EL LÍMITE: LAS VIEW

    v_web_libro           una fila por libro visible
    v_web_libro_persona   una fila por persona y libro
    v_web_coleccion       colecciones con al menos un libro visible
    v_web_libro_tapa      la tapa web de cada libro visible
    v_web_libro_venta     los puntos de venta de cada libro visible (1.21.0)

Las crea y las mantiene gbpublisher. Si cambia una tabla interna, se adapta la VIEW y gbWeb no se entera. La regla de visibilidad (SC-80) está una sola vez, en el WHERE de `v_web_libro`; las otras cuatro la heredan porque se unen con ella.

Las columnas que se agregan van al final, como en las tablas (SC-22), con `CREATE OR REPLACE VIEW`, que conserva el permiso de la cuenta (GV-177):

- 1.20.0, `v_web_libro`: `licencia` (es `licencia_defecto`, la etiqueta del catálogo: «CC BY 4.0») y `url_licencia`.
- 1.21.0, `v_web_libro`: `idioma_nombre` e `idioma_nombre_ingles` (LEFT JOIN al catálogo `idiomas`) y los pares de texto e idioma `resumen_traducido`, `resumen_traducido_2`, `palabras_clave_traducidas`, `palabras_clave_traducidas_2`. Queda con 32 columnas.
- 1.22.0, `v_web_libro`: `destino_html` y `url_portal` (SC-85). Queda con 34 columnas. gbWeb avisa al construir si un libro integrado declara otro portal.
- 1.21.0, `v_web_libro_persona`: `id_autor`. gbWeb reconoce a la misma persona en otro libro por él, nunca por el nombre. No exponen el email ni la afiliación de las personas ni ningún campo interno (`notas_internas` y similares): la VIEW es también el filtro de lo público.

LA CUENTA: UNA POR APLICACIÓN

gbWeb se conecta con `gbweb_lector`, una cuenta de MySQL con `SELECT` solo sobre las VIEW del contrato (cinco desde la 1.21.0). Desde el 04/11/2026 tiene además `SELECT`, `INSERT`, `UPDATE` y `DELETE` sobre el esquema propio de gbWeb (`gbweb`, SC-80), sin permisos de estructura: la misma cuenta con más permisos y una sola credencial (decisión de Alberto). Sobre gbpublisher no cambia nada. No es un usuario de trabajo (esos se dan de alta en FSysAdmin, en la tabla `usuarios`): es una credencial de infraestructura, como `app_user`. Las VIEW son `SQL SECURITY DEFINER`, así que la cuenta las lee sin permisos sobre las tablas, y cualquier otra cosa le da error 1142 (GV-167): el aislamiento lo garantiza el motor, no la disciplina. Con `app_user` el contrato sería una costumbre, no un límite. La crea `crear-cuenta-gbweb.sh`, en el repositorio de gbWeb (privado), no el script de esquema: tener gbWeb es una decisión de cada instalación, y gbWeb es de uso casi exclusivo de la editorial.

- Se corre SIN sudo y lo pide cuando lo necesita: la credencial es del usuario que va a correr gbWeb y va a su carpeta personal. Con sudo se niega.
- La clave la genera el script (decisión de Alberto, 02/11/2026): 28 letras y cifras al azar más un sufijo fijo con mayúscula, minúscula, cifra y símbolo, por si el servidor tiene `validate_password`. Nadie la tipea ni la recuerda, y no queda en ningún repositorio. Viaja al servidor por la entrada estándar, no por la línea de comandos.
- La guarda en `~/.gbweb/conexion.conf` (carpeta 700, archivo 600), escrito entero y movido a su lugar. Es un archivo de opciones de MySQL: `[client]` con `user`, `password`, `host` y `database`. El propio cliente lo lee con `mysql --defaults-extra-file`, y gbWeb solo necesita esas cuatro líneas.
- Idempotente, por el estado real: la cuenta existe; sus permisos son exactamente SELECT sobre las VIEW (en `information_schema`: `TABLE_PRIVILEGES`, `SCHEMA_PRIVILEGES` y `USER_PRIVILEGES`); la clave del archivo abre la sesión. Lo que no está en regla se corrige: crea la cuenta, renueva la clave (`ALTER USER`) o repone los permisos (`REVOKE ALL PRIVILEGES, GRANT OPTION` y un `GRANT` por VIEW). Exige la versión del esquema que crea la última VIEW (hoy, la 1.21.0). Si todo está en regla, no hace nada.
- Verifica con la clave del archivo: lee `v_web_libro`, NO lee `libros_md` y ve solo las VIEW del contrato (GV-167).
- No es un cambio de esquema: no toca la base gbpublisher, no hace respaldo ni escribe en `esquema_version`.

Probado en el contenedor con un usuario común y sudo, en siete situaciones: primera corrida, segunda, archivo borrado, un permiso de más, clave equivocada, cuenta borrada con archivo viejo y una corrida más con todo en regla.

LOS DATOS

- Personas: una fila por persona y libro, y la agrupación la hace la XSLT. Sin `GROUP_CONCAT`, que corta en `group_concat_max_len` sin error. `nombre_mostrar` es `nombre_preferido`, o `nombre_completo` si está vacío. Los nombres de los roles («coord.», «comp.») son textos de interfaz: los traduce gbWeb.
- Mes: `libros_md.mes_publicacion` es texto («Noviembre»). La VIEW lo da como número (`mes_numero`), con setiembre y septiembre; otro valor sale NULL. Se resuelve en la VIEW, no con una migración de la columna.
- Los tres idiomas del libro (1.21.0, decisión de Alberto): el modelo de los capítulos. El resumen y las palabras clave en el idioma principal y en dos traducciones, cada una con su código del catálogo: seis columnas al final de `libros_md` (`resumen_traducido_2`, `palabras_clave_traducidas`, `palabras_clave_traducidas_2` y su `idioma_…` cada una). Al guardar, un texto cargado exige su idioma (`m_Idiomas.IdiomaAsignado`) y las dos traducciones de un mismo texto no pueden estar en el mismo idioma (`m_Metadatos.IdiomasDistintos`): gbWeb elige el resumen por el idioma de la página.
- Los puntos de venta (1.21.0, decisión de Alberto): `libro_venta`, una fila por tienda. `id_libro` (FK a `libros_md`, CASCADE), `tienda` ENUM (`amazon`, `apple`, `google`, `mercadolibre`; su orden es el de los botones), `url` `VARCHAR(500)` NOT NULL con `CHECK` `^https?://[^ ]+$`; clave (`id_libro`, `tienda`). Reemplaza a `url_compra` (1.19.0), que quedó en desuso: la 1.21.0 pasó su valor a la fila `mercadolibre` y la dejó en NULL. No se edita ni se lee; no se borra porque la nombra `v_web_libro`.

EL ORDEN LO PONE gbWeb

Una VIEW no garantiza el orden de las filas: gbWeb lo pide al consultar.

    libros     ano_publicacion DESC, mes_numero DESC, id_libro DESC
    personas   id_libro, orden_autoria, id_relacion
    ventas     tienda   (un ENUM ordena por su posición, GV-176)

Con `DESC`, MySQL pone los NULL al final: un libro sin mes va detrás de los de su año (GV-167). `orden_autoria` no es único en `libro_autor` y `id_relacion` desempata.

LA TAPA WEB, EN LA BASE

La identidad del proyecto es el nombre de su .md, no la carpeta (SC-82): la base no sabe dónde está `media/`. Solo gbpublisher, con el proyecto abierto, puede leer la tapa. Por eso la convierte al guardar y deja el resultado en la base, en `libro_tapa_web`:

    id_libro   INT, clave; FK a libros_md, CASCADE
    imagen     MEDIUMBLOB, el JPEG ya convertido
    formato    'jpg' (CHECK)
    ancho      INT > 0
    alto       INT > 0
    sha256     CHAR(64) ascii_bin, hexadecimal en minúsculas (CHECK)

- Conversión: color a sRGB, aplanado sobre blanco, `-resize '600x>'`, `-strip`, JPEG calidad 80 (detalle en CÓMO SE GENERA). Unos 117 KB por tapa (GV-156). El ancho alcanza para la tarjeta y la ficha en pantallas de alta densidad.
- `sha256` se calcula en el propio SQL con `SHA2(imagen, 256)`, que da lo mismo que `sha256sum` (GV-168).
- Sin fecha de actualización, a propósito: nada variable llega a la salida.
- gbWeb escribe los bytes tal cual: el determinismo está en lo guardado. Publica `tapas/<id>-<primeros 8 del sha256>.jpg`: si la tapa cambia, cambia el nombre y ningún navegador muestra la vieja. Con `ancho` y `alto` pone `width` y `height` en el `<img>`, y la página no salta mientras carga.

Así el contrato no depende de ninguna ruta ni de ninguna máquina, y viaja en los respaldos de `mysqldump`. Una persona que carga el fondo desde otra computadora no necesita compartir carpetas.

CÓMO SE GENERA (decisiones de Alberto, 04/11/2026)

- `engine/tapa_web.sh <ruta_proyecto> <imagen_tapa>`, por la lanzadora (SC-53). No toca la base (SC-13): deja `tmp/tapa-web.jpg` y sus medidas en `tmp/tapa-web.txt` («ancho alto», leídas del resultado y no calculadas). Solo png y jpg, los formatos que acepta el formulario.
- La receta, en este orden: el color con `receta_color_srgb` de `comun.sh`, la misma de las imágenes de pantalla (SC-76), porque una tapa de imprenta suele venir en CMYK y `-strip` borra el perfil; aplanado sobre blanco (`-background white -flatten`), porque JPEG no tiene transparencia y la zona transparente de un PNG saldría negra; `-resize '600x>'`; `-strip`; JPEG calidad 80.
- `m_TapaWeb` (Gambas) lee los dos archivos y reemplaza la fila en una transacción: `DELETE` y `INSERT … VALUES (&1, &2, 'jpg', &3, &4, SHA2(&2, 256))`. Los bytes y su huella salen del mismo valor (GV-168). La tapa vieja se va solo si la nueva entra. Un libro que ya no declara tapa pierde su fila: una tapa quitada no sigue publicándose.
- CUÁNDO: al cerrar FMetadatosLibro, si se guardó. El formulario levanta `m_TapaWeb.Pendiente` y FMain, al volver de `ShowModal`, llama a `AtenderPendiente`: la lanzadora escribe en la terminal de FMain, que el formulario modal tapa. La marca vive en el módulo porque la instancia del formulario no sobrevive a su cierre (RC-GM-13). Es el camino de los libros del fondo, que nunca generan salidas. Además, después de generar el HTML del libro, si salió: cubre una tapa reemplazada en `media/` sin volver a guardar el formulario.
- El mensaje aparece solo si falla; en el éxito lo dice la terminal, y otro mensaje después de «Metadatos guardados» sería ruido.
- Las cuatro tiendas se cargan en FMetadatosLibro, debajo de las descargas. `m_VentaLibro` las carga, las valida con la regla del CHECK y las reescribe después del `Update` del libro, en una transacción (`Begin`, `DELETE`, los `INSERT`, `Commit`; GV-173). Vuelve a leer el `id_libro`, que un libro recién creado no tenía.

MEDIDO (contenedor; MySQL 8.0.46, ImageMagick 6.9.12-98, perfiles de TeX Live): siete tapas de prueba —sRGB grande y chica, CMYK con y sin perfil, Adobe RGB, grises, PNG con transparencia— dan los mismos bytes en dos corridas, los CMYK salen en sRGB y la transparencia en blanco. `m_TapaWeb` en un banco con MySQL: sin guardado no hace nada; con guardado convierte y guarda (el `sha256` de la fila es el del archivo); una segunda vez reemplaza sin duplicar; una tapa que falta en `media/` avisa y deja la anterior; un libro sin tapa queda sin fila. El proyecto completo compila con los cambios (gbc3 3.19, con gb.db y Qt5 en lugar de gb.db2 y Qt6). En Linux Mint (Alberto, 04/11/2026, Gambas 3.22): al guardar y cerrar el formulario, la terminal mostró la conversión, y la fila de `libro_tapa_web` tiene el mismo `sha256` que `tmp/tapa-web.jpg` (GV-168). Es también el mismo que la prueba del 02/11 sobre esa tapa: la receta da los mismos bytes en días distintos, y el aplanado sobre blanco no cambia una tapa sin transparencia.

EL LOTE DE 1.19.0 (SC-22)

`m_ConexionBD.ObtenerEsquemaEsperado`: `libros_md` pasa de 79 a 80 y entra `libro_tapa_web` con 6. Las VIEW no se cuentan: `ValidarEsquemaBD` solo mira las tablas que lista.

LA 1.20.0 Y LA 1.21.0

- 1.20.0: sin lote; solo cambia la VIEW.
- 1.21.0: `libros_md` pasa de 80 a 86 y entra `libro_venta` con 3; va con el `.deb` que trae el formulario nuevo. `crear-cuenta-gbweb.sh` suma el permiso sobre `v_web_libro_venta`.
- MEDIDO (contenedor, MySQL 8.0.46): la primera corrida de la 1.21.0 aplica todo (17 URL de compra pasan a `mercadolibre`, las seis columnas al final, las VIEW DEFINER, el permiso de la cuenta intacto); la segunda no tiene nada que cambiar; la vuelta atrás que imprime (DROP de lo nuevo y restauración, GV-169) deja la base en 80 columnas y la VIEW en 22. Aplicada por Alberto en Linux Mint el 04/11/2026, con el portal reconstruido.

BASELINE 2.0.0 (20/11/2026, SC-102). Las cinco VIEW viajan en el baseline: `generar-baseline.sh` vuelca la estructura de la base entera, vistas incluidas; enumera `BASE TABLE` solo para contar y para separar las semillas. Medido al cargarlo: las cinco vistas, iguales a las de la base de origen. `url_compra` NO se retiró en la 2.0.0: la nombra `v_web_libro`, que lee gbWeb, y gbWeb no se revisó en este lote.

**Relaciones:** vinculo:SC-80,vinculo:SC-82,vinculo:SC-22,vinculo:GV-74,apoya:GV-156,apoya:GV-167,apoya:GV-168,apoya:GV-169,apoya:GV-170,vinculo:SC-76,vinculo:SC-53,vinculo:RC-GM-13,apoya:GV-173,apoya:GV-176,apoya:GV-177,vinculo:SC-83,vinculo:SC-85,vinculo:SC-102,vinculo:SC-106

**PENDIENTE:** Revisar las exportaciones e importaciones que recorren todas las columnas de `libros_md` (SC-22, lote 3). Las hojas DocBook y EPUB del libro todavía no usan las traducciones nuevas del resumen y de las palabras clave. Retirar `url_compra` de `libros_md` y de `v_web_libro` junto con una revisión de gbWeb: no entró en el baseline 2.0.0.

### SC-82 — La identidad de un proyecto es el nombre de su .md, no la carpeta que lo contiene

**Estado:** vigente

Decisión de Alberto, de siempre; escrita el 02/11/2026. gbpublisher identifica un proyecto por el nombre de su archivo (`l-*.md`, `r-*.md`; en proyectos anteriores, `.tex`). En la base, `proyectos.nombre` guarda solo ese nombre, sin ruta.

La carpeta puede llamarse de cualquier forma y estar en cualquier lugar: un `git clone` la trae con otro nombre, y en la máquina de Alberto `l-JENSEN.md` está en `Jensen/`. Del nombre del archivo no se deduce la carpeta.

CONSECUENCIAS

- Ninguna tabla guarda la ruta de un proyecto, ni siquiera relativa a un directorio base.
- Lo que otra aplicación necesita de la carpeta lo saca gbpublisher cuando el proyecto está abierto, y lo deja en la base. El primer caso es la tapa web de gbWeb (SC-81).

Es la misma idea que SC-16: el .md viaja solo.

**Relaciones:** vinculo:SC-16,vinculo:SC-81,vinculo:SC-103

### SC-83 — gbWeb: cómo se construye el sitio (sitio.xml, portal.xsl, construir_sitio.sh, docs/) y el esquema gbweb

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbWeb / Saxon-HE 12.5 / Pandoc 3.1.3 / MySQL 8.0.46 / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-11

Decisiones de Alberto, 02 al 04/11/2026. Lo que muestra el portal está en SC-80 y lo que lee de gbpublisher, en SC-81. Acá, cómo se arma y por qué sale siempre igual.

DETERMINISMO

Los mismos datos dan los mismos bytes: plantillas cerradas, con una lista finita de variables de diseño; orden explícito y con desempate, nunca el de la base (SC-81); sin fecha de generación en la salida; la tapa llega ya convertida y gbWeb copia sus bytes (SC-81). Es el criterio de exportación de SC-50: el diff de git muestra solo lo que cambió. `construir_sitio.sh` termina imprimiendo la huella de `docs/`, y dos construcciones seguidas dan la misma.

- Las fuentes WOFF2 no se generan en cada construcción: son archivos fijos de `.hidden/sitio/fuentes/`, con su licencia OFL (GV-180).
- Las imágenes que gbWeb convierte llevan `-strip` y `-define png:exclude-chunks=date,time`: un PNG guarda la fecha si no.

CÓMO SE ARMA

- Motor: XSLT con Saxon. gbWeb (Gambas, `m_Sitio`) vuelca las VIEW del contrato y sus datos propios en `tmp/sitio.xml` y las tapas en `tmp/tapas/`; una sola corrida de `portal.xsl` genera el sitio entero, una página por `xsl:result-document`, en los tres idiomas. Gambas lleva los datos y la interfaz; XSLT, la presentación. `sitio.xml` queda como archivo intermedio que se puede comparar.
- Páginas: inicio, catálogo (`catalogo/`, `catalogo/2/`…), la ficha de cada libro (`libro/<id>/`) y las páginas escritas (`<clave>/`), con el español en la raíz y el inglés y el portugués en `en/` y `pt/`. Sin redirección por JavaScript.
- URL de la ficha: `id_libro`, lo único que gbpublisher garantiza estable. En la revista, volumen y número.
- Se armó primero un esqueleto de punta a punta (las VIEW, `sitio.xml`, una XSLT, portada y fichas, dos construcciones con la misma huella) y los formularios crecieron encima.

LA CARPETA DEL PORTAL

    <CÓDIGO>.md   el anotador (SC-80); no interviene en la construcción
    media/        los originales: logo-portal.<ext> e imagen-NN.<ext>
    paginas/      las páginas escritas, <clave>.<idioma>.md
    tmp/          sitio.xml, tapas/, paginas/; fuera de git
    docs/         el sitio, ENTERO de gbWeb: cada construcción lo reemplaza
                  y lo puesto ahí a mano se pierde

- EL LOGO: se copia a `media/logo-portal.<ext>`, borrando antes los de otra extensión. LAS IMÁGENES, como en gbpublisher: una que ya está en `media/` se activa sin copiar; una idéntica a otra de `media/` (comparados los bytes) no se duplica; las demás se copian como `imagen-NN`. La activa la guarda la base (`gbweb` 1.1.0).

sitio.xml

    <sitio codigo tipo logo imagen>
      <datos> nombre, url-base, direccion, correo, ano-inicio, licencia,
              <red tipo>url</red>…
      <libro id estado acceso idioma ano mes>
        titulo, subtitulo (planos: el corte \\ es un espacio, SC-28),
        isbn-impreso, isbn-electronico, paginas, url-libro, url-pdf, url-epub,
        <idioma-nombre es en/>, <resumen idioma>…, <palabras-clave idioma>…,
        <licencia url>, <coleccion id numero>, <persona id rol orcid>…,
        <venta tienda>url</venta>…, <tapa archivo ancho alto sha256/>

Un dato que falta no aparece: la XSLT decide con eso. El resumen y las palabras clave del idioma principal van primero.

construir_sitio.sh

Corre por la lanzadora (SC-53) y no toca la base (SC-13): todo lo que necesita lo dejó Gambas en `tmp/`.

1. Comprueba `sitio.xml` y cada tapa: la forma del nombre (`<id>-<sha8>.jpg`) y su sha256 contra el del XML.
2. El logo y la imagen activa, publicados con su huella; sin imagen, la de por defecto, con un aviso.
3. Avisa si faltan el nombre o la URL del sitio.
4. Las páginas escritas: crea las que faltan con «Acá va el texto» (nunca pisa) y las pasa con Pandoc a un fragmento XML (GV-181), envuelto en un `<div>` y validado con `xmllint`. Un nombre fuera de la matriz se avisa. Las imágenes dentro de una página escrita todavía no se publican: se avisa.
5. Saxon, con los parámetros del logo, la imagen y sus medidas, y la hoja de estilo, en `tmp/docs-nuevo/`.
6. Copia las tapas, la hoja de estilo, las fuentes con su licencia, las banderas y los íconos PNG.
7. Reemplaza `docs/` (pasando la anterior por `tmp/docs-anterior`) e imprime la huella.

NOMBRES CON HUELLA

Lo que cambia de contenido cambia de nombre: `tapas/<id>-<sha8>.jpg`, `media/logo-portal-<sha8>.<ext>`, `media/destacada-<sha8>.<ext>`, `estilo-<sha8>.css` (los primeros 8 del sha256). Así ningún navegador ni GitHub Pages sirve de su caché una versión vieja. Se agregó para la hoja de estilo cuando un CSS viejo siguió publicado después de corregido.

LOS ENLACES

- Internos: relativos y con `index.html` explícito, para que el sitio funcione abierto desde el disco, en el visor de gbWeb (GV-179).
- `canonical`, `og:` y `hreflang`: absolutos, con la URL del sitio (`url_base`). Sin ella no van, y tampoco los botones de compartir.
- Los de compartir, con `encode-for-uri` sobre la URL y el título de la página.

EL MARCO PARA LAS OBRAS INTEGRADAS (05/11/2026; .xml desde el 07/11/2026)

Con la dirección del sitio, `portal.xsl` escribe además la cabecera y el pie de cada idioma como fragmentos XML, `marco/<idioma>/cabecera.xml` y `pie.xml`, con `marco` en verdadero: enlaces absolutos a `url_base`, el logo relativo al fragmento (`../media/…`) y los botones de compartir con los patrones `{u}` y `{t}`, que gbpublisher completa en cada página de la obra. Sin banderas: la obra está en un idioma. El paso 7b de `construir_sitio.sh` suma la hoja con nombre fijo (`marco.css`), las fuentes con su licencia y el logo, y escribe `marco/marco.xml`: el portal (`codigo`, `url-base`) y cada archivo con su sha256, en orden fijo. Lo baja y lo verifica gbpublisher (SC-85).

POR QUÉ .xml: un servidor puede reescribir los .html que publica. Netlify, con «Pretty URLs», cambia los enlaces `…/index.html` por `…/` (GV-188): la cabecera llegaba con otros bytes y gbpublisher la rechazaba por su sha256, mientras el pie, sin enlaces internos, pasaba. Los fragmentos ya eran XML (gbpublisher los lee con `doc()`); con la extensión `.xml` se sirven tal cual. Además el despliegue apaga Pretty URLs (SC-84), para que lo publicado sea lo construido.

EL ESQUEMA gbweb

Los scripts del repositorio de gbWeb siguen las reglas de SC-22 (cadena en SC-22):

- 1.0.0: `portal` y `portal_libro` (SC-80).
- 1.1.0: `portal.logo` y `portal.imagen_destacada`, solo el nombre, sin ruta (SC-82), con CHECK de su forma: `logo-portal.(svg|png|jpg)`, `imagen-NN.(jpg|png)`.
- 1.2.0: `portal.nombre`, `url_base`, `direccion`, `correo`, `ano_inicio` y `licencia` (NULL si no hay dato; CHECK de la forma: la URL con `/` final, el correo nombre@dominio.algo, el año entre 1000 y 2999), y `portal_red` (`id_portal`, `red` ENUM de las 9 redes del pie, `url` https con CHECK; clave `id_portal`, `red`). Se editan en FDatosPortal (SC-84).

MEDIDO (contenedor; Saxon-HE 12.5, Pandoc 3.1.3, MySQL 8.0.46): la misma huella en dos construcciones seguidas, también después de reescribir `sitio.xml`; 1758 enlaces locales sin uno roto en el portal de prueba (18 libros, tres idiomas); los sugeridos de SC-80 con un `sitio.xml` armado para cada escalón.

**Relaciones:** vinculo:SC-80,vinculo:SC-81,vinculo:SC-84,vinculo:SC-50,vinculo:SC-53,vinculo:SC-13,vinculo:SC-22,vinculo:SC-28,apoya:GV-179,apoya:GV-180,apoya:GV-181,apoya:GV-182,apoya:GV-183,apoya:GV-186,vinculo:SC-85,apoya:GV-188

**PENDIENTE:** Las imágenes dentro de las páginas escritas. El índice de búsqueda y `sitemap.xml` (SC-80).

### SC-84 — gbWeb: la aplicación (ventana, salida, entorno) y el despliegue en GitHub

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbWeb / Gambas 3.22 (gb.db2, gb.qt6) / Linux Mint; Gambas 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Decisiones de Alberto, 04/11/2026. gbWeb sigue el modelo de gbpublisher siempre que puede: quien usa una sabe usar la otra.

LA VENTANA (FMain)

- A la izquierda, la grilla de libros disponibles con su buscador y los botones para asociar y quitar (SC-80), y debajo la terminal; a la derecha, el visor (WebView) con el sitio construido.
- El reparto entre las dos mitades es FIJO, como en gbpublisher: `spPrincipal_Resize` vuelve a poner el `Layout` cada vez, porque el Splitter dispara `Resize` mientras se arrastra el separador (GV-171).
- Menú «Acciones»: abrir portal, «Datos del portal…», desplegar, salir. Botones: logo, imagen, construir. Mientras corre un script, la lanzadora bloquea los que lanzarían otro.
- Los mensajes de la lanzadora son neutros («terminó correctamente»): no hablan de una acción en particular.

SALIR

Un solo camino, por el menú o por la X (`Form_Close` frena el evento y llama a `Salir`): pregunta (y avisa si hay un proceso en la terminal), mata el bash de la terminal, cierra la conexión y termina con `Quit`. Con `Me.Close` solo, la ventana se cerraba y el programa seguía vivo (GV-174). Es lo que hace `m_InicioCierre.CerrarTodoMySQL` en gbpublisher; la diferencia, deliberada, es que en gbWeb la X sale y no solo avisa.

EL ENTORNO

- Las 17 líneas `StartupEnvironment` de gbpublisher, en el `.project`: modo claro (`GB_GUI_DARK_THEME=0`), estilo Fusion, X11. Llegan al proceso antes de que se carguen los componentes (GV-172).
- Los recursos (`engine/`, `xslt/`, `css/`, `sitio/`) se toman de `.hidden/` del proyecto y, si no están, de `/usr/share/gbweb`: desde el IDE, los de la versión en ejecución (criterio de SC-11).
- Las preferencias, en `~/.gbweb/gbweb.conf` (`New Settings`), como gbpublisher; la credencial de la base, en `~/.gbweb/conexion.conf` (SC-81).

LOS DATOS DEL PORTAL (FDatosPortal)

Desde «Datos del portal…»: nombre, URL del sitio, dirección, correo, año de inicio, licencia de los textos y un perfil por red. Las filas de las redes se arman en el código, una por red del ENUM, y el formulario ajusta su alto a ellas al mostrarse. `m_DatosPortal` valida con las mismas reglas que los CHECK (la URL termina en `/`, que se agrega si falta; el año, cuatro cifras; los perfiles, `https://` sin espacios) y guarda todo en una transacción. Es también el canal de retorno del formulario (RC-GM-13).

DESPLEGAR

- `desplegar_portal.sh`, por la lanzadora: comprueba la clave SSH de GitHub; crea el repositorio con la rama `main` si no lo hay; pone `/tmp/` en `.gitignore`; si falta el remoto, pone `git@github.com:<usuario>/<código>.git`; `git add -A`, commit si hay cambios y push. Que lo corra un script y no comandos tipeados en la terminal es lo que permite saber si salió bien (SC-53).
- El repositorio se llama como el portal (SC-80) y tiene que existir en GitHub: el script no lo crea, y si no está, el push falla con ese mensaje.
- Si el remoto usa HTTPS, gbWeb ofrece pasarlo a SSH antes de pedir nada (`VerificarProtocoloRemoto` de gbpublisher). Para comparar el remoto se lee `git config --get remote.origin.url` (GV-178).
- FCommits pide el usuario de GitHub (propone el último, guardado en `gbweb.conf`, sección `[GitHub]`; se controla con la forma de los usuarios de GitHub porque va en la URL) y el mensaje del commit. Los dos vuelven por `m_Desplegar`; la decisión, por `ShowModal` (RC-GM-13).
- Se suben el `.md`, `media/` y `docs/`; `tmp/` no. Durante el desarrollo el repositorio es público; después, privado, con Netlify publicando `docs/`.
- `netlify.toml` en la raíz del repositorio, al lado de `docs/`, con `[build.processing.html] pretty_urls = false` (decisión de Alberto, 07/11/2026): Netlify no reescribe lo que publica (GV-188). Lo escribe el script si falta; si existe y no apaga Pretty URLs, avisa y no lo pisa. El archivo pisa el interruptor del panel de Netlify (documentación de Netlify, «File-based configuration»).

PROBADO por Alberto en Linux Mint (04/11/2026, Gambas 3.22, gb.db2 y Qt6): el despliegue de `L-IMAGO`, y la salida por el menú y por la X, que termina el programa.

**Relaciones:** vinculo:SC-80,vinculo:SC-81,vinculo:SC-83,vinculo:SC-53,vinculo:SC-11,vinculo:RC-GM-13,apoya:GV-171,apoya:GV-172,apoya:GV-174,apoya:GV-178,vinculo:GV-142,apoya:GV-188,vinculo:SC-103

**PENDIENTE:** El visor no muestra el portal hasta hacer clic en su borde. Mini-test propuesto: `wvPortal.Url = "about:blank"` al final de `Form_Open` (sospecha de Alberto: el momento en que se asigna la URL). Junto con eso, el `#` en la ruta (GV-142).

### SC-85 — HTML del libro integrado al portal de gbWeb: el destino, el marco descargado y la página (modelo 2)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher 1.22.0 / Saxon-HE 12.5 / vnu / contenedor Ubuntu 24.04; Gambas 3.22 y Netlify, Linux Mint · **Verificado:** 2026-11

Decisiones de Alberto, 05 y 07/11/2026; documento de trabajo `claude/gbweb.md`. El sitio de una obra es una salida HTML de gbpublisher (SC-80). Desde la 1.22.0 tiene dos destinos.

EL DESTINO, DATO DEL LIBRO

- `libros_md.destino_html` ENUM('autonomo','portal'), NOT NULL, 'autonomo' por omisión: lo que la salida HTML hacía hasta entonces. `url_portal`: la dirección del portal, con su `/` final, como `gbweb.portal.url_base`. Dos CHECK: la forma de la URL, y que el destino portal tenga su URL. Sin catálogo de portales: el portal es estable y es una sola URL por libro. Se cargan en FMetadatosLibro (`m_Metadatos.UrlPortalValida`: obligatoria con portal, forma, agrega la `/`).
- La vista del contrato (`v_web_libro`, SC-81) lleva las dos columnas: gbWeb avisa al construir si un libro integrado declara otro portal. La asociación de gbWeb decide qué libros aparecen en el portal; la URL del libro decide solo su cabecera.
- Revistas: el mismo par va en la revista, no en el número (decisión de Alberto, 07/11/2026, `claude/salidas-revistas.md`).

LA CABECERA DEL PORTAL, COPIADA AL GENERAR

gbWeb publica el marco (SC-83); `generar_html_libro.sh`, con destino portal, lo baja de `<url_portal>marco/`, controla cada sha256 y recién entonces reemplaza `docs/assets/marco/`. El libro no depende de que el portal responda después: sin red, usa el marco anterior si sigue íntegro y es del mismo portal, con aviso (código 3). Si el `url-base` del manifiesto no es la URL del libro, frena: el portal se mudó y hay que corregir el formulario. Con destino autónomo, el marco y la hoja integrada se borran de `docs/`: un libro que deja el portal no conserva restos.

POR QUÉ COPIADA: el sitio del libro es otro repositorio y otra dirección, y en un sitio estático nada junta dos sitios al mostrar una página; copiada, el libro funciona solo (sin JavaScript para la cabecera, aunque el portal esté caído, sin pedidos al portal ni CORS); es determinista (la cabecera queda fechada con la edición del libro); y al libro se llega seguido sin pasar por el portal (Google Scholar, el DOI, un enlace compartido), y la cabecera le da a ese lector el camino al catálogo. Descartadas: armarla al abrir con JavaScript (salto visible, sin cabecera si falla el portal o no hay JavaScript) y armarla en el servidor con funciones de Netlify (lo más complejo de montar). La primera se puede sumar después sin rehacer nada.

LA PÁGINA (MODELO 2)

- La hoja `docbook-to-html-portal.xsl` importa la autónoma y reemplaza solo la raíz y las plantillas de página: la salida autónoma no la lee y no puede cambiar. De la autónoma se extrajeron plantillas compartidas con salida idéntica byte a byte.
- Una sola familia, Noto Serif 400 y 600 con sus cursivas, y Noto Sans Mono para el código y «Cómo citar»; nada de IBM Plex (`gbpublisher-integrado.css`).
- Cabecera y pie del marco. El idioma del marco es el del libro si el portal lo publica (se compara la primera parte del código: `pt-BR` es `pt`); si no, el castellano.
- Barra del libro fija al desplazar: «Índice» abre un menú de 600 px sobre el texto (tapa chica, título, autoría y la lista, con la pieza actual en negrita; sin JavaScript, con una casilla; Esc lo cierra), dónde se está, y Anterior / Siguiente, que se repiten al final de la pieza.
- Dos columnas fijas en el ancho útil del portal (1168 px): texto 600 | calle 24 | panel 544 (notas, referencias, figuras), siempre a la vista. Debajo de 1232 px, el panel es un cajón.
- En la cabeza del texto, «Cómo citar» y el PDF del capítulo.
- Portada (`index.html`, adonde lleva «Leer en línea»), créditos (`creditos.html`) y dedicatoria son pasos de la lectura, en páginas separadas y fuera del menú (SC-25). «Cómo citar» del libro, a la derecha, en las tres; los metadatos para indexadores, solo en la portada.
- ORCID como en la ficha del portal: el nombre sin enlace y el ícono enlazado.
- Compartir: la URL de cada página es `url_libro` + su archivo; sin `url_libro` no hay botones de compartir.
- La validación HTML5 (vnu) recibe todos los .html de `docs/` menos los de `assets/marco/`: los fragmentos no son páginas.

PROBADO por Alberto en Linux Mint (07/11/2026): el libro de Duek integrado al portal L-IMAGO, publicado en Netlify. Abrir el portal, ir al libro, navegarlo y volver desde el libro al inicio y al catálogo, sin errores. Antes, en el contenedor: cero enlaces rotos, cero errores de vnu y la misma salida en dos generaciones.

**Relaciones:** vinculo:SC-80,vinculo:SC-81,vinculo:SC-83,vinculo:SC-84,vinculo:SC-25,vinculo:SC-53,vinculo:SC-22,apoya:GV-188

**PENDIENTE:** El HTML integrado de las revistas (etapa A de las salidas de revistas): la ficha del número y «Archivos» en gbWeb. Las figuras en el panel con el pie completo y uno corto en el texto (pedido de Alberto).

### SC-86 — Nota con símbolo en un título de sección: \footnote{símbolo}{texto}, con el diccionario de la AMS (libros)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / jing 20220510 / LuaLaTeX (TeX Live 2023) con titlesec 2.16, footmisc, scrextend y hyperref / fontTools / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (decisiones de Alberto, 11/11/2026). Deja sin efecto la renuncia de SC-29: un título de sección puede llevar una nota con símbolo en lugar de número, como `\Footnote{}{}` en LaTeX (consejo de la AMS). Por ahora solo en libros; las revistas, después de su refactorización.

CÓMO SE ESCRIBE

    ## La edición universitaria\footnote{*}{Versión revisada de la ponencia leída en las *Jornadas*.}

El primer par de llaves lleva el símbolo; el segundo, el texto, en Markdown (bastardilla, citas, volada, cifras). Pegado al título y entero en su línea. El sumario sale solo, como en SC-29: no hace falta escribir el argumento opcional.

EL DICCIONARIO

La secuencia de la AMS sin ‖, que IBM Plex Sans y Plex Sans Condensed no tienen (medido con fontTools):

    en el .md       *    \dag   \ddag   \S   \P   **     \dag\dag   \ddag\ddag
    signo           *    †      ‡       §    ¶    **     ††         ‡‡
    nombre (label)  ast  dag    ddag    S    P    ast2   dag2       ddag2
    índice (PDF)    1    2      3       4    5    6      7          8

Cerrado (decisión de Alberto): sin números, que chocarían con la numeración, ni otros signos. Tres gemelos, en el mismo orden: `nota-simbolo.lua`, `nota-simbolo-comun.xsl` y `\gbSimboloNota` del contrato.

EL SÍMBOLO LO ELIGE QUIEN EDITA

Sin contador: el símbolo es un dato del canónico y sale igual en todas las salidas. La regla de la página —el mismo símbolo puede volver cinco páginas después, nunca dos veces en la misma— la controla quien edita en la prueba del PDF, como en LaTeX (decisión de Alberto). Un contador por página (footmisc `perpage`) daría símbolos distintos en el PDF y en la web, y reiniciaría también las numeradas. Las numeradas no se enteran: 1, 2, *, 3, 4, **, 5.

LA REGLA

- Solo en un título de sección: `##` y siguientes. En el `#` del capítulo, que sale de la base (SC-28), o fuera de un título, frena.
- Una sola nota por título, numerada o con símbolo (decisión de Alberto: lo que sobre es un tema de corrección con el autor). titlesec guarda una sola (GV-190): lo informa el control `nota_doble_en_titulo` (SC-54) y lo frena el filtro.
- Frena también: un símbolo fuera del diccionario; un solo par de llaves; un espacio entre los dos pares; el texto sin la llave de cierre (una nota partida en dos líneas); el texto vacío; una nota dentro de la nota.

CANÓNICO

`nota-simbolo.lua`, en la cadena del libro después de `volada.lua` y antes de `corte-titulo.lua`, reconstruye la nota desde lo que deja Pandoc (GV-189): cuenta las llaves en los Str del primer nivel, arma un Note con la marca `<?gb-nota-simbolo ast?>` al comienzo y rearma el identificador automático del título, que traía el texto de la nota. `cite-to-biblioref-db.lua`, que serializa las notas, quita la marca y la pasa al atributo:

    DocBook   <title>La edición universitaria<footnote label="ast"><para>…</para></footnote></title>

`label` es NMTOKEN: va el nombre, no el signo (GV-191). `controles_md.lua` admite `\footnote{…}` en `latex_en_linea`.

PDF (CONTRATO 22)

- `docbook-to-latex.xsl`: en la apertura del título, `\gbNotaTituloSimbolo{N}{texto}`; fuera de un título, `\gbNotaSimbolo{N}{texto}`. El sumario, el folio y los marcadores van sin la nota, como en SC-29.
- `\gbNotaSimbolo{N}` es `\footnote[1000+N]`: con el argumento opcional no avanza el contador, y titlesec difiere la nota con el mismo valor (GV-190). `\gbNotaTituloSimbolo` no emite nada cuando titlesec mide el título (GV-70).
- La estética arma `\thefootnote` con `\gbMarcaNota{[\arabic{footnote}]}`: un valor mayor que `\gbBaseSimbolo` (1000) compone el símbolo, sin corchetes; si no, la marca numerada de la casa. Una estética de editorial que no use `\gbMarcaNota` mostraría «[1001]».
- La llamada con símbolo de un título no tiene vínculo en el PDF (GV-190; aceptado por Alberto): el lector ve el símbolo al pie de la misma página.

HTML

`docbook-to-html.xsl`: la marca es el signo y no se cuenta en la numeración del capítulo; su `data-fn-id` es `s1`, `s2`… El panel muestra «Nota *» y la navegación cruzada funciona igual: el JS no cambia.

EPUB

`docbook-to-epub.xsl`: la llamada lleva el signo (`epub:type="noteref"`) y la lista de notas del capítulo la encabeza con el mismo signo; los ids son `fn-s1` y `fnref-s1`. Las numeradas se cuentan sin las de símbolo.

MEDIDO EN EL CONTENEDOR

Pandoc 3.1.3 con volada, nota-simbolo, corte-titulo y cite-to-biblioref-db: el capítulo valida contra el RNG de DocBook 5.2 (jing), y los once casos que frenan, frenan con su mensaje. SaxonJ-HE 12.5: `docbook-to-latex` (la apertura con la nota, el sumario sin ella), `docbook-to-epub` (ids y marcas) y la plantilla de nota de `docbook-to-html`. LuaLaTeX (TeX Live 2023, titlesec 2.16) con las capas reales del libro —contrato, contrato común, estética y hyperref; la estética con las Plex .ttf del sistema en lugar de .otf—: «1, 2, *, 3, 4, †, ‡, 5, [6] en un título, 7», cada nota al pie con su marca, sin avisos de hyperref, siete vínculos para las siete numeradas.

PROBADO EN MINT

Alberto, 11/11, con un libro real («El Atlántico de los exilios»): en el PDF, la llamada * en la apertura del título, sin corchetes, y al pie la nota con el mismo símbolo entre las numeradas, que siguen [2], *, [3]; en el HTML, la llamada * y «Nota *» en el panel; en el EPUB, la llamada * y la nota emergente encabezada por *. Liberada para libros con gbShortcodes `datos-v5-026.sql` (decisión de Alberto, 11/11).

**Relaciones:** vinculo:SC-29,vinculo:SC-28,vinculo:SC-54,vinculo:SC-63,vinculo:SC-62,vinculo:GV-70,vinculo:GV-189,vinculo:GV-190,vinculo:GV-191

**PENDIENTE:** Falta en Mint: epubcheck del EPUB, la inserción desde el panel, la ayuda y un caso que frene. Revistas, en la refactorización del módulo (otra conversación): el canónico JATS (fn/@symbol con <label>), jats-to-latex, jats-to-html, jats-to-epub, los sabores SciELO y Redalyc, y la fila nota-simbolo de no_aplica a borrador.

### SC-87 — Revistas: el canónico JATS por script — el volcado de la base, el front por XSLT, la validación y el camino que deciden los datos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / pandoc 3.1.3 / SaxonJ-HE 12.5 / xmllint / jats-schematrons v0.0.17 / gbc3 3.19 / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 7/11/2026; etapa A0 de las salidas de revistas, `claude/salidas-revistas.md`). El canónico JATS de cada artículo de un número del esquema nuevo (SC-71) lo arma un script de `engine/`, como el de los capítulos (SC-75). Gambas solo escribe la base como archivos (SC-13).

EL VOLCADO

`m_CanonicoRevista.PrepararNumero(iIdNumero, aArchivos)` escribe `tmp/numero-datos.xml`, un XML de datos (no JATS) con todo lo que las salidas necesitan del número: revista, número, secciones y plantillas con sus títulos por idioma, dossiers, preliminares y página legal (SC-88), y cada artículo en el orden de los archivos, con la herencia ya resuelta. También escribe el `reflist-{base}.xml` de cada artículo. Al final lista `<sin-metadatos>` (archivo sin fila) y `<huerfano>` (fila sin archivo), que el script informa.

El volcado lleva versión (`numero-datos/@version`). Cada lector exige la suya y frena con un mensaje si no coincide: `ensamblar-articulo-canonico.xsl`, `numero-a-latex.xsl`, `numero-maestro-latex.xsl`, `numero-a-epub.xsl`, `numero-a-html.xsl` y los scripts que lo leen. Historia: 1 (A0.2), 2 (los nombres de babel de cada idioma, resueltos con el catálogo), 3 (preliminares y página legal, SC-88), 4 (los textos del catálogo en el idioma del artículo, SC-90).

EL CANÓNICO

`engine/generar_canonicos_articulos.sh <proyecto> <lista>`, por artículo: controles del .md (`controles_md.lua`: un error frena el artículo, un aviso da código 3), huellas de las fuentes (SC-75), pandoc `--to jats` con `FILTROS_REVISTA`, `ensamblar-articulo-canonico.xsl` (que importa `ensamblar-canonico.xsl` para el cuerpo e incluye `datos-a-front-jats.xsl` para el front) y `mv`. Un artículo que falla pierde su canónico anterior. Rehace todos los de la lista aunque el .md no haya cambiado: el volcado puede traer datos nuevos. Al final corre `validar_canonicos.sh` anidado.

- Nombre: `jats/c-a-NN-x.xml`, con el prefijo del .md.
- `<article dtd-version="1.4" article-type xml:lang>`, con el identificador público real de la DTD: «-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.4 20241031//EN». El de `ensamblar-canonico.xsl` (camino viejo) no existe. La hoja sigue en uso porque `ensamblar-articulo-canonico.xsl` la importa: se revisa en el bloque 3 de SC-97.
- Front en el orden de la DTD: `contrib` con ORCID como URL, CRediT con vocabulario de JATS4R (GV-202), `aff` compartida con `institution-wrap` y ROR; `author-notes` con el conflicto de intereses y las notas; las dos `pub-date` (pub y collection); páginas o `elocation-id` solo si existen; `pub-history`; `permissions` siempre, con `ali:free_to_read` y `ali:license_ref`; `self-uri` por cada ubicación del artículo; `related-article` (un destino local sin DOI, con `@specific-use="gbpublisher-local:<archivo>"`); `abstract` estructurado con `sec`; `kwd-group` con `@kwd-group-type` y `@vocab`; un `funding-group`.
- La declaración de disponibilidad de datos va en el back como `<sec sec-type="data-availability">` (JATS4R).

LA VALIDACIÓN

`validar_canonicos.sh` con alcance `articulo`: la DTD JATS 1.4 (`xmllint --dtdvalid --nonet`) y JATS4R con una sola JVM por lote, las dos sobre una copia sin DOCTYPE. Las reglas de JATS4R se compilan con `generar-schematron-jats4r.sh` (herramienta de desarrollo, en la raíz del repositorio): clona jats-schematrons v0.0.17, comprueba el commit, compila el maestro con el esqueleto ISO (GV-26), copia los vocabularios que las reglas leen y prueba cinco instancias con resultado exacto antes de reemplazar el producto (`.hidden/schemas/jats4r/`).

EL CAMINO LO DECIDEN LOS DATOS

`m_GenerarSalidasRevista.ConfigurarControles` (al abrir el proyecto) muestra los menús del camino nuevo. Hasta el 18/11/2026, `NumeroEsNuevo` elegía entre el nuevo y el viejo según hubiera artículos en `articulo` (SC-98). Menú propio «JATS» (`mJats`, `menuJats`) para el XML, como `menuDocBook` en libros: «Canónico archivo en curso» y «Todos los canónicos». Las salidas van en `menuSalidaRevistaMD` (SC-89, SC-91, SC-92).

**Relaciones:** vinculo:SC-71,vinculo:SC-72,vinculo:SC-13,vinculo:SC-53,vinculo:SC-75,vinculo:SC-52,vinculo:SC-28,vinculo:GV-25,vinculo:GV-26,apoya:GV-202

**PENDIENTE:** El código ISO 3166 del país de la afiliación (la base guarda el nombre: JATS4R lo avisa). El vocab-identifier de MeSH y de DeCS. La figura de revista sin alt-text (JATS4R lo marca): decidir si controles_md lo avisa en revistas. Las reglas compiladas por grupo para el auditor de XML ajenos.

### SC-88 — Revistas: la editorial, los órganos editoriales y las preliminares del número

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / gbc3 3.19 / SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 12/11/2026; etapa B de las salidas de revistas). Modelo: el PDF de *Sociedad y Desigualdades* n.º 4 (UNPAZ): tapa, página legal y sumario.

LA EDITORIAL ES LA MADRE DE SUS REVISTAS

- Tabla `editorial` (nombre, institución, ROR, ciudad, país, prefijo DOI, correo, licencia, URL y titular por defecto) y `editorial_credito` (cargo, persona, desde, hasta): la producción y las autoridades viven en la editorial, con vigencia.
- `revista.id_editorial` NOT NULL. El correo queda también en la revista como reemplazo opcional; `tipo_acceso_defecto` sigue en la revista. La editorial se vinculaba solo a revistas; los libros, desde la 2.2.0 (LOS LIBROS, abajo).
- Esquemas: 1.26.0 crea las tablas y migra una editorial por grupo de identidad (frena si hay conflicto); 1.27.0 borra de `revista` las nueve columnas que pasaron.
- Interfaz: la pestaña «Revistas» de `FSysAdmin` pasa a «Editorial» (`m_Editorial`), con un botón que abre `FRevistas`. Una editorial se borra solo sin revistas; una revista, solo sin números.

LOS ÓRGANOS EDITORIALES

- `revista_organo` y `revista_organo_miembro` (persona de `autores`, afiliación de la membresía, desde, hasta). La afiliación se propone desde la ficha y no se sincroniza. Un órgano con miembros no se borra, se desactiva. `ValidarMiembro` frena períodos superpuestos de la misma persona en el mismo órgano.
- Buscador propio de personas (`FBuscarAutor`), con la conexión del administrador.

LAS PRELIMINARES

- Se declaran por número, como en libros (SC-25): `numero_pieza`, con tres nombres fijos (tapa, página legal, sumario): `fm-01-TAPA`, `fm-02-LEGALES` y `fm-03-SUMARIO` (`m_Numero.PiezasArchivos`), con la regla de SC-104. Hasta el 21/11/2026 eran `fm-01-tapa`, `fm-02-legales` y `fm-03-sumario`: el CHECK de la 2.1.0 acepta las dos formas y las filas viejas se reescriben al volver a guardar el número. El formulario ofrece las tres; no se crean solas.
- Fecha de referencia de las vigencias: el último día del mes del número (sin mes, el 31/12; sin año, frena si declara la página legal). El volcado (versión 3) trae `<preliminares>` y `<pagina-legal>` ya filtrados: un órgano sale si tiene algún miembro vigente a esa fecha. Ninguna salida decide vigencias.
- El rótulo del volumen es de la revista (`revista.rotulo_volumen`: «Año III»); el período, un solo mes.
- La tapa es `numero.imagen_tapa`: si el número declara la tapa y no tiene imagen, frena.
- Las arman el PDF del número (`numero-maestro-latex.xsl`, SC-89) y el EPUB (`numero-a-epub.xsl`, SC-91) con las mismas funciones (`revista-comun.xsl`: la conjunción «y/e», la persona, los tramos del sumario por sección o dossier). El sumario agrupa los artículos por tramo seguido del mismo dossier o, sin dossier, de la misma sección. Un órgano de un solo miembro va en línea.

LOS LIBROS (25/11/2026)

- `libro_editorial` (2.2.0, SC-22): las editoriales de cada libro, en orden. La de orden 1 es la principal: deposita en Crossref y da el lugar de edición (`{ciudad}`, `\gbciudad`).
- La ficha del libro tiene la lista, con Agregar, Quitar, Subir y Bajar (`m_EditorialLibro`, `CEditorialesLibro`). El correo del libro queda como «email-depositante», optativo, y reemplaza solo al de la principal. Una editorial con libros no se borra.
- La coedición va en todas las salidas, con los nombres unidos por la regla de `{autoria}` («A y B», «A, B y C», con y/e):
  - PDF: `{editorial}` de las primeras y `\gbeditorial`;
  - EPUB: la tapa y los créditos; en el OPF, un `dc:publisher` por editorial;
  - canónico: un `publisher` por editorial;
  - HTML (`docbook-to-html.xsl`, `$editoriales`): la cabecera, «Cómo citar», `citation_publisher` y los datos de citación con los nombres unidos; un `DC.publisher` por editorial; en Schema.org, una `Organization` o una lista;
  - Crossref: un `publisher` por editorial en `book_metadata`; en `book_series_metadata` el esquema admite uno solo, y va la principal (SC-108).
- Un libro con una sola editorial sale idéntico a antes (HTML de Duek, comparado byte a byte).
- La 2.4.0 borró de `libros_md` los datos que pasaron a la editorial (SC-22).

**Relaciones:** vinculo:SC-71,vinculo:SC-22,vinculo:SC-25,vinculo:SC-87,vinculo:SC-104,vinculo:SC-108

### SC-89 — Revistas: el PDF de cada artículo y el del número — contrato partido, primera página con columna, paginación que vuelve a la base y PDF/A-2u

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / LuaLaTeX y biber (TeX Live 2023) / veraPDF 1.30.3 / SaxonJ-HE 12.5 / gbc3 3.19 / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 7 a 14/11/2026; etapas A1, B5 y C de las salidas de revistas). Reemplaza la decisión 11 de SC-72 (componer el número y partirlo): cada artículo se compone solo y el PDF del número junta los PDF de los artículos.

EL CONTRATO DE LaTeX, PARTIDO

- `preambulo-contrato-comun.tex` (común a libros y revistas): corte y nota en títulos, paquetes, babel con los idiomas del volcado, csquotes, siunitx, cuadros, bloques, llamadas y código. Versión 2: el gancho de castellano y gallego (GV-200).
- `preambulo-contrato.tex` (libros, versión 21): lo que depende del capítulo (`\counterwithin*{gbcodigo}{chapter}`, `citereset=chapter`, GV-193).
- `preambulo-revista-contrato.tex` (versión 4): la primera página, los idiomas por código (`\gbselectlanguage`, `gbotroidioma`, GV-198), las declaraciones y las preliminares del número. La estética, en `preambulo-revista-estetica.tex`, sobre ganchos.
- Los `cita-*-config.tex` son comunes, sin `citereset`. Vancouver va por biblatex (biblatex-vancouver ajustado a la guía de la UAB, 2021).
- `numero-a-latex.xsl` escribe `preambulo-numero.tex` (idiomas con su nombre de babel, banderas, el .bib) y un `main-{archivo}.tex` por artículo, con `\DocumentMetadata` en su idioma.

LA HOJA

`jats-a-latex-articulo.xsl` importa `jats-to-latex.xsl` y reemplaza la primera página (la vieja frenaba con el front nuevo: dos `pub-date`). Primera página (modelo de Alberto, requisitos de Redalyc, SciELO, DOAJ y Latindex verificados en sus fuentes): títulos a ancho completo; a la izquierda los resúmenes con sus palabras clave; a la derecha una columna (autores con ORCID, correo y afiliación; notas de autor; edición y traducción; fechas; DOI o e-id; cómo citar; licencia y copyright; compartir), armada en caja (GV-197) y colocada a la altura del primer resumen. Si no entra, el `.log` lo dice y el script da código 3. Las declaraciones (CRediT, financiamiento, conflicto de intereses, disponibilidad de datos) van al final, en un bloque. El membrete de las interiores lleva los autores en forma corta. El «cómo citar» lo compone biblatex: la hoja escribe un .bib propio y `\fullcite` corre en una `refsection` aparte, en el estilo de la revista; el rango de páginas sale del propio LaTeX (una segunda pasada con `pagina_final`). La regla de agrupamiento de citas (SC-57) vale sobre JATS (`cita-jats-comun.xsl`). Rótulos, tipos, fechas y nombres salen de `revista-comun.xsl`, que comparten el EPUB y el HTML.

LA PAGINACIÓN

Cuatro modelos (`revista.modelo_paginacion`): `por_numero` (desde 1), `por_volumen` (el número sigue al anterior entero del mismo volumen; los suplementos empiezan en 1; `numero.pagina_inicial` manda si está cargada; sin las páginas del anterior y sin ese dato, frena), `por_articulo` (cada uno desde 1) y `continua` (e-id «e» + año + tres cifras, corrido en el año, asignado una vez y nunca renumerado; las páginas internas van de 1). Foliado corrido, sin páginas en blanco. La paginación nace en la composición y vuelve a la base: `generar_pdf_revista.sh` deja `tmp/paginacion.tsv` solo si todo salió bien, y Gambas lo guarda (`GuardarPaginacion`, sin tocar los publicados) y regenera los canónicos con los rangos. Un publicado que caería en otras páginas frena sin escribir nada. Publicar exige las páginas o, en `continua`, el e-id.

EL PDF DEL NÚMERO

`numero-maestro-latex.xsl` arma un maestro con las preliminares que el número declara (SC-88) y los PDF de los artículos ya compuestos, incluidos con pdfpages (GV-201: los enlaces quedan en los PDF sueltos). Folio del sumario: la página inicial, el e-id o nada, según el modelo. Escapa `< > "` (GV-199). Todo PDF de revista es PDF/A-2u y se valida con veraPDF; el PDF/X queda para después. Nombre: ACRÓNIMO-AÑO-vVOL-nNÚM[-sSUPL].pdf, armado por `nombre_numero` (`engine/revista_comun.sh`, GV-204); sin acrónimo o sin año, frena al empezar. Las salidas van a `salidas/pdf/`.

DESDE GAMBAS

`m_GenerarSalidasRevista`: «PDF del artículo en curso» (prueba, `{archivo}-prueba.pdf`, no escribe en la base) y «PDF completo del número en curso», un botón con todo encadenado (e-id, página inicial, composición, páginas a la base, canónicos de nuevo). `media/logo-revista.png` se escribe desde la base en cada composición.

**Relaciones:** vinculo:SC-72,vinculo:SC-87,vinculo:SC-88,vinculo:SC-57,vinculo:SC-31,vinculo:SC-13,vinculo:SC-53,apoya:GV-193,apoya:GV-194,apoya:GV-197,apoya:GV-198,apoya:GV-199,apoya:GV-200,apoya:GV-201,apoya:GV-204

**PENDIENTE:** La comilla recta en f:latex (GV-199). El PDF/X.

### SC-90 — Catálogos comunes de CRediT y licencias: el nombre del rol y el texto de la licencia por idioma, congelados al publicar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / gbc3 3.19 / SaxonJ-HE 12.5 / jats-schematrons v0.0.17 / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 14/11/2026; etapa C de las salidas de revistas). CRediT y licencias son catálogos comunes a revistas, libros y autores: la consulta vive en módulos comunes (`m_CreditRoles`, `m_Licencias`), no en el volcado de revista.

LOS CATÁLOGOS (esquema 1.28.0)

- `credit_roles.uri` y `credit_rol_nombre` (id_rol, idioma, nombre): las traducciones es y pt de Contributorship Collaboration (credit-translation v1.0.0), tal cual la fuente. Sin traducción, el término en inglés.
- `licencia_texto` (url, idioma, texto), con la URL como clave (SC-23), cargada con los seis textos CC 4.0 en castellano. Sin texto, la licencia se nombra solo con su etiqueta.
- Respaldo de idioma en las dos: el código exacto, después la subetiqueta primaria (pt-BR → pt).
- Se editan en la pestaña «Catálogos» de `FSysAdmin` (Roles CRediT, Licencias, Vocabularios, SC-74), que edita textos y no da de alta ni de baja licencias. La licencia de la editorial se elige del catálogo (combo de solo lectura) y su URL sale de él.
- `revista.logo` (MEDIUMBLOB, GV-195): el logo de la cabecera, cargado en `FRevistas` (solo PNG, reconocido por su firma; avisa si la proporción se aparta más de un 5 % de 184:20).

CONGELADO AL PUBLICAR (esquema 1.29.0; la reproducibilidad manda)

`PublicarArticulo` escribe, dentro de su transacción, el texto de la licencia efectiva en el idioma del artículo (`articulo.licencia_texto`) y el nombre y la URI de cada rol (`contribuyente_credit.nombre_rol`, `uri_rol`). El volcado (versión 4) lleva `<licencia url texto>` y `<credit nombre uri>`: un artículo no publicado los toma del catálogo; uno publicado, los congelados. Cambiar el catálogo no toca lo publicado. El script de 1.29.0 congeló los publicados con el catálogo de ese día.

EN EL CANÓNICO

`<role>` lleva el nombre en el idioma del artículo; `@vocab-term` el término de JATS4R, buscado por la URI (GV-202); `@vocab-term-identifier`, la URI. `license-p` = etiqueta + «. » + texto.

**Relaciones:** vinculo:SC-23,vinculo:SC-71,vinculo:SC-74,vinculo:SC-87,vinculo:SC-22,apoya:GV-195,apoya:GV-196,apoya:GV-202

### SC-91 — Revistas: el EPUB del número — un solo EPUB, el armazón desde el volcado y cada artículo con los datos de la columna del PDF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / SaxonJ-HE 12.5 / make4ht v0.3m / epubcheck 4.2.6 / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 14/11/2026; etapa E de las salidas de revistas).

- UN SOLO EPUB por número: tapa, página legal, sumario y todos los artículos. No hay EPUB por artículo, como en libros. Noto Serif embebida. Nombre: el del PDF del número con `.epub` (`nombre_numero`, SC-89), en `salidas/epub/`.
- EL ARMAZÓN LO ARMA UNA XSLT DESDE EL VOLCADO, no Gambas como en libros (`m_GenerarEpubLibro`): `numero-a-epub.xsl` escribe `content.opf`, `nav.xhtml` y las preliminares. Las del PDF salen del volcado con las mismas funciones (`revista-comun.xsl`): escritas dos veces podían divergir. La frontera con la base no cambia: Gambas escribe el volcado y el script no la toca.
- PRELIMINARES: las que el número declara (SC-88), en el orden de su nombre. El sumario es una página propia, sin folios, con cada artículo enlazado y sus autores; el nav va aparte, fuera del recorrido de lectura, con los artículos agrupados por tramo y los landmarks (tapa, sumario, primer artículo). La imagen de la tapa es la cover-image cuando la tapa está declarada. Los rótulos de las preliminares son los del contrato de revista en castellano y se traducen en una revista de otro idioma (en, pt, fr); el PDF los deja en castellano salvo que la estética los redefina.
- OPF: identificador `urn:gbpublisher:numero-{id}` (el ISSN es de la revista, no del número), título con la identificación del número, el idioma principal y los de los artículos, fecha AAAA-MM.
- CADA ARTÍCULO: `jats-a-epub-articulo.xsl` importa `jats-to-epub.xsl` para el cuerpo (la hoja del EPUB viejo, que sigue por esa importación) y reemplaza el resto, en este orden: cabecera, resúmenes con sus palabras clave, un bloque con los datos de la columna del PDF en su orden y sin «compartir», cuerpo, agradecimientos, declaraciones (como en el PDF), apéndices, notas (solo las del texto: las de author-notes van en el bloque de datos) y referencias. Citas, referencias y «cómo citar» desde `citas.html` (SC-57).
- IMÁGENES: las que usan los artículos y la tapa; el OPF es la única lista y el script copia exactamente esas (SC-76).
- `engine/generar_epub_revista.sh <proyecto> <bib>`: verifica el volcado, las preliminares, la pinza y las páginas (SC-93); regenera los canónicos; la pasada de citas; el armazón y los artículos; recursos, mimetype y container.xml; verifica que todo lo que el OPF declara exista; empaqueta y pasa epubcheck (sus errores avisan, código 3).
- DESDE GAMBAS: «EPUB completo del número en curso» (`GenerarEpubNumero`): escribe el .bib y el volcado y lanza el script (`LanzarSalidaNumero`). No escribe en la base.

**Relaciones:** vinculo:SC-72,vinculo:SC-87,vinculo:SC-88,vinculo:SC-89,vinculo:SC-57,vinculo:SC-76,vinculo:SC-31,vinculo:SC-25,apoya:GV-203

**PENDIENTE:** Probar en Mint con un número real. En jats-to-epub.xsl (la hoja del EPUB viejo, importada por la nueva): el texto alternativo de una figura sin alt es el pie aplanado, con la clave de la cita; «Figura N» va fijo en castellano. Se pueden resolver en la hoja nueva.

### SC-92 — Revistas: el HTML autónomo del número — un sitio por número en docs/, el diseño del libro y las descargas en el sitio

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / SaxonJ-HE 12.5 / vnu 24.10.17 / Chromium (Playwright) / gbc3 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 14/11/2026; etapa H de las salidas de revistas).

- ALCANCE: el HTML autónomo. El integrado al portal (como SC-85 en libros) espera el portal de revista (R-) de gbWeb, con su esquema en `revista` y `FSysAdmin`.
- UN SITIO POR NÚMERO en `docs/` del proyecto: `index.html` es el sumario y hay una página por artículo (`h-{archivo}.html`), la que se enlaza desde OJS. Desaparecen los modos control y final de la hoja vieja: el canonical va a la página del artículo cargada en la base (`articulo_ubicacion`, tipo pagina, `self-uri` en el canónico), y con ella se comparte; sin ella no hay canonical ni compartir.
- EL DISEÑO DEL LIBRO AUTÓNOMO: `gbpublisher.css` y `gbpublisher.js` enlazados desde `docs/assets/` (jats-to-html.xsl los metía en cada página; las dos compartían 149 de 152 clases). La página del artículo tiene las tres columnas del capítulo del libro: a la izquierda, volver al sumario, la tapa, la identificación del número, compartir, el PDF y los datos de la columna del PDF; al centro, cabecera, resúmenes, cuerpo, agradecimientos, declaraciones y apéndices; a la derecha, el panel de notas, referencias y figuras. El sumario, dos columnas como la entrada del libro: la tapa, los ISSN y las descargas del número; los tramos de `revista-comun.xsl`, con cada artículo enlazado, sus autores y su PDF. La página legal no va: es de las ediciones.
- LAS HOJAS: `jats-a-html-articulo.xsl` importa `jats-to-html.xsl` para el cuerpo; la raíz, los metadatos y la columna de datos de la vieja leían el canónico viejo y no se usan. Metadatos nuevos desde el canónico: Highwire, Dublin Core, Open Graph y Schema.org (ScholarlyArticle dentro de PublicationIssue, PublicationVolume y Periodical). `numero-a-html.xsl` escribe el sumario desde el volcado. Las dos salen sin espacio de nombres, como toda la hoja de revista.
- CITAS: desde `citas.html` (SC-57), la misma pasada que el EPUB. El «cómo citar» es el de biblatex, en el estilo de la revista: no va el widget de cinco formatos del libro, que arma la cita en JavaScript.
- LAS DESCARGAS se copian al sitio (`docs/descargas/`): el PDF de cada artículo y el PDF y el EPUB del número. No hace falta esquema nuevo. Están siempre: la revista es de acceso abierto (SC-93).
- `engine/generar_html_revista.sh <proyecto> <bib>`: verifica la pinza y las páginas; regenera los canónicos; la pasada de citas; colorea el código por artículo (SC-42); rehace en `docs/` solo lo que escribe (`index.html`, `h-a-*.html`, `assets/media/`, `descargas/`), así un artículo que salió del número no queda publicado; imágenes por SC-76 con los gráficos interactivos (SC-69); las hojas; vnu (sus errores avisan, código 3; sin vnu el HTML no se genera: SC-95).
- DESDE GAMBAS: «HTML completo del número en curso» (`GenerarHtmlNumero`). El viejo «Generar salida HTML» queda solo para los números viejos.

**Relaciones:** vinculo:SC-72,vinculo:SC-87,vinculo:SC-89,vinculo:SC-91,vinculo:SC-57,vinculo:SC-76,vinculo:SC-69,vinculo:SC-42,vinculo:SC-85,vinculo:SC-80

**PENDIENTE:** Probar en Mint con un número real. El HTML integrado al portal de revista de gbWeb. Si se suma el widget de cinco formatos de cita, es una decisión aparte.

### SC-93 — La pinza de las salidas del número: cada salida exige las anteriores; el PDF es la base

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / bash / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 14/11/2026). Las revistas son solo de acceso abierto, a diferencia de los libros, que pueden producirse para venta (sin descarga ni lectura en línea: de ahí los ajustes del formulario del libro). En una revista las salidas se validan cruzadas, «en pinza»: cada una se apoya en las otras o las ofrece, y no se genera si falta una de las que necesita.

- PDF DEL NÚMERO (SC-89): es la base. Deja en la base las páginas y los e-id, y en `salidas/pdf/` el PDF de cada artículo y el del número.
- EPUB (SC-91): exige los PDF del número y de cada artículo, y las páginas (o el e-id) de cada artículo en la base: sin ellas el «cómo citar» no tendría rango.
- HTML (SC-92): exige los PDF y el EPUB, que ofrece como descargas, y las páginas.

Lo que falta frena antes de trabajar, con la lista de lo que falta y qué generar primero. Se verifica la EXISTENCIA, no la frescura: un PDF viejo pasa. Las funciones viven en `engine/revista_comun.sh` (`salidas_que_faltan pdf | pdf+epub`, `articulos_sin_paginas`), compartidas por los dos scripts.

**Relaciones:** vinculo:SC-89,vinculo:SC-91,vinculo:SC-92,vinculo:SC-72

### SC-94 — El gestor de archivos del proyecto: Midnight Commander en una ventana de gnome-terminal, no Desktop.Open ni un TerminalView

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 / gb.desktop / mc / gnome-terminal / Cinnamon / X11 / Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 15/11/2026, después de probar las dos variantes).

El botón que abre la carpeta del proyecto (`btnAbrirDirectorio` en `FMain`) lanza Midnight Commander en una ventana propia de gnome-terminal, parado en la carpeta del proyecto. Reemplaza a `Desktop.Open` (GV-43), que abría el gestor de archivos del escritorio.

POR QUÉ mc

Los gestores de archivos gráficos (Nemo, Dolphin, Nautilus) piden demasiados clics y fallan al mover grandes volúmenes; mc no falla. La consola que sigue la ruta, como la de Dolphin, la trae mc de fábrica: su línea de comandos ejecuta en la carpeta del panel activo, y el subshell (Ctrl+O) se sincroniza con el panel en los dos sentidos.

POR QUÉ EN UNA VENTANA EXTERNA Y NO EN UN TerminalView

Un formulario con su propio TerminalView daba más control (posición y tamaño en píxeles, sin gestor de ventanas de por medio) y se descartó por la robustez, que es la razón de usar mc:
- Quien lee la salida de mc es el TerminalView, o sea el bucle de eventos de gbpublisher. Si la aplicación se ocupa en algo que bloquea, el pseudo-terminal se llena y mc se detiene al escribir la pantalla: una copia grande se pausa. Razonado, no medido.
- Cerrar gbpublisher mata a sus procesos hijos (GV-174): una copia en curso se cortaría. La ventana de gnome-terminal no depende de gbpublisher.
El TerminalView de `FMain` tampoco sirve: tiene un bash y `Exec` responde «Terminal already in use» (GV-42).

CÓMO SE LANZA

    Exec ["gnome-terminal", "--", "mc", sRuta]

`Exec` sobre un array, sin `Wait`: no hay shell, la ruta no se interpreta (GV-06) y la interfaz no se congela. mc recibe la carpeta como argumento: no hace falta `cd`. Al salir con F10, gnome-terminal se cierra solo.

LA VENTANA (GV-205)

- AL FRENTE, con `Desktop.ActiveWindow`: si no, Cinnamon la deja detrás de gbpublisher.
- TAMAÑO de 960×720 píxeles (`ANCHO_VENTANA_MC`, `ALTO_VENTANA_MC`), con `Resize`; el terminal lo redondea a celdas.
- POSICIÓN: la que decide gnome-terminal. Centrarla después de creada se veía en dos pasos; el costo se aceptó.

LA CONFIGURACIÓN DE mc

Vive en `~/.config/mc/` (`ini`, `panels.ini`; `mc -F` da las rutas). OBSERVADO por Alberto: con el guardado automático activado los cambios no persistían; persisten guardándolos a mano (F9 → Opciones → Guardar configuración). Cerrar la ventana con la X, en lugar de F10, mata a mc sin que guarde.

DEPENDENCIAS Y ERROR DE Exec (18/11/2026). Un `Exec` de un programa que no existe da un error atrapable con `Try`: código 45, «File or directory does not exist» (medido en 3.19 con gbx3). `gambas3-gb-desktop-x11` entra al .deb solo, porque `gb.desktop.x11` es componente del proyecto; `mc` ya estaba entre las dependencias extra del `.project`, y se agregó `gnome-terminal`.

**Relaciones:** vinculo:GV-205,vinculo:GV-43,vinculo:GV-42,vinculo:GV-174,vinculo:GV-06,vinculo:GV-17

**PENDIENTE:** Confirmar en Mint, con el .deb siguiente, que gnome-terminal figura entre sus dependencias.

### SC-95 — Integridad del sistema: una sola lista en engine/integridad.sh, herramientas de producción congeladas en /opt y control por funcionamiento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / engine/integridad.sh / pkexec / Saxon-HE 12.9 / pandoc 3.1.3 / epubcheck 4.2.6 / veraPDF 1.30.1 / packtools 4.18.2 / vnu 26.7.3 / Linux Mint 22 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026, después de probarlo en Linux Mint con el libro de Jensen).

POR QUÉ

La mayoría de quienes usan gbpublisher no tienen formación técnica: son usuarios de Windows que pasaron a Linux Mint sin fricción, pero que no leen la consola. El control anterior fallaba hasta para quien sí sabía leerlo. Había dos listas (`IntegridadSistema` en Gambas y el viejo `integridad.sh`) y ninguna miraba lo que usa la cadena. Saxon se buscaba como `saxon-he-*.jar` y la cadena llama a `saxon-he.jar`: sin el enlace, el control daba OK y la generación moría. packtools se probaba con el Python del sistema y vive en su propio entorno en `/opt/packtools`.

UNA SOLA LISTA, EN engine/

`engine/integridad.sh` es la única lista. Gambas no tiene otra.

QUÉ SE CONGELA EN /opt

Se congela, con versión y huella fijas, lo que cumple las tres condiciones a la vez: su resultado es el contenido de una salida o el veredicto de una validación; una versión nueva no garantiza el mismo resultado; y congelarlo cuesta poco (un JAR o un binario autónomo).

    Saxon-HE 12.9     /opt/Saxon-HE, con el enlace saxon-he.jar (SC-52)
    pandoc 3.1.3      /opt/pandoc/bin/pandoc, el binario oficial
    epubcheck 4.2.6   /opt/epubcheck/epubcheck.jar
    veraPDF 1.30.1    /opt/verapdf
    packtools 4.18.2  /opt/packtools (engine/instalar_packtools.sh)
    vnu 26.7.3        /opt/vnu/vnu.jar

La URL, la huella de la descarga y la huella de lo instalado de cada uno viven en `integridad.sh`. Para cambiar de versión se cambian las tres juntas, más la versión esperada.

Por qué pandoc: el canónico se regenera desde el `.md` muchas veces durante la edición, así que pandoc está dentro de lo que tiene que poder reproducirse. Ubuntu no cambia la versión de un paquete durante una LTS, pero Mint saca una base nueva cada dos años y cada una dura unos cinco: van a convivir usuarios en dos versiones. Y el pandoc 3.1.3 de apt no es el binario oficial (Debian lo compila con sus bibliotecas de Haskell), así que la misma versión no garantiza el mismo XML (GV-207).

Por qué epubcheck: es un veredicto, y `generar_epub_libro.sh` cuenta los errores leyendo el texto que imprime.

QUÉ QUEDA EN EL SISTEMA

Lo que garantiza el `.deb` y no se vuelve a controlar: Java, TeX Live (`texlive-full`), xmllint, Python con venv, perl, ImageMagick, poppler-utils. TeX Live no rompe hacia atrás salvo algún paquete puntual: si un cambio rompe algo, se corrige cuando aparece. MySQL tampoco se controla: si hay un proyecto abierto, la aplicación ya se conectó a la base.

CONTROL POR FUNCIONAMIENTO, NO POR PRESENCIA

Cada componente se controla por la huella de lo instalado y haciéndolo trabajar, como usuario común, que es como lo usa la cadena: Saxon transforma un XML mínimo y el enlace tiene que llevar al JAR de la 12.9; pandoc convierte una línea a DocBook y responde como intérprete Lua (`pandoc lua`, que usa `colorear_codigo.sh`); epubcheck y veraPDF dan su versión; packtools carga su validador desde su entorno; vnu da su versión y valida una página HTML5 mínima. Una instalación que funciona no se toca, aunque se haya hecho a mano: solo se repara lo que falla, y se reemplaza la carpeta entera.

CÓMO SE INSTALA

1. Como usuario común: el control y las descargas. Cada descarga se acepta solo si su huella coincide. Sin conexión, el script dice «No hay conexión a internet» (curl sale con 6, 7, 28 o 35) y no un error de curl.
2. Una sola llamada a `pkexec`, con todo lo que falta. La contraseña se pide en una ventana gráfica: con sudo, la línea «[sudo] contraseña para...» se pierde entre los mensajes (GV-206). La parte de root es el mismo script con `--instalar <carpeta> <componentes>`: vuelve a verificar las huellas, instala y deja cada carpeta de root y legible por todos, componente por componente. pkexec limpia el entorno: la parte de root no toca `~/.gbpublisher`.
3. El control final, igual al primero.

Mensajes con el vocabulario de `comun.sh` y códigos de SC-53: 0 todo en orden, 1 algo quedó sin resolver. Cada falta se explica por lo que deja de poder hacerse («sin esto los .md no se convierten en el XML canónico»), no por el archivo que falta.

DÓNDE SE LANZA

Desde el menú «Acerca de... → Controlar integridad del sistema» (`FMain.menuAcercaIntegridad_Click`), con `m_Lanzadora.EjecutarScript`, que bloquea las salidas mientras corre: nadie genera un PDF a mitad de una instalación. Hace falta un proyecto abierto, revista o libro: el script corre en su terminal. Sin proyecto, el menú lo dice.

No hay control al arrancar: es una instancia de control del usuario (decisión de Alberto). Se quitó el de `FAvisoLegal.Form_Open`.

LAS RUTAS EN LA CADENA

`RUTA_PANDOC` y `RUTA_EPUBCHECK` en `engine/comun.sh` (con `GBP_PANDOC` y `GBP_EPUBCHECK` para probar a mano otra versión), en `m_Constantes` (solo `RUTA_PANDOC`: `RUTA_EPUBCHECK` salió el 18/11/2026, la usaba solo el EPUB viejo de revistas) y en `convertir_docx.sh`, que no carga `comun.sh`. Nadie llama a pandoc por su nombre: ni los scripts de `engine/` ni Gambas (`m_AnalizarProyecto`, `m_PrimerasLibro`). `requerir_pandoc` reemplaza a «requerir_comandos pandoc». Todo aviso de herramienta faltante termina con `COMO_REPARAR`: «Abrí cualquier proyecto y usá «Acerca de... → Controlar integridad del sistema»: instala lo que falte».

LO QUE SE RETIRÓ

`IntegridadSistema`, `ReporteIntegridadTexto` y sus auxiliares (`m_FuncionesGenericas`); el control al arrancar; `instalar-packtools.sh` de la raíz del repositorio, mudado a `engine/instalar_packtools.sh` para que viaje en el `.deb`; `pandoc` y `epubcheck` de las dependencias del paquete.

PROBADO

En Mint (18/11/2026): el script reparó pandoc y epubcheck con una sola ventana de contraseña y respetó el Saxon instalado a mano. Con el libro de Jensen, los canónicos regenerados con el pandoc de /opt son idénticos byte a byte a los del pandoc de apt; el EPUB pasa epubcheck 4.2.6 sin mensajes. En un Ubuntu 24.04 de prueba: la instalación desde cero de pandoc, epubcheck y veraPDF, el control como usuario común, y la ventana cerrada (código 126).

VNU SE CONGELA (18/11/2026). El validador de HTML, que ya usaban los dos HTML (`generar_html_libro.sh`, `generar_html_revista.sh`), se suma a la lista: su veredicto cambia con cada versión, igual que el de epubcheck. Se congela la 26.7.3, la que estaba instalada en Mint: el jar de Mint y el del paquete son idénticos byte a byte.

- DE DÓNDE SE BAJA. Las releases de GitHub de `validator/validator` no tienen un archivo por versión. Se usa el paquete `vnu-jar` de npm, que publica el propio repositorio desde GitHub Actions. No hace falta npm: el `.tgz` trae `package/build/dist/vnu.jar` y la licencia, y `integridad.sh` lo baja con curl y controla dos huellas, la del `.tgz` y la del jar. Queda en `/opt/vnu/vnu.jar`, con su `LICENSE`.
- EL CONTROL. La huella del jar; que `--version` empiece con «26.7.3»; y que una página HTML5 con `aside` y `details` dé código 0. Se mira solo el código: vnu escribe sus mensajes en stderr, donde Java también avisa «Picked up JAVA_TOOL_OPTIONS» si esa variable está puesta.
- LOS HTML. `RUTA_VNU` pasa a `comun.sh` (con `GBP_VNU` para probar a mano otra versión), y `requerir_vnu` corta al verificar el entorno, antes de generar. Antes, sin vnu el HTML se generaba entero y solo avisaba al final que no se había validado. Los errores que vnu encuentra siguen siendo avisos (código 3).

PROBADO en el contenedor (Ubuntu 24.04, Java 21): instalación desde cero, un jar de otra versión reemplazado, el control como usuario común, y `requerir_vnu` con y sin el jar.

**Relaciones:** apoya:GV-206,apoya:GV-207,apoya:GV-208,vinculo:GV-209,vinculo:SC-52,vinculo:SC-53,vinculo:SC-11,vinculo:GV-42,vinculo:SC-107

**PENDIENTE:** Adaptar engine/integridad.sh para que el instalador lo llame sin un proyecto abierto (SC-107). La política de polkit (GV-206).

### SC-96 — La salida ODT se retira, en revistas y en libros

**Estado:** vigente · **Evidencia:** inferida · **Entorno:** gbpublisher · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026).

La salida ODT se retira, en revistas y en libros. La necesidad real es remota: un autor pidió alguna vez su texto actualizado en un procesador de texto, y no justifica, para un solo desarrollador, mantener una salida más con su margen de error en cada filtro y cada shortcode.

QUÉ SE RETIRÓ

- `m_GenerarODT` entero y `FMain.menuSalidaODT_Click`.
- Los dos menús «Generar salida ODT»: el de revistas (`menuSalidaODT`) y el de libros (`Menu2`), que no tenía handler y nunca hizo nada.
- La carpeta `salidas/odt` de los proyectos nuevos (las que existen no se tocan).
- El documento de referencia `ott/reference.ott`: sale de `ExtraFiles`, de la copia a `~/.gbpublisher` (`DirectorioOcultoApp`) y del cotejo de SC-11.
- El filtro `epigrafe-odt.lua` y el icono `libreoffice.png`.

QUÉ NO ES ODT

`m_EditorHTML` usa LibreOffice (`soffice`) para IMPORTAR un documento al editor. Es una entrada, no una salida: sigue.

LAS MENCIONES EN OTRAS ENTRADAS

Varias entradas describen cómo cada filtro o shortcode resolvía el ODT («las tres cadenas: revista, libro y ODT», los párrafos «ODT», «las seis salidas»). Esas menciones quedan sin efecto desde esta entrada y se limpian junto con el retiro del camino viejo de revistas, que toca las mismas entradas: una sola pasada y no dos. Hecho el 18/11/2026 (act-106, SC-98).

**Relaciones:** vinculo:SC-11,vinculo:SC-35

### SC-97 — Limpieza de código muerto: por bloques, con rastreo de referencias y compilación completa

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 (Mint) y gbc3 3.19 (contenedor) · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026). La limpieza de código muerto se hace por bloques; cada bloque es un zip que compila y que Alberto prueba en Mint antes del siguiente. La mayor parte es borrar.

QUÉ CUENTA COMO MUERTO

- Una función, propiedad, constante o variable que nada nombra fuera de su propia declaración.
- Un handler cuyo control ya no está en el formulario: el código existe pero ningún evento lo dispara.
- Un formulario que nadie abre, un módulo o una clase que nadie nombra.
- Lo que solo usaba algo de lo anterior: la segunda capa. Se repite el rastreo hasta que no aparezca nada nuevo.
- El código viejo dentro de comentarios. Los comentarios que explican se quedan.

CÓMO SE RASTREA (lo que costó aprender)

- Un control público se declara en el `.form` con `!` delante del nombre (`{ !btnX Button`); uno no visual, con `#` delante de la clase (`{ TimerX #Timer`); y el tercer elemento de la línea es su grupo (`{ txtA TextBox AllTextBoxes`). Un handler `Grupo_Evento` está vivo si el grupo existe.
- El nombre de un control puede tener guiones bajos (`ano_publicacion`): el evento es lo que va después del ÚLTIMO.
- También están vivos los handlers de objetos creados en código con `New X As "Nombre"`.
- Una propiedad (`Property Read X` y `X_Read`) se usa como `objeto.X`: está viva si `X` aparece fuera de su declaración. Un error en esta cuenta borró dos propiedades usadas por `m_AuditarJats` y el compilador no lo detectó (GV-210); se repusieron en el mismo bloque.
- Lo que se nombra por texto en tiempo de ejecución no lo ve el rastreo: `Object.GetProperty(FMain[sControl], …)` en `m_AplicarBib`. Antes de borrar un control, se busca su nombre como texto.
- Un encabezado de función separado de la función por una línea en blanco queda huérfano al borrarla: se busca y se borra aparte.

CÓMO SE VERIFICA

1. El proyecto completo se compila con `gbc3` en el contenedor (Gambas 3.19, cambiando para la prueba `gb.qt6` por `gb.qt5` y `gb.db2` por `gb.db`). Compiló sin errores antes de empezar.
2. Como el compilador no ve las llamadas a lo borrado en otro módulo ni en otra clase (GV-210), se busca cada nombre borrado en el código vivo, sin comentarios.
3. Las menciones en el corpus se corrigen en el mismo bloque.
4. Alberto aplica el zip, compila en Mint y prueba.

LOS BLOQUES (orden acordado)

1. La salida ODT (SC-96). 2. El muerto directo y sus capas, y el código comentado. 3. Recursos de `.hidden` sin uso (XSLT, filtros, scripts de prueba) y entradas de `ExtraFiles`. 4. El camino viejo de revistas: el esquema viejo es todo de prueba (Alberto, 18/11/2026), así que se retira entero, con las tablas viejas, en una actualización de esquema.

BLOQUE 2, HECHO (18/11/2026): 61 funciones, handlers y propiedades; 15 constantes; 7 variables; los formularios `FVocabularios` (reemplazado por la subpestaña de `FSysAdmin` el 14/11), `FAyudaABM` y `FDoi`; el módulo `m_FuncionesExportar`; la clase `CPosicionTexto`; cuatro funciones viejas comentadas. Dos herencias viejas: la capa de claves en `Settings` de `m_Traduccion` (el traductor ya usa `m_ApiCredenciales`) y `LiberarLock`, que nadie llamaba (`OtraInstanciaActiva` ya descarta un bloqueo viejo por el PID).

BLOQUE 1, HECHO (18/11/2026): la salida ODT (SC-96).

BLOQUE 4, HECHO (18/11/2026): el camino viejo de revistas, con la actualización de esquema 1.32.0 (SC-98). Dos lecciones para el rastreo. La primera: el alcance desde el formulario de arranque (`FAvisoLegal`) encuentra los ciclos muertos que el rastreo por nombres no ve, como formularios que solo se abren entre sí. La segunda: lo muerto no es lo único que deja un camino retirado. Hay que buscar también el código vivo que lee las tablas del camino viejo: falla sin aviso con los datos nuevos (las herencias huérfanas de SC-98).

BLOQUE 3, HECHO (18/11/2026): los recursos de `.hidden` sin uso. El criterio para las hojas XSLT no fue «alguien las nombra», porque los comentarios las nombran todas. Fue el alcance desde los puntos de entrada reales: las hojas que invocan `engine/` y Gambas, más sus `xsl:import` e `xsl:include`. Así quedan vivas `jats-to-latex`, `jats-to-html`, `jats-to-epub` y `ensamblar-canonico`, porque las importan las nuevas.

Salieron:
- `jats-to-crossref`, `jats-to-doaj`, `jats-to-redalyc` y `jats-to-scielo`: los envíos viejos.
- `prueba-saxon.xslt`.
- El filtro `table-to-end.lua`.
- El menú «Exportar XML-JATS», con `m_XML.ExportarJATSdesdeBIB`, `AplicarReglasPostproceso` y `filters/postprocesar_jats.py`.
- `m_XML.ExportarDocBookdesdeBIB`: escribía un `ref-*.xml` en cada lanzamiento de los canónicos del libro y nadie lo leía. La bibliografía de las salidas sale del `.bib` (SC-57).

Lo que nadie lee y viajaba en el `.deb` (y en la copia a `~/.gbpublisher`):
- En `dtd/`: la Tag Library (`Green-1_4-HTML.zip`, 44 MB) y los doce zips de DTD, RNG y XSD.
- En `schematron/`: el clon de `jats-schematrons` (con `.git` y `testfiles`) y `schxslt-cli.jar`.
- En `schemas/crossref/`: los XSD que la validación no alcanza. Se conservan los veinte que alcanza `crossref5.4.0.xsd` (calculado siguiendo sus `include` e `import`, con el catálogo) y `catalogo-crossref.xml`.

`scripts/` NO es código muerto: es el espacio del usuario para sus filtros y scripts personales sobre lo que genera la app (por ejemplo, el `main.tex`). Se copia y se queda (Alberto).

BLOQUE 3a, HECHO (18/11/2026): las reglas compiladas del auditor salen del repositorio. Hasta ese día se hacían a mano con un `compilar-schematron.sh` que no quedó guardado: estaban solo en el `/usr/share` de la máquina de Alberto, y una instalación nueva desde el `.deb` no las tenía. En ese caso el auditor avisa en el informe «faltan las reglas compiladas» y no evalúa JATS4R.

Qué cambió:
- `generar-schematron-jats4r.sh` escribe también `.hidden/schematron/compilados/`: un `.xsl` por temático (36 en v0.0.17), con los vocabularios al lado y una cabecera con su origen. Cada temático se verifica contra el maestro (GV-211). Si uno difiere, no se reemplaza ninguno de los dos productos. Se probó saboteando la comparación: frena, dice qué temático, en qué instancia y qué hallazgo, y deja intactos los anteriores.
- `m_ValidacionSchematron` lee la carpeta desde `m_InicioCierre.RutaRecursos()`, como `m_Sonido`: `.hidden/` desde el IDE, `/usr/share/gbpublisher` instalado. Antes era una ruta fija a `/usr/share`, y desde el IDE se probaba contra lo instalado.
- Se corrigieron los comentarios que decían que el pipeline propio compartía la carpeta (no lo hace desde SC-87), y se borró el encabezado huérfano de una «API heredada» ya borrada.
- Sale `schematron/schxslt-xslt/`.

BLOQUE 3b, HECHO (18/11/2026): CSL sale entero. Los `.csl` y el CSL-JSON eran el camino anterior de las referencias del EPUB y del HTML, con citeproc. Se reemplazó por tex4ht sobre lo que generan biblatex y biber, que unifica las salidas con el PDF (SC-57, Alberto).

Salieron:
- la carpeta `csl/`, con su entrada en la lista de copia de `m_InicioCierre` y en ExtraFiles;
- el menú «Exportar CSL-JSON», con `m_Json.ExportarCSLJSON` y las cinco funciones que solo usaba él (`ConvertirTipoCSL`, `CrearFechaCSL`, `MapearCampoCSL`, `ParsearFechaCompleta` y `ParsearNombres`).

El combo de estilo de cita de `FMetadatosLibro` pasó de `cmb_tipo_csl` a `cmbEstiloCita`: listaba los estilos de biblatex, no CSL. Solo lo nombran `FMetadatosLibro` y `m_Metadatos`, por nombre; la columna es `libros_md.estilo_cita`. También se corrigió su ayuda emergente, que decía que leía de `~/.gbpublisher/csl/`.

Verificado además: `jats-a-marcalyc` no deja pasar las instrucciones `gb-*` (SC-38).

**Relaciones:** vinculo:GV-210,vinculo:SC-96,vinculo:SC-70

**PENDIENTE:** Probar en Mint: generar-schematron-jats4r.sh con el Saxon de /opt, el auditor desde el IDE (lee .hidden/) y, con el .deb siguiente, instalado.

### SC-98 — Revistas: el camino viejo se retira — el código, las tablas viejas y articulo.id_doaj (actualización 1.32.0)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 (Mint) y gbc3 3.19 (contenedor) / MariaDB 10.11 (prueba del script) · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026). El camino viejo de revistas se retira entero: el código, sus menús y controles, las tablas viejas y la columna `articulo.id_doaj`. Los números del esquema viejo eran todos de prueba, así que no hay migración. Es el bloque 4 de la limpieza (SC-97).

QUÉ SALE DEL CÓDIGO

- Los módulos `m_GenerarEpub`, `m_GenerarHTML`, `m_GenerarPDF`, `m_GenerarDOAJ`, `m_GenerarCROSSREF` y `m_GenerarSCIELO`, y los formularios `FMetadatosRevista`, `FMetadatosArticulos` y `FResumenEstructurado`.
- En `FMain`: `btnGenerarXMLcanonico`, `Menu6` (PDF a una y a dos columnas), `menuGenerarEpub`, `HTMLcontrol`, `Menu9` (los envíos a DOAJ, Crossref, SciELO, Redalyc y PMC) y el bloque `TabStripValidaciones`, que ya estaba oculto. 81 controles y 25 handlers.
- En `m_XML`: el front y el body JATS, el envío a DOAJ, la validación de archivos de indexadores y el PDF viejo (`GenerarTeXBodyDesdeCanonico`, `EnsamblarTeX`, `CompilarPDF`, `GenerarPDF`, `MostrarArchivos*`): 41 funciones; el módulo pasa de 379 KB a 219 KB. Se queda `ObtenerPreambuloEmbebido`, que usa la vista de cuadros.
- `m_GenerarSalidasRevista.NumeroEsNuevo`: `ConfigurarControles` muestra siempre el camino nuevo.
- `m_InicioCierre.IdArticuloEnCurso`: era el id de la tabla vieja `articulos`. El artículo del editor lo da el archivo abierto (`ArticuloDelEditor`).
- `m_Constantes.RUTA_SAXON` y `RUTA_EPUBCHECK`, sin uso. `GBA_RUTA_SAXON` sigue.
- La segunda capa, que solo usaba lo anterior: funciones sueltas de `m_Metadatos`, `m_AplicarBib`, `m_AuditarJats`, `m_Licencias`, `m_OrdenTaller`, `m_InicioCierre` y `CAsercionSVRL`.

HERENCIAS HUÉRFANAS: CÓDIGO VIVO QUE LEÍA LAS TABLAS VIEJAS

El camino nuevo seguía leyendo `revistas_md` y `articulos` en cinco lugares. En un número nuevo no hay filas ahí, así que fallaban sin aviso. Pasan al esquema nuevo:
- `m_XML.ObtenerIdRevista`: de `numero` (`numero.id_proyecto` es único). Antes, en un número nuevo, devolvía 0.
- `m_XML.EstiloCitaRevista`: de `revista.estilo_cita`. Lo usa la vista de cuadros (SC-67).
- `m_Cuadros.IdiomaArticuloEnCurso`: el artículo lo da el archivo abierto, como `m_GenerarSalidasRevista.ArticuloDelEditor`, buscado en `articulo` por el número del proyecto. Antes daba siempre «es» en un número nuevo.
- `m_Estructura.TitulosDeLaBase`: `articulo.titulo` (SC-18). Antes mostraba el nombre del archivo.
- `m_GitHub.GenerarEstadoProyecto` y `ObtenerAutoresArticulo`: de `articulo` y `articulo_contribuyente` (`rol='autor'`, por `orden`; una autoría colectiva va con su nombre). Las claves del JSON no cambian, porque las lee `.github/workflows/estado-editorial.yml`. Dos diferencias: `responsable_edicion` va nulo (no tiene columna en el esquema nuevo; el workflow muestra «N/D»), y `estado` toma los valores nuevos (`borrador`, `en_produccion`, `publicado`).
- `m_Bibtex`: en revistas no guarda las claves citadas en la base. Salen del .md al generar el canónico (SC-16). Antes buscaba la fila en `articulos`.
- El selector de archivos de `FMain` ya no busca el id del artículo en `articulos`.

LA BASE: ACTUALIZACIÓN 1.32.0

`actualizar-esquema-1.32.0.sh` sigue el patrón de la 1.31.0 (SC-22): exige la 1.31.0, es idempotente, pide SI, hace un respaldo verificado, verifica después y registra.
- Borra `articulo_revisor`, `articulo_autor`, `articulos` y `revistas_md`, en ese orden.
- Borra los proyectos del esquema viejo: los que tienen filas en `revistas_md` o `articulos` y no tienen número nuevo ni libro. Lo que cuelga de ellos con CASCADE se va con ellos (bibliografía, siglas, tiempos, órdenes de taller), y `usuarios.id_proyecto_actual` queda en NULL. Un proyecto con número nuevo se conserva: solo pierde sus filas viejas.
- Con cada proyecto borrado sale su grupo de notas: vistas, respuestas, notas, miembros y grupo, en ese orden y en una transacción. Las claves son todas RESTRICT (GV-111). La regla «nada se borra» es para el uso de las notas, no para retirar un proyecto de prueba (Alberto, 18/11/2026). El grupo se borra antes que las tablas: si falla, no se tocó nada más. Lo encontró el freno del script en la primera corrida en Mint, en el proyecto `r-03REV-EJEMPLO.md`: 1 nota y 2 miembros.
- Borra `articulo.id_doaj`: la escribía el envío viejo a DOAJ por API, y la subida a DOAJ es a mano (Alberto).
- Antes de tocar nada, consulta la base y frena si alguna tabla fuera del camino viejo apunta a sus tablas, o si una clave RESTRICT hacia `proyectos` tiene filas de los proyectos a borrar.
- No se vuelve atrás con un parche. Se restaura el respaldo completo con `--init-command="SET SESSION innodb_strict_mode=0"` (GV-67): el respaldo trae `articulos`. El script muestra el comando.
- Las carpetas de los proyectos borrados quedan en el disco. El script lista sus nombres.

`m_ConexionBD.ObtenerEsquemaEsperado`: salen las cuatro tablas, y `articulo` baja a 31 columnas. El 2.0.0 fue el de `bibtex` (SC-102).

VERIFICADO

- Compilación completa con `gbc3` 3.19 en el contenedor.
- Búsqueda de cada nombre borrado (funciones, controles, módulos y formularios) en el código vivo, fuera de comentarios y de cadenas (GV-210): ninguno.
- Los 107 controles que `m_AplicarBib` y `m_Bibtex` nombran por texto siguen en `FMain.form`.
- Ninguna consulta viva nombra las tablas viejas.
- El script 1.32.0, sobre MariaDB 10.11 con una base de prueba: los casos normales (un proyecto viejo, uno viejo con solo `articulos`, uno nuevo con una fila vieja, un libro), la segunda corrida, la cancelación, los dos frenos y la restauración del respaldo. No se probó sobre MySQL 8: las consultas son de `information_schema`, comunes a los dos.

LA PASADA SOBRE EL CORPUS

Con act-106 se corrigieron las menciones del camino viejo y del ODT (SC-96) en las entradas vigentes: las cadenas, las salidas, los pendientes y los nombres de módulos. El criterio para el resto:
- Los registros de lo MEDIDO («con las cadenas reales de libro, revista y ODT») quedan como historia: dicen lo que se midió.
- Las hojas XSLT del camino viejo que el nuevo todavía importa (`ensamblar-canonico.xsl`, `jats-to-epub.xsl`) se tratan en el bloque 3.

LO QUE QUEDÓ A LA VISTA

- La vista de cuadros de revista compone con el preámbulo del PDF viejo (`m_XML.ObtenerPreambuloEmbebido`: clase `article`, sus fuentes), no con el de capas del PDF nuevo (`generar_pdf_revista.sh`). El cuadro se ve con otra letra y otra caja que en el PDF. Se encara aparte.
- Varias entradas daban las reglas de CSS del EPUB en `m_GenerarEpub`, que salió. No se cotejó si el EPUB nuevo de revistas las tiene.

**Relaciones:** vinculo:SC-97,vinculo:SC-96,vinculo:SC-71,vinculo:SC-72,vinculo:SC-87,vinculo:SC-22,vinculo:GV-67,vinculo:GV-210,vinculo:SC-102

**PENDIENTE:** La vista de cuadros de revista con el preámbulo de capas del PDF nuevo. Cotejar el CSS del EPUB nuevo de revistas con las reglas que citaban el de m_GenerarEpub (epígrafe SC-35, código SC-42, conversación SC-43, verso SC-49). Aplicar la 1.32.0 en Mint y probar: abrir un número, la vista de cuadros (idioma), el árbol de estructura (títulos) y el JSON de GitHub.

### SC-99 — La orden de taller se retira: el circuito de imprenta de las editoriales no pasa por gbpublisher (actualización 1.33.0)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 (Mint) y gbc3 3.19 (contenedor) / MariaDB 10.11 (prueba del script) · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026). La orden de taller (OT) se retira entera: el menú, el formulario, el módulo, el icono y la tabla.

POR QUÉ. La OT supone un circuito de imprenta que no es el de las editoriales reales:
- unas no imprimen nada;
- otras imprimen en la imprenta de su facultad, con un trámite administrativo propio, fuera de esta app;
- otras imprimen con talleres externos, casi siempre por licitación pública, también con su trámite.

Ninguna de las tres pasa por un documento armado en gbpublisher.

QUÉ SALE
- El menú «OT para imprenta» (`FMain.menuImprenta`) y el separador que lo precedía (`Menu4`).
- El formulario `FOrdenTaller` y el módulo `m_OrdenTaller`.
- El icono `iconos/impresora.png`.
- La tabla `orden_taller`, con la actualización de esquema 1.33.0 (patrón de SC-22). Pide SI, hace un respaldo verificado y frena si alguna tabla apunta a ella. Se vuelve atrás restaurando el respaldo. El 2.0.0 fue el de `bibtex` (SC-102).
- `m_ConexionBD.ObtenerEsquemaEsperado`: sale `orden_taller`.
- La cascada sacó además `m_Json.RutaProyecto`, una variable que solo usaba la cadena de CSL-JSON (bloque 3b de SC-97).

ESTABA ROTA. `m_OrdenTaller` leía y escribía `FMain.txtProveedorOT`, `FMain.txtCabeceraOT` y el resto, pero esos controles estaban en `FOrdenTaller` y no en `FMain`. Compilaba (GV-210) y fallaba al guardar o al generar el PDF.

SE QUEDA `media/logo-cabecera.png`: la OT lo usaba, pero también lo usan el logo de cabecera de las revistas (`FRevistas`) y la copia a cada proyecto (`m_FuncionesGenericas`). Los PDF de OT ya generados quedan en `salidas/pdf/` de cada proyecto.

VERIFICADO: compilación completa con `gbc3` 3.19; ningún nombre borrado en el código vivo; el script 1.33.0 sobre MariaDB 10.11 (el caso normal, la segunda corrida, la cancelación y el freno).

**Relaciones:** vinculo:SC-97,vinculo:SC-22,vinculo:GV-210,vinculo:SC-102

**PENDIENTE:** Aplicar la 1.33.0 en Mint.

### SC-100 — El readme.md del proyecto se escribe en la primera apertura, con el nombre y qué es; reemplaza la copia vacía

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22 (Mint) y gbc3, gbx3 3.19 (contenedor) · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 18/11/2026).

El `readme.md` es la portada del proyecto cuando se sube a GitHub. Hasta esta fecha `CopiarArchivosBase_MD` copiaba a cada proyecto un `readme.md` vacío de la raíz de la aplicación. Ahora lo escribe `m_FuncionesGenericas.EscribirReadme` en la primera apertura, con lo que se sabe en ese momento:

- el título: el nombre del proyecto sin `.md` (`l-ALGO`, `r-ALGO-V99-N01`);
- qué es: «Número de revista en producción editorial» o «Libro en producción editorial»;
- en una revista, el número en una línea (`m_Numero.DescripcionNumero`: revista, volumen, número, suplemento y año). El número ya quedó vinculado antes, en el alta del proyecto;
- «Producido con gbpublisher», con el enlace al repositorio.

La editorial y el título del libro no se ponen: en la primera apertura todavía no están en la base, y el archivo no se vuelve a escribir.

CUÁNDO SE ESCRIBE. `CopiarArchivosBase_MD` corre en cada apertura (`FMain`, apartado 11). El `readme.md` se escribe si no existe o si está vacío: un archivo vacío no tiene nada del usuario que cuidar, y así los proyectos que ya tenían la copia vacía reciben el suyo. Uno con contenido no se toca, porque pudo escribirlo el equipo. La condición va en dos ramas y no con `Or`, porque `Or` evalúa las dos partes y `Stat` falla si el archivo no existe. Si no se puede escribir, se avisa y la apertura sigue, como con el `.gitignore` de `ControlarCarpetas`.

EL TIPO VA COMO PARÁMETRO. `CopiarArchivosBase_MD(iTipo)` lo recibe de `FMain`: `EsLibroEnCurso` recién se fija en el apartado 12, después de la llamada.

LO QUE SE RETIRÓ. El `readme.md` vacío de la raíz de la aplicación. Convivía en el repositorio con `README.md`, la portada de gbpublisher, y los dos nombres solo se distinguían por la caja.

PROBADO. Compila con gbc3 3.19. En un proyecto de consola con gbx3 3.19: `File.BaseName` da el nombre sin `.md`, `Stat().Size` da 0 para un archivo vacío y `Stat` de un archivo que no existe falla con «File or directory does not exist».

**Relaciones:** vinculo:RC-GM-02

**PENDIENTE:** Probar en Mint: un proyecto nuevo de cada tipo y uno existente con el readme.md vacío.

### SC-101 — El respaldo diario de la aplicación: completo o ninguno, sin la contraseña a la vista, y SHOW VIEW para app_user (actualización 1.34.0)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8 (Mint) y MariaDB 10.11 (contenedor) / gbc3, gbx3 3.19 / probado en Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 19/11/2026).

EL PROBLEMA. `FMain.RespaldarBaseDatos` corre al arrancar la aplicación (`FAvisoLegal`, formulario inicial) y respalda la base local con mysqldump y la cuenta `app_user`. Desde la 1.19.0 cortaba en la primera VIEW de gbWeb (GV-214) y dejaba un archivo incompleto: sin las vistas ni la tabla `vocabulario_termino`, que va después en orden alfabético. Nadie se enteraba, porque se corría con `Try Shell ... Wait` sin mirar el resultado. Lo mostró una corrida de la aplicación desde la terminal en Mint (19/11/2026).

LOS PERMISOS DE app_user. En Mint, `app_user` tiene `SELECT, INSERT, UPDATE, DELETE` sobre `gbpublisher`, y la aplicación no necesita más para trabajar. El instalador, en cambio, le da `ALL PRIVILEGES`, y el comentario de la 1.23.0 lo da por hecho. Lo que tiene que tener queda para el bloque de credenciales.

LA ACTUALIZACIÓN 1.34.0. Da `SHOW VIEW` sobre la base a cada host de `app_user` que no lo tenga. Es de solo lectura y es lo que necesita mysqldump para copiar las vistas. No toca tablas ni datos, así que no hace respaldo; se deshace con un `REVOKE` que el script muestra. NO da `TRIGGER`: con él, `app_user` podría borrar los disparadores que hacen de `articulo_reapertura` un registro solo de altas (1.23.0).

EL RESPALDO
- `mysqldump` con `Exec` y un arreglo, sin `Shell`. Opciones: `--no-tablespaces`, `--skip-lock-tables`, `--single-transaction`, `--skip-triggers` (a propósito: sin el permiso, mysqldump los omite en silencio), `--default-character-set=utf8mb4`, `--result-file` y `--log-error`.
- La contraseña va en un archivo de opciones en la carpeta temporal del proceso (`--defaults-extra-file`, el primer argumento), que se borra al terminar. En la línea de comandos la veía cualquier usuario en la lista de procesos.
- Se escribe en `gbpublisher_AAMMDD.sql.parcial` y se renombra solo si mysqldump salió con 0 y el archivo cierra con «Dump completed». Si no, se borra el parcial, el anterior queda intacto y un aviso dice el motivo, con el mensaje de mysqldump.
- El archivo queda legible solo por el usuario: tiene toda la base, con las claves cifradas de `usuarios_sistema`.

RESTAURAR. Un respaldo de la aplicación no trae los disparadores. Después de restaurarlo se corre otra vez `actualizar-esquema-1.23.0.sh`, que decide por el estado real y repone los que falten.

PROBADO en el contenedor (MariaDB 10.11, gbc3 y gbx3 3.19), sobre una base con una VIEW, `vocabulario_termino`, un disparador y `app_user` con los cuatro permisos de Mint: el corte reproducido (código 2, sin la marca final); la 1.34.0 aplicada, repetida, cancelada y con un segundo host que ya tenía `ALL`; la función, con un respaldo completo (permisos 600) y con el permiso quitado (aviso con el mensaje de mysqldump y el archivo anterior intacto, la misma huella md5); la contraseña ausente de `/proc/*/cmdline`.

PROBADO EN MINT por Alberto (19/11/2026, MySQL 8): sin la 1.34.0, la aplicación avisó al arrancar con el mensaje de mysqldump («SHOW VIEW command denied … v_web_coleccion (1142)») y no escribió el archivo del día. Con la 1.34.0 aplicada, el respaldo del día quedó completo («-- Dump completed») y con permisos 600. Los respaldos de Mint estaban cortados desde el 2/11/2026; se rescató con un respaldo manual de la cuenta de administración.

DESDE SC-106 (25/11/2026). La credencial ya no se escribe en un temporal. `mysqldump` recibe el archivo de conexión del usuario, `~/.gbpublisher/conexion.conf` (600), con `--defaults-extra-file`, y de ahí salen el usuario y la contraseña. Sin ese archivo no se respalda y no se avisa: el aviso lo da el inicio de sesión.

**Relaciones:** apoya:GV-214,vinculo:SC-22,vinculo:SC-81,vinculo:GV-67,vinculo:SC-106

### SC-102 — La bibliografía en entrada y pares campo/valor: bibtex, bibtex_campo y el catálogo de campos de biblatex (actualización y baseline 2.0.0)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher 2.0.0 / MySQL 8.0.46 (contenedor Ubuntu 24.04) / Gambas 3.19 gbc3 (contenedor; gb.qt5 y gb.db en lugar de gb.qt6 y gb.db2) / bash · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 20/11/2026). La tabla `bibtex` tenía 110 columnas, una por campo de biblatex. En la base de trabajo, al migrar, 4.933 referencias tenían 33.932 valores: siete campos en promedio, de 105. Pasa a un modelo de entrada y pares, y con ella se genera el baseline 2.0.0 (SC-22, PUNTO DE RUPTURA).

EL MODELO

- `bibtex` es la entrada: `id`, `id_proyecto`, `tipo_de_entrada`, `clave_bibtex`, `fecha_modificacion`, `id_origen`.
- `bibtex_campo` guarda un par por dato: `id_bibtex`, `campo`, `valor`. Clave (`id_bibtex`, `campo`): un valor por campo. FK a `bibtex` con ON DELETE CASCADE; FK de `campo` al catálogo con RESTRICT y ON UPDATE CASCADE. `CHECK chk_bibtex_campo_valor (CHAR_LENGTH(TRIM(valor)) > 0)`: sin dato no hay par, ni vacío ni NULL. Índice (`campo`, `valor`(100)) para los autocompletados y las búsquedas por campo; FULLTEXT `ft_bibtex_campo_valor` sobre `valor` (GV-217).
- `bibtex_campo_catalogo` tiene los 105 campos: `campo` (nombre de biblatex, clave), `orden` (único, de 10 en 10: el orden de escritura en el `.bib`, que es el de las columnas viejas), `literal` (el campo no pasa por la regla de órdenes de LaTeX, SC-58) y `nombre_anterior` (la columna vieja, para leer JSON viejos).
- Los nombres son los de biblatex: `tipo_de_tesis` pasa a `type`; `hyphenation` y `lang_id` se unen en `langid` (`lang_id` solo donde `hyphenation` estaba vacío).
- Las referencias siguen por proyecto. Una biblioteca compartida trajo más problemas de los que resolvía; el buscador de relación uniforma la escritura.
- La clave sigue con 32 caracteres como máximo.
- El formulario no cambia: «son campos, se usan o no se usan». Sale el par `txtLangId`/`cmbLangId` (`HBox251`), que se borra en el IDE.

EN EL CÓDIGO

- `m_Bibtex.$MapaCampos` (control → campo). `CargarCatalogo` lo contrasta con el catálogo al arrancar y frena si un campo no tiene control.
- Lectura: una subconsulta por campo (`SubconsultaCampo`). La grilla es de 8 columnas fijas (`ConsultaGrilla`, constantes `COL_*`; GV-58).
- Escritura: una sola función, `EscribirEntrada`, en transacción (GV-173). Hace el INSERT o el UPDATE de la entrada, borra los pares e inserta los que tienen dato; ante cualquier error hace Rollback. Con un id provisorio en la clave, la corrige con el id real dentro de la misma transacción. `FRelacionarBib` (los tres pares de la relación) y `FCorregirBibTeX` (corrección en masa) escriben también en transacción.
- Control al guardar. `langid` admite un solo nombre de babel (`idiomas.babel`). `m_Idiomas.EsNombreBabel` compara en binario.
- `language` y `origlanguage` son texto que se imprime: con una clave de localización de biblatex, el nombre sale traducido («inglés»); con otro valor, sale tal cual (`biblatex.def`, `\DeclareListFormat{language}`, que acepta la clave con o sin el prefijo `lang`). Decisión de Alberto (20/11/2026): solo se admiten claves. Son las 29 de `spanish.lbx` de biblatex 3.19, en la constante `m_Bibtex.CLAVES_IDIOMA_BIBLATEX`. Varias van unidas con « and ». La importación JSON informa los valores que no lo son.
- Selector de idioma, como el de hyphenation: en `language` y `origlanguage`, Enter muestra las claves que contienen lo escrito. Filtra por el último nombre de la lista, y la elección lo reemplaza (`m_FuncionesGenericas.BuscarIdiomaBiblatexDesdeTexto` y `ElegirIdiomaBiblatex`). No va a la base.
- `VerificacionBase` marca como error `relatedtype` y `relatedstring` juntos (RC-BL-01).
- `.bib`: `ExportarBibTeX` recorre dos `Result` en paralelo: las entradas por clave, y los pares unidos al catálogo por clave y orden.
- JSON: exporta con los nombres de biblatex y `"schema": "2.0.0"`. Importa los nombres nuevos y los viejos (`CampoDeNombreAnterior`) e informa los campos descartados, las entradas que fallaron y los idiomas que no son de babel.
- Búsqueda FULLTEXT (`m_BuscarBib`): sobre los pares de `title`, `author`, `booktitle` y `journaltitle`; suma de MATCH por entrada, las 20 mejores.
- `m_ConexionBD.ObtenerEsquemaEsperado`: `bibtex` 6, `bibtex_campo` 3, `bibtex_campo_catalogo` 4.
- Consultas canónicas (`consultas`): la 2.0.0 reescribe las nueve de bibliografía que leían columnas (BIB-002 a BIB-006, BIB-CAL-001 a BIB-CAL-003, BIB-GEO-001). Se identifican por el prefijo del nombre. BIB-001 no cambia.

LA ACTUALIZACIÓN 2.0.0 (`actualizar-esquema-2.0.0.sh`, SC-22)

1. Exige la 1.34.0. Una base instalada desde el baseline 2.0.0 sale sin tocar nada.
2. Antes de empezar, controla que las columnas de `bibtex` sean las del catálogo y estén en su orden, y que ninguna clave foránea apunte a una columna que se borra.
3. Respaldo verificado.
4. Crea el catálogo y `bibtex_campo`.
5. En una transacción: corrige `eng` y `span` a `english` y `spanish`, y copia cada valor no vacío.
6. Crea el FULLTEXT después de la copia (GV-217).
7. Prueba del `.bib`: por proyecto, el SHA2 del `.bib` armado desde las columnas y el armado desde los pares. Si uno difiere, o si la consulta de la prueba falla, vacía los pares y no borra nada.
8. Borra las columnas viejas y `ft_bibtex_busqueda` en un solo ALTER.
9. Pasa `formatos_pdf` a `utf8mb4_unicode_ci` y reescribe las consultas canónicas. Lo hace también al repetir el script: una corrida cortada después del ALTER se completa en la siguiente.
10. Verificación, registro e informe de control de solo lectura:
    - idiomas que no son de babel;
    - claves de 32 caracteres;
    - valores con caracteres de control;
    - consultas guardadas que nombran tablas retiradas en la 1.32.0.

La vuelta atrás que imprime el script borra las dos tablas nuevas y después restaura el respaldo.

MEDIDO (20/11/2026, MySQL 8.0.46 en el contenedor, sobre el respaldo de Alberto `gbpublisher_261120.sql`):

- La migración tarda 4 s.
- Los 31 proyectos dan el `.bib` idéntico byte a byte.
- Las 24 consultas de la aplicación andan.
- La búsqueda FULLTEXT encuentra 300 de 300 referencias reales, como el índice viejo.
- Probados: el alta con corrección de la clave provisoria, la edición, la relación y la corrección en masa; los rechazos del CHECK y de la FK; el borrado en cascada.
- Las nueve consultas reescritas dan las mismas filas que las viejas.
- La segunda corrida y la reanudación tras un corte funcionan; la vuelta atrás también.
- Una copia saboteada se detecta.

Esquema: una instalación desde cero (baseline 1.0.0 y la cadena hasta la 2.0.0) da las mismas columnas, índices, claves, CHECK y vistas que la base de Alberto migrada. La única diferencia es el orden del ENUM `capitulos.tipo_capitulo`, que la 1.11.0 acepta.

EL BASELINE 2.0.0. `generar-baseline.sh` lo genera desde esa instalación desde cero, no desde la base de trabajo:

- doce tablas semilla;
- testigo: `bibtex` con 6 columnas;
- carga con `innodb_strict_mode` activo (GV-67);
- solo MySQL.

Cargado: 68 tablas, las cinco vistas de gbWeb y los disparadores, con esquema y semillas idénticos a los de la base de origen. `instalar-gbpublisher.sh` pasa a esperar 68 tablas y las doce semillas.

La 1.23.0, que repone los disparadores después de restaurar un respaldo de la aplicación, acepta también una base instalada desde el baseline 2.0.0.

**Relaciones:** vinculo:SC-22,apoya:GV-217,vinculo:RC-BL-01,vinculo:SC-58,vinculo:GV-58,vinculo:GV-173,vinculo:RC-GM-15,vinculo:GV-67,vinculo:SC-81

**PENDIENTE:** Aplicar en Mint:
1. Instalar el .deb y correr la 2.0.0 antes de abrir la aplicación.
2. Borrar `HBox251` en `FMain.form`.
3. Probar:
   - alta, edición y relación;
   - corrección en masa;
   - importar y exportar JSON;
   - exportar el `.bib`;
   - compilar un libro con bibliografía.

Revisar a mano lo que listó el informe de control:
- la referencia 1515 (`language` IX, `origlanguage` 73: parecen ser volumen y número);
- seis títulos con saltos de línea;
- cuatro claves de 32 caracteres, dos cortadas.

Decidir:
- si al guardar se cambian los saltos de línea por espacios;
- qué hacer con las 48 consultas guardadas que nombran `articulos` o `revistas_md` (SC-98), entre ellas BIB-ART-001 y BIB-ART-002.

### SC-103 — El gestor de archivos del proyecto: FFileManager, confinado a la raíz, con protecciones y acciones en el menú contextual

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.2 / gb.qt6 / gb.inotify / Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 21/11/2026). `FFileManager` reemplaza al gestor de la pestaña «Proyecto» de `TabPanelIzquierdaInferior`, que se borró, y a Midnight Commander, que abría `btnAbrirDirectorio` y quedó desvinculado de la aplicación: se usa por fuera para las copias grandes. Hace pocas cosas, siempre dentro del proyecto en curso. La lógica está en `m_FileManager` (SC-70); el formulario tiene los controles y los manejadores. Detalle de diseño: `claude/filemanager.md` del proyecto.

LA VENTANA

- `ShowModal`, redimensionable; el tamaño se guarda en `gbpublisher.conf`, `[FileManager]` Ancho y Alto (SC-17). `m_Ventana.FijarBotones(Me)` (SC-20): la salida es Cerrar o Escape (`btnCerrar.Cancel`). La cierra siempre el usuario.
- Todas las acciones están en el menú contextual `menuFF`: Abrir, Renombrar, Borrar, Agregar archivo, Agregar carpeta. Cada ítem se habilita según la selección, con las mismas reglas que la acción.
- `lblRaiz` muestra el .md del proyecto (`m_InicioCierre.ArchivoProyectoEnCurso`); el árbol va con `HideRoot` y sin barra horizontal (RF-15).
- `gvDetalles`, propiedad y valor: nombre, ubicación relativa, tipo, tamaño o contenido directo, fecha, protección; en una pieza, su código y familia; el formato real por los primeros bytes contra la extensión (un HEIC renombrado a .jpg rompe LuaLaTeX). Lo pesado (dimensiones y semáforo de `m_GestionImagenes.EvaluarResolucion` en imágenes, páginas y tamaño en PDF) espera 250 ms con un Timer que se reinicia en cada selección.

EL CONFINAMIENTO

- Navegar y abrir: `DentroDelProyecto` compara la ruta REAL (`File.RealPath`) con la raíz: un enlace simbólico que apunta afuera no saca del proyecto.
- Renombrar y borrar: `UbicacionDentroDelProyecto` resuelve solo la carpeta, así un enlace se opera como enlace.
- Sin proyecto abierto, `FMain` no abre el gestor: con `Root` vacío, `DirView` arranca en `User.Home` (RF-15). Por ahí se escapaba el gestor viejo.

LAS PROTECCIONES

- La raíz y las carpetas predefinidas no se borran ni se renombran. La lista es una sola, `m_FuncionesGenericas.CarpetasPredefinidas()`, la misma con la que `ControlarCarpetas` las crea. Las carpetas temporales de trabajo (REVISAR) son carpetas comunes.
- Un .md de la raíz no se borra ni se renombra: es la identidad del proyecto (SC-82).
- Una pieza (el .md con el prefijo de su carpeta: fm- en front-matter, a- en articulos, bm- en back-matter) no se borra. Se renombra con la regla de SC-104 y el gestor no toca la base: la ficha se corrige en el ABM eligiendo otra vez el archivo, como cuando se renombraba por fuera.
- El archivo abierto en el editor (`FMain.sRutaArchivoAbierto`) no se borra ni se renombra: el editor lo volvería a crear con el nombre viejo.

LAS ACCIONES

- Abrir: un .md nunca (existe el editor); un .xml de `jats/` tampoco (se lee en el editor XML). Lo demás, `Exist` y `Desktop.Open` sin `Wait` (GV-43). Sin tabla de asociaciones propia: manda la del sistema.
- Borrar: definitivo, sin papelera, con una confirmación que dice qué se borra (en una carpeta, cuántos archivos y subcarpetas). Recorre con `Stat`, que no sigue enlaces: un enlace a una carpeta de afuera se borra como enlace (GV-219).
- Nombres: letras sin tilde, dígitos y guion; sin guion bajo (el conversor lo reserva para sus imágenes); extensión de 2 a 4 en minúscula. Al renombrar, la sugerencia viene normalizada («IMG_2034 (1).JPG» → «IMG-2034-1.jpg»), con tildes y ñ por mapa propio (GV-204). Todo .md de una carpeta de piezas sigue la regla de SC-104. `FPedirNombre` valida al aceptar, no por tecla: así se controla también lo pegado. Reemplazó a `FAgregarArchivo` y `FAgregarCarpeta`.

EL CIERRE, EN TRES CAPAS

1. Lo propio: `Form_Close` detiene el Timer y guarda el tamaño. No deja cerrar con un script en curso (`m_Lanzadora.HayScriptEnCurso`): el manejador que lo lanzó sigue esperando con `Wait` y tocaría controles destruidos.
2. Lo de FMain: al volver de `ShowModal`, `btnAbrirDirectorio` llama siempre a `m_GestionImagenes.RefrescarComboSiCambio` y `m_RevisarPDF.RefrescarComboSiCambio` (SC-27). Siempre y no según un valor de retorno: no depende de cómo se cerró ni de si los Timer de FMain corren durante el modal.
3. Lo externo: avisa de los documentos del proyecto que LibreOffice tiene abiertos, por sus archivos de bloqueo `.~lock.<nombre>#`.

EL EMPUJE REMOTO

`btnEmpujar` lanza `engine/empujar_remoto.sh` con el formulario abierto: la salida corre en la terminal de FMain, que se ve corriendo la ventana. El usuario de GitHub se escribe en `txtUsuarioGit` del gestor (con el modal abierto no se puede escribir en FMain) y se guarda en `[GitHub] Usuario` tras un empuje exitoso. Ver SC-53, LANZAR CON UN FORMULARIO MODAL ABIERTO.

**Relaciones:** vinculo:SC-70,vinculo:SC-82,vinculo:SC-104,vinculo:SC-53,vinculo:SC-17,vinculo:SC-20,vinculo:SC-27,vinculo:GV-43,vinculo:GV-204,apoya:GV-219,vinculo:RF-15

**PENDIENTE:** Mini-test: el formato del archivo de bloqueo de LibreOffice (ls -a con un .docx del proyecto abierto); se asumió .~lock.<nombre>#. Medir Image.Load con la imagen más pesada de un proyecto real: si tarda menos de 100 ms, el Timer de los detalles sobra.

### SC-104 — La regla única del nombre de pieza: prefijo-NN-NOMBRE, la del conversor, aplicada al escribir

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.2 / MySQL 8 / esquema 2.1.0 / Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 21/11/2026). El nombre de una pieza tiene una sola regla, la del conversor de .docx, que es la de origen:

    prefijo-NN-NOMBRE

- El prefijo (`fm-`, `a-`, `bm-`) en minúscula; NN, dos dígitos; NOMBRE, mayúsculas, dígitos y guiones. «NN-NOMBRE» tiene hasta 24 caracteres. El NOMBRE es obligatorio.
- Sin guion bajo: el conversor lo usa para separar el nombre de la pieza del de sus imágenes (`NOMBRE_imagenN.ext`).

Vale para las piezas con .md del libro (`capitulos`), las páginas lógicas del libro (sin .md: portadilla, portada, créditos, colofón), los artículos (`articulo`) y las preliminares del número (`numero_pieza`, SC-88). Complementa a SC-44: aquella dice cómo se ordena por el nombre; esta, cómo se escribe.

CUÁNDO SE APLICA

Al ESCRIBIR un nombre: un alta o un cambio. Lo que ya está en la base queda; se corrige solo si se cambia el nombre. Por eso la ficha de capítulos la aplica al guardar solo si el nombre cambió, y al elegir un .md solo si es otro que el que ya tenía.

DÓNDE ESTÁ ESCRITA

Tres lenguajes, una regla; cada copia cita a las otras:
- Gambas: `m_OrdenPiezas` — `MotivoCodigoYNombre`, `MotivoNombrePieza` (con el prefijo esperado, opcional), `NormalizarEscrituraPieza` y las constantes `CARACTERES_NOMBRE`, `DIGITOS`, `LARGO_MAXIMO_NOMBRE`. La consultan `FConversorDOCX2MD` (que dejó de tener la suya), `m_FileManager`, la ficha de capítulos y `m_Metadatos.GuardarMetadatosDeCapitulo`.
- bash: el regex de `engine/convertir_docx.sh`.
- SQL: el CHECK `chk_pieza_nombre` de `numero_pieza` (esquema 2.1.0), que acepta la forma nueva y la vieja en minúsculas para lo que ya está.

AL ESCRIBIR

En la ficha de capítulos, `nombre_archivo` filtra lo que se tipea (letras, dígitos y guion) y acomoda la caja mientras se escribe (prefijo en minúscula, el resto en mayúscula), como el conversor. Es lo que faltaba para las páginas lógicas, que se escribían a mano sin regla.

LO QUE NO CAMBIA

El orden sale del código NN (`m_OrdenPiezas.ClausulaOrden`, `ensamblar-libro-canonico.xsl`), no del resto del nombre. La base compara sin distinguir caja (`utf8mb4_unicode_ci`), salvo el CHECK. Las salidas de revista reconocen las preliminares por `@tipo`, no por el nombre.

El informe de la 2.1.0 lista, sin corregirlos, los nombres que no siguen la regla en `numero_pieza`, `capitulos` y `articulo`.

**Relaciones:** vinculo:SC-44,vinculo:SC-25,vinculo:SC-45,vinculo:SC-55,vinculo:SC-88,vinculo:SC-22,vinculo:SC-103

### SC-105 — Consultas a servicios bibliográficos externos: engine/consultar_doi.sh con tres modos, por m_Crossref, sin mailto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.2 / bash / python3 / curl / Linux Mint · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 21/11/2026). Las consultas a Crossref, OpenCitations y OpenAIRE pasan por un solo script, `engine/consultar_doi.sh`, lanzado por la lanzadora (SC-53) desde un solo módulo, `m_Crossref`. Es el criterio 2 de SC-13: el script consulta y normaliza y deja un TSV; Gambas muestra, compara con la base y aplica.

LOS TRES MODOS

    consultar_doi.sh analisis <doi>    <salida.tsv>   FAnalizarDOI
    consultar_doi.sh crossref <doi>    <salida.tsv>   FMain.btnChequearCrossref_Click
    consultar_doi.sh titulo   <título> <salida.tsv>   FMain.btnCrossrefTitulo_Click

- `analisis`: dato TAB valor, en el orden en que se muestran (DOI, tipo, título, autores con su ORCID, revista, ISSN, fechas, licencia, citas en Crossref y en OpenCitations, presencia en OpenAIRE, enlace a Google Scholar).
- `crossref`: clave TAB valor, con las claves de `FEstructuraResultados.cValoresAplicar` (doi, titulo, anio, paginas, issn, autor). Un dato que Crossref no tiene va vacío y no crea su clave (GV-98).
- `titulo`: hasta cinco candidatos, siete columnas (score, tipo, DOI, título, año, primer autor, revista).

EL CONTRATO

- El DOI llega como se pega (`https://doi.org/…`, `http://dx.doi.org/…`, `doi:…`): el script lo normaliza y controla su forma antes de consultar. Un valor con `$(…)` no llega a ninguna consulta.
- La salida va a `tmp/consulta-doi.tsv` del proyecto: hace falta un proyecto abierto, como en el control de integridad (SC-95). `m_Crossref.HayProyectoAbierto` lo controla y lo explica; «Analizar DOI» no abre sin proyecto.
- El script borra la salida vieja al empezar y escribe la nueva en un temporal que mueve al final: lo que Gambas lee es de esta consulta. La última línea no lleva salto: un valor vacío al final sigue siendo una columna.
- Códigos: 0; 3 si OpenCitations u OpenAIRE no respondieron (la fila dice «(sin respuesta)») o si la búsqueda por título no encontró nada (salida vacía); 1 si Crossref no responde, no tiene el DOI o el DOI no tiene forma de DOI. El motivo, en la terminal.
- El JSON lo lee `python3` dentro del script (SC-95 lo da por garantizado); bash hace las consultas y muestra el avance.
- `FAnalizarDOI` lanza desde un modal: valen las reglas de SC-53 (curl no pregunta nada, controles apagados mientras espera, `Form_Close` no cierra con un script en curso).

SIN mailto

Crossref ofrece una cola preferente a quien se identifica con un correo. La aplicación no manda ninguno: cada instalación se presentaría con el mismo. El agente HTTP identifica a la aplicación y su repositorio, no a quien la usa.

LO QUE QUEDA EN GAMBAS

`m_DOI.VerificarDOI` y las consultas de `m_Orcid` solo necesitan un código HTTP o una respuesta corta por stdout: criterio 3 de SC-13, `Exec … To` (GV-20), sin script. Antes usaban `Shell` con `Quote()` (GV-06).

LO QUE SE RETIRÓ (22/11/2026)

De `FAnalizarDOI`: tres `Shell "curl …"` con el DOI entre comillas simples, `ProcesarRespuestas` y sus auxiliares de fechas y entidades, y la apertura de URL con `Shell "xdg-open '…'"` (GV-06). De FMain: los temporales fijos en `/tmp`, dos `python3 -c` armados como string y el lector de JSON a mano (`ExtraerValorJson`, `ExtraerDesde`, `DecodificarJson`).

Probado por Alberto en Mint (22/11/2026): los tres modos a mano contra los servicios reales; en la aplicación, «Analizar DOI» con y sin proyecto, el clic en una URL, el cierre bloqueado durante la consulta, los dos botones de Crossref y «Aplicar»; `m_DOI`, `m_Orcid` y el aviso legal.

**Relaciones:** vinculo:SC-13,vinculo:SC-53,vinculo:GV-06,vinculo:GV-20,vinculo:GV-43,vinculo:GV-98,vinculo:SC-95,apoya:GV-221

### SC-106 — La credencial de app_user sale del código: ~/.gbpublisher/conexion.conf por usuario, configurar-conexion.sh y sin contraseña de respaldo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / MySQL 8.0.46 / Gambas 3.19 (gbs3, gbc3; contenedor Ubuntu 24.04) / bash / Linux Mint 22, Gambas 3.22.2, pkexec (25/11/2026) · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 25/11/2026). Hasta acá la contraseña de `app_user` era la misma en todas las instalaciones y estaba escrita en cinco lugares del código público: `m_ConexionBD` (ConexionAbierta, SondearEstadoConexion, AbrirConexionSondeo), `FMain.RespaldarBaseDatos` y `FSysAdmin.ConectarMySQL`, más `instalar-gbpublisher.sh`. Pasa a un archivo de configuración. Es requisito del instalador (SC-107).

EL ARCHIVO

- **Uno por usuario de la computadora:** `~/.gbpublisher/conexion.conf`, permisos 600. No se eligió `/etc/gbpublisher` con un grupo porque quien entra a un grupo tiene que cerrar sesión y volver a entrar antes de usarlo: para el usuario de gbpublisher es una trampa.
- **Aparte de `gbpublisher.conf`.** Ese archivo de preferencias lo reescribe la aplicación con `Settings`, y no se midió si conserva los permisos 600. A este, la aplicación solo lo lee.
- **El formato es un archivo de opciones de MySQL, el modelo de gbWeb (SC-81):** `[client]` con `user`, `password` y `host`; `[mysql]` con `database`.
  - `database` no va en `[client]` porque `mysqldump` la rechaza (GV-222).
  - Lo leen la aplicación (`gb.settings`, GV-223), `mysql` y `mysqldump` (`--defaults-extra-file`).
  - El `host` lo usan las herramientas de MySQL. La aplicación sigue usando la IP que se elige al iniciar sesión.

LA APLICACIÓN

- **`m_ConexionBD.PrepararConexion(hConn, sHost)` es el único lugar que arma la credencial.** Lee `client/user` y `client/password` y configura la conexión. La usan los cinco lugares.
  - No usa `mConn`: `FSysAdmin` la llama sin sesión (GV-151).
  - Si falla, el motivo queda en `ErrorCredenciales`.
- **Sin contraseña de respaldo en el código (decisión de Alberto):** sin archivo no hay conexión. El inicio de sesión y `FSysAdmin` dicen qué hacer: ejecutar el instalador o `configurar-conexion.sh`.
- **El respaldo diario (SC-101)** le pasa a `mysqldump` el propio `conexion.conf` con `--defaults-extra-file`. Ya no escribe una copia temporal de la contraseña, y sigue sin contraseña en la línea de comandos. Sin archivo no respalda y no avisa: el aviso lo da el inicio de sesión.

configurar-conexion.sh (RAÍZ DEL REPOSITORIO)

Sigue el modelo de `crear-cuenta-gbweb.sh` (SC-81).

- **Corre sin sudo:** el archivo es del usuario. Con sudo se niega.
- **La parte de MySQL corre como root, con `pkexec`** (ventana gráfica, GV-206), y con `sudo` si no hay sesión gráfica. `--con-sudo` fuerza sudo; lo usa `instalar-gbpublisher.sh`, que ya lo tiene.
  - La parte de root es el mismo script con `--root <archivo>`.
  - pkexec limpia el entorno, así que la parte de root no toca `~/.gbpublisher`.
- **Decide por el estado real.** Si el archivo existe y abre una sesión, no toca nada. Si no:
  1. genera una contraseña;
  2. la pone en TODAS las cuentas `app_user` del servidor (`localhost` y los rangos de red);
  3. escribe el archivo entero, con permisos 600, y lo mueve a su lugar;
  4. verifica que abre la sesión.
- **La contraseña:** 28 letras y cifras al azar, la primera una letra, más el sufijo fijo `Gb7_` (mayúscula, minúscula, cifra y símbolo, por si el servidor tiene `validate_password`).
  - No lleva `#`, que en un archivo de opciones empieza un comentario, ni comillas.
  - Nunca va en una línea de comandos: viaja a la parte de root en un archivo temporal 600 y a MySQL por la entrada estándar. No se usa la entrada estándar de `pkexec` porque no está verificada (GV-206 verificó solo la salida).
- **Generación de la contraseña.** Se hace con `head -c 4096 /dev/urandom | tr -dc 'A-Za-z0-9'`, no con `tr -dc … </dev/urandom | head -c N`. En la segunda forma `tr` muere por SIGPIPE, y bajo `set -e` y `pipefail` eso corta el script: medido, salida 141 en `instalar-gbpublisher.sh`.
- **Salida:** 0 en regla, 1 algo quedó sin resolver.
- **Atención:** cambiar la contraseña corta a toda máquina que se conecte con la vieja. Cada cliente necesita una copia del archivo, con `host` = la IP del servidor (`BBDD_LEEME.md` §6). El caso de varias máquinas (Eduvim) queda para después de hablar con su administrador.

instalar-gbpublisher.sh

- Crea las cuentas con una contraseña provisoria al azar, que va por la entrada estándar.
- Al final llama a `configurar-conexion.sh --con-sudo`, que pone la definitiva y escribe el archivo. Si ese paso falla, avisa: la base quedó instalada, pero falta el archivo.

PASAR UNA INSTALACIÓN EXISTENTE

1. Instalar el `.deb` de la primera versión que lee el archivo.
2. Una vez, sin sudo, antes de abrir la aplicación: `bash configurar-conexion.sh`. Si no se hace, la aplicación no conecta y dice qué hacer.

`LEEME.md` lo pide en «Actualizar una instalación existente». El instalador (SC-107) lo hará solo.

PROBADO (25/11/2026, contenedor Ubuntu 24.04, MySQL 8.0.46, Gambas 3.19 con gb.db y gb.qt5, un usuario común con sudo; sin pkexec, que no tiene agente de polkit):

- **`configurar-conexion.sh`:**
  - creación desde cero, con dos cuentas (`localhost` y `10.0.%.%`, las dos con la clave nueva);
  - segunda corrida, que no toca nada;
  - archivo con la clave equivocada, que se rehace;
  - sin `app_user`, que da un error claro y salida 1;
  - con sudo, que se niega;
  - tres claves generadas, de 32 caracteres cada una.
- **`mysqldump`** con el archivo, hasta «Dump completed».
- **`instalar-gbpublisher.sh`** completo, como usuario común, con el archivo escrito al final.
- **Gambas:** `gbs3` con `gb.settings` y `gb.db`, que lee el archivo, abre la conexión y consulta.
- **El proyecto actual compila** con los tres archivos cambiados.

PROBADO EN MINT (Alberto, 25/11/2026; Linux Mint 22, Gambas 3.22.2, MySQL 8.0):

- **`configurar-conexion.sh`** desde una terminal, con pkexec: se abrió la ventana; la salida de la parte de root se vio en la terminal; se cambió la clave de `app_user@localhost` y se escribió el archivo. La segunda corrida dijo «en regla» y no tocó nada.
- **La aplicación con el archivo:** el inicio de sesión a 127.0.0.1, el semáforo en verde (SondearEstadoConexion) y FSysAdmin («Acceso concedido como SUPERADMINISTRADOR»).
- **El respaldo diario:** borrado el del día y reabierta la aplicación, se recreó `gbpublisher_261125.sql` (2,6 MB). La función solo deja el archivo si salió completo.
- **Sin el archivo:** el inicio de sesión no conecta, muestra la ruta completa y la indicación de ejecutar `configurar-conexion.sh`, y el semáforo queda en rojo.

AJUSTE DEL MISMO DÍA. El aviso de copiar el archivo a otras máquinas sale solo si el servidor tiene cuentas `app_user` de red, además de la de `localhost`. Con solo `localhost` era ruido. La parte de root lo informa con la salida 4 (0 = solo `localhost`). Probado en el contenedor con y sin una cuenta de red. Probado también el caso de un servidor apagado: la salida es 3, con el mensaje de MySQL.

**Relaciones:** vinculo:SC-81,vinculo:SC-101,apoya:GV-222,apoya:GV-223,vinculo:GV-151,vinculo:GV-206,vinculo:SC-107

**PENDIENTE:** Probar en Mint: las notas, que abren su propia conexión (AbrirConexionSondeo), y cerrar la ventana de pkexec con la X (código 126).

### SC-107 — El instalador: instalador.sh versionado contra el .deb, sin sudo y con pkexec, para usuarios sin formación técnica que instalan solos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Linux Mint 22 (Ubuntu 24.04) y 23 (Ubuntu 26.04) / openSUSE Build Service home:gambas:stable / MySQL 8.0 y 8.4 / pkexec · **Verificado:** 2026-11

DECISIONES CERRADAS (Alberto, del 20/11 al 25/11/2026), después de discutir las fricciones. Falta implementarlo.

PARA QUIÉN

- Editores y estudiantes de edición sin formación técnica, que instalan solos y de forma asincrónica:
  - los alumnos de los cursos virtuales de Alberto, que reciben como consigna descargar el instalador;
  - unos 150 editores de la REUN, de todo el país.
- Cada uno en su máquina o en una de pruebas, con su base local. Las editoriales consultadas prefieren evaluar así antes de pensar en la migración interna.
- Fuera de la primera versión queda el modo compartido: un servidor con varios usuarios o puestos (Eduvim, con escritorio remoto y VPN). Se documenta aparte, después de que Alberto hable con su administrador.

CÓMO LLEGA Y CÓMO SE EJECUTA

- **Un instalador por release, versionado contra el `.deb`:** `instalador-X.Y.Z.sh`, publicado como archivo de la release.
  - Lleva escritas su versión, las direcciones de esa etiqueta y la huella del `.deb`, que verifica antes de instalar.
  - No consulta la API de GitHub.
  - Se genera desde una plantilla, como el baseline: no se edita a mano.
  - Un error del propio instalador se corrige con una revisión (`instalador-X.Y.Z-rN.sh`), nunca reemplazando el archivo publicado.
  - Un instalador más viejo que lo instalado frena: nunca baja de versión.
- **La línea para pegar:** `curl -fsSLo instalador.sh <URL> && bash instalador.sh`. No `curl … | bash`: en esa forma la entrada del script es la descarga y las preguntas leerían el propio script. El archivo queda y se puede volver a ejecutar.
- **Sin sudo:** la contraseña de administrador se pide una vez, con `pkexec` (ventana gráfica, GV-206).
- **`LEER-INSTALADOR.md`, en el repositorio y de la misma etiqueta,** explica qué hace el instalador y qué se decidió. Lo primero que pregunta el instalador es si se leyó. Con «no», cancela, pide que se lea y da la dirección. El `README.md` dice, arriba, que la instalación se hace con el instalador.
- **Mensajes simples y en color,** con el vocabulario de la consola de FMain. Antes de cada decisión va un texto que la explica. Las decisiones se reducen a lo inevitable: lo que está decidido no se pregunta.

LO QUE HACE

1. **Controles previos, sin tocar nada:**
   - sistema (Mint 22; Mint 23 cuando esté probado);
   - espacio en disco;
   - conexión y respuesta de cada sitio de descarga;
   - MariaDB, que frena (GV-209).

   Una sesión que no es X11 no frena: la aplicación ya lo avisa al arrancar.
2. **Detectar el caso:**
   - instalación nueva;
   - actualización;
   - reinstalación (sin aplicación y con base);
   - instalador más viejo, que frena.
3. **Gambas:** el repositorio `home:gambas:stable` de openSUSE.
   - Medido el 20/11/2026: existe para `xUbuntu_24.04` y `xUbuntu_26.04` (200). No hay repositorio por versión `3.22` para ninguna de las dos bases (404).
   - Gambas sigue al canal estable. El `.deb` declara la versión mínima.
   - Si hay un Gambas de Mint u otro repositorio de Gambas, se reemplaza: no se mezclan.
4. **El `.deb`:** descarga, huella e instalación con `apt install ./paquete.deb`. TeX Live es el paso largo y se muestra el progreso.
5. **Las herramientas de `/opt`:** se delegan en `engine/integridad.sh` del `.deb` (SC-95), que hay que adaptar para que corra sin un proyecto abierto. No hay una segunda lista.
6. **La base:**
   - en una instalación nueva: MySQL si falta, el baseline y `app_user` solo local;
   - en una actualización: un solo respaldo y los scripts de esquema en un modo no interactivo.

   La credencial, con `configurar-conexion.sh` (SC-106).
7. **Control final:** conexión e integridad.
8. **Cierre:** qué se hizo, dónde quedó el registro y «Pulse Enter para cerrar».

REGISTRO Y SOPORTE

- **Registro:** cada corrida escribe `~/gbpublisher-instalacion.log`.
- **Soporte:** un formulario de issues en GitHub (`.github/ISSUE_TEMPLATE`). Tener cuenta de GitHub es condición (decisión de Alberto). Ante un error, el instalador da el enlace al formulario ya cargado (versión, sistema y paso) y pide adjuntar el registro.
- **Cómo crear la cuenta y reportar** lo explica un artículo del blog de Estudio 2A, al que remite `LEER-INSTALADOR.md`.

MINT 23

Sale en diciembre de 2026, sobre Ubuntu 26.04.

- **MySQL 8.4:** Ubuntu 26.04 trae la serie 8.4 (`mysql-server` 8.4.8 en la base).
  - Medido en el contenedor: `app_user` ya usa `caching_sha2_password`, el método que la 8.4 usa por defecto.
  - Las 82 claves foráneas del esquema 2.0.0 apuntan a una clave única o primaria, que la 8.4 exige.
  - Falta probarlo con un servidor 8.4 real.
- **Wayland** pasa a tener soporte, y X11 sigue siendo la sesión por defecto según lo anunciado.
- **Una tanda de pruebas aparte,** en una máquina virtual:
  - Gambas `stable`;
  - MySQL 8.4: el baseline, la cadena y el paso de una base 8.0 a 8.4;
  - las salidas;
  - el cambio de base en la misma máquina: corregir la línea del repositorio de Gambas y verificar la base.

  Cada instalador declara para qué bases fue probado.

TeX Live sigue sin congelarse (SC-95): según la experiencia de Alberto, no rompe hacia atrás.

**Relaciones:** vinculo:SC-95,vinculo:SC-106,vinculo:SC-22,vinculo:GV-206,vinculo:GV-209,vinculo:SC-81

**PENDIENTE:** Implementar, en este orden:
1. La plantilla del instalador y su generador (versión y huella del .deb).
2. engine/integridad.sh sin proyecto abierto.
3. El modo no interactivo de los scripts de esquema.
4. LEER-INSTALADOR.md y la sección del README.
5. El formulario de issues.
6. El artículo del blog sobre la cuenta de GitHub.

Después: la tanda de Mint 23 y el modo compartido (Eduvim).

### SC-108 — Crossref para libros: el XML de depósito desde el canónico y la base, con el DOI del libro obligatorio y el registro manual del depósito

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Crossref 5.4.0 / Saxon-HE / xmllint / Linux Mint, probado por Alberto; gbc3 3.19 y Saxon 9.9 en el contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 25/11/2026). Debate y decisiones: `claude/crossref-libros.md` del proyecto. Esquema: Crossref 5.4.0 (`schemas/crossref/crossref5.4.0.xsd` del paquete).

LO QUE MANDA CROSSREF

- El DOI del libro es obligatorio: no se depositan capítulos con DOI sin el DOI de la obra (guía de marcado de libros y capítulos). El XSD lo deja opcional; manda la guía.
- Sin ISBN, `<noisbn>` es obligatorio.
- `content_item` exige `doi_data`.
- `book_series_metadata` admite un solo `publisher`.

CÓMO SE ARMA

- Menú de FMain para el libro (`m_GenerarSalidasLibro.GenerarCrossrefLibro`). Gambas escribe el volcado de la base, `tmp/crossref-libro-datos.xml` (versión 1, `EscribirVolcadoCrossref`), y lanza `engine/generar_crossref_libro.sh` (SC-13). El script ensambla el canónico y aplica `xslt/libro-a-crossref.xsl` con Saxon (parámetros `canonico`, `manifiesto`, `timestamp` y `libro`).
- Antes de transformar, la plantilla con nombre `verificar` de la misma hoja devuelve un TSV con los frenos y los avisos: la regla vive en un solo lugar. El script lee el TSV pasando el tabulador a 0x1F antes de `read` (GV-162), y manda los mensajes de java a un archivo aparte.
- Las piezas son los elementos del canónico con `xml:id` de la forma `cap-N` (`^cap-[0-9]+$`).
- El validador del XSD está en `engine/crossref_comun.sh`, compartido con revistas; salió de `revista_comun.sh`, que ahora lo incluye.
- En la pestaña de validación de FMain, la opción Crossref se habilita también para libros (`m_Validaciones.EsLibro`; `validar_sabor.sh`, `validar_crossref_libro`).

MAPEOS

- `book_type`: monografia, manual y traduccion → monograph; obra_colectiva, compilacion y actas → edited_book; referencia → reference.
- Roles: author → author; editor, cualquiera sea su role → editor; othercredit translator → translator. Los demás no van.
- ISBN: impreso → `media_type="print"`, electrónico → `electronic`. Sin ninguno, `noisbn reason="monograph"` con aviso. Impreso igual al electrónico: FRENO, es un error de carga.
- Serie: la más específica con ISSN (la subserie antes que la serie); `volume` es el número en la colección.
- Editoriales: un `publisher` por editorial del libro, en orden; en la serie, solo la principal (SC-88).
- Licencia: `ai:program` con `ai:license_ref applies_to="vor"`.

PIEZAS Y DESTINOS

- Sin `doi_libro`, FRENA.
- Van como `content_item` solo las piezas con DOI. FRENAN: un DOI de otro prefijo que el del libro, un DOI repetido y un `capitulo` sin DOI cuando al menos una pieza tiene.
- `resource` del libro: `url_libro`. De cada pieza: `url_libro` + `h-{nombre_archivo}.html`, la página propia del capítulo en el HTML del libro.
- Con el libro depositado, una pieza con DOI no se renombra: el nombre es parte de la URL registrada (`m_Metadatos.GuardarMetadatosDeCapitulo`, apartado 3c).
- Páginas: las de la composición (SC-109). Una pieza sin folio va sin `pages`.

CITAS

`citation_list` por pieza: su bibliografía o, si el libro tiene bibliografía consolidada, lo que la pieza cita (`biblioref`). Si ninguna pieza tiene DOI, las referencias van en el libro.

EL REGISTRO DEL DEPÓSITO

gbpublisher no deposita: arma y valida el XML, y la editorial lo sube. `libros_md.crossref_fecha_deposito` (2.3.0, SC-22) registra que se subió.

- En la ficha del libro, «marcar» pone la fecha de hoy (si ya había una, pregunta: es otro depósito) y «quitar» la borra; se graba con Guardar. El campo es de solo lectura, con la norma de diseño de esos campos.
- No es un `DateBox`: no admite vacío (GV-226).
- Con la fecha puesta: una pieza con DOI no se renombra (quitar la marca es el camino para hacerlo), y si la composición cambia las páginas avisa que hay que redepositar (SC-25).
- Las columnas por capítulo (`capitulos.crossref_estado` y `crossref_fecha_deposito`) no tenían uso y se borraron en la 2.4.0.

PROBADO

Por Alberto en Mint, con las pruebas de los frenos, incluido un DOI falso.

**Relaciones:** vinculo:SC-13,vinculo:SC-22,vinculo:SC-25,vinculo:SC-52,vinculo:SC-53,vinculo:SC-72,vinculo:SC-85,vinculo:SC-88,vinculo:SC-105,vinculo:SC-109,vinculo:GV-162,vinculo:GV-226

**PENDIENTE:** Partes con DOI: Alberto tiene libros con partes, todavía sin DOI de libro. Las partes viven solo en la base (`partes_libro`, `capitulos.id_parte`); el canónico es plano. Para depositarlas como `content_item component_type="part"` hacen falta el DOI y el título en el manifiesto, y una página de destino para la parte, que hoy no existe (en el HTML la parte es un rótulo del índice). Se decide cuando haya un libro con partes y DOI. Aparte: un registro del depósito como este para los números de revista.

### SC-109 — Paginación del libro: la escribe la composición, leída de los .aux por engine/paginacion_libro.pl

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / LuaLaTeX, TeX Live / perl / pdfinfo (poppler-utils) / Linux Mint, probado por Alberto con Duek · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 25/11/2026). Las páginas del libro y de cada pieza tienen un solo escritor: la composición. El formulario las muestra y no las deja editar (SC-25).

DE DÓNDE SALEN

`engine/paginacion_libro.pl` lee `main.tex` y el `.aux` de cada pieza:

- inicio: el folio de `\newlabel{cap-ID}{{…}{FOLIO}…}`, el rótulo que el generador pone al abrir cada pieza;
- fin: la página de `\@setckpt` al cerrar la pieza, menos uno, en el estilo del inicio (arábigo o romano);
- salida: `archivo<TAB>id<TAB>inicio<TAB>fin<TAB>paginas`;
- una pieza sin folio (dedicatoria, foto) va a stderr como «página especial, sin folio» y queda en NULL.

`compilar_pdf_libro.sh` borra el TSV viejo al empezar, exige `perl` y `pdfinfo`, y en su apartado 8 escribe `tmp/paginacion-libro.tsv` de forma atómica, con una fila `(libro)` que lleva el total de `pdfinfo`.

CUÁNDO NO SE ESCRIBE

- Con un `\includeonly` activo, o con un `.aux` que falta o no se lee, no hay TSV: aviso (código 3) y el PDF se entrega igual.
- La salida PDF/A no escribe páginas.

LO QUE HACE GAMBAS

`m_GenerarSalidasLibro.GuardarPaginacion` guarda todo en una sola transacción:

- Si una pieza del TSV no coincide con la base (`nombre_archivo` e id), no guarda nada.
- Libro publicado (`EsLibroPublicado`): no escribe; si las páginas cambiaron, lo avisa y muestra las diferencias.
- Avisos «volvé a componer» y «redepositar en Crossref»: SC-25 y SC-108.
- `RangoLegible` arma lo que muestra el formulario, «(sin páginas)» para una pieza sin folio.

MEDIDO

Con Duek: el total 152 y cada pieza con sus folios (por ejemplo, la introducción IX–XXII y el capítulo 3, 45–60), cotejados por Alberto contra el PDF.

**Relaciones:** vinculo:SC-25,vinculo:SC-13,vinculo:SC-53,vinculo:SC-108

### SC-110 — Fórmulas: el canónico guarda el TeX del autor y el MathML; el PDF compone el TeX, el HTML y el EPUB copian el MathML; la fórmula en bloque va adentro del párrafo que la introduce

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / Saxon-HE 12.9 / xmllint / LuaLaTeX, TeX Live 2023, unicode-math, Libertinus Math / epubcheck 4.2.6 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 25-26/11/2026), a partir del libro de economía de Iñigo Carrera: fórmulas en línea, sistemas de ecuaciones y fórmulas más anchas que la caja. Lote 1: el libro. Las revistas, la fórmula numerada y los avisos van en el lote 2.

EL .md

- En línea, `$…$`; en bloque, `$$…$$`. La fuente es TeX: lo que deja Pandoc al convertir el Word (OMML) y lo que corrige el editor.
- La fórmula en bloque va pegada a la frase que la introduce, sin línea en blanco antes. El texto que sigue sin línea en blanco («donde», «siendo, en general») continúa el mismo párrafo y no lleva sangría. Es lo que se hacía en LaTeX y lo que Alberto quiere repetir.
- Los cortes de una fórmula ancha los decide el editor con amsmath: `aligned` (sistemas, alineados en el = o el ≠), dos renglones con `&` y `&\qquad +` para la ecuación que no entra, `\vdots` entre grupos. El HTML y el EPUB no cortan: la fórmula ancha se desplaza de costado (CSS).
- Una variable de una letra, `$A$`; de varias letras, `$\mathit{co}$` (decisión de Alberto). Una letra que nombra un caso o una técnica («caso *b*», «la técnica *b*)») no es una variable: bastardilla de texto.
- La prima es `'`, no la ’ que trae el Word, y va antes del superíndice: `g'^{c}_{x}` (GV-228).
- Los dólares se escriben USD; un $ como texto, `\$` (GV-227).

EL CANÓNICO. `filters/formula.lua` (cadena del libro, 0c°: después de cuadro-leer y espacio-fijo, antes de todo filtro que serializa) reemplaza cada fórmula por su ecuación con las dos formas:

    <inlineequation><alt role="tex">c_{ij}</alt><mml:math>…</mml:math></inlineequation>
    <informalequation><alt role="tex">…</alt><mml:math>…</mml:math></informalequation>

El escritor DocBook de Pandoc guarda solo el MathML (GV-229); convertir MathML a TeX en XSLT perdería los cortes del autor. Con el alt antes del MathML el capítulo valida contra DocBook 5.2. Una fórmula adentro de una nota llega con sus dos formas: formula.lua corre antes de cite-to-biblioref-db, que serializa las notas sin --mathml (RC-DB-07). No entra en un bloque `.formula`: ese lo arma fenced-divs-to-elements-db como `<equation xml:id>`, del lote 2.

EL PDF (docbook-to-latex.xsl). Compone desde el alt, sin escaparlo: `$…$` en línea; `\[ … \]` en bloque, con saltos de línea y sin línea en blanco, adentro del párrafo. Un sistema (un solo `aligned` que ocupa toda la fórmula) sale como `align*`: `aligned` es una caja que no se parte, y el sistema a precios de producción del capítulo 10 de Inigo, más alto que la caja de texto, invadía el pie. `align*` tiene las mismas columnas y se parte con `\allowdisplaybreaks`. Un renglón que empieza con `&\qquad` es la continuación de la ecuación anterior: el `\\` que los separa pasa a `\\*` y la página no se corta entre los dos (en el .md no se puede escribir `\\*`, GV-229). Sin alt frena («FÓRMULA SIN SU TeX»: el canónico es anterior a formula.lua). Un `<equation>` frena con su propio mensaje hasta el lote 2. CONTRATO 24 (preambulo-contrato-comun.tex): amsmath explícito, antes de unicode-math, `\allowdisplaybreaks`, y `\decimalpoint` después de babel: el punto decimal también en la fórmula, como \num (SC-64, GV-230).

EL HTML Y EL EPUB (formula-comun.xsl, incluida en docbook-to-html.xsl y docbook-to-epub.xsl). Copian el MathML como `<math>` sin prefijo y descartan el alt; los atributos pierden el prefijo `mml:` (GV-229); la fórmula en bloque lleva `display="block"` y queda adentro del `<p>`. Sin CDN ni JavaScript. El EPUB declara `properties="mathml"` en cada ítem con fórmulas (generar_epub_libro.sh, paso 7b): el OPF lo escribe Gambas antes de los capítulos y no sabe cuáles las tienen. CSS: `math[display="block"]` con desplazamiento horizontal.

PROBADO EN EL CONTENEDOR (26/11/2026), con los capítulos 3, 9 y 10 del libro Inigo por la cadena completa de filtros del libro: los canónicos validan (xmllint, DocBook 5.2); LuaLaTeX con el preámbulo real del libro compila los tres sin errores ni cajas desbordadas (50 páginas), y el sistema largo del capítulo 10 se parte entre dos páginas por una ecuación entera; el EPUB del capítulo 9 pasa epubcheck 4.2.6 sin errores ni advertencias.

LOTE 2a (26/11/2026): EL LIBRO

LA NUMERADA. Se escribe `[$$…$$]{#eq-nombre}`, pegada a la frase que la introduce: queda adentro del párrafo como la otra, y el «donde» que sigue no lleva sangría (decisión de Alberto; Pandoc lo lee como un corchete con id, GV-231). `formula.lua` arma `<equation xml:id="eq-nombre">` con el alt y el MathML. Frena si el id no es `eq-` con letras sin acento, cifras o guiones, si el corchete lleva clases o si adentro no hay una sola fórmula en bloque. El viejo `::: {.formula #eq-…}` frena con un mensaje: cortaba el párrafo y su `<equation>` no tenía el TeX. Los id `eq-` son globales en el libro (`db:es-id-global`), como `fig-` y `tbl-` (SC-32).

EL NÚMERO. El de la figura (SC-32): 9.1 en un capítulo numerado, A.1 en un apéndice, 1 en una pieza sin número; solo las numeradas cuentan. PDF: `\begin{equation}\label{eq-nombre}` con `\theequation` del contrato 9; un sistema numerado (`aligned`) lleva un solo número y no se parte. HTML y EPUB: `<span class="formula-numerada" id="eq-nombre">` adentro del `<p>`, con la fórmula y el número a la derecha (`nl:numero-ecuacion` de numeracion-libro.xsl; CSS con flex).

LA REMISIÓN. `@eq-nombre`, desde cualquier capítulo (cite-to-biblioref-db.lua: `<xref linkend>`). Escribe el número entre paréntesis, «(9.1)», como `\eqref` (decisión de Alberto): PDF `\eqref`; HTML y EPUB, `nl:texto-referencia`. La palabra («la ecuación») la escribe el editor, como en las figuras.

LOS AVISOS (controles_md.lua, todos aviso; decisión de Alberto): `formula_prima` (la ’ adentro de una fórmula), `formulas_pegadas` (dos `$…$` seguidos), `formula_abre_parrafo` (una fórmula en bloque, suelta o numerada, que abre su párrafo: deja un renglón vacío arriba en el PDF), `formula_en_celda`, `matriz_como_sistema`, `variable_como_texto` (bastardilla con subíndice, superíndice o prima: `*r~V~*`, `*g’*`), `dolar_us` (US$, U$S: va USD) y `letra_en_bastardilla` (una letra sola en bastardilla, salvo el rótulo seguido de paréntesis o prima: `*b*)`, `*d*′)`). En el libro Inigo: capítulo 4, 83 variables como texto y 87 letras solas; capítulo 3, 18 fórmulas que abren párrafo y 12 primas. La pasada de controles ya no muestra «Could not convert TeX math» (comun.sh, GV-231).

LAS PRIMAS DE RÓTULO (limpiar_docx.lua, pasada 5b, decisión de Alberto). Un rótulo con variantes, «la técnica *d*′)», «*d*″)», llega del Word como `d’)` y `d”)`: el autor teclea `'` y `"` y el autocorrector los cambia. La pasada de comillas tomaba la ” por una de cierre y dejaba `d»)`. Antes de las comillas, una letra suelta seguida de la marca (’ ' ” ") y un paréntesis de cierre pasa a ′ (U+2032) o ″ (U+2033), también con la letra en otro tramo de cursiva. «l’État» y «ád’)» quedan. La forma del .md: la letra en bastardilla, la prima y el paréntesis en redonda, `*d*′)`; Libertinus Serif tiene los dos caracteres.

PROBADO EN EL CONTENEDOR (26/11/2026): una numerada en el capítulo 10 de Inigo, con una remisión desde el mismo capítulo y otra desde el 9: los canónicos validan; el PDF da «(3.1)» a la derecha de la fórmula y en las dos remisiones (tercer capítulo de la prueba), con enlace; el EPUB da el mismo número y enlaza al otro capítulo, y pasa epubcheck sin errores ni advertencias. Los controles, sobre un archivo de prueba con un caso de cada aviso y sobre los capítulos 3, 4, 9 y 11. La limpieza, sobre un párrafo con las ocho formas y comillas reales.

LOTE 2b (26/11/2026): LAS REVISTAS

El mismo modelo que el libro (decisión de Alberto): el canónico JATS guarda el TeX y el MathML en `<alternatives>`, que el escritor de Pandoc ya pone (GV-229); el PDF compone el TeX; el HTML y el EPUB copian el MathML, sin MathJax ni CDN.

LA NUMERADA. Se escribe igual que en el libro, `[$$…$$]{#eq-nombre}`. `formula-jats.lua` (FILTROS_REVISTA, después de espacio-fijo) arma `<disp-formula id="eq-nombre"><label>(1)</label><alternatives>…`: el número es automático, en el orden del artículo, y va en el canónico, para que el PDF, el HTML, el EPUB y los sabores (SciELO lee el `<label>`) muestren el mismo. Frena en los mismos casos que `formula.lua`. No hay remisión: `@eq-` sigue frenando en `cite-to-xref.lua` y la mención («la ecuación (2)») la escribe el autor (SC-32).

PDF (`jats-a-latex-articulo.xsl`). Plantillas propias, que ganan a las de `jats-to-latex.xsl`: la de `mml:math` escribía un texto provisorio pegado al TeX en cada fórmula. En línea, `$…$`; en bloque, `\[…\]`, o `align*` si la fórmula es un solo `aligned` (se parte entre páginas; `\\*` antes del renglón que empieza con `&\qquad`); la numerada, `equation*` con `\tag*{(n)}` del `<label>`, y un sistema numerado no se parte. Sin `<tex-math>` frena. El `\decimalpoint` del contrato común 24 vale también para la revista: «3.5» sale con punto.

HTML Y EPUB. `formula-jats-comun.xsl`, incluido en `jats-a-html-articulo.xsl` y `jats-a-epub-articulo.xsl`: `<math>`, `<math display="block">` o `<span class="formula-numerada">` con el número, el mismo armado que el libro y las mismas reglas de CSS (`gbpublisher.css` para el HTML; `gbpublisher-epub-revista.css`, sección 19, para el EPUB). Vale igual en el texto, en el panel de notas del HTML (`nota-panel`) y en las notas finales del EPUB (`text-only`): en una nota, la fórmula también es MathML. La copia del MathML pasó a `mathml-comun.xsl`, que incluyen las dos (`formula-comun.xsl` del libro y `formula-jats-comun.xsl`). Cada hoja declara `gbfj:ns-html`: vacío en el HTML (`method="html"`), XHTML en el EPUB; sin ella no compila.

EL OPF. `numero-a-epub.xsl` mira el canónico de cada artículo, como ya hacía con las imágenes, y pone `properties="mathml"` al que tiene fórmulas (sin eso, epubcheck da OPF-014). No hace falta una pasada posterior.

PROBADO EN EL CONTENEDOR (26/11/2026) con un artículo de prueba (`a-01-prueba.md` del lote): fórmulas en línea, un sistema de tres renglones, uno de nueve que cruza la página con un renglón de continuación, tres numeradas (una es un sistema), una fórmula en línea y otra en bloque en las notas, y `$3.5$`. El cuerpo, con la cadena y los argumentos de `generar_canonicos_articulos.sh`. El PDF compila con los preámbulos de la revista y el contrato común 24. El HTML y el EPUB dan 17 `<math>` y los números (1), (2), (3). El EPUB de un número con ese artículo pasa epubcheck sin errores ni advertencias.

**Relaciones:** vinculo:SC-31,vinculo:SC-32,vinculo:SC-64,vinculo:RC-DB-07,vinculo:RC-DB-03,vinculo:GV-227,vinculo:GV-228,vinculo:GV-231,vinculo:SC-40,vinculo:GV-232

**PENDIENTE:** Probar en Mint con el libro Inigo: una numerada, sus remisiones y los avisos.
Probar en Mint con una revista: un número de prueba con a-01-prueba.md (canónicos, PDF, HTML y EPUB), y ver el MathML del HTML en el navegador.
Los sabores JATS (SciELO con packtools, Redalyc, Crossref) con <alternatives> y <label> en <disp-formula>: en su fase.
gbShortcodes: las filas disp-formula y numbered-equation tienen la sintaxis vieja (::: {.formula} y ::: numbered-equation): rehacerlas con [$$…$$]{#eq-…} y sumar el sistema de ecuaciones como plantilla.
RC-DB-03 dice que <equation> exige title, y el RNG de DocBook 5.2 valida un <equation> sin title (GV-229): revisar RC-DB-03.

### SC-111 — Bastardilla en los títulos de la base: el editor escribe *…*, una marca de gbpublisher que cada destino traduce, como el corte de SC-28

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / Saxon-HE 12.9 / LuaLaTeX, TeX Live 2023, IBM Plex Sans Condensed, Libertinus / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

DECISIÓN CERRADA (Alberto, 26/11/2026). Un título o un subtítulo que se carga en el formulario puede llevar una parte en bastardilla: el título de una obra («… a propósito del libro de Fred Moseley *Money and Totality*», capítulo 13 de Inigo), un nombre científico. Antes los asteriscos y `\emph{}` llegaban literales al PDF: `m_XML.TituloXML` escapaba el título como texto, y aunque el canónico hubiera traído la marca, `f:titulo-compuesto` y `f:titulo-plano` lo aplanaban a cadena.

LA MARCA. `*…*`, la del Markdown (decisión de Alberto). No es LaTeX: es vocabulario de gbpublisher, como el `\\` del corte (SC-28), y la regla de SC-25 sigue: nunca LaTeX en la base. `\emph{}` en un campo de título no se interpreta.

ALCANCE. Todo lo que pasa por `m_XML.TituloXML` (decisión de Alberto): título y subtítulo de capítulo, de libro y de artículo, y los títulos traducidos del artículo. Los títulos de parte, de las piezas que arma el PDF (índices, bibliografía) y el abreviado pasan por las funciones de LaTeX de `m_GenerarPDFLibro`, que también la traducen.

UNA SOLA REGLA DE PARTICIÓN. `m_CorteTitulo.Segmentos` parte un tramo en el asterisco: los segmentos pares van en redonda, los impares en bastardilla. Como `Tramos`, no escapa: quien llama escapa cada segmento y envuelve los impares. El orden sigue siendo partir, escapar, unir.

    DocBook   <emphasis>…</emphasis>       m_XML.TituloXML (TramoXML)
    JATS      <italic>…</italic>           m_XML.TituloXML; el volcado la lleva y datos-a-front-jats.xsl la copia (modo titulo)
    LaTeX     \emph{…}                     m_GenerarPDFLibro (TramoTeX); f:titulo-compuesto y f:titulo-plano (tex-comun.xsl)
    plano     sin los asteriscos           m_CorteTitulo.Plano: OPF, JSON de gbWeb, ficha, metadatos del PDF, árbol

`\emph` y no `\textit`: la apertura y el subtítulo que la estética compone en bastardilla dan redonda (el enroque). La versión plana del LaTeX también lleva `\emph`: el sumario y el folio la componen, y hyperref la quita de los marcadores y de `pdftitle` sin avisar (GV-233). Por eso no hace falta una tercera versión del título.

EL HTML Y EL EPUB DEL LIBRO. El encabezado del capítulo (título y subtítulo) y el título del libro en el HTML se recorren por nodos: la `<emphasis>` sale en `<em>`; el `<title>` de la página y el índice siguen planos. El HTML y el EPUB de la revista ya recorrían el `article-title`.

LO QUE NO ES MARCA. Un asterisco sin pareja es texto: `Segmentos` devuelve el último como «*». No se frena al guardar, porque un título real puede llevar uno y un descuido se ve en la salida. La bastardilla no cruza un corte: cada tramo se parte por separado, y un `*…*` partido por `\\` deja dos asteriscos sueltos, que salen como texto. `**` no escribe nada (no hay negrita en los títulos).

PROBADO EN EL CONTENEDOR (26/11/2026):
- Gambas 3.19, las funciones nuevas sobre siete títulos (con corte, con `&` y `<`, con un asterisco suelto, con `**`, con la bastardilla cruzando el corte, vacío): DocBook, JATS, LaTeX compuesto y plano, y plano.
- El capítulo 10 de Inigo con el título del 13 y un subtítulo con una obra, por `docbook-to-latex.xsl` y los cuatro preámbulos reales del libro: la apertura sale en IBM Plex Sans Condensed Italic, el sumario con la cursiva, el subtítulo con el enroque y el marcador plano, sin avisos de fuente ni de hyperref.
- `docbook-to-epub.xsl` y la cabeza del capítulo de `docbook-to-html.xsl` dan `<em>`; `datos-a-front-jats.xsl` copia la `<italic>`.

**Relaciones:** vinculo:SC-28,vinculo:SC-25,vinculo:SC-63,apoya:GV-233

**PENDIENTE:** Probar en Mint: el capítulo 13 de Inigo en PDF, HTML y EPUB; un artículo con *…* en el título (canónico, PDF, HTML, EPUB, SciELO).
Crossref admite <i> en los títulos y hoy recibe el título plano.
El sumario del PDF del número (numero-maestro-latex.xsl) arma el título con f:titulo-tramos: sale sin la cursiva.

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbCorpus 0.0.10 / SQLite / esquema versión 2 · **Verificado:** 2026-10

Base local en `~/.gbcorpus/corpus.sqlite`. Cuatro tablas, sin vistas. Nivel registrado en `esquema_version`, igual que en gbpublisher y gbKumula.

ESTA ENTRADA DESCRIBE LA VERSIÓN 2 DEL ESQUEMA. Si `esquema_version` no dice 2, hay migraciones posteriores y esta descripción quedó vieja. La 2 agregó la tabla `importaciones` (`.hidden/esquema/esquema-v1-a-v2.sql`, 29/10/2026); las otras tres no cambiaron desde la 1.

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

TABLA `importaciones` (DESDE EL ESQUEMA 2)

    id_importacion  INTEGER PRIMARY KEY
    archivo         TEXT NOT NULL CHECK (archivo <> '')
    numero          INTEGER UNIQUE CHECK (numero > 0)
    sha256          TEXT CHECK (64 dígitos hexadecimales en minúscula)
    fecha           TEXT NOT NULL
    origen          TEXT NOT NULL DEFAULT 'importador'
                    CHECK (origen IN ('importador', 'retroactivo'))

Una fila por script aplicado, en orden de llegada. La escribe solo el importador, en la misma sesión de `sqlite3` que aplica el script y después de él: si el script falla, no hay fila. La aplicación la lee y no la toca.

- `archivo`: el nombre del `.sql`, sin carpeta.
- `numero`: el NN de `gbcorpus-act-NN.sql`. NULL para un script fuera de la serie, como una migración; UNIQUE admite varios NULL en SQLite.
- `sha256`: la huella del archivo tal como se aplicó. Detecta el mismo archivo aplicado dos veces, aunque haya cambiado de nombre.
- `fecha`: `datetime('now','localtime')` del momento de la aplicación.
- `origen`: `retroactivo` solo para la siembra de la migración, act-78, que se aplicó antes de que existiera el registro; su fecha es la `fecha_alta` de las entradas que dio de alta. Todo lo demás es `importador`.

Lo que se aplicó antes del esquema 2 no está registrado, salvo act-78. La serie empieza ahí.

CÓMO FUNCIONA LA APLICACIÓN

El alcance, el importador, los scripts y la exportación son los de todas las aplicaciones satélite: SC-50. La cabecera muestra, en `lblInformar`, el último registro de `importaciones` (`m_Base.UltimaImportacion`): «última importación: act-NN · fecha». Si el último script no es de la serie, agrega en qué act va la serie. Antes de pedir un cambio al corpus, ese número tiene que ser el más alto de la carpeta de gbCorpus. El volcado SQL incluye el registro.

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
- marca: solo en línea. Inserta la apertura y el cierre juntos, sin contenido ni selección, en lugar de los espacios que rodean al cursor, después de los controles propios del shortcode (SC-63: el corte de un título, apertura `\\` y cierre un espacio). Se agrega con `datos-v5-023`. El cierre de una marca queda al final de su línea de `_catalogo.tsv`: un editor que recorta los blancos finales lo borraría, y gbpublisher rechaza una fila de modo marca sin cierre.

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

**Relaciones:** vinculo:RF-08,vinculo:SC-50,vinculo:SC-24,vinculo:SC-11,vinculo:SC-32,vinculo:GV-74,vinculo:GV-64,vinculo:SC-33,vinculo:SC-35,vinculo:SC-36,vinculo:SC-42,vinculo:SC-38,vinculo:SC-39,vinculo:SC-63

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

### RF-15 — DirView y FileView de gb.form 3.22.1: raíz por omisión, TreeView interno, navegación, eventos y vigilancia del disco

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22.1 / código fuente de gb.form y gb.gui.base · **Verificado:** 2026-11

Leído en el fuente, etiqueta 3.22.1: `comp/src/gb.form/.src/File/DirView.class` y `FileView.class`, `comp/src/gb.gui.base/.src/TreeView/_TreeView.class` e `IconView/IconView.class`. Informa, no manda.

DirView

- Con `Root` vacío, `GetRoot` devuelve `User.Home`: el árbol arranca en la carpeta personal. `Root_Write` recorta la barra final.
- Por dentro es un `UserControl` con un `TreeView` hijo (`DirView._new`). No tiene `ScrollBar` propia: se llega al `TreeView` por `Children` (UserControl hereda de Container), buscándolo por tipo. En el `TreeView`, `ScrollBar = Scroll.Vertical` saca la barra horizontal y prende `AutoResize` (`_TreeView.ScrollBar_Write`): la columna se ajusta al ancho visible. Si una versión cambia el armado interno, se pierde solo eso.
- Muestra los enlaces simbólicos a carpetas con el emblema de enlace y deja entrar.
- Asignar `Current` dispara `Click` si la ruta cambió (`Current_Write`). `Reload` reconstruye el árbol y conserva la carpeta actual.

FileView

- No navega solo: el doble clic o Enter dispara `Activate`, también sobre una carpeta (`ShowDirectory`). El que lo usa decide.
- `Current` es el nombre seleccionado, o vacío si no hay selección; `Path` es `Dir &/ Current`.
- Dispara `Select` al cambiar la selección, también con el teclado, y `Refresh` al terminar cada recarga.
- Vigila el disco solo si está cargado `gb.inotify` (`Component.IsLoaded`): sin él, lo que cambia afuera aparece recién con `Reload`.
- `FileCount`, `DirCount` y `TotalSize` describen la carpeta mostrada; se calculan al recargar, que es asíncrono: justo después de cambiar `Dir` pueden ser los anteriores.
- Trae renombrado en línea (`Rename()`) con un evento `Rename` que se cancela devolviendo True.

IconView (la vista normal de FileView)

- `MouseDown` no filtra por botón: el derecho también selecciona el ícono, antes de mostrar el `PopupMenu`. Sobre el área vacía, en modo `Single`, la selección anterior se conserva.

**Relaciones:** vinculo:SC-103

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

**Relaciones:** apoya:RC-GM-17,vinculo:GV-219

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

TAMPOCO ENTRE PARÉNTESIS, AUNQUE ESTÉN DENTRO DE UN If (medido con gbc3 3.19, 04/11/2026):

    If (Left(s, 8) <> "https://" And If Left(s, 7) <> "http://") Or If InStr(s, " ") > 0 Then
                                 ^ error: Missing ')'

`And If` y `Or If` son parte de la sintaxis del `If`, no operadores de una expresión. Una condición compuesta se arma antes en una variable Boolean (`m_VentaLibro.Validar`).

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

CASO (21/11/2026, SC-105). `FAnalizarDOI` abría las URL de su grilla con `Shell "xdg-open '" & sValor & "'"`, y `sValor` no lo escribía el usuario: venía de las respuestas de Crossref y OpenAIRE. Una comilla simple en un dato remoto cerraba la cita y lo que seguía lo ejecutaba `sh`. Además de lo que se tipea, lo que llega de un servicio externo nunca se arma en una línea de `Shell`. Ahora la apertura es `Desktop.Open` (GV-43), y las consultas van por un script con los valores como argumentos.

**Relaciones:** vinculo:SC-105

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

**Relaciones:** vinculo:SC-105

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

### GV-25 — Saxon 12 resuelve la DTD por red: las propiedades de JAXP no lo impiden; un catálogo (-catalog) o la copia sin DOCTYPE, sí

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Un XML de 70 KB con DOCTYPE de JATS tarda OCHO SEGUNDOS en parsear con Saxon. El desglose ubica la causa sin ambigüedad:

    arranque de la JVM sin hacer nada            0,24 s
    ese XML con una plantilla que no hace nada  12,87 s
    una regla real sobre un XML mínimo           0,57 s
    el mismo comando sin red (unshare -rn)       0,42 s, y falla

No es la JVM ni son las reglas: es PARSEAR ESE XML. `strace` confirma dos conexiones salientes. Saxon va a buscar la DTD a `jats.nlm.nih.gov` en cada archivo.

Ninguna opción lo evita. Se probaron `-Djavax.xml.accessExternalDTD`, `-Djavax.xml.accessExternalSchema`, `-dtd:off`, `-Dxml.catalog.ignoreMissing` y `-Dxmlresolver.properties`: el tiempo no cambió en ningún caso. El resolvedor de Saxon 12 ignora las propiedades estándar de JAXP.

SOLUCIÓN: cuando la DTD no hace falta para la transformación, entregarle a Saxon una copia SIN DOCTYPE. Verificado: 0,43 s en lugar de 8,1 s, con resultados idénticos.

MATIZ (7/11/2026, SaxonJ-HE 12.5): la opción `-catalog:archivo` de Saxon SÍ resuelve la DTD sin red, con el catálogo de NISO: 1,9 s contra 16 s, y sin red ni catálogo falla. No se había probado. La copia sin DOCTYPE (`xmllint --nonet --dropdtd`) sigue siendo más rápida (0,6 s) y es la que usan los scripts de revistas (SC-87, SC-89).

Al recortar el DOCTYPE hay que CONTAR CORCHETES: el de JATS trae declaraciones de entidades entre `[` y `]`, que contienen sus propios `>`. Cortar en el primero rompe el documento; un `sed` ingenuo dejó el prefijo `ali` sin enlazar.

Esto es la contracara de RC-XJ-03, y las dos reglas deben leerse juntas: allí el problema era que Saxon no conseguía la DTD y la solución fue permitirle buscarla; acá la busca cuando no hace falta.

Vale para todo el proyecto: cualquier cadena XSLT que reciba un JATS con DOCTYPE remoto está pagando esos ocho segundos por archivo.

**Relaciones:** vinculo:SC-87,vinculo:SC-89

### GV-26 — Los Schematron de JATS4R no se ejecutan tal como se distribuyen

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SchXslt 1.10.1 / SaxonJ-HE 12.9 / Java 21 · **Verificado:** 2026-08

Cuatro problemas distintos, todos verificados:

El `.xsl` publicado en el repositorio está MAL COMPILADO. Un `<xsl:function>` quedó sin `@name`, con lo que tres de las cuatro funciones `j4r:` no se declaran y Saxon aborta con `XPST0017`.

`compile-for-svrl.xsl` de SchXslt 1.10.1 copia SOLO LA PRIMERA `<xsl:function>` del `<schema>` y descarta las demás. De las cuatro de `jats4r.sch` sobrevive una.

Los archivos temáticos NO son documentos Schematron completos. Empiezan en `<pattern>` y están pensados para entrar por `<include>`. Sueltos dan "this document contains more than one top-level element". Necesitan un envoltorio con las declaraciones de namespace del maestro.

Y hay reglas que abortan con estructuras normales. Una regla sobre `<sec>` llama a `normalize-space()` sobre un conjunto de títulos y falla con `XPTY0004` en cuanto un artículo tiene subsecciones. En el corpus de referencia, doce secciones de un solo artículo tenían más de un título. Como Saxon aborta, se pierde el análisis del ARCHIVO ENTERO, no solo esa regla.

COMBINACIÓN QUE FUNCIONA: `include.xsl` de SchXslt para resolver los includes, esqueleto ISO `iso_svrl_for_xslt2.xsl` para compilar. Cada implementación aporta lo que la otra rompe.

ACTUALIZACIÓN (18/11/2026): SchXslt ya no hace falta. Un envoltorio derivado del maestro y los tres pasos del esqueleto ISO compilan cada temático, con hallazgos idénticos a los del maestro (GV-211).

REGLA: compilar y ejecutar temático por temático, nunca el maestro completo, y verificar cada grupo contra un corpus real antes de darlo por bueno. Que una regla compile no garantiza que ejecute.

ALCANCE (7/11/2026): la regla vale para el auditor de XML ajenos. Para los canónicos de gbpublisher se compila el maestro (`generar-schematron-jats4r.sh`, SC-87): el aborto XPTY0004 de la regla de `sec` (dos `title`) no puede darse en un canónico que la DTD ya controla, y las cinco instancias de prueba confirman cada compilación.

**Relaciones:** vinculo:GV-28,vinculo:SC-87

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

DESDE LA 2.0.0 (SC-102) `FRelacionarBib` ya no usa `Edit` + `Update` sobre `bibtex`: el campo que no se usa no tiene par en `bibtex_campo`. El comportamiento medido sigue valiendo para gb.db.

**Relaciones:** vinculo:RC-GM-15,vinculo:SC-102

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

Aplicado también en `m_FileManager.Abrir` (21/11/2026, SC-103): `Exist` antes, sin `Wait`, para abrir con la aplicación del sistema lo que el gestor de archivos no reserva al editor.

Aplicado también en `FAnalizarDOI.gvAnalizarDOI_Click` y en `FAvisoLegal.HtmlViewLegales_Link` (22/11/2026, SC-105): reemplazó a `Shell "xdg-open '…'"` y a `Exec ["xdg-open", …]`. Desktop.Open queda como el único camino para abrir con el sistema.

**Relaciones:** vinculo:GV-17, apoya:GV-23, vinculo:GV-06,vinculo:SC-103,vinculo:SC-105

**PENDIENTE:** Falta medir si xdg-open en Cinnamon vuelve de inmediato (delegando en gio open) o espera a que se cierre el visor. Mini-test: en una terminal, xdg-open archivo.pdf; echo $? — si el echo aparece recién al cerrar el visor, Wait = True queda descartado definitivamente. Hasta medirlo, no usar Wait = True.

### GV-44 — TextEdit.Pos: escribirlo manda el cursor al final

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint; código fuente de CTextEdit.cpp (rama principal) / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

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

MEDIDO (19/11/2026, banco gbBancoForm322, en 3.19 con gb.qt5 y en 3.22.2 con gb.qt6). La caché se fija la primera vez que se ESCRIBE `Pos`: con «abc», leer `Pos` y escribir `Pos = 1`, cargar 1.000 caracteres y escribir `Pos = 500` deja el cursor en 1.000. Si antes solo se leyó `Pos`, `Pos = 500` funciona. `Select(500, 0)` deja 500. `ToIndex(500)` devuelve 1.000, el final: pasa por la misma caché, como se leyó en el fuente. `ToParagraph(500)` dio 0 en un documento de un solo párrafo, que no distingue nada. La REGLA no cambia.

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-45, apoya:GV-23

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

ALCANCE: X11. En Wayland no está verificado. Lo único leído en el fuente de Muffin, no medido: los hints Motif solo se aplican a ventanas de clientes X11, y una ventana Wayland nativa se decora del lado del cliente. El resultado dependería de si la aplicación corre por XWayland o como cliente Wayland nativo, y gb.desktop.x11 necesita un display X. Mientras el proyecto apunte exclusivamente a X11 no afecta; si eso cambia, esta entrada deja de valer hasta medirla.

**Relaciones:** vinculo:SC-20, vinculo:GV-11

**PENDIENTE:** Verificar en Mint si Alt+F4 sigue cerrando una ventana sin botones.

### GV-51 — TreeView: el click del mouse dispara Select y Click; asignar Key, solo Select

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.gui.base / Linux Mint y Gambas 3.19 / contenedor Ubuntu noble; código fuente de _TreeView.class (etiqueta 3.22.1) / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

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

CONFIRMADO CON gb.qt6 (19/11/2026, banco gbBancoForm322, Mint): asignar Key da Select 1 y Click 0; sobre el hijo de un padre plegado, Key se lee vacío; con `EnsureVisible` antes, se lee el hijo.

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, ComboBox.class (etiqueta 3.22.1); uso en Gambas 3.22.1 / Linux Mint / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

En `gb.qt5` el `ComboBox` es el de `gb.gui.base`, escrito en Gambas: el componente no trae uno propio en C++. `Index_Write` termina en `Raise Click` sin comparar con el valor anterior, así que asignar el índice que ya está elegido también dispara `Click`.

Es el efecto colateral que SC-06 neutraliza con `bAbriendoProyecto`, pero la bandera solo suprime el aviso de cambios sin guardar. Si el handler carga el archivo, reasignar el mismo `Index` lo recarga, y en un `TextEdit` eso reasigna `RichText` y vacía el historial de deshacer (GV-46).

REGLA: antes de asignar `Index` desde el código, compararlo con el actual. Si es el mismo, no se asigna.

CASO EN EL PROYECTO: el temporizador de archivos llama a `CargarListaArticulosMD(True)`, que vacía el combobox y repone la selección asignando `Index`. Eso recargaba el archivo abierto: preguntaba por cambios sin guardar y vaciaba el deshacer. Como ahí la asignación no se puede evitar, `cmbArticulosRevista_Click` sale sin hacer nada si la ruta elegida es la del archivo ya abierto, antes del aviso de SC-06.

MÁS CASOS: los refrescos en caliente de `cmbVerPDF` y `cmbImagenes` (SC-27) reponen el `Index` con una bandera que el handler consulta. Lo que hacen `Clear` y `Add` al volver a llenar un combo de solo lectura está en GV-69.

MEDIDO AISLADO (19/11/2026, banco gbBancoForm322, en 3.19 con gb.qt5 y en 3.22.2 con gb.qt6): asignar Index de 0 a 1 da un Click, y volver a asignar 1 da otro.

**Relaciones:** vinculo:SC-06, vinculo:GV-46, vinculo:SC-18, vinculo:SC-27, vinculo:GV-69

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / Linux Mint / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Caso de la sesión que implementó los snippets (SC-21). `m_Snippets.Expandir` usaba `m_Constantes.SNIPPET_MARCADOR` antes de que la constante existiera en `m_Constantes`. Limpiar y Compilar no dio ningún error; la aplicación arrancó y el formulario de snippets funcionó.

La falla en ejecución no se llegó a observar: la constante se agregó antes de que esa línea corriera.

POR QUÉ IMPORTA

Que el proyecto compile no prueba que existan los miembros que un módulo usa de otro. El error aparece recién cuando la línea se ejecuta, que puede ser mucho después y lejos de donde está la causa. Es la misma familia que GV-32 y GV-23.

REGLA

Un parche que agrega una referencia a un miembro de otro módulo —constante, variable, función— entra en el MISMO lote que el alta de ese miembro, y el lote se aplica entero antes de recompilar. Ante la duda, buscar el nombre en `.src` antes de dar el parche por aplicado: no alcanza con que compile.

EL MENSAJE EN EJECUCIÓN (19/11/2026, banco gbBanco322, en 3.19 y en 3.22.2): `Unknown symbol 'NoExiste' in class 'M2'`, código 11. Se provocó con un módulo `M2` sin ese miembro, dentro de un `Try`.

**Relaciones:** vinculo:GV-32, apoya:GV-23, vinculo:SC-03, vinculo:SC-21

### GV-57 — Visibilidad de los controles de un formulario: la decide la opción ControlPublic del proyecto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor Ubuntu noble (gbc3 con y sin -f public-control); gbpublisher en Gambas 3.22.1 / Linux Mint · **Verificado:** 2026-09

Por omisión, los controles de un `.form` son privados salvo que lleven `#Public = True` (en el archivo, además, un `!` delante del nombre). Usarlos desde otro módulo compila y falla recién al ejecutar la línea:

    Unknown symbol 'privado' in class 'Container' (#11)

Medido en banco en tres situaciones, las tres con el mismo error: formulario sin mostrar (instancia automática), formulario mostrado, y dentro de `With Formulario`.

LA OPCIÓN DEL PROYECTO LO CAMBIA TODO

`ControlPublic=1` en el `.project` hace públicos TODOS los controles de todos los formularios, lleven o no `#Public`. El compilador la recibe como `-f public-control`. Medido en banco: con esa opción, las tres situaciones anteriores funcionan.

gbpublisher tiene `ControlPublic=1` (y también `ModulePublic=1`). Por eso `FMetadatosRevista.numero_especial` (formulario del camino viejo de revistas, retirado el 18/11/2026: SC-98), que no tenía `#Public`, abría y guardaba bien desde `m_Metadatos` en 3.22.1 (verificado por Alberto). En este proyecto, el `#Public` de cada control no decide nada.

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

DESDE LA 2.0.0 (SC-102). La grilla de la bibliografía tiene 8 columnas fijas (`m_Bibtex.COLUMNAS_GRILLA`, constantes `COL_*`) y `ConsultaGrilla` devuelve esas 8: la cantidad ya no depende del esquema de `bibtex`. El caso de arriba queda como antecedente.

**Relaciones:** vinculo:GV-15,vinculo:SC-22,vinculo:SC-102

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.1 / gb.qt5.ext / Linux Mint / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

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

CONFIRMADO CON gb.qt6 (19/11/2026, banco gbBancoForm322, Mint): `Select(0, 1)` sobre «¿hola» da Start 0, Length 1 y «¿»; la selección de espacio, raya y espacio devuelve « — ».

**Relaciones:** vinculo:RC-GM-21, vinculo:GV-03, vinculo:GV-44, vinculo:SC-18

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 / MySQL 8.0.46, respaldo posterior a la 1.32.0 (20/11/2026) · **Verificado:** 2026-11

Restaurar un respaldo con el comando directo falla en la tabla `articulos`:

    sudo mysql gbpublisher < respaldo.sql
    ERROR 1118 (42000) at line 194: Row size too large (> 8126).

Y falla DESPUÉS de haberla borrado: el volcado trae un `DROP TABLE IF EXISTS` antes de cada `CREATE TABLE`, y el cliente se detiene en el primer error. La base queda sin `articulos`, con las tablas anteriores en orden alfabético ya restauradas y las siguientes sin tocar: una mezcla de dos momentos, peor que antes de intentarlo. Verificado: después del intento, `articulos` no existía.

CAUSA

Con `innodb_strict_mode` activo —el valor por omisión en MySQL 8—, InnoDB rechaza un `CREATE TABLE` cuyo peor caso teórico de tamaño de fila supera el límite, aunque ninguna fila real lo alcance. `articulos` tenía 220 columnas. La 1.32.0 la borró (SC-98), pero todo respaldo anterior a la 1.32.0 la trae; un respaldo posterior se restaura con el comando directo (medido, ver abajo); para uno anterior la regla de SC-22 sigue. El baseline desactiva el chequeo en su cabecera (`SET SESSION innodb_strict_mode=0`); `mysqldump` no escribe esa línea.

RESTAURACIÓN CORRECTA

    sudo mysql --init-command="SET SESSION innodb_strict_mode=0" gbpublisher < respaldo.sql

Verificado: restaura la base completa, `esquema_version` incluida.

ALCANCE

Los mensajes «Para volver atrás» de `actualizar-esquema-1.1.0.sh` a `1.3.0.sh` dan el comando directo. Los respaldos que dejaron en `~/gbpublisher-respaldos` están bien; lo que cambia es cómo se restauran. `actualizar-esquema-1.4.0.sh` ya trae el comando correcto.

MENSAJES CORREGIDOS (18/11/2026): `actualizar-esquema-1.1.0.sh`, `1.2.0.sh` y `1.3.0.sh` muestran el comando con `--init-command="SET SESSION innodb_strict_mode=0"`, como los demás.

MEDIDO (20/11/2026, MySQL 8.0.46, `innodb_strict_mode` = 1). El respaldo diario de la aplicación `gbpublisher_261120.sql`, posterior a la 1.32.0, se restauró varias veces con `sudo mysql gbpublisher < respaldo.sql`, sin error. También se restauró así un volcado de la base ya migrada a la 2.0.0, cuya tabla más ancha es `libros_md` (89 columnas). El baseline 2.0.0 ya no relaja el chequeo, y `generar-baseline.sh` controla que no lo haga (SC-102). El pendiente de MariaDB no aplica: el proyecto usa solo MySQL.

**Relaciones:** vinculo:SC-22,vinculo:SC-102

### GV-68 — Asignar "" a una clave de Collection no la crea, y si existía la borra

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbs3 / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

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

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): los cuatro casos, incluido el `String[]` vacío que sí crea la clave.

**Relaciones:** vinculo:SC-25,vinculo:GV-24

### GV-69 — ComboBox de solo lectura: Clear y Add mueven el índice sin disparar Click

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, ComboBox.class (etiqueta 3.22.1 y rama principal 41d9348) / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

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

MEDIDO (19/11/2026, banco gbBancoForm322, en 3.19 con gb.qt5 y en 3.22.2 con gb.qt6): los seis casos de la tabla, tal como se leyeron en el fuente. `Add("z", 0)` deja Index en 0, que ahora es «z».

**Relaciones:** vinculo:GV-53, vinculo:GV-59, vinculo:SC-27

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.highlight / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

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

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint). El error aparece al crear el resaltador (`TextHighlighter[clave]`), no al registrar la gramática. En 3.22.2 el mensaje nombra otra línea del componente: «[gb.highlight].TextHighlighter.CreateCustomHighlighter.681: [gb.highlight].CCommandMatch.SetArgs.12: Syntax error at line 2». Con `\x20`, carga.

**Relaciones:** vinculo:SC-34,vinculo:SC-33

### GV-77 — File.Load y <> comparan bien un archivo binario, con bytes nulos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbx3 / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

`File.Load` devuelve el archivo entero aunque tenga bytes nulos, y `<>` compara las cadenas por su largo y su contenido, no hasta el primer nulo:

    b1 = "ab\0cd"   b2 = "ab\0ce"   b3 = copia de b1
    Len(File.Load(b1))                       ->  5
    File.Load(b1) <> File.Load(b2)           ->  True
    File.Load(b1) <> File.Load(b3)           ->  False

CONSECUENCIA

El cotejo de recursos de SC-11 servía también para un binario, como era el `.ott` del ODT (retirado: SC-96), sin sumas de verificación. El cotejo se retiró con la copia local el 25/11/2026 (SC-11); el comportamiento sigue medido y vale para cualquier comparación de archivos.

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): los tres casos.

**Relaciones:** vinculo:SC-11

### GV-78 — GridView: asignar Row emite Change y Select, nunca Click

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Código fuente de gb.gui.base, GridView.class (etiqueta 3.22.1); uso en Gambas 3.22.1 / Linux Mint / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

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

MEDIDO AISLADO (19/11/2026, banco gbBancoForm322, en 3.19 con gb.qt5 y en 3.22.2 con gb.qt6): `Row = 1` da Change 1, Select 1 y Click 0; repetirlo no emite nada; `Row = 10` con tres filas se ignora sin error.

**Relaciones:** vinculo:GV-51,vinculo:GV-53,vinculo:GV-15,vinculo:GV-58,vinculo:GV-69,vinculo:SC-51

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

CONSECUENCIA: en el `.deb`, `Depends: perl`, SIN versión. Los paquetes de los módulos llevan la versión de Perl en el nombre y cambian de una versión de Mint a otra; `perl` es el nombre estable que trae los que correspondan. No se controla el comando `perl`: el binario lo trae también `perl-base` y un control así daría verde sin servir. Lo garantiza la dependencia del `.deb` (SC-95).

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gbs3 / contenedor Ubuntu 24.04 / locales C.UTF-8 y es_AR.UTF-8 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

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

LOS ENTEROS ESCRITOS POR EL USUARIO (18/11/2026). Ningún campo numérico se lee con `Val`. `m_FuncionesGenericas` tiene tres funciones:

- `EsEnteroOVacio`: vacío, o solo dígitos y hasta nueve;
- `EnteroDeTexto`: `Null` si está vacío, el `Integer` si no (`CInt` sobre solo dígitos no depende del locale);
- `ControlarEnteros`: antes de guardar, un solo aviso que nombra todos los campos inválidos, y no se guarda nada.

Las usan `FAutores` (alta y modificación: índice h, i10, publicaciones, citas, director actual, calificación), `m_Metadatos` (capítulo: páginas, figuras, tablas, ecuaciones, año del copyright; libro: edición, páginas, año de publicación, embargo, que antes iban como texto y MySQL los rechazaba con un error de tipo) y `FSysAdmin` (años de colección y de serie).

MEDIDO en 3.19 (gbx3): «1.234», «12,5», «1 234», «-3», un NBSP delante y diez dígitos son inválidos; «», «0», « 42 » y nueve dígitos son válidos. `CInt("1.234")` da «Type mismatch» en vez de adivinar.

CONFIRMADO EN 3.22.2 CON es_AR.UTF-8 (19/11/2026, banco gbBanco322, Mint): `Val("15.5")` Null, `Val("15,5")` 15.5, `Val("1.234")` 1234, `Str(15.5)` «15,5», `CStr(15.5)` «15.5», `CFloat("15.5")` 15.5, `CFloat("15,5")` error, y `CInt("1.234")` error (la base de `EnteroDeTexto`).

**Relaciones:** vinculo:GV-03,vinculo:RC-GM-02

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

**Relaciones:** vinculo:GV-68,vinculo:RC-GM-17,vinculo:SC-51,vinculo:SC-105

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 (gbs3) / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

En un patrón de `Like`, la clase de caracteres negada se escribe con circunflejo: `[^a-z]`. La forma con signo de exclamación, `[!a-z]`, que es la del glob de bash y la de Visual Basic, NO niega: Gambas la lee como una clase que contiene el propio `!` y el rango.

MEDIDO con `gbs3`:

    "abc"  Like "*[!a-z]*"    True     (cualquier letra entra en la clase)
    "abc"  Like "*[^a-z]*"    False
    "a/b"  Like "*[^a-z]*"    True

El error no da aviso: el patrón compila y responde, con el resultado contrario al esperado. Un control de forma escrito con `[!…]` deja pasar todo. Así pasaba en el primer borrador de `m_GenerarSalidasLibro.EstiloLibroExiste`, que tiene que rechazar un identificador con `/` o `..` antes de armar una ruta: con `[!a-z0-9-]` aceptaba `a/b` y `../x`.

REGLA: en `Like`, la negación va con `[^…]`. Si la línea existe por esta entrada, citarla.

Es otra de las diferencias con Visual Basic que rompen código (CONTEXTO, punto 4).

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): los tres casos.

**Relaciones:** vinculo:SC-57,apoya:GV-23

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

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / contenedor (arnés de m_Notas) / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

Una grilla se vació con `Rows.Count = 0` y se volvió a llenar. Las celdas a las que no se les asignó `Background` en la carga nueva mostraron el fondo de la carga anterior: una nota cerrada heredaba el verde del índice de días.

REGLA: una carga que pinta celdas asigna el fondo en TODAS las celdas de la columna, también `Color.Default` en las que no llevan color. Aplicado en `m_Notas.CargarLista` y en `FSysAdmin.CargarNotasAdmin`.

MEDIDO (19/11/2026, banco gbBancoForm322, en 3.19 con gb.qt5 y en 3.22.2 con gb.qt6). Al volver `Rows.Count` a 0 y llenarla otra vez, la celda conserva `Background`, y también `Foreground` y `Alignment`. `Clear()` sí borra el formato: después de `Clear`, el fondo ya no es el de antes. La REGLA sigue: una carga que pinta asigna el formato en todas las celdas, o vacía con `Clear`.

**Relaciones:** vinculo:GV-58,vinculo:SC-60

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

### GV-134 — Chart.js 4.4.1: lo que dibuja con cada forma de los datos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chart.js 4.4.1 (.hidden/chart/chart.min.js) / Chromium 153 headless (Playwright) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con el `chart.min.js` del proyecto en Chromium headless, ventana de 844×560, con la configuración que armaba `FFiguras.btnDibujar`:

    torta o dona, backgroundColor como cadena   todas las porciones del mismo color: hace falta un
                                                arreglo, un color por porción
    responsive: true, sin aspectRatio           el canvas toma el ancho del contenedor y la proporción
                                                por omisión del tipo: 820×500 en barras, 820×820 en
                                                torta; la torta sale cortada en 844×560
    scatter con valores sueltos y labels        la x de cada punto es null: no dibuja ningún punto;
                                                hacen falta pares {x, y}
    un valor que no es número en data («s/d»)   el script se corta (ReferenceError): no hay gráfico
    doughnut con dos datasets                   dos anillos concéntricos, el primero afuera; la
                                                leyenda nombra las porciones, no los anillos
    options.locale: 'es-AR'                     marcas «1.000», «1.200»; tooltip «S: 1.234,5»

EN EL PROYECTO: los cuatro primeros eran errores de FFiguras. En SC-69 la configuración la arma `m_Graficos` desde el archivo: un color por porción, la proporción del archivo, pares {x, y} en dispersión, `null` en la celda vacía, y las celdas se controlan antes de generar.

**Relaciones:** apoya:SC-69

### GV-135 — Canvas: la fuente embebida tiene que estar cargada antes de dibujar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chromium 153 headless (Playwright) / Chart.js 4.4.1 / fonttools 4.66.1 / Noto Serif 2.015 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido en Chromium headless con Chart.js 4.4.1 y Noto Serif en un `@font-face` con data URI (woff2), bajo un nombre de familia propio para no confundirla con una instalada:

    dibujar sin esperar                 la imagen es idéntica a la de la letra de respaldo,
                                        aunque después document.fonts.check dé true
    esperar document.fonts.load(…)      sale en Noto Serif, con tildes y ñ
    y dibujar en el then

El canvas no se vuelve a pintar cuando la fuente llega: lo dibujado queda. `@font-face` carga la fuente recién cuando algo la pide, y un data URI no cambia eso.

EL SUBCONJUNTO. Noto Serif 2.015 (`.hidden/fonts`) es OFL 1.1 y su aviso no declara Reserved Font Name: se puede reducir y distribuir con el mismo nombre. Con `pyftsubset` (fonttools):

    pyftsubset NotoSerif-Regular.ttf \
      --unicodes="U+0020-007E,U+00A0-00FF,U+0152-0153,U+2010-2015,U+2018-201E,U+2022,U+2026,U+202F,U+2030,U+2032-2033,U+2039-203A,U+2070,U+2074-2079,U+207B,U+20AC,U+2212" \
      --layout-features='kern,liga,tnum,lnum,pnum' --flavor=woff2 --output-file=…

Regular, 12,0 KB; Bold, 12,8 KB. Las TTF enteras pesan unos 500 KB cada una. El espacio fino U+202F y los volados (⁰ ⁴–⁹ ⁻) los piden las cifras de SC-64: la primera versión del rango los dejaba afuera, y la TTF entera los tiene.

EN EL PROYECTO: el HTML del gráfico embebe los dos subconjuntos y dibuja después de `document.fonts.load` (SC-69).

**Relaciones:** apoya:SC-69

### GV-136 — Saxon-HE 12.5: unparsed-text-available con una ruta absoluta pasada por parámetro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Saxon-HE 12.5 / OpenJDK / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con la ruta de la carpeta `media` como parámetro de la línea de órdenes y el nombre del archivo armado en la hoja:

    iri-to-uri, ruta con espacio y ñ            true si el archivo existe, false si no
    iri-to-uri, ruta con # o ?                  false aunque exista: iri-to-uri no escapa # ni ?
    encode-for-uri por segmento                 true y false correctos con espacio, ñ, # y ?
    el HTML de un gráfico (200 KB, Chart.js)    true: el contenido se lee como texto UTF-8 válido
    locale POSIX (LANG vacío)                   la ñ del parámetro llega rota (a%EF%BF%BD%EF%BF%BDo)
                                                y la función da false; -Dfile.encoding y
                                                -Dsun.jnu.encoding no lo corrigen
    locale UTF-8                                la ñ llega bien

La forma que funciona:

    concat('file://', string-join(
      for $s in tokenize($ruta, '/') return encode-for-uri($s), '/'))

EN EL PROYECTO: Mint usa es_AR.UTF-8. La hoja del HTML decide así si una figura tiene versión interactiva (SC-69).

**Relaciones:** apoya:SC-69

### GV-137 — JSON.Encode (gb.util.web): qué escapa y qué no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.util.web / contenedor Ubuntu 24.04, C.UTF-8 y es_AR.UTF-8 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Medido con una `Collection` y un `Variant[]`:

    comilla doble, barra invertida      \" y \\
    salto de línea, tabulador           \n y \t
    Null en un Variant[]                null
    Float                               con punto, también con es_AR.UTF-8
    </script> dentro de una cadena      sale igual: NO se escapa
    orden de las claves                 el de inserción en la Collection

Embebido en un `<script>`, un texto con `</script>` cierra el bloque: antes de embeber hay que reemplazar `</` por `<\/`, que sigue siendo JSON válido.

LEER LOS NÚMEROS. Con es_AR.UTF-8, `Val("1234.5")` da Null y `CFloat("1234.5")` da 1234.5 (GV-96): los números del archivo se leen con `CFloat` dentro de `Try`.

EN EL PROYECTO: la configuración del gráfico se escribe con `JSON.Encode` (SC-69).

CONFIRMADO EN 3.22.2 CON es_AR.UTF-8 (19/11/2026, banco gbBanco322, Mint): los escapes, el orden de inserción, `</script>` sin escapar, `null` y el Float con punto.

**Relaciones:** apoya:SC-69,vinculo:GV-96,vinculo:GV-98

### GV-138 — ListBox en Select.Multiple: la selección por código no emite eventos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.qt5 / xvfb / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

Medido con `Mode = Select.Multiple` y cuatro elementos:

    lst[1].Selected = True, lst[3].Selected = True   quedan elegidos 1 y 3; ningún evento
                                                     (Select ni Click)
    leer lst[i].Selected                            devuelve la selección
    lst.Index, lst.Text                             -1 y vacío: elegir por código no mueve
                                                    el elemento actual
    UnselectAll()                                   no queda ninguno; ningún evento
    List = <otra lista>                             los índices que siguen existiendo quedan
                                                    elegidos: la selección no se borra

A diferencia de `Index` (GV-53), reponer la selección de una lista múltiple no dispara los handlers: no hace falta la bandera de llenado para esto.

EN EL PROYECTO: la lista de series de FGraficos (SC-69). `RefrescarSeries` reemplaza la lista, llama a `UnselectAll` y recién después elige: sin eso, al insertar una columna la serie elegida quedaba elegida dos veces, en su lugar viejo y en el nuevo.

CONFIRMADO CON gb.qt6 (19/11/2026, banco gbBancoForm322, Mint): los cinco casos.

**Relaciones:** apoya:SC-69,vinculo:GV-53

### GV-139 — Chromium headless: --force-device-scale-factor multiplica el PNG y Chart.js dibuja a esa escala

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chromium 153 headless (Playwright) / Chart.js 4.4.1 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido:

    --screenshot --window-size=844,560                         PNG de 844×560
    lo mismo con --force-device-scale-factor=3                 PNG de 2532×1680
    devicePixelRatio 3, canvas de 800 px de ancho en CSS       canvas.width = 2400

`--screenshot` espera el dibujo que se hace después de `document.fonts.load` (GV-135): con la plantilla de SC-69, los siete tipos salieron dibujados y en Noto Serif, a 1× y a 3×, sin `--virtual-time-budget`. Con `--hide-scrollbars`, la tabla oculta de la plantilla no agrega barra.

Chart.js toma `window.devicePixelRatio` y dibuja el canvas a esa escala: el PNG no es una ampliación. 844 px a 1× dan unos 7 cm a 300 ppp; a 3×, unos 21 cm.

EN EL PROYECTO: el PNG del gráfico se saca a escala 3 (SC-69).

**Relaciones:** apoya:SC-69

**PENDIENTE:** Confirmar con el chromium de Mint (el paquete que pide la aplicación).

### GV-140 — Base64$ con un archivo binario

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Medido con `File.Load` de un woff2 (12 796 bytes) y `Base64$`:

    Len(File.Load(…))         12 796: la cadena tiene los bytes del archivo
    Base64$(…)                17 064 caracteres, en una sola línea, sin saltos
    comparado con base64 -w0  idéntico (la misma suma md5)

`Base64$` es una función del intérprete: no pide componente.

EN EL PROYECTO: no se usa. El HTML del gráfico lo arma `engine/grafico.sh` (SC-13, SC-69), que codifica las fuentes con `base64 -w0`; en `.hidden/chart/` quedan los woff2 y no una copia en base64.

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): `Base64$` de una cadena con un nulo da «YWIAY2Q=», y una larga sale sin saltos de línea.

**Relaciones:** vinculo:SC-69

### GV-141 — Chromium sin ventana: --dump-dom espera el dibujo; la página va como URL y sin perfil propio

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chromium 153 headless (Playwright) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con la plantilla de SC-69, en un proyecto con espacio, ñ y # en el nombre de la carpeta:

    --dump-dom <url>                   el DOM después de los scripts, incluido el dibujo que
                                       espera a document.fonts.load: <html data-listo="1">; si la
                                       plantilla falla, data-listo="error" y data-motivo
    la ruta tal cual, con # en ella    la página no se encuentra: chromium lee el # como el
                                       comienzo del fragmento
    file:// con %XX por cada byte      funciona con espacio, ñ y #
    --user-data-dir=<carpeta nueva>    --dump-dom no termina: vence el timeout
    sin --user-data-dir                un perfil temporal en /tmp/org.chromium.Chromium.*: no toca
                                       el de quien opera

EN EL PROYECTO: `engine/grafico.sh` controla así que el gráfico se haya dibujado, y arma la URL con perl, un %XX por cada byte que no es letra, cifra ni -._~ (SC-69).

**Relaciones:** apoya:SC-69

**PENDIENTE:** Confirmar con el chromium de Mint.

### GV-142 — WebView (gb.qt5.webview): asignar la misma URL vuelve a leer la página

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.qt5.webview / xvfb / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con un archivo en una carpeta con espacio y # en el nombre, cambiando su contenido entre una asignación y otra:

    URL = <url>, después el archivo cambia, URL = <la misma>   muestra el contenido nuevo
    Reload()                                                  muestra el contenido nuevo
    leer URL                                                  la URL decodificada: espacio y ñ
                                                              legibles, el # sigue como %23

No hace falta `Reload()` ni pasar por about:blank para ver un archivo regenerado. Y la URL que se lee no es la que se asignó: compararlas para decidir si recargar no sirve.

EN EL PROYECTO: FGraficos muestra la vista previa y lo generado asignando la URL (`MostrarEnVista`, SC-69).

**Relaciones:** apoya:SC-69

**PENDIENTE:** Confirmar en Mint con Gambas 3.22.1.

### GV-143 — XSLT: el JavaScript escrito en una hoja se lee como XML

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Saxon-HE 12.5 / jats-to-html.xsl / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El JavaScript de las hojas de HTML va como texto de la hoja, sin CDATA. El parser de XML lo lee antes que nadie:

    // … <img> … en un comentario de JS   la hoja no compila: «The element type "img" must be
                                           terminated by the matching end-tag»
    '<img src="' + x + '" alt=""/>'        compila: el parser lo toma como un elemento img
                                           literal, con atributos que contienen JS, y el método
                                           html lo vuelve a escribir como <img src="' + x + '"
                                           alt="">, que sigue siendo JS válido

La segunda forma funciona de casualidad: depende de que el texto parezca un elemento bien formado. Un comentario o una cadena con una etiqueta suelta rompe la hoja entera.

EN EL PROYECTO: el panel de figuras de `jats-to-html.xsl` (SC-69). Al tocar el JS de una hoja: nada que parezca una etiqueta en los comentarios, y probar que la hoja compile.

**Relaciones:** apoya:SC-69

### GV-144 — CSS: una tabla no se achica a 1 px; agranda la página aunque esté recortada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chromium 153 headless (Playwright) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con la plantilla del gráfico (SC-69), en un iframe de 570 px de alto con el canvas de 570:

    la clase «fuera de la vista» (position:absolute;   el documento mide 637 px: la tabla
    width:1px; height:1px; overflow:hidden; clip)      crece con sus filas e ignora el height
    en la <table>
    la misma clase en un <div> que envuelve la tabla   el documento mide 570 px

`clip` oculta lo que se ve pero no quita la tabla del alto de la página. Con `scrolling="no"` en el iframe no se notaba; en una página que se desplaza, sí.

EN EL PROYECTO: la tabla de datos de la plantilla del gráfico va dentro de un div con la clase (SC-69).

**Relaciones:** apoya:SC-69

### GV-145 — TextBox: Change se dispara al asignar Text por código, pero no si el texto no cambia

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.qt5 / xvfb / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2 con gb.qt6, Linux Mint (banco gbBancoForm322, 19/11/2026) · **Verificado:** 2026-11

Medido con un `TextBox` y un handler que cuenta:

    txt.Text = "hum"          Change: 1 (el handler corre aunque no tipeó nadie)
    txt.Text = ""             Change: 2
    txt.Text = "ano" dos veces  la segunda asignación no dispara Change

CONSECUENCIA: un handler de `Change` que depende de OTRO control (por ejemplo, sugerencias según el vocabulario elegido en un combo) no se vuelve a ejecutar si cambia ese otro control y el texto sigue igual. El otro control tiene que llamar al mismo procedimiento.

EN EL PROYECTO: `FMetadatosArticulo` (SC-74): `txtBuscarControlado_Change`, `cmbVocabulario_Click` y `cmbVocabulario_Change` llaman a `ActualizarCoincidencias`. Las asignaciones por código que no deben buscar van con la bandera `$bCargando`.

CONFIRMADO CON gb.qt6 (19/11/2026, banco gbBancoForm322, Mint): los tres casos.

**Relaciones:** apoya:SC-74,vinculo:GV-53

### GV-146 — ListBox de selección simple: asignar Index no dispara Click

**Estado:** corregida · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.qt5 / xvfb / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

CORREGIDA (19/11/2026). Lo que dice esta entrada es falso: asignar `Index` en una `ListBox` simple SÍ dispara `Select` y `Click`. Lo midió el banco gbBancoForm322 en el mismo entorno de la medición original (3.19, gb.qt5, xvfb) y en Mint (3.22.2, gb.qt6), con el mismo resultado. Lo vigente está en GV-215.

Medido con `ListBox` en su modo por omisión (una sola selección):

    lst.Index = 1     queda elegido el 1; Click NO corre; lst.Text devuelve el elemento

Es la contracara de GV-53: en un `ComboBox`, asignar `Index` dispara `Click` siempre. En una `ListBox` no hace falta la bandera de llenado para reponer la selección; si el código necesita lo que hace el handler, lo llama.

Lo que pasa en `Select.Multiple` está en GV-138.

EN EL PROYECTO: `FMetadatosArticulo` (SC-74): `RedibujarControladas` y `MostrarResumen` reponen el elemento elegido asignando `Index`.

**Relaciones:** contracara:GV-53,vinculo:GV-138,apoya:SC-74,reemplazada_por:GV-215

### GV-147 — If(s = "", Null, s) con s String no da Null: Exec escribe una cadena vacía

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.db / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

`If()` toma el tipo de sus ramas. Con una rama `String`, el `Null` de la otra se convierte en `""`, y `Connection.Exec` recibe una cadena: escribe `''`, no NULL.

Medido: `Exec("INSERT … VALUES (&1)", If(sId = "", Null, sId))` con `sId` vacío escribió `''` y lo rechazó `CHECK (identificador <> '')`.

PATRÓN: una función que devuelve `Variant`:

    Private Function NuloSiVacio(sTexto As String) As Variant
      If Trim(sTexto) = "" Then Return Null
      Return Trim(sTexto)
    End

CON Edit + Update ES INOFENSIVO: asignar `""` a un campo ya escribe NULL (GV-74), así que `!campo = If(…, Null, …)` da el resultado esperado por otro camino.

EN EL PROYECTO: `m_Vocabularios.NuloSiVacio`, `m_Articulo.NuloSiVacio`, `m_Revistas.NuloSiVacio`. Toda columna que la interfaz puede dejar vacía es NULL con `CHECK (<> '')` (GV-74), y con `Exec` el valor tiene que llegar como `Variant` nulo.

**Relaciones:** vinculo:GV-74,vinculo:GV-34,apoya:SC-71

### GV-148 — Los arreglos no tienen Exchange: el intercambio se escribe a mano

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Medido: `aLista.Exchange(i, j)` sobre un `String[]` compila y falla al ejecutar con «Unknown symbol 'Exchange' in class 'String[]'» (el miembro inexistente compila: GV-56).

PATRÓN: intercambio con una variable auxiliar del tipo del elemento. Con arreglos paralelos, el intercambio se hace en todos en el mismo paso.

EN EL PROYECTO: `CContribuyente.Intercambiar`, `CTextosArticulo.MoverControlado`, `FMetadatosArticulo.MoverContribuyente`, `FPlantillasResumen.MoverSeccion`.

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): `Exchange` falla al ejecutar. La instrucción `Swap` entre dos variables sí funciona (medido en 3.19 y en 3.22.2): sirve para dos variables sueltas, no para dos elementos de un arreglo con su índice, que siguen con la variable auxiliar.

**Relaciones:** vinculo:GV-56

### GV-149 — gb.db / MySQL: SELECT ROW_COUNT() en un Exec aparte dio 0 después de un UPDATE

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0, gb.db / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido dentro de una transacción: un `Exec` con `UPDATE … JOIN …` que corrigió una fila, seguido de `Exec("SELECT ROW_COUNT() AS n")` en la misma conexión, devolvió 0.

No se averiguó la causa. No contar las filas afectadas así.

PATRÓN: contar ANTES, con la misma condición y dentro de la misma transacción.

EN EL PROYECTO: `m_Vocabularios.GuardarTermino` cuenta las palabras clave que va a corregir antes del `UPDATE` (SC-74).

**Relaciones:** apoya:SC-74

**PENDIENTE:** Una sola medición; causa sin averiguar.

### GV-150 — LCase solo convierte ASCII; String.LCase convierte todo si el locale es UTF-8

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 / contenedor Ubuntu 24.04 (locale C y C.UTF-8) / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Medido:

    LCase("ÁRBOL Ñandú")           «Árbol Ñandú»: solo las letras ASCII
    String.LCase("ÁRBOL Ñandú")    con LANG=C.UTF-8: «árbol ñandú»
                                   con locale C (sin UTF-8): «Árbol Ñandú»

Es otro caso de RC-GM-12: las funciones sin prefijo son de bytes. Y `String.LCase` depende de que el locale sea UTF-8 (Mint lo es; un contenedor con locale C, no).

EN EL PROYECTO: el control de palabras clave repetidas (`m_Articulo.AvisoPalabras`) y el de términos repetidos al agregar uno controlado comparan con `String.LCase`, la misma regla que la clave única de la base (GV-152).

CONFIRMADO EN 3.22.2 CON es_AR.UTF-8 (19/11/2026, banco gbBanco322, Mint): `LCase` deja «Árbol Ñandú» y `String.LCase` da «árbol ñandú».

**Relaciones:** vinculo:RC-GM-12,vinculo:GV-96,apoya:SC-74

### GV-151 — FSysAdmin funciona sin sesión: nada de lo que llama puede depender de m_ConexionBD.mConn

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / Gambas 3.22.1 / Linux Mint (informado por Alberto, 25/10) · **Verificado:** 2026-10

`FSysAdmin` se abre también sin sesión de usuario, con su propia conexión (`hConnServidor`). En ese caso `m_ConexionBD.mConn` no existe, y cualquier función que la use falla con «Null object».

Medido: la pestaña «Revistas» llamaba a `m_Licencias.LlenarCombo`, que leía de `mConn`: «Null object» al abrir sin sesión.

PATRÓN: toda función que llama `FSysAdmin` recibe la conexión como parámetro. En los módulos compartidos, un parámetro `Optional hConn As Connection` que, si falta, toma `mConn`.

EN EL PROYECTO: `m_Revistas`, `m_Vocabularios`, `FPlantillasResumen` (`hConn` del llamador); `m_Licencias.LlenarCombo`, `CompletarUrl` y `m_Idiomas.ListaValida` con `hConn` opcional.

**Relaciones:** apoya:SC-71,apoya:SC-106

### GV-152 — MySQL 8: utf8mb4_unicode_ci iguala ñ con n y las vocales con y sin tilde

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 (cliente con --default-character-set=utf8mb4) · **Verificado:** 2026-10

Medido con una clave única sobre una columna de texto:

    utf8mb4_unicode_ci    «Año» = «Ano», «Niño» = «Nino», «Métodos» = «Metodos»,
                          «humanos» = «Humanos»
    utf8mb4_0900_as_ci    distingue tildes y ñ; no distingue mayúsculas:
                          «Año» ≠ «Ano», «humanos» = «Humanos», «AÑO» = «Año»
    utf8mb4_0900_ai_ci    como unicode_ci: sirve para BUSCAR sin tildes

Para la clave única de un término en castellano, `unicode_ci` es un error: rechaza «Ano» si ya existe «Año». `0900_as_ci` va en la columna; `COLLATE utf8mb4_0900_ai_ci` va solo en la consulta de búsqueda. Pasar una columna a una colación más estricta (`MODIFY … COLLATE`) no crea repetidos y no choca con un CHECK de la columna.

Las colaciones 0900 son de MySQL 8: MariaDB no las tiene con ese nombre.

EN EL PROYECTO: actualización 1.16.0 (`vocabulario_termino.termino`, `articulo_palabra_clave.termino`; SC-74).

**Relaciones:** apoya:SC-74,vinculo:SC-22

### GV-153 — MySQL 8: un CHECK admite REGEXP_LIKE; con colación _ci hace falta la opción 'c'

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido: `CHECK (REGEXP_LIKE(ror, '^https://ror[.]org/0[a-hj-km-np-tv-z0-9]{6}[0-9]{2}$', 'c'))` se crea y controla. NULL pasa; `''`, la forma sin prefijo, una letra excluida y LAS MAYÚSCULAS se rechazan. Sin `'c'`, la comparación sigue la colación de la columna (`_ci`) y acepta mayúsculas.

En un script bash con el SQL entre comillas dobles, el `$` del patrón va como `\$`.

EN EL PROYECTO: `contribuyente_afiliacion.ror`, actualización 1.15.0 (SC-71).

**Relaciones:** apoya:SC-71,vinculo:GV-111

### GV-154 — ROR: el dígito de control es ISO 7064 Mod 97-10 sobre los siete primeros caracteres en base 32 de Crockford

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** ror.readme.io (identifier, jats, crossref) / Python 3 y Gambas 3.19.0 · **Verificado:** 2026-10

Un ROR ID tiene nueve caracteres: un `0`, seis de base 32 de Crockford (minúsculas y cifras, sin i, l, o, u) y dos dígitos de control. La forma preferida es la URL completa: `https://ror.org/02mhbdp94` (ror.readme.io/docs/identifier; JATS e `institution-id` y Crossref `institution_id` muestran la URL).

La documentación remite al código generador para la cuenta. Verificada con los seis ROR de ejemplo de esa documentación (02mhbdp94, 03134gf68, 024mw5h28, 020hgte69, 05gq02987, 02twcfp32):

    n = valor en base 32 de los 7 primeros ("0123456789abcdefghjkmnpqrstvwxyz")
    control = 98 - (n * 100 mod 97)

En Gambas, `n` es `Long`: 32^7 no cabe en un `Integer`.

EN EL PROYECTO: `m_Articulo.NormalizarRor` (cualquier forma que acepte la API → URL completa en minúsculas) y `m_Articulo.RorValido`. La base controla la forma (GV-153).

**Relaciones:** apoya:SC-71,vinculo:GV-153

### GV-155 — LuaLaTeX: graphicx admite pdf, png y jpg, no svg, gif ni webp

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0 / TeX Live 2023 (Debian) / graphics-def luatex.def / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El controlador de graphicx para LuaTeX (`luatex.def`) admite estas extensiones:

    .pdf,.png,.jpg,.mps,.jpeg,.jbig2,.jb2  (y las mismas en mayúsculas)

MEDIDO: un `\includegraphics[width=\linewidth]` con un png compila; con un svg o un gif, LuaLaTeX frena con «LaTeX Error: Unknown graphics extension: .svg.» (o .gif).

CONSECUENCIA: de los formatos que admite el EPUB 3.3 (jpg, png, gif, svg, webp; GV-66), solo jpg y png salen también en el PDF, y el HTML los muestra todos. Una figura que tiene que salir en las tres salidas va en png o jpg; un pdf sale solo en el PDF. Es la regla de formato de la capa de recursos del validador (SC-75) y la que SC-25 ya fijaba para los logos.

**Relaciones:** apoya:SC-75,vinculo:GV-66,vinculo:SC-25

### GV-156 — ImageMagick 6: la copia reproducible, el perfil de color y el PNG reducido

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** ImageMagick 6.9.12-98 Q16 / perfiles de TeX Live 2023 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con ImageMagick 6.9.12-98 Q16, sobre imágenes reales de Califa y Duek y un CMYK armado con el perfil FOGRA39 de TeX Live.

1. Sin `-strip`, dos corridas idénticas de `convert x.png -resize 2000x2000> y.png` dan archivos distintos: el PNG guarda la fecha en el bloque tIME y en `date:create` / `date:modify`. `-define png:exclude-chunks=date,time` no alcanza. Con `-strip`, las dos corridas dan bytes idénticos, en PNG y en JPG.
2. `-strip` borra también el perfil de color.
3. `-profile sRGB.icc` sobre un CMYK CON perfil embebido lo convierte a sRGB. Sobre un CMYK SIN perfil no hace nada: la imagen sigue en CMYK. Hay que asignarle antes uno de origen: `-profile FOGRA39L_coated.icc -profile sRGB.icc`.
4. Un PNG reducido puede pesar más que el original: al remuestrear aparecen tonos intermedios y comprime peor. La tapa de Califa (1747×2593) pasó de 1,1 MB a 1,8 MB a 2000 px; el gráfico fig-02 (2532×1584), de 50 KB a 82 KB. Ni `-filter Triangle` ni `png:compression-level=9` ni `png:compression-filter=0` lo evitan; `png:compression-filter=5` da advertencia y se ignora. Una foto grande sí baja: la tapa de Duek (1831×2717) pasó de 4,8 MB a 2,9 MB.
5. Un PNG con el perfil sRGB estándar en su bloque iCCP (la tapa de Califa, «sRGB IEC61966-2.1» escrito por Photoshop) aparece sin perfil: `%[profile:icc]` sale vacío y advierte por stderr que la propiedad no existe. Un perfil que no reconoce sí lo expone, con su descripción.
6. `identify -format '%[colorspace]'` devuelve `sRGB`, `CMYK` o `Gray`; es lo que decide la conversión.
7. La tapa web en JPEG (SC-81), sobre la tapa de Duek: `-resize '800x>' -strip -quality 85` da 800×1187 y 229 KB; `-resize '600x>' -strip -quality 80`, 600×890 y 117 KB (en PNG a 800 px, 1,1 MB). Dos corridas separadas por `sleep 2` dan el mismo sha256: no hay fecha guardada, tampoco con segundos de diferencia. En pantalla, Alberto no distingue la de 600 de la de 800 (02/11/2026).

**Relaciones:** apoya:SC-76,apoya:SC-81

### GV-157 — Pandoc: \index[…]{…} en el .md es LaTeX en línea entero; solo lo rompen un % y una llave sin cerrar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con Pandoc 3.1.3 (`-f markdown -t native`).

1. `\index[onomastico]{Borges, Jorge Luis!infancia}` es un RawInline tex entero en un párrafo, dentro de una nota, dentro de una bastardilla y al final de un título. Partida en dos líneas también: el salto queda adentro.
2. En un título, el RawInline no entra en el id que Pandoc deriva del texto.
3. Adentro de las llaves no interpreta `! @ | & # _ ~ $ ^`, `"` ni « »; `\!`, `\&` y `\%` quedan tal cual.
4. Dos cosas rompen la lectura. Un `%` sin barra abre un comentario de LaTeX y una llave sin cerrar deja el grupo abierto: en los dos casos la orden no se reconoce y queda partida en Str (`F\index[concepto]{I+D`, `&`, `50`, `%`, …). Es el comportamiento de GV-124.

**Relaciones:** apoya:SC-77,vinculo:GV-116,vinculo:GV-124

### GV-158 — xindy: el módulo español cargado por ruta con -M no ordena en español; -L spanish-modern -C utf8 sí

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** xindy (paquete de Ubuntu 24.04, TeX Live 2023) / contenedor Ubuntu 24.04 y Linux Mint · **Verificado:** 2026-10

Medido con el xindy de Ubuntu 24.04 (TeX Live 2023) y la invocación de `compilar_latex_comun.sh`: `-M texindy -M page-ranges -M word-order -M /usr/share/xindy/lang/spanish/modern-utf8.xdy -I latex`.

1. Con el módulo por ruta el orden no es el español: «Ávila» va antes que «Absalón» y «Alberdi», y «Ñandú» cae primero, en el grupo A.
2. Con `-L spanish-modern -C utf8` en lugar de `-M …/modern-utf8.xdy`: Absalón, Alberdi, Avellaneda, Ávila; Ñandú en su grupo Ñ, después de la N.
3. `-L spanish -C utf8` no existe: «Cannot locate xindy module for language spanish in codepage utf8».
4. El índice `names` no lo sufre con las tildes: esindex escribe la clave sin ellas (`Avila, Juan@Ávila, Juan`). Lo sufren los índices sin esindex: los que carga el editor.
5. El orden de las páginas dentro de una entrada sigue el de las clases de ubicación, y texindy pone las arábigas antes que las romanas: «Borges, 3, XIII». El módulo `book-order` de xindy (`/usr/share/xindy/base/book-order.xdy`, `define-location-class-order`) pone primero las romanas en minúscula, después las romanas en mayúscula y después las arábigas: «Borges, XIII, 3». Las remisiones siguen al final. Afecta a los tres índices, también al de autores.

Confirmado en Linux Mint (Alberto, 30/10/2026): la Ñ en su grupo y, con `book-order`, los romanos de los preliminares antes que los arábigos.

**Relaciones:** apoya:SC-77

### GV-159 — hyperref: hyperindex rompe los índices de xindy; con hyperindex=false y |hyperpage explícito no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0, TeX Live 2023 / babel-spanish / imakeidx / esindex / biblatex + biber / hyperref / xindy (Ubuntu 24.04) / qpdf / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con LuaLaTeX, imakeidx con la opción `xindy`, babel-spanish y hyperref con `hyperindex` encendido, que es el valor por omisión y el de `preambulo-hyperref.tex`.

1. hyperref reescribe el formato en el .idx. `|(` pasa a `|(hyperpage` y `|)` queda `|)`: xindy no cierra el rango («Found no :close-range matching an already opened one»).
2. Un formato propio pasa a `|hyperindexformat{\gbIndNota}`: xindy lo trata como otro atributo y la página sale vacía (`\hyperindexformat{\gbIndNota}{}`).
3. `|see{…}` y `|seealso{…}` pasan a `|hyperindexformat{\see{…}}` y se mezclan con el formato de otra página de la misma entrada: «educación superior» perdió su página 2.
4. Con `hyperindex=false` y el formato escrito explícito (`|hyperpage`, `|(hyperpage` y `|)hyperpage`, `|see{…}`) los tres casos salen bien, con enlace.
5. esindex acepta `|formato`. Con el formato de nombre de biblatex llamando a una orden que hace `\esindex[names]{#1|hyperpage}`, el índice de autores conserva los enlaces con `hyperindex=false`: seis anotaciones Link a `page.N`, contadas con qpdf, una por página de cada autor.

**Relaciones:** apoya:SC-77

### GV-160 — xindy: un formato no declarado descarta la página; un formato por número de nota no ordena

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0, TeX Live 2023 / babel-spanish / imakeidx / esindex / biblatex + biber / hyperref / xindy (Ubuntu 24.04) / qpdf / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Medido con xindy (texindy, `-I latex`) y LuaLaTeX con babel-spanish.

1. Una página con un formato que xindy no tiene declarado se descarta con un «WARNING: unknown attribute» y nada más: «Alberdi» perdió la página de su nota. `compilar_latex_comun.sh` solo cuenta «did not match any location-class».
2. Un módulo propio lo declara: `define-attributes` con los formatos en un solo grupo y un `markup-locref` por formato. xindy avisa que ignora la redefinición de los cuatro que ya tenía, pero el orden nuevo se aplica. Resultado: «Alberdi, Juan Bautista, 1 n., 3» y la principal en negrita.
   En un mismo grupo, dos marcas de una entrada en la misma página dejan la del formato que va primero en la lista. Con `(("gbIndPrincipal" "default" "textbf" "textit" "hyperpage" "gbIndNota"))`, el orden de `gbindice.xdy`: principal y común en la página 5 dan 5 en negrita; común y en nota dan 5, sin «n.». Con `"default"` primero, la principal perdía la negrita.
3. Número de nota («23 n. 45»). Con un atributo por número (`gbIndNota1` a `gbIndNota999`) y la orden armada con `\edef` y `\detokenize`, el número llega bien al .idx usando solo `\index`. Pero cada atributo en su grupo: xindy pone las notas después de todas las páginas y sin separador («1, 2 1 nota 2 1 nota 3 2 nota 4»). Todos en un grupo: funde la página y las notas de esa página, y las notas se pierden. Ordenaría bien una clase de ubicación de dos capas (página y nota), que exige escribir el localizador por dentro de imakeidx (`\imki@wrindexentry…`, no es interfaz documentada). No probado.
4. Escape. `"!` y `"@` dentro de `\index` llegan como `!` y `@` literales con babel-spanish activo, también con el `\index` dentro de `\emph` y de `\footnote`: «¡Absalón, Absalón!», «Twitter @jlb».
5. Rango `|(hyperpage` … `|)hyperpage` de la página 1 a la 3: «1–3».

**Relaciones:** apoya:SC-77

### GV-161 — Pandoc 3.1.3, escritor DocBook: un Span con clase sale solo con su texto; una lista de definiciones sale como <variablelist>

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El escritor `docbook5` de Pandoc 3.1.3 no tiene forma para un Span con clases: escribe su contenido y descarta clases y atributos, sin aviso. Una lista de definiciones de Markdown la escribe como `<variablelist>` con `<varlistentry>`, `<term>` y `<listitem>`.

MEDIDO (contenedor, pandoc 3.1.3):

    Plano secuencia
    :   Véase también [plano secuencia]{.vease}.

sale `<varlistentry><term>Plano secuencia</term><listitem><para>Véase también plano secuencia.</para>…`: el `{.vease}` desapareció. Lo mismo un `[OMS]{.sigla}` sin filtro: queda «OMS».

Una marca mal escrita, `[OMS] {.sigla}` (con espacio), no es un Span: Pandoc deja `{.sigla}` como texto, que saldría literal.

EN EL PROYECTO: toda marca en línea que Pandoc lee como Span la tiene que traducir un filtro antes del escritor, y el filtro frena con la que quedó partida (siglas.lua, glosario.lua). Es el mismo criterio que con el LaTeX crudo (GV-116).

**Relaciones:** apoya:SC-78,apoya:SC-79,vinculo:GV-116

### GV-162 — bash: con IFS=$'\t', read junta dos tabuladores seguidos y un campo vacío corre a los siguientes

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** GNU bash 5.2.21 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

El tabulador es «espacio de IFS» (como el espacio y el salto de línea): una secuencia de ellos cuenta como un solo separador, y los del comienzo y el final se descartan. Un campo vacío entre dos tabuladores desaparece y los siguientes se corren uno a la izquierda.

MEDIDO (GNU bash 5.2.21):

    printf 'a\t\tc\n' | { IFS=$'\t' read -r x y z; echo "x=[$x] y=[$y] z=[$z]"; }
    x=[a] y=[c] z=[]

Con `read -a`, el arreglo tiene 2 elementos y no 3.

EN EL PROYECTO: `tmp/siglas-libro.tsv` tiene campos opcionales (plural, idioma). `generar_canonicos_capitulos.sh` (`procesar_lista_siglas`) parte cada línea a mano, con `${linea%%$'\t'*}` y `${linea#*$'\t'}`, y no con `IFS=$'\t' read`. Las listas de dos o cuatro campos siempre llenos (la del lote, `tmp/siglas-piezas.txt`) se pueden leer con `read`.

**Relaciones:** apoya:SC-78

### GV-163 — babel acepta \foreignlanguage{\csname …\endcsname}; \emph dentro de \emph sale en redonda

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX 1.17.0, TeX Live 2023 / babel (english, main=spanish) / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Dos comportamientos medidos al componer el desarrollo de una sigla en otro idioma.

1. `\foreignlanguage` acepta el nombre del idioma armado con `\csname`: con

    \expandafter\def\csname gbbabel@en\endcsname{english}
    \foreignlanguage{\csname gbbabel@en\endcsname}{…}

adentro `\languagename` es `english` (la partición es la inglesa). Un `\csname` sin definir no es un error de babel: hay que controlarlo antes con `\ifcsname`.

2. `\emph` alterna: dentro de un texto en cursiva, `\emph` vuelve a redonda. `\emph{Clarín \emph{The Times}}` compone «The Times» en redonda. Es la regla tipográfica (lo citado dentro de una cursiva va en redonda), pero un desarrollo con idioma escrito `*The Times*` saldría en redonda, porque el idioma ya pone la cursiva.

MEDIDO: LuaLaTeX, TeX Live 2023, babel con `english,main=spanish`, `pdftotext` del resultado.

EN EL PROYECTO: `\gbextranjero` (contrato 19, SC-78) usa la forma 1 con `\ifcsname` y un `\PackageError` si el código no tiene nombre. La forma 2 la evita `m_Siglas.AvisoIdioma` al grabar, y la frenan siglas.lua y la lista sobre lo ya grabado.

**Relaciones:** apoya:SC-78

### GV-164 — LaTeX, clase book: un \frontmatter después de \backmatter reinicia el folio en romanos

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaHBTeX, TeX Live 2023, clase book / Linux Mint con Califa · **Verificado:** 2026-10

`\frontmatter` hace `\cleardoublepage`, pone la numeración en romanos y la reinicia en 1. No mira en qué parte del libro está: emitido después de `\backmatter`, la página siguiente sale «i» o «iii», sin aviso.

MEDIDO (Linux Mint, Alberto, 31/10/2026): una lista de siglas declarada `bm-12` iba, por su tipo, a preliminares (`ZonaDeTipo`); el recorrido del main.tex cerró posliminares, abrió otra vez la zona de preliminares, y la página salió «iii» después del índice de autores. En `fm-` salía bien. Lo mismo pasaría con `\mainmatter` después de los apéndices o los posliminares: vuelve a arábigos desde 1.

EN EL PROYECTO: `ArmarInsumosLaTeX` abre una zona cada vez que cambia. `VerificarZonas` (m_GenerarPDFLibro) frena antes de escribir nada si una pieza obliga a volver a una zona anterior, y dice cuál está después de cuál (SC-55); la lista de siglas va donde dice su prefijo (`ZonaDePieza`, SC-78).

**Relaciones:** apoya:SC-78,apoya:SC-55

### GV-165 — MySQL 8.0.46: una columna generada no puede usar una columna AUTO_INCREMENT (error 3109)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Una columna generada (`GENERATED ALWAYS AS`, virtual o almacenada) no puede referirse a una columna `AUTO_INCREMENT`: el `CREATE TABLE` falla con el error 3109. El valor de la AUTO_INCREMENT no existe todavía cuando se calcula la generada.

MEDIDO: MySQL 8.0.46, al diseñar `sigla_catalogo` con una clave `<id>-<sigla>` generada.

EN EL PROYECTO: la clave de una sigla no se guarda en el catálogo; se calcula (`m_Siglas.ClaveDe`) y se guarda, fija, en la copia del libro (`libro_sigla.clave`, SC-78).

**Relaciones:** apoya:SC-78

### GV-166 — TextEdit (gb.qt6.ext): no da las coordenadas en pantalla del cursor

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22, gb.qt6.ext (fuente CTextEdit.cpp, master 3.22.99) · **Verificado:** 2026-10

El control `TextEdit` de gb.qt6.ext no expone la posición en pantalla del cursor de texto: no hay un `CursorAt` ni un equivalente, y una ventana emergente no se puede abrir junto a donde se escribe.

VERIFICADO EN EL FUENTE: `CTextEdit.cpp` de gb.qt6.ext, rama master 3.22.99 (gambaswiki.org bloquea el acceso automatizado: la verificación es en el código).

EN EL PROYECTO: la ventanita de siglas (F2, SC-78) se ubica respecto del editor y no del cursor: centrada en vertical, con su borde izquierdo en el borde derecho del editor, que se sigue viendo entero; si no entra, se arrima al borde de la pantalla (`Desktop.Width`).

**Relaciones:** apoya:SC-78

### GV-167 — MySQL 8.0.46: una cuenta con SELECT solo sobre VIEW con SQL SECURITY DEFINER lee esas VIEW y nada más

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

MEDIDO (MySQL 8.0.46, contenedor, con el esquema de gbpublisher): cuatro VIEW creadas `SQL SECURITY DEFINER` y una cuenta con `GRANT SELECT ON gbpublisher.<vista>` para cada una.

    SELECT … FROM v_web_libro                 lee
    SELECT … FROM libros_md                   ERROR 1142: SELECT command denied
    SELECT … FROM libro_tapa_web              ERROR 1142: SELECT command denied
    UPDATE v_web_libro SET …                  ERROR 1142: UPDATE command denied
    SHOW TABLES                               solo las cuatro VIEW

- La VIEW corre con los permisos de quien la creó: `information_schema.VIEWS` da `DEFINER` y `SECURITY_TYPE = DEFINER`. Es el comportamiento por omisión; se escribe igual para que quede la intención.
- Una VIEW apoyada en otra VIEW funciona igual: la cuenta solo necesita permiso sobre la que consulta.
- `app_user` no puede crear cuentas: `CREATE USER` da ERROR 1227. Va con la cuenta administrativa (`sudo mysql`), como los cambios de esquema.
- Con `ORDER BY … DESC`, los NULL van al final; con `ASC`, al principio.

EN EL PROYECTO: la cuenta `gbweb_lector` del contrato con gbWeb (SC-81).

**Relaciones:** apoya:SC-81

### GV-168 — Gambas 3.19, gb.db.mysql: un MEDIUMBLOB va y vuelve byte a byte con Connection.Create y Blob.Data

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 (gbc3, gbx3; gb.db, gb.db.mysql) / MySQL 8.0.46 / contenedor Ubuntu 24.04 / fuente de gb.db2 y gb.db2.mysql (master 3.22.99) / Linux Mint, Gambas 3.22 (gb.db2) · **Verificado:** 2026-11

Escritura y lectura de un campo binario:

    rRes = hCon.Create("prueba_blob")
    rRes!id = 1
    rRes!imagen = File.Load("/tmp/t3.jpg")     ' UN String CON LOS BYTES
    rRes.Update()

    rRes = hCon.Exec("SELECT imagen FROM prueba_blob WHERE id = 1")
    hBlob = rRes!imagen                         ' UN OBJETO Blob
    sLeido = hBlob.Data                         ' String CON LOS BYTES

MEDIDO (gbc3 y gbx3 3.19.0, gb.db y gb.db.mysql, MySQL 8.0.46, contenedor): con 117.001 bytes aleatorios, que incluyen NUL, comillas y barras invertidas, el largo y el String leído son iguales al original y `sha256sum` da el mismo hash en los dos archivos. `SHA2(imagen, 256)` en MySQL da ese mismo hash. También leído con otra cuenta a través de una VIEW (GV-167).

FUENTE DEL PATRÓN: el ejemplo `db-blob` del curso de Gambas de jsbsan (github.com/jsbsan/Ejemplos-del-Curso-De-Gambas3), con SQLite; gambaswiki.org bloquea el acceso automatizado. Acá se midió con MySQL. No se midió en Gambas 3.22.

EN EL PROYECTO: gbpublisher guarda la tapa web en `libro_tapa_web` y gbWeb la lee de `v_web_libro_tapa` (SC-81).

EN gb.db2, EL COMPONENTE DE gbpublisher (04/11/2026)

gbpublisher usa gb.db2, no gb.db. Leído en el fuente (gitlab.com/gambas/gambas, rama master 3.22.99: `main/comp/gb.db2` y `gb.db2.mysql`):

- No existe la clase `Blob`: el código de arriba no compila en gbpublisher. Un campo binario se lee como `String`: `Result` llama a `GetResultBlob`, que en MySQL devuelve los bytes con su largo real (`GB.ReturnConstString(row[field], mysql_fetch_lengths(res)[field])`).
- Se escribe como `String`, con `Exec` y sus `&N` o con `Create`/`Edit`: el controlador lo cita con `quote_string`, que escapa `\`, `'` y NUL y deja los demás bytes tal cual, sobre una conexión con `SET NAMES 'utf8mb4'`. Un mismo `&N` puede repetirse en la sentencia (`Subst`).
- `Begin` y `Commit` con MySQL: `NoTransactionNest` es falso, así que cada `Begin` emite `START TRANSACTION` y cada `Commit` un `COMMIT`, aunque el contador de `Connection` quede desparejo por los `Commit` sin `Begin` de gbpublisher.

MEDIDO (MySQL 8.0.46, `sql_mode` estricto): la sentencia que arma gb.db2, reproducida byte a byte, con 117.001 bytes al azar y con un JPEG: `LENGTH` y `SHA2(imagen, 256)` iguales a los del archivo, sin advertencias. MEDIDO EN LINUX MINT (Alberto, 04/11/2026; Gambas 3.22, gb.db2): `m_TapaWeb` guardó la tapa de Duek con `Exec` y `&2` repetido; en la base, `LENGTH(imagen)` 117001 y `sha256` e6c2df368048973413f3ec84d1f1ced63a42bf0aab9f1286d16ef1bb75b7a125, igual al `sha256sum` del archivo.

**Relaciones:** apoya:SC-81,vinculo:GV-167,vinculo:SC-81

### GV-169 — mysqldump: restaurar el respaldo previo no borra lo creado después; una VIEW queda apuntando a una columna que ya no existe

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

El respaldo trae `DROP TABLE IF EXISTS` y `CREATE` solo de lo que existía al hacerlo. Lo que un script creó después (una tabla, una VIEW) sigue en la base tras restaurar.

MEDIDO (MySQL 8.0.46, contenedor, con actualizar-esquema-1.19.0.sh): después de restaurar el respaldo previo con el comando de GV-67, `libros_md` volvió a 79 columnas, pero `libro_tapa_web` y las cuatro VIEW seguían. `v_web_libro` lee `url_compra`, que ya no existía:

    ERROR 1356: View 'gbpublisher.v_web_libro' references invalid table(s) or column(s) …

Por la misma razón, la vuelta atrás de 1.18.0 dejaría `sigla_catalogo` y `libro_sigla` (no medido).

EN EL PROYECTO: la vuelta atrás que imprime un script de esquema borra antes lo que el script creó y después restaura (SC-22). Medido en 1.19.0: la base queda exactamente como antes, `esquema_version` incluida.

**Relaciones:** apoya:SC-22,apoya:SC-81,vinculo:GV-67

### GV-170 — bash: con pipefail, tr … </dev/urandom | head -c N termina con 141 (SIGPIPE) y set -e aborta el script

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** GNU bash 5.2.21 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

`head` termina apenas tiene sus N bytes y cierra el caño; `tr`, que sigue leyendo de `/dev/urandom` (que no se acaba nunca), muere por SIGPIPE al escribir. Con `set -o pipefail`, el estado del caño es el de `tr`, 141; con `set -e`, el script termina ahí, sin mensaje propio.

MEDIDO (GNU bash 5.2.21, contenedor): `crear-cuenta-gbweb.sh` con

    CLAVE="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 28)Aa9_"

anunció «Se crea la cuenta…», recibió la confirmación y salió con 141 antes de crearla.

FORMA CORRECTA: leer un bloque acotado, que `tr` consume entero, y cortar con bash:

    ALEATORIO="$(head -c 4096 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9')"
    CLAVE="${ALEATORIO:0:28}Aa9_"

Acá el que corta es `head` leyendo de un archivo, que no recibe SIGPIPE. Conviene controlar el largo (4096 bytes al azar dan unas 990 letras y cifras).

EN EL PROYECTO: `crear-cuenta-gbweb.sh` (SC-81). Vale para cualquier caño con `head` dentro de un script con `set -euo pipefail`, que es el encabezado de los scripts de esquema (SC-22).

**Relaciones:** apoya:SC-81,vinculo:SC-22

### GV-171 — Splitter (gb.gui.base): Resize se dispara mientras se arrastra el separador

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.gui.base, código fuente de Split/Splitter.class (rama principal) / Linux Mint · **Verificado:** 2026-11

En el fuente de `Split/Splitter.class` (gb.gui.base), el arrastre del separador pasa por `Resize_MouseMove`, que termina con `Raise Resize`. El evento no espera a que se suelte el mouse.

EN EL PROYECTO: un handler de `Resize` que vuelve a asignar el `Layout` (`[1, 2]`) deja el reparto fijo: el separador se mueve con el mouse y vuelve a su lugar. Es como gbpublisher mantiene fija la proporción de su ventana, y lo mismo hace gbWeb (`spPrincipal_Resize`, SC-84). El handler no sobra: sacarlo devuelve el separador al usuario.

**Relaciones:** apoya:SC-84

### GV-172 — StartupEnvironment del .project: llega al proceso antes de que se carguen los componentes

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 (gbc3, gba3) / contenedor Ubuntu 24.04; código fuente de gbc_compile.c, gba.c y gbx_project.c (rama principal) · **Verificado:** 2026-11

Cada línea `StartupEnvironment=VARIABLE=valor` del `.project` termina en el entorno del programa ANTES de cargar los componentes:

- gbc la escribe en el archivo `.environment` del proyecto;
- gba mete `.environment` en el ejecutable `.gambas`;
- gbx hace `putenv` de cada línea antes de cargar los componentes.

Por eso sirve para lo que Qt lee al arrancar (`QT_STYLE_OVERRIDE`, `QT_QPA_PLATFORM`) y para `GB_GUI` o `GB_GUI_DARK_THEME`, que deciden qué componente gráfico se carga y cómo. Una variable puesta desde el código, en cambio, llega tarde.

LEÍDO en el fuente (rama principal: `gbc_compile.c`, `gba.c`, `gbx_project.c`) y MEDIDO con gbc3 y gba3 3.19: el `.environment` se genera y viaja en el ejecutable.

EN EL PROYECTO: gbWeb lleva las 17 líneas de gbpublisher (modo claro, Fusion, X11), así las dos aplicaciones se ven igual (SC-84).

**Relaciones:** apoya:SC-84

### GV-173 — gb.db2: Commit() sin Begin() deja el contador de transacciones en negativo; Begin llega siempre al driver

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.db2 / código fuente de Connection.class y _DatabaseDriver.class (rama principal); MySQL 8.0.46 · **Verificado:** 2026-11

En `Connection.class` de gb.db2, `Begin` incrementa y `Commit`/`Rollback` decrementan un contador privado (`$iTrans`). Cada uno llama al driver si el contador está en 0 o si el driver no declara `NoTransactionNest`, que por omisión es False (`_DatabaseDriver.class`). Con MySQL, entonces:

- Un `Commit()` sin `Begin()` deja el contador en negativo y no hace daño: la conexión está en autocommit y cada sentencia suelta ya quedó escrita.
- Un `Begin()` posterior llega igual al driver y abre la transacción, aunque el contador esté en negativo.

REGLA DE USO: una sentencia suelta no necesita `Commit`. Varias que van juntas, entre `Begin` y `Commit`, con `Rollback` si una falla; conviene guardar el texto del error antes del `Rollback`, que pasa por el driver.

EN EL PROYECTO: `m_DatosPortal.Guardar` (gbWeb) y `m_VentaLibro.Guardar` (gbpublisher) usan el par; el `Commit` suelto que sigue a `resultado.Update` en `m_Metadatos` es de antes y no molesta.

**Relaciones:** apoya:SC-81,apoya:SC-84

### GV-174 — Me.Close no termina el programa mientras vive el bash de un TerminalView

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.form.terminal / gb.qt6 / Linux Mint · **Verificado:** 2026-11

Cerrar la ventana principal con `Me.Close` cierra la ventana, pero si un TerminalView tiene su bash corriendo, el programa sigue vivo y sin ventana: mientras un proceso hijo vive, gbx no termina.

La salida tiene que matar el bash, cerrar la conexión y llamar a `Quit`. Es lo que hace `m_InicioCierre.CerrarTodoMySQL` en gbpublisher (`DetenerProcesoBash`).

OBSERVADO por Alberto en Linux Mint con gbWeb, y CONFIRMADO con la salida corregida (04/11/2026): por el menú y por la X, el programa termina.

**Relaciones:** apoya:SC-84

### GV-175 — MySQL 8.0.46: IFNULL sobre una columna ascii_bin con un literal utf8mb4 no ASCII da el error 1267

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

    SELECT IFNULL(codigo, '—') FROM gbweb.portal;
    ERROR 1267: Illegal mix of collations (ascii_bin,IMPLICIT) and
                (utf8mb4_0900_ai_ci,COERCIBLE) for operation 'ifnull'

`codigo` es `ascii` con `ascii_bin`; la raya del literal no es ASCII. Se resuelve convirtiendo la columna: `IFNULL(CONVERT(codigo USING utf8mb4), '—')`.

Es pariente del detalle de SC-22 sobre `COLLATE` en los `CAST` de los informes.

**Relaciones:** vinculo:SC-22,vinculo:SC-80

### GV-176 — MySQL 8.0.46: ORDER BY sobre un ENUM ordena por la posición en la lista, también a través de una VIEW

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Una columna ENUM se ordena por el índice de cada valor en la definición, no por el texto. Una VIEW que la expone conserva el tipo: `information_schema.COLUMNS` da `enum` para `v_web_libro_venta.tienda`, y `ORDER BY tienda` sigue el orden de la definición.

EN EL PROYECTO: el orden de los botones de las tiendas es el del ENUM de `libro_venta.tienda` (SC-81): para cambiarlo se cambia la definición, no el código de gbWeb.

**Relaciones:** apoya:SC-81

### GV-177 — MySQL 8.0.46: CREATE OR REPLACE VIEW conserva los permisos que ya tenía la VIEW

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Reemplazar una VIEW con `CREATE OR REPLACE VIEW` (con columnas nuevas) no toca los `GRANT` que había sobre ella: `SHOW GRANTS` da lo mismo antes y después.

MEDIDO con `gbweb_lector` en las actualizaciones 1.20.0 y 1.21.0 de gbpublisher: después de reemplazar `v_web_libro` y `v_web_libro_persona`, la cuenta las sigue leyendo sin correr de nuevo `crear-cuenta-gbweb.sh`. Una VIEW NUEVA, en cambio, no tiene permiso hasta que se da.

**Relaciones:** apoya:SC-81

### GV-178 — git: remote get-url devuelve la URL ya reescrita por url.insteadOf; config --get, la guardada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** git 2.43.0 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Con una regla `url.<base>.insteadOf` activa, `git remote get-url origin` devuelve la URL YA REESCRITA, no la que está guardada en la configuración del repositorio. `git config --get remote.origin.url` devuelve la guardada.

    git remote get-url origin              /tmp/bare/r.git
    git config --get remote.origin.url     git@github.com:u/r.git

EN EL PROYECTO: `desplegar_portal.sh` compara el remoto con `git config --get`, para decidir sobre lo que dice el repositorio y no sobre lo que resuelve la máquina (SC-84).

**Relaciones:** apoya:SC-84

### GV-179 — Por file://, un enlace a una carpeta no abre su index.html

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Chromium (Playwright) y WebView de Gambas / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Un sitio estático abierto desde el disco (`file://`) no tiene servidor que resuelva `catalogo/` a `catalogo/index.html`: el enlace a la carpeta no abre su `index.html`.

EN EL PROYECTO: los enlaces internos del portal terminan en `index.html` explícito (`gbw:enlace`), y el sitio se navega igual en el visor de gbWeb, que lo abre desde `docs/`, y publicado (SC-83). La alternativa, un servidor local para el visor, quedó descartada por ahora.

**Relaciones:** apoya:SC-83

### GV-180 — fontTools: guardar una fuente (también como WOFF2) reescribe la fecha de modificación de la tabla head

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** fontTools 4.67.0 / Python 3 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Por omisión, fontTools pone la hora actual en `head.modified` al guardar: dos conversiones del mismo TTF a WOFF2 dan archivos distintos.

MEDIDO (fontTools 4.67.0), dos conversiones con un segundo y medio de diferencia:

    TTFont(ttf)                          head.modified distinto, archivos distintos
    TTFont(ttf, recalcTimestamp=False)   archivos idénticos

EN EL PROYECTO: las WOFF2 del portal son archivos fijos en `.hidden/sitio/fuentes/` y no se regeneran al construir (SC-83). Si alguna vez se generan en la construcción, con `recalcTimestamp=False`.

**Relaciones:** apoya:SC-83

### GV-181 — Pandoc 3.1.3: markdown-raw_html a html5 da un fragmento que, envuelto en un elemento, es XML bien formado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / xmllint / SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

    pandoc -f markdown-raw_html -t html5 --shift-heading-level-by=1 pagina.md

- `-raw_html` desactiva el HTML suelto del Markdown: lo que no es Markdown sale escapado, y no puede colarse una etiqueta sin cerrar.
- `--shift-heading-level-by=1` baja los títulos un nivel: el `#` del archivo sale `<h2>`, porque el `<h1>` de la página es su nombre.
- La salida es una secuencia de elementos (`<h2 id="t">T</h2>`, `<p>…</p>`); envuelta en un `<div>`, `xmllint --noout` la acepta y Saxon la lee con `doc()`.

EN EL PROYECTO: las páginas escritas del portal (SC-83).

**Relaciones:** apoya:SC-83,vinculo:GV-161

### GV-182 — XSLT 2.0: dentro de un predicado sobre doc(), la / es la raíz de ese documento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

En `doc('menu.xml')/menu/tipo[@t = /sitio/@tipo]`, la `/` del predicado no es la raíz del documento de entrada: es la del árbol del nodo de contexto, que dentro del predicado es `menu.xml`. La comparación no encuentra nada y no hay error.

Se resuelve leyendo antes el valor en una variable:

    <xsl:variable name="tipo" select="string(/sitio/@tipo)"/>
    <xsl:variable name="matriz" select="doc('menu.xml')/menu/tipo[@t = $tipo]"/>

EN EL PROYECTO: `portal.xsl` (SC-83).

**Relaciones:** apoya:SC-83

### GV-183 — XPath 2.0: una ruta como f()/@id devuelve los nodos en orden de documento, no en el de la secuencia

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Un paso de ruta (`/`) ordena su resultado por orden de documento y quita los repetidos. Si `f()` devuelve libros en un orden propio (6, 4, 7, 3), `f()/@id` da sus id en el orden en que están en el XML (3, 4, 6, 7).

Para conservar el orden de la secuencia: `for $x in f() return string($x/@id)`. `xsl:apply-templates select="$v"` y `xsl:for-each select="$v"`, con una variable, sí procesan en el orden de la secuencia.

MEDIDO con Saxon-HE 12.5 (04/11/2026) al probar los sugeridos (SC-80): con la ruta, los escalones parecían mal ordenados; con `for`, salían bien.

EN EL PROYECTO: `gbw:sugeridos` arma los escalones con la coma (`($e1, $e2, $e3, $e4)`) y la ficha los aplica desde una variable (SC-83).

**Relaciones:** apoya:SC-83,vinculo:SC-80

### GV-184 — Gambas: un arreglo literal de controles se puede usar como Object[]

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / xvfb / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

    Dim a As Object[]
    a = [t1, t2]            ' t1 y t2, TextBox
    Print Object.Type(a)    ' Object[]
    a[1].Text = "hola"      ' enlace tardío: escribe en t2

MEDIDO con Gambas 3.19 y gb.qt5 (04/11/2026). Sirve para recorrer controles hermanos en un orden fijo sin repetir el código de cada uno.

EN EL PROYECTO: `m_VentaLibro.Cajas()` (gbpublisher) devuelve las cuatro cajas de las tiendas en el orden del ENUM (SC-81).

**Relaciones:** apoya:SC-81

### GV-185 — Split toma cada carácter del separador como un separador aparte

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

    Split("uno<>dos>tres", "<>")   →   [uno] [] [dos] [tres]   (4 elementos)

El segundo argumento no es una cadena separadora: es un conjunto de caracteres, y cada uno corta. Entre `<` y `>` queda un elemento vacío.

Para cortar por una marca de varios caracteres, como el corte de título `\\` (SC-28), se recorre el texto con `InStr` y `String.Mid` (`m_Texto.TituloPlano` en gbWeb, como `m_CorteTitulo` en gbpublisher).

MEDIDO con Gambas 3.19 (04/11/2026).

CASOS EN gbpublisher (20/11/2026, SC-102):
- `Split(texto, " and ")` partía «spanish» en [sp] [] [ish] y la referencia no se guardaba.
- `Split(html, "<p")` en `m_EditorHTML.ContarMarcas` cortaba en cada `<` de un `<span>`: contaba tramos, no párrafos. Con un párrafo de dos tramos marcados y otro de uno, daba 3 en lugar de 2.

En los dos se cambió la marca por `Chr(1)` con `Replace` y se cortó por ese carácter: `Split(Replace(texto, " and ", Chr(1)), Chr(1))`. Es más corto que recorrer con `InStr`, y vale cuando el carácter de reemplazo no puede aparecer en el texto.

**Relaciones:** vinculo:SC-28,apoya:SC-102

### GV-186 — bash: read sobre una entrada sin salto de línea final devuelve 1, aunque asignó las variables

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** bash 5 / ImageMagick 6.9.12-98 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

    printf 'a b' > x.txt
    read A B < x.txt      # código 1; A=a, B=b

`read` devuelve 1 cuando llega al fin de la entrada sin encontrar el salto de línea, pero asigna lo que leyó. Con `set -e`, o con `read … || morir`, el script se corta en un caso que salió bien.

La salida de `identify -format '%w %h'` no termina en salto de línea. Se lee en dos pasos (primero a una variable con `$( … )`, después se separa), o se agrega el salto en el formato.

Es pariente de GV-162 (`read` con `IFS` de tabulador).

MEDIDO con bash 5 (04/11/2026). EN EL PROYECTO: `construir_sitio.sh` lee las medidas de la imagen destacada (SC-83).

**Relaciones:** apoya:SC-83,vinculo:GV-162

### GV-187 — IDE de Gambas: un archivo de .hidden/ reemplazado desde afuera con el IDE abierto volvió a la versión anterior

**Estado:** hipotesis · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / IDE / Linux Mint · **Verificado:** 2026-11

OBSERVADO por Alberto (04/11/2026, Gambas 3.22, Linux Mint): con gbWeb abierto en el IDE, se copió desde afuera un `.hidden/css/estilo.css` nuevo y se hizo «Recargar» (RC-GM-05). En el disco quedó la versión anterior (14.281 bytes en lugar de 15.565), y el sitio salió con la hoja vieja.

SOSPECHA: el archivo estaba abierto en un editor del IDE, y el IDE grabó encima su copia en memoria.

MINI-TEST: abrir un `.css` de `.hidden/` en el IDE; reemplazarlo desde afuera; Recargar, Compilar y cerrar el IDE; comparar el sha256 con el del archivo copiado. Repetir con el archivo cerrado en el IDE.

Si se confirma, RC-GM-05 suma: aplicar las entregas con el IDE cerrado. Mientras tanto, es lo que se hace.

**Relaciones:** vinculo:RC-GM-05

**PENDIENTE:** Correr el mini-test y pasar a vigente o descartar.

### GV-188 — Netlify, con «Pretty URLs», reescribe los enlaces de los .html que publica: …/index.html pasa a …/ y las comillas a simples

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Netlify (sitio estático desde un repositorio privado de GitHub) / curl / Linux Mint · **Verificado:** 2026-11

MEDIDO el 07/11/2026 con curl sobre el portal L-IMAGO publicado en Netlify (https://monumental-tapioca-7b0eaf.netlify.app/), construido por gbWeb con enlaces internos a `…/index.html` y comillas dobles (GV-179):

- Las páginas llegan con `href='/en/'` y `href='/en/catalogo/'`: sin `index.html`, y con comillas simples donde `portal.xsl` escribió dobles.
- Del marco (SC-83), en ese momento con extensión .html: `marco.xml`, los `pie.html` (sin enlaces internos), `marco.css`, el logo y las fuentes coinciden con el sha256 de `marco.xml`; las `cabecera.html`, con enlaces al menú del portal, no.

Es el post-procesado «Pretty URLs» de Netlify. Se apaga desde el repositorio con `netlify.toml` (`[build.processing.html] pretty_urls = false`), que pisa el interruptor del panel según la documentación de Netlify («File-based configuration»). Con eso y los fragmentos del marco en `.xml`, Alberto volvió a construir y desplegar el portal y a generar el libro integrado, y el flujo anduvo sin errores (07/11/2026).

CONSECUENCIA: un archivo que se verifica por su huella después de publicarse no puede ser un .html servido por un host que reescribe páginas.

**Relaciones:** vinculo:GV-179,vinculo:SC-83,vinculo:SC-84,vinculo:SC-85

### GV-189 — Pandoc 3.1.3: \footnote{x}{y} en Markdown — el primer par de llaves es LaTeX crudo y el segundo, Markdown con las llaves como texto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / jing 20220510 / LuaLaTeX (TeX Live 2023) con titlesec 2.16, footmisc, scrextend y hyperref / fontTools / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con Pandoc 3.1.3, lector markdown, sin filtros:

    en el .md                                      resultado
    ## A\footnote{*}{Texto *cursiva* [@c].}         RawInline tex "\footnote{*}", Str "{Texto", Emph, Cite, Str ".}"
    ## A\footnote{\dag\dag}{x}                   RawInline tex "\footnote{\dag\dag}", Str "{x}"
    ## A\footnote{*} {x}                            RawInline, Space, Str "{x}"
    ## A\footnote{*}{}                              un solo RawInline: "\footnote{*}{}"
    ## A\footnote{*}{ }                             RawInline "\footnote{*}"; el par con un espacio desaparece
    ## A\footnote{texto}                            RawInline "\footnote{texto}"
    ## A\footnote{*}{Nota (salto) sigue}             el título termina en Str "{Nota"; «sigue}» es otro párrafo

El segundo par se lee como Markdown: la bastardilla, las citas, \sptext y \num (como RawInline) y una nota ^[…] adentro salen como en cualquier texto. Las llaves quedan como caracteres de los Str, también las de adentro («{llaves}»): para encontrar el cierre hay que contarlas. Pandoc no interpreta \footnote: no crea una nota (Note), y el RawInline lo descartan los escritores de XML (GV-116).

El identificador automático del título incluye el texto del segundo par: «## A\footnote{**}{*Cursiva* inicial}» da `acursiva-inicial`.

**Relaciones:** apoya:SC-86,vinculo:GV-116,vinculo:GV-124

### GV-190 — titlesec 2.16: dentro de un título, \footnote es \footnotemark más un \footnotetext que se compone después; guarda una sola nota

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / jing 20220510 / LuaLaTeX (TeX Live 2023) con titlesec 2.16, footmisc, scrextend y hyperref / fontTools / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Leído en titlesec.sty 2.16 (2023/10/27) y medido con LuaLaTeX (TeX Live 2023), footmisc (bottom, stable), scrextend y hyperref, con las capas del libro.

Al componer un título, titlesec redefine \footnote: emite la llamada con \footnotemark y guarda el texto con `\gdef\ttl@fn{\footnotetext{…}}`, que se compone después del título (`\ttl@savefn`, `\ttl@finmarks`).

- Una sola nota por título: cada \footnote pisa `\ttl@fn`. Con dos notas numeradas en un título, la primera pierde el texto sin aviso (medido: la llamada [2] queda sin nota al pie; la [3] sale).
- El texto se compone fuera del título y del grupo que lo rodeaba. Un \footnote agrupado, con \thefootnote local y el contador devuelto a mano, daba la llamada con el símbolo y, al pie, el número ([2] en lugar de *).
- Con el argumento opcional, `\footnote[N]{…}`, titlesec guarda `\footnotemark[N]` y `\footnotetext[N]{…}`: la llamada y el texto usan el mismo valor, y el contador no avanza. Es lo que usa la nota con símbolo (SC-86).
- hyperref no vincula esa llamada de un título; la de un `\footnote[N]` en un párrafo, sí. Medido: siete vínculos para siete notas numeradas, ninguno para tres notas con símbolo en títulos; sin avisos de destinos repetidos.

Vale también para la nota numerada de SC-29: una por título.

**Relaciones:** apoya:SC-86,apoya:SC-29,vinculo:GV-70

### GV-191 — DocBook 5.2: footnote/@label es NMTOKEN — «*» y «†» no validan

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / SaxonJ-HE 12.5 / jing 20220510 / LuaLaTeX (TeX Live 2023) con titlesec 2.16, footmisc, scrextend y hyperref / fontTools / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

En el RNG de DocBook 5.2, `db.footnote.label.attribute` («Identifies the desired footnote mark») es de tipo NMTOKEN.

Medido con jing 20220510: `<footnote label="*">` y `label="†"` fallan («value of attribute "label" is invalid; must be an XML NMTOKEN»); `label="ast"` y `label="dag"` validan. Un NMTOKEN admite letras, dígitos, punto, guion, guion bajo y dos puntos: un signo tipográfico, no.

Por eso el canónico del libro guarda el nombre del símbolo y las hojas lo traducen (SC-86). En JATS 1.4, `fn/@symbol` es CDATA y `<fn>` admite `<label>` (`fn-model`: `(label?, (%just-para.class;)+)`): ahí el signo entra tal cual.

**Relaciones:** apoya:SC-86

### GV-192 — LaTeX: con \raggedright, \\ termina el párrafo; en la forma hang de titlesec la línea cortada cae debajo del número

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX (TeX Live 2023) con titlesec 2.16 y la estética del libro / SaxonJ-HE 12.5 / Pandoc 3.1.3 / contenedor Ubuntu 24.04; gbpublisher en Linux Mint (observación de Alberto, 11/11) · **Verificado:** 2026-11

Observado por Alberto en Mint (11/11/2026) en un título de sección con corte: la segunda línea empezaba en el margen, debajo de «1.1», y no alineada con el texto del título como en LaTeX.

POR QUÉ

- En el núcleo de LaTeX, `\raggedright` cambia `\\` por `\@centercr`, que hace `\par`. titlesec solo le agrega `\nobreak` (`\ttl@changecentercr`, 2.16).
- La forma `hang` de titlesec (`\ttlh@hang`) pone el número y su separación en una caja y compone el título como un párrafo con `\hangindent` igual al ancho de esa caja.
- Un `\\` en el título cierra ese párrafo: la línea siguiente empieza otro, sin la sangría colgante.
- `\newline` corta la línea dentro del mismo párrafo, y la sangría se conserva.

MEDIDO

LuaLaTeX (TeX Live 2023) con las capas reales del libro —la estética compone las secciones con `\titleformat{\section}[hang]{\sf\bfseries\large\raggedright}{\thesection}{.5em}{}`—: con `\\` la segunda línea empieza en el margen del número; con `\newline` queda alineada con el texto del título, igual que la segunda línea de un título largo que LaTeX parte solo. Desde el .md, por la cadena real (filtros, `docbook-to-latex`), en una sección con nota con símbolo y en una subsección: las dos alineadas.

NO MEDIDO

En un texto centrado (`\centering`), `\\` sirve: cada línea es un párrafo centrado. `\newline` termina la línea con `\hfil\break`, y ese `\hfil` correría la línea cortada hacia la izquierda: por eso `\gbCorteTitulo`, que usan los títulos centrados, no se cambió.

**Relaciones:** apoya:SC-63,vinculo:GV-70,vinculo:GV-190

### GV-193 — biblatex: \ExecuteBibliographyOptions{citereset=chapter} después de cargar el paquete rige igual que la opción de carga

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / babel / LuaLaTeX (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con biblatex de TeX Live 2023, un documento de dos capítulos que cita la misma obra en los dos:

    \usepackage[style=verbose-ibid]{biblatex}
    \ExecuteBibliographyOptions{citereset=chapter}

En el segundo capítulo la cita vuelve a salir completa, igual que con `citereset=chapter` en las opciones de carga. Sin la orden, sale «ibid.».

POR QUÉ IMPORTA: los `cita-*-config.tex` son comunes a libros y revistas (SC-89). `citereset=chapter` es de libros (un artículo no tiene capítulos), así que salió de los archivos de estilo y la pone `preambulo-contrato.tex` (libros, versión 21) con esta orden, después de que el estilo cargó biblatex.

**Relaciones:** vinculo:SC-57,vinculo:SC-59

### GV-194 — gb.db.mysql: SUM() llega como String; COUNT, MAX y CAST(… AS SIGNED), como Long

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19, gb.db.mysql / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con `TypeOf` sobre el Result de `Connection.Exec`:

    SELECT SUM(paginas) …                 String   (MySQL devuelve DECIMAL)
    SELECT COUNT(*) …                     Long
    SELECT MAX(pagina_fin) …              Long
    SELECT CAST(SUM(paginas) AS SIGNED)   Long

Comparar el String de un SUM() con un número da «Type mismatch» en tiempo de ejecución, no al compilar. Una suma que se compara o se opera se pide con `CAST(… AS SIGNED)` en la consulta.

**Relaciones:** vinculo:RC-GM-01

### GV-195 — gb.db.mysql: un MEDIUMBLOB NULL se lee como un Blob con .Data vacío, y !campo = Null con Edit graba un blob vacío, no NULL

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19, gb.db.mysql / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido sobre `revista.logo` (MEDIUMBLOB, esquema 1.28.0):

- LECTURA: una fila con `logo` NULL no da `IsNull(r!logo)`: da un objeto Blob cuyo `.Data` es la cadena vacía. Lo que distingue «sin logo» es `Len(r!logo.Data) = 0`. `m_Revistas.DatosDeBlob` lo resuelve en un solo lugar.
- ESCRITURA: con `Edit`, `rEdit!logo = Null` y `Update` deja `LENGTH(logo) = 0`, no NULL (comprobado con `SELECT logo IS NULL, LENGTH(logo)`).

Para quitar el dato se usa `UPDATE revista SET logo = NULL WHERE …`. Es una excepción a RC-GM-15, comentada en el código con este motivo. La escritura de un valor sigue siendo la de GV-168 (Create/Edit con `.Data`).

**Relaciones:** vinculo:GV-168,vinculo:RC-GM-15

### GV-196 — gb.db.mysql: Create y Edit funcionan sobre una tabla con clave primaria compuesta

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19, gb.db.mysql / MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Mini-test previo a la pestaña «Catálogos» (C2b): `credit_rol_nombre` (PRIMARY KEY (id_rol, idioma)) y `licencia_texto` (PRIMARY KEY (url, idioma)).

- `Create("credit_rol_nombre")`, los dos campos de la clave y `Update` dan de alta la fila.
- `Edit("credit_rol_nombre", "id_rol = &1 AND idioma = &2", …)` y `Update` cambian solo esa fila.

No hace falta una clave sustituta para usar el patrón de RC-GM-15 en una tabla de traducciones.

**Relaciones:** vinculo:RC-GM-15

### GV-197 — LaTeX: una caja guardada con lrbox dentro de un entorno se pierde al cerrarlo; hace falta \global\setbox

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / babel / LuaLaTeX (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

La columna derecha de la primera página del artículo (contrato de revista, `gbcolumna`) se arma en una caja para medirla y colocarla después (`\gbcolocarcolumna`). Con `lrbox` dentro del entorno, la caja queda en el grupo del entorno y en el `\end{gbcolumna}` vuelve a estar vacía: la columna no salía, sin error.

Lo que funciona, medido:

    \global\setbox\gbcajacolumna\box\gbcajacolumna

al final del entorno, que saca el contenido del grupo.

### GV-198 — babel: \selectlanguage y otherlanguage no expanden un \csname en su argumento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / babel / LuaLaTeX (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con babel de TeX Live 2023:

    \selectlanguage{\csname gbbabel@de\endcsname}

no cambia al alemán: toma «csnamegbbabel@de…» como nombre de idioma. Lo mismo `\begin{otherlanguage}{\csname …\endcsname}`. `\foreignlanguage` sí lo acepta (GV-163).

Lo que funciona: expandir antes con `\edef` y llamar después.

    \edef\gb@idioma{\noexpand\selectlanguage{\csname gbbabel@#1\endcsname}}%
    \gb@idioma

Es lo que hacen `\gbselectlanguage{código}` y `gbotroidioma{código}` del contrato de revista: las hojas emiten el código del idioma (es, pt-BR) y el preámbulo del número define `\gbbabel@<código>` con el nombre de babel del catálogo.

**Relaciones:** vinculo:GV-163

### GV-199 — babel-spanish: ~ se lleva el token siguiente, y < > " son activos y rompen los marcadores, el sumario y el texto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / babel / LuaLaTeX (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Con `\usepackage[spanish]{babel}` (TeX Live 2023), medido:

- `~` es un atajo activo que toma el token siguiente: `\nobreakspace` y no `~` dentro de una macro (`«~de~\fi»` se comía el `\fi`).
- `<` y `>` son activos: un título con «<» en un marcador o en el sumario frena con «Argument of \language@active@arg> has an extra }».
- `"` es activo: «Nota "de" autor» sale «Nota ”de.autor» en el PDF.

El maestro del número escapa los tres (`gbm:tex`: `\textless{}`, `\textgreater{}`, `\textquotedbl{}`). `f:latex` (`tex-comun.xsl`, común con libros) no escapa la comilla recta: en el PDF de un artículo sale rota.

**Relaciones:** vinculo:GV-163

**PENDIENTE:** Decidir dónde se escapa la comilla recta: en f:latex para libros y revistas, o solo en el camino de revistas (al final de la serie de salidas de revistas, decisión de Alberto del 14/11).

### GV-200 — babel: castellano y gallego en el mismo documento frenan con «Command \quoting already defined»

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex 3.19 / biber 2.19 / babel / LuaLaTeX (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

`spanish.ldf` define el entorno `quoting` con `\newenvironment`, sin mirar si existe; `galician.ldf` lo define o lo redefine según exista. babel carga el idioma principal al final: con `main=spanish` y `galician` entre los otros, el castellano llega después y frena (medido, babel de TeX Live 2023). Con `main=galician` no pasa.

Arreglo medido, en `preambulo-contrato-comun.tex` (versión 2), antes de cargar babel:

    \AddToHook{file/spanish.ldf/before}{%
      \let\quoting\@undefined\let\endquoting\@undefined}

Compila en los dos órdenes. No cambia nada más: las hojas no emiten `quoting`; las comillas son de csquotes.

### GV-201 — Unir PDF/A: qpdf deja los enlaces internos colgados; pdfpages pierde todos los enlaces de los PDF que incluye y pax no corre con LuaLaTeX

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** veraPDF 1.30.3 / qpdf 11.9.0 / pdfpages / pax / LuaLaTeX y pdflatex (TeX Live 2023) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Mini-test para el PDF del número (7/11, veraPDF 1.30.3, qpdf 11.9.0, TeX Live 2023), con dos artículos y una tapa que pasan PDF/A-2b cada uno:

- qpdf con la tapa como base: falla 6.1.7.1-2 (Length del stream); con `--newline-before-endstream` valida. Conserva los enlaces externos y pierde los marcadores. Los enlaces internos quedan colgados: apuntan a destinos con nombre que no están en el árbol del archivo base y que además se repiten entre artículos (`section.1`). El XMP es el de la tapa.
- qpdf `--empty`: falla tres reglas (sin XMP ni intención de salida).
- pdfpages en un maestro con `\DocumentMetadata`: valida en una sola compilación, los marcadores los arma el maestro y el XMP es el del número; pierde todos los enlaces de los artículos, también los URI.
- pax, que recupera los enlaces: frena con LuaLaTeX («pdfTeX is too old»; medido en B5).

Por eso el PDF del número usa pdfpages y los enlaces viven en los PDF sueltos de cada artículo (SC-89).

### GV-202 — JATS4R: el vocab-term de CRediT tiene la escritura de credit-roles.xml de JATS4R («Formal Analysis»), no la de NISO

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** jats-schematrons v0.0.17 / SaxonJ-HE 12.5 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

La regla de JATS4R (`credit-errors.sch`, jats-schematrons v0.0.17) compara `@vocab-term` con el término de su `credit-roles.xml`, que escribe «Formal Analysis» con mayúscula. NISO y el catálogo de gbpublisher (`credit_roles`) dicen «Formal analysis». Con la escritura de NISO el rol no valida.

En el canónico, `datos-a-front-jats.xsl` toma `vocab-term` de su tabla buscando por la URI del rol (`vocab-term-identifier`), no por el término del catálogo. El contenido de `<role>` es el nombre en el idioma del artículo (SC-90).

**Relaciones:** vinculo:GV-26

### GV-203 — biblatex-vancouver bajo tex4ht: las entradas de la bibliografía salen etiquetadas «1.», no «[1]»

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** biblatex-vancouver (vancouver.bbx v0.1, 2020/05/20) / make4ht v0.3m / TeX Live 2023 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

En `citas.html` (make4ht con `cita-tex4ht.cfg`, SC-57), el `<dt>` de cada entrada con `style=vancouver` dice «1.», «2.»; con `ieee`, «[1]». Las citas del texto salen igual en los dos: «[1, p. 3, ver 2]».

`gbct:estilo-numerico` reconocía solo ieee: con vancouver la hoja esperaba una lista sin etiquetas y frenaba. Desde E3 (14/11/2026) la lista incluye vancouver y `cita-fragmentos.xsl` acepta «[n]» o «n.»; el ancho de la columna de la etiqueta descuenta el punto.

**Relaciones:** vinculo:SC-57

### GV-204 — iconv //TRANSLIT translitera las letras con tilde solo con un locale UTF-8

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** glibc iconv / bash / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con el iconv de glibc:

    printf 'Ñandú' | LC_ALL=C.UTF-8 iconv -f UTF-8 -t ASCII//TRANSLIT    Nandu
    printf 'Ñandú' | LC_ALL=C       iconv -f UTF-8 -t ASCII//TRANSLIT    ?and?

Con el locale C las letras con tilde salen como «?», y una limpieza posterior que deja solo [A-Za-z0-9.] las borra: «Ñandú» quedaba «and».

Por eso `limpiar_parte_nombre` (engine/revista_comun.sh), que arma el nombre del PDF y el EPUB del número, fija `LC_ALL=C.UTF-8` en la llamada.

### GV-205 — gb.desktop en X11: encontrar, dimensionar y traer al frente la ventana de otro programa

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22 / gb.desktop / gb.desktop.x11 / código fuente (master, 15/11/2026) / gnome-terminal / Cinnamon / X11 / Linux Mint · **Verificado:** 2026-11

Leído en el código fuente de Gambas (`comp/src/gb.desktop/.src/Desktop.class`; `gb.desktop.x11`: `X11.class`, `DesktopWindow.class`, `_Desktop_Windows.class`, `c_x11.c`, `x11.c`; rama master del 15/11/2026, no la etiqueta 3.22.1) y probado por Alberto en Linux Mint Cinnamon el 15/11/2026, con mc en gnome-terminal (SC-94).

`Desktop` carga solo `gb.desktop.x11` en X11 (`Component.Load` en `LoadPlatform`): no hace falta declararlo en el proyecto, pero el paquete `gambas3-gb-desktop-x11` tiene que estar instalado.

ENCONTRAR LA VENTANA

    Desktop.FindWindow(Optional Title, Application, Role) As Integer[]

Sin argumentos devuelve todas las ventanas que el gestor registra (`_NET_CLIENT_LIST`). `Application` compara contra `WM_CLASS`. Para la ventana de un programa recién lanzado no se busca por título ni por clase (el título lo cambia el programa; la clase depende de la versión): se toma la lista antes del `Exec` y se espera, con la sentencia `Wait` (GV-17), la primera ventana que no estaba. Es `EsperarVentanaNueva` en `FMain` de gbpublisher, con tres segundos de plazo.

TRAERLA AL FRENTE

    Desktop.ActiveWindow = iVentana

Manda `_NET_ACTIVE_WINDOW` como pedido de aplicación, con `X11.Time`: la hora del último evento del usuario en la aplicación Gambas, el clic que lanzó el programa. Con eso Cinnamon acepta el pedido. Hace falta porque gnome-terminal abre la ventana desde su servidor, ya corriendo, y la prevención de robo de foco la dejaba detrás de gbpublisher.

DIMENSIONARLA

    Desktop.Windows.Refresh()
    hVentana = Desktop.Windows.FromHandle(iVentana)
    hVentana.Resize(iAncho, iAlto)

`FromHandle` busca en una lista que la colección guarda en caché: sin `Refresh` no ve una ventana recién creada y devuelve Null. `Resize` y `Move(X, Y, Width, Height)` mandan `_NET_MOVERESIZE_WINDOW`. Un terminal redondea el tamaño a celdas enteras de carácter.

MOVERLA SE VE EN DOS PASOS

El gestor ubica y muestra la ventana antes de que Gambas la encuentre: moverla después (centrarla con `Move`) se ve como una ventana que aparece en un lugar y salta a otro. Se probó y se descartó. La posición, si importa, tiene que viajar con la creación de la ventana (en gnome-terminal, `--geometry=COLUMNASxFILAS+X+Y`, no probado).

Ninguno de los tres pasos es crítico: van con `Try` y, si fallan, el programa queda abierto igual.

**Relaciones:** apoya:SC-94,vinculo:GV-17,vinculo:GV-43

**PENDIENTE:** Cotejar contra la etiqueta 3.22.1 del fuente: se leyó master. `Integer[].Exist()`, que usa EsperarVentanaNueva, no tiene entrada propia en el corpus. Si `--geometry` con posición lo respeta Cinnamon.

### GV-206 — pkexec desde el TerminalView de FMain: ventana gráfica, salida visible en la terminal, 0 al autenticar y 126 al cerrar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gbpublisher / gb.form.terminal / pkexec (polkit) / Cinnamon / X11 / Linux Mint 22 · **Verificado:** 2026-11

Probado por Alberto el 18/11/2026 en Linux Mint 22 Cinnamon, desde el TerminalView de `FMain` (la terminal del proyecto), con un script de prueba que llamaba a `pkexec /bin/bash -c '…'`.

- La ventana gráfica de contraseña aparece: la pone el agente de polkit de Cinnamon. No hace falta una terminal con tty para contestar.
- La salida del proceso que corre como root se ve en la misma terminal, línea por línea: pkexec conserva los descriptores de salida del proceso que lo llama.
- El proceso corre como root (`id -un` da `root`).
- Código de salida: 0 al autenticar (el del programa); 126 al cerrar la ventana («Error executing command as another user: Request dismissed»). Por el manual de pkexec, 127 cuando no se obtiene autorización.

pkexec limpia el entorno: el programa no recibe el HOME del usuario. Lo que corre como root no puede contar con `~/.gbpublisher`.

La ventana describe la acción como la ejecución de `/bin/bash` como superusuario. El texto se cambia con una política de polkit propia, no probada.

**Relaciones:** apoya:SC-95,vinculo:GV-42,vinculo:SC-53,apoya:SC-106,apoya:SC-107

**PENDIENTE:** Una política de polkit propia, para que la ventana describa la acción en castellano y no como la ejecución de /bin/bash.

### GV-207 — pandoc 3.1.3 y epubcheck 4.2.6: el binario oficial y el paquete de apt de Mint 22 dan el mismo resultado

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** pandoc 3.1.3 (oficial y 3.1.3+ds-2) / epubcheck 4.2.6 (oficial y 4.2.6-2) / Ubuntu 24.04 / Linux Mint 22 · **Verificado:** 2026-11

Medido el 18/11/2026 en un Ubuntu 24.04 (la base de Linux Mint 22) y confirmado en Mint con la cadena real.

PANDOC

El paquete de apt es `3.1.3+ds-2`: Debian lo compila contra sus propios paquetes de las bibliotecas de Haskell, así que no es el binario oficial (`pandoc-3.1.3-linux-amd64.tar.gz`, de las releases de jgm). Las 15 piezas del libro de Jensen, con la llamada de `generar_canonicos_capitulos.sh` (los 21 filtros del libro, `--to docbook5 --mathml`), dan el mismo XML byte a byte con los dos. Antes se verificó que la corrida reproducía la de la aplicación: lo generado con el pandoc de apt fue idéntico a los `tmp/body-*.xml` de la app. Límite: Jensen no tiene fórmulas (texmath sin probar), y la ruta `--citeproc` del ODT no se comparó (ya no hace falta: el ODT se retiró, SC-96).

El binario oficial trae `pandoc-lua` y `pandoc-server` como enlaces a `pandoc`; `pandoc lua -e` funciona.

EPUBCHECK

El 4.2.6 oficial (`epubcheck-4.2.6.zip`, releases de w3c) y el paquete `4.2.6-2` de Ubuntu dan el mismo informe línea por línea, sobre un EPUB válido y sobre uno roto a propósito (1 fatal, 3 errores, 1 advertencia). El `/usr/bin/epubcheck` de Debian es un JAR que se ejecuta por binfmt (jarwrapper): sin binfmt, bash lo trata como un script de texto.

CONCLUSIÓN

Hoy pasar de apt a /opt no cambia la producción. El congelamiento protege del cambio de versión de la distribución, no de una diferencia actual (SC-95).

**Relaciones:** apoya:SC-95

**PENDIENTE:** Comparar con un libro o un artículo con fórmulas (texmath).

### GV-208 — veraPDF 1.30.1: instalación sin preguntas con -options y un archivo con INSTALL_PATH; instalado por root, lo usa un usuario común

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** veraPDF 1.30.1 / IzPack 5.2.4 / Java 21 / Ubuntu 24.04 / Linux Mint 22 · **Verificado:** 2026-11

Probado el 18/11/2026: por Alberto en Linux Mint 22 y en un Ubuntu 24.04 de prueba.

El zip oficial (`verapdf-greenfield-1.30.1-installer.zip`, de software.verapdf.org; la URL y el sha256 los fija también el manifiesto de Flathub) trae `verapdf-install`, `verapdf-install.bat` y `verapdf-izpack-installer-1.30.1.jar`. Es un instalador IzPack.

- `./verapdf-install -options-template archivo` escribe la plantilla: su única clave es `INSTALL_PATH=`.
- `./verapdf-install -options archivo`, con `INSTALL_PATH` completo, instala sin preguntas los tres paquetes (GUI, CLI, documentación). Si la carpeta existe, la limpia antes.
- Instalado por root en `/opt/verapdf` y dejado legible por todos, un usuario común lo usa: `--version` y una validación con `-f 2u --format json` funcionan. La configuración la escribe en `~/.verapdf`, no en la carpeta de instalación.
- Flathub instala con `java -jar <instalador> auto-install.xml`: el formato XML también existe; no se probó.

**Relaciones:** apoya:SC-95

### GV-209 — MySQL y MariaDB se excluyen en apt por virtual-mysql-server: instalar uno saca al otro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** mysql-server-8.0 8.0.46 / mariadb-server 10.11.14 / Linux Mint 22 (Ubuntu 24.04) · **Verificado:** 2026-11

Medido el 18/11/2026 en Linux Mint 22 con `apt-cache show`.

`mysql-server-8.0` (8.0.46-0ubuntu0.24.04.5) y `mariadb-server` (1:10.11.14-0ubuntu0.24.04.1) declaran los dos `Provides: virtual-mysql-server` y `Conflicts: virtual-mysql-server`. apt nunca deja los dos instalados: instalar uno saca al otro. `mariadb-server` además declara `Breaks` y `Replaces` sobre `mysql-server-8.0`.

Consecuencia para un instalador: si encuentra MariaDB, tiene que frenar, no instalar MySQL encima. Para detectarlo no alcanza el nombre del paquete (un MySQL de los repositorios de Oracle se llama distinto): `mysqld --version` dice «MariaDB» en MariaDB.

**Relaciones:** vinculo:SC-95,apoya:SC-107

### GV-210 — gbc3 compila la llamada a una función o propiedad que no existe en otro módulo o clase, aun con la variable tipada

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 (gbc3) / Ubuntu 24.04 / proyecto gbpublisher · **Verificado:** 2026-11

Medido el 18/11/2026 con `gbc3` 3.19 sobre el proyecto gbpublisher completo, en un Ubuntu 24.04.

Compila sin errores un módulo que llama a una función que no existe en otro módulo (`m_Traduccion.ObtenerDeepLKey()`, recién borrada) y que lee una propiedad que no existe en una variable TIPADA (`Dim o As CArchivoAuditado` … `o.TotalHallazgos`, borrada). El fallo llega recién al ejecutar esa línea.

Sí detecta un identificador desconocido dentro de la misma clase o un nombre de clase o módulo que no existe (`Unknown identifier: m_EstilosHTML`).

CONSECUENCIA: compilar no prueba que un borrado sea seguro. Después de borrar hay que buscar cada nombre borrado en el código vivo (SC-97).

DESDE 3.22 (master). `gbc3 -p`, la compilación experimental en dos pasadas, sí detecta estos casos; pero su bytecode puede no arrancar y el botón del IDE se cuelga ante el error: sirve para verificar, no para ejecutar (GV-216).

**Relaciones:** apoya:SC-97,vinculo:GV-216

### GV-211 — Un temático de JATS4R se compila solo, sin SchXslt, con un envoltorio derivado del maestro, y da los mismos hallazgos que el maestro

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.9 (Maven) / jats-schematrons v0.0.17 / esqueleto ISO del repositorio / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 18/11/2026 en el contenedor (Ubuntu 24.04, Java del sistema, SaxonJ-HE 12.9 de Maven Central: misma versión que la de `/opt/Saxon-HE` de Mint, pero no los mismos bytes), con jats-schematrons v0.0.17 (commit `6589a03`) y el esqueleto ISO del repositorio (`.hidden/schematron/iso`).

UN TEMÁTICO SE COMPILA SOLO SIN SchXslt. El envoltorio se DERIVA DEL MAESTRO: `jats4r.sch` sin sus `<phase>` (nombran patrones de los otros temáticos) y con un único `<include>`, el del temático, que se copia al lado. Así lleva los mismos `<ns>`, las funciones `j4r:` y los `<let>` del maestro. Después, los tres pasos ISO de siempre: `iso_dsdl_include`, `iso_abstract_expand` y `iso_svrl_for_xslt2`. Compilan los 36 `<include>` del maestro.

SON EQUIVALENTES AL MAESTRO. Las 36 hojas se corrieron sobre 15 instancias: las cinco del generador más diez de `testfiles/` de JATS4R, sin DOCTYPE. Los hallazgos de cada temático son IDÉNTICOS a los del maestro en los patrones de ese temático, comparados por patrón, tipo, ubicación, id o test y texto. En total, 98 hallazgos sin una diferencia. Se omitieron dos instancias de JATS4R, `auths-affs-test1` y `test2`: usan el prefijo `ali:` sin declararlo. `xmllint --dropdtd` las deja pasar con un aviso y Saxon las rechaza (SXXP0003), con el maestro igual que con los temáticos.

LAS HOJAS QUE TENÍA EL AUDITOR SON DEL MISMO COMPILADOR. Las 31 hechas a mano el 30/08/2026 llevan la cabecera del esqueleto ISO («Implementers: please note that overriding process-prolog…», los bloques PHASES y PROLOG), no la de SchXslt. El SVRL que parsea `m_ValidacionSchematron` no cambia de forma.

CONSECUENCIA. El `include.xsl` de SchXslt que pedía GV-26 ya no hace falta. `generar-schematron-jats4r.sh` produce las dos cosas desde la misma versión fijada: el maestro para `validar_canonicos.sh` y los temáticos para el auditor (SC-97, bloque 3a).

**Relaciones:** apoya:SC-97,vinculo:GV-26,vinculo:GV-28,vinculo:SC-87

**PENDIENTE:** Repetir la corrida en Mint con el Saxon de /opt (el jar del zip oficial).

### GV-212 — Trim() de Gambas 3.19 no quita el byte 0xA0 de un carácter UTF-8: la advertencia de m_XML.TrimUTF8 no se cumple en esa versión

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 (gbc3, gbx3) / contenedor Ubuntu 24.04 / confirmado en Gambas 3.22.2, Linux Mint, es_AR.UTF-8 (banco gbBanco322, 19/11/2026) · **Verificado:** 2026-11

Medido el 18/11/2026 con Gambas 3.19 (gbc3 y gbx3, en un contenedor Ubuntu 24.04): un proyecto de consola imprime los bytes antes y después de `Trim()`.

- `Trim("Voilà" & Chr(10))` da `56 6F 69 6C C3 A0`: quita el salto y deja intacta la «à», cuyos bytes son `C3 A0`.
- `Trim("à")` queda en 2 bytes, `Trim(Chr(194) & Chr(160))` (un NBSP) en 2 bytes y `Trim(Chr(160))` en 1 byte.

En 3.19, `Trim()` NO quita el byte 0xA0. El comentario de `m_XML.TrimUTF8` («Trim() de Gambas elimina bytes 0xA0 que son parte de secuencias UTF-8 válidas, ej. à = 0xC3 0xA0») no se cumple en esta versión.

ALCANCE. Lo medido es 3.19, no la 3.22 de Mint. Hasta medirlo allá, la precaución de `TrimUTF8` se conserva. El código nuevo que necesite recortar blancos lo hace por bytes ASCII (9, 10, 13, 32), que es correcto en cualquier versión (`FTXTextendido.Limpiar`).

CONFIRMADO EN 3.22.2 (19/11/2026, banco gbBanco322, Mint): los cuatro casos dan lo mismo que en 3.19. `Trim()` no quita el byte 0xA0 tampoco en la versión de Mint.

**Relaciones:** vinculo:SC-18

**PENDIENTE:** Decidir si m_XML.TrimUTF8 sigue haciendo falta: ni en 3.19 ni en 3.22.2 Trim() quita el byte 0xA0.

### GV-213 — CStr de un Boolean da «T» o la cadena vacía, no «True» ni «False»

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 (gbx3) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

`CStr` de un Boolean no da «True» ni «False»: da «T» para True y la cadena vacía para False.

    CStr(True)            «T»
    CStr(False)           «»
    CStr(1 = 1)           «T»

CONSECUENCIA. Comparar el resultado con «True», escribirlo en un archivo de texto o mostrarlo en un mensaje no da lo que se espera, y no hay error que lo avise. Lo vio el banco gbBanco322: la primera versión comparaba `CStr(c.Exist("a"))` con «False» y daba 12 falsas diferencias.

REGLA. Para mostrar o escribir un Boolean, decidir el texto: `If(b, "True", "False")`, o las palabras del caso («sí»/«no»).

**Relaciones:** vinculo:RC-GM-01

**PENDIENTE:** Confirmar en Mint con 3.22.2: gbs3 con Print "«"; CStr(True); "» «"; CStr(False); "»".

### GV-214 — mysqldump: sin SHOW VIEW corta en la primera vista y deja el archivo incompleto; sin TRIGGER omite los disparadores en silencio

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8 (Mint, el mensaje) / MariaDB 10.11 y mysqldump (contenedor) · **Verificado:** 2026-11

Medido el 19/11/2026.

SIN SHOW VIEW. Una cuenta con `SELECT, INSERT, UPDATE, DELETE` sobre la base y sin `SHOW VIEW` no puede respaldarla con mysqldump si la base tiene vistas: corta en la primera y sale con código 2.

    mysqldump: Couldn't execute 'show create table `v_web_coleccion`':
    SHOW VIEW command denied to user 'app_user'@'localhost' for table
    'v_web_coleccion' (1142)

El archivo queda con lo escrito hasta ahí y sin la línea final «-- Dump completed». Las tablas que van después de la vista en orden alfabético no están. El mensaje es el de MySQL 8 en Mint; en MariaDB 10.11 da el mismo error, con el nombre de la tabla calificado con la base.

SIN TRIGGER. Sin el permiso `TRIGGER`, mysqldump no da error: omite los disparadores en silencio y el respaldo termina completo (MariaDB 10.11).

CONSECUENCIA. Un respaldo se da por bueno solo si mysqldump salió con 0 y el archivo cierra con «Dump completed» (SC-22, SC-101).

**Relaciones:** vinculo:SC-101

### GV-215 — ListBox de selección simple: asignar Index dispara Select y Click, como en el ComboBox

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / gb.qt5 / xvfb (contenedor) y Gambas 3.22.2 / gb.qt6 / Linux Mint (banco gbBancoForm322) · **Verificado:** 2026-11

Medido el 19/11/2026 con el banco gbBancoForm322, en Gambas 3.19 con gb.qt5 (contenedor, xvfb) y en 3.22.2 con gb.qt6 (Mint), con el mismo resultado. Una `ListBox` en su modo por omisión (una sola selección) y un handler que cuenta:

    lst.Index = 1     Select 1, Click 1; lst.Text devuelve el elemento

Es lo mismo que el `ComboBox` (GV-53): asignar `Index` desde el código corre el handler de `Click`. Reemplaza a GV-146, que decía lo contrario. En `Select.Multiple` es distinto: elegir por código no emite nada (GV-138).

REGLA: reponer la selección de una `ListBox` simple corre su `Click`. Si el handler no debe correr, se suprime con la bandera de llenado, o el handler compara con el índice que ya tenía.

EN EL PROYECTO (revisado el 19/11/2026, ningún error): todas las asignaciones de `Index` a una `ListBox` con `Click` ya funcionan con el evento.
- `FTabla.lstCuadros` y `FGraficos.lstGraficos`: al abrir y después de borrar, `Index = 0` abre el primero justamente porque corre el `Click`. Al llenar, la bandera `$bLlenando` lo calla, y el handler compara con `$iIndiceLista`.
- `FMetadatosArticulo.lstSeccionesResumen`: se repone con `$bCargando` puesto (SC-74).
- `FDossiers.lstEditoresDossier`, `FOrtografia.lstSugerencias` y `FEditarIPs.ListBox1`: el `Click` hace lo mismo que el código que asigna, o lo que ese código quiere.

**Relaciones:** vinculo:GV-53,vinculo:GV-138,vinculo:SC-74

### GV-216 — gbc3 -p (dos pasadas, experimental): detecta los símbolos que faltan en otras clases, pero el IDE se cuelga ante el error y el bytecode puede no arrancar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.2 dbe6434 (master) / gbc3 e IDE / gb.qt6 / Linux Mint / proyecto gbpublisher · **Verificado:** 2026-11

Medido el 20/11/2026 con `gbc3` 3.22.2 `dbe6434` (master) sobre el proyecto gbpublisher completo, en Mint.

QUÉ ES. `-p` (`--two-pass`) es una compilación experimental en dos pasadas: la primera carga los componentes y escribe en `.desc/` la descripción de cada clase del proyecto; la segunda compila consultándolas. Por eso ve lo que la compilación normal no ve (GV-210): un miembro que no existe en OTRA clase. En el IDE es el botón «Compile all in two pass».

LO QUE DETECTÓ. Una línea que el `Try` dejaba muda (RC-GM-02): `Process` no tiene `Terminate`.

    gbc3 -a -p .
    m_ConexionBD.module:229:36: error: Unknown symbol 'Terminate' in class 'Process'
    (sale con 1; sin -p, el mismo proyecto sale con 0)

Se detiene en el PRIMER error: la misma llamada en `m_InicioCierre`, sin `Try` y por lo tanto un error seguro al ejecutarse, no apareció hasta corregir la primera. Con `-v` la salida vuelca la carga de símbolos de cada componente y tapa el error; sin `-v` sale solo el error.

EL IDE SE CUELGA. Con ese mismo error, el botón del IDE no lo muestra: da «¡El compilador se ha bloqueado!». Desde la terminal, `gbc3 -a -p` lo informa limpio y sale con 1.

EL BYTECODE PUEDE NO ARRANCAR. Corregido el código, `gbc3 -a -p .` dio `OK` y salió con 0, pero la aplicación no arrancó: símbolo desconocido `gvNotas`, el `GridView` de `FMain` que `m_Notas` usa como `FMain.gvNotas` (`ControlPublic=1`, GV-57). El control y el código estaban intactos (comparado contra la copia previa). Después de Proyecto → Limpiar y compilar SIN `-p`, arrancó.

REGLA. `-p` sirve para VERIFICAR, desde la terminal: `gbc3 -a -p . ; echo $?`, sin `-v`, repitiendo hasta que dé 0. Para EJECUTAR, siempre Limpiar y compilar sin `-p` (RC-GM-05): un `OK` de `-p` no prueba que el bytecode funcione. El botón de dos pasadas del IDE, no usarlo.

**Relaciones:** vinculo:GV-210,apoya:RC-GM-05,vinculo:RC-GM-02,vinculo:GV-57

**PENDIENTE:** El punto del bytecode es una sola observación: repetirla (gbc3 -a -p, ejecutar; Limpiar, compilar sin -p, ejecutar) para confirmar que la causa es -p. Reportar al bugtracker de Gambas el cuelgue del IDE y el bytecode, con la versión y el commit de gbpublisher anterior a la consolidación de DetenerBashEnCurso. Revisar esta entrada cuando cambie la versión de master.

### GV-217 — MySQL 8: un índice FULLTEXT creado antes de una carga masiva con INSERT … SELECT dio relevancia 0 hasta un OPTIMIZE; creado después de la carga, no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 / InnoDB · **Verificado:** 2026-11

Medido el 20/11/2026 con MySQL 8.0.46 en el contenedor, al escribir la actualización 2.0.0 (SC-102).

CASO. `bibtex_campo` creada con su FULLTEXT `ft_bibtex_campo_valor` sobre `valor`, y después cargada con un `INSERT … SELECT` por columna dentro de una transacción (33.932 filas). Terminado el COMMIT, `MATCH (valor) AGAINST (…)` dio relevancia 0 en todas las filas: la búsqueda de `m_BuscarBib` no encontraba nada. Después de un `OPTIMIZE TABLE` la relevancia volvió.

CON EL ÍNDICE CREADO DESPUÉS DE LA CARGA (`ALTER TABLE bibtex_campo ADD FULLTEXT …`), las relevancias salen bien de entrada: 300 de 300 referencias reales encontradas, como con el índice viejo de `bibtex`. Un volcado de esa base restaurado con `mysql` (que trae el FULLTEXT en el CREATE TABLE y después los INSERT) también busca bien.

REGLA. En un script de esquema que crea una tabla con FULLTEXT y la llena de una vez, el índice se crea después de la copia. La causa no se estableció: no se aisló si depende de la transacción, del tamaño de la carga o de las estadísticas del índice.

**Relaciones:** apoya:SC-102,vinculo:SC-22

**PENDIENTE:** Mini-test para la causa: tabla con FULLTEXT; INSERT … SELECT de unas miles de filas en una transacción; COMMIT; medir MATCH. Repetir sin transacción y con OPTIMIZE intermedio. Ver si lo cambia innodb_ft_cache_size.

### GV-218 — If Not con un entero: el If niega en lógico (Not 1 da Else), pero Not como expresión es bit a bit (Not 1 = -2)

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 (gbs3) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido con `gbs3` 3.19.0 en el contenedor (20/11/2026):

    Dim i As Integer = 1
    Print Not i                         ' -2
    If Not i Then ... Else ...          ' rama Else
    If (Not i) Then ... Else ...        ' rama Else
    Dim b As Boolean = Not i            ' True
    If Not 2 → Else;  If Not 0 → Then

`Not` sobre un entero es bit a bit: `Not 1` vale -2, y -2 convertido a Boolean es True. Pero en la condición de un `If`, aun entre paréntesis, `Not` se comporta como negación lógica del entero: da Else con 1 y 2, y Then con 0. El mismo `Not i` da True asignado a un Boolean y Else en un `If`.

CONSECUENCIA. `If Not Message.Question(…) Then` funciona como se lee: `Message.Question` devuelve 1 con el primer botón, y el `If` entra con cualquier otro. Esto se midió al revisar `FCorregirBibTeX` (SC-102), donde se había sospechado lo contrario. Fuera de un `If` (asignado, en una expresión, como argumento), `Not` de un entero no es una negación lógica: para eso, comparar (`= 0`, `<> 1`).

**Relaciones:** vinculo:RC-GM-17,vinculo:SC-102

**PENDIENTE:** Confirmar en 3.22 (Mint) con el mismo script. Leer en el fuente del compilador cómo se compila Not dentro de la condición de un If.

### GV-219 — IsDir sigue los enlaces simbólicos; Stat sin segundo parámetro no; Dir devuelve los ocultos y, con gb.Directory, deja afuera los enlaces

**Estado:** vigente · **Evidencia:** doc_oficial · **Entorno:** Gambas 3.22.1 / código fuente del intérprete (main/share, main/gbx) · **Verificado:** 2026-11

Verificado en el fuente del intérprete, etiqueta 3.22.1 (`main/share/gb_file_temp.h` y `main/gbx/gbx_subr_file.c`).

- `IsDir(ruta)` usa `stat()` (`FILE_is_dir`): SIGUE el enlace. Un enlace a una carpeta da True.
- `Stat(ruta)` sin segundo parámetro usa `lstat()` (`SUBR_stat`, follow = FALSE): NO lo sigue. Un enlace da `.Type = gb.Link`. Con `Stat(ruta, True)` lo sigue.
- `Dir(ruta)` sin patrón ni filtro devuelve también los ocultos: solo saltea «.» y «..» (`FILE_dir_next`).
- `Dir(ruta, "*", gb.Directory)` decide por `d_type = DT_DIR` cuando el sistema lo informa (glibc, ext4): un enlace a una carpeta no aparece como carpeta. Con `gb.File` aparece entre los archivos.

CONSECUENCIA. Un borrado recursivo que decide con `IsDir` entra por un enlace a una carpeta de afuera y borra el contenido del destino. Fue el caso de `FMain.BorrarCarpeta`, retirado el 21/11/2026 (SC-103), que además no protegía la raíz del proyecto. Para recorrer sin salir: `Stat(ruta).Type = gb.Directory` decide si se entra, y un enlace se borra con `Kill` como un archivo.

Para un guard de «esto es una carpeta» que sí debe seguir enlaces (navegar), `IsDir` sigue siendo el indicado (GV-01).

**Relaciones:** vinculo:GV-01,apoya:SC-103

### GV-220 — Un control borrado que se nombra como FMain.Control compila igual; sacar una pestaña intermedia de un TabStrip corre los índices

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.22.2 / IDE / gb.qt6 / Linux Mint · **Verificado:** 2026-11

Observado el 21/11/2026 al borrar la pestaña «Proyecto» de `FMain` (SC-103). Con los controles `DirViewProyecto` y `FileViewProyecto` ya borrados del formulario, el proyecto compiló y la aplicación arrancó con tres líneas que los nombraban con la clase adelante: `FMain.DirViewProyecto.Root = …` en `FMain.AbrirProyectoMD` y en `m_InicioCierre` (`CerrarProyecto`, `CerrarTodoMySQL`). Los usos sin la clase adelante sí los marcó el compilador, y por eso se habían corregido.

REGLA PRÁCTICA. Después de borrar un control, buscar `FMain.<nombre>` (o `<Formulario>.<nombre>`) en todo el proyecto: que compile no prueba que no quede ninguno.

SACAR UNA PESTAÑA DEL MEDIO DE UN TabStrip EN EL IDE. Bajar `Count` quita solo las últimas. Se mueve la pestaña al final y se baja `Count`. Las que estaban después se corren un lugar: todo índice escrito como número en el código cambia de sentido sin error de compilación. Por eso el de «Resultados» pasó a `m_Constantes.PESTANA_INFERIOR_RESULTADOS` (SC-03).

**Relaciones:** vinculo:SC-103,vinculo:SC-03

**PENDIENTE:** Confirmar que la línea falla al ejecutarse (los parches la sacaron antes de abrir o cerrar un proyecto) y leer en el fuente del compilador por qué no resuelve el miembro cuando va con el nombre de la clase adelante.

### GV-221 — Crossref bloqueó query.title en 2019; OpenCitations cuenta citas con /index/v2/citation-count; OpenAIRE da el total en response.header.total

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** API REST de Crossref / OpenCitations Index API v2 / OpenAIRE Search API / Linux Mint · **Verificado:** 2026-11

Verificado el 21-22/11/2026 en la documentación de cada servicio y medido por Alberto en Mint con `consultar_doi.sh` (SC-105).

CROSSREF. `query.title` está bloqueado en la API REST desde octubre de 2019, por el costo que tenía para todo el servicio; Crossref indica usar `query.bibliographic`. La búsqueda por título de FMain lo seguía usando: no podía funcionar. Con `query.bibliographic` el orden es por relevancia sobre todos los datos bibliográficos (título, autores, revista, año), no solo el título: «The OpenCitations Index» trae primero preprints de COCI que el artículo de 2024.

OPENCITATIONS. La API del índice va por la versión 2 (`https://api.opencitations.net/index/v2`). `/citation-count/doi:{doi}` devuelve solo la cantidad, como `[{"count": "34"}]` (el número es un texto). La barra del DOI va sin codificar, como en su documentación. El token de acceso es optativo; el límite es de 180 consultas por minuto por IP. Lo de antes (`/index/api/v1/citations/{doi}`) bajaba todas las citas para contarlas.

OPENAIRE. `https://api.openaire.eu/search/publications?doi=…&format=json` sigue documentada. El total está en `response.header.total`; el script acepta que llegue como número o como `{"$": N}`. Medido: el DOI de prueba da «Sí (1 resultado/s)».

MEDIDO CON 10.1108/jd-12-2013-0166: Crossref, 46 citas; OpenCitations, 57. La diferencia es esperable: OpenCitations reúne varias fuentes.

**Relaciones:** apoya:SC-105

**PENDIENTE:** Ver en qué forma llega el total de OpenAIRE (número o {"$": N}): el script acepta las dos. La API de búsqueda convive con la del grafo (api.openaire.eu/graph); si se retira, migrar a /graph con el filtro por pid.

### GV-222 — mysqldump rechaza database en la sección [client] de un archivo de opciones: «unknown variable 'database=...'»; en [mysql] la usa solo el cliente mysql

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 (mysql, mysqldump) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 25/11/2026 con MySQL 8.0.46 en el contenedor.

Con un archivo de opciones que tiene `database=gbpublisher` en `[client]`, `mysqldump --defaults-extra-file=archivo … gbpublisher` termina con `mysqldump: [ERROR] unknown variable 'database=gbpublisher'.` y no vuelca nada.

Con `database` en una sección `[mysql]` aparte:
- `mysqldump` vuelca hasta «Dump completed»;
- `mysql --defaults-extra-file=archivo` entra a esa base (`SELECT DATABASE()` da `gbpublisher`).

`[client]` la leen todos los programas del cliente, y cada uno rechaza las opciones que no conoce. `[mysql]` la lee solo el cliente `mysql`.

CONSECUENCIA. Un archivo de conexión que sirva a la vez para `mysql` y para `mysqldump` lleva `database` en `[mysql]` (SC-106). El `~/.gbweb/conexion.conf` de gbWeb la tiene en `[client]`: sirve porque gbWeb solo usa `mysql`.

**Relaciones:** apoya:SC-106,vinculo:SC-81,vinculo:SC-101

### GV-223 — gb.settings lee un archivo de opciones de MySQL tal cual: [client] user=… se lee como Settings["client/user"], texto, sin comillas

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19.0 (gbs3, gb.settings, gb.db) / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 25/11/2026 con `gbs3` 3.19.0 en el contenedor.

Archivo:

    [client]
    user=app_user
    password=Ab3kXy9Qz7Lm2Np8Rt5Vw1Hj6Gd4Fs0Aa1!
    host=localhost

    [mysql]
    database=gbpublisher

- `New Settings(ruta)` lo abre.
- `Settings["client/user"]` da `app_user`, y `Settings["client/password"]` da la contraseña exacta, con el símbolo final.
- `TypeOf` da 9 (String): los valores sin comillas se leen como texto.
- `Settings["client/database"]` da vacío: está en `[mysql]`.

Con esa credencial, una `Connection` de `gb.db` a `localhost` abre y consulta.

LÍMITE. No se probó un valor que parezca número o booleano (por ejemplo, una contraseña solo de cifras): Settings podría convertirlo. Por eso la contraseña de SC-106 empieza con una letra y termina con un sufijo fijo con símbolo.

**Relaciones:** apoya:SC-106

**PENDIENTE:** Confirmar en 3.22 (Mint) con el mismo script.

### GV-224 — MySQL 8.0: DROP COLUMN de una columna que usa una FK da el error 1828; un CHECK que solo la usa a ella se borra solo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** MySQL 8.0.46 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 25/11/2026 con MySQL 8.0.46, al escribir `actualizar-esquema-2.4.0.sh` (la columna `libros_md.pais_publicacion_codigo` y su FK `fk_libro_pais_publicacion`), y repetido en una tabla de prueba:

    CREATE TABLE h (id INT PRIMARY KEY, c CHAR(2), n INT,
      CONSTRAINT fk_h FOREIGN KEY (c) REFERENCES p(c),
      CONSTRAINT chk_n CHECK (n > 0));
    ALTER TABLE h DROP COLUMN c;
    -- ERROR 1828 (HY000): Cannot drop column 'c': needed in a foreign key constraint 'fk_h'
    ALTER TABLE h DROP FOREIGN KEY fk_h, DROP COLUMN c;   -- correcto
    ALTER TABLE h DROP COLUMN n;                           -- correcto: chk_n desaparece con la columna

REGLA. Un script de esquema que borra una columna busca antes en `information_schema` las FK que la usan y las borra en el MISMO `ALTER` que la columna. Un CHECK que solo nombra a esa columna no hace falta borrarlo. Un CHECK que nombra también a otras no se midió.

**Relaciones:** apoya:SC-22

### GV-225 — LaTeX (titlesec): con footskip=0pt el pie cae sobre la última línea; \raisebox con sus argumentos opcionales dentro de \setfoot imprime un corchete suelto

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX / TeX Live 2023 / titlesec (pagestyles) / geometry / contenedor Ubuntu 24.04; el folio, visto por Alberto en Mint · **Verificado:** 2026-11

Medido el 25/11/2026 con LuaLaTeX (TeX Live 2023), titlesec con `pagestyles` y geometry, al poner el folio en la primera página de cada capítulo (estilo `plain`).

- La geometría del libro tiene `footskip=0pt`: la línea base del pie coincide con la de la última línea del texto. Un folio puesto con `\setfoot{}{\usepage}{}` queda encima de ella.
- `\raisebox{-2\baselineskip}[0pt][0pt]{\usepage}` dentro de `\setfoot`, en `\renewpagestyle{plain}[]{…}`, imprime un «]» suelto en la página.
- Lo que funciona: `\setfoot{}{\smash{\raisebox{-2\baselineskip}{\normalfont\usepage}}}{}`. `\smash` anula el alto y la profundidad sin argumentos opcionales; el folio baja dos líneas por debajo de la caja y la paginación no cambia.

Está en `latex/preambulo-estetica.tex` del paquete. El folio en la apertura del capítulo va centrado, en la fuente del cuerpo y sin peso: es una norma de estilo de Alberto.

**Relaciones:** vinculo:SC-31

### GV-226 — DateBox no admite un valor vacío: siempre muestra una fecha

**Estado:** hipotesis · **Evidencia:** inferida · **Entorno:** Gambas 3.22 / gb.qt6 · **Verificado:** 2026-11

HIPÓTESIS, sin medir. Se tomó al diseñar el registro del depósito Crossref de los libros (SC-108, 25/11/2026): un campo que tiene que poder estar vacío («todavía no se depositó») no puede ser un `DateBox` si este siempre muestra una fecha. Se resolvió con un `TextBox` de solo lectura y dos botones, que no dependen de la hipótesis.

Relacionado: `DateBox.ReadOnly` no bloquea el botón del calendario (RC-GM-14).

**Relaciones:** vinculo:RC-GM-14,vinculo:SC-108

**PENDIENTE:** Medir en Gambas 3.22 (Mint): un DateBox nuevo, ¿qué Value tiene? ¿Se le puede asignar Null y qué muestra? ¿El usuario puede borrar la fecha?

### GV-227 — gb.highlight: la matemática del .md se pinta de un solo color con el estilo Value; un estilo propio sale sin clave en 3.19; un from … to de varias líneas solo sigue en 3.22

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** gb.highlight 3.19.0 / gb.pcre / contenedor Ubuntu 24.04; gb.highlight 3.22.2 / Linux Mint (Alberto, 26/11/2026) · **Verificado:** 2026-11

Medido el 26/11/2026 con un banco de consola (`bancoMatematica`): registra la gramática con `TextHighlighter.Register`, crea el tema DESPUÉS del registro, lista `TextHighlighterTheme.Styles` y corre `Run` línea por línea arrastrando el estado, como `m_ResaltadoSintaxis.HtmlResaltado`. En el contenedor con 3.19.0; en Mint con 3.22.2 (Alberto).

EL PROBLEMA. `Markdown.highlight` no tenía estado para la matemática: el `_` de `c_{1j}` abría `italic.underscore`, que cerraba en el próximo `_`, y un capítulo con fórmulas quedaba manchado de bastardilla.

LOS ESTADOS. Después de `code.inline` (un `$` entre comillas invertidas sigue siendo código) y antes de la negrita y la bastardilla (gana el primero que coincide, GV-120), sin hijos, para que toda la fórmula tome un color:

    dolar.literal{Normal}:
      match /\\\$/
    math.display{Value}:
      from /\$\$/ to /\$\$/
    math.inline{Value}:
      from /\$(?=\S)/ to /\$/

`$$` va antes que `$`. `\$` (el signo escrito como texto, como lo deja la conversión del Word) se consume primero y no abre nada. Un `$` en `from … to` no choca con la sustitución `$(nombre)` (GV-119): cargan tanto `/\$\$/` como `$$` literal.

MEDIDO (3.22.2, Mint):

    esfera $j$ que son $c_{ij}$   [Normal:esfera ][Value:$j$][Normal: que son ][Value:$c_{ij}$]
    $$\begin{aligned}             [Value:$$\begin{aligned}]
    \sum_{j=1}^{l} c_{1j} … \\    [Value:\sum_{j=1}^{l} c_{1j} … \\]
    \end{aligned}$$               [Value:\end{aligned}$$]
    pesos: \$ 100 y USD 50        [Normal:pesos: \$ 100 y USD 50]
    `code $x$` y 5 * 3            [String:`code $x$`][Normal: y 5 * 3]

VARIAS LÍNEAS. En 3.22.2 el estado de un `from … to` abierto pasa a las líneas siguientes: el `aligned` entero sale en `Value`, y el bloque de código de tres comillas también. En 3.19 no pasa (ni el bloque de código): cada línea arranca en `Normal` y el `$$` de `\end{aligned}$$` abre otro bloque. Coincide con lo observado en GV-120.

UN ESTILO PROPIO NO SIRVE EN 3.19. Con `math.inline{Matematica}`, el componente agrega una entrada a `TextHighlighterTheme.Styles`, pero su `Key` es la cadena vacía: `CssDeGramatica` buscaría `Markdown/` y no encontraría color. Con `{Value}`, una clave que el componente ya trae y que la gramática de Markdown no usaba, sale bien. En 3.22 el estilo propio no se midió.

LAS CLAVES CAMBIAN ENTRE VERSIONES. 3.19 trae `Background`, `Selection`, `Breakpoint`… y 3.22.2 no; 3.22.2 trae `Column1` a `Column8`, `Prolog`, `CData`, `Slot`, `PseudoElement`. `Header` sale en las dos. Por eso `ClavesDeEstilo` las lee en tiempo de ejecución y no las fija en el código.

LÍMITE. Pandoc no cierra una fórmula con un `$` precedido de espacio; el resaltador no puede verlo porque el lookbehind no funciona (GV-120). Un `$` suelto pinta hasta el próximo `$`. Con los dólares escritos `USD` y el signo como texto escrito `\$`, el caso no aparece.

LOS TEMAS. La clave `Value` de `[Markdown]` de cada uno de los nueve temas toma el color de `[XML] String`, el de los valores de atributo del visor XML (decisión de Alberto, 26/11). En gruvbox, flexoki, gbpflexoki y los dos solarizados coincide con el color del código del .md: no molesta (decisión de Alberto).

PROBADO EN LA APLICACIÓN (Alberto, 26/11/2026; Mint, Gambas 3.22.2, tema gruvbox): el capítulo 9 del libro Inigo, con las fórmulas en línea y el `aligned` enteros en verde y el texto sin manchas.

**Relaciones:** vinculo:SC-15,vinculo:GV-119,vinculo:GV-120,vinculo:GV-48,vinculo:GV-76

**PENDIENTE:** Medir en 3.22.2 si un estilo propio ({Matematica}) sale con su nombre en Styles: el banco trae math-propio.highlight.

### GV-228 — La prima de las fórmulas del Word es U+2019 (’), no un apóstrofo; con ' LaTeX exige la prima antes del superíndice: g'_{x}^{c} da «Double superscript»

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / pdflatex, amsmath / TeX Live 2023 / contenedor Ubuntu 24.04; Word (OMML) del libro Inigo / LuaLaTeX, unicode-math, Libertinus Math (26/11/2026) · **Verificado:** 2026-11

Medido el 25-26/11/2026 sobre el libro Inigo (capítulos con ecuaciones de Word, OMML), con Pandoc 3.1.3 y pdflatex (TeX Live 2023) en el contenedor.

LO QUE TRAE EL WORD. El autocorrector cambia el apóstrofo por la comilla tipográfica, y el editor de ecuaciones la guarda así: `<m:t>’</m:t>`. Pandoc la deja tal cual en el TeX del .md (`{g’}_{ij}`, `M’_{1}`) y en el MathML como un identificador: `<mml:mi>’</mml:mi>`, no como prima. En el libro, unas 57 fórmulas la tienen.

EL CAMBIO A ' NO ES UNA SUSTITUCIÓN CIEGA. En TeX, `'` es `^{\prime}`. Seguida de `^` se funde con él; seguida de `_` y después `^`, son dos superíndices:

    $g'^{c}_{\overline{x}}$     correcto
    $g'_{\overline{x}}^{c}$     ! Double superscript.

Con ’ el error no aparecía porque para TeX es un carácter común. La forma correcta pone la prima antes del superíndice: `g'^{c}_{x}`.

DECISIÓN DE ALBERTO (25/11): la prima no se corrige sola al convertir; se avisa y la corrige el editor.

CONFIRMADO CON LA COMPOSICIÓN REAL (26/11/2026, GV-230): LuaLaTeX con babel-spanish y unicode-math con Libertinus Math. `$s’ = 1$` imprime la comilla; `$s' = 1$`, la prima. `$g'_{\overline{x}}^{c}$` da «Double superscript» también con unicode-math; `$g'^{c}_{\overline{x}}$` compone bien.

**Relaciones:** vinculo:GV-207,apoya:SC-110,vinculo:GV-230

### GV-229 — Pandoc 3.1.3 y la matemática: el JATS trae el TeX y el MathML; el DocBook, solo el MathML, con atributos mml: que un navegador no reconoce; un alt con el TeX valida

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / xmllint / DocBook 5.2 RNG / Saxon-HE 12.9 / epubcheck 4.2.6 / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 25-26/11/2026 en el contenedor, con el capítulo 9 del libro Inigo.

JATS (`--to jats`, con o sin `--mathml`). En línea y en bloque, Pandoc escribe las dos formas:

    <inline-formula><alternatives><tex-math>…</tex-math><mml:math>…</mml:math></alternatives></inline-formula>

La fórmula en bloque sale como `<disp-formula>` adentro de un `<p>`.

DocBook (`--to docbook5 --mathml`). Solo el MathML: `<inlineequation><mml:math>` y `<informalequation><mml:math>`. El TeX se pierde. La fórmula en bloque queda adentro del `<para>` cuando en el .md no hay línea en blanco antes del `$$`.

ATRIBUTOS CON PREFIJO. El escritor DocBook escribe `mml:columnalign`, `mml:accent`, `mml:stretchy`, `mml:style` (con prefijo). El RNG de DocBook acepta cualquier atributo dentro de MathML y el capítulo valida; un navegador no los reconoce: la barra de `\overline{x}` saldría como límite y no como acento. Al copiar el MathML al HTML y al EPUB se quita el prefijo.

EL alt VALIDA. `<alt role="tex">` antes del MathML, en `inlineequation` e `informalequation`, valida con xmllint contra `docbook.rng-5.2`: el esquema define `alt` opcional antes del contenido. Un `<equation xml:id>` sin `<title>` también valida.

texmath convierte `aligned`, `split`, `multline` y `matrix` en `mtable`: los cortes del autor llegan al MathML. `\\*` (el salto sin corte de página de amsmath) no lo entiende: lo lee como `\\` y un `<mo>*</mo>` suelto al comienzo del renglón siguiente. La prima `g'^{c}_{x}` sale como `<mi>g</mi><msubsup><mi>′</mi>…`: el subíndice y el superíndice cuelgan de la prima; a la vista, igual.

EPUB. Con el MathML copiado sin prefijo y `display="block"`, epubcheck 4.2.6 da 0 errores y 0 advertencias. Sin `properties="mathml"` en el ítem del OPF da OPF-014 («The property mathml should be declared in the OPF file»).

**Relaciones:** apoya:SC-110,vinculo:RC-DB-03,vinculo:RC-DB-07,vinculo:GV-207

### GV-230 — babel-spanish cambia el punto de una fórmula por coma: $3.5$ sale «3,5» y \num{3.5} «3.5»; \decimalpoint después de babel lo arregla, es-nodecimaldot como opción de babel no

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** LuaLaTeX / TeX Live 2023 / babel-spanish / siunitx / unicode-math, Libertinus Math / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 26/11/2026 con LuaLaTeX (TeX Live 2023) y el preámbulo real del libro Inigo (babel con main=spanish, siunitx con detect-all, unicode-math con Libertinus Math):

    $3.5$ y $0.25 x$     →  3,5 y 0,25𝑥
    \num{3.5}            →  3.5

Contradice SC-64 (punto decimal) dentro de una misma página.

- `\usepackage[\gbidiomas,es-nodecimaldot]{babel}` y `\PassOptionsToPackage{es-nodecimaldot}{babel}`: «Package babel Error: Unknown option es-nodecimaldot». babel la toma como un idioma.
- `\ifdefined\decimalpoint\decimalpoint\fi` justo después de babel: `$3.5$` sale «3.5», sin errores. `\decimalpoint` es de spanish.ldf (`\spanishdecimal{.}`); sin castellano en el libro no existe, y el `\ifdefined` lo saltea.

Con el mismo preámbulo se confirmó GV-228: `$s’$` imprime la comilla, `$s'$` la prima, y `$g'_{x}^{c}$` da «Double superscript» también con unicode-math.

**Relaciones:** apoya:SC-110,vinculo:SC-64,vinculo:GV-123,vinculo:GV-228

### GV-231 — Pandoc 3.1.3 lee [$$…$$]{#eq-x} como un corchete con id adentro del párrafo; $$…$$ {#eq-x} deja el id como texto; el escritor plain no convierte las fórmulas complejas y avisa «Could not convert TeX math»

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / contenedor Ubuntu 24.04; el aviso, también en Mint (Alberto, 26/11/2026) · **Verificado:** 2026-11

Medido el 26/11/2026 en el contenedor.

LA NUMERADA EN EL PÁRRAFO. Con la frase, la fórmula y el «donde» sin líneas en blanco:

    Texto que la introduce
    [$$E = mc^2$$]{#eq-energia}
    donde $E$ es la energía.

da un solo Para con `Span ("eq-energia", [], []) [Math DisplayMath "E = mc^2"]` en el medio. `$$…$$ {#eq-suma}` (la forma de pandoc-crossref) da la fórmula seguida de `Str "{#eq-suma}"`: el id queda como texto. `::: {.formula #eq-x}` es un bloque aparte: corta el párrafo.

EL ESCRITOR plain. La pasada de controles (comun.sh, `--to plain`) pasa cada fórmula a texto Unicode con texmath; no puede con fracciones, `aligned` ni la ’, y escribe en stderr «[WARNING] Could not convert TeX math …, rendering as TeX», con el TeX de varios renglones. No afecta a las salidas: la conversión al canónico (formula.lua, `--mathml`) no lo da. comun.sh descarta esas líneas al mostrar los avisos del lector (Alberto lo aplicó el 26/11).

**Relaciones:** apoya:SC-110,vinculo:GV-229

### GV-232 — Pandoc 3.1.3: pandoc.write de un Plain a JATS lo envuelve en <p>; sin --wrap=none, el salto de renglón después de $$…$$ llega al canónico JATS y en el TeX es un renglón vacío

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Pandoc 3.1.3 / Saxon-HE 12.9 / LuaLaTeX, contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 26/11/2026 en el contenedor.

pandoc.write A JATS. `pandoc.write(pandoc.Pandoc({pandoc.Plain({math})}), 'jats', {wrap_text = 'none'})` devuelve `<p><disp-formula>…</disp-formula></p>`: el escritor no tiene forma de bloque suelto para un Plain. `formula-jats.lua` quita el `<p>` de los extremos antes de agregar el `<label>` y devuelve un RawInline `jats`, que queda adentro del párrafo del autor.

EL SALTO DESPUÉS DE LA FÓRMULA. Con el .md

    La unidad se expresa en
    [$$…$$]{#eq-unidad}
    y la tasa media en

y Pandoc sin `--wrap=none`, el texto que sigue a `</disp-formula>` empieza con un salto de renglón y una sangría. Una plantilla de LaTeX que cierra el entorno con su propio salto (`\end{equation*}` y un `\n`) deja dos saltos seguidos: un renglón vacío, párrafo nuevo, y «y la tasa media en» sale con sangría. Con `--wrap=none` (el de `generar_canonicos_articulos.sh` y `generar_canonicos_capitulos.sh`) el salto es un espacio y el texto sigue el párrafo sin sangría. Una prueba fuera de la cadena tiene que usar los mismos argumentos.

**Relaciones:** apoya:SC-110,vinculo:GV-229,vinculo:GV-231

### GV-233 — Split con un separador de un carácter conserva los elementos vacíos y con texto vacío da cero elementos; hyperref quita \emph de los marcadores y de pdftitle sin avisar

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** Gambas 3.19 / LuaLaTeX, TeX Live 2023, hyperref / contenedor Ubuntu 24.04 · **Verificado:** 2026-11

Medido el 26/11/2026 en el contenedor.

SPLIT (Gambas 3.19). Con el asterisco como separador:

    "Sobre *Money and Totality*"   →  [Sobre ] [Money and Totality] []
    "*X*"                          →  [] [X] []
    "a*b"                          →  [a] [b]
    "**b**"                        →  [] [] [b] [] []
    "cañón *ñandú* ü"              →  [cañón ] [ñandú] [ ü]
    ""                             →  ningún elemento

Los vacíos de los extremos y del medio quedan (lo mismo que GV-185 con un separador de varios caracteres), y con eso el índice dice qué va en bastardilla: impar, adentro de un par de asteriscos. Un número par de elementos es un asterisco sin pareja. Con texto vacío no hay elementos: quien recorre el resultado no debe suponer uno. El separador es ASCII y no corta un carácter multibyte. `Else If` compila y anda.

hyperref (TeX Live 2023, LuaLaTeX). `\hypersetup{pdftitle={Sobre \emph{Money and Totality}}}` y `\chapter[… \emph{Money and Totality}]{…}` con `bookmarks`: el título del PDF y el marcador salen «Sobre Money and Totality», sin el `\emph`, y hyperref no da «Token not allowed» ni otro aviso. El sumario compone la cursiva. Medido también con los cuatro preámbulos del libro Inigo y `\gbCapitulo` (pypdf lee el marcador plano).

**Relaciones:** apoya:SC-111,vinculo:GV-185

---

## GV-XML — Comportamientos verificados XML

Evidencia empírica sobre XML, XPath, XSLT, Saxon, los validadores y los esquemas JATS y DocBook

### GV-XML-02 — jing no ejecuta el Schematron embebido en docbook.rng ni mira las instrucciones de procesamiento

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** jing 20220510-3 (paquete Debian; la misma versión que en Linux Mint) / DocBook 5.2 RNG; contenedor Ubuntu · **Verificado:** 2026-10

El RNG de DocBook 5.2 trae embebidas 247 reglas Schematron ISO (`s:pattern`, espacio de nombres `http://purl.oclc.org/dsdl/schematron`). jing las ignora: valida solo la gramática RELAX NG.

MEDIDO, contra `.hidden/schemas/docbook/docbook.rng-5.2`:

    instancia                                         jing
    <chapter> raíz sin @version                       válido
    <note> dentro de <note>                           válido
    footnoteref con @linkend a un <para>              válido
    <?gb-fuente sha256="…"?> en el prólogo            válido
    xref con @linkend a un id inexistente             IDREF "nada" without matching ID

Las tres primeras las prohíbe el Schematron del RNG. La cuarta muestra que una PI en el prólogo no molesta a la validación. La quinta, que la comprobación de ID e IDREF sí la hace jing (es la que SC-53 informa en tenue en una pieza suelta).

CONSECUENCIA: «válido para jing» no incluye ninguna regla Schematron de DocBook: ni las exclusiones (figura en figura, cuadro en nota, recuadro en recuadro), ni las comprobaciones de tipo de destino (`footnoteref`, `glossterm`, `indexterm/@startref`), ni la de `@version` en la raíz. Son una capa aparte (SC-52, criterio 4), y se ejecutan compiladas (GV-XML-03).

DE LAS 248 ASERCIONES: 131 son la de `@version` en la raíz; el resto, exclusiones entre elementos, tipos de destino de remisiones y reglas de XLink, segmentedlist, termdef y transclusión.

**Relaciones:** apoya:SC-52,vinculo:SC-53,vinculo:GV-XML-03

### GV-XML-03 — El Schematron de DocBook 5.2, extraído del RNG, compila y ejecuta con el esqueleto ISO

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / esqueleto ISO iso_svrl_for_xslt2.xsl del repositorio / DocBook 5.2 RNG / Java 21; contenedor Ubuntu; canónicos de Duek y Califa; en Linux Mint, SaxonJ-HE 12.9 con generar-schematron-docbook.sh (las cuatro instancias de prueba, como se esperaba) · **Verificado:** 2026-10

Las reglas que jing no ejecuta (GV-XML-02) se pueden correr aparte.

CÓMO

1. Extraer del RNG los `s:ns` (10, sin repetir prefijo) y los `s:pattern` (247) y envolverlos en `<s:schema queryBinding="xslt2">`. Una hoja XSLT 2.0 de diez líneas lo hace.
2. Compilar ese documento con `iso_svrl_for_xslt2.xsl` del repositorio (`.hidden/schematron/iso/`). No hay `include` que resolver.
3. Correr la hoja compilada (unos 400 KB) sobre el canónico. La salida es SVRL.

MEDIDO

- Compila sin errores ni advertencias. A diferencia de JATS4R (GV-26), ninguna regla aborta la transformación.
- Sobre las instancias de GV-XML-02 informa los tres incumplimientos: «If this element is the root element, it must have a version attribute.», «note must not occur among the children or descendants of note» y «@linkend on footnoteref must point to a footnote.».
- Sobre los 21 canónicos de dos libros reales (Duek, publicado; Califa, en corrección), capítulos y libro ensamblado: cero incumplimientos y ningún aborto. En el libro de Califa las reglas se dispararon 7113 veces.
- Toda salida contiene `schematron-output` (la comprobación de GV-28): es el informe, no la hoja.

COSTO

- Una llamada por archivo: unos 2,3 s, casi todo el arranque de la JVM y la carga de la hoja compilada.
- Una sola llamada sobre una carpeta (`-s:carpeta -o:carpeta/`): los 11 archivos de Califa en 3,6 s. El modo carpeta toma la carpeta entera, no una lista.

LÍMITE: el corpus real no tiene figuras ni cuadros. Las reglas de exclusión se probaron solo con instancias sintéticas.

**Relaciones:** apoya:SC-52,vinculo:GV-26,vinculo:GV-28,vinculo:GV-XML-02

### GV-XML-04 — Schematron con el esqueleto ISO: una regla con contexto en una PI solo se dispara para las del prólogo

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** SaxonJ-HE 12.5 / esqueleto ISO iso_svrl_for_xslt2.xsl del repositorio / contenedor Ubuntu; gbpublisher.sch compilado y probado también en Linux Mint con SaxonJ-HE 12.9 · **Verificado:** 2026-10

Con el esqueleto ISO (`iso_svrl_for_xslt2.xsl`), una regla cuyo contexto es una instrucción de procesamiento solo se dispara para las PI que están fuera del elemento raíz.

MEDIDO, sobre un capítulo con `<?gb-fuente …?>` en el prólogo y `<?gb-raro …?>` dentro de un `<para>`:

    contexto de la regla                              resultado
    processing-instruction()[starts-with(name(),      se dispara una vez, para la
      'gb-')]                                         del prólogo; gb-raro no se
                                                      revisa
    /  con  //processing-instruction()[…]  en un      encuentra gb-raro
      s:let y la aserción sobre él

La hoja compilada recorre los elementos de cada patrón con `apply-templates select="*"`: las PI dentro de los elementos no entran en el recorrido.

REGLA: una regla sobre instrucciones de procesamiento se escribe sobre la raíz del documento (`context="/"`), con las PI juntadas en un `s:let`. Así lo hace el patrón gbp-pi de `gbpublisher.sch` (SC-75).

También medido: el `@id` y el `@role` de cada aserción llegan al SVRL como atributos de `svrl:failed-assert`. Es lo que usa el validador para separar las reglas propias y leer su nivel.

**Relaciones:** apoya:SC-75,vinculo:GV-XML-03

### GV-XML-05 — DocBook 5.2: acronym admite xlink:title; glossary admite glosslist y glossdiv; @otherterm es IDREF

**Estado:** vigente · **Evidencia:** empirica · **Entorno:** jing / RNG DocBook 5.2 del repositorio / contenedor Ubuntu 24.04 · **Verificado:** 2026-10

Validado con jing contra el RNG 5.2 del repositorio:

- `<acronym xlink:title="…">` es válido: los atributos de enlace (`db.common.linking.attributes`) admiten los de XLink sin `xlink:href`.
- `<foreignphrase xml:lang="en">` en línea, válido.
- Una instrucción de procesamiento dentro del cuerpo (un `<para>`, un `<section>`) no afecta la validación.
- `<glossary>` admite, después de su `<info>`, bloques (`<para>`, `<glosslist>`) y después `<glossdiv>` o `<glossentry>`. `<glossentry>`: `<glossterm>`, y `<glosssee>` o uno o más `<glossdef>`.
- `@otherterm` de `<glosssee>` y `<glossseealso>` es IDREF: un destino inexistente invalida el documento.

EN EL PROYECTO: la lista de siglas es `<glossary role="abreviaturas">` con un `<glosslist role="siglas">`; el glosario, `<glossary role="glosario">` con `<glossdiv>` por letra (SC-78, SC-79). `ensamblar-capitulo-canonico.xsl` prefija los id con el de la pieza: prefija también `@otherterm`, con el mismo criterio que `@linkend`; sin eso, el «véase» apuntaba a un id que ya no existía.

**Relaciones:** apoya:SC-78,apoya:SC-79
