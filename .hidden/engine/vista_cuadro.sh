#!/bin/bash
# Vista previa de un cuadro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   vista_cuadro.sh <ruta_proyecto> <tbl-id> <libro|revista> <idioma>
#
#   ruta_proyecto   raíz del proyecto
#   tbl-id          el cuadro: cuadros/<tbl-id>.md
#   libro|revista   qué cadena y qué hoja de composición
#   idioma          el de la pieza donde va el cuadro (es, en, pt…): lo leen
#                   volada.lua, cifras.lua y conversacion.lua
#
# EL CUADRO SE COMPONE SOLO, PERO CON TODO LO DEL LIBRO O DEL ARTÍCULO (SC-67):
#   - los mismos filtros, en el mismo orden (FILTROS_LIBRO, FILTROS_REVISTA en
#     comun.sh);
#   - la misma plantilla de composición (vista-cuadro-*.xsl importa la hoja
#     del PDF y solo cambia la raíz);
#   - el mismo preámbulo, con showframe. Lo escribe Gambas en
#     tmp/vista-cuadro/preambulo-vista.tex ANTES DE LANZAR ESTE SCRIPT: es lo
#     único que sale de la base (el formato de página, el estilo de cita).
#
# LO QUE ESCRIBE, EN tmp/vista-cuadro/
#   vista.md            el .md mínimo que nombra el cuadro
#   cuadro.xml          lo que dejó pandoc, con su envoltorio
#   cuadro-vista.tex    el cuadro compuesto (Saxon)
#   medir-vista.tex     las medidas: carga vista_cuadro_medir.lua
#   vista.tex           el maestro: preámbulo + medidas + cuadro
#   vista.pdf           LO QUE GAMBAS ABRE
#   veredicto.txt       lo que Gambas muestra: una línea por hallazgo,
#                       «nivel<TAB>mensaje», nivel info, aviso o error
#
# EL VEREDICTO
#   - Por tramo, el ancho y el alto del cuadro contra los de la caja (info).
#   - Un tramo más ancho que la caja, o más alto: error.
#   - «Float too large» de LaTeX: error. Es el alto con el pie, que la medida
#     del tabular no ve.
#   - Una celda que se sale de su columna: error, con el tramo. En el libro
#     esto solo lo ve la medida: linebreaker calla los Overfull (GV-128).
#   - Un error de LaTeX («!») en el cuadro: error. Uno del preámbulo: aviso,
#     porque no es del cuadro (sale igual en el PDF de la pieza).
#   - Si frena antes del PDF (el cuadro mal escrito, una plantilla), el motivo
#     también va al veredicto: Gambas no tiene que leer la terminal.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  el PDF salió y el cuadro entra
#   3  el PDF salió y el veredicto tiene errores o avisos: Gambas lo abre
#      igual, para que se vea qué no entra
#   1  no salió el PDF: el motivo está en el veredicto y en la terminal
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_PANDOC=60
TIEMPO_SAXON=120
TIEMPO_LUALATEX=180

# UNA DIFERENCIA MENOR QUE ESTA NO ES UN DESBORDE: EL REDONDEO DE LOS ANCHOS
# p{…} EN cm (MEDIO PUNTO ES 0,18 mm)
TOLERANCIA_SP=32768

# EL ENVOLTORIO DE CADA TIPO: EL MISMO QUE EL DE LA CADENA REAL
# (generar_canonicos_capitulos.sh Y m_XML.GenerarBodyXML)
ENVOLTORIO_LIBRO_ABRE='<section xmlns="http://docbook.org/ns/docbook" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink">'
ENVOLTORIO_LIBRO_CIERRA='</section>'
ENVOLTORIO_REVISTA_ABRE='<body xmlns:xlink="http://www.w3.org/1999/xlink">'
ENVOLTORIO_REVISTA_CIERRA='</body>'

