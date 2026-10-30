#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.16.0.sh
# Propósito : Actualización 1.16.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Vocabulario controlado (entrega
#             C3, decisiones de Alberto, 28/10):
#               1. Tabla nueva vocabulario_termino: catálogo GLOBAL de
#                  términos por vocabulario (MeSH, DeCS…) e idioma, con su
#                  identificador opcional (el código del vocabulario, p. ej.
#                  D006801; la URI de JATS vocab-term-identifier se arma al
#                  generar).
#               2. articulo_palabra_clave: columna identificador (copia por
#                  valor del catálogo, SC-23) y termino con colación
#                  utf8mb4_0900_as_ci.
#             COLACIÓN: utf8mb4_unicode_ci iguala ñ con n y vocales con y sin
#             tilde («Año» = «Ano», «Niño» = «Nino»): para la clave única de
#             un término eso es un error. utf8mb4_0900_as_ci no distingue
#             mayúsculas pero sí tildes y ñ (medido en 8.0.46, 28/10). La
#             búsqueda que sugiere términos usa 0900_ai_ci en la consulta.
#             Pasar termino a una colación MÁS estricta no puede crear
#             repetidos: la clave única se reconstruye sin conflictos.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.16.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK; colaciones 0900). No corre en
#             MariaDB tal cual (no tiene las colaciones 0900).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.15.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema), tabla por tabla.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: vocabulario_termino 5
#             (nueva) y articulo_palabra_clave 7 -> 8.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.16.0"
PREVIO="actualizacion-1.15.0"
DESCRIPCION="Revistas: catálogo de vocabulario controlado (vocabulario_termino); identificador y colación 0900_as_ci en articulo_palabra_clave"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS AL TERMINAR (LAS DE hEsquema)
COLS_VOC=5
COLS_KWD=8
# RESTRICCIONES CHECK AL TERMINAR, EN LAS TABLAS DE REVISTAS: 16 + 3 + 1
CHECK_ESPERADAS=20

LISTA_SQL="'revista','revista_plantilla_resumen','revista_plantilla_resumen_seccion','revista_plantilla_resumen_titulo','revista_seccion','revista_seccion_titulo','revista_bloque','numero','numero_dossier','numero_dossier_titulo','numero_contribuyente','articulo','articulo_texto','articulo_resumen_seccion','articulo_palabra_clave','articulo_contribuyente','contribuyente_afiliacion','contribuyente_credit','articulo_financiamiento','tipo_declaracion','articulo_declaracion','articulo_relacion','articulo_ubicacion','vocabulario_termino'"

