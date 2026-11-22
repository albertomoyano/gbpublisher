#!/bin/bash
# Empuje del proyecto al repositorio remoto de GitHub — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   empujar_remoto.sh <ruta_proyecto> <url_remoto> <integracion> <mensaje>
#
#   ruta_proyecto  la raíz del proyecto, que es también la raíz del
#                  repositorio (un repo = un proyecto, m_Git)
#   url_remoto     la URL SSH del remoto (git@github.com:usuario/repo.git),
#                  o «-» si Gambas no tiene el usuario. Solo se usa si el
#                  proyecto todavía no tiene «origin»
#   integracion    «si» o «no»: si el proyecto usa la integración con GitHub
#                  Actions. La decide Gambas, que lee la base (SC-13)
#   mensaje        el mensaje del commit
#
# QUÉ HACE
#   Reemplaza a m_GitHub.EmpujarGitHubRemoto, que tipeaba los comandos en la
#   terminal con Input() sin recibir el resultado (deuda de SC-13). El JSON de
#   la integración lo escribe Gambas ANTES de lanzar este script, porque sale
#   de la base. El commit lo hace commit_local.sh, anidado (apartado 8).
#
# SOLO SSH (decisión de Alberto, 21/11/2026)
#   Un remoto que no es SSH no se corrige: el script se detiene y muestra el
#   comando para corregirlo a mano.
#
# NADA ESPERA UNA RESPUESTA
#   El script se lanza mientras FFileManager está abierto con ShowModal, y un
#   formulario modal no deja escribir en la terminal de FMain. Por eso ssh y
#   git corren sin preguntas (BatchMode, GIT_TERMINAL_PROMPT=0): si la clave
#   pide una frase de paso que el agente no tiene, falla y lo dice, en lugar
#   de quedarse esperando algo que nadie puede escribir.
#
# CÓDIGOS: los de comun.sh
#   0  se empujó
#   3  se empujó, con avisos (por ejemplo, no había cambios para commitear)
#   1  no se empujó
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
RAMA="main"
# SIN PREGUNTAS: VER «NADA ESPERA UNA RESPUESTA» EN LA CABECERA
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=15"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "EMPUJE AL REPOSITORIO REMOTO"

# --- 2. ARGUMENTOS ---
if (( $# != 4 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <url_remoto> <integracion> <mensaje>"
fi

DIR_PROYECTO="${1%/}"
URL_REMOTO="$2"
INTEGRACION="$3"
MENSAJE="$4"

requerir_comandos git ssh

[[ -d "$DIR_PROYECTO" ]] || morir "No existe la carpeta del proyecto: $DIR_PROYECTO"
[[ -n "$MENSAJE" ]] || morir "Falta el mensaje del commit"
case "$INTEGRACION" in
    si|no) ;;
    *) morir "El tercer argumento tiene que ser «si» o «no»: $INTEGRACION" ;;
esac

cd "$DIR_PROYECTO" || morir "No se pudo entrar a la carpeta del proyecto"

