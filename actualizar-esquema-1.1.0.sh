#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.1.0.sh
# Propósito : Actualización 1.1.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Prepara la búsqueda de
#             referencias en la propia base antes de consultar al LLM:
#               1. bibtex.fecha_modificacion  DATETIME, se actualiza sola
#               2. bibtex.id_origen           fila de la que se copió la entrada
#               3. fk_bibtex_origen           id_origen → bibtex.id, ON DELETE SET NULL
#               4. ft_bibtex_busqueda         FULLTEXT (title, author, book_title, journal_title)
# Uso       : ./actualizar-esquema-1.1.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo (cuenta administrativa
#             del servidor: app_user NO puede modificar estructuras).
# Reglas    : BBDD_LEEME.md §5. IDEMPOTENTE: verifica el estado REAL del
#             esquema y aplica solo lo que falta; no decide por las filas de
#             esquema_version. Respaldo verificado antes de tocar nada;
#             verificación posterior; sin efecto si ya está aplicado.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.1.0"
DESCRIPCION="Búsqueda de referencias: FULLTEXT en bibtex, id_origen, fecha_modificacion"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS COLUMNAS NUEVAS VAN AL FINAL DE LA TABLA, SIN AFTER: HAY CÓDIGO QUE LEE
# bibtex POR POSICIÓN (MostrarRefereciasEnTableViewBibtexEnCurso, aFields[4]
# EN m_Json) Y UNA COLUMNA EN EL MEDIO LO CORRERÍA SIN AVISO
COLUMNAS_FT="title,author,book_title,journal_title"

# COLORES SOLO SI LA SALIDA ES UNA TERMINAL (MISMO ESQUEMA QUE EL INSTALADOR)
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

# COMO ROOT NO HACE FALTA sudo (EJECUCIÓN DESDE UN CONTENEDOR O UNA SESIÓN DE ROOT)
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# CLIENTE CON utf8mb4 EXPLÍCITO: SIN ESO, LA DESCRIPCIÓN CON ACENTOS SE
# GRABARÍA CON EL JUEGO DE CARACTERES POR OMISIÓN DEL CLIENTE
mysql_adm() {
  $SUDO mysql --default-character-set=utf8mb4 "$@"
}

# CONSULTA DE UN SOLO VALOR, SIN ENCABEZADOS
valor() {
  mysql_adm -N -B -e "$1"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.1.0${RESET}"
echo "-------------------------------------------------"
echo "Agrega a la tabla bibtex lo necesario para buscar referencias ya"
echo "cargadas antes de consultar al LLM. No borra ni modifica datos."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${DB}';")" != "1" ]; then
  error "No existe la base '${DB}'."
  exit 1
fi

# SIN esquema_version NO SE PUEDE SABER SOBRE QUÉ NIVEL SE ESTÁ TRABAJANDO
if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# --- 3. ESTADO REAL DEL ESQUEMA ---
# SE PREGUNTA POR CADA PIEZA, NO POR LA FILA DE esquema_version (BBDD_LEEME §5)
existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND COLUMN_NAME='$1';"
}

existe_fk() {
  valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND CONSTRAINT_NAME='fk_bibtex_origen' AND CONSTRAINT_TYPE='FOREIGN KEY';"
}

# EL ÍNDICE SE RECONOCE POR TIPO Y COLUMNAS, NO SOLO POR NOMBRE
existe_fulltext() {
  valor "SELECT COUNT(*) FROM (SELECT INDEX_NAME, GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS cols FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND INDEX_TYPE='FULLTEXT' GROUP BY INDEX_NAME) t WHERE t.cols='${COLUMNAS_FT}';"
}

FALTA_FECHA=0; FALTA_ORIGEN=0; FALTA_FK=0; FALTA_FT=0
[ "$(existe_columna fecha_modificacion)" = "0" ] && FALTA_FECHA=1
[ "$(existe_columna id_origen)" = "0" ] && FALTA_ORIGEN=1
[ "$(existe_fk)" = "0" ] && FALTA_FK=1
[ "$(existe_fulltext)" = "0" ] && FALTA_FT=1