# «SIN DATO» ES NULL (GV-74): identificador NULL CON CHECK (<> '').
# DOS CLAVES ÚNICAS: EL TÉRMINO, Y EL IDENTIFICADOR (UN DESCRIPTOR ES UN SOLO
# TÉRMINO POR IDIOMA). MySQL ADMITE VARIOS NULL EN UNA CLAVE ÚNICA: LOS
# TÉRMINOS SIN IDENTIFICADOR NO CHOCAN ENTRE SÍ
DDL_VOC="CREATE TABLE IF NOT EXISTS vocabulario_termino (
  id_termino INT NOT NULL AUTO_INCREMENT,
  vocabulario VARCHAR(50) NOT NULL COMMENT 'MeSH, DeCS... (por valor, SC-23)',
  idioma VARCHAR(20) NOT NULL COMMENT 'Código BCP 47 (SC-23)',
  termino VARCHAR(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL COMMENT 'Sin distinguir mayúsculas; sí tildes y ñ',
  identificador VARCHAR(50) NULL DEFAULT NULL COMMENT 'Código del vocabulario: D006801 (MeSH)',
  PRIMARY KEY (id_termino),
  UNIQUE KEY uq_voc_termino (vocabulario, idioma, termino),
  UNIQUE KEY uq_voc_identificador (vocabulario, idioma, identificador),
  CONSTRAINT chk_voc_vocabulario CHECK (vocabulario <> ''),
  CONSTRAINT chk_voc_termino CHECK (termino <> ''),
  CONSTRAINT chk_voc_identificador CHECK (identificador <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo global de términos de vocabularios controlados';"

DDL_KWD="ALTER TABLE articulo_palabra_clave
  MODIFY termino VARCHAR(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_ci NOT NULL,
  ADD COLUMN identificador VARCHAR(50) NULL DEFAULT NULL COMMENT 'Copia del catálogo (SC-23); solo vocabulario controlado' AFTER termino,
  ADD CONSTRAINT chk_kwd_identificador CHECK (identificador <> '');"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.16.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el catálogo de vocabulario controlado y el identificador de cada término."
echo "No borra datos. La columna termino de las palabras clave pasa a distinguir tildes y ñ."
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

# LA CADENA ES ORDENADA: 1.16.0 VA SOBRE 1.15.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.15.0. Aplicala primero (actualizar-esquema-1.15.0.sh)."
  exit 1
fi

# LAS COLACIONES 0900 SON DE MySQL 8: SIN ELLAS NO HAY NADA QUE HACER
if [ "$(valor "SELECT COUNT(*) FROM information_schema.COLLATIONS WHERE COLLATION_NAME IN ('utf8mb4_0900_as_ci','utf8mb4_0900_ai_ci');")" != "2" ]; then
  error "El servidor no tiene las colaciones utf8mb4_0900_as_ci / _ai_ci (hace falta MySQL 8)."
  exit 1
fi

# --- 3. ESTADO REAL, TABLA POR TABLA ---
CREAR_VOC=0
N="$(columnas_de vocabulario_termino)"
if [ "$N" = "0" ]; then
  CREAR_VOC=1
elif [ "$N" != "${COLS_VOC}" ]; then
  error "La tabla vocabulario_termino tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

CORREGIR_KWD=0
N="$(columnas_de articulo_palabra_clave)"
if [ "$N" = "7" ]; then
  CORREGIR_KWD=1
elif [ "$N" != "${COLS_KWD}" ]; then
  error "La tabla articulo_palabra_clave tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

if [ "$CREAR_VOC" -eq 0 ] && [ "$CORREGIR_KWD" -eq 0 ]; then
  ok "No hay nada que agregar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$CREAR_VOC" -eq 1 ] && info "Se crea vocabulario_termino."
  [ "$CORREGIR_KWD" -eq 1 ] && info "Se modifica articulo_palabra_clave ($(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo_palabra_clave;") filas)."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.16.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`articulo_palabra_clave\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla articulo_palabra_clave. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CAMBIOS ---
  if [ "$CREAR_VOC" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_VOC}"
    ok "Creada vocabulario_termino."
  fi
  if [ "$CORREGIR_KWD" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_KWD}"
    ok "Modificada articulo_palabra_clave."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de vocabulario_termino)" != "${COLS_VOC}" ]; then
    error "La tabla vocabulario_termino no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(columnas_de articulo_palabra_clave)" != "${COLS_KWD}" ] || [ "$(nulable articulo_palabra_clave identificador)" != "YES" ]; then
    error "La tabla articulo_palabra_clave no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(valor "SELECT COLLATION_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='articulo_palabra_clave' AND COLUMN_NAME='termino';")" != "utf8mb4_0900_as_ci" ]; then
    error "articulo_palabra_clave.termino no quedó con la colación utf8mb4_0900_as_ci."
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
  ok "Verificación correcta: tabla nueva, columna nueva, colación y ${CHK} restricciones CHECK."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: palabras clave por vocabulario"
mysql_adm "$DB" -e "SELECT IFNULL(vocabulario, '(del autor)') AS vocabulario, idioma, COUNT(*) AS terminos FROM articulo_palabra_clave GROUP BY vocabulario, idioma ORDER BY vocabulario, idioma;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.16.0 lista.${RESET}"