# ============================================================================
# Función   : anotar
# Propósito : Escribe una línea en el veredicto
# Parámetros: $1 nivel (info, aviso, error)  $2 mensaje
# ============================================================================
anotar() {
    printf '%s\t%s\n' "$1" "$2" >> "$VEREDICTO"
}

# ============================================================================
# Función   : frenar
# Propósito : Corta la vista: el motivo va al veredicto y a la terminal
# Parámetros: $1 mensaje
# ============================================================================
frenar() {
    anotar error "$1"
    morir "$1"
}

# ============================================================================
# Función   : motivo_de
# Propósito : El motivo de una salida de pandoc o de Saxon en una línea: las
#             líneas con la marca del filtro ([cuadro], [cifras]…), sin la
#             pila de Lua. SI NO HAY MARCA, LA ÚLTIMA LÍNEA CON TEXTO
# Parámetros: $1 la salida capturada
# Retorna   : imprime el motivo
# ============================================================================
motivo_de() {
    local limpio marcado
    limpio=$(printf '%s\n' "$1" | sed '/^[[:space:]]*stack traceback:/,$d')
    marcado=$(printf '%s\n' "$limpio" | grep -E '^\[[a-z-]+\]' | head -3 | tr '\n' ' ')
    if [[ -n "$marcado" ]]; then
        printf '%s' "${marcado% }"
    else
        printf '%s\n' "$limpio" | grep -v '^[[:space:]]*$' | tail -1
    fi
}

# ============================================================================
# Función   : mm
# Propósito : Pasa sp a milímetros, con coma decimal
# Parámetros: $1 medida en sp
# Retorna   : imprime «12,3»
# ============================================================================
mm() {
    # 1 pt = 65536 sp; 1 pt = 25,4 / 72,27 mm
    awk -v sp="$1" 'BEGIN { printf "%.1f", sp / 65536 * 25.4 / 72.27 }' | tr '.' ','
}

# --- 2. ARGUMENTOS ---
if (( $# != 4 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <tbl-id> <libro|revista> <idioma>"
fi
DIR_PROYECTO="${1%/}"
ID="$2"
TIPO="$3"
IDIOMA="$4"

DIR_VISTA="$DIR_PROYECTO/tmp/vista-cuadro"
VEREDICTO="$DIR_VISTA/veredicto.txt"
DIR_FILTROS="$DIR_GBP_LOCAL/filters"

# EL VEREDICTO SE EMPIEZA ANTES QUE NADA: GAMBAS LO LEE SIEMPRE, Y UNO VIEJO
# DIRÍA ALGO DE OTRO CUADRO
mkdir -p "$DIR_VISTA" || morir "No se pudo crear $DIR_VISTA"
: > "$VEREDICTO"

encabezado "Vista previa del cuadro $ID"

case "$TIPO" in
    libro)
        FILTROS=("${FILTROS_LIBRO[@]}")
        FORMATO="docbook5"
        ARGS_FORMATO=(--mathml --metadata gb-idioma-pieza="$IDIOMA")
        ABRE="$ENVOLTORIO_LIBRO_ABRE"; CIERRA="$ENVOLTORIO_LIBRO_CIERRA"
        XSL="$DIR_GBP_LOCAL/xslt/vista-cuadro-libro.xsl"
        ;;
    revista)
        FILTROS=("${FILTROS_REVISTA[@]}")
        FORMATO="jats"
        # LA MISMA FORMA QUE m_XML.ArgumentoIdiomaPandoc
        ARGS_FORMATO=(-M gb-idioma="$IDIOMA")
        ABRE="$ENVOLTORIO_REVISTA_ABRE"; CIERRA="$ENVOLTORIO_REVISTA_CIERRA"
        XSL="$DIR_GBP_LOCAL/xslt/vista-cuadro-revista.xsl"
        ;;
    *)  frenar "tipo desconocido: «$TIPO» (se espera libro o revista)" ;;
esac

