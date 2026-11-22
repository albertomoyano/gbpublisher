#!/bin/bash
# Commit en el repositorio local del proyecto — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   commit_local.sh <ruta_proyecto> <mensaje>
#
#   ruta_proyecto  la raíz del proyecto, que es también la raíz del
#                  repositorio (un repo = un proyecto, m_Git)
#   mensaje        el mensaje del commit
#
# QUÉ HACE
#   Reemplaza a m_GitHub.EmpujarGitLocal, que tipeaba git init, git add y
#   git commit en la terminal con Input() sin recibir el resultado (deuda de
#   SC-13). Lo llaman:
#     - Gambas, por la lanzadora (SC-53): el botón de commit local de FMain;
#     - empujar_remoto.sh, anidado (GBP_ANIDADO=1), entre la sincronización
#       con el remoto y el push: el commit se arma en un solo lugar.
#
# .github-ids.json
#   Vive solo en el remoto y lo gestiona el Action de la integración: git add
#   lo marcaría como borrado y el commit llevaría el borrado al remoto en el
#   próximo push. restore --staged lo devuelve al estado de HEAD. Sin
#   integración el archivo no existe y no hay nada que restaurar. (El commit
#   local que esto reemplaza no lo hacía.)
#
# CÓDIGOS: los de comun.sh
#   0  se hizo el commit
#   3  no había cambios para commitear (aviso)
#   1  no se pudo
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
RAMA="main"
export GIT_TERMINAL_PROMPT=0

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "COMMIT EN EL REPOSITORIO LOCAL"

# --- 2. ARGUMENTOS ---
if (( $# != 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <mensaje>"
fi

DIR_PROYECTO="${1%/}"
MENSAJE="$2"

requerir_comandos git

[[ -d "$DIR_PROYECTO" ]] || morir "No existe la carpeta del proyecto: $DIR_PROYECTO"
[[ -n "$MENSAJE" ]] || morir "Falta el mensaje del commit"

cd "$DIR_PROYECTO" || morir "No se pudo entrar a la carpeta del proyecto"

# --- 3. REPOSITORIO ---
if [[ ! -d .git ]]; then
    git init --initial-branch="$RAMA" >/dev/null || morir "No se pudo inicializar el repositorio"
    ok "Repositorio inicializado"
fi

# --- 4. CAMBIOS ---
git add -A || morir "No se pudieron agregar los cambios"
git restore --staged .github-ids.json 2>/dev/null || true

if git diff --cached --quiet; then
    aviso "No había cambios para commitear"
    terminar
fi

# --- 5. COMMIT ---
# EL MENSAJE LLEGA COMO ARGUMENTO (Shell$ DESDE LA LANZADORA, SC-53): SIN
# ESCAPADO A MANO
git commit -m "$MENSAJE" >/dev/null || morir "No se pudo hacer el commit"
ok "Commit: $(git log -1 --format='%h %s')"

terminar
