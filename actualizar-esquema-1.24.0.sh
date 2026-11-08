#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.24.0.sh
# Propósito : Actualización 1.24.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Los cuatro modelos de foliado
#             de una revista (Alberto, 07/11; claude/salidas-revistas.md):
#               1. revista.modelo_paginacion suma el valor por_articulo (cada
#                  artículo empieza en 1). Va AL FINAL del ENUM: agregar un
#                  valor al final no renumera los existentes y MySQL lo hace
#                  sin copiar la tabla; el orden de la pantalla lo da
#                  m_Revistas, no el ENUM.
#               2. Los comentarios de revista.modelo_paginacion,
#                  numero.pagina_inicial y articulo.elocation_id dicen lo que
#                  significan ahora: la página inicial de por_volumen se
#                  calcula del número anterior del volumen y la cargada a mano
#                  manda; el e-id del modelo continua lo genera Gambas
#                  (e + año + 3 cifras, e2026001).
#             Sin columnas ni tablas nuevas. Al final emite un INFORME DE
#             CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.24.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.23.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema).
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: sin cambios (no cambia la
#             cantidad de columnas de ninguna tabla).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.24.0"
PREVIO="actualizacion-1.23.0"
DESCRIPCION="Revistas: modelo de foliado por_articulo y comentarios de paginación y e-id"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# EL ENUM Y LOS COMENTARIOS COMO TIENEN QUE QUEDAR. LOS DDL REPITEN EL TIPO,
# EL NULL Y EL DEFAULT DE 1.13.0: MODIFY COLUMN REEMPLAZA LA DEFINICIÓN ENTERA
ENUM_NUEVO="enum('por_numero','por_volumen','continua','por_articulo')"
COM_MODELO="Foliado: por_numero (cada número empieza en 1), por_volumen (sigue al número anterior del volumen), por_articulo (cada artículo empieza en 1), continua (e-id por artículo, elocation-id)"
COM_PAGINA="Solo por_volumen: dónde arranca este número. Si está, manda; si no, se calcula del número anterior del volumen"
COM_ELOCATION="Solo modelo continua: e + año + 3 cifras (e2026001). Lo genera Gambas y se congela al publicar"

DDL_MODELO="ALTER TABLE revista MODIFY COLUMN modelo_paginacion ${ENUM_NUEVO} NOT NULL DEFAULT 'por_numero' COMMENT '${COM_MODELO}';"
DDL_PAGINA="ALTER TABLE numero MODIFY COLUMN pagina_inicial INT NULL DEFAULT NULL COMMENT '${COM_PAGINA}';"
DDL_ELOCATION="ALTER TABLE articulo MODIFY COLUMN elocation_id VARCHAR(50) NULL DEFAULT NULL COMMENT '${COM_ELOCATION}';"

# RESTRICCIONES CHECK AL TERMINAR, EN LAS TABLAS DE REVISTAS: LAS DE 1.23.0
CHECK_ESPERADAS=22

LISTA_SQL="'revista','revista_plantilla_resumen','revista_plantilla_resumen_seccion','revista_plantilla_resumen_titulo','revista_seccion','revista_seccion_titulo','revista_bloque','numero','numero_dossier','numero_dossier_titulo','numero_contribuyente','articulo','articulo_texto','articulo_resumen_seccion','articulo_palabra_clave','articulo_contribuyente','contribuyente_afiliacion','contribuyente_credit','articulo_financiamiento','tipo_declaracion','articulo_declaracion','articulo_relacion','articulo_ubicacion','vocabulario_termino','articulo_reapertura'"

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

# UN DATO DE UNA COLUMNA EN information_schema.COLUMNS
dato_columna() {
  valor "SELECT $3 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.24.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega el modelo de foliado «cada artículo empieza en 1» y corrige"
echo "tres comentarios de columna. No borra ni modifica datos."
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

# LA CADENA ES ORDENADA: 1.24.0 VA SOBRE 1.23.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.23.0. Aplicala primero (actualizar-esquema-1.23.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
# LAS TRES COLUMNAS TIENEN QUE EXISTIR CON EL TIPO DE 1.13.0; SI NO, LA BASE
# NO ES LA QUE ESTE SCRIPT CONOCE Y NO SE TOCA
TIPO_MODELO="$(dato_columna revista modelo_paginacion COLUMN_TYPE)"
TIPO_PAGINA="$(dato_columna numero pagina_inicial DATA_TYPE)"
TIPO_ELOCATION="$(dato_columna articulo elocation_id COLUMN_TYPE)"
if [ "$TIPO_MODELO" != "enum('por_numero','por_volumen','continua')" ] && [ "$TIPO_MODELO" != "${ENUM_NUEVO}" ]; then
  error "revista.modelo_paginacion tiene una forma inesperada (${TIPO_MODELO:-no existe}). Revisala a mano. No se modificó nada."
  exit 1
fi
if [ "$TIPO_PAGINA" != "int" ] || [ "$TIPO_ELOCATION" != "varchar(50)" ]; then
  error "numero.pagina_inicial (${TIPO_PAGINA:-no existe}) o articulo.elocation_id (${TIPO_ELOCATION:-no existe}) tienen una forma inesperada. No se modificó nada."
  exit 1
fi

CAMBIAR_MODELO=0
[ "$TIPO_MODELO" != "${ENUM_NUEVO}" ] && CAMBIAR_MODELO=1
[ "$(dato_columna revista modelo_paginacion COLUMN_COMMENT)" != "${COM_MODELO}" ] && CAMBIAR_MODELO=1
CAMBIAR_PAGINA=0
[ "$(dato_columna numero pagina_inicial COLUMN_COMMENT)" != "${COM_PAGINA}" ] && CAMBIAR_PAGINA=1
CAMBIAR_ELOCATION=0
[ "$(dato_columna articulo elocation_id COLUMN_COMMENT)" != "${COM_ELOCATION}" ] && CAMBIAR_ELOCATION=1

if [ "$CAMBIAR_MODELO" -eq 0 ] && [ "$CAMBIAR_PAGINA" -eq 0 ] && [ "$CAMBIAR_ELOCATION" -eq 0 ]; then
  ok "No hay nada que cambiar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$CAMBIAR_MODELO" -eq 1 ] && info "Se modifica revista.modelo_paginacion (valor por_articulo y comentario)."
  [ "$CAMBIAR_PAGINA" -eq 1 ] && info "Se corrige el comentario de numero.pagina_inicial."
  [ "$CAMBIAR_ELOCATION" -eq 1 ] && info "Se corrige el comentario de articulo.elocation_id."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.24.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`revista\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla revista. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE (SC-22, DESDE 1.19.0): EL ENUM DE
  # 1.13.0. SE PUEDE MIENTRAS NINGUNA REVISTA USE por_articulo: CON UNA QUE LO
  # USE, MySQL RECHAZA EL CAMBIO (MODO ESTRICTO) Y NO SE PIERDE NADA. LOS
  # COMENTARIOS NO SE VUELVEN ATRÁS: NO CAMBIAN NINGÚN COMPORTAMIENTO
  VOLVER_ATRAS="sudo mysql ${DB} -e \"ALTER TABLE revista MODIFY COLUMN modelo_paginacion ENUM('por_numero','por_volumen','continua') NOT NULL DEFAULT 'por_numero';\""

  # --- 5. CAMBIOS ---
  if [ "$CAMBIAR_MODELO" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_MODELO}"
    ok "Modificada revista.modelo_paginacion."
  fi
  if [ "$CAMBIAR_PAGINA" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_PAGINA}"
    ok "Corregido el comentario de numero.pagina_inicial."
  fi
  if [ "$CAMBIAR_ELOCATION" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_ELOCATION}"
    ok "Corregido el comentario de articulo.elocation_id."
  fi

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(dato_columna revista modelo_paginacion COLUMN_TYPE)" != "${ENUM_NUEVO}" ] ||
     [ "$(dato_columna revista modelo_paginacion COLUMN_DEFAULT)" != "por_numero" ] ||
     [ "$(dato_columna revista modelo_paginacion IS_NULLABLE)" != "NO" ] ||
     [ "$(dato_columna revista modelo_paginacion COLUMN_COMMENT)" != "${COM_MODELO}" ]; then
    error "revista.modelo_paginacion no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(dato_columna numero pagina_inicial COLUMN_COMMENT)" != "${COM_PAGINA}" ] ||
     [ "$(dato_columna numero pagina_inicial IS_NULLABLE)" != "YES" ]; then
    error "numero.pagina_inicial no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(dato_columna articulo elocation_id COLUMN_COMMENT)" != "${COM_ELOCATION}" ] ||
     [ "$(dato_columna articulo elocation_id COLUMN_TYPE)" != "varchar(50)" ]; then
    error "articulo.elocation_id no quedó como se esperaba."
    FALLA=1
  fi
  # MODIFY COLUMN NO TOCA LAS CHECK DE LA TABLA; SE CUENTAN IGUAL, COMO EN
  # CADA ACTUALIZACIÓN DE REVISTAS
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
  ok "Verificación correcta: el ENUM, los tres comentarios y ${CHK} restricciones CHECK."

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
info "Informe de control: revistas por modelo de foliado"
mysql_adm "$DB" -e "SELECT modelo_paginacion, COUNT(*) AS revistas FROM revista GROUP BY modelo_paginacion ORDER BY modelo_paginacion;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.24.0 lista.${RESET}"
