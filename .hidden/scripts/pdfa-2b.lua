#!/usr/bin/env lua
-- Script: generación PDF/A-2b para repositorios
-- ============================================================
-- PROPÓSITO : Genera un PDF/A-2b apto para archivo en repositorios
--             institucionales a partir del .tex ya generado por
--             gbpublisher. Lee los metadatos del canónico JATS para
--             construir el archivo XMP requerido por la norma.
--
-- MODELO    : Igual a color-borravino.lua — trabaja sobre una copia
--             temporal del .tex, no modifica el original.
--             El PDF/A se guarda como archivo separado (-pdfa.pdf)
--             sin reemplazar el PDF de trabajo.
--
-- REQUISITO : El paquete pdfx debe estar instalado (incluido en
--             TeX Live completo). El canónico JATS debe existir.
--
-- ARGUMENTOS:
--   arg[1] = ruta del .gbp (contexto del proyecto, no se usa)
--   arg[2] = ruta del .md activo
-- ============================================================

local COMPILACIONES = 3

-- ============================================================
-- VERIFICAR ARGUMENTOS
-- ============================================================
if not arg[2] then
  print("✗ Error: no se recibió el archivo activo como argumento")
  os.exit(1)
end

local ruta_md = arg[2]
print("→ Archivo activo: " .. ruta_md)

-- ============================================================
-- DERIVAR RUTAS DESDE EL .md
-- /proyecto/articulos/a-02-revista-v01-n01.md
--   → /proyecto/latex/l-02-revista-v01-n01.tex
--   → /proyecto/jats/c-02-revista-v01-n01.xml
--   → /proyecto/salidas/pdf/l-02-revista-v01-n01-pdfa.pdf
-- ============================================================
local nombre_archivo = ruta_md:match("([^/]+)$")
local nombre_base    = nombre_archivo and nombre_archivo:match("^..(.+)%.md$")
local ruta_proyecto  = ruta_md:match("^(.+)/articulos/")

if not ruta_proyecto or not nombre_base then
  print("✗ Error: no se pudo derivar la ruta del proyecto desde: " .. ruta_md)
  os.exit(1)
end

local ruta_latex     = ruta_proyecto .. "/latex"
local ruta_tex       = ruta_latex    .. "/l-" .. nombre_base .. ".tex"
local ruta_tex_tmp   = ruta_latex    .. "/l-" .. nombre_base .. "-pdfa.tex"
local ruta_xmpdata   = ruta_latex    .. "/l-" .. nombre_base .. "-pdfa.xmpdata"
local ruta_canonico  = ruta_proyecto .. "/jats/c-" .. nombre_base .. ".xml"
local ruta_pdf_tmp   = ruta_latex    .. "/l-" .. nombre_base .. "-pdfa.pdf"
local ruta_pdf_final = ruta_proyecto .. "/salidas/pdf/l-" .. nombre_base .. "-pdfa.pdf"
local nombre_pdfa    = "l-" .. nombre_base .. "-pdfa"

print("→ Archivo .tex:    " .. ruta_tex)
print("→ Canónico JATS:   " .. ruta_canonico)
print("→ PDF/A destino:   " .. ruta_pdf_final)

-- ============================================================
-- HELPER: EXTRACCIÓN DE NODO XML CON xmllint
-- Devuelve el contenido de texto del primer nodo que coincide
-- con la expresión XPath. Requiere xmllint instalado.
-- ============================================================
local function xpath_texto(xml, expr)
  local cmd = "xmllint --xpath 'string(" .. expr .. ")' \"" .. xml .. "\" 2>/dev/null"
  local h = io.popen(cmd)
  if not h then return "" end
  local r = h:read("*all")
  h:close()
  return (r:match("^%s*(.-)%s*$") or "")
end

-- ============================================================
-- HELPER: EXTRACCIÓN DE MÚLTIPLES NODOS XML
-- Devuelve el XML crudo de todos los nodos que coinciden.
-- Se usa cuando necesitamos iterar varios elementos (autores, kwd).
-- ============================================================
local function xpath_nodos(xml, expr)
  local cmd = "xmllint --xpath \"" .. expr .. "\" \"" .. xml .. "\" 2>/dev/null"
  local h = io.popen(cmd)
  if not h then return "" end
  local r = h:read("*all")
  h:close()
  return (r:match("^%s*(.-)%s*$") or "")
