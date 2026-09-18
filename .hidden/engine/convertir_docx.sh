#!/bin/bash
# ============================================================================
# Script     : convertir_docx.sh
# Propósito  : Convierte un .docx a Markdown según el contrato de ingreso de
#              gbpublisher y lo incorpora al proyecto: texto, original, informe
#              e imágenes. Todo se prepara en un directorio temporal dentro del
#              proyecto y se confirma al final con mv (atómico en el mismo
#              sistema de archivos): si algo falla antes, el proyecto no se toca.
# Uso        : bash convertir_docx.sh ORIGEN RAIZ SUBCARPETA NOMBRE
#                ORIGEN     ruta absoluta del .docx
#                RAIZ       carpeta raíz del proyecto
#                SUBCARPETA front-matter | articulos | back-matter
#                NOMBRE     nombre con prefijo, p. ej. a-01-INTRODUCCION
# Salidas    : RAIZ/SUBCARPETA/NOMBRE.md
#              RAIZ/originales/NOMBRE.docx
#              RAIZ/originales/NOMBRE.txt   (informe TSV)
#              RAIZ/media/NOMBRE_imagenN.ext
# Códigos    : 0 conversión completa
#              10 argumentos inválidos
#              11 dependencia ausente (pandoc >= 3.1.3, python3 o el filtro)
#              20 falló pandoc (83 = fallo del filtro)
#              30 falló la normalización NFC
#              40 falló una escritura en el proyecto (copia, reemplazo)
#              50 falló el armado del informe
# Invocado   : desde FConversorDOCX2MD con TerminalView.Exec, sin shell
#              intermedio. No pregunta nada ni lee stdin.
# Ubicación  : engine/ — NO se copia a ~/.gbpublisher (SC-11).
# ============================================================================

set -u

readonly VERSION_PANDOC_MINIMA="3.1.3"
DIR_ENGINE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DIR_ENGINE
readonly FILTRO="$DIR_ENGINE/limpiar_docx.lua"

DIR_TRABAJO=""

# ============================================
# Función   : etapa
# Propósito : Canal humano: anuncia una etapa en la terminal
# Parámetros: $1 — número de etapa; $2 — descripción
# Retorna   : nada
# ============================================
etapa() {
  printf '\n[%s/6] %s\n' "$1" "$2"
}

# ============================================
# Función   : fallar
# Propósito : Informa el error en la terminal y sale con el código de la tabla.
#             El trap de salida borra el directorio temporal
# Parámetros: $1 — código de salida; $2 — motivo
# Retorna   : no retorna
# ============================================
fallar() {
  printf '\nERROR (código %s): %s\n' "$1" "$2"
  exit "$1"
}

# ============================================
# Función   : limpiar_temporal
# Propósito : Borra el directorio de trabajo en cualquier salida, también ante
#             Ctrl+C. No corre ante SIGKILL: por eso la etapa 1 barre restos
# Parámetros: ninguno
# Retorna   : nada
# ============================================
limpiar_temporal() {
  if [ -n "$DIR_TRABAJO" ] && [ -d "$DIR_TRABAJO" ]; then
    rm -rf -- "$DIR_TRABAJO"
  fi
}

trap limpiar_temporal EXIT

# --- 1. VALIDACIÓN DE ARGUMENTOS Y DEPENDENCIAS ---
etapa 1 "Validando argumentos y dependencias"

if [ "$#" -ne 4 ]; then
  fallar 10 "se esperaban 4 argumentos y llegaron $#"
fi

ORIGEN="$1"
RAIZ="$2"
SUBCARPETA="$3"
NOMBRE="$4"

