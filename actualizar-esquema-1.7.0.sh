#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.7.0.sh
# Propósito : Actualización 1.7.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos editoriales. Retira la tabla
#             shortcodes: el catálogo de shortcodes pasó a gbShortcodes y
#             gbpublisher lo lee del archivo exportado
#             (shortcodes/_catalogo.tsv, RF-11). La tabla era semilla de
#             solo lectura: no contiene datos de ninguna editorial.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.7.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado deja
#             de esperar shortcodes. ORDEN: PRIMERO LA APLICACIÓN NUEVA,
#             DESPUÉS ESTE SCRIPT. La validación de arranque ignora una
#             tabla que sobra, pero rechaza una esperada que falta: una
#             versión anterior de gbpublisher no arranca sin shortcodes.
# Cadena    : la 1.7.0 estaba reservada para el refactor de bibtex, que pasa
#             a la 1.8.0 (SC-22).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.7.0"
DESCRIPCION="Retiro de la tabla shortcodes: el catálogo pasa a gbShortcodes"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="shortcodes"
# COLUMNAS DE shortcodes EN EL BASELINE 1.0.0: OTRO CONTEO ES UNA TABLA QUE
# ESTE SCRIPT NO CONOCE Y NO SE BORRA
COLUMNAS_TABLA=22

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

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.7.0${RESET}"
echo "-------------------------------------------------"
echo "Retira la tabla shortcodes: el catálogo vive ahora en gbShortcodes."
echo "No toca datos editoriales. La tabla queda en el respaldo previo."
echo
warn "Antes de seguir, gbpublisher tiene que estar actualizado a la versión"
warn "que lee el catálogo exportado: una versión anterior no arranca sin la tabla."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='esquema_version';")" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.7.0 VA SOBRE 1.6.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.6.0';")" != "1" ]; then
  error "Falta la actualización 1.6.0. Aplicala primero (actualizar-esquema-1.6.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}';"
}

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}';"
}

# UNA CLAVE FORÁNEA DE OTRA TABLA HACIA shortcodes HARÍA FALLAR EL DROP O
# DEJARÍA DATOS SIN REFERENCIA: EL BASELINE NO TIENE NINGUNA, PERO SE MIRA
# EL ESTADO REAL
referencias_entrantes() {
  valor "SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME='${TABLA}';"
}

if [ "$(existe_tabla)" = "0" ]; then
  ok "La tabla ${TABLA} ya no existe. No hay nada que modificar."
  SOLO_INFORME=1
else
  # OTRO CONTEO ES UNA TABLA QUE ESTE SCRIPT NO CONOCE: NO SE BORRA
  if [ "$(columnas_tabla)" != "$COLUMNAS_TABLA" ]; then
    error "${TABLA} tiene $(columnas_tabla) columnas y se esperaban ${COLUMNAS_TABLA}: no es la tabla prevista. No se modificó nada."
    exit 1
  fi
  if [ "$(referencias_entrantes)" != "0" ]; then
    error "Hay claves foráneas que apuntan a ${TABLA}. No se modificó nada."
    exit 1
  fi

  SOLO_INFORME=0
  FILAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.\`${TABLA}\`;")"
  info "Pendiente:"
  echo "    - retirar la tabla ${TABLA} (${FILAS} filas, quedan en el respaldo)"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.7.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # LA TABLA TESTIGO ES LA QUE SE BORRA: SIN ELLA EN EL RESPALDO NO HAY VUELTA
  if ! grep -q "CREATE TABLE \`${TABLA}\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla ${TABLA}. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # SIN IF EXISTS: LA EXISTENCIA SE VERIFICÓ EN EL PUNTO 3, Y SI ENTRE TANTO
  # DESAPARECIÓ, EL ERROR DEBE VERSE
  mysql_adm "$DB" -e "DROP TABLE \`${TABLA}\`;"
  ok "Tabla ${TABLA} retirada."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  if [ "$(existe_tabla)" != "0" ]; then
    error "La tabla ${TABLA} sigue existiendo. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos DESPUÉS DE
    # HABERLA BORRADO (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: ${TABLA} ya no está en la base."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# EL CATÁLOGO QUE REEMPLAZA A LA TABLA ES EL QUE TRAE EL PAQUETE INSTALADO
# (SC-11). SI NO ESTÁ, EL PANEL DE SHORTCODES AVISA AL ABRIR UN PROYECTO
echo
CATALOGO="/usr/share/gbpublisher/shortcodes/_catalogo.tsv"
info "Informe de control: catálogo de shortcodes del paquete instalado"
if [ -f "$CATALOGO" ]; then
  ok "${CATALOGO}: $(($(wc -l < "$CATALOGO") - 1)) shortcodes."
else
  warn "No está ${CATALOGO}. Si gbpublisher está instalado, el paquete es anterior al catálogo exportado."
fi
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.7.0 lista.${RESET}"