PENDIENTES=$((FALTA_FECHA + FALTA_ORIGEN + FALTA_FK + FALTA_FT))

if [ "$PENDIENTES" -eq 0 ]; then
  ok "El esquema ya tiene todo lo de 1.1.0. No hay nada que hacer."
  exit 0
fi

info "Piezas pendientes: ${PENDIENTES} de 4"
[ "$FALTA_FECHA" -eq 1 ]  && echo "    - columna fecha_modificacion"
[ "$FALTA_ORIGEN" -eq 1 ] && echo "    - columna id_origen"
[ "$FALTA_FK" -eq 1 ]     && echo "    - clave foránea fk_bibtex_origen"
[ "$FALTA_FT" -eq 1 ]     && echo "    - índice FULLTEXT ft_bibtex_busqueda"
echo

read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
if [ "$RESPUESTA" != "SI" ]; then
  warn "Cancelado. No se modificó nada."
  exit 0
fi

# --- 4. RESPALDO PREVIO VERIFICADO ---
mkdir -p "$DIR_RESPALDO"
RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.1.0-$(date '+%Y%m%d-%H%M%S').sql"
info "Respaldo en ${RESPALDO}"

$SUDO mysqldump --single-transaction --routines --triggers --events \
  --default-character-set=utf8mb4 "$DB" > "$RESPALDO"

# NO ALCANZA CON QUE mysqldump DEVUELVA ÉXITO: SE VERIFICA EL ARCHIVO
if [ ! -s "$RESPALDO" ]; then
  error "El respaldo quedó vacío. No se modificó nada."
  exit 1
fi
if ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
  error "El respaldo no terminó completo (falta la marca final). No se modificó nada."
  exit 1
fi
if ! grep -q "CREATE TABLE \`bibtex\`" "$RESPALDO"; then
  error "El respaldo no contiene la tabla bibtex. No se modificó nada."
  exit 1
fi
ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

FILAS_ANTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex;")"
info "Filas en bibtex: ${FILAS_ANTES}"

# --- 5. APLICACIÓN, PIEZA POR PIEZA ---

# 5.1 fecha_modificacion. EN DOS PASOS: SI SE AGREGARA DIRECTO CON DEFAULT
# CURRENT_TIMESTAMP, TODAS LAS FILAS EXISTENTES QUEDARÍAN CON LA FECHA DE HOY,
# QUE ES FALSA. PRIMERO SE AGREGA EN NULL; DESPUÉS SE CAMBIA EL DEFAULT, QUE
# SOLO VALE PARA LAS FILAS NUEVAS. MISMO TIPO QUE proyectos.fecha_modificacion.
if [ "$FALTA_FECHA" -eq 1 ]; then
  mysql_adm "$DB" -e "ALTER TABLE bibtex ADD COLUMN fecha_modificacion DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP;"
  mysql_adm "$DB" -e "ALTER TABLE bibtex MODIFY COLUMN fecha_modificacion DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;"
  ok "Columna fecha_modificacion agregada (las filas existentes quedan en NULL: fecha desconocida)."
fi

# 5.2 id_origen
if [ "$FALTA_ORIGEN" -eq 1 ]; then
  mysql_adm "$DB" -e "ALTER TABLE bibtex ADD COLUMN id_origen INT NULL DEFAULT NULL;"
  ok "Columna id_origen agregada."
fi

# 5.3 CLAVE FORÁNEA. SET NULL: SI SE BORRA LA ENTRADA DE ORIGEN, LA COPIA SIGUE
# VIVA Y SOLO PIERDE EL VÍNCULO (PRECEDENTE: articulos.articulo_correccion_id)
if [ "$FALTA_FK" -eq 1 ]; then
  mysql_adm "$DB" -e "ALTER TABLE bibtex ADD CONSTRAINT fk_bibtex_origen FOREIGN KEY (id_origen) REFERENCES bibtex (id) ON DELETE SET NULL ON UPDATE CASCADE;"
  ok "Clave foránea fk_bibtex_origen agregada."
