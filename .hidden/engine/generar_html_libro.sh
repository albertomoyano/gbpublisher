#!/bin/bash
# Generador de la salida HTML de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   generar_html_libro.sh <ruta_proyecto> <nombre_base> <lugar_bibliografia>
#                         <biblio_rel> <estilo_cita> <modo_citas>
#                         [imagen_tapa|-] [destino_html] [url_portal]
#
#   Los cuatro primeros son los de ensamblar_libro.sh, que este script invoca.
#   estilo_cita    el identificador del estilo — lo resuelve Gambas
#                  (ResolverEstiloCita)
#   modo_citas     tex4ht | xslt — lo decide Gambas (PrepararCitasPantalla,
#                  SC-57): tex4ht si el estilo tiene archivo de pantalla
#                  (cita-<estilo>-html.tex). Con tex4ht, este script corre
#                  antes la pasada de citas (preparar_citas_libro.sh) y la
#                  hoja toma el texto de citas.html
#   imagen_tapa    nombre del archivo de tapa según la base. Opcional: se
#                  copia con las imágenes del canónico, y si falta se avisa.
#                  «-» es «sin tapa», para poder pasar los dos siguientes
#   destino_html   autonomo | portal (libros_md.destino_html, 1.22.0).
#                  Opcional: sin él, autonomo
#   url_portal     la dirección del portal, terminada en «/». Obligatoria
#                  con destino portal
#
# EL HTML INTEGRADO AL PORTAL (LOTE 3, 05/11/2026)
#   Con destino portal, el libro se lee dentro del marco del portal de gbWeb:
#   su cabecera, su pie y su hoja de estilos. El script baja el marco que el
#   portal publica en <url_portal>marco/ (marco.xml y los archivos que lista),
#   controla el sha256 de cada uno y lo deja en docs/assets/marco/: el libro
#   no depende de que el portal responda después. Si no se puede bajar, usa
#   el de la generación anterior, si sigue íntegro, y avisa.
#   La hoja es docbook-to-html-portal.xsl, que importa la autónoma. La
#   portada y los créditos de la página de entrada los escribe Gambas en
#   tmp/html-portal/ (las mismas páginas del EPUB); sus logos se copian con
#   las demás imágenes.
#   Con destino autonomo, el marco y la hoja integrada se borran de docs/:
#   un libro que deja el portal no conserva restos.
#
# LAS IMÁGENES (29/10/2026)
#   docs/assets/media/ se vacía y recibe solo lo que el HTML usa: las imágenes
#   que nombra el canónico del libro, la tapa y, para cada gráfico de
#   gbpublisher (fig-x.png con fig-x.html al lado, SC-69), su HTML. Cada
#   imagen pasa por copiar_imagen_pantalla (comun.sh): tal cual, o reducida
#   a 2000 px de lado mayor y en sRGB. Antes se copiaba media/ entera.
# ============================================================================
# POR QUÉ ENSAMBLA PRIMERO
#
#   El HTML es la única salida que lee el canónico del LIBRO: el PDF y el EPUB
#   recorren los canónicos de cada capítulo. Así que un canónico del libro
#   truncado o viejo solo se nota acá, y la costura entre ensamblar y
#   transformar es exactamente donde se rompía. Ensamblar dentro del mismo
#   script la elimina: bash no pasa al paso siguiente hasta que el anterior
#   terminó, y ensamblar_libro.sh no deja en disco un canónico a medio escribir.
#
# LA VALIDACIÓN HTML5 ES INFORMATIVA: sus errores no impiden la salida, pero
# llegan a Gambas como código 3.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=300
TIEMPO_VNU=300
RUTA_VNU="/opt/vnu/vnu.jar"
LINEAS_ERROR_VNU=15
# PLAZO DE CADA DESCARGA DEL MARCO, EN SEGUNDOS
TIEMPO_CURL=30

# ============================================================================
# EL MARCO DEL PORTAL
# ============================================================================

