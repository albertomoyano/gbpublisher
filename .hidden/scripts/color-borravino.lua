#!/usr/bin/env lua
-- Script: cambio de color azulrevista → borravino
-- Reemplaza el color azul corporativo por borravino (722F37)
-- Preserva el .tex original — trabaja sobre una copia temporal
-- Recompila y reemplaza el PDF final

-- ==============================================================
-- CONSTANTES
-- ==============================================================
local COLOR_ORIGINAL = "\\definecolor{azulrevista}{HTML}{2d5a8e}"
local COLOR_NUEVO    = "\\definecolor{azulrevista}{HTML}{722F37}"
local COMPILACIONES  = 3   -- LUALATEX REQUIERE MÚLTIPLES PASADAS

-- ==============================================================
-- VERIFICAR ARGUMENTOS
-- arg[1] = ruta del .gbp (contexto del proyecto)
-- arg[2] = ruta del .md activo
-- ==============================================================
if not arg[2] then
  print("✗ Error: no se recibió el archivo activo como argumento")
  os.exit(1)
end

local ruta_md = arg[2]
print("DEBUG match: " .. tostring(ruta_md:match("^(.+)/articulos/")))
print("→ Archivo activo: " .. ruta_md)

-- ==============================================================
-- DERIVAR RUTAS DESDE EL .md
-- /proyecto/articulos/a-02-revista.md → /proyecto/latex/l-02-revista.tex
-- ==============================================================
-- DERIVAR RUTAS DESDE EL .md
local nombre_archivo = ruta_md:match("([^/]+)$")
local nombre_base = nombre_archivo and nombre_archivo:match("^..(.+)%.md$")
local ruta_proyecto  = ruta_md:match("^(.+)/articulos/")

if not ruta_proyecto or not nombre_base then
  print("✗ Error: no se pudo derivar la ruta del proyecto desde: " .. ruta_md)
  print("  nombre_archivo: " .. tostring(nombre_archivo))
  print("  nombre_base:    " .. tostring(nombre_base))
  print("  ruta_proyecto:  " .. tostring(ruta_proyecto))
  os.exit(1)
end

local ruta_latex    = ruta_proyecto .. "/latex"
local ruta_tex      = ruta_latex .. "/l-" .. nombre_base .. ".tex"
local ruta_tex_tmp  = ruta_latex .. "/l-" .. nombre_base .. "-script.tex"
local ruta_pdf_orig = ruta_proyecto .. "/salidas/pdf/l-" .. nombre_base .. ".pdf"
local ruta_pdf_tmp  = ruta_latex .. "/l-" .. nombre_base .. "-script.pdf"

print("→ Archivo .tex:  " .. ruta_tex)
print("→ PDF destino:   " .. ruta_pdf_orig)

-- ==============================================================
-- VERIFICAR QUE EL .tex EXISTE
-- ==============================================================
local f = io.open(ruta_tex, "r")
if not f then
  print("✗ Error: no se encontró el archivo .tex: " .. ruta_tex)
  os.exit(1)
end

-- ==============================================================
-- LEER EL CONTENIDO DEL .tex ORIGINAL
-- ==============================================================
local contenido = f:read("*all")
f:close()

-- ==============================================================
-- VERIFICAR QUE EL COLOR ORIGINAL EXISTE EN EL ARCHIVO
-- ==============================================================
if not contenido:find(COLOR_ORIGINAL, 1, true) then
  print("✗ Error: no se encontró la definición del color azulrevista")
  print("  Buscado: " .. COLOR_ORIGINAL)
  os.exit(1)
end

-- ==============================================================
-- APLICAR EL CAMBIO DE COLOR
-- SOLO SE REEMPLAZA LA LÍNEA DE DEFINICIÓN
-- TODAS LAS REFERENCIAS A azulrevista SE ACTUALIZAN AUTOMÁTICAMENTE
-- ==============================================================
local contenido_modificado = contenido:gsub(
  COLOR_ORIGINAL:gsub("[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1"),
  COLOR_NUEVO,
  1
)

print("✓ Color reemplazado: azulrevista 2d5a8e → borravino 722F37")

-- ==============================================================
-- GUARDAR EL ARCHIVO TEMPORAL .tex
-- EL ORIGINAL QUEDA INTACTO
-- ==============================================================
local out = io.open(ruta_tex_tmp, "w")
if not out then
  print("✗ Error: no se pudo escribir el archivo temporal: " .. ruta_tex_tmp)
  os.exit(1)
end
out:write(contenido_modificado)
out:close()

print("✓ Archivo temporal generado: " .. ruta_tex_tmp)

-- ==============================================================
-- COMPILAR CON LUALATEX
-- SE REQUIEREN MÚLTIPLES PASADAS PARA REFERENCIAS Y CABECERAS
-- ==============================================================
print("→ Compilando con LuaLaTeX (" .. COMPILACIONES .. " pasadas)...")

for i = 1, COMPILACIONES do
  print("  Pasada " .. i .. "/" .. COMPILACIONES .. "...")
  local cmd = "cd \"" .. ruta_latex .. "\" && lualatex" ..
    " -interaction=nonstopmode" ..
    " \"" .. ruta_tex_tmp .. "\""
  local ok = os.execute(cmd)
  if not ok then
    print("✗ Error en la pasada " .. i .. " de LuaLaTeX")
    os.remove(ruta_tex_tmp)
    os.exit(1)
  end
end

print("✓ Compilación completada")

-- ==============================================================
-- VERIFICAR QUE SE GENERÓ EL PDF TEMPORAL
-- ==============================================================
local f_pdf = io.open(ruta_pdf_tmp, "r")
if not f_pdf then
  print("✗ Error: LuaLaTeX no generó el PDF esperado: " .. ruta_pdf_tmp)
  os.remove(ruta_tex_tmp)
  os.exit(1)
end
f_pdf:close()

-- ==============================================================
-- REEMPLAZAR EL PDF ORIGINAL CON EL NUEVO
-- ==============================================================
local ok_mv = os.rename(ruta_pdf_tmp, ruta_pdf_orig)
if not ok_mv then
  -- os.rename PUEDE FALLAR ENTRE DISPOSITIVOS — INTENTAR CON cp + rm
  local ok_cp = os.execute("cp \"" .. ruta_pdf_tmp .. "\" \"" .. ruta_pdf_orig .. "\"")
  if not ok_cp then
    print("✗ Error: no se pudo reemplazar el PDF original")
    os.remove(ruta_tex_tmp)
    os.exit(1)
  end
  os.remove(ruta_pdf_tmp)
end

print("✓ PDF reemplazado: " .. ruta_pdf_orig)

-- ==============================================================
-- LIMPIAR ARCHIVOS TEMPORALES DE COMPILACIÓN
-- .aux .log .out .toc generados por la compilación del -script.tex
-- ==============================================================
local extensiones_tmp = {"aux", "log", "out", "toc", "bbl", "bcf", "blg", "run.xml"}
local base_tmp = ruta_latex .. "/l-" .. nombre_base .. "-script"

for _, ext in ipairs(extensiones_tmp) do
  os.remove(base_tmp .. "." .. ext)
end
os.remove(ruta_tex_tmp)

print("✓ Archivos temporales eliminados")
print("✓ Script completado — PDF con color borravino listo")
