#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.15.0.sh
# Propósito : Actualización 1.15.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. ADITIVA: agrega la columna ror a
#             contribuyente_afiliacion, que el modelo lógico preveía y la
#             1.13.0 omitió (error de la 1.13.0). Sin ella, JATS no puede
#             emitir <institution-id institution-id-type="ror"> ni Crossref
#             (esquema 5.3.0 o posterior) recibir la afiliación con su ROR.
#             Forma guardada: la URL completa, que es la forma preferida por
#             ROR y la que piden JATS y Crossref (ror.readme.io: identifier,
#             jats, crossref). «Sin dato» es NULL (GV-74); el CHECK exige la
#             forma https://ror.org/0 + 6 caracteres Crockford base 32 (sin
#             i, l, o, u) + 2 dígitos. El dígito de control (ISO 7064 Mod
#             97-10) lo verifica la aplicación (m_Articulo.RorValido).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.15.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK); permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.14.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema).
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: contribuyente_afiliacion
#             7 -> 8.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.15.0"
PREVIO="actualizacion-1.14.0"
DESCRIPCION="Revistas: ROR en la afiliación del contribuyente (contribuyente_afiliacion.ror)"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS AL TERMINAR (LA DE hEsquema)
COLS_AFIL=8
# RESTRICCIONES CHECK DE LAS 23 TABLAS DE LA 1.13.0 AL TERMINAR: 15 + 1
CHECK_ESPERADAS=16

LISTA_SQL="'revista','revista_plantilla_resumen','revista_plantilla_resumen_seccion','revista_plantilla_resumen_titulo','revista_seccion','revista_seccion_titulo','revista_bloque','numero','numero_dossier','numero_dossier_titulo','numero_contribuyente','articulo','articulo_texto','articulo_resumen_seccion','articulo_palabra_clave','articulo_contribuyente','contribuyente_afiliacion','contribuyente_credit','articulo_financiamiento','tipo_declaracion','articulo_declaracion','articulo_relacion','articulo_ubicacion'"

# UN SOLO ALTER: COLUMNA Y CHECK JUNTOS (ATÓMICO). LA COLUMNA NACE NULL EN
# TODAS LAS FILAS, ASÍ QUE EL CHECK NO RECHAZA NINGUNA EXISTENTE.
# EL FLAG 'c' HACE LA COMPARACIÓN SENSIBLE A MAYÚSCULAS: LA COLACIÓN DE LA
# TABLA ES _ci Y SIN ÉL ACEPTARÍA «02MHBDP94» (MEDIDO EN 8.0.46, 28/10)
DDL_AFIL="ALTER TABLE contribuyente_afiliacion
  ADD COLUMN ror VARCHAR(100) NULL DEFAULT NULL COMMENT 'URL completa: https://ror.org/0xxxxxxNN' AFTER pais,
  ADD CONSTRAINT chk_afil_ror CHECK (REGEXP_LIKE(ror, '^https://ror[.]org/0[a-hj-km-np-tv-z0-9]{6}[0-9]{2}\$', 'c'));"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.15.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el ROR a las afiliaciones de los contribuyentes de artículos."
echo "Es aditiva: no modifica ni borra datos."
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

# LA CADENA ES ORDENADA: 1.15.0 VA SOBRE 1.14.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.14.0. Aplicala primero (actualizar-esquema-1.14.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
# 7 COLUMNAS: SE AGREGA. 8 CON ror: YA ESTÁ. CUALQUIER OTRA: ABORTA SIN TOCAR
N="$(columnas_de contribuyente_afiliacion)"
TIENE_ROR="$(valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='contribuyente_afiliacion' AND COLUMN_NAME='ror';")"
if [ "$N" = "7" ] && [ "$TIENE_ROR" = "0" ]; then
  SOLO_INFORME=0
  info "Se agrega ror a contribuyente_afiliacion ($(valor "SELECT COUNT(*) FROM \`${DB}\`.contribuyente_afiliacion;") filas)."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
elif [ "$N" = "${COLS_AFIL}" ] && [ "$TIENE_ROR" = "1" ]; then
  ok "No hay nada que agregar."
  SOLO_INFORME=1
else
  error "La tabla contribuyente_afiliacion tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.15.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`contribuyente_afiliacion\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla contribuyente_afiliacion. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. AGREGADO ---
  mysql_adm "$DB" -e "${DDL_AFIL}"
  ok "Agregada contribuyente_afiliacion.ror."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de contribuyente_afiliacion)" != "${COLS_AFIL}" ] || [ "$(nulable contribuyente_afiliacion ror)" != "YES" ]; then
    error "La tabla contribuyente_afiliacion no quedó como se esperaba."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas de revistas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: columna nulable y ${CHK} restricciones CHECK."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba agregada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: columnas de contribuyente_afiliacion"
mysql_adm "$DB" -e "SELECT COLUMN_NAME, IS_NULLABLE, COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='contribuyente_afiliacion' ORDER BY ORDINAL_POSITION;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.15.0 lista.${RESET}"