# RUTA DE UN ARCHIVO DEL MARCO: RELATIVA, SIN «..», SIN SEGMENTOS QUE EMPIECEN
# CON PUNTO. EL MANIFIESTO VIENE DE LA RED: SIN ESTE CONTROL, UNA RUTA PODRÍA
# ESCRIBIR FUERA DE docs/assets/marco/
# LOS FRAGMENTOS DEL MARCO: .xml Y NO .html DESDE EL 07/11/2026 (gbWeb,
# portal.xsl): UN SERVIDOR PUEDE REESCRIBIR LOS .html QUE PUBLICA (NETLIFY
# CON «PRETTY URLS») Y EL sha256 DEJA DE COINCIDIR. UN PORTAL CONSTRUIDO
# ANTES PUBLICA .html: HAY QUE RECONSTRUIRLO Y DESPLEGARLO
CABECERA_MARCO="cabecera.xml"
PIE_MARCO="pie.xml"

RUTA_MARCO_VALIDA='^[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)*(/[A-Za-z0-9][A-Za-z0-9_-]*(\.[A-Za-z0-9_-]+)*)*$'

# ----------------------------------------------------------------------------
# verificar_marco <carpeta> <url_portal>
#   Controla un marco ya en disco: marco.xml bien formado, del portal que se
#   espera, con la cabecera y el pie en castellano y la hoja, y cada archivo
#   que lista presente y con su sha256. Deja el motivo del fallo en
#   MARCO_MOTIVO y la cantidad de archivos en MARCO_ARCHIVOS.
# ----------------------------------------------------------------------------
verificar_marco() {
    local dir="$1" url="$2" manifiesto="$1/marco.xml"
    local total i ruta huella base
    MARCO_MOTIVO=""
    MARCO_ARCHIVOS=0

    if [[ ! -f "$manifiesto" ]]; then
        MARCO_MOTIVO="no hay marco.xml"
        return 1
    fi
    if ! bien_formado "$manifiesto"; then
        MARCO_MOTIVO="marco.xml está mal formado"
        return 1
    fi

    # EL MARCO ES DEL PORTAL QUE EL LIBRO DECLARA: SI EL PORTAL SE MUDÓ, LA
    # DIRECCIÓN DEL LIBRO TIENE QUE SEGUIRLO
    base=$(xmllint --nonet --xpath 'string(/marco/@url-base)' "$manifiesto" 2>/dev/null)
    if [[ "$base" != "$url" ]]; then
        MARCO_MOTIVO="el marco es del portal «$base», no de «$url»: revisá la dirección del portal en el formulario del libro"
        return 1
    fi

    total=$(xmllint --nonet --xpath 'count(/marco/archivo)' "$manifiesto" 2>/dev/null)
    for ruta in "es/$CABECERA_MARCO" "es/$PIE_MARCO" marco.css; do
        if [[ $(xmllint --nonet --xpath "count(/marco/archivo[@ruta='$ruta'])" "$manifiesto" 2>/dev/null) != 1 ]]; then
            MARCO_MOTIVO="marco.xml no lista $ruta"
            # UN PORTAL CONSTRUIDO ANTES DEL 07/11/2026 PUBLICA LOS FRAGMENTOS
            # COMO .html: SE DICE QUÉ HACER
            if [[ $(xmllint --nonet --xpath "count(/marco/archivo[@ruta='es/cabecera.html'])" "$manifiesto" 2>/dev/null) == 1 ]]; then
                MARCO_MOTIVO+=" (el portal publica el marco anterior, en .html: reconstruilo y desplegalo con gbWeb)"
            fi
            return 1
        fi
    done

    for (( i = 1; i <= total; i++ )); do
        ruta=$(xmllint --nonet --xpath "string(/marco/archivo[$i]/@ruta)" "$manifiesto" 2>/dev/null)
        huella=$(xmllint --nonet --xpath "string(/marco/archivo[$i]/@sha256)" "$manifiesto" 2>/dev/null)
        if [[ ! "$ruta" =~ $RUTA_MARCO_VALIDA ]]; then
            MARCO_MOTIVO="ruta no admitida en marco.xml: «$ruta»"
            return 1
        fi
        if [[ ! -f "$dir/$ruta" ]]; then
            MARCO_MOTIVO="falta $ruta"
            return 1
        fi
        if [[ "$(sha256sum "$dir/$ruta" | cut -d' ' -f1)" != "$huella" ]]; then
            MARCO_MOTIVO="$ruta no coincide con su sha256"
            return 1
        fi
    done

    # LOS FRAGMENTOS LOS LEE LA HOJA CON doc(): TIENEN QUE SER XML
    for ruta in "es/$CABECERA_MARCO" "es/$PIE_MARCO"; do
        if ! bien_formado "$dir/$ruta"; then
            MARCO_MOTIVO="$ruta no es XML bien formado"
            return 1
        fi
    done

    MARCO_ARCHIVOS=$total
    return 0
}

