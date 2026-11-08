#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.25.0.sh
# Propósito : Actualización 1.25.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Un tipo de declaración nuevo
#             en el catálogo tipo_declaracion: disponibilidad_datos, la
#             declaración de disponibilidad de los datos de la investigación
#             que SciELO pide en todos los artículos (Criterios SciELO
#             Brasil 2024, §2.3 y §5.2.2; decisión de Alberto, 07/11).
#             Es una FILA, no una columna: el formulario del artículo arma
#             sus declaraciones desde el catálogo (m_Articulo, las de
#             bloque nulo), así que aparece sola. En el canónico va como
#             <sec sec-type="data-availability"> en el back
#             (ensamblar-articulo-canonico.xsl, forma de JATS4R).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.25.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.24.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sin cambios.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.25.0"
PREVIO="actualizacion-1.24.0"
DESCRIPCION="Revistas: tipo de declaración disponibilidad_datos (SciELO)"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LA FILA. orden 15: ENTRE financiamiento (10) Y conflicto_interes (20), EN
# EL ORDEN EN QUE SE LEEN AL FINAL DEL ARTÍCULO. bloque NULO: ES DEL NÚCLEO,
# PARA TODAS LAS REVISTAS
CODIGO="disponibilidad_datos"
ETIQUETA="Disponibilidad de datos"
ORDEN=15

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

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.25.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el tipo de declaración «Disponibilidad de datos». No borra ni"
echo "modifica datos."
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

# LA CADENA ES ORDENADA: 1.25.0 VA SOBRE 1.24.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.24.0. Aplicala primero (actualizar-esquema-1.24.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='tipo_declaracion';")" != "1" ]; then
  error "No existe la tabla tipo_declaracion (1.13.0). No se modificó nada."
  exit 1
fi
EXISTE="$(valor "SELECT COUNT(*) FROM \`${DB}\`.tipo_declaracion WHERE codigo='${CODIGO}';")"
if [ "$EXISTE" = "1" ]; then
  ok "El tipo ${CODIGO} ya está en el catálogo."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Se agrega el tipo de declaración ${CODIGO} («${ETIQUETA}»)."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.25.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`tipo_declaracion\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla tipo_declaracion. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE (SC-22): BORRAR LA FILA. SE PUEDE
  # MIENTRAS NINGÚN ARTÍCULO TENGA UNA DECLARACIÓN DE ESE TIPO: SI LA HAY,
  # LAS DECLARACIONES QUEDARÍAN APUNTANDO A UN TIPO INEXISTENTE. EL BORRADO
  # LO COMPRUEBA EN LA MISMA ORDEN
  VOLVER_ATRAS="sudo mysql ${DB} -e \"DELETE FROM tipo_declaracion WHERE codigo='${CODIGO}' AND NOT EXISTS (SELECT 1 FROM articulo_declaracion WHERE tipo='${CODIGO}');\""

  # --- 5. CAMBIO ---
  mysql_adm "$DB" -e "INSERT INTO tipo_declaracion (codigo, etiqueta, bloque, orden, activo) VALUES ('${CODIGO}', '${ETIQUETA}', NULL, ${ORDEN}, 1);"
  ok "Agregado el tipo ${CODIGO}."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FILA="$(valor "SELECT CONCAT_WS('|', etiqueta, IFNULL(bloque, 'NULO'), orden, activo) FROM \`${DB}\`.tipo_declaracion WHERE codigo='${CODIGO}';")"
  if [ "$FILA" != "${ETIQUETA}|NULO|${ORDEN}|1" ]; then
    error "La fila no quedó como se esperaba: «${FILA}». NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: ${CODIGO} en el catálogo, del núcleo y activo."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (respaldo en ${RESPALDO}):"
  echo "  ${VOLVER_ATRAS}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: los tipos de declaración del núcleo, en el orden del formulario"
mysql_adm "$DB" -e "SELECT codigo, etiqueta, orden FROM tipo_declaracion WHERE bloque IS NULL AND activo = 1 ORDER BY orden, codigo;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.25.0 lista.${RESET}"
