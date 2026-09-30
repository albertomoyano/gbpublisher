#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.5.0.sh
# Propósito : Actualización 1.5.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Primeras del libro (SC-25):
#               libros_md.leyenda_autoria, AL FINAL de la tabla (SC-22): la
#               línea que va debajo de los nombres en la portada
#               («coordinadores», «compiladoras»). La escribe el editor: el
#               género y el número no se deducen de la base.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.5.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado pasa
#             libros_md de 78 a 79 columnas.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.5.0"
DESCRIPCION="Primeras del libro: leyenda de autoría de la portada en libros_md"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
COLUMNA="leyenda_autoria"
DEFINICION="VARCHAR(200) COLLATE utf8mb4_unicode_ci NULL COMMENT 'Línea debajo de los nombres en la portada: coordinadores, compiladoras (SC-25)'"
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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.5.0${RESET}"
echo "-------------------------------------------------"
echo "Agrega a libros_md la leyenda de autoría de la portada."
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

# LA CADENA ES ORDENADA: 1.5.0 VA SOBRE 1.4.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.4.0';")" != "1" ]; then
  error "Falta la actualización 1.4.0. Aplicala primero (actualizar-esquema-1.4.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND COLUMN_NAME='${COLUMNA}';"
}

columnas_libro() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md';"
}

if [ "$(existe_columna)" = "1" ]; then
  ESPERADAS=$COLUMNAS_DESPUES
else
  ESPERADAS=$COLUMNAS_ANTES
fi

# OTRO CONTEO ES UN ESQUEMA QUE ESTE SCRIPT NO CONOCE
if [ "$(columnas_libro)" != "$ESPERADAS" ]; then
  error "libros_md tiene $(columnas_libro) columnas y se esperaban ${ESPERADAS}: el esquema no es el previsto."
  exit 1
fi

if [ "$(existe_columna)" = "1" ]; then
  ok "El esquema ya tiene todo lo de 1.5.0. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente:"
  echo "    - libros_md.${COLUMNA}"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.5.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # SIN AFTER: VA AL FINAL (SC-22). MYSQL 8.0 NO TIENE ADD COLUMN IF NOT
  # EXISTS: LA EXISTENCIA SE VERIFICÓ EN EL PUNTO 3
  mysql_adm "$DB" -e "ALTER TABLE \`libros_md\` ADD COLUMN \`${COLUMNA}\` ${DEFINICION};"
  ok "libros_md.${COLUMNA} agregada."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0
  [ "$(existe_columna)" = "1" ] || { error "Falta libros_md.${COLUMNA}."; FALLAS=1; }
  [ "$(columnas_libro)" = "$COLUMNAS_DESPUES" ] || { error "libros_md no tiene ${COLUMNAS_DESPUES} columnas."; FALLAS=1; }

  # VA AL FINAL: HAY CÓDIGO QUE LEE POR POSICIÓN (SC-22)
  ULTIMA="$(valor "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND ORDINAL_POSITION = ${COLUMNAS_DESPUES};")"
  [ "$ULTIMA" = "$COLUMNA" ] || { error "La columna nueva no quedó al final (quedó: ${ULTIMA})."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos DESPUÉS DE
    # HABERLA BORRADO (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: libros_md con ${COLUMNAS_DESPUES} columnas."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# LOS LIBROS QUE DECLARAN PORTADA Y TIENEN AUTORÍA CON ROL DE EDICIÓN SIN
# LEYENDA: SU PORTADA SALE SIN LA LÍNEA DE ROL HASTA QUE SE LA ESCRIBA
echo
info "Informe de control: libros con portada, autoría de edición y sin leyenda"
mysql_adm "$DB" -t <<'SQL'
SELECT l.id_libro, LEFT(l.titulo_libro, 40) AS libro, l.tipo_libro
FROM libros_md l
WHERE EXISTS (SELECT 1 FROM capitulos c WHERE c.id_libro = l.id_libro AND c.tipo_capitulo = 'portada')
  AND EXISTS (SELECT 1 FROM libro_autor la WHERE la.id_libro = l.id_libro AND la.rol_libro IN ('editor','compilador','coordinador'))
  AND COALESCE(TRIM(l.leyenda_autoria), '') = ''
ORDER BY l.id_libro;
SQL
echo "Si la tabla no aparece, no hay libros en esa situación. El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.5.0 lista.${RESET}"