# --- 3. INSUMOS ---
paso "insumos"
requerir_comandos pandoc java lualatex xmllint awk
[[ "$ID" =~ ^tbl-[A-Za-z0-9_-]+$ ]] || frenar "«$ID» no es el nombre de un cuadro (tbl-…)"
[[ -f "$DIR_PROYECTO/cuadros/$ID.md" ]] || frenar "no existe cuadros/$ID.md"
[[ -f "$DIR_VISTA/preambulo-vista.tex" ]] || frenar "falta tmp/vista-cuadro/preambulo-vista.tex: lo escribe gbpublisher antes de la vista"
[[ -f "$RUTA_SAXON" ]] || frenar "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]] || frenar "falta la hoja $XSL"
[[ -f "$DIR_ENGINE/vista_cuadro_medir.lua" ]] || frenar "falta $DIR_ENGINE/vista_cuadro_medir.lua"
for filtro in "${FILTROS[@]}"; do
    [[ -f "$DIR_FILTROS/$filtro" ]] || frenar "falta el filtro $DIR_FILTROS/$filtro"
done
[[ -f "$RUTA_ABREVIATURAS" ]] || frenar "falta la lista de abreviaturas $RUTA_ABREVIATURAS"
ok "cuadros/$ID.md"

# LO DE LA CORRIDA ANTERIOR SE BORRA: UN PDF VIEJO NO PUEDE PASAR POR NUEVO
rm -f "$DIR_VISTA"/{vista.md,parcial.xml,cuadro.xml,cuadro-vista.tex,medir-vista.tex,vista.tex,vista.pdf,vista.log,vista.aux,medidas.txt}

# --- 4. EL .md QUE NOMBRA EL CUADRO, COMO LO INSERTA FTabla ---
printf '::: {.cuadro #%s}\n[/cuadro]: # ()\n:::\n' "$ID" > "$DIR_VISTA/vista.md"

# --- 5. PANDOC CON LA CADENA DE LA PIEZA ---
paso "el cuadro por los filtros de $TIPO"
args_pandoc=()
for filtro in "${FILTROS[@]}"; do
    args_pandoc+=(--lua-filter "$DIR_FILTROS/$filtro")
done
salida=$(timeout "$TIEMPO_PANDOC" pandoc "$DIR_VISTA/vista.md" \
            --from markdown --to "$FORMATO" --no-highlight --wrap=none \
            --abbreviations "$RUTA_ABREVIATURAS" \
            "${ARGS_FORMATO[@]}" "${args_pandoc[@]}" \
            --metadata gb-proyecto="$DIR_PROYECTO" \
            --output "$DIR_VISTA/parcial.xml" 2>&1)
codigo=$?
if (( codigo != 0 )); then
    # EL MOTIVO LO DA EL FILTRO QUE FRENÓ: ES LO QUE EL EDITOR TIENE QUE LEER
    mostrar_cola "$salida"
    anotar error "$(motivo_de "$salida")"
    morir "pandoc rechazó el cuadro"
fi
{ printf '%s\n' "$ABRE"; cat "$DIR_VISTA/parcial.xml"; printf '%s\n' "$CIERRA"; } > "$DIR_VISTA/cuadro.xml"
rm -f "$DIR_VISTA/parcial.xml"
bien_formado "$DIR_VISTA/cuadro.xml" || frenar "lo que dejó pandoc está mal formado: tmp/vista-cuadro/cuadro.xml"
ok "convertido"

# --- 6. LA COMPOSICIÓN: LA MISMA PLANTILLA QUE EL PDF ---
paso "composición"
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$DIR_VISTA/cuadro.xml" -xsl:"$XSL" -o:"$DIR_VISTA/cuadro-vista.tex" 2>&1)
codigo=$?
if (( codigo != 0 )) || [[ ! -s "$DIR_VISTA/cuadro-vista.tex" ]]; then
    mostrar_cola "$salida"
    anotar error "$(motivo_de "$salida")"
    morir "Saxon no compuso el cuadro"