# ----------------------------------------------------------------------------
# bajar_marco <url_portal> <carpeta>
#   Baja marco.xml y cada archivo que lista a una carpeta vacía y la verifica.
#   -L: UN PORTAL QUE SE MUDÓ REDIRIGE DESDE LA DIRECCIÓN VIEJA; LO QUE DECIDE
#   ES EL url-base DEL MANIFIESTO (verificar_marco)
# ----------------------------------------------------------------------------
bajar_marco() {
    local url="$1" dir="$2" total i ruta

    if ! curl -fsSL --max-time "$TIEMPO_CURL" -o "$dir/marco.xml" "${url}marco/marco.xml" 2>/dev/null; then
        MARCO_MOTIVO="no se pudo bajar ${url}marco/marco.xml"
        return 1
    fi
    if ! bien_formado "$dir/marco.xml"; then
        MARCO_MOTIVO="${url}marco/marco.xml no es XML bien formado"
        return 1
    fi

    total=$(xmllint --nonet --xpath 'count(/marco/archivo)' "$dir/marco.xml" 2>/dev/null)
    for (( i = 1; i <= total; i++ )); do
        ruta=$(xmllint --nonet --xpath "string(/marco/archivo[$i]/@ruta)" "$dir/marco.xml" 2>/dev/null)
        # LA RUTA SE CONTROLA ANTES DE ESCRIBIR NADA CON ELLA
        if [[ ! "$ruta" =~ $RUTA_MARCO_VALIDA ]]; then
            MARCO_MOTIVO="ruta no admitida en marco.xml: «$ruta»"
            return 1
        fi
        mkdir -p "$dir/$(dirname "$ruta")" || { MARCO_MOTIVO="no se pudo crear $(dirname "$ruta")"; return 1; }
        if ! curl -fsSL --max-time "$TIEMPO_CURL" -o "$dir/$ruta" "${url}marco/$ruta" 2>/dev/null; then
            MARCO_MOTIVO="no se pudo bajar ${url}marco/$ruta"
            return 1
        fi
    done

    verificar_marco "$dir" "$url"
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "GENERACIÓN DE LA SALIDA HTML"

# --- 2. ARGUMENTOS ---
if (( $# < 6 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel|-> <estilo_cita> <modo_citas> [imagen_tapa|-] [destino_html] [url_portal]"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BASE="$2"
LUGAR_BIB="$3"
BIBLIO_ARG="$4"
ESTILO_CITA="$5"
MODO_CITAS="$6"
IMAGEN_TAPA="${7:-}"
DESTINO="${8:-autonomo}"
URL_PORTAL="${9:-}"

# «-» ES «SIN TAPA»: OCUPA EL LUGAR PARA QUE LLEGUEN EL DESTINO Y EL PORTAL
if [[ "$IMAGEN_TAPA" == "-" ]]; then IMAGEN_TAPA=""; fi

# EL DESTINO Y SU DIRECCIÓN LOS CONTROLA YA LA BASE (chk_libros_destino_html,
# chk_libros_url_portal, 1.22.0); ACÁ SE VUELVE A MIRAR PORQUE EL SCRIPT
# TAMBIÉN SE PUEDE LLAMAR A MANO
case "$DESTINO" in
    autonomo) ;;
    portal)
        [[ "$URL_PORTAL" =~ ^https?://[^[:space:]]+/$ ]] ||
            morir "Destino portal con una dirección de portal no válida: «$URL_PORTAL» (https://…/)"
        ;;
    *) morir "Destino del HTML no reconocido: «$DESTINO» (autonomo | portal)" ;;
esac

# EL MODO LO DECIDE GAMBAS; ACÁ SOLO SE CONTROLA QUE SEA UNO CONOCIDO
case "$MODO_CITAS" in
    tex4ht|xslt) ;;
    *) morir "Modo de citas no reconocido: «$MODO_CITAS» (tex4ht | xslt)" ;;
