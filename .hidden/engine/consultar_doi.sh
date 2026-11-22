#!/bin/bash
# Consultas por DOI y por título a Crossref, OpenCitations y OpenAIRE — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   consultar_doi.sh analisis <doi>    <salida.tsv>
#   consultar_doi.sh crossref <doi>    <salida.tsv>
#   consultar_doi.sh titulo   <título> <salida.tsv>
#
#   analisis  el informe de FAnalizarDOI: Crossref, más las citas de
#             OpenCitations y la presencia en OpenAIRE. Dos columnas por
#             línea: dato TAB valor, en el orden en que se muestran.
#   crossref  los datos de Crossref que FMain compara con la ficha de
#             bibtex (btnChequearCrossref). Dos columnas: clave TAB valor,
#             con las claves de FEstructuraResultados.cValoresAplicar
#             (doi, titulo, anio, paginas, issn, autor). Un dato que
#             Crossref no tiene va vacío.
#   titulo    hasta cinco candidatos de Crossref para un título
#             (btnCrossrefTitulo). Siete columnas: score, tipo, DOI,
#             título, año, primer autor, revista.
#
#   El DOI puede venir como https://doi.org/…, http://dx.doi.org/… o doi:…:
#   el script lo normaliza y lo controla. La salida se escribe completa o no
#   se escribe: se arma en un temporal y se mueve al final.
#
# QUÉ REEMPLAZA (21/11/2026)
#   Las consultas que hacían FAnalizarDOI y FMain con Shell: el DOI y el
#   título llegaban a sh -c entre comillas simples, sin escapar; la URL de
#   la grilla de FAnalizarDOI, que viene de los servicios, se abría con
#   Shell "xdg-open '…'"; FMain usaba nombres fijos en /tmp y python3 -c
#   armado como string, y leía el JSON a mano (SC-13, criterio 2: el script
#   busca y normaliza, Gambas muestra y compara con la base).
#
# LOS SERVICIOS
#   - Crossref: /works/{doi} y /works?query.bibliographic=…. query.title,
#     que usaba la búsqueda por título, está bloqueado desde 2019.
#     Sin mailto: cada instalación se presentaría con un mismo correo.
#   - OpenCitations: /index/v2/citation-count/doi:{doi}, que devuelve
#     [{"count": "N"}]. Reemplaza a /index/api/v1/citations, que bajaba
#     todas las citas para contarlas.
#   - OpenAIRE: /search/publications?doi=…&format=json.
#   Si Crossref no responde o no tiene el DOI, la consulta falla. Si fallan
#   OpenCitations u OpenAIRE, la fila dice «(sin respuesta)» y es un aviso.
#
# CÓDIGOS: los de comun.sh
#   0  la consulta terminó y la salida está escrita
#   3  avisos: un servicio secundario no respondió, o la búsqueda por
#      título no encontró nada (la salida queda vacía)
#   1  no se pudo: falta curl o python3, el DOI no tiene forma de DOI,
#      Crossref no responde o no tiene el DOI
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
# EL AGENTE IDENTIFICA A LA APLICACIÓN, NO A QUIEN LA USA (SIN mailto)
AGENTE="gbpublisher (https://github.com/albertomoyano/gbpublisher)"
URL_CROSSREF="https://api.crossref.org/works"
URL_OPENCITATIONS="https://api.opencitations.net/index/v2/citation-count/doi:"
URL_OPENAIRE="https://api.openaire.eu/search/publications"

