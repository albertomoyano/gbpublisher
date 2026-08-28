#!/bin/bash
# Buscador de palabras por consola

# --- 1. COLORES (SOLO SI LA SALIDA ES UNA TERMINAL) ---
if [[ -t 1 ]]; then
    C_ARCHIVO=$'\033[1;38;2;125;211;252m'   # CELESTE CLARO
    C_LINEA=$'\033[38;2;250;204;21m'        # AMARILLO BASE
    C_RESET=$'\033[0m'
else
    C_ARCHIVO="" ; C_LINEA="" ; C_RESET=""
fi

# --- 2. EXTENSIÓN ---
IFS= read -rp "¿En qué tipo de archivo? [md] " EXT
EXT="${EXT#.}"        # ACEPTAR TANTO «md» COMO «.md»
EXT="${EXT:-md}"     # VALOR POR DEFECTO SI SE PULSA ENTER

# --- 3. TEXTO A BUSCAR ---
IFS= read -rp "¿Qué desea buscar? " BUSCAR
if [[ -z "$BUSCAR" ]]; then
    echo "No ingresó ningún texto."
    exit 1
fi

# --- 4. APLICAR -w SOLO SI EL PATRÓN EMPIEZA Y TERMINA EN CARÁCTER DE PALABRA ---
if [[ "$BUSCAR" =~ ^[[:alnum:]_] ]] && [[ "$BUSCAR" =~ [[:alnum:]_]$ ]]; then
    PALABRA=(-w)
else
    PALABRA=()
fi

# --- 5. BÚSQUEDA, ORDEN Y FORMATO ---
echo
echo "Buscando «$BUSCAR» en archivos .$EXT..."
echo "================================================================================"
grep -Rn --include="*.$EXT" -F "${PALABRA[@]}" -- "$BUSCAR" . \
    | sort -t: -k1,1 -k2,2n \
    | awk -F: -v ca="$C_ARCHIVO" -v cl="$C_LINEA" -v cr="$C_RESET" \
        '{printf "%s%-45s%s %slínea %s%s\n", ca, $1, cr, cl, $2, cr}'
RET=${PIPESTATUS[0]}
echo "================================================================================"
if [[ $RET -ne 0 ]]; then
    echo "No se encontraron coincidencias."
fi