fi
ok "cuadro-vista.tex"

# --- 7. EL MAESTRO ---
# LAS MEDIDAS SE CARGAN DESPUÉS DEL PREÁMBULO: luatexbase YA ESTÁ, Y LOS
# GANCHOS DE tabular QUEDAN ÚLTIMOS. \luaescapestring PORQUE LA RUTA DEL
# MOTOR SE ESCRIBE DENTRO DE UNA CADENA DE LUA
cat > "$DIR_VISTA/medir-vista.tex" <<EOF
% medir-vista.tex — LO ESCRIBE vista_cuadro.sh. NO EDITAR
\\newsavebox{\\gbvista}
\\directlua{dofile("\\luaescapestring{$DIR_ENGINE/vista_cuadro_medir.lua}")}
\\AtBeginDocument{\\directlua{gbvista.pagina()}}
\\AddToHook{env/table/begin}{\\directlua{gbvista.flotante = true}}
\\AddToHook{env/table/end}{\\directlua{gbvista.flotante = false}}
\\AddToHook{env/sidewaystable/begin}{\\directlua{gbvista.flotante = true}}
\\AddToHook{env/sidewaystable/end}{\\directlua{gbvista.flotante = false}}
\\AddToHook{env/tabular/before}{\\directlua{gbvista.empezar()}\\begin{lrbox}{\\gbvista}}
\\AddToHook{env/tabular/after}{\\end{lrbox}\\directlua{gbvista.medir()}\\usebox{\\gbvista}}
EOF
cat > "$DIR_VISTA/vista.tex" <<'EOF'
% vista.tex — LO ESCRIBE vista_cuadro.sh. NO EDITAR
\input{preambulo-vista}
\input{medir-vista}
\begin{document}
\typeout{GB-VISTA: empieza el cuadro}
\input{cuadro-vista}
\end{document}
EOF

# --- 8. LuaLaTeX, UNA PASADA ---
# UNA ALCANZA: NO HAY REFERENCIAS NI BIBLIOGRAFÍA QUE RESOLVER. EL CRITERIO
# DE ÉXITO ES EL PDF, NO EL CÓDIGO (VER compilar_latex_comun.sh). EL cwd ES LA
# CARPETA DE LA VISTA: AHÍ ESCRIBE vista_cuadro_medir.lua SUS MEDIDAS.
# latex/ DEL PROYECTO PRIMERO: AHÍ ESTÁN LOS PREÁMBULOS DEL LIBRO
paso "LuaLaTeX"
salida=$(cd "$DIR_VISTA" && TEXINPUTS="$DIR_PROYECTO/latex/:$DIR_VISTA/:${TEXINPUTS:-}" \
            timeout "$TIEMPO_LUALATEX" lualatex -interaction=nonstopmode vista.tex 2>&1)
codigo=$?
LOG="$DIR_VISTA/vista.log"

