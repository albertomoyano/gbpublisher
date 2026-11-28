#!/usr/bin/env bash
#
# ============================================
# Script    : configurar-conexion.sh
# Propósito : Deja en regla la credencial con la que gbpublisher se conecta a
#             su base: la cuenta app_user de MySQL y el archivo de conexión
#             del usuario, ~/.gbpublisher/conexion.conf (SC-106).
#             Desde la versión que lee ese archivo, la contraseña ya no está
#             en el código: sin el archivo, la aplicación no se conecta.
# Uso       : bash configurar-conexion.sh              (SIN sudo)
#             bash configurar-conexion.sh --con-sudo   pide permiso con sudo
#                                                      y no con pkexec (lo
#                                                      usa instalar-gbpublisher.sh,
#                                                      que ya lo tiene)
#             configurar-conexion.sh --root <archivo>  parte de root; la llama
#                                                      este mismo script
# Qué hace  : decide por el estado real, como crear-cuenta-gbweb.sh (SC-81):
#             1. Si el archivo existe y abre una sesión en la base: no toca
#                nada.
#             2. Si no: genera una contraseña nueva, la pone en TODAS las
#                cuentas app_user del servidor (localhost y los rangos de red)
#                y escribe el archivo. Después verifica que abre la sesión.
# Formato   : un archivo de opciones de MySQL. [client] con user, password y
#             host; [mysql] con database. database NO va en [client]:
#             mysqldump la rechaza («unknown variable 'database=...'»,
#             GV-222). Lo leen la aplicación (gb.settings, GV-223), mysql y
#             mysqldump (--defaults-extra-file).
# Contraseña: 28 letras y cifras al azar, empezando por letra, más un sufijo
#             fijo con mayúscula, minúscula, cifra y guion bajo, por si el
#             servidor tiene validate_password. Sin «#» (en un archivo de
#             opciones empieza un comentario) ni comillas. Nadie la tipea ni
#             la recuerda. Nunca va en una línea de comandos: viaja a la
#             parte de root en un archivo temporal 600 y a MySQL por la
#             entrada estándar.
# Permisos  : la parte de MySQL corre como root, con pkexec (ventana gráfica,
#             GV-206). Sin sesión gráfica (por ejemplo, por SSH) usa sudo.
# Atención  : cambiar la contraseña corta a toda máquina que se conecte a
#             esta base con la contraseña vieja. A cada una hay que copiarle
#             el archivo nuevo, con host = la IP de este servidor.
# Salida    : 0 en regla; 1 algo quedó sin resolver.
#             El aviso de copiar el archivo a otras máquinas sale solo si el
#             servidor tiene cuentas app_user de red (no solo localhost).
# ============================================

set -uo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
DB_USER="app_user"
SUFIJO_CLAVE="Gb7_"

if [ -t 1 ]; then
  ROJO=$'\e[0;31m'; VERDE=$'\e[0;32m'; AMBAR=$'\e[0;33m'
  AZUL=$'\e[0;34m'; NEGRITA=$'\e[1m'; RESET=$'\e[0m'
else
  ROJO=""; VERDE=""; AMBAR=""; AZUL=""; NEGRITA=""; RESET=""
fi

info()  { echo "${AZUL}➜${RESET} $*"; }
ok()    { echo "${VERDE}✔${RESET} $*"; }
warn()  { echo "${AMBAR}⚠${RESET} $*"; }
error() { echo "${ROJO}✖${RESET} $*" >&2; }

