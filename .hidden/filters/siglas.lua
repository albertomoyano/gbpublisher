-- ============================================================
-- FILTRO      : siglas.lua
-- PROPÓSITO   : RESUELVE LAS MARCAS DE SIGLA DEL .md (1.18.0, documento
--               claude/siglas-glosario.md) CON EL MODELO DE glossaries:
--               LA PRIMERA VEZ EN LA PIEZA, «desarrollo (SIGLA)»; DESPUÉS,
--               SOLO LA SIGLA. CADA PIEZA (CAPÍTULO) EMPIEZA DE CERO, SIN
--               IMPORTAR LA AUTORÍA (DECISIÓN DE ALBERTO, 31/10).
-- ENTRADA     : [OMS]{.sigla}
--               [CI]{.sigla .plural}         EL PLURAL DEL DESARROLLO
--               [CI]{.sigla .inicial}        MAYÚSCULA INICIAL (COMIENZO
--                                            DE ORACIÓN)
--               [PO]{.sigla clave=12-po}     SOLO CUANDO EL LIBRO TIENE DOS
--                                            ENTRADAS CON LA MISMA SIGLA
--               .plural Y .inicial SOLO CUENTAN EN EL PRIMER USO: DESPUÉS
--               SALE LA SIGLA, QUE NO VARÍA («las ONG»).
-- DATOS       : tmp/siglas-libro.tsv DEL PROYECTO (-M gb-proyecto). LO
--               ESCRIBE GAMBAS (m_Siglas.EscribirParaFiltro) DESDE
--               libro_sigla ANTES DE LANZAR EL SCRIPT. UNA LÍNEA POR SIGLA,
--               CINCO CAMPOS SEPARADOS POR TABULADOR, SIN ENCABEZADO:
--                 clave  sigla  desarrollo  plural  idioma
--               plural E idioma PUEDEN ESTAR VACÍOS. EL DESARROLLO SOLO
--               ADMITE CURSIVA (*…*); TODO LO DEMÁS ES LITERAL ($ & % # _).
-- SALIDA      : DOCBOOK (LIBRO)
--               PRIMER USO:
--                 Organización Mundial de la Salud
--                 (<acronym xlink:title="Organización Mundial de la Salud">OMS</acronym>)
--               CON idioma, EL DESARROLLO VA EN
--                 <foreignphrase xml:lang="en">…</foreignphrase>
--               (LAS HOJAS DE SALIDA LO PONEN EN CURSIVA; LA SIGLA, NUNCA).
--               USOS SIGUIENTES: SOLO EL <acronym>.
--               AL FINAL DE LA PIEZA, UNA HUELLA POR SIGLA USADA:
--                 <?gb-sigla clave="1-oms" sha1="…"?>
--               sha1 ES EL DE SU LÍNEA EN EL .tsv: SI LA SIGLA SE CORRIGE EN
--               EL CATÁLOGO, vigencia_canonico (engine/comun.sh) DA EL
--               CANÓNICO POR DESACTUALIZADO (SC-75). LA FORMA —clave PRIMERO,
--               sha1 DESPUÉS, COMILLAS DOBLES— ES LA QUE ESA FUNCIÓN ESPERA.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : SOLO EN LA CADENA DEL LIBRO (LAS REVISTAS NO TIENEN SIGLAS),
--               DESPUÉS DE indice.lua Y ANTES DE cite-to-biblioref-db.lua,
--               QUE SERIALIZA LAS NOTAS CON pandoc.write: UNA MARCA QUE
--               LLEGUE AHÍ SIN RESOLVER SALDRÍA COMO TEXTO SUELTO. DESPUÉS DE
--               guillemets-to-quoted-db.lua: LAS COMILLAS DEL DESARROLLO NO
--               SE CONVIERTEN (EL DESARROLLO ES LITERAL).
-- REGLA       : LO QUE NO CUMPLE FRENA LA CONVERSIÓN CON UN MENSAJE: NUNCA
--               SE DEGRADA EN SILENCIO.
--               - LA MARCA NO VA EN UN TÍTULO, NI EN UNA CITA EN BLOQUE, UN
--                 EPÍGRAFE O UN VERSO, NI EN UNA FIGURA O UN CUADRO, NI EN
--                 UNA CITA BIBLIOGRÁFICA: AHÍ LA SIGLA SE ESCRIBE A MANO
--                 (DECISIÓN DE ALBERTO, 31/10). LAS COMILLAS EN LÍNEA SÍ LA
--                 ADMITEN.
--               - SIN clave, LA SIGLA TIENE QUE ESTAR UNA SOLA VEZ EN EL
--                 LIBRO. CON clave, LA CLAVE TIENE QUE ESTAR Y SER DE ESA
--                 SIGLA.
--               - .plural PIDE UN PLURAL CARGADO.
--               - EL PRIMER USO NO VA DETRÁS DEL DESARROLLO ESCRITO A MANO:
--                 «Organización Mundial de la Salud ([OMS]{.sigla})»
--                 SALDRÍA CON EL DESARROLLO DOS VECES.
--               - NO QUEDA UNA MARCA PARTIDA COMO TEXTO.
-- NOTAS       : CUENTAN EN EL LUGAR DE SU LLAMADA, COMO EN glossaries: EL
--               RECORRIDO ES PROPIO Y EN EL ORDEN DEL TEXTO, Y ENTRA EN LA
--               NOTA CUANDO LLEGA A ELLA.
-- ============================================================

-- LA RUTA DE LOS DATOS, RELATIVA AL PROYECTO. LA MISMA USAN
-- engine/comun.sh (RUTA_SIGLAS) Y m_Siglas (ARCHIVO_FILTRO): SI CAMBIA ACÁ,
-- CAMBIA EN LOS TRES
local RUTA_SIGLAS = 'tmp/siglas-libro.tsv'

-- LAS CLASES Y LOS ATRIBUTOS QUE ADMITE LA MARCA
local CLASE = 'sigla'
local MODIFICADORES = { plural = true, inicial = true }

-- LA FORMA DE LA CLAVE: LA DEL CHECK DE libro_sigla (1.18.0)
local PATRON_CLAVE = '^%d+[%-a-z0-9]*$'

-- LOS BLOQUES DONDE LA MARCA NO VA, CON EL NOMBRE PARA EL MENSAJE. SON Div
-- CON CLASE: A ESTA ALTURA DE LA CADENA fenced-divs-to-elements-db.lua
-- TODAVÍA NO LOS CONVIRTIÓ
local DIVS_PROHIBIDOS = {
  epigraph = 'un epígrafe',
  verse = 'un verso',
  source = 'una cita de fuente',
  ['primary-source'] = 'una cita de fuente',
  fig = 'una figura',
  cuadro = 'un cuadro',
  table = 'un cuadro',
}

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  La marca es [SIGLA]{.sigla}, con .plural o .inicial si hace falta, y' ..
  '\n  clave=… solo cuando el libro tiene dos siglas iguales (F2 la escribe).' ..
  '\n  En títulos, citas en bloque, epígrafes, versos, figuras y cuadros la' ..
  '\n  sigla se escribe a mano, sin marca.'

-- LAS SIGLAS DEL LIBRO: POR CLAVE, Y LAS CLAVES DE CADA SIGLA
local tPorClave = {}
local tClavesDeSigla = {}
local bDatosLeidos = false
local sRutaLeida = ''

-- LAS YA USADAS EN ESTA PIEZA (PRIMER USO) Y EL ORDEN, PARA LAS HUELLAS
local tUsadas = {}
local aUsadas = {}

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
--             bSinAyuda As Boolean — True si el problema no es de la marca
--             (el archivo de datos): la ayuda de la marca no vendría al caso
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo, bSinAyuda)
  error('\n[siglas] ' .. motivo .. (bSinAyuda and '' or ADMITIDOS) .. '\n', 0)