fi

# 5.4 FULLTEXT. EL PRIMER ÍNDICE FULLTEXT DE UNA TABLA InnoDB LA RECONSTRUYE
# (AGREGA LA COLUMNA OCULTA FTS_DOC_ID): PUEDE TARDAR Y EMITIR UNA ADVERTENCIA
if [ "$FALTA_FT" -eq 1 ]; then
  info "Creando el índice FULLTEXT (reconstruye la tabla)…"
  mysql_adm "$DB" -e "ALTER TABLE bibtex ADD FULLTEXT INDEX ft_bibtex_busqueda (${COLUMNAS_FT});"
  ok "Índice ft_bibtex_busqueda creado."
fi

# --- 6. VERIFICACIÓN POSTERIOR ---
FALLAS=0

[ "$(existe_columna fecha_modificacion)" = "1" ] || { error "Falta fecha_modificacion."; FALLAS=1; }
[ "$(existe_columna id_origen)" = "1" ]          || { error "Falta id_origen."; FALLAS=1; }
[ "$(existe_fk)" = "1" ]                         || { error "Falta fk_bibtex_origen."; FALLAS=1; }
[ "$(existe_fulltext)" = "1" ]                   || { error "Falta el índice FULLTEXT."; FALLAS=1; }

TIPO_FECHA="$(valor "SELECT CONCAT(DATA_TYPE, '|', IFNULL(COLUMN_DEFAULT,''), '|', EXTRA) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='bibtex' AND COLUMN_NAME='fecha_modificacion';")"
case "$TIPO_FECHA" in
  datetime\|*CURRENT_TIMESTAMP*\|*on\ update*) ok "fecha_modificacion: ${TIPO_FECHA}" ;;
  *) error "fecha_modificacion no quedó como se esperaba: ${TIPO_FECHA}"; FALLAS=1 ;;
esac

FILAS_DESPUES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex;")"
if [ "$FILAS_DESPUES" != "$FILAS_ANTES" ]; then
  error "Cambió la cantidad de filas: ${FILAS_ANTES} → ${FILAS_DESPUES}."
  FALLAS=1
else
  ok "Filas preservadas: ${FILAS_DESPUES}."
fi

# LA COLUMNA NUEVA NO DEBE HABERLE PUESTO FECHA A NINGUNA FILA PREVIA
if [ "$FALTA_FECHA" -eq 1 ]; then
  CON_FECHA="$(valor "SELECT COUNT(*) FROM \`${DB}\`.bibtex WHERE fecha_modificacion IS NOT NULL;")"
  if [ "$CON_FECHA" != "0" ]; then
    error "${CON_FECHA} filas existentes recibieron fecha_modificacion: se esperaba NULL."
    FALLAS=1
  else
    ok "Filas existentes con fecha_modificacion en NULL."
  fi
fi

# EL ÍNDICE TIENE QUE RESPONDER A UNA CONSULTA REAL
if ! mysql_adm "$DB" -N -B -e "SELECT COUNT(*) FROM bibtex WHERE MATCH(${COLUMNAS_FT}) AGAINST ('prueba');" >/dev/null 2>&1; then
  error "El índice FULLTEXT no responde a MATCH … AGAINST."
  FALLAS=1
else
  ok "El índice responde a MATCH … AGAINST."
fi

if [ "$FALLAS" -ne 0 ]; then
  error "La verificación falló. NO se registra la actualización."
  error "Para volver atrás: sudo mysql ${DB} < ${RESPALDO}"
  exit 1
fi

# --- 7. REGISTRO ---
# INSERT IGNORE: SI YA ESTABA REGISTRADA (CORRIDA ANTERIOR INTERRUMPIDA DESPUÉS
# DEL REGISTRO), NO FALLA
mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
ok "Registrado en esquema_version como ${PARCHE}."
echo
ok "${NEGRITA}Actualización 1.1.0 aplicada.${RESET} Respaldo previo: ${RESPALDO}"