# ============================================
# Función   : parte_root
# Propósito : Corre como root (pkexec o sudo). Pone la contraseña del archivo
#             temporal en todas las cuentas app_user. No toca ~/.gbpublisher:
#             pkexec limpia el entorno (GV-206)
# Parámetros: $1 — archivo temporal con la contraseña (una línea)
# Retorna   : 0 bien, solo la cuenta de localhost; 4 bien, y hay cuentas de
#             red (el aviso de las otras máquinas sale solo en ese caso);
#             2 no existe app_user; 3 MySQL no responde o falló
# ============================================
parte_root() {
  local archivo="$1" clave hosts host sql=""

  # --- 1. LA CONTRASEÑA ---
  clave="$(head -n 1 "$archivo" 2>/dev/null)"
  if [ -z "$clave" ]; then
    error "No se pudo leer la contraseña nueva."
    return 3
  fi

  # --- 2. LAS CUENTAS app_user QUE EXISTEN ---
  # EN MySQL LA IDENTIDAD ES usuario@host: CADA RANGO DE RED ES UNA CUENTA
  if ! hosts="$(mysql -N -B -e "SELECT host FROM mysql.user WHERE user='${DB_USER}';" 2>&1)"; then
    error "El servidor de base de datos no responde: ${hosts}"
    return 3
  fi
  if [ -z "$hosts" ]; then
    error "No existe la cuenta ${DB_USER} en el servidor: la base no está instalada."
    return 2
  fi

  # --- 3. ALTER USER POR LA ENTRADA ESTÁNDAR, NUNCA POR ARGUMENTO ---
  while IFS= read -r host; do
    sql+="ALTER USER '${DB_USER}'@'${host}' IDENTIFIED BY '${clave}';"$'\n'
  done <<< "$hosts"
  if ! printf '%s' "$sql" | mysql; then
    error "No se pudo cambiar la contraseña de ${DB_USER}."
    return 3
  fi
  while IFS= read -r host; do
    ok "Contraseña nueva en ${DB_USER}@${host}."
  done <<< "$hosts"

  # --- 4. ¿HAY CUENTAS DE RED? ---
  # CON SOLO localhost EL AVISO DE LAS OTRAS MÁQUINAS ES RUIDO
  if grep -qvx 'localhost' <<< "$hosts"; then
    return 4
  fi
  return 0
}

# --- MODO ROOT: LO LLAMA ESTE MISMO SCRIPT CON pkexec O sudo ---
if [ "${1:-}" = "--root" ]; then
  [ "$(id -u)" -eq 0 ] || { error "--root es solo para la parte de administrador."; exit 1; }
  parte_root "${2:-}"
  exit $?
fi

# ============================================
# Función   : abre_sesion
# Propósito : Prueba la credencial del archivo como la usa la aplicación:
#             app_user, en localhost, sobre la base gbpublisher
# Parámetros: $1 — ruta del archivo de conexión
# Retorna   : 0 si abre la sesión y lee esquema_version
# ============================================
abre_sesion() {
  mysql --defaults-extra-file="$1" -h localhost -N -B \
    -e "SELECT COUNT(*) FROM \`${DB}\`.esquema_version;" >/dev/null 2>&1
}

# --- 1. COMO USUARIO COMÚN, NO COMO ROOT ---
# EL ARCHIVO ES DEL USUARIO QUE VA A USAR gbpublisher Y VA A SU CARPETA
if [ "$(id -u)" -eq 0 ]; then
  error "Este script se corre SIN sudo: el archivo de conexión es de su usuario."
  error "Ejecute:  bash configurar-conexion.sh"
  exit 1
fi