# ============================================================================
# Función   : codificar_url
# Propósito : Codifica un texto para una URL, byte por byte (UTF-8).
# Parámetros: $1 — el texto; $2 — caracteres que quedan sin codificar,
#             además de las letras, los dígitos y «-._~» (opcional)
# Retorna   : el texto codificado, por stdout
# ============================================================================
codificar_url() {
    local LC_ALL=C
    local texto="$1" seguros="${2:-}" i c salida=""
    for (( i = 0; i < ${#texto}; i++ )); do
        c="${texto:i:1}"
        # LETRAS, DÍGITOS Y LOS CUATRO NO RESERVADOS DE RFC 3986 VAN TAL CUAL
        if [[ "$c" == [a-zA-Z0-9.~_-] ]] || [[ -n "$seguros" && "$seguros" == *"$c"* ]]; then
            salida+="$c"
        else
            printf -v c '%%%02X' "'$c"
            salida+="$c"
        fi
    done
    printf '%s' "$salida"
}

# ============================================================================
# Función   : consultar
# Propósito : Baja una URL a un archivo y devuelve el código HTTP.
# Parámetros: $1 — la URL; $2 — el archivo donde queda la respuesta
# Retorna   : el código HTTP por stdout; «000» si curl no llegó al servidor
#             (el motivo de curl queda en $TMP/curl.err)
# ============================================================================
consultar() {
    local url="$1" archivo="$2" codigo
    # SIN sh -c: LA URL ES UN ARGUMENTO. curl NO PREGUNTA NADA (SC-53, MODAL)
    codigo="$(curl -sS -L --connect-timeout 10 --max-time 20 \
        -A "$AGENTE" -H 'Accept: application/json' \
        -o "$archivo" -w '%{http_code}' "$url" 2>"$TMP/curl.err")"
    if [[ $? -ne 0 || -z "$codigo" ]]; then
        codigo="000"
    fi
    printf '%s' "$codigo"
}

# ============================================================================
# Función   : motivo_curl
# Propósito : Muestra en tenue el motivo de curl, si lo dejó.
# ============================================================================
motivo_curl() {
    if [[ -s "$TMP/curl.err" ]]; then
        tenue "$(head -n 1 "$TMP/curl.err")"
    fi
}

# ============================================================================
# Función   : consultar_crossref_doi
# Propósito : Baja el registro del DOI de Crossref a $TMP/crossref.json.
#             Muere si Crossref no lo tiene o no responde.
# ============================================================================
consultar_crossref_doi() {
    local codigo
    paso "Crossref"
    codigo="$(consultar "$URL_CROSSREF/$(codificar_url "$DOI")" "$TMP/crossref.json")"
    case "$codigo" in
        200) ok "Crossref tiene el DOI $DOI" ;;
        404) morir "El DOI no existe en Crossref: $DOI. Verificá que esté bien escrito." ;;
        000) motivo_curl
             morir "No se pudo llegar a Crossref. Verificá la conexión a internet." ;;
        *)   morir "Crossref respondió con un error (HTTP $codigo). Probá de nuevo más tarde." ;;
    esac
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

# --- 2. ARGUMENTOS ---
if (( $# != 3 )); then
    encabezado "CONSULTA A CROSSREF"
    morir "Uso: $(basename "$0") analisis|crossref|titulo <doi o título> <salida.tsv>"
fi

MODO="$1"
VALOR="$2"
SALIDA="$3"

case "$MODO" in
    analisis) encabezado "ANÁLISIS DE UN DOI" ;;
    crossref) encabezado "VERIFICACIÓN EN CROSSREF" ;;
    titulo)   encabezado "BÚSQUEDA EN CROSSREF POR TÍTULO" ;;
    *)        encabezado "CONSULTA A CROSSREF"
              morir "Modo desconocido: $MODO (analisis, crossref o titulo)" ;;
esac

requerir_comandos curl python3

# --- 3. LA SALIDA ---
# UNA SALIDA VIEJA NO PUEDE PASAR POR EL RESULTADO DE ESTA CONSULTA
[[ -d "$(dirname "$SALIDA")" ]] || morir "No existe la carpeta de la salida: $(dirname "$SALIDA")"
rm -f "$SALIDA"
SALIDA_TMP="$SALIDA.tmp"

TMP="$(mktemp -d)" || morir "No se pudo crear la carpeta temporal"
trap 'rm -rf "$TMP" "$SALIDA_TMP"' EXIT

# --- 4. EL DOI O EL TÍTULO ---
# LOS MODOS POR DOI ACEPTAN LAS FORMAS EN QUE SE PEGA UN DOI
DOI=""
TITULO=""
if [[ "$MODO" != "titulo" ]]; then
    DOI="$(printf '%s' "$VALOR" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s#^https?://(dx\.)?doi\.org/##I; s/^doi:[[:space:]]*//I')"
    # LA FORMA DE UN DOI: 10., EL PREFIJO NUMÉRICO, BARRA Y UN SUFIJO SIN ESPACIOS
    if [[ ! "$DOI" =~ ^10\.[0-9]{4,}(\.[0-9]+)*/[^[:space:]]+$ ]]; then
        morir "No tiene forma de DOI: «$VALOR». Un DOI empieza con 10. y tiene una barra, como 10.1234/abcd."
    fi
    tenue "DOI: $DOI"
else
    TITULO="$(printf '%s' "$VALOR" | tr '\t\n\r' '   ' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [[ -n "$TITULO" ]] || morir "Falta el título para buscar"
fi

# --- 5. LAS CONSULTAS ---
OC_OK=0
OA_OK=0