end

-- ============================================================
-- VERIFICAR QUE EL .tex EXISTE
-- ============================================================
local f = io.open(ruta_tex, "r")
if not f then
  print("✗ Error: no se encontró el archivo .tex: " .. ruta_tex)
  print("  Generá primero el PDF desde gbpublisher.")
  os.exit(1)
end
local contenido = f:read("*all")
f:close()
print("✓ Archivo .tex encontrado")

-- ============================================================
-- VERIFICAR QUE EL CANÓNICO JATS EXISTE
-- ============================================================
local fc = io.open(ruta_canonico, "r")
if not fc then
  print("✗ Error: no se encontró el canónico JATS: " .. ruta_canonico)
  print("  Generá primero el XML canónico desde gbpublisher.")
  os.exit(1)
end
fc:close()
print("✓ Canónico JATS encontrado")

-- ============================================================
-- EXTRAER METADATOS DEL CANÓNICO JATS
-- Los datos del artículo se toman directamente del canónico
-- para garantizar consistencia con el resto de las salidas.
-- ============================================================
print("→ Extrayendo metadatos del canónico JATS...")

local titulo    = xpath_texto(ruta_canonico, "//article-meta/title-group/article-title")
local idioma    = xpath_texto(ruta_canonico, "/article/@xml:lang")
local doi       = xpath_texto(ruta_canonico, "//article-meta/article-id[@pub-id-type='doi']")
local anio      = xpath_texto(ruta_canonico, "//article-meta/pub-date/year")
local editorial = xpath_texto(ruta_canonico, "//journal-meta/publisher/publisher-name")
local abstract  = xpath_texto(ruta_canonico, "//article-meta/abstract/p[1]")

-- AUTORES: EXTRAER SURNAME + GIVEN-NAMES DE CADA CONTRIBUYENTE
local autores_xml = xpath_nodos(ruta_canonico,
  "//article-meta/contrib-group/contrib[@contrib-type='author']/name")
local autores = {}
for surname, given in autores_xml:gmatch(
    "<surname>([^<]+)</surname>%s*<given%-names>([^<]+)</given%-names>") do
  table.insert(autores, surname .. ", " .. given)
end
-- FALLBACK: SOLO APELLIDO SI NO HAY NOMBRE
if #autores == 0 then
  for surname in autores_xml:gmatch("<surname>([^<]+)</surname>") do
    table.insert(autores, surname)
  end
end
local autores_str = table.concat(autores, "; ")

-- PALABRAS CLAVE
local kwds_xml = xpath_nodos(ruta_canonico, "//article-meta/kwd-group/kwd")
local kwds = {}
for kwd in kwds_xml:gmatch("<kwd>([^<]+)</kwd>") do
  table.insert(kwds, kwd)
end
local kwds_str = table.concat(kwds, ", ")

-- VALORES POR DEFECTO SI FALTAN DATOS
if titulo      == "" then titulo      = "Sin título"            end
if idioma      == "" then idioma      = "es"                    end
if autores_str == "" then autores_str = "Autor no especificado" end

print("  Título:    " .. titulo)
print("  Autores:   " .. autores_str)
print("  Idioma:    " .. idioma)
if doi  ~= "" then print("  DOI:       " .. doi)  end
if anio ~= "" then print("  Año:       " .. anio) end

-- ============================================================
-- GENERAR EL ARCHIVO .xmpdata
-- pdfx REQUIERE UN ARCHIVO CON EL MISMO NOMBRE BASE QUE EL .tex
-- Y EXTENSIÓN .xmpdata EN EL MISMO DIRECTORIO.
-- LOS CAMPOS XMP SE INCRUSTAN EN EL PDF COMO METADATOS DUBLIN CORE.
-- ============================================================
print("→ Generando archivo de metadatos XMP...")

local xmp = io.open(ruta_xmpdata, "w")
if not xmp then
  print("✗ Error: no se pudo escribir el archivo XMP: " .. ruta_xmpdata)
  os.exit(1)
end

xmp:write("\\Title{"    .. titulo      .. "}\n")
xmp:write("\\Author{"   .. autores_str .. "}\n")
if abstract ~= "" then
  -- LIMITAR EL ABSTRACT A 500 CARACTERES PARA EL CAMPO SUBJECT
  xmp:write("\\Subject{" .. abstract:sub(1, 500) .. "}\n")
