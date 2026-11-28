#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.3.0.sh
# Propósito : Actualización 2.3.0 de la base de gbpublisher. AGREGA una sola
#             columna, al final de libros_md (SC-22):
#               crossref_fecha_deposito DATE NULL
#             Es la fecha en que el libro se depositó en Crossref. La marca
#             la persona en FMetadatosLibro después de subir el XML: la
#             aplicación no deposita, así que es la única que lo sabe
#             (decisión de Alberto del 25/11/2026, claude/crossref-libros.md,
#             F2). NULL = sin depositar.
#             Con la fecha cargada, la composición avisa «redepositá» si las
#             páginas cambian, y no se puede renombrar una pieza con DOI
#             (su página h-<nombre>.html es la URL del DOI, F4).
#             ADITIVA: no se modifica ninguna fila ni se borra nada. Las
#             columnas viejas (crossref_estado y crossref_fecha_deposito de
#             capitulos, las de editorial de libros_md, colecciones.doi_prefix)
#             se borran en la 2.4.0, después de instalar la aplicación que ya
#             no las usa (el mismo camino que 1.26.0 y 1.27.0).
# Uso       : sudo bash actualizar-esquema-2.3.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Exige
#             la 2.2.0.
# Orden     : se aplica ANTES de usar la aplicación nueva, que la exige
#             (m_ConexionBD: libros_md con 90 columnas). La aplicación
#             anterior sigue funcionando con la columna nueva.
# Volver    : ALTER TABLE libros_md DROP COLUMN crossref_fecha_deposito; el
#             script muestra el comando. El respaldo queda por las dudas.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.3.0"
PREVIO="actualizacion-2.2.0"
DESCRIPCION="libros_md.crossref_fecha_deposito: fecha del depósito en Crossref, la marca la persona"
# EL RESPALDO VA A LA CARPETA DEL USUARIO QUE PIDIÓ EL PERMISO, NO A LA DE
# root: CON sudo, HOME ES /root (GV-235, MEDIDO EN MINT 22). sudo DEJA
# SUDO_USER Y pkexec DEJA PKEXEC_UID. GBP_DIR_RESPALDOS LO FIJA QUIEN LLAMA
USUARIO_RESPALDO="${SUDO_USER:-}"
if [ -z "$USUARIO_RESPALDO" ] && [ -n "${PKEXEC_UID:-}" ]; then
  USUARIO_RESPALDO="$(id -nu "$PKEXEC_UID" 2>/dev/null || true)"
fi
HOME_RESPALDO="$HOME"
if [ -n "$USUARIO_RESPALDO" ]; then
  HOME_RESPALDO="$(getent passwd "$USUARIO_RESPALDO" | cut -d: -f6 || true)"
  [ -n "$HOME_RESPALDO" ] || HOME_RESPALDO="$HOME"
fi
DIR_RESPALDO="${GBP_DIR_RESPALDOS:-${HOME_RESPALDO}/gbpublisher-respaldos}"

# AL SALIR, POR DONDE SEA, LA CARPETA Y LOS RESPALDOS QUEDAN A NOMBRE DE ESE
# USUARIO: SIN ESTO SERÍAN DE root Y NO LOS PODRÍA ABRIR NI BORRAR
entregar_respaldos() {
  if [ -n "$USUARIO_RESPALDO" ] && [ "$(id -u)" -eq 0 ] && [ -d "$DIR_RESPALDO" ]; then
    chown -R "${USUARIO_RESPALDO}:" "$DIR_RESPALDO" 2>/dev/null || true
  fi
}
trap entregar_respaldos EXIT
TABLA="libros_md"
COLUMNA="crossref_fecha_deposito"
DEFINICION="DATE NULL DEFAULT NULL COMMENT 'Depósito en Crossref: lo marca la persona después de subir el XML; NULL = sin depositar'"

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

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

mysql_adm() {
  $SUDO mysql --default-character-set=utf8mb4 "$@"
}

# -r (raw): SIN ÉL, EL MODO -B DUPLICA LAS BARRAS DE UN VALOR CON APÓSTROFO
valor() {
  mysql_adm -N -B -r -e "$1"
}

existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}' AND COLUMN_NAME='${COLUMNA}';"
}

columnas() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.3.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega a libros_md la fecha del depósito en Crossref. No se modifica"
echo "ninguna fila: todos los libros quedan sin depositar hasta que lo marques."
echo