# LOS ERRORES DE LaTeX, CON SU LÍNEA DE CONTEXTO «l.N …». LA MARCA QUE
# ESCRIBE EL MAESTRO SEPARA LOS DEL CUADRO DE LOS DEL PREÁMBULO: LOS DEL
# PREÁMBULO NO SON DEL CUADRO Y SALEN TAMBIÉN EN EL PDF DE LA PIEZA, ASÍ QUE
# VAN COMO AVISO, PARA QUE NO TAPEN EL VEREDICTO DEL CUADRO
if [[ -f "$LOG" ]]; then
    while IFS=$'\t' read -r donde linea; do
        if [[ "$donde" == "cuadro" ]]; then
            anotar error "LaTeX: $linea"
        else
            anotar aviso "LaTeX, en el preámbulo (no es del cuadro): $linea"
        fi
    done < <(awk '
        /^GB-VISTA: empieza el cuadro$/ { donde = "cuadro" }
        /^! / && !/Emergency stop|==> Fatal error/ {
            print (donde == "" ? "preambulo" : donde) "\t" substr($0, 3) }
        ' "$LOG" | head -8)
fi
if [[ ! -f "$DIR_VISTA/vista.pdf" ]]; then
    (( codigo == 124 )) && anotar error "LuaLaTeX no terminó en $TIEMPO_LUALATEX segundos"
    [[ -s "$VEREDICTO" ]] || anotar error "LuaLaTeX no produjo el PDF: ver tmp/vista-cuadro/vista.log"
    mostrar_cola "$salida"
    morir "no salió el PDF de la vista"
fi
ok "vista.pdf"

# --- 9. EL VEREDICTO ---
paso "veredicto"
[[ -f "$DIR_VISTA/medidas.txt" ]] || frenar "faltan las medidas: vista_cuadro_medir.lua no corrió"

alto_marcado=0
tramos=$(grep -c '^tramo' "$DIR_VISTA/medidas.txt")
(( tramos > 0 )) || frenar "el PDF salió sin ningún tramo medido"

# 9a. CADA TRAMO: ANCHO Y ALTO
while IFS=$'\t' read -r _ n ancho caja alto disponible; do
    rotulo="tramo $n de $tramos"
    (( tramos == 1 )) && rotulo="el cuadro"
    anotar info "$rotulo: $(mm "$ancho") × $(mm "$alto") mm en una caja de $(mm "$caja") × $(mm "$disponible") mm"
    if (( ancho - caja > TOLERANCIA_SP )); then
        anotar error "$rotulo se pasa del ancho de la caja en $(mm $((ancho - caja))) mm"
    fi
    if (( alto - disponible > TOLERANCIA_SP )); then
        anotar error "$rotulo se pasa del alto de la caja en $(mm $((alto - disponible))) mm: hace falta un corte"
        alto_marcado=1
    fi
done < <(grep '^tramo' "$DIR_VISTA/medidas.txt")

# 9b. LAS CELDAS QUE SE SALEN DE SU COLUMNA
while IFS=$'\t' read -r _ n exceso; do
    rotulo="en el tramo $n"
    (( tramos == 1 )) && rotulo="en el cuadro"
    anotar error "$rotulo, una celda se sale de su columna en $(mm "$exceso") mm: una palabra que no se puede cortar, o una columna angosta"
done < <(grep '^desborde' "$DIR_VISTA/medidas.txt")

# 9c. EL FLOTANTE MÁS ALTO QUE LA PÁGINA: TABULAR MÁS PIE. LaTeX DA EL EXCESO
# EN pt («Float too large for page by 516.60013pt on input line 149.»). SI
# UN TRAMO YA SE PASA SOLO, EL AVISO DE LaTeX DICE LO MISMO Y NO SE REPITE
(( alto_marcado == 0 )) && while IFS= read -r pt; do
    sp=$(awk -v p="$pt" 'BEGIN { printf "%d", p * 65536 }')
    rotulo="un tramo"; (( tramos == 1 )) && rotulo="el cuadro"
    anotar error "$rotulo, con su pie, se pasa del alto de la página en $(mm "$sp") mm: hace falta un corte"
done < <(grep -o 'Float too large for page by [0-9.]*pt' "$LOG" | grep -o '[0-9.]*pt' | sed 's/pt$//')

# 9d. LO QUE NO ENTRA, CONTANDO LOS ERRORES DE LaTeX DEL APARTADO 8
errores=$(grep -c '^error' "$VEREDICTO")

avisos=$(grep -c '^aviso' "$VEREDICTO")
if (( errores > 0 )); then
    aviso "el cuadro no entra: $errores problema(s). El detalle está en el veredicto"
elif (( avisos > 0 )); then
    aviso "el cuadro entra, con $avisos aviso(s) en el veredicto"
else
    ok "el cuadro entra en la caja"
fi
printf '\n  %stmp/vista-cuadro/vista.pdf%s\n' "$C_TENUE" "$C_RESET"
terminar