esac

CANONICO="$DIR_PROYECTO/jats/c-libro-$NOMBRE_BASE.xml"
MANIFIESTO_REL="tmp/manifiesto-libro-$NOMBRE_BASE.xml"
DIR_DOCS="$DIR_PROYECTO/docs"
DIR_ASSETS="$DIR_DOCS/assets"
INDEX="$DIR_DOCS/index.html"
XSL="$DIR_GBP_LOCAL/xslt/docbook-to-html.xsl"
# LA INTEGRADA IMPORTA LA AUTÓNOMA: LAS DOS TIENEN QUE ESTAR
XSL_PORTAL="$DIR_GBP_LOCAL/xslt/docbook-to-html-portal.xsl"
CSS_INTEGRADO="$DIR_GBP_LOCAL/assets/css/gbpublisher-integrado.css"
# LAS PRIMERAS DE LA PÁGINA DE ENTRADA: LAS ESCRIBE GAMBAS
# (m_GenerarEpubLibro.EscribirPrimerasHtml, CONSTANTE CARPETA_PRIMERAS_HTML)
DIR_PRIMERAS="$DIR_PROYECTO/tmp/html-portal"
DIR_MARCO="$DIR_ASSETS/marco"
COLOFON="$DIR_PROYECTO/tmp/colofon-digital.xml"
CSS="$DIR_GBP_LOCAL/assets/css/gbpublisher.css"
JS="$DIR_GBP_LOCAL/assets/js/gbpublisher.js"
# LA PASADA DE CITAS (SC-57): LOS INSUMOS LOS ESCRIBE GAMBAS
# (m_GenerarPDFLibro.EscribirInsumosCitas) CON LOS NOMBRES DE SUS CONSTANTES
# LISTA_PIEZAS_LATEX E INSUMOS_CITAS. LA CARPETA ES DE ESTA SALIDA
LISTA_CITAS_REL="tmp/latex-piezas.txt"
INSUMOS_CITAS_REL="tmp/citas-proyecto.tex"
DIR_CITAS_REL="tmp/bib/html-libro-$NOMBRE_BASE"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"

requerir_comandos java xmllint identify convert sha256sum

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de salida HTML: $XSL"
[[ -f "$CSS" ]]        || morir "No se encontró la hoja de estilos compartida: $CSS"
[[ -f "$JS" ]]         || morir "No se encontró el script compartido: $JS"

