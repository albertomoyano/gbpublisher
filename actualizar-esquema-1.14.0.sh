#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.14.0.sh
# Propósito : Actualización 1.14.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Corrige un error de diseño de la
#             1.13.0 que violaba GV-74:
#               numero.volumen, numero.numero, numero.suplemento y
#               articulo_palabra_clave.vocabulario eran NOT NULL DEFAULT ''.
#             En Gambas la cadena vacía ES Null (GV-68): Edit + Update escribe
#             NULL donde se asigna "" (GV-74), y el Update sobre esas columnas
#             falla («Column 'suplemento' cannot be null»; medido en
#             FMetadatosNumero, 25/10). La regla de GV-74 es la que se aplica:
#             la columna admite NULL y lleva CHECK (columna <> ''); «sin
#             dato» es NULL, nunca ''.
#             La clave única no puede apoyarse en columnas nulables (MySQL
#             trata cada NULL como distinto): se apoya en una columna
#             GENERADA que lleva el vacío a '' (precedente: notas_miembros
#             .clave_activa, 1.10.0).
#               1. numero: las tres columnas pasan a NULL; '' existentes
#                  pasan a NULL; CHECK (<> '') en cada una; columna generada
#                  clave_identidad; la clave única pasa a
#                  (id_revista, clave_identidad).
#               2. articulo_palabra_clave: vocabulario pasa a NULL (NULL = del
#                  autor); CHECK; columna generada clave_vocabulario; la clave
#                  única pasa a (id_articulo, idioma, clave_vocabulario,
#                  termino).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.14.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK); permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.13.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema), tabla por tabla.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: numero 15 -> 16 y
#             articulo_palabra_clave 6 -> 7. m_Numero compara la identidad
#             con <=> (igualdad que admite NULL).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.14.0"
PREVIO="actualizacion-1.13.0"
DESCRIPCION="Revistas: volumen, número, suplemento y vocabulario admiten NULL (GV-74); claves únicas por columna generada"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS AL TERMINAR (LAS DE hEsquema)
COLS_NUMERO=16
COLS_KWD=7
# RESTRICCIONES CHECK DE LAS 23 TABLAS DE LA 1.13.0 AL TERMINAR: 11 + 3 + 1
CHECK_ESPERADAS=15

# LA LISTA DE TABLAS DE LA 1.13.0, PARA CONTAR LAS CHECK
LISTA_SQL="'revista','revista_plantilla_resumen','revista_plantilla_resumen_seccion','revista_plantilla_resumen_titulo','revista_seccion','revista_seccion_titulo','revista_bloque','numero','numero_dossier','numero_dossier_titulo','numero_contribuyente','articulo','articulo_texto','articulo_resumen_seccion','articulo_palabra_clave','articulo_contribuyente','contribuyente_afiliacion','contribuyente_credit','articulo_financiamiento','tipo_declaracion','articulo_declaracion','articulo_relacion','articulo_ubicacion'"

# TRES PASOS POR TABLA, EN ESTE ORDEN:
#   1. MODIFY A NULL: ANTES NO SE PUEDE ESCRIBIR NULL (MEDIDO: EL UPDATE
#      PRIMERO FALLA CON «Column 'suplemento' cannot be null»).
#   2. UPDATE: LOS '' PASAN A NULL. SIN ÉL, EL CHECK RECHAZARÍA LAS FILAS.
#   3. ALTER CON LA COLUMNA GENERADA, LA CLAVE Y LOS CHECK, ATÓMICO.
# LOS TRES SON REPETIBLES: SI SE CORTA A MITAD, LA CORRIDA SIGUIENTE VE 15 (O
# 6) COLUMNAS Y LOS REPITE
DDL_NUMERO_1="ALTER TABLE numero
  MODIFY volumen VARCHAR(20) NULL DEFAULT NULL,
  MODIFY numero VARCHAR(20) NULL DEFAULT NULL,
  MODIFY suplemento VARCHAR(20) NULL DEFAULT NULL;"
DML_NUMERO="UPDATE numero SET volumen = NULLIF(volumen, ''), numero = NULLIF(numero, ''), suplemento = NULLIF(suplemento, '');"
DDL_NUMERO="ALTER TABLE numero
  ADD COLUMN clave_identidad VARCHAR(70) GENERATED ALWAYS AS (CONCAT(IFNULL(volumen, ''), '|', IFNULL(numero, ''), '|', IFNULL(suplemento, ''))) STORED COMMENT 'Identidad del número dentro de la revista; los NULL cuentan como vacío',
  DROP INDEX uq_numero_identidad,
  ADD UNIQUE KEY uq_numero_identidad (id_revista, clave_identidad),
  ADD CONSTRAINT chk_numero_volumen CHECK (volumen <> ''),
  ADD CONSTRAINT chk_numero_numero CHECK (numero <> ''),
  ADD CONSTRAINT chk_numero_suplemento CHECK (suplemento <> '');"

