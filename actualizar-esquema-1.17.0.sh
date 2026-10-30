#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.17.0.sh
# Propósito : Actualización 1.17.0 de la base de gbpublisher: SOLO DATOS, sin
#             cambios de estructura. Corrige dos términos CRediT a la forma
#             exacta de la tabla oficial de JATS4R (recomendación CRediT,
#             v1.2; su validador da ERROR si vocab-term no es un término
#             exacto): «Writing – Original draft» → «Writing – original draft» y
#             «Writing – Review & editing» → «Writing – review & editing».
#             Decisión de Alberto (28/10): corregir, aunque credit_roles es
#             compartida con libros (decisión 5), porque libros también tiene
#             que emitir el término exacto.
#             Corrige el catálogo credit_roles y, además, cualquier texto ya
#             grabado con la forma vieja en las columnas que guardan CRediT
#             por valor (texto «a; b» y JSON). La comparación es BINARIA:
#             solo cambia la forma con mayúscula; la correcta no se toca.
#             Ningún código lee credit_roles (los textos salen de
#             FCreditRoles, que ya usa la forma oficial).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.17.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE (sin la forma vieja no
#             hay nada que cambiar); respaldo verificado; verificación
#             posterior. Exige la 1.16.0 registrada.
# Lote      : sin cambios en m_ConexionBD.ObtenerEsquemaEsperado (no cambia
#             ninguna estructura).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.17.0"
PREVIO="actualizacion-1.16.0"
DESCRIPCION="Datos: dos términos CRediT a la forma exacta de JATS4R (original draft, review & editing)"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# EN UNA SOLA TRANSACCIÓN: O SE CORRIGE TODO O NADA
DML="START TRANSACTION;
UPDATE credit_roles SET nombre = 'Writing – original draft' WHERE nombre LIKE BINARY 'Writing – Original draft';
UPDATE credit_roles SET nombre = 'Writing – review & editing' WHERE nombre LIKE BINARY 'Writing – Review & editing';
UPDATE articulo_autor SET taxonomia_credit = REPLACE(REPLACE(taxonomia_credit, 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') WHERE (taxonomia_credit LIKE BINARY '%Writing – Original draft%' OR taxonomia_credit LIKE BINARY '%Writing – Review & editing%');
UPDATE capitulo_autor SET taxonomia_credit = REPLACE(REPLACE(taxonomia_credit, 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') WHERE (taxonomia_credit LIKE BINARY '%Writing – Original draft%' OR taxonomia_credit LIKE BINARY '%Writing – Review & editing%');
UPDATE autores SET credit_roles_tipicos = REPLACE(REPLACE(credit_roles_tipicos, 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') WHERE (credit_roles_tipicos LIKE BINARY '%Writing – Original draft%' OR credit_roles_tipicos LIKE BINARY '%Writing – Review & editing%');
UPDATE contribuyente_credit SET rol_credit = REPLACE(REPLACE(rol_credit, 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') WHERE (rol_credit LIKE BINARY '%Writing – Original draft%' OR rol_credit LIKE BINARY '%Writing – Review & editing%');
UPDATE articulo_autor SET contribuciones_credit = CAST(REPLACE(REPLACE(CAST(contribuciones_credit AS CHAR), 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') AS JSON) WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%');
UPDATE capitulo_autor SET contribuciones_credit = CAST(REPLACE(REPLACE(CAST(contribuciones_credit AS CHAR), 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') AS JSON) WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%');
UPDATE libro_autor SET contribuciones_credit = CAST(REPLACE(REPLACE(CAST(contribuciones_credit AS CHAR), 'Writing – Original draft', 'Writing – original draft'), 'Writing – Review & editing', 'Writing – review & editing') AS JSON) WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%');
COMMIT;"

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

columnas_de() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# YES SI LA COLUMNA ADMITE NULL
nulable() {
  valor "SELECT IS_NULLABLE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización de gbpublisher a 1.17.0 (solo datos)${RESET}"
echo "--------------------------------------------------"
echo "Corrige dos términos CRediT a la forma oficial de JATS4R. No cambia la estructura."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

VERSION="$(valor "SELECT VERSION();")"
if [ "$(valor "SELECT (CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED) * 10000 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED) * 100 + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED)) >= 80016;")" != "1" ]; then
  error "El servidor es ${VERSION}: hace falta MySQL 8.0.16 o posterior para las restricciones CHECK."
  exit 1
fi

info "Servidor: ${VERSION}"

# LA CADENA ES ORDENADA: 1.17.0 VA SOBRE 1.16.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.16.0. Aplicala primero (actualizar-esquema-1.16.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL: CUÁNTOS VALORES TIENEN LA FORMA VIEJA ---
viejos() {
  valor "SELECT (SELECT COUNT(*) FROM \`${DB}\`.credit_roles WHERE nombre LIKE BINARY 'Writing – Original draft' OR nombre LIKE BINARY 'Writing – Review & editing') + (SELECT COUNT(*) FROM \`${DB}\`.articulo_autor WHERE (taxonomia_credit LIKE BINARY '%Writing – Original draft%' OR taxonomia_credit LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.capitulo_autor WHERE (taxonomia_credit LIKE BINARY '%Writing – Original draft%' OR taxonomia_credit LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.autores WHERE (credit_roles_tipicos LIKE BINARY '%Writing – Original draft%' OR credit_roles_tipicos LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.contribuyente_credit WHERE (rol_credit LIKE BINARY '%Writing – Original draft%' OR rol_credit LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.articulo_autor WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.capitulo_autor WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%')) + (SELECT COUNT(*) FROM \`${DB}\`.libro_autor WHERE (CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Original draft%' OR CAST(contribuciones_credit AS CHAR) LIKE BINARY '%Writing – Review & editing%'));"
}
N="$(viejos)"
if [ "$N" = "0" ]; then
  ok "No hay nada que corregir."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Valores con la forma vieja: ${N} (catálogo y textos grabados)."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.17.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`credit_roles\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla credit_roles. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CORRECCIÓN ---
  mysql_adm "$DB" -e "${DML}"
  ok "Términos corregidos."

  # --- 6. VERIFICACIÓN POSTERIOR: NO QUEDA NINGUNA FORMA VIEJA ---
  N="$(viejos)"
  if [ "$N" != "0" ]; then
    error "Quedan ${N} valores con la forma vieja. NO se registra la actualización."
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: no queda ninguna forma vieja."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: catálogo CRediT"
mysql_adm "$DB" -e "SELECT id, nombre FROM credit_roles ORDER BY id;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.17.0 lista.${RESET}"