# --- 3. CLAVE SSH ---
paso "Acceso a GitHub por SSH"
if [[ ! -f "$HOME/.ssh/id_ed25519.pub" && ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
    morir "No hay ninguna clave SSH en ~/.ssh/. Para generarla: ssh-keygen -t ed25519; después cargá la clave pública en GitHub → Settings → SSH and GPG keys"
fi

# ssh -T CONTRA GitHub SALE CON 1 AUNQUE AUTENTIQUE (NO DA SHELL): EL
# VEREDICTO ES EL TEXTO, COMO EN LA VERSIÓN DE GAMBAS QUE ESTO REEMPLAZA
SALIDA_SSH=$(ssh -o BatchMode=yes -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)
if [[ "$SALIDA_SSH" == *"successfully authenticated"* ]]; then
    ok "GitHub acepta la clave"
elif [[ "$SALIDA_SSH" == *"Permission denied"* ]]; then
    morir "La clave SSH existe pero GitHub la rechazó (o pide una frase de paso que el agente no tiene). Verificá que la clave pública esté cargada en GitHub → Settings → SSH and GPG keys"
else
    morir "No se pudo conectar con GitHub. Verificá la conexión a internet. Detalle: $SALIDA_SSH"
fi

# --- 4. REPOSITORIO LOCAL ---
paso "Repositorio local"
if [[ ! -d .git ]]; then
    git init --initial-branch="$RAMA" >/dev/null || morir "No se pudo inicializar el repositorio"
    ok "Repositorio inicializado"
else
    tenue "Ya existía"
fi

# --- 5. REMOTO: SOLO SSH ---
URL_ACTUAL=$(git remote get-url origin 2>/dev/null) || URL_ACTUAL=""
if [[ -z "$URL_ACTUAL" ]]; then
    [[ "$URL_REMOTO" != "-" ]] || morir "El proyecto no tiene remoto configurado y falta el usuario de GitHub. Cerrá el gestor de archivos, escribí el usuario en la barra de FMain y volvé a empujar"
    [[ "$URL_REMOTO" == git@* ]] || morir "La URL del remoto no es SSH: $URL_REMOTO"
    git remote add origin "$URL_REMOTO" || morir "No se pudo configurar el remoto"
    ok "Remoto configurado: $URL_REMOTO"
elif [[ "$URL_ACTUAL" == git@* ]]; then
    ok "Remoto: $URL_ACTUAL"
else
    if [[ "$URL_REMOTO" != "-" ]]; then
        morir "El remoto no usa SSH: $URL_ACTUAL. gbpublisher empuja solo por SSH. Para corregirlo: git -C \"$DIR_PROYECTO\" remote set-url origin $URL_REMOTO"
    fi
    morir "El remoto no usa SSH: $URL_ACTUAL. gbpublisher empuja solo por SSH. Para corregirlo: git -C \"$DIR_PROYECTO\" remote set-url origin git@github.com:<usuario>/<repositorio>.git"
fi

# --- 6. RAMA ---
RAMA_ACTUAL=$(git symbolic-ref --short HEAD 2>/dev/null) || RAMA_ACTUAL=""
if [[ "$RAMA_ACTUAL" != "$RAMA" ]]; then
    git branch -M "$RAMA" || morir "No se pudo renombrar la rama a $RAMA"
    tenue "Rama renombrada a $RAMA"
fi

# --- 7. INTEGRACIÓN: SINCRONIZAR CON LOS COMMITS DEL ACTION ---
# fetch DESCARGA LOS COMMITS DEL ACTION (INCLUIDO .github-ids.json); reset
# --mixed MUEVE HEAD AL REMOTO CONSERVANDO EL DIRECTORIO DE TRABAJO. EL
# COMMIT QUEDA ENCIMA DEL REMOTO Y EL push ES FAST-FORWARD. SI EL REMOTO
# TODAVÍA NO TIENE LA RAMA (PRIMER EMPUJE), NO HAY CON QUÉ SINCRONIZAR
if [[ "$INTEGRACION" == "si" ]]; then
    paso "Sincronización con el remoto (integración con GitHub)"
    if git ls-remote --exit-code --heads origin "$RAMA" >/dev/null 2>&1; then
        git fetch origin || morir "No se pudo descargar el remoto"
        git reset --mixed "origin/$RAMA" >/dev/null || morir "No se pudo sincronizar con origin/$RAMA"
        ok "Sincronizado con origin/$RAMA"
    else
        tenue "El remoto todavía no tiene la rama $RAMA: primer empuje"
    fi
fi

# --- 8. COMMIT ---
# EL COMMIT SE ARMA EN UN SOLO LUGAR: commit_local.sh, EL MISMO DEL BOTÓN DE
# COMMIT LOCAL. ANIDADO (GBP_ANIDADO=1, SC-53) SE PRESENTA COMO UN PASO MÁS.
# SUS AVISOS («NO HABÍA CAMBIOS») LOS IMPRIME ÉL; ACÁ SOLO SE CUENTAN PARA EL
# CÓDIGO FINAL: SIN CAMBIOS, SE EMPUJAN IGUAL LOS COMMITS PENDIENTES
GBP_ANIDADO=1 bash "$DIR_ENGINE/commit_local.sh" "$DIR_PROYECTO" "$MENSAJE"
CODIGO_COMMIT=$?
case "$CODIGO_COMMIT" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") AVISOS=$((AVISOS + 1)) ;;
    *) morir "No se pudo hacer el commit: no se empuja" ;;
esac

# --- 9. EMPUJE ---
paso "Empuje"
if ! git push --set-upstream origin "$RAMA"; then
    morir "El remoto rechazó el empuje o no se pudo conectar. El motivo está arriba"
fi
ok "Empujado a origin/$RAMA"

terminar
