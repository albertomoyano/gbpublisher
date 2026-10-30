#!/bin/bash
# Gráfico: el HTML y el PNG — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   grafico.sh <ruta_proyecto> <fig-id> <vista|generar> <idioma> <alto_px>
#
#   ruta_proyecto   raíz del proyecto
#   fig-id          el gráfico: graficos/<fig-id>.md
#   vista|generar   vista: solo el HTML, en tmp/vista-grafico/, para el
#                   formulario. generar: el HTML y el PNG, en media/
#   idioma          el de la pieza (es, en, pt…): el lang del HTML
#   alto_px         el alto de la ventana para el PNG, en píxeles CSS; lo
#                   calcula m_Graficos.AltoPx con la proporción del gráfico
#
# LO QUE ESCRIBE GAMBAS ANTES DE LANZARLO (SC-13: EL SCRIPT NO LEE LA BASE NI
# EL ARCHIVO DEL GRÁFICO; LO LEE Y LO CONTROLA m_Graficos)
#   tmp/vista-grafico/<fig-id>.json   la descripción del gráfico
#
# LO QUE ESCRIBE ESTE SCRIPT
#   tmp/vista-grafico/<fig-id>.html   el HTML: la plantilla con sus huecos
#                                     llenos (plantilla-grafico.html)
#   tmp/vista-grafico/<fig-id>.png    al generar
#   media/<fig-id>.html, .png         al generar, copiados al final y los dos
#                                     juntos: un fallo no deja media/ a medias
#   tmp/vista-grafico/veredicto.txt   el motivo, si frena: «error<TAB>…»
#
# EL CONTROL: chromium --dump-dom DEVUELVE EL DOM DESPUÉS DE LOS SCRIPTS,
# INCLUIDO EL DIBUJO QUE ESPERA A LA FUENTE. LA PLANTILLA DEJA
# data-listo="1" AL TERMINAR, O data-listo="error" Y data-motivo (MEDIDO).
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  el HTML (y el PNG, al generar) salieron y la plantilla dibujó
#   1  no salieron, o la plantilla no pudo dibujar: el motivo en el
#      veredicto y en la terminal
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_CHROMIUM=60

# EL ANCHO DEL GRÁFICO EN PÍXELES CSS (m_Graficos.ANCHO_PX) Y LA ESCALA DEL
# PNG: 844 × 3 = 2532 PÍXELES, UNOS 21 cm A 300 ppp (GV-139)
ANCHO_PX=844
ESCALA_PNG=3

# chromium, O OTRO BINARIO PARA PROBAR A MANO (COMO GBP_SAXON EN comun.sh)
CHROMIUM="${GBP_CHROMIUM:-chromium}"

# LOS RECURSOS DE LA PLANTILLA: LA COPIA LOCAL DE TRABAJO (SC-11)
DIR_CHART="$DIR_GBP_LOCAL/chart"
PLANTILLA="$DIR_CHART/plantilla-grafico.html"
CHARTJS="$DIR_CHART/chart.min.js"
FUENTE_REGULAR="$DIR_CHART/NotoSerif-Regular-latino.woff2"
FUENTE_NEGRITA="$DIR_CHART/NotoSerif-Bold-latino.woff2"

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
# Propósito : Corta: el motivo va al veredicto y a la terminal
# Parámetros: $1 mensaje
# ============================================================================
frenar() {
    anotar error "$1"
    morir "$1"
}

# ============================================================================
# Función   : url_de
# Propósito : La URL file:// de una ruta, con cada byte que no es letra,
#             cifra o «-._~» escrito %XX. chromium NO PUEDE RECIBIR LA RUTA
#             TAL CUAL: UN «#» EN LA CARPETA DEL PROYECTO LO LEE COMO EL
#             COMIENZO DEL FRAGMENTO, Y LA PÁGINA NO SE ENCUENTRA (MEDIDO)
# Parámetros: $1 ruta absoluta
# Retorna   : imprime la URL
# ============================================================================
url_de() {
    perl -e 'print "file://", join("/", map { my $s = $_; $s =~ s/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord $1)/ge; $s } split(m{/}, $ARGV[0], -1));' "$1"
}

# ============================================================================
# Función   : chromium_sin_ventana
# Propósito : Corre chromium sin ventana. SIN --user-data-dir: CON UN PERFIL
#             PROPIO, --dump-dom NO TERMINÓ NUNCA (MEDIDO, Chromium 153). SIN
#             ÉL, EL MODO SIN VENTANA TRABAJA EN UN PERFIL TEMPORAL
#             (/tmp/org.chromium.Chromium.*) Y NO TOCA EL DE QUIEN OPERA
# Parámetros: los argumentos de chromium que siguen a los comunes
# ============================================================================
chromium_sin_ventana() {
    timeout "$TIEMPO_CHROMIUM" "$CHROMIUM" --headless --no-sandbox --disable-gpu \
        --hide-scrollbars "$@"
}

