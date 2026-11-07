#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.23.0.sh
# Propósito : Actualización 1.23.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Registro de reaperturas
#             (entrega E, decisiones 17 y de Alberto del 28/10). Se escribió
#             como 1.18.0 y no llegó a aplicarse: ese número lo tomaron las
#             siglas de libros (31/10). Va como 1.23.0, sobre la 1.22.0:
#               1. Tabla nueva articulo_reapertura: artículo, fecha, quién
#                  (el administrador que reabrió desde FSysAdmin) y motivo
#                  obligatorio.
#               2. Dos disparadores que rechazan UPDATE y DELETE sobre ella:
#                  es un registro SOLO DE ALTAS. app_user tiene ALL sobre la
#                  base y MySQL no permite quitarle una tabla de un permiso
#                  de base: la garantía tiene que estar en la tabla.
#             La clave hacia articulo es RESTRICT, no CASCADE: un artículo
#             que se reabrió alguna vez no se puede borrar, y el borrado en
#             cascada no dispara los disparadores (pasaría por encima del
#             registro sin aviso).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.23.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.22.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema).
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: articulo_reapertura 5
#             (nueva).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.23.0"
PREVIO="actualizacion-1.22.0"
DESCRIPCION="Revistas: registro de reaperturas de artículos publicados (articulo_reapertura, solo de altas)"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS AL TERMINAR (LAS DE hEsquema)
COLS_REAP=5
# RESTRICCIONES CHECK AL TERMINAR, EN LAS TABLAS DE REVISTAS: 20 + 2
CHECK_ESPERADAS=22

LISTA_SQL="'revista','revista_plantilla_resumen','revista_plantilla_resumen_seccion','revista_plantilla_resumen_titulo','revista_seccion','revista_seccion_titulo','revista_bloque','numero','numero_dossier','numero_dossier_titulo','numero_contribuyente','articulo','articulo_texto','articulo_resumen_seccion','articulo_palabra_clave','articulo_contribuyente','contribuyente_afiliacion','contribuyente_credit','articulo_financiamiento','tipo_declaracion','articulo_declaracion','articulo_relacion','articulo_ubicacion','vocabulario_termino','articulo_reapertura'"

# «SIN DATO» NO EXISTE ACÁ: QUIÉN Y MOTIVO SON OBLIGATORIOS Y NO VACÍOS
DDL_REAP="CREATE TABLE IF NOT EXISTS articulo_reapertura (
  id_reapertura INT NOT NULL AUTO_INCREMENT,
  id_articulo INT NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario VARCHAR(100) NOT NULL COMMENT 'El administrador que reabrió (FSysAdmin)',
  motivo TEXT NOT NULL,
  PRIMARY KEY (id_reapertura),
  KEY fk_reap_articulo (id_articulo),
  CONSTRAINT fk_reap_articulo FOREIGN KEY (id_articulo) REFERENCES articulo (id_articulo) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT chk_reap_usuario CHECK (usuario <> ''),
  CONSTRAINT chk_reap_motivo CHECK (motivo <> '')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reaperturas de artículos publicados: solo de altas';"

# SIGNAL CON SQLSTATE 45000: EL CLIENTE RECIBE EL MENSAJE COMO ERROR
DDL_TRG_UPD="CREATE TRIGGER trg_reapertura_sin_update BEFORE UPDATE ON articulo_reapertura FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'articulo_reapertura es solo de altas: no se modifica';"
DDL_TRG_DEL="CREATE TRIGGER trg_reapertura_sin_delete BEFORE DELETE ON articulo_reapertura FOR EACH ROW
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'articulo_reapertura es solo de altas: no se borra';"

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

disparador() {
  valor "SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='${DB}' AND TRIGGER_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.23.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el registro de reaperturas de artículos publicados."
echo "No borra ni modifica datos."
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

# LA CADENA ES ORDENADA: 1.23.0 VA SOBRE 1.22.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.22.0. Aplicala primero (actualizar-esquema-1.22.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
CREAR_REAP=0
N="$(columnas_de articulo_reapertura)"
if [ "$N" = "0" ]; then
  CREAR_REAP=1
elif [ "$N" != "${COLS_REAP}" ]; then
  error "La tabla articulo_reapertura tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi
CREAR_UPD=0
[ "$(disparador trg_reapertura_sin_update)" = "0" ] && CREAR_UPD=1
CREAR_DEL=0
[ "$(disparador trg_reapertura_sin_delete)" = "0" ] && CREAR_DEL=1

if [ "$CREAR_REAP" -eq 0 ] && [ "$CREAR_UPD" -eq 0 ] && [ "$CREAR_DEL" -eq 0 ]; then
  ok "No hay nada que agregar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$CREAR_REAP" -eq 1 ] && info "Se crea articulo_reapertura."
  [ "$CREAR_UPD" -eq 1 ] && info "Se crea el disparador trg_reapertura_sin_update."
  [ "$CREAR_DEL" -eq 1 ] && info "Se crea el disparador trg_reapertura_sin_delete."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.23.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`articulo\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla articulo. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE (SC-22, DESDE 1.19.0: RESTAURAR
  # EL RESPALDO NO BORRA LO CREADO DESPUÉS, GV-169). BORRAR LA TABLA BORRA SUS
  # DOS DISPARADORES. SE PUEDE HACER MIENTRAS NO HAYA REAPERTURAS QUE CONSERVAR
  VOLVER_ATRAS="sudo mysql ${DB} -e \"DROP TABLE IF EXISTS articulo_reapertura;\""

  # --- 5. CAMBIOS: PRIMERO LA TABLA, DESPUÉS SUS DISPARADORES ---
  if [ "$CREAR_REAP" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_REAP}"
    ok "Creada articulo_reapertura."
  fi
  if [ "$CREAR_UPD" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_TRG_UPD}"
    ok "Creado trg_reapertura_sin_update."
  fi
  if [ "$CREAR_DEL" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_TRG_DEL}"
    ok "Creado trg_reapertura_sin_delete."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de articulo_reapertura)" != "${COLS_REAP}" ]; then
    error "La tabla articulo_reapertura no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(disparador trg_reapertura_sin_update)" != "1" ] || [ "$(disparador trg_reapertura_sin_delete)" != "1" ]; then
    error "Faltan los disparadores de articulo_reapertura."
    FALLA=1
  fi
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME IN (${LISTA_SQL});")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK en las tablas de revistas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: tabla nueva, dos disparadores y ${CHK} restricciones CHECK."

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
info "Informe de control: artículos por estado"
mysql_adm "$DB" -e "SELECT estado, COUNT(*) AS articulos FROM articulo GROUP BY estado ORDER BY estado;"
info "Reaperturas registradas: $(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo_reapertura;")"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.23.0 lista.${RESET}"