# --- 2. VERIFICACIONES PREVIAS ---
if ! command -v mysql >/dev/null 2>&1 || ! command -v mysqldump >/dev/null 2>&1; then
  error "Faltan los clientes mysql o mysqldump."
  exit 1
fi

if [ -n "$SUDO" ] && ! sudo -v; then
  error "No se pudieron obtener permisos de administrador (sudo)."
  exit 1
fi

if ! mysql_adm -e "SELECT 1;" >/dev/null 2>&1; then
  error "No se pudo conectar al servidor con la cuenta administrativa."
  exit 1
fi

if [ "$(existe_tabla esquema_version)" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" = "0" ]; then
  error "Falta la 2.2.0. Aplique primero actualizar-esquema-2.2.0.sh."
  exit 1
fi

if [ "$(existe_tabla "${TABLA}")" != "1" ]; then
  error "No existe la tabla ${TABLA}. No se modificó nada."
  exit 1
fi

# --- 3. ESTADO REAL ---
VOLVER="sudo mysql ${DB} -e \"ALTER TABLE ${TABLA} DROP COLUMN ${COLUMNA};\""
APLICADO_AHORA=0

if [ "$(existe_columna)" = "1" ]; then
  ok "${TABLA}.${COLUMNA} ya existe."
else
  info "${TABLA} tiene $(columnas) columnas; queda con una más, al final."

  # --- 4. CONFIRMACIÓN ---
  echo
  if [ "${GBP_SIN_PREGUNTAS:-0}" = "1" ]; then
    # LO LLAMA EL INSTALADOR, QUE YA PIDIÓ LA CONFIRMACIÓN (SC-107)
    RESPUESTA="SI"
  else
    read -r -p "Para continuar, escriba SI en mayúsculas: " RESPUESTA
  fi
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.3.0-$(date '+%Y%m%d-%H%M%S').sql"
  info "Respaldo en ${RESPALDO}"

  $SUDO mysqldump --single-transaction --routines --triggers --events \
    --default-character-set=utf8mb4 "$DB" > "$RESPALDO"

  if [ ! -s "$RESPALDO" ]; then
    error "El respaldo quedó vacío. No se modificó nada."
    exit 1
  fi
  if ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
    error "El respaldo no terminó completo (falta la marca final). No se modificó nada."
    exit 1
  fi
  if ! grep -q "CREATE TABLE \`${TABLA}\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla ${TABLA}. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  FILAS_ANTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA};")"
  COLUMNAS_ANTES="$(columnas)"

  # --- 6. LA COLUMNA ---
  # SIN AFTER: VA AL FINAL (SC-22)
  mysql_adm "$DB" -e "ALTER TABLE ${TABLA} ADD COLUMN ${COLUMNA} ${DEFINICION};"
  APLICADO_AHORA=1

  # --- 7. VERIFICACIÓN POSTERIOR ---
  ULTIMA="$(valor "SELECT COLUMN_NAME FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}' ORDER BY ORDINAL_POSITION DESC LIMIT 1;")"
  FILAS_DESPUES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA};")"
  CON_FECHA="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA} WHERE ${COLUMNA} IS NOT NULL;")"
  if [ "$ULTIMA" != "$COLUMNA" ] || [ "$(columnas)" != "$((COLUMNAS_ANTES + 1))" ]; then
    error "La columna no quedó al final o la cuenta de columnas no da. NO se registra la actualización."
    exit 1
  fi
  if [ "$FILAS_ANTES" != "$FILAS_DESPUES" ] || [ "$CON_FECHA" != "0" ]; then
    error "${TABLA}: ${FILAS_ANTES} filas antes, ${FILAS_DESPUES} después, ${CON_FECHA} con fecha. NO se registra la actualización."
    exit 1
  fi
  ok "Verificación correcta: ${TABLA} con $(columnas) columnas, ${FILAS_DESPUES} libros, ninguno depositado."
fi

# --- 8. REGISTRO ---
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
  mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 9. CÓMO VOLVER ATRÁS ---
if [ "$APLICADO_AHORA" = "1" ]; then
  echo
  info "Para volver atrás:"
  echo "  ${VOLVER}"
fi

echo
ok "${NEGRITA}Actualización 2.3.0 lista.${RESET}"