if [[ "$DESTINO" == "portal" ]]; then
    requerir_comandos curl
    [[ -f "$XSL_PORTAL" ]]    || morir "No se encontró la hoja del HTML integrado: $XSL_PORTAL"
    [[ -f "$CSS_INTEGRADO" ]] || morir "No se encontró la hoja de estilos del HTML integrado: $CSS_INTEGRADO"
    # LOS CRÉDITOS VAN SIEMPRE; LA PORTADA, SOLO SI EL LIBRO LA DECLARA (SC-25)
    [[ -f "$DIR_PRIMERAS/creditos.xhtml" ]] ||
        morir "No están los créditos de la página de entrada: $DIR_PRIMERAS/creditos.xhtml"
    for primera in "$DIR_PRIMERAS"/*.xhtml; do
        bien_formado "$primera" || morir "La página está mal formada: $primera"
    done
    XSL="$XSL_PORTAL"
fi

ok "herramientas del sistema"

# EL COLOFÓN DEL PIE LO ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT. LA HOJA LO
# LEE CON doc-available(): SI FALTARA, OMITIRÍA EL PIE SIN DECIR NADA
[[ -f "$COLOFON" ]]    || morir "No existe el colofón del pie: $COLOFON"
bien_formado "$COLOFON" || morir "El colofón del pie está mal formado: $COLOFON"
ok "colofón del pie"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s (%s)\n' "Citas:"  "$ESTILO_CITA" "$MODO_CITAS"
if [[ "$DESTINO" == "portal" ]]; then
    printf '  %-14s %s\n' "Integrado a:" "$URL_PORTAL"
else
    printf '  %-14s %s\n' "Destino:" "autónomo"
fi

# --- 4. CANÓNICO DEL LIBRO ---
# CÓDIGO 3 DEL ENSAMBLADOR: EL CANÓNICO EXISTE Y ESTÁ BIEN FORMADO, PERO
# CON AVISOS. SE SIGUE, Y EL AVISO SE HEREDA. CUALQUIER OTRO CÓDIGO DISTINTO
# DE 0: NO HAY CANÓNICO NUEVO Y NO SE GENERA NADA SOBRE EL VIEJO.
GBP_ANIDADO=1 bash "$DIR_ENGINE/ensamblar_libro.sh" \
    "$DIR_PROYECTO" "$NOMBRE_BASE" "$LUGAR_BIB" "$BIBLIO_ARG"
codigo=$?

if (( codigo == SALIDA_AVISOS )); then
    aviso "el canónico del libro tiene avisos: la salida HTML se genera igual"
elif (( codigo != SALIDA_OK )); then
    morir "No se pudo ensamblar el canónico del libro: la salida HTML no se genera"
fi

# --- 5. ESTRUCTURA docs/ Y RECURSOS ---
# CSS Y JS SE SOBRESCRIBEN SIEMPRE PARA PROPAGAR ACTUALIZACIONES (DECISIÓN
# PREVIA DEL PROYECTO).
paso "preparando docs/"

mkdir -p "$DIR_ASSETS/css" "$DIR_ASSETS/js" ||
    morir "No se pudo crear $DIR_ASSETS"

cp -f "$CSS" "$DIR_ASSETS/css/" || morir "No se pudo copiar la hoja de estilos"
cp -f "$JS"  "$DIR_ASSETS/js/"  || morir "No se pudo copiar el script"

# LA HOJA INTEGRADA SOLO VA CON DESTINO PORTAL; CON EL AUTÓNOMO SE BORRA
# JUNTO CON EL MARCO, QUE SON RESTOS DE CUANDO EL LIBRO ESTABA EN UN PORTAL
if [[ "$DESTINO" == "portal" ]]; then
    cp -f "$CSS_INTEGRADO" "$DIR_ASSETS/css/" || morir "No se pudo copiar la hoja del HTML integrado"
else
    rm -f "$DIR_ASSETS/css/$(basename "$CSS_INTEGRADO")"
    rm -rf "$DIR_MARCO" || morir "No se pudo borrar el marco de una generación anterior: $DIR_MARCO"
fi
ok "hoja de estilos y script"

# --- 5b. IMÁGENES: SOLO LAS QUE EL HTML USA ---
# LA CARPETA SE VACÍA: SIN ESO QUEDAN LAS DE UNA CORRIDA ANTERIOR, O LAS DE
# CUANDO SE COPIABA media/ ENTERA. ES SALIDA DEL SCRIPT: NADIE LA EDITA A MANO
rm -rf "$DIR_ASSETS/media" || morir "No se pudo vaciar $DIR_ASSETS/media"
mkdir -p "$DIR_ASSETS/media" || morir "No se pudo crear $DIR_ASSETS/media"

# LAS DEL CANÓNICO DEL LIBRO (QUE YA INCLUYE LA TAPA COMO mediaobject) Y LA
# TAPA QUE DECLARA LA BASE. sort -u: LA TAPA LLEGA POR LOS DOS LADOS
mapfile -t USADAS < <(
    {
        imagenes_canonico "$CANONICO"
        if [[ -n "$IMAGEN_TAPA" ]]; then printf '%s\n' "$IMAGEN_TAPA"; fi
        # LOS LOGOS DE LA PORTADA Y DE LOS CRÉDITOS DEL HTML INTEGRADO: LAS
        # PÁGINAS DEL EPUB LOS NOMBRAN COMO ../images/<archivo>
        if [[ "$DESTINO" == "portal" ]]; then
            cat "$DIR_PRIMERAS"/*.xhtml | grep -oP 'src="\.\./images/\K[^"]+'
        fi
    } | sort -u
)

imagenes=0
reducidas=0
faltan=0
for nombre in "${USADAS[@]}"; do
    [[ -n "$nombre" ]] || continue
    origen="$DIR_PROYECTO/media/$nombre"

    # UNA IMAGEN QUE EL CANÓNICO NOMBRA Y NO ESTÁ NO IMPIDE LA SALIDA, PERO EL
    # HTML LA VA A MOSTRAR ROTA. EL VALIDADOR LA MARCA COMO ERROR (SC-75)
    if [[ ! -f "$origen" ]]; then
        if [[ "$nombre" == "$IMAGEN_TAPA" ]]; then
            aviso "la tapa declarada en la base no está en media/: $nombre"
        else
            aviso "el canónico usa una imagen que no está en media/: $nombre"
        fi
        faltan=$((faltan + 1))
        continue
    fi

    copiar_imagen_pantalla "$origen" "$DIR_ASSETS/media/$nombre" "$DIR_PROYECTO/tmp/pantalla" ||
        morir "No se pudo preparar la imagen $nombre${PANTALLA_NOTA:+: $PANTALLA_NOTA}"
    imagenes=$((imagenes + 1))
    [[ -z "$PANTALLA_NOTA" ]] || tenue "$nombre: $PANTALLA_NOTA"
    reducidas=$((reducidas + PANTALLA_PREPARADA))

    # EL GRÁFICO INTERACTIVO (SC-69): EL MISMO PATRÓN QUE gbg:patron-png EN
    # grafico-comun.xsl, QUE ES QUIEN DECIDE SI LA FIGURA VA COMO IFRAME
    if [[ "$nombre" =~ ^fig-[A-Za-z0-9-]+\.png$ && -f "$DIR_PROYECTO/media/${nombre%.png}.html" ]]; then
        cp -f "$DIR_PROYECTO/media/${nombre%.png}.html" "$DIR_ASSETS/media/" ||
            morir "No se pudo copiar ${nombre%.png}.html"
        tenue "$nombre: gráfico interactivo, con su HTML"
    fi
done

if (( imagenes > 0 && reducidas > 0 )); then
    ok "$imagenes imagen(es) de las que usa el libro, $reducidas preparada(s) para pantalla"
elif (( imagenes > 0 )); then
    ok "$imagenes imagen(es) de las que usa el libro"
elif (( faltan == 0 )); then
    tenue "el libro no usa imágenes"
fi

# --- 5c. EL MARCO DEL PORTAL ---
# SE BAJA A UNA CARPETA NUEVA Y RECIÉN VERIFICADO REEMPLAZA AL ANTERIOR: UNA
# DESCARGA A MEDIAS NO PISA UN MARCO SANO. SIN RED, VALE EL DE LA GENERACIÓN
# ANTERIOR SI SIGUE ÍNTEGRO Y ES DEL MISMO PORTAL
if [[ "$DESTINO" == "portal" ]]; then
    paso "bajando el marco del portal"
    DIR_MARCO_NUEVO="$DIR_PROYECTO/tmp/marco-nuevo"
    rm -rf "$DIR_MARCO_NUEVO" && mkdir -p "$DIR_MARCO_NUEVO" ||
        morir "No se pudo preparar $DIR_MARCO_NUEVO"

    if bajar_marco "$URL_PORTAL" "$DIR_MARCO_NUEVO"; then
        rm -rf "$DIR_MARCO" || morir "No se pudo reemplazar $DIR_MARCO"
        mv "$DIR_MARCO_NUEVO" "$DIR_MARCO" || morir "No se pudo mover el marco a $DIR_MARCO"
        ok "$MARCO_ARCHIVOS archivo(s) del marco, verificados por su sha256"
    else
        MOTIVO_DESCARGA="$MARCO_MOTIVO"
        rm -rf "$DIR_MARCO_NUEVO"
        if verificar_marco "$DIR_MARCO" "$URL_PORTAL"; then
            aviso "$MOTIVO_DESCARGA: se usa el marco de la generación anterior"
        else
            morir "No se pudo bajar el marco del portal ($MOTIVO_DESCARGA) y no hay uno anterior que sirva ($MARCO_MOTIVO)"
        fi
    fi
fi

# --- 6. CÓDIGO (SC-42) ---
# LOS BLOQUES SE COLOREAN ANTES DE LA HOJA, SOBRE EL MISMO CANÓNICO; LA HOJA
# LOS LEE CON codigo_dir. SI EL COLOREO FALLA, NO HAY HTML.
paso "coloreando el código"
DIR_CODIGO="$DIR_PROYECTO/tmp/codigo/html-libro-$NOMBRE_BASE"
salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/colorear_codigo.sh" "$CANONICO" "$DIR_CODIGO" html 2>&1)
codigo=$?
if (( codigo != 0 )); then
    mostrar_cola "$salida"
    morir "No se pudo colorear el código: la salida HTML no se genera"
fi
ok "$(printf '%s\n' "$salida" | tail -n 1) bloque(s) de código"

# --- 7. CITAS (SC-57) ---
# CON tex4ht, EL TEXTO DE LAS CITAS Y DE LAS REFERENCIAS LO ESCRIBE biblatex
# EN citas.html, Y LA HOJA LO TOMA DE AHÍ (bib_dir). SIN citas.html NO HAY
# HTML: VOLVER A LAS PLANTILLAS DE LA HOJA SERÍA OTRO TEXTO QUE EL DEL PDF.
# CÓDIGO 3: CITAS SIN ENTRADA EN EL .bib; SE SIGUE Y EL AVISO SE HEREDA
PARAM_CITAS=()
if [[ "$MODO_CITAS" == "tex4ht" ]]; then
    paso "preparando las citas con biblatex"
    salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_citas_libro.sh" \
                "$DIR_PROYECTO" "$LISTA_CITAS_REL" "$INSUMOS_CITAS_REL" "$DIR_CITAS_REL" 2>&1)
    codigo=$?
    if (( codigo == SALIDA_AVISOS )); then
        mostrar_cola "$(grep '⚠' <<< "$salida")"
        aviso "la pasada de citas tiene avisos: el HTML se genera igual"
    elif (( codigo != SALIDA_OK )); then
        mostrar_cola "$salida"
        morir "No se pudieron preparar las citas: la salida HTML no se genera"
    fi
    ok "$(printf '%s\n' "$salida" | tail -n 1) cita(s) de biblatex"
    PARAM_CITAS=(bib_dir="$DIR_PROYECTO/$DIR_CITAS_REL")
else
    tenue "citas con las plantillas de la hoja"
fi

# --- 8. TRANSFORMACIÓN ---
# SE BORRA EL index.html ANTERIOR: SU EXISTENCIA ES PARTE DEL CRITERIO DE
# ÉXITO, Y EL DE LA CORRIDA ANTERIOR DARÍA UN FALSO POSITIVO.
# LA HOJA ESCRIBE docs/index.html CON xsl:result-document Y RUTA RELATIVA,
# QUE SE RESUELVE CONTRA EL DIRECTORIO DE TRABAJO: POR ESO SAXON CORRE DESDE
# LA RAÍZ DEL PROYECTO, DENTRO DE UN SUBSHELL PARA NO CAMBIAR EL DEL SCRIPT.
paso "transformando a HTML"

rm -f "$INDEX"

# LOS DE LA HOJA INTEGRADA: DÓNDE ESTÁN EL MARCO Y LAS PRIMERAS
PARAM_PORTAL=()
if [[ "$DESTINO" == "portal" ]]; then
    PARAM_PORTAL=(marco_dir="$DIR_MARCO" primeras_dir="$DIR_PRIMERAS")
fi

salida=$(cd "$DIR_PROYECTO" &&
         timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$CANONICO" \
            -xsl:"$XSL" \
            proyecto_dir="$DIR_PROYECTO" \
            manifiesto_libro="$MANIFIESTO_REL" \
            estilo_cita="$ESTILO_CITA" \
            codigo_dir="$DIR_CODIGO" \
            "${PARAM_CITAS[@]}" \
            "${PARAM_PORTAL[@]}" 2>&1)
codigo=$?

if (( codigo == 124 )); then
    morir "Saxon no terminó en $TIEMPO_SAXON segundos"
fi

if (( codigo != 0 )); then
    mostrar_cola "$salida"
    morir "Saxon no pudo generar el HTML"
fi

[[ -s "$INDEX" ]] || morir "Saxon terminó sin escribir docs/index.html"

if [[ -n "$salida" ]]; then
    tenue "mensajes de la transformación:"
    mostrar_cola "$salida" 10
fi

ok "docs/index.html"

# --- 9. VALIDACIÓN HTML5 (Nu Html Checker) ---
# vnu Y NO xmllint: xmllint ES UN PARSER HTML 4.01 Y DA FALSOS POSITIVOS CON
# aside, details Y EL RESTO DE HTML5. SIN --exit-zero-always, vnu DEVUELVE
# DISTINTO DE CERO CUANDO ENCUENTRA ERRORES, Y ESO ES LO QUE SE USA ACÁ.
paso "validando el HTML"

if [[ ! -f "$RUTA_VNU" ]]; then
    tenue "vnu no está instalado en $RUTA_VNU: el HTML no se validó"
else
    # LOS FRAGMENTOS DEL MARCO (assets/marco/<idioma>/*.xml) NO SON PÁGINAS:
    # SON XML SIN DOCTYPE, Y COMPARTIR LLEVA {u} Y {t}, QUE LA HOJA COMPLETA
    # AL COPIARLOS. DESDE QUE SON .xml, find YA NO LOS TOMA; LA EXCLUSIÓN DE
    # assets/marco/ QUEDA POR SI EL PORTAL PUBLICARA UN .html AHÍ. vnu RECIBE
    # TODOS LOS .html DE docs/ MENOS ESOS; CON EL
    # DESTINO AUTÓNOMO NO HAY MARCO Y LA LISTA ES LA DE SIEMPRE (INCLUIDOS LOS
    # GRÁFICOS DE assets/media/, SC-69)
    mapfile -t PAGINAS_VNU < <(find "$DIR_DOCS" -type f -name '*.html' \
                                    -not -path "$DIR_MARCO/*" | LC_ALL=C sort)
    salida=$(timeout "$TIEMPO_VNU" java -jar "$RUTA_VNU" \
                --format gnu --errors-only --skip-non-html "${PAGINAS_VNU[@]}" 2>&1)
    codigo=$?
    if (( codigo == 0 )); then
        ok "HTML5 sin errores"
    elif (( codigo == 124 )); then
        aviso "la validación HTML5 no terminó en $TIEMPO_VNU segundos"
    else
        errores=$(printf '%s\n' "$salida" | grep -c .)
        aviso "$errores error(es) de HTML5:"
        printf '%s\n' "$salida" | sed "s|$DIR_DOCS/||" |
            head -"$LINEAS_ERROR_VNU" | sed 's/^/     /'
        if (( errores > LINEAS_ERROR_VNU )); then
            tenue "(+$((errores - LINEAS_ERROR_VNU)) más)"
        fi
    fi
fi

# --- 10. RESUMEN ---
echo
titulo "$REGLA"
printf '%s✓ HTML generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n' "Archivo:" "$INDEX"
if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo

terminar