end
if kwds_str ~= "" then
  xmp:write("\\Keywords{" .. kwds_str .. "}\n")
end
if editorial ~= "" then
  xmp:write("\\Org{"  .. editorial .. "}\n")
end
xmp:write("\\Language{" .. idioma .. "}\n")
if doi ~= "" then
  xmp:write("\\Doi{"  .. doi  .. "}\n")
end
if anio ~= "" then
  xmp:write("\\Date{" .. anio .. "}\n")
end

xmp:close()
print("✓ Archivo XMP generado: " .. ruta_xmpdata)

-- ============================================================
-- MODIFICAR EL PREAMBLE DEL .tex PARA PDF/A-2b
-- SE INSERTA \usepackage[a-2b,latxmp]{pdfx} INMEDIATAMENTE DESPUÉS
-- DE \documentclass. pdfx DEBE CARGARSE ANTES QUE CUALQUIER OTRO
-- PAQUETE PARA TOMAR CONTROL DEL COLOR Y LOS METADATOS.
-- ============================================================
print("→ Modificando preamble para conformidad PDF/A-2b...")

-- INSERCIÓN: pdfx + hypersetup EN UN SOLO BLOQUE DESPUÉS DE \documentclass
local insercion_pdfa =
  "\n\\usepackage[a-2b,latxmp]{pdfx}\n" ..
  "\\hypersetup{\n" ..
  "  colorlinks=true,\n" ..
  "  linkcolor=azulrevista,\n" ..
  "  citecolor=azulrevista,\n" ..
  "  urlcolor=azulrevista,\n" ..
  "  filecolor=azulrevista,\n" ..
  "  linktoc=all,\n" ..
  "  breaklinks=true,\n" ..
  "  bookmarksopen=true,\n" ..
  "  bookmarksnumbered=true\n" ..
  "}"

local contenido_pdfa = contenido:gsub(
  "(\\documentclass%b{})",
  "%1" .. insercion_pdfa,
  1
)

if contenido_pdfa == contenido then
  print("✗ Error: no se encontró \\documentclass en el archivo .tex")
  os.remove(ruta_xmpdata)
  os.exit(1)
end

-- REMOVER HYPERREF EXPLÍCITO DEL PREAMBLE
-- pdfx CARGA HYPERREF INTERNAMENTE CON OPCIONES PDF/A.
-- SI EL PREAMBLE LO VUELVE A CARGAR CON OTRAS OPCIONES, HAY CONFLICTO.
contenido_pdfa = contenido_pdfa:gsub(
  "\\usepackage%b[]{hyperref}[^\n]*\n",
  "%% hyperref gestionado por pdfx\n"
)
contenido_pdfa = contenido_pdfa:gsub(
  "\\usepackage{hyperref}\n",
  "%% hyperref gestionado por pdfx\n"
)

-- ============================================================
-- GUARDAR EL ARCHIVO .tex TEMPORAL
-- EL ORIGINAL (l-*.tex) QUEDA INTACTO PARA EL WORKFLOW NORMAL.
-- ============================================================
local out = io.open(ruta_tex_tmp, "w")
if not out then
  print("✗ Error: no se pudo escribir el archivo .tex temporal: " .. ruta_tex_tmp)
  os.remove(ruta_xmpdata)
  os.exit(1)
end
out:write(contenido_pdfa)
out:close()
print("✓ Archivo .tex con PDF/A generado")

-- ============================================================
-- COMPILAR CON LUALATEX + BIBER
-- SECUENCIA CORRECTA PARA BIBLATEX:
--   pasada 1 → genera .bcf
--   biber    → procesa .bcf y genera .bbl con las referencias
--   pasada 2 → lee .bbl y resuelve citas
--   pasada 3 → resuelve referencias cruzadas
--
-- PATRÓN SENTINEL: LUALATEX PUEDE SALIR CON CÓDIGO DE ERROR POR
-- WARNINGS PERO IGUAL GENERAR EL PDF. SE VERIFICA LA EXISTENCIA
-- DEL SENTINEL, NO EL EXIT CODE, IGUAL QUE EN EL PIPELINE PRINCIPAL.
-- ============================================================
print("→ Compilando PDF/A-2b con LuaLaTeX + Biber...")