case "$MODO" in
    analisis)
        consultar_crossref_doi

        # OPENCITATIONS: LA BARRA DEL DOI VA SIN CODIFICAR, COMO EN SU
        # DOCUMENTACIÓN (doi:10.1108/jd-12-2013-0166)
        paso "OpenCitations"
        CODIGO="$(consultar "$URL_OPENCITATIONS$(codificar_url "$DOI" "/")" "$TMP/opencitations.json")"
        if [[ "$CODIGO" == "200" ]]; then
            OC_OK=1
            ok "OpenCitations respondió"
        else
            motivo_curl
            aviso "OpenCitations no respondió (HTTP $CODIGO): las citas quedan sin dato"
        fi

        paso "OpenAIRE"
        CODIGO="$(consultar "$URL_OPENAIRE?doi=$(codificar_url "$DOI")&format=json" "$TMP/openaire.json")"
        if [[ "$CODIGO" == "200" ]]; then
            OA_OK=1
            ok "OpenAIRE respondió"
        else
            motivo_curl
            aviso "OpenAIRE no respondió (HTTP $CODIGO): la presencia queda sin dato"
        fi
        ;;

    crossref)
        consultar_crossref_doi
        ;;

    titulo)
        paso "Crossref"
        tenue "Título: $TITULO"
        # query.bibliographic: query.title ESTÁ BLOQUEADO EN CROSSREF DESDE 2019
        CODIGO="$(consultar "$URL_CROSSREF?rows=5&query.bibliographic=$(codificar_url "$TITULO")" "$TMP/crossref.json")"
        case "$CODIGO" in
            200) ok "Crossref respondió" ;;
            000) motivo_curl
                 morir "No se pudo llegar a Crossref. Verificá la conexión a internet." ;;
            *)   morir "Crossref respondió con un error (HTTP $CODIGO). Probá de nuevo más tarde." ;;
        esac
        ;;
esac

# --- 6. LA SALIDA EN TSV ---
# python3 LEE LOS JSON (EL JSON NO SE INTERPRETA EN bash) Y ESCRIBE EL TSV.
# CADA VALOR SALE EN UNA SOLA LÍNEA Y SIN TABULADORES, CON LAS ENTIDADES
# HTML RESUELTAS. LA ÚLTIMA LÍNEA NO LLEVA SALTO: UN VALOR VACÍO AL FINAL
# SIGUE SIENDO UNA COLUMNA
paso "Resultado"
VALOR_PY="$DOI"
[[ "$MODO" == "titulo" ]] && VALOR_PY="$TITULO"

if ! FILAS="$(python3 - "$MODO" "$VALOR_PY" "$TMP" "$OC_OK" "$OA_OK" "$SALIDA_TMP" 2>"$TMP/python.err" <<'PY'
import html
import json
import os
import re
import sys
import urllib.parse

modo, valor, carpeta, oc_ok, oa_ok, salida = sys.argv[1:7]

def leer(nombre):
    with open(os.path.join(carpeta, nombre), encoding="utf-8") as f:
        return json.load(f)

def limpio(v):
    # UNA LÍNEA, SIN TABULADORES, SIN ENTIDADES
    if v is None:
        return ""
    v = html.unescape(str(v))
    return re.sub(r"\s+", " ", v).strip()

def primero(lista):
    if isinstance(lista, list) and lista:
        return lista[0]
    return ""

def fecha_partes(nodo):
    # [[año, mes, día]] DE CROSSREF A d/m/aaaa, CON LO QUE HAYA
    try:
        partes = [p for p in nodo["date-parts"][0] if p is not None]
    except (KeyError, IndexError, TypeError):
        return ""
    if not partes:
        return ""
    return "/".join(str(int(p)) for p in reversed(partes))

def anio(m):
    for clave in ("published", "issued"):
        try:
            a = m[clave]["date-parts"][0][0]
            if a is not None:
                return str(int(a))
        except (KeyError, IndexError, TypeError, ValueError):
            pass
    return ""

def fecha_iso(nodo):
    # 2023-06-01T21:13:59Z A 01/06/2023 21:13 UTC
    try:
        s = nodo["date-time"]
    except (KeyError, TypeError):
        return ""
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})", s or "")
    if not m:
        return limpio(s)
    return "%s/%s/%s %s:%s UTC" % (m.group(3), m.group(2), m.group(1), m.group(4), m.group(5))

def primer_autor(m):
    autores = m.get("author") or []
    if not autores:
        return ""
    a = autores[0]
    familia, nombre = limpio(a.get("family")), limpio(a.get("given"))
    if familia and nombre:
        return familia + ", " + nombre
    return familia or nombre or limpio(a.get("name"))

filas = []