end

-- ============================================
-- Función   : es_marca
-- Propósito : Dice si un elemento es una marca de sigla
-- Parámetros: el As Inline
-- Retorna   : boolean
-- ============================================
local function es_marca(el)
  return el.t == 'Span' and el.classes:includes(CLASE)
end

-- ============================================
-- Función   : contiene_marca
-- Propósito : Dice si un elemento tiene alguna marca adentro
-- Parámetros: el As Block, Inline o lista
-- Retorna   : boolean; String — la primera sigla encontrada
-- ============================================
local function contiene_marca(el)
  local sPrimera = nil
  el:walk({ Span = function(s)
    if sPrimera == nil and es_marca(s) then
      sPrimera = pandoc.utils.stringify(s)
    end
  end })
  return sPrimera ~= nil, sPrimera
end

-- ============================================
-- Función   : xml
-- Propósito : Escapa un texto para ponerlo en el XML del canónico
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function xml(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

-- ============================================
-- Función   : campos
-- Propósito : Parte una línea del .tsv en sus campos, conservando los vacíos
-- Parámetros: sLinea As String
-- Retorna   : Table — los campos, en orden
-- ============================================
local function campos(sLinea)
  local aCampos, iDesde, iTab

  aCampos, iDesde = {}, 1
  while true do
    iTab = sLinea:find('\t', iDesde, true)
    if not iTab then
      table.insert(aCampos, sLinea:sub(iDesde))
      break
    end
    table.insert(aCampos, sLinea:sub(iDesde, iTab - 1))
    iDesde = iTab + 1
  end
  return aCampos
end

-- ============================================
-- Función   : leer_datos
-- Propósito : Lee las siglas del libro del .tsv del proyecto, una sola vez
-- Parámetros: meta As Meta — los metadatos del documento
-- Retorna   : nada; frena si el archivo falta o está mal formado
-- ============================================
local function leer_datos(meta)
  local sProyecto, hArchivo, iLinea, aCampos, oSigla

  if bDatosLeidos then return end
  bDatosLeidos = true

  -- --- 1. LA RUTA ---
  -- SIN gb-proyecto NO HAY DE DÓNDE LEER (vista_cuadro.sh LO PASA IGUAL QUE
  -- generar_canonicos_capitulos.sh)
  sProyecto = meta['gb-proyecto'] and pandoc.utils.stringify(meta['gb-proyecto']) or ''
  if sProyecto == '' then
    fallar('Falta -M gb-proyecto: sin él no se encuentran las siglas del libro.', true)
  end
  sRutaLeida = sProyecto:gsub('/+$', '') .. '/' .. RUTA_SIGLAS

  -- --- 2. EL ARCHIVO ---
  hArchivo = io.open(sRutaLeida, 'r')
  if not hArchivo then
    fallar('No existe ' .. RUTA_SIGLAS .. ' en el proyecto. Lo escribe la ' ..
           'aplicación antes de generar: hay que generar desde gbpublisher.', true)
  end

  -- --- 3. LAS LÍNEAS ---
  iLinea = 0
  for sLinea in hArchivo:lines() do
    iLinea = iLinea + 1
    if sLinea ~= '' then
      aCampos = campos(sLinea)
      if #aCampos ~= 5 then
        hArchivo:close()
        fallar(RUTA_SIGLAS .. ', línea ' .. iLinea .. ': tiene ' .. #aCampos ..
               ' campos y se esperan 5. El archivo lo escribe la aplicación: ' ..
               'hay que volver a generar desde gbpublisher.', true)
      end
      oSigla = {
        clave = aCampos[1], sigla = aCampos[2], desarrollo = aCampos[3],
        plural = aCampos[4], idioma = aCampos[5],
        -- LA HUELLA ES DE LA LÍNEA TAL CUAL: LA MISMA QUE CALCULA comun.sh
        sha1 = pandoc.utils.sha1(sLinea),
      }
      if not oSigla.clave:match(PATRON_CLAVE) or oSigla.sigla == '' or
         oSigla.desarrollo == '' then
        hArchivo:close()
        fallar(RUTA_SIGLAS .. ', línea ' .. iLinea .. ': la clave, la sigla o ' ..
               'el desarrollo no tienen la forma esperada.', true)
      end
      tPorClave[oSigla.clave] = oSigla
      tClavesDeSigla[oSigla.sigla] = tClavesDeSigla[oSigla.sigla] or {}
      table.insert(tClavesDeSigla[oSigla.sigla], oSigla.clave)
    end
  end
  hArchivo:close()
end

-- ============================================
-- Función   : resolver
-- Propósito : La entrada del libro a la que se refiere una marca
-- Parámetros: oSpan As Span — la marca
-- Retorna   : Table — la sigla del .tsv; String — el texto de la marca
-- ============================================
local function resolver(oSpan)
  local sTexto, sClave, aClaves, oSigla

  -- --- 1. LA FORMA DE LA MARCA ---
  sTexto = pandoc.utils.stringify(oSpan)
  if sTexto == '' then
    fallar('Una marca de sigla está vacía: []{.sigla}.')
  end
  for _, sClase in ipairs(oSpan.classes) do
    if sClase ~= CLASE and not MODIFICADORES[sClase] then
      fallar('«[' .. sTexto .. ']»: la clase .' .. sClase .. ' no va en una ' ..
             'marca de sigla (se admiten .plural y .inicial).')
    end
  end
  for sAtributo, _ in pairs(oSpan.attributes) do
    if sAtributo ~= 'clave' then
      fallar('«[' .. sTexto .. ']»: el atributo ' .. sAtributo .. '= no va en ' ..
             'una marca de sigla (se admite clave=).')
    end
  end
  if oSpan.identifier ~= '' then
    fallar('«[' .. sTexto .. ']»: una marca de sigla no lleva #' ..
           oSpan.identifier .. '.')
  end
  if contiene_marca(pandoc.Inlines(oSpan.content)) then
    fallar('«[' .. sTexto .. ']»: una marca de sigla dentro de otra.')
  end

  -- --- 2. CON CLAVE: LA CLAVE MANDA Y TIENE QUE SER DE ESA SIGLA ---
  sClave = oSpan.attributes['clave']
  if sClave then
    oSigla = tPorClave[sClave]
    if not oSigla then
      fallar('«[' .. sTexto .. ']{… clave=' .. sClave .. '}»: el libro no ' ..
             'tiene esa clave. Abrí Siglas para ver las del libro, o borrá ' ..
             'la marca y volvé a insertarla con F2.')
    end
    if oSigla.sigla ~= sTexto then
      fallar('«[' .. sTexto .. ']{… clave=' .. sClave .. '}»: esa clave es de ' ..
             '«' .. oSigla.sigla .. '», no de «' .. sTexto .. '».')
    end
    return oSigla, sTexto
  end

  -- --- 3. SIN CLAVE: UNA SOLA EN EL LIBRO ---
  aClaves = tClavesDeSigla[sTexto]
  if not aClaves then
    fallar('«' .. sTexto .. '» no está entre las siglas del libro: no está en ' ..
           'el catálogo, o el catálogo la tiene con más de un significado y ' ..
           'hay que elegirlo (F2, o «Adoptar» en Siglas).')
  end
  if #aClaves > 1 then
    fallar('«' .. sTexto .. '» tiene ' .. #aClaves .. ' significados en este ' ..
           'libro: la marca necesita la clave (' .. table.concat(aClaves, ', ') ..
           '). F2 la escribe.')
  end
  return tPorClave[aClaves[1]], sTexto
end

-- ============================================
-- Función   : plano
-- Propósito : El desarrollo sin los asteriscos de la cursiva
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function plano(s)
  return (s:gsub('%*', ''))
end

-- ============================================
-- Función   : con_inicial
-- Propósito : El desarrollo con la primera letra en mayúscula, salteando los
--             asteriscos del comienzo (*clarín* → *Clarín*)
-- Parámetros: s As String
-- Retorna   : String
-- Nota      : pandoc.text TRABAJA POR CARACTERES UTF-8: string.upper NO
--             SUBE LAS LETRAS CON TILDE.
-- ============================================
local function con_inicial(s)
  local sAsteriscos, sResto

  sAsteriscos, sResto = s:match('^(%**)(.*)$')
  if pandoc.text.len(sResto) == 0 then return s end
  return sAsteriscos .. pandoc.text.upper(pandoc.text.sub(sResto, 1, 1)) ..
         pandoc.text.sub(sResto, 2)
end

-- ============================================
-- Función   : palabras
-- Propósito : Un texto literal como Str y Space, para que el resto de la
--             cadena lo trate como texto común
-- Parámetros: s As String
-- Retorna   : Inlines
-- ============================================
local function palabras(s)
  local aInlines, bPrimera

  aInlines, bPrimera = pandoc.Inlines({}), true
  -- LOS ESPACIOS DE BORDE DE UN TRAMO CUENTAN: «la *Nación* hoy»
  if s:match('^%s') then aInlines:insert(pandoc.Space()) end
  for sPalabra in s:gmatch('%S+') do
    if not bPrimera then aInlines:insert(pandoc.Space()) end
    aInlines:insert(pandoc.Str(sPalabra))
    bPrimera = false
  end
  if s:match('%s$') and #aInlines > 0 and not s:match('^%s+$') then
    aInlines:insert(pandoc.Space())
  end
  return aInlines
end

-- ============================================
-- Función   : desarrollo_inlines
-- Propósito : El desarrollo como contenido del documento: *…* a Emph y todo
--             lo demás literal. No usa pandoc.read: $ & % # _ no son
--             Markdown acá (decisión de Alberto, 31/10)
-- Parámetros: s As String — el desarrollo (los asteriscos van de a pares:
--             lo controla m_Siglas.AvisoEntrada al grabar)
-- Retorna   : Inlines
-- ============================================
local function desarrollo_inlines(s)
  local aInlines, bCursiva

  aInlines, bCursiva = pandoc.Inlines({}), false
  -- LOS TRAMOS ENTRE ASTERISCOS ALTERNAN: FUERA, DENTRO, FUERA…
  for sTramo in (s .. '*'):gmatch('([^*]*)%*') do
    if sTramo ~= '' then
      if bCursiva then
        aInlines:insert(pandoc.Emph(palabras(sTramo)))
      else
        aInlines:extend(palabras(sTramo))
      end
    end
    bCursiva = not bCursiva
  end
  return aInlines
end

-- ============================================
-- Función   : acronimo
-- Propósito : El <acronym> de una sigla, con el desarrollo en xlink:title
--             (lo usan el HTML y el EPUB para el <abbr title>)
-- Parámetros: oSigla As Table
-- Retorna   : Inline — RawInline docbook
-- ============================================
local function acronimo(oSigla)
  return pandoc.RawInline('docbook',
    '<acronym xlink:title="' .. xml(plano(oSigla.desarrollo)) .. '">' ..
    xml(oSigla.sigla) .. '</acronym>')
end

-- ============================================
-- Función   : texto_anterior
-- Propósito : El texto plano de los inlines anteriores a una posición, sin
--             espacios repetidos, en minúscula
-- Parámetros: aLista As Inlines; iPos As Integer — la posición de la marca
-- Retorna   : String
-- ============================================
local function texto_anterior(aLista, iPos)
  local aAntes = pandoc.Inlines({})
  for i = 1, iPos - 1 do aAntes:insert(aLista[i]) end
  return pandoc.text.lower((pandoc.utils.stringify(aAntes):gsub('%s+', ' ')))
end

-- ============================================
-- Función   : termina_con
-- Propósito : Dice si un texto termina con otro
-- Parámetros: s, sFin As String
-- Retorna   : boolean
-- ============================================
local function termina_con(s, sFin)
  return sFin ~= '' and #s >= #sFin and s:sub(-#sFin) == sFin
end

-- ============================================
-- Función   : primer_uso
-- Propósito : «desarrollo (SIGLA)» para la primera aparición en la pieza
-- Parámetros: oSpan As Span — la marca; oSigla As Table
--             aLista As Inlines; iPos As Integer — dónde está la marca
-- Retorna   : Inlines — lo que reemplaza a la marca
-- ============================================
local function primer_uso(oSpan, oSigla, aLista, iPos)
  local sDesarrollo, sAntes, sPlanoS, sPlanoP, aDesarrollo, aSalida

  -- --- 1. EL TEXTO QUE VA ---
  sDesarrollo = oSigla.desarrollo
  if oSpan.classes:includes('plural') then
    if oSigla.plural == '' then
      fallar('«[' .. oSigla.sigla .. ']{.sigla .plural}»: la sigla no tiene ' ..
             'plural cargado. Se carga en Siglas, en el catálogo.')
    end
    sDesarrollo = oSigla.plural
  end
  if oSpan.classes:includes('inicial') then
    sDesarrollo = con_inicial(sDesarrollo)
  end

  -- --- 2. EL DESARROLLO NO ESTÁ YA ESCRITO A MANO ---
  -- SALDRÍA DOS VECES: «Organización Mundial de la Salud (Organización
  -- Mundial de la Salud (OMS))»
  sAntes = texto_anterior(aLista, iPos)
  sPlanoS = pandoc.text.lower(plano(oSigla.desarrollo):gsub('%s+', ' '))
  sPlanoP = pandoc.text.lower(plano(oSigla.plural):gsub('%s+', ' '))
  if termina_con(sAntes, sPlanoS .. ' (') or termina_con(sAntes, sPlanoS .. '(') or
     termina_con(sAntes, sPlanoP .. ' (') or termina_con(sAntes, sPlanoP .. '(') then
    fallar('«' .. oSigla.sigla .. '» se usa por primera vez en esta pieza ' ..
           'detrás de su desarrollo escrito a mano: el desarrollo saldría dos ' ..
           'veces. Se deja solo la marca, [' .. oSigla.sigla .. ']{.sigla}, y ' ..
           'el desarrollo lo pone la aplicación.')
  end

  -- --- 3. EL DESARROLLO, EN SU IDIOMA SI LO TIENE ---
  -- CON IDIOMA YA SALE EN CURSIVA: UNA CURSIVA QUE LO ENVUELVE ENTERO SE
  -- INVERTIRÍA (\emph DENTRO DE \emph). LA CONTROLA TAMBIÉN
  -- m_Siglas.AvisoIdioma AL GRABAR; ACÁ, LO GRABADO ANTES
  if oSigla.idioma ~= '' and sDesarrollo:match('^%*[^*]+%*$') then
    fallar('«' .. oSigla.sigla .. '» tiene idioma y el desarrollo entre ' ..
           'asteriscos: con idioma ya sale en cursiva y así saldría en ' ..
           'redonda. Sacá los asteriscos en Siglas, en el catálogo.', true)
  end
  aDesarrollo = desarrollo_inlines(sDesarrollo)
  aSalida = pandoc.Inlines({})
  if oSigla.idioma ~= '' then
    aSalida:insert(pandoc.RawInline('docbook',
      '<foreignphrase xml:lang="' .. xml(oSigla.idioma) .. '">'))
    aSalida:extend(aDesarrollo)
    aSalida:insert(pandoc.RawInline('docbook', '</foreignphrase>'))
  else
    aSalida:extend(aDesarrollo)
  end

  -- --- 4. LA SIGLA ENTRE PARÉNTESIS ---
  aSalida:insert(pandoc.Space())
  aSalida:insert(pandoc.Str('('))
  aSalida:insert(acronimo(oSigla))
  aSalida:insert(pandoc.Str(')'))
  return aSalida
end

-- EL RECORRIDO SE DECLARA ANTES: BLOQUES E INLINES SE LLAMAN ENTRE SÍ
local recorrer_bloques

-- ============================================
-- Función   : recorrer_inlines
-- Propósito : Resuelve las marcas de una lista de inlines en el orden del
--             texto, entrando en cada elemento al llegar a él (las notas
--             cuentan en el lugar de su llamada)
-- Parámetros: aLista As Inlines
-- Retorna   : Inlines — la lista con las marcas resueltas
-- ============================================
local function recorrer_inlines(aLista)
  local aSalida, oSigla, el

  aSalida = pandoc.Inlines({})
  for i = 1, #aLista do
    el = aLista[i]
    if es_marca(el) then
      -- --- 1. UNA MARCA: PRIMER USO O LOS SIGUIENTES ---
      oSigla = resolver(el)
      if tUsadas[oSigla.clave] then
        -- .plural CON UNA ENTRADA SIN PLURAL ESTÁ MAL AUNQUE NO SE USE ACÁ
        if el.classes:includes('plural') and oSigla.plural == '' then
          fallar('«[' .. oSigla.sigla .. ']{.sigla .plural}»: la sigla no ' ..
                 'tiene plural cargado. Se carga en Siglas, en el catálogo.')
        end
        aSalida:insert(acronimo(oSigla))
      else
        -- EL TEXTO ANTERIOR ES EL DE LA LISTA YA RESUELTA: aSalida
        aSalida:extend(primer_uso(el, oSigla, aSalida, #aSalida + 1))
        tUsadas[oSigla.clave] = true
        table.insert(aUsadas, oSigla)
      end
    elseif el.t == 'Note' then
      -- --- 2. UNA NOTA: SUS MARCAS CUENTAN ACÁ ---
      el.content = recorrer_bloques(el.content)
      aSalida:insert(el)
    elseif el.t == 'Str' and el.text:find('{.' .. CLASE, 1, true) then
      -- --- 3. UNA MARCA QUE PANDOC NO LEYÓ: SALDRÍA LITERAL ---
      fallar('«' .. el.text .. '…»: la marca quedó partida. Se escribe ' ..
             '[SIGLA]{.sigla}, con el corchete pegado a la llave.')
    elseif el.content ~= nil and pandoc.utils.type(el.content) == 'Inlines' then
      -- --- 4. CURSIVA, NEGRITA, COMILLAS, ENLACES, Span: ADENTRO ---
      el.content = recorrer_inlines(el.content)
      aSalida:insert(el)
    else
      aSalida:insert(el)
    end
  end
  return aSalida
end

-- ============================================
-- Función   : recorrer_bloques
-- Propósito : Resuelve las marcas de una lista de bloques en el orden del
--             texto
-- Parámetros: aBloques As Blocks
-- Retorna   : Blocks — la lista con las marcas resueltas
-- ============================================
recorrer_bloques = function(aBloques)
  local b

  for i = 1, #aBloques do
    b = aBloques[i]
    if b.t == 'Para' or b.t == 'Plain' then
      b.content = recorrer_inlines(b.content)
    elseif b.t == 'LineBlock' then
      for j = 1, #b.content do b.content[j] = recorrer_inlines(b.content[j]) end
    elseif b.t == 'Div' then
      b.content = recorrer_bloques(b.content)
    elseif b.t == 'BulletList' or b.t == 'OrderedList' then
      for j = 1, #b.content do b.content[j] = recorrer_bloques(b.content[j]) end
    elseif b.t == 'DefinitionList' then
      for j = 1, #b.content do
        b.content[j][1] = recorrer_inlines(b.content[j][1])
        for k = 1, #b.content[j][2] do
          b.content[j][2][k] = recorrer_bloques(b.content[j][2][k])
        end
      end
    end
    -- Header, BlockQuote, Figure Y Table NO LLEGAN CON MARCAS: LOS FRENA
    -- controlar_lugares. CodeBlock, RawBlock Y HorizontalRule NO LAS TIENEN
    aBloques[i] = b
  end
  return aBloques
end

-- ============================================
-- Función   : controlar_lugares
-- Propósito : Frena con una marca en un lugar donde no va
-- Parámetros: doc As Pandoc
-- Retorna   : nada; frena la conversión si encuentra una
-- ============================================
local function controlar_lugares(doc)

  -- ============================================
  -- Función   : frenar_si
  -- Propósito : Frena si el elemento tiene una marca
  -- Parámetros: el — el elemento; sLugar As String — dónde, para el mensaje
  -- Retorna   : nada
  -- ============================================
  local function frenar_si(el, sLugar)
    local bHay, sSigla = contiene_marca(el)
    if bHay then
      fallar('«[' .. sSigla .. ']{.sigla}» está en ' .. sLugar .. ': ahí la ' ..
             'sigla se escribe a mano, sin marca.')
    end
  end

  doc:walk({
    -- --- 1. TÍTULOS: PASARÍAN AL SUMARIO Y A LOS MARCADORES ---
    Header = function(h)
      frenar_si(h, 'el título «' .. pandoc.utils.stringify(h) .. '»')
    end,
    -- --- 2. CITAS EN BLOQUE: NO SE TOCAN ---
    BlockQuote = function(q) frenar_si(q, 'una cita en bloque') end,
    -- --- 3. EPÍGRAFES, VERSOS, CITAS DE FUENTE, FIGURAS Y CUADROS ---
    Div = function(d)
      for sClase, sLugar in pairs(DIVS_PROHIBIDOS) do
        if d.classes:includes(sClase) then frenar_si(d, sLugar) end
      end
    end,
    Figure = function(f) frenar_si(f, 'una figura') end,
    Image = function(img) frenar_si(img, 'una imagen') end,
    Table = function(t) frenar_si(t, 'un cuadro') end,
    -- --- 4. CITAS BIBLIOGRÁFICAS: LAS ARMA cite-to-biblioref-db.lua ---
    Cite = function(c) frenar_si(c, 'una cita bibliográfica') end,
  })
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Controla los lugares, resuelve las marcas en el orden del texto
--             y deja al final las huellas de las siglas usadas
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con las marcas resueltas
-- ============================================
function Pandoc(doc)
  local aHuellas

  -- --- 1. FORMATO: SOLO LA CADENA DEL LIBRO ---
  if FORMAT ~= 'docbook5' then
    error('\n[siglas] Formato de salida no previsto: ' .. FORMAT ..
          ' (las siglas son solo de libros)\n', 0)
  end

  -- --- 2. SIN MARCAS NO HAY NADA QUE HACER ---
  -- NI SE LEE EL .tsv: vista_cuadro.sh Y UN LIBRO SIN SIGLAS NO LO NECESITAN
  if not contiene_marca(doc) then
    doc:walk({ Str = function(s)
      if s.text:find('{.' .. CLASE, 1, true) then
        fallar('«' .. s.text .. '…»: la marca quedó partida. Se escribe ' ..
               '[SIGLA]{.sigla}, con el corchete pegado a la llave.')
      end
    end })
    return doc
  end

  -- --- 3. LUGARES DONDE NO VA ---
  controlar_lugares(doc)

  -- --- 4. LOS DATOS DEL LIBRO Y LAS MARCAS, EN EL ORDEN DEL TEXTO ---
  leer_datos(doc.meta)
  doc.blocks = recorrer_bloques(doc.blocks)

  -- --- 5. LAS HUELLAS, AL FINAL DE LA PIEZA (SC-75) ---
  aHuellas = {}
  for _, oSigla in ipairs(aUsadas) do
    table.insert(aHuellas, '<?gb-sigla clave="' .. oSigla.clave ..
      '" sha1="' .. oSigla.sha1 .. '"?>')
  end
  doc.blocks:insert(pandoc.RawBlock('docbook', table.concat(aHuellas, '\n')))

  return doc
end