-- --- PASADA 1 ---
print("  Pasada 1/3 (genera .bcf para Biber)...")
local sentinel1 = ruta_latex .. "/.pdfa-sentinel-1"
os.remove(sentinel1)
os.execute("cd \"" .. ruta_latex .. "\" && lualatex" ..
           " -interaction=nonstopmode" ..
           " \"" .. ruta_tex_tmp .. "\"" ..
           " ; touch \"" .. sentinel1 .. "\"")
local fs1 = io.open(sentinel1, "r")
if not fs1 then
  print("✗ Error fatal en la pasada 1: LuaLaTeX no completó la ejecución")
  os.remove(ruta_tex_tmp)
  os.remove(ruta_xmpdata)
  os.exit(1)
end
fs1:close()
os.remove(sentinel1)

-- --- BIBER ---
print("  Procesando bibliografía con Biber...")
os.execute("cd \"" .. ruta_latex .. "\" && biber \"" .. nombre_pdfa .. "\"")

-- --- PASADAS 2 Y 3 ---
for i = 2, COMPILACIONES do
  print("  Pasada " .. i .. "/3...")
  local sentinel = ruta_latex .. "/.pdfa-sentinel-" .. i
  os.remove(sentinel)
  os.execute("cd \"" .. ruta_latex .. "\" && lualatex" ..
             " -interaction=nonstopmode" ..
             " \"" .. ruta_tex_tmp .. "\"" ..
             " ; touch \"" .. sentinel .. "\"")
  local fs = io.open(sentinel, "r")
  if not fs then
    print("✗ Error fatal en la pasada " .. i .. ": LuaLaTeX no completó la ejecución")
    os.remove(ruta_tex_tmp)
    os.remove(ruta_xmpdata)
    os.exit(1)
  end
  fs:close()
  os.remove(sentinel)
end

print("✓ Compilación completada")

-- ============================================================
-- VERIFICAR QUE SE GENERÓ EL PDF
-- ============================================================
local f_pdf = io.open(ruta_pdf_tmp, "r")
if not f_pdf then
  print("✗ Error: LuaLaTeX no generó el PDF esperado: " .. ruta_pdf_tmp)
  os.remove(ruta_tex_tmp)
  os.remove(ruta_xmpdata)
  os.exit(1)
end
f_pdf:close()

-- ============================================================
-- MOVER EL PDF AL DIRECTORIO DE SALIDAS
-- SE GUARDA COMO l-*-pdfa.pdf PARA NO REEMPLAZAR EL PDF DE TRABAJO.
-- ============================================================
local ok_mv = os.rename(ruta_pdf_tmp, ruta_pdf_final)
if not ok_mv then
  -- os.rename PUEDE FALLAR ENTRE SISTEMAS DE ARCHIVOS — USAR cp
  local ok_cp = os.execute(
    "cp \"" .. ruta_pdf_tmp .. "\" \"" .. ruta_pdf_final .. "\"")
  if not ok_cp then
    print("✗ Error: no se pudo copiar el PDF al directorio de salidas")
    os.remove(ruta_tex_tmp)
    os.remove(ruta_xmpdata)
    os.exit(1)
  end
  os.remove(ruta_pdf_tmp)
end

print("✓ PDF/A-2b guardado: " .. ruta_pdf_final)

-- ============================================================
-- LIMPIAR ARCHIVOS TEMPORALES
-- SE ELIMINAN TODOS LOS AUXILIARES GENERADOS POR LA COMPILACIÓN
-- DEL ARCHIVO -pdfa.tex, INCLUYENDO EL .xmpdata YA PROCESADO.
-- ============================================================
local extensiones_tmp = {
  "aux", "log", "out", "toc", "bbl", "bcf", "blg", "run.xml", "xmpdata"
}
local base_tmp = ruta_latex .. "/l-" .. nombre_base .. "-pdfa"

for _, ext in ipairs(extensiones_tmp) do
  os.remove(base_tmp .. "." .. ext)
end
os.remove(ruta_tex_tmp)

print("✓ Archivos temporales eliminados")
print("✓ Script completado — PDF/A-2b listo para archivo en repositorios")