# --- 2. ARGUMENTOS ---
if (( $# != 5 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <fig-id> <vista|generar> <idioma> <alto_px>"
fi
DIR_PROYECTO="${1%/}"
ID="$2"
MODO="$3"
IDIOMA="$4"
ALTO_PX="$5"
DIR_VISTA="$DIR_PROYECTO/tmp/vista-grafico"
VEREDICTO="$DIR_VISTA/veredicto.txt"
DESCRIPCION="$DIR_VISTA/$ID.json"
HTML="$DIR_VISTA/$ID.html"
PNG="$DIR_VISTA/$ID.png"

# EL VEREDICTO SE EMPIEZA ANTES QUE NADA: GAMBAS LO LEE SIEMPRE, Y UNO VIEJO
# DIRÍA ALGO DE OTRO GRÁFICO
mkdir -p "$DIR_VISTA" || morir "No se pudo crear $DIR_VISTA"
: > "$VEREDICTO"

encabezado "Gráfico $ID"

# --- 3. INSUMOS ---
paso "insumos"
[[ "$ID" =~ ^fig-[A-Za-z0-9-]+$ ]] || frenar "«$ID» no es el nombre de un gráfico (fig-…)"
[[ "$MODO" == "vista" || "$MODO" == "generar" ]] || frenar "modo desconocido: «$MODO» (se espera vista o generar)"
[[ "$IDIOMA" =~ ^[A-Za-z]{2,3}(-[A-Za-z0-9]+)*$ ]] || frenar "«$IDIOMA» no es un código de idioma"
[[ "$ALTO_PX" =~ ^[0-9]+$ ]] && (( ALTO_PX > 0 )) || frenar "«$ALTO_PX» no es un alto en píxeles"
requerir_comandos perl base64 timeout grep "$CHROMIUM"
[[ -f "$DESCRIPCION" ]] || frenar "falta tmp/vista-grafico/$ID.json: lo escribe gbpublisher antes de lanzar el script"
for archivo in "$PLANTILLA" "$CHARTJS" "$FUENTE_REGULAR" "$FUENTE_NEGRITA"; do
    [[ -f "$archivo" ]] || frenar "falta $archivo"
done
ok "graficos/$ID.md, descripción escrita"

# LO DE LA CORRIDA ANTERIOR SE BORRA: UN HTML O UN PNG VIEJO NO PUEDE PASAR
# POR NUEVO
rm -f "$HTML" "$PNG"

# --- 4. EL HTML: LA PLANTILLA CON SUS SEIS HUECOS ---
# TITULO ES EL ID, YA CONTROLADO ARRIBA (fig-[A-Za-z0-9-]+): NO NECESITA
# ESCAPE EN HTML. UN <title> VACÍO NO ES HTML VÁLIDO (29/10/2026)
# perl Y NO LA SUSTITUCIÓN DE bash: CON patsub_replacement (bash 5.2) UN «&»
# EN EL REEMPLAZO ES LO ENCONTRADO, Y chart.min.js TIENE MUCHOS. index Y
# substr NO INTERPRETAN NADA DEL REEMPLAZO: VA BYTE POR BYTE. CADA HUECO
# TIENE QUE ESTAR UNA SOLA VEZ, Y LOS DATOS VAN AL FINAL: UN TEXTO DEL
# USUARIO CON EL NOMBRE DE UN HUECO NO SE VUELVE A REEMPLAZAR
paso "el HTML"
regular=$(base64 -w0 "$FUENTE_REGULAR") || frenar "no se pudo codificar $FUENTE_REGULAR"
negrita=$(base64 -w0 "$FUENTE_NEGRITA") || frenar "no se pudo codificar $FUENTE_NEGRITA"
salida=$(GBP_TITULO="$ID" GBP_IDIOMA="$IDIOMA" GBP_REGULAR="$regular" GBP_NEGRITA="$negrita" \
    perl -e '
        use strict; use warnings;
        sub leer { my ($r) = @_; open(my $f, "<:raw", $r) or die "no se pudo leer $r\n";
                   local $/; my $t = <$f>; close $f; return $t; }
        my ($plantilla, $chartjs, $datos, $destino) = @ARGV;
        my $t = leer($plantilla);
        my @huecos = (["TITULO", $ENV{GBP_TITULO}], ["IDIOMA", $ENV{GBP_IDIOMA}], ["REGULAR", $ENV{GBP_REGULAR}],
                      ["NEGRITA", $ENV{GBP_NEGRITA}], ["CHARTJS", leer($chartjs)],
                      ["DATOS", leer($datos)]);
        for my $h (@huecos) {
            my $marca = "@@" . $h->[0] . "@@";
            my $i = index($t, $marca);
            die "la plantilla no tiene el hueco $h->[0]\n" if $i < 0;
            die "el hueco $h->[0] está más de una vez en la plantilla\n" if index($t, $marca, $i + 1) >= 0;
            substr($t, $i, length($marca)) = $h->[1];
        }
        open(my $s, ">:raw", $destino) or die "no se pudo escribir $destino\n";
        print $s $t; close $s or die "no se pudo escribir $destino\n";
    ' "$PLANTILLA" "$CHARTJS" "$DESCRIPCION" "$HTML" 2>&1)
if (( $? != 0 )) || [[ ! -s "$HTML" ]]; then
    mostrar_cola "$salida"
    frenar "no se armó el HTML: $(printf '%s' "$salida" | tail -1)"
fi
ok "tmp/vista-grafico/$ID.html"

# --- 5. EL CONTROL: QUE LA PLANTILLA HAYA DIBUJADO ---
# EL DOM DESPUÉS DE LOS SCRIPTS; DE <html …> SE LEEN data-listo Y data-motivo
paso "el dibujo"
dom=$(chromium_sin_ventana --dump-dom "$(url_de "$HTML")" 2>/dev/null)
etiqueta=$(printf '%s' "$dom" | grep -o -m1 '<html[^>]*>')
if [[ "$etiqueta" != *'data-listo="1"'* ]]; then
    motivo=$(printf '%s' "$etiqueta" | sed -n 's/.*data-motivo="\([^"]*\)".*/\1/p' | sed 's/&quot;/"/g; s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g')
    if [[ -n "$motivo" ]]; then
        frenar "la plantilla no pudo dibujar el gráfico: $motivo"
    fi
    frenar "chromium no devolvió el gráfico dibujado (¿está instalado? ¿venció el plazo de ${TIEMPO_CHROMIUM} s?)"
fi
ok "dibujado"

# --- 6. EN LA VISTA, ALCANZA CON EL HTML ---
if [[ "$MODO" == "vista" ]]; then
    terminar
fi

# --- 7. EL PNG: LA MISMA PÁGINA, A ESCALA 3 ---
# --screenshot ESPERA EL DIBUJO QUE SIGUE A document.fonts.load (GV-139)
paso "el PNG"
salida=$(chromium_sin_ventana --force-device-scale-factor="$ESCALA_PNG" \
    --window-size="$ANCHO_PX,$ALTO_PX" --screenshot="$PNG" "$(url_de "$HTML")" 2>&1)
if [[ ! -s "$PNG" ]]; then
    mostrar_cola "$salida"
    frenar "chromium no sacó el PNG"
fi
ok "tmp/vista-grafico/$ID.png ($((ANCHO_PX * ESCALA_PNG)) × $((ALTO_PX * ESCALA_PNG)) px)"

# --- 8. A media/: LOS DOS JUNTOS ---
# PRIMERO SE COPIAN CON UN NOMBRE TEMPORAL Y DESPUÉS SE RENOMBRAN: mv EN LA
# MISMA CARPETA ES ATÓMICO, Y UN FALLO DE COPIA NO TOCA LO QUE YA ESTABA
paso "a media/"
DIR_MEDIA="$DIR_PROYECTO/media"
mkdir -p "$DIR_MEDIA" || frenar "no se pudo crear media/"
cp -f "$HTML" "$DIR_MEDIA/.$ID.html.tmp" && cp -f "$PNG" "$DIR_MEDIA/.$ID.png.tmp" \
    || { rm -f "$DIR_MEDIA/.$ID.html.tmp" "$DIR_MEDIA/.$ID.png.tmp"; frenar "no se pudieron copiar las salidas a media/"; }
mv -f "$DIR_MEDIA/.$ID.html.tmp" "$DIR_MEDIA/$ID.html" && mv -f "$DIR_MEDIA/.$ID.png.tmp" "$DIR_MEDIA/$ID.png" \
    || frenar "no se pudieron dejar las salidas en media/"
ok "media/$ID.html"
ok "media/$ID.png"

terminar