# RUTAS ABSOLUTAS: EL SCRIPT CAMBIA DE DIRECTORIO DE TRABAJO MÁS ADELANTE
case "$ORIGEN" in
  /*) ;;
  *) fallar 10 "la ruta de origen no es absoluta" ;;
esac

case "$RAIZ" in
  /*) ;;
  *) fallar 10 "la raíz del proyecto no es absoluta" ;;
esac

if [ ! -f "$ORIGEN" ] || [ ! -r "$ORIGEN" ]; then
  fallar 10 "el archivo de origen no existe o no se puede leer"
fi

# LA EXTENSIÓN SE COMPARA SIN DISTINGUIR CAJA: .DOCX DE WINDOWS ES VÁLIDO
case "${ORIGEN,,}" in
  *.docx) ;;
  *) fallar 10 "el archivo de origen no es .docx" ;;
esac

if [ ! -d "$RAIZ" ] || [ ! -w "$RAIZ" ]; then
  fallar 10 "la raíz del proyecto no es un directorio con permiso de escritura"
fi

# EL PREFIJO DEL NOMBRE DEBE CORRESPONDER A LA SUBCARPETA
case "$SUBCARPETA" in
  front-matter) PREFIJO_ESPERADO="fm" ;;
  articulos)    PREFIJO_ESPERADO="a" ;;
  back-matter)  PREFIJO_ESPERADO="bm" ;;
  *) fallar 10 "subcarpeta desconocida: $SUBCARPETA" ;;
esac

# SOLO MAYÚSCULAS, DÍGITOS Y GUION: EL "_" QUEDA RESERVADO PARA LAS IMÁGENES
if [[ ! "$NOMBRE" =~ ^(fm|a|bm)-[0-9]{2}-[A-Z0-9-]+$ ]]; then
  fallar 10 "nombre inválido: $NOMBRE"
fi

if [ "${BASH_REMATCH[1]}" != "$PREFIJO_ESPERADO" ]; then
  fallar 10 "el prefijo de $NOMBRE no corresponde a $SUBCARPETA"
fi

if [ ! -r "$FILTRO" ]; then
  fallar 11 "no se encuentra el filtro: $FILTRO"
fi

if ! command -v python3 >/dev/null 2>&1; then
  fallar 11 "python3 no está instalado"
fi

if ! command -v pandoc >/dev/null 2>&1; then
  fallar 11 "pandoc no está instalado"
fi

VERSION_PANDOC="$(pandoc --version 2>/dev/null | head -n 1 | cut -d ' ' -f 2)"

# sort -V -C TIENE ÉXITO SI LA LISTA YA ESTÁ ORDENADA: MÍNIMA <= INSTALADA
if ! printf '%s\n%s\n' "$VERSION_PANDOC_MINIMA" "$VERSION_PANDOC" | sort -V -C; then
  fallar 11 "pandoc $VERSION_PANDOC es menor que la mínima $VERSION_PANDOC_MINIMA"
fi

printf '  origen : %s\n' "$ORIGEN"
printf '  destino: %s/%s.md\n' "$SUBCARPETA" "$NOMBRE"
printf '  pandoc : %s\n' "$VERSION_PANDOC"

# RESTOS DE UNA CONVERSIÓN MATADA CON SIGKILL, DONDE EL TRAP NO CORRE
rm -rf -- "$RAIZ"/.convertir_docx.*

DIR_TRABAJO="$(mktemp -d "$RAIZ/.convertir_docx.XXXXXX")" || fallar 40 "no se pudo crear el directorio temporal en el proyecto"

cd -- "$DIR_TRABAJO" || fallar 40 "no se pudo entrar al directorio temporal"

# SE TRABAJA SOBRE UNA COPIA: EL HASH, LA CONVERSIÓN Y EL ARCHIVADO
# CORRESPONDEN EXACTAMENTE A LOS MISMOS BYTES
cp -- "$ORIGEN" original.docx || fallar 40 "no se pudo copiar el original al directorio temporal"

# --- 2. CAMBIOS CONTROLADOS, COMENTARIOS Y ESTILOS DEL WORD ---
# PANDOC ACEPTA LOS CAMBIOS ANTES DEL FILTRO, ASÍ QUE SE CUENTAN EN EL XML.
# SE CUENTAN MARCAS (w:ins, w:del), NO PALABRAS. UN FALLO ACÁ NO DETIENE LA
# CONVERSIÓN: SI EL .docx ESTÁ ROTO, PANDOC LO REPORTA EN LA ETAPA 3
etapa 2 "Revisando cambios controlados, comentarios y estilos"

python3 - original.docx docx.tsv 2> error_docx.txt <<'PY'
import collections
import sys
import xml.etree.ElementTree as ET
import zipfile

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
ruta, salida = sys.argv[1], sys.argv[2]

with zipfile.ZipFile(ruta) as z:
    partes = set(z.namelist())

    def leer(nombre):
        return ET.fromstring(z.read(nombre)) if nombre in partes else None

    insertados = borrados = 0
    for nombre in ("word/document.xml", "word/footnotes.xml", "word/endnotes.xml"):
        raiz = leer(nombre)
        if raiz is None:
            continue
        insertados += sum(1 for _ in raiz.iter(W + "ins"))
        borrados += sum(1 for _ in raiz.iter(W + "del"))

    raiz = leer("word/comments.xml")
    comentarios = 0 if raiz is None else sum(1 for _ in raiz.iter(W + "comment"))

    # NOMBRES DE LOS ESTILOS DE PÁRRAFO Y ESTILO POR DEFECTO
    nombres, defecto = {}, None
    raiz = leer("word/styles.xml")
    if raiz is not None:
        for estilo in raiz.iter(W + "style"):
            if estilo.get(W + "type") != "paragraph":
                continue
            ident = estilo.get(W + "styleId")
            nodo = estilo.find(W + "name")
            nombres[ident] = nodo.get(W + "val") if nodo is not None else ident
            if estilo.get(W + "default") in ("1", "true", "on"):
                defecto = ident

    # USO DE ESTILOS DE PÁRRAFO DISTINTOS DEL DEFECTO
    uso = collections.Counter()
    raiz = leer("word/document.xml")
    if raiz is not None:
        for parrafo in raiz.iter(W + "p"):
            nodo = parrafo.find(W + "pPr/" + W + "pStyle")
            ident = nodo.get(W + "val") if nodo is not None else defecto
            if ident is None or ident == defecto:
                continue
            nombre = nombres.get(ident, ident).replace("\t", " ").replace("\n", " ")
            uso[nombre] += 1

with open(salida, "w", encoding="utf-8") as f:
    f.write("cambios_insertados\t%d\n" % insertados)
    f.write("cambios_borrados\t%d\n" % borrados)
    f.write("comentarios\t%d\n" % comentarios)
    # sorted: ORDEN DETERMINISTA
    for nombre in sorted(uso):
        f.write("estilo:%s\t%d\n" % (nombre, uso[nombre]))
PY

if [ "$?" -ne 0 ]; then
  printf '  AVISO: no se pudo leer la estructura del .docx; el informe dirá no_disponible\n'
  printf '  %s\n' "$(tail -n 1 error_docx.txt)"
  rm -f docx.tsv
fi

# --- 3. CONVERSIÓN CON PANDOC Y EL FILTRO ---
# LECTOR: EXTENSIONES EXPLÍCITAS, NO LOS DEFAULTS DE LA VERSIÓN INSTALADA.
#   -styles: CON styles LOS ESTILOS DE CARÁCTER Strong/Emphasis PIERDEN LA
#   NEGRITA Y LA CURSIVA; SIN ÉL, LOS ESTILOS DE PÁRRAFO DESCONOCIDOS YA SALEN
#   COMO PÁRRAFO NORMAL
# ESCRITOR: -smart CONSERVA COMILLAS CURVAS, RAYAS Y PUNTOS SUSPENSIVOS REALES.
# --extract-media=media CON EL TEMPORAL COMO DIRECTORIO DE TRABAJO DEJA
# REFERENCIAS RELATIVAS media/..., LA CONVENCIÓN DEL PROYECTO
etapa 3 "Convirtiendo con pandoc"

pandoc original.docx \
  --from=docx-styles-citations-empty_paragraphs \
  --to=markdown-smart \
  --wrap=none \
  --track-changes=accept \
  --extract-media=media \
  --lua-filter="$FILTRO" \
  -M "gbp-prefijo=$NOMBRE" \
  --output=convertido.md
CODIGO_PANDOC=$?

if [ "$CODIGO_PANDOC" -ne 0 ]; then
  if [ "$CODIGO_PANDOC" -eq 83 ]; then
    fallar 20 "pandoc terminó con código 83 (fallo del filtro)"
  fi
  fallar 20 "pandoc terminó con código $CODIGO_PANDOC"
fi

if [ ! -f conteo.tsv ]; then
  fallar 20 "el filtro no escribió su conteo"
fi

# --- 4. NORMALIZACIÓN NFC ---
# PANDOC PRESERVA LA FORMA DESCOMPUESTA (NFD) TAL COMO VIENE EN EL .docx
etapa 4 "Normalizando a NFC"

python3 - convertido.md normalizado.md <<'PY'
import sys
import unicodedata

with open(sys.argv[1], encoding="utf-8") as f:
    texto = f.read()
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(unicodedata.normalize("NFC", texto))
PY

if [ "$?" -ne 0 ] || [ ! -f normalizado.md ]; then
  fallar 30 "no se pudo normalizar el texto a NFC"
fi

# --- 5. INFORME ---
etapa 5 "Armando el informe"

declare -A CONTEO=()

# CONTEO DEL FILTRO Y DE LA LECTURA DEL XML EN UNA SOLA TABLA
for ARCHIVO_CONTEO in conteo.tsv docx.tsv; do
  [ -f "$ARCHIVO_CONTEO" ] || continue
  while IFS=$'\t' read -r CLAVE VALOR; do
    [ -n "$CLAVE" ] && CONTEO["$CLAVE"]="$VALOR"
  done < "$ARCHIVO_CONTEO"
done

SHA256="$(sha256sum -- original.docx | cut -d ' ' -f 1)"
if [ -z "$SHA256" ]; then
  fallar 50 "no se pudo calcular el sha256"
fi

# ============================================
# Función   : valor
# Propósito : Devuelve el valor de un concepto del conteo, 0 si no aparece,
#             o no_disponible si la lectura del XML falló
# Parámetros: $1 — clave; $2 — "xml" si la clave sale de la lectura del .docx
# Retorna   : el valor por stdout
# ============================================
valor() {
  if [ "${2:-}" = "xml" ] && [ ! -f docx.tsv ]; then
    printf 'no_disponible'
  else
    printf '%s' "${CONTEO[$1]:-0}"
  fi
}

{
  printf 'concepto\tvalor\n'
  printf 'archivo_origen\t%s\n' "$(basename -- "$ORIGEN")"
  printf 'sha256_origen\t%s\n' "$SHA256"
  printf 'destino\t%s\n' "$SUBCARPETA/$NOMBRE.md"
  printf 'version_pandoc\t%s\n' "$VERSION_PANDOC"
  printf 'version_filtro\t%s\n' "$(valor version_filtro)"
  printf 'fecha\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
  printf 'cambios_insertados\t%s\n' "$(valor cambios_insertados xml)"
  printf 'cambios_borrados\t%s\n' "$(valor cambios_borrados xml)"
  printf 'comentarios\t%s\n' "$(valor comentarios xml)"
  for CLAVE in subrayado resaltado versalitas guion_blando espacio_duro \
               salto_linea_a_parrafo salto_linea_a_espacio imagenes imagen_no_embebida; do
    printf '%s\t%s\n' "$CLAVE" "$(valor "$CLAVE")"
  done
  # CLAVES VARIABLES, EN ORDEN DE BYTES PARA QUE EL INFORME SEA ESTABLE
  for CLAVE in "${!CONTEO[@]}"; do
    case "$CLAVE" in
      estilo_metadato:*|estilo:*) printf '%s\t%s\n' "$CLAVE" "${CONTEO[$CLAVE]}" ;;
    esac
  done | LC_ALL=C sort
} > informe.txt || fallar 50 "no se pudo escribir el informe"

# LA TABLA SE MUESTRA EN LA TERMINAL: EL INFORME NO ES UNA CAJA NEGRA.
# LA ALINEACIÓN SE HACE EN PYTHON: EL ANCHO DE printf DE BASH SE MIDE EN BYTES
# (UNA "ó" OCUPA DOS Y CORRE LA COLUMNA), Y ${#VAR} DEPENDE DEL LOCALE.
# ljust CUENTA CODEPOINTS SOBRE EL TEXTO LEÍDO EXPLÍCITAMENTE COMO UTF-8
python3 - informe.txt <<'PY'
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    for linea in f:
        clave, _, valor = linea.rstrip("\n").partition("\t")
        sys.stdout.write("  " + clave.ljust(32) + " " + valor + "\n")
PY

# --- 6. CONFIRMACIÓN EN EL PROYECTO ---
# PRIMERO LAS IMÁGENES (EL .md LAS REFERENCIA), DESPUÉS TEXTO, ORIGINAL E INFORME
etapa 6 "Incorporando al proyecto"

mkdir -p -- "$RAIZ/$SUBCARPETA" "$RAIZ/originales" "$RAIZ/media" || fallar 40 "no se pudieron crear las carpetas del proyecto"

# IMÁGENES DE UNA CONVERSIÓN ANTERIOR DE ESTA MISMA PIEZA. EL "_" GARANTIZA
# QUE a-01-X_ NO ALCANCE A LAS IMÁGENES DE a-01-X-Y
rm -f -- "$RAIZ/media/${NOMBRE}_"*

if [ -d media ]; then
  for IMAGEN in media/*; do
    [ -e "$IMAGEN" ] || continue
    mv -f -- "$IMAGEN" "$RAIZ/media/" || fallar 40 "no se pudo mover la imagen $(basename -- "$IMAGEN")"
  done
fi

mv -f -- normalizado.md "$RAIZ/$SUBCARPETA/$NOMBRE.md" || fallar 40 "no se pudo escribir $SUBCARPETA/$NOMBRE.md"
mv -f -- original.docx "$RAIZ/originales/$NOMBRE.docx" || fallar 40 "no se pudo archivar el original"
mv -f -- informe.txt "$RAIZ/originales/$NOMBRE.txt" || fallar 40 "no se pudo archivar el informe"

printf '\nOK: %s/%s.md\n' "$SUBCARPETA" "$NOMBRE"
exit 0