if modo == "analisis":
    m = leer("crossref.json").get("message", {})
    def fila(dato, v):
        v = limpio(v)
        filas.append((dato, v if v else "(no disponible)"))

    fila("DOI", m.get("DOI"))
    fila("Tipo", m.get("type"))
    fila("Título", primero(m.get("title")) or "(sin título)")

    autores = m.get("author") or []
    nombres = []
    con_orcid = 0
    for a in autores:
        n = " ".join(x for x in (limpio(a.get("given")), limpio(a.get("family"))) if x) or limpio(a.get("name"))
        if a.get("ORCID"):
            con_orcid += 1
            n += " [ORCID ✓]"
        nombres.append(n)
    fila("Autores", " / ".join(nombres))
    fila("ORCID en CrossRef", "%d de %d autores tienen ORCID declarado en CrossRef" % (con_orcid, len(autores)))

    if primero(m.get("container-title")):
        fila("Revista", primero(m.get("container-title")))
    if m.get("ISSN"):
        fila("ISSN", " / ".join(limpio(x) for x in m["ISSN"]))
    if m.get("issued"):
        fila("Fecha de publicación", fecha_partes(m["issued"]) or "(fecha no disponible)")
    if m.get("created"):
        fila("Primer depósito CrossRef", fecha_iso(m["created"]))
    if m.get("deposited"):
        fila("Último depósito CrossRef", fecha_iso(m["deposited"]))
    fila("URL", m.get("URL"))

    licencias = m.get("license") or []
    lic = licencias[0].get("URL") if licencias and isinstance(licencias[0], dict) else ""
    fila("Licencia", lic or "(no declarada en CrossRef)")
    fila("Citado por (CrossRef)", str(m.get("is-referenced-by-count", 0)))
    fila("Referencias incluidas", str(m.get("reference-count", 0)))
    fila("Resumen en CrossRef", "Sí" if m.get("abstract") else "No")

    # OPENCITATIONS v2: [{"count": "N"}]
    citas = "(sin respuesta)"
    if oc_ok == "1":
        try:
            citas = str(int(leer("opencitations.json")[0]["count"]))
        except (ValueError, KeyError, IndexError, TypeError):
            citas = "(respuesta ilegible)"
    fila("Citas en OpenCitations", citas)

    # OPENAIRE: response.header.total, QUE LLEGA COMO {"$": N} O COMO N
    presencia = "(sin respuesta)"
    if oa_ok == "1":
        try:
            total = leer("openaire.json")["response"]["header"]["total"]
            if isinstance(total, dict):
                total = total.get("$", 0)
            total = int(total)
            presencia = "Sí (%d resultado/s)" % total if total > 0 else "No encontrado"
        except (ValueError, KeyError, TypeError):
            presencia = "(respuesta ilegible)"
    fila("OpenAIRE", presencia)

    fila("Google Scholar", "https://scholar.google.com/scholar?q=" + urllib.parse.quote(valor, safe=""))

elif modo == "crossref":
    m = leer("crossref.json").get("message", {})
    issn = m.get("ISSN") or []
    # EL PRIMER ISSN: EL VALOR TIENE QUE SER COMPARABLE Y APLICABLE A UN CAMPO
    filas = [
        ("doi", limpio(m.get("DOI"))),
        ("titulo", limpio(primero(m.get("title")))),
        ("anio", anio(m)),
        ("paginas", limpio(m.get("page"))),
        ("issn", limpio(issn[0]) if issn else ""),
        ("autor", primer_autor(m)),
    ]

elif modo == "titulo":
    tipos = {
        "journal-article": "Artículo",
        "book": "Libro",
        "book-chapter": "Capítulo",
        "proceedings-article": "Congreso",
        "posted-content": "Preprint",
        "dissertation": "Tesis",
        "report": "Informe",
        "dataset": "Dataset",
    }
    for i in (leer("crossref.json").get("message", {}).get("items") or [])[:5]:
        try:
            score = "%.1f" % float(i.get("score", 0))
        except (TypeError, ValueError):
            score = ""
        filas.append((
            score,
            tipos.get(i.get("type", ""), limpio(i.get("type"))),
            limpio(i.get("DOI")),
            limpio(primero(i.get("title"))),
            anio(i),
            primer_autor(i),
            limpio(primero(i.get("container-title"))),
        ))

with open(salida, "w", encoding="utf-8") as f:
    f.write("\n".join("\t".join(c) for c in filas))

print(len(filas))
PY
)"; then
    tenue "$(tail -n 1 "$TMP/python.err")"
    morir "No se pudo interpretar la respuesta de los servicios"
fi

mv -f "$SALIDA_TMP" "$SALIDA" || morir "No se pudo escribir la salida: $SALIDA"

if [[ "$MODO" == "titulo" && "$FILAS" == "0" ]]; then
    aviso "Crossref no encontró resultados para ese título"
else
    ok "$FILAS fila(s) en $(basename "$SALIDA")"
fi

terminar