ELEVAR="pkexec"
[ "${1:-}" = "--con-sudo" ] && ELEVAR="sudo"
# SIN SESIÓN GRÁFICA NO HAY VENTANA DE pkexec
if [ "$ELEVAR" = "pkexec" ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
  ELEVAR="sudo"
fi

for comando in mysql "$ELEVAR" tr head mktemp; do
  if ! command -v "$comando" >/dev/null 2>&1; then
    error "Falta el programa «${comando}»."
    exit 1
  fi
done

DIR_CONF="${HOME}/.gbpublisher"
CONF="${DIR_CONF}/conexion.conf"
SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"

echo
echo "${NEGRITA}gbpublisher — conexión con la base de datos${RESET}"
echo

# --- 2. ¿YA ESTÁ EN REGLA? ---
if [ -f "$CONF" ] && abre_sesion "$CONF"; then
  chmod 600 "$CONF" 2>/dev/null || true
  ok "El archivo de conexión está en regla: ${CONF}"
  ok "No se modificó nada."
  exit 0
fi
if [ -f "$CONF" ]; then
  warn "El archivo de conexión existe pero no abre una sesión en la base: se rehace."
else
  info "No hay archivo de conexión: se crea."
fi

# --- 3. CONTRASEÑA NUEVA ---
# 28 LETRAS Y CIFRAS, LA PRIMERA UNA LETRA, MÁS EL SUFIJO FIJO. head LEE UNA
# CANTIDAD FIJA Y tr LA FILTRA ENTERA: CON «tr </dev/urandom | head» tr MUERE
# POR SIGPIPE, Y BAJO pipefail ESO ES UN ERROR (MEDIDO: SALIDA 141)
ALEA="$(head -c 4096 /dev/urandom | tr -dc 'A-Za-z0-9')"
LETRAS="${ALEA//[0-9]/}"
CLAVE="${LETRAS:0:1}${ALEA:0:27}${SUFIJO_CLAVE}"
if [ "${#CLAVE}" -ne 32 ]; then
  error "No se pudo generar la contraseña."
  exit 1
fi

# --- 4. LA PARTE DE ADMINISTRADOR ---
# LA CONTRASEÑA VIAJA EN UN ARCHIVO 600 DEL USUARIO: ROOT LO LEE, NADIE MÁS
TEMPORAL="$(umask 077 && mktemp)"
trap 'rm -f "$TEMPORAL"' EXIT
printf '%s\n' "$CLAVE" > "$TEMPORAL"

echo
if [ "$ELEVAR" = "pkexec" ]; then
  printf '  %s➜ Se abre una ventana que pide su contraseña. Escríbala y acepte.%s\n' "$AMBAR" "$RESET"
else
  info "Se pide su contraseña de administrador (sudo)."
fi
echo
"$ELEVAR" /bin/bash "$SCRIPT" --root "$TEMPORAL"
CODIGO=$?
HAY_RED=0
case "$CODIGO" in
  0)   ;;
  4)   HAY_RED=1 ;;
  2)   error "Primero hay que instalar la base de datos (instalar-gbpublisher.sh)."; exit 1 ;;
  126) error "Se cerró la ventana de la contraseña: no se cambió nada."; exit 1 ;;
  127) error "No se obtuvo permiso de administrador: no se cambió nada."; exit 1 ;;
  *)   error "No se pudo terminar (código ${CODIGO}). El motivo está más arriba."; exit 1 ;;
esac

# --- 5. EL ARCHIVO: ENTERO, CON PERMISOS 600, Y MOVIDO A SU LUGAR ---
# SI SE CORTA A LA MITAD, EL ARCHIVO ANTERIOR NO QUEDA A MEDIO ESCRIBIR
mkdir -p "$DIR_CONF"
NUEVO="$(umask 077 && mktemp "${DIR_CONF}/conexion.conf.XXXXXX")"
{
  echo "# gbpublisher: credencial de la base de datos (configurar-conexion.sh)."
  echo "# Archivo de opciones de MySQL. No lo comparta: tiene la contraseña."
  echo "[client]"
  echo "user=${DB_USER}"
  echo "password=${CLAVE}"
  echo "host=localhost"
  echo
  echo "[mysql]"
  echo "database=${DB}"
} > "$NUEVO"
chmod 600 "$NUEVO"
mv -f "$NUEVO" "$CONF"
ok "Archivo de conexión escrito: ${CONF} (solo lo lee su usuario)."

# --- 6. VERIFICACIÓN CON EL ARCHIVO ---
if abre_sesion "$CONF"; then
  ok "La conexión con la base funciona."
else
  error "El archivo quedó escrito, pero no abre una sesión en la base."
  error "Copie lo que muestra esta ventana y envíeselo a quien le da soporte."
  exit 1
fi

echo
echo "${VERDE}${NEGRITA}Listo.${RESET} Ya puede abrir gbpublisher."
if [ "$HAY_RED" -eq 1 ]; then
  warn "Esta base tiene cuentas para otras máquinas: cada una necesita una copia"
  warn "de este archivo, con host = la IP de esta computadora (ver BBDD_LEEME.md §6)."
fi
echo
exit 0
