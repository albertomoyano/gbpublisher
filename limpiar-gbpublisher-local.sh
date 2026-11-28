#!/usr/bin/env bash
#
# ============================================
# Script    : limpiar-gbpublisher-local.sh
# Propósito : Saca de ~/.gbpublisher las copias de los recursos del paquete
#             que gbpublisher ya no lee (SC-11, modelo del 25/11/2026: los
#             recursos se leen de /usr/share/gbpublisher). Antes de borrar,
#             archiva TODO lo que saca en un .tar.gz verificado: no se pierde
#             nada, ni lo que solo existía en la copia local.
#
#             SE ARCHIVAN Y SE SACAN (eran copias del paquete o restos de
#             versiones anteriores):
#               assets auditor chart dtd filters fonts github latex llm media
#               schemas schematron themes xslt
#             EN scripts/ SE SACAN SOLO LOS IGUALES A LOS DEL PAQUETE: LOS
#             DEMÁS SON DEL USUARIO Y QUEDAN.
#             NO SE TOCA: gbpublisher.conf, conexion.conf, .ips.txt,
#               .superuser.sqlite, respaldo/, regex/, snippets/, plantillas/,
#               editorial/, scripts propios, ni ninguna otra carpeta que no
#               esté en la lista (biblatex-old/, csl/…).
#
# Uso       : bash limpiar-gbpublisher-local.sh            (muestra qué haría)
#             bash limpiar-gbpublisher-local.sh --aplicar  (lo hace)
#             Con GBP_RECURSOS=/ruta/a/.hidden se compara contra el
#             repositorio en vez de /usr/share/gbpublisher.
# Orden     : DESPUÉS de instalar la versión de gbpublisher que lee los
#             recursos del sistema, y con gbpublisher CERRADO: una versión
#             anterior volvería a copiar las carpetas al arrancar.
# Volver    : tar -xzf <archivo> -C ~/.gbpublisher (el script muestra la ruta)
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
LOCAL="${HOME}/.gbpublisher"
SISTEMA="${GBP_RECURSOS:-/usr/share/gbpublisher}"
DIR_ARCHIVO="${HOME}/gbpublisher-respaldos"
CARPETAS=(assets auditor chart dtd filters fonts github latex llm media schemas schematron themes xslt)
APLICAR=0
[[ "${1:-}" == "--aplicar" ]] && APLICAR=1

if [ -t 1 ]; then
  VERDE=$'\e[0;32m'; AMBAR=$'\e[0;33m'; AZUL=$'\e[0;34m'; ROJO=$'\e[0;31m'; NEGRITA=$'\e[1m'; RESET=$'\e[0m'
else
  VERDE=""; AMBAR=""; AZUL=""; ROJO=""; NEGRITA=""; RESET=""
fi
info()  { echo "${AZUL}➜${RESET} $*"; }
ok()    { echo "${VERDE}✔${RESET} $*"; }
warn()  { echo "${AMBAR}⚠${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

echo
echo "${NEGRITA}Limpieza de ~/.gbpublisher${RESET}"
echo "--------------------------"

# --- 1. VERIFICACIONES ---
[[ -d "$LOCAL" ]] || { ok "No existe $LOCAL: no hay nada que limpiar."; exit 0; }
[[ -d "$SISTEMA/xslt" && -d "$SISTEMA/latex" ]] ||
  { error "No están los recursos del sistema en $SISTEMA. ¿Está instalado gbpublisher?"; exit 1; }
if pgrep -x gbpublisher >/dev/null 2>&1 || pgrep -f 'gbpublisher\.gambas' >/dev/null 2>&1; then
  error "gbpublisher está abierto: cerralo antes de limpiar."
  exit 1
fi

# --- 2. QUÉ SE SACA ---
A_SACAR=()
for c in "${CARPETAS[@]}"; do
  [[ -e "$LOCAL/$c" ]] && A_SACAR+=("$c")
done
# scripts/: SOLO LOS IGUALES A LOS DEL PAQUETE
SCRIPTS_PAQUETE=()
SCRIPTS_PROPIOS=()
if [[ -d "$LOCAL/scripts" ]]; then
  for f in "$LOCAL"/scripts/*; do
    [[ -f "$f" ]] || continue
    n="$(basename "$f")"
    if [[ -f "$SISTEMA/scripts/$n" ]] && cmp -s "$f" "$SISTEMA/scripts/$n"; then
      SCRIPTS_PAQUETE+=("scripts/$n")
    else
      SCRIPTS_PROPIOS+=("$n")
    fi
  done
fi

if (( ${#A_SACAR[@]} == 0 && ${#SCRIPTS_PAQUETE[@]} == 0 )); then
  ok "~/.gbpublisher ya está limpia."
  exit 0
fi

info "Se archivan y se sacan:"
for c in "${A_SACAR[@]}"; do
  printf '    %-12s %6s archivo(s)\n' "$c/" "$(find "$LOCAL/$c" -type f | wc -l)"
done
(( ${#SCRIPTS_PAQUETE[@]} > 0 )) && printf '    %-12s %6s copia(s) de los scripts del paquete\n' "scripts/" "${#SCRIPTS_PAQUETE[@]}"
(( ${#SCRIPTS_PROPIOS[@]} > 0 )) && info "Quedan en scripts/ (tuyos): ${SCRIPTS_PROPIOS[*]}"
info "No se toca nada más: configuración, conexión, respaldos, patrones, snippets, plantillas, editorial/."

if (( APLICAR == 0 )); then
  echo
  warn "No se hizo nada. Para hacerlo: bash $(basename "$0") --aplicar"
  exit 0
fi

# --- 3. EL ARCHIVO, VERIFICADO ---
mkdir -p "$DIR_ARCHIVO"
ARCHIVO="$DIR_ARCHIVO/gbpublisher-local-$(date '+%Y%m%d-%H%M%S').tar.gz"
info "Archivando en $ARCHIVO"
tar -czf "$ARCHIVO" -C "$LOCAL" "${A_SACAR[@]}" "${SCRIPTS_PAQUETE[@]}"
# LA LISTA DEL ARCHIVO TIENE QUE TENER CADA ARCHIVO QUE SE VA A BORRAR
ESPERADOS=$( (cd "$LOCAL" && find "${A_SACAR[@]}" "${SCRIPTS_PAQUETE[@]}" -type f) | sort)
GUARDADOS=$(tar -tzf "$ARCHIVO" | grep -v '/$' | sort)
if [[ "$ESPERADOS" != "$GUARDADOS" ]]; then
  error "El archivo no tiene todo lo que se iba a sacar. No se borró nada."
  exit 1
fi
ok "Archivo verificado: $(grep -c . <<< "$GUARDADOS") archivo(s), $(du -h "$ARCHIVO" | cut -f1)."

# --- 4. SACAR ---
for c in "${A_SACAR[@]}"; do rm -rf "${LOCAL:?}/$c"; done
for f in "${SCRIPTS_PAQUETE[@]}"; do rm -f "${LOCAL:?}/$f"; done
ok "Listo. Quedó en ~/.gbpublisher:"
ls -A "$LOCAL" | sed 's/^/    /'
echo
info "Para volver atrás: tar -xzf $ARCHIVO -C $LOCAL"
