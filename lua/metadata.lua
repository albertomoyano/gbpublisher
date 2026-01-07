-- Cargar dkjson desde files/
local dkjson_path = kpse.find_file("files/dkjson.lua")
if not dkjson_path then
  tex.print("\\PackageError{metadata}{No se encontró files/dkjson.lua}")
  return
end
local json = dofile(dkjson_path)

local function escape_tex(str)
  if not str then return "" end
  str = string.gsub(str, "\\", "\\textbackslash ")
  str = string.gsub(str, "([#$%%&_{}])", "\\%1")
  str = string.gsub(str, "~", "\\textasciitilde ")
  str = string.gsub(str, "%^", "\\textasciicircum ")
  return str
end

function load_metadata(jsonfile)
  -- jsonfile puede ser nil; intentar localizar con kpse
  local path = jsonfile
  if not path then
    path = kpse.find_file("files/metadata.json") or kpse.find_file("metadata.json")
  end

  if not path then
    -- Como último recurso: intentar construir ruta relativa al directorio de trabajo
    local cwd = io.popen("pwd"):read("*l")
    local candidate = cwd .. "/files/metadata.json"
    local f = io.open(candidate, "r")
    if f then
      f:close()
      path = candidate
    end
  end

  if not path then
    tex.print("\\PackageError{metadata}{No se encontró metadata.json (buscado en kpse y directorio actual)}")
    return {}
  end

  local f, err = io.open(path, "r")
  if not f then
    tex.print("\\PackageError{metadata}{No se pudo abrir " .. path .. ": " .. (err or "") .. "}")
    return {}
  end
  local content = f:read("*all")
  f:close()

  local obj, pos, decode_err = json.decode(content, 1, nil)
  if decode_err then
    tex.print("\\PackageError{metadata}{JSON inválido: " .. decode_err .. "}")
    return {}
  end
  return obj or {}
end

function inject_pdf_metadata(meta)
  tex.print("\\hypersetup{")
  tex.print("  pdftitle={" .. escape_tex(meta.title or "") .. "},")
  tex.print("  pdfauthor={" .. escape_tex(meta.authors or "") .. "},")
  tex.print("  pdfsubject={" .. escape_tex(meta.subject or "") .. "},")
  tex.print("  pdfkeywords={" .. escape_tex(meta.keywords or "") .. "},")
  tex.print("  pdflang={" .. (meta.language or "es") .. "},")
  tex.print("  pdfinfo={")
  if meta.doi then tex.print("    DOI={" .. escape_tex(meta.doi) .. "},") end
  if meta.isbn then tex.print("    ISBN={" .. escape_tex(meta.isbn) .. "},") end
  if meta.isbn13 then tex.print("    ISBN13={" .. escape_tex(meta.isbn13) .. "},") end
  tex.print("  },")
  tex.print("}")
end
