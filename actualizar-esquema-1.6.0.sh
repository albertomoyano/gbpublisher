#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.6.0.sh
# Propósito : Actualización 1.6.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Autoría en la apertura de
#             capítulo de los libros colectivos:
#               capitulos.autoria_apertura, AL FINAL de la tabla (SC-22): la
#               forma de cada nombre debajo del título del capítulo en el
#               PDF, separadas por punto y coma («A. Moyano; J. Sotelo»).
#               Vacía: los nombres completos de capitulo_autor. Es solo
#               presentación: los metadatos siguen saliendo de autores.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.6.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado pasa
#             capitulos de 78 a 79 columnas.
# Cadena    : la 1.6.0 estaba reservada para el refactor de bibtex, que pasa
#             a la 1.7.0 (SC-22).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.6.0"
DESCRIPCION="Autoría en la apertura de capítulo: forma de los nombres en capitulos"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="capitulos"
COLUMNA="autoria_apertura"
DEFINICION="VARCHAR(500) COLLATE utf8mb4_unicode_ci NULL COMMENT 'Forma de los nombres en la apertura del capítulo, separados por punto y coma; vacía: nombres completos'"
COLUMNAS_ANTES=78
COLUMNAS_DESPUES=79

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.6.0${RESET}"
echo "-------------------------------------------------"
echo "Agrega a capitulos la forma de los nombres en la apertura del capítulo."
echo "No borra ni modifica valores existentes."
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

# LA CADENA ES ORDENADA: 1.6.0 VA SOBRE 1.5.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.5.0';")" != "1" ]; then
  error "Falta la actualización 1.5.0. Aplicala primero (actualizar-esquema-1.5.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}' AND COLUMN_NAME='${COLUMNA}';"
}

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}';"
}

if [ "$(existe_columna)" = "1" ]; then
  ESPERADAS=$COLUMNAS_DESPUES
else
  ESPERADAS=$COLUMNAS_ANTES
fi

# OTRO CONTEO ES UN ESQUEMA QUE ESTE SCRIPT NO CONOCE
if [ "$(columnas_tabla)" != "$ESPERADAS" ]; then
  error "${TABLA} tiene $(columnas_tabla) columnas y se esperaban ${ESPERADAS}: el esquema no es el previsto."
  exit 1
fi

if [ "$(existe_columna)" = "1" ]; then
  ok "El esquema ya tiene todo lo de 1.6.0. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente:"
  echo "    - ${TABLA}.${COLUMNA}"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.6.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`${TABLA}\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla ${TABLA}. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # SIN AFTER: VA AL FINAL (SC-22). MYSQL 8.0 NO TIENE ADD COLUMN IF NOT
  # EXISTS: LA EXISTENCIA SE VERIFICÓ EN EL PUNTO 3
  mysql_adm "$DB" -e "ALTER TABLE \`${TABLA}\` ADD COLUMN \`${COLUMNA}\` ${DEFINICION};"
  ok "${TABLA}.${COLUMNA} agregada."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0
  [ "$(existe_columna)" = "1" ] || { error "Falta ${TABLA}.${COLUMNA}."; FALLAS=1; }
  [ "$(columnas_tabla)" = "$COLUMNAS_DESPUES" ] || { error "${TABLA} no tiene ${COLUMNAS_DESPUES} columnas."; FALLAS=1; }

  # VA AL FINAL: HAY CÓDIGO QUE LEE POR POSICIÓN (SC-22)
  ULTIMA="$(valor "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}' AND ORDINAL_POSITION = ${COLUMNAS_DESPUES};")"
  [ "$ULTIMA" = "$COLUMNA" ] || { error "La columna nueva no quedó al final (quedó: ${ULTIMA})."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos DESPUÉS DE
    # HABERLA BORRADO (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: ${TABLA} con ${COLUMNAS_DESPUES} columnas."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# CAPÍTULOS DE LIBROS COLECTIVOS CON CUATRO O MÁS AUTORES Y SIN FORMA
# DECLARADA: SON LOS QUE PUEDEN NO ENTRAR EN UNA LÍNEA CON LOS NOMBRES
# COMPLETOS. EL CRITERIO DE CUATRO ES SOLO PARA ESTE LISTADO
echo
info "Informe de control: capítulos de libros colectivos con 4 o más autores y sin forma declarada"
mysql_adm "$DB" -t <<'SQL'
SELECT c.id_libro, c.nombre_archivo, LEFT(c.titulo_capitulo, 40) AS capitulo,
       COUNT(ca.id_autor) AS autores
FROM capitulos c
JOIN libros_md l ON l.id_libro = c.id_libro
JOIN capitulo_autor ca ON ca.id_capitulo = c.id_capitulo AND ca.rol_autor = 'autor'
WHERE l.tipo_libro IN ('obra_colectiva','compilacion','actas','referencia')
  AND COALESCE(TRIM(c.autoria_apertura), '') = ''
GROUP BY c.id_capitulo, c.id_libro, c.nombre_archivo, c.titulo_capitulo
HAVING COUNT(ca.id_autor) >= 4
ORDER BY c.id_libro, c.nombre_archivo;
SQL
echo "Si la tabla no aparece, no hay capítulos en esa situación. El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.6.0 lista.${RESET}"
