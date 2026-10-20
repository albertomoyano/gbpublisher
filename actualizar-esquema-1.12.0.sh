#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.12.0.sh
# Propósito : Actualización 1.12.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Retira la tabla postits: las
#             notas internas viven desde la 1.10.0 en notas, notas_grupos,
#             notas_miembros, notas_respuestas y notas_vistas, y la 1.10.0
#             migró cada postit con su mismo id.
#             Antes de borrar, lista los postits que NO están en notas (los
#             que la 1.10.0 no pudo migrar, o los que escribió una versión
#             vieja de la aplicación después de la migración) y guarda la
#             tabla sola en un archivo aparte, además del respaldo completo.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : ./actualizar-esquema-1.12.0.sh
# Requisitos: MySQL en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.11.0 registrada: la cadena es ordenada.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado deja
#             de esperar postits y FEstadisticas deja de nombrarla. ORDEN:
#             PRIMERO LA APLICACIÓN NUEVA, DESPUÉS ESTE SCRIPT (SC-22, punto
#             5 del lote). La validación de arranque ignora una tabla que
#             sobra, pero rechaza una esperada que falta: una versión
#             anterior de gbpublisher no arranca sin postits.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.12.0"
PREVIO="actualizacion-1.11.0"
DESCRIPCION="Retiro de la tabla postits: las notas internas viven en notas desde la 1.10.0"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="postits"
# COLUMNAS DE postits EN EL BASELINE 1.0.0: OTRO CONTEO ES UNA TABLA QUE
# ESTE SCRIPT NO CONOCE Y NO SE BORRA
COLUMNAS_TABLA=11

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.12.0${RESET}"
echo "--------------------------------------------------"
echo "Retira la tabla postits: las notas internas viven ahora en la tabla notas."
echo "La tabla queda en el respaldo previo y en un archivo propio."
echo
warn "Antes de seguir, gbpublisher tiene que estar actualizado a la versión"
warn "que ya no espera postits: una versión anterior no arranca sin la tabla."
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

# LA CADENA ES ORDENADA: 1.12.0 VA SOBRE 1.11.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.11.0. Aplicala primero (actualizar-esquema-1.11.0.sh)."
  exit 1
fi

# LA TABLA QUE REEMPLAZA A postits TIENE QUE ESTAR: SIN ELLA, BORRAR postits
# DEJARÍA LA BASE SIN NOTAS
if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='notas';")" != "1" ]; then
  error "La base no tiene la tabla notas (1.10.0). No se modificó nada."
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

# UNA CLAVE FORÁNEA DE OTRA TABLA HACIA postits HARÍA FALLAR EL DROP: EL
# BASELINE NO TIENE NINGUNA, PERO SE MIRA EL ESTADO REAL
referencias_entrantes() {
  valor "SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME='${TABLA}';"
}

# POSTITS SIN SU NOTA: LA 1.10.0 MIGRÓ CADA UNO CON EL MISMO id, ASÍ QUE UN
# id QUE NO ESTÁ EN notas ES UN POSTIT QUE NO PASÓ
sin_migrar() {
  valor "SELECT COUNT(*) FROM \`${DB}\`.postits p WHERE NOT EXISTS (SELECT 1 FROM \`${DB}\`.notas n WHERE n.id = p.id);"
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
  PERDIDOS="$(sin_migrar)"

  # LOS QUE NO PASARON A notas SE MUESTRAN ANTES DE PEDIR CONFIRMACIÓN: SON
  # LO ÚNICO QUE EL BORRADO SACA DE LA BASE (QUEDAN EN LOS DOS RESPALDOS)
  if [ "$PERDIDOS" != "0" ]; then
    warn "${PERDIDOS} postit(s) no están en notas. Al retirar la tabla quedan solo en los respaldos:"
    mysql_adm "$DB" -t -e "SELECT p.id, p.de, p.para, p.fecha, p.leido, LEFT(REPLACE(IFNULL(p.texto, ''), CHAR(10), ' '), 50) AS texto FROM postits p WHERE NOT EXISTS (SELECT 1 FROM notas n WHERE n.id = p.id) ORDER BY p.id;"
    warn "Si alguno importa, cancelá, copialo como nota nueva desde la aplicación y volvé a correr el script."
    echo
  fi

  info "Pendiente:"
  echo "    - retirar la tabla ${TABLA} (${FILAS} filas; ${PERDIDOS} sin su nota en notas)"
  echo

  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDOS PREVIOS VERIFICADOS ---
  mkdir -p "$DIR_RESPALDO"
  SELLO="$(date '+%Y%m%d-%H%M%S')"

  # 4.1 LA BASE COMPLETA, COMO EN TODA ACTUALIZACIÓN
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.12.0-${SELLO}.sql"
  info "Respaldo completo en ${RESPALDO}"

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
  ok "Respaldo completo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # 4.2 LA TABLA SOLA, EN UN ARCHIVO QUE SE PUEDE GUARDAR APARTE: EL
  #     RESPALDO COMPLETO SE REEMPLAZA CON EL TIEMPO, ESTE NO
  ARCHIVO_TABLA="${DIR_RESPALDO}/gbpublisher-postits-retirada-${SELLO}.sql"
  info "Tabla ${TABLA} sola en ${ARCHIVO_TABLA}"

  $SUDO mysqldump --single-transaction --default-character-set=utf8mb4 \
    "$DB" "$TABLA" > "$ARCHIVO_TABLA"

  if [ ! -s "$ARCHIVO_TABLA" ] || ! tail -n 1 "$ARCHIVO_TABLA" | grep -q "Dump completed" \
     || ! grep -q "CREATE TABLE \`${TABLA}\`" "$ARCHIVO_TABLA"; then
    error "El archivo de la tabla ${TABLA} no quedó completo. No se modificó nada."
    exit 1
  fi
  ok "Archivo de la tabla verificado ($(du -h "$ARCHIVO_TABLA" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # SIN IF EXISTS: LA EXISTENCIA SE VERIFICÓ EN EL PUNTO 3, Y SI ENTRE TANTO
  # DESAPARECIÓ, EL ERROR DEBE VERSE
  NOTAS_ANTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.notas;")"
  mysql_adm "$DB" -e "DROP TABLE \`${TABLA}\`;"
  ok "Tabla ${TABLA} retirada."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0
  [ "$(existe_tabla)" = "0" ] || { error "La tabla ${TABLA} sigue existiendo."; FALLAS=1; }
  # EL BORRADO NO PUEDE HABER TOCADO LAS NOTAS
  NOTAS_DESPUES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.notas;")"
  [ "$NOTAS_ANTES" = "$NOTAS_DESPUES" ] || { error "Cambió la cantidad de notas (antes ${NOTAS_ANTES}, después ${NOTAS_DESPUES})."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: ${TABLA} ya no está en la base y las notas siguen iguales."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
  info "La tabla sola, para consultar o restaurar: ${ARCHIVO_TABLA}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "La tabla ya no estaba; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# LAS NOTAS QUE QUEDAN, PARA COMPARAR CON LO QUE SE VE EN LA APLICACIÓN
echo
info "Informe de control: notas internas"
mysql_adm "$DB" -t <<'SQL'
SELECT COUNT(*) AS notas,
       CAST(IFNULL(SUM(fecha_cierre IS NULL), 0) AS SIGNED) AS abiertas,
       CAST(IFNULL(SUM(fecha_cierre IS NOT NULL), 0) AS SIGNED) AS cerradas,
       CAST(IFNULL(SUM(id_grupo IS NOT NULL), 0) AS SIGNED) AS de_proyecto
FROM notas;
SQL
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.12.0 lista.${RESET}"