DDL_KWD_1="ALTER TABLE articulo_palabra_clave
  MODIFY vocabulario VARCHAR(50) NULL DEFAULT NULL COMMENT 'NULL: del autor. MeSH, DeCS...';"
DML_KWD="UPDATE articulo_palabra_clave SET vocabulario = NULLIF(vocabulario, '');"
DDL_KWD="ALTER TABLE articulo_palabra_clave
  ADD COLUMN clave_vocabulario VARCHAR(50) GENERATED ALWAYS AS (IFNULL(vocabulario, '')) STORED COMMENT 'Para la clave única: NULL cuenta como vacío',
  DROP INDEX uq_kwd,
  ADD UNIQUE KEY uq_kwd (id_articulo, idioma, clave_vocabulario, termino),
  ADD CONSTRAINT chk_kwd_vocabulario CHECK (vocabulario <> '');"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.14.0${RESET}"
echo "--------------------------------------------------"
echo "Corrige volumen, número, suplemento y vocabulario: «sin dato» pasa a ser NULL (GV-74)."
echo "No toca otras tablas. Los valores vacíos que haya pasan a NULL."
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

# LA CADENA ES ORDENADA: 1.14.0 VA SOBRE 1.13.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.13.0. Aplicala primero (actualizar-esquema-1.13.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL, TABLA POR TABLA ---
# TRES ESTADOS POR TABLA: CON LAS COLUMNAS DE 1.13.0, CON O SIN EL PRIMER PASO
# HECHO (SE CORRIGE), YA CORREGIDA (NO SE TOCA) O CUALQUIER OTRA (ABORTA SIN
# TOCAR NADA)
CORREGIR_NUMERO=0
N="$(columnas_de numero)"
if [ "$N" = "15" ]; then
  CORREGIR_NUMERO=1
elif [ "$N" = "${COLS_NUMERO}" ] && [ "$(nulable numero suplemento)" = "YES" ]; then
  CORREGIR_NUMERO=0
else
  error "La tabla numero tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

CORREGIR_KWD=0
N="$(columnas_de articulo_palabra_clave)"
if [ "$N" = "6" ]; then
  CORREGIR_KWD=1
elif [ "$N" = "${COLS_KWD}" ] && [ "$(nulable articulo_palabra_clave vocabulario)" = "YES" ]; then
  CORREGIR_KWD=0
else
  error "La tabla articulo_palabra_clave tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

if [ "$CORREGIR_NUMERO" -eq 0 ] && [ "$CORREGIR_KWD" -eq 0 ]; then
  ok "No hay nada que corregir."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$CORREGIR_NUMERO" -eq 1 ] && info "Se corrige numero ($(valor "SELECT COUNT(*) FROM \`${DB}\`.numero;") filas)."
  [ "$CORREGIR_KWD" -eq 1 ] && info "Se corrige articulo_palabra_clave ($(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo_palabra_clave;") filas)."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.14.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`numero\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla numero. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. CORRECCIONES ---
  # LOS TRES PASOS DE CADA TABLA, EN ORDEN (VER LA CONFIGURACIÓN)
  if [ "$CORREGIR_NUMERO" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_NUMERO_1}"
    mysql_adm "$DB" -e "${DML_NUMERO}"
    mysql_adm "$DB" -e "${DDL_NUMERO}"
    ok "Corregida numero."
  fi
  if [ "$CORREGIR_KWD" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_KWD_1}"
    mysql_adm "$DB" -e "${DML_KWD}"
    mysql_adm "$DB" -e "${DDL_KWD}"
    ok "Corregida articulo_palabra_clave."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de numero)" != "${COLS_NUMERO}" ] || [ "$(nulable numero volumen)" != "YES" ] || [ "$(nulable numero numero)" != "YES" ] || [ "$(nulable numero suplemento)" != "YES" ]; then
    error "La tabla numero no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(columnas_de articulo_palabra_clave)" != "${COLS_KWD}" ] || [ "$(nulable articulo_palabra_clave vocabulario)" != "YES" ]; then
    error "La tabla articulo_palabra_clave no quedó como se esperaba."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas de revistas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi
  # NINGÚN '' QUEDÓ VIVO: «SIN DATO» ES NULL
  VACIOS="$(valor "SELECT (SELECT COUNT(*) FROM \`${DB}\`.numero WHERE volumen = '' OR numero = '' OR suplemento = '') + (SELECT COUNT(*) FROM \`${DB}\`.articulo_palabra_clave WHERE vocabulario = '');")"
  if [ "$VACIOS" != "0" ]; then
    error "Quedan ${VACIOS} valores vacíos que debían ser NULL."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: columnas nulables, claves por columna generada y ${CHK} restricciones CHECK."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba corregido; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: números"
mysql_adm "$DB" -e "SELECT n.id_numero, r.titulo AS revista, n.volumen, n.numero, n.suplemento, n.clave_identidad FROM numero n JOIN revista r ON r.id_revista = n.id_revista ORDER BY r.titulo, n.clave_identidad;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.14.0 lista.${RESET}"
