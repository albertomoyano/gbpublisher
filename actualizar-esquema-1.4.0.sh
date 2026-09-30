#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.4.0.sh
# Propósito : Actualización 1.4.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Primeras del libro (SC-25):
#               1. capitulos.tipo_capitulo: agrega portadilla, portada y
#                  creditos al enum, AL FINAL y partiendo de la lista REAL
#               2. libros_md: seis columnas nuevas, AL FINAL de la tabla
#                  (SC-22): texto_catalogacion, texto_legal,
#                  texto_catalogacion_digital, texto_legal_digital,
#                  logo_portada, logo_coleccion
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : ./actualizar-esquema-1.4.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
# Lote      : en la misma entrega, m_ConexionBD.ObtenerEsquemaEsperado pasa
#             libros_md de 72 a 78 columnas. capitulos no cambia de conteo.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.4.0"
DESCRIPCION="Primeras del libro: tipos portadilla, portada y creditos; textos legales y logos en libros_md"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# VALORES NUEVOS DEL ENUM, EN EL ORDEN EN QUE SE AGREGAN
TIPOS_NUEVOS="portadilla portada creditos"

# COLUMNAS NUEVAS DE libros_md: NOMBRE|DEFINICIÓN. EL ORDEN ES EL DE LA TABLA
COLUMNAS_LIBRO=(
  "texto_catalogacion|TEXT COLLATE utf8mb4_unicode_ci NULL COMMENT 'Ficha de catalogación del impreso: Markdown de línea con marcadores (SC-25)'"
  "texto_legal|TEXT COLLATE utf8mb4_unicode_ci NULL COMMENT 'Texto legal del impreso: Markdown de línea con marcadores (SC-25)'"
  "texto_catalogacion_digital|TEXT COLLATE utf8mb4_unicode_ci NULL COMMENT 'Ficha de catalogación del EPUB; vacío: bloque genérico (SC-25)'"
  "texto_legal_digital|TEXT COLLATE utf8mb4_unicode_ci NULL COMMENT 'Texto legal del EPUB; vacío: bloque genérico (SC-25)'"
  "logo_portada|VARCHAR(255) COLLATE utf8mb4_unicode_ci NULL COMMENT 'Nombre del archivo en media/: logo-portada.EXT'"
  "logo_coleccion|VARCHAR(255) COLLATE utf8mb4_unicode_ci NULL COMMENT 'Nombre del archivo en media/: logo-coleccion.EXT'"
)
COLUMNAS_ANTES=72
COLUMNAS_DESPUES=78

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.4.0${RESET}"
echo "-------------------------------------------------"
echo "Agrega los tipos de pieza de las primeras del libro y los campos de"
echo "textos legales y logos. No borra ni modifica valores existentes."
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

# LA CADENA ES ORDENADA: 1.4.0 VA SOBRE 1.3.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.3.0';")" != "1" ]; then
  error "Falta la actualización 1.3.0. Aplicala primero (actualizar-esquema-1.3.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DEL ESQUEMA ---
# SE DECIDE POR information_schema, NUNCA POR LAS FILAS DE esquema_version
tipo_enum() {
  valor "SELECT COLUMN_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='capitulos' AND COLUMN_NAME='tipo_capitulo';"
}

# CUENTA UN VALOR EN LA LISTA DEL ENUM, COMPARANDO EL LITERAL ENTRE COMILLAS
enum_tiene() {
  case "$(tipo_enum)" in
    *"'$1'"*) echo 1 ;;
    *)        echo 0 ;;
  esac
}

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND COLUMN_NAME='$1';"
}

columnas_libro() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md';"
}

ENUM_ANTES="$(tipo_enum)"
case "$ENUM_ANTES" in
  enum\(*) ;;
  *)
    error "capitulos.tipo_capitulo no es un ENUM (es: '${ENUM_ANTES}'): el esquema no es el previsto."
    exit 1
    ;;
esac

TIPOS_FALTANTES=""
for t in $TIPOS_NUEVOS; do
  if [ "$(enum_tiene "$t")" = "0" ]; then
    TIPOS_FALTANTES="${TIPOS_FALTANTES} ${t}"
  fi
done
TIPOS_FALTANTES="${TIPOS_FALTANTES# }"

COLUMNAS_FALTANTES=()
for c in "${COLUMNAS_LIBRO[@]}"; do
  nombre="${c%%|*}"
  if [ "$(existe_columna "$nombre")" = "0" ]; then
    COLUMNAS_FALTANTES+=("$c")
  fi
done

# LA TABLA TIENE QUE ESTAR EN UNO DE LOS DOS CONTEOS CONOCIDOS, O EN UNO
# INTERMEDIO SI UNA CORRIDA ANTERIOR SE INTERRUMPIÓ. OTRO CONTEO ES UN
# ESQUEMA QUE ESTE SCRIPT NO CONOCE
ESPERADAS=$((COLUMNAS_DESPUES - ${#COLUMNAS_FALTANTES[@]}))
if [ "$(columnas_libro)" != "$ESPERADAS" ]; then
  error "libros_md tiene $(columnas_libro) columnas y se esperaban ${ESPERADAS}: el esquema no es el previsto."
  exit 1
fi

if [ -z "$TIPOS_FALTANTES" ] && [ "${#COLUMNAS_FALTANTES[@]}" -eq 0 ]; then
  ok "El esquema ya tiene todo lo de 1.4.0. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente:"
  if [ -n "$TIPOS_FALTANTES" ]; then
    echo "    - tipo_capitulo: ${TIPOS_FALTANTES}"
  fi
  for c in "${COLUMNAS_FALTANTES[@]}"; do
    echo "    - libros_md.${c%%|*}"
  done
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.4.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`capitulos\`" "$RESPALDO" || ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene las tablas capitulos y libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---

  # 5.1 ENUM. LA LISTA NUEVA ES LA REAL MÁS LOS VALORES QUE FALTAN, AL FINAL:
  # EL BASELINE NO COINCIDE CON EL CÓDIGO (NO TIENE indice_concepto NI
  # indice_autores) Y UN MODIFY CON UNA LISTA ESCRITA A MANO BORRARÍA LO QUE
  # NO NOMBRE. AGREGAR AL FINAL NO RENUMERA LOS VALORES EXISTENTES.
  # EL MODIFY CONSERVA COLACIÓN, NULL, DEFAULT Y COMENTARIO (SC-22)
  if [ -n "$TIPOS_FALTANTES" ]; then
    AGREGADO=""
    for t in $TIPOS_FALTANTES; do
      AGREGADO="${AGREGADO},'${t}'"
    done
    # COLUMN_TYPE YA ES UNA LISTA SQL VÁLIDA: MYSQL DUPLICA LOS APÓSTROFOS
    TIPO_NUEVO="${ENUM_ANTES%)}${AGREGADO})"
    ATRIBUTOS="$(valor "SELECT CONCAT(' COLLATE ', COLLATION_NAME, IF(IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'), IF(COLUMN_DEFAULT IS NULL, '', CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT))), IF(COLUMN_COMMENT = '', '', CONCAT(' COMMENT ', QUOTE(COLUMN_COMMENT)))) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='capitulos' AND COLUMN_NAME='tipo_capitulo';")"
    echo "ALTER TABLE \`capitulos\` MODIFY \`tipo_capitulo\` ${TIPO_NUEVO}${ATRIBUTOS};" | mysql_adm "$DB"
    ok "tipo_capitulo: agregados ${TIPOS_FALTANTES}."
  fi

  # 5.2 COLUMNAS. SIN AFTER: VAN AL FINAL, EN EL ORDEN DE LA LISTA. MYSQL 8.0
  # NO TIENE ADD COLUMN IF NOT EXISTS: LA EXISTENCIA SE VERIFICÓ EN EL PUNTO 3
  for c in "${COLUMNAS_FALTANTES[@]}"; do
    nombre="${c%%|*}"
    definicion="${c#*|}"
    mysql_adm "$DB" -e "ALTER TABLE \`libros_md\` ADD COLUMN \`${nombre}\` ${definicion};"
    ok "libros_md.${nombre} agregada."
  done

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0

  for t in $TIPOS_NUEVOS; do
    [ "$(enum_tiene "$t")" = "1" ] || { error "tipo_capitulo no tiene '${t}'."; FALLAS=1; }
  done

  # NINGÚN VALOR PREVIO DEL ENUM SE PERDIÓ: LA LISTA NUEVA EMPIEZA CON LA VIEJA
  ENUM_DESPUES="$(tipo_enum)"
  case "$ENUM_DESPUES" in
    "${ENUM_ANTES%)}"*) ;;
    *) error "La lista de tipo_capitulo no conserva la anterior."; FALLAS=1 ;;
  esac

  # EL DEFAULT 'capitulo' TIENE QUE SOBREVIVIR AL MODIFY
  DEF_TIPO="$(valor "SELECT IFNULL(COLUMN_DEFAULT, '') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='capitulos' AND COLUMN_NAME='tipo_capitulo';")"
  [ "$DEF_TIPO" = "capitulo" ] || { error "tipo_capitulo perdió su DEFAULT 'capitulo' (quedó: '${DEF_TIPO}')."; FALLAS=1; }

  for c in "${COLUMNAS_LIBRO[@]}"; do
    nombre="${c%%|*}"
    [ "$(existe_columna "$nombre")" = "1" ] || { error "Falta libros_md.${nombre}."; FALLAS=1; }
  done
  [ "$(columnas_libro)" = "$COLUMNAS_DESPUES" ] || { error "libros_md no tiene ${COLUMNAS_DESPUES} columnas."; FALLAS=1; }

  # LAS SEIS VAN AL FINAL: HAY CÓDIGO QUE LEE POR POSICIÓN (SC-22)
  ULTIMAS="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ' ') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND ORDINAL_POSITION > ${COLUMNAS_ANTES};")"
  [ "$ULTIMAS" = "texto_catalogacion texto_legal texto_catalogacion_digital texto_legal_digital logo_portada logo_coleccion" ] \
    || { error "Las columnas nuevas no quedaron al final y en orden (quedó: ${ULTIMAS})."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (FILA DEMASIADO
    # GRANDE) DESPUÉS DE HABERLA BORRADO: EL VOLCADO NO TRAE LA LÍNEA QUE SÍ
    # TRAE EL BASELINE (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: tres tipos nuevos y libros_md con ${COLUMNAS_DESPUES} columnas."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# 8.1 PIEZAS SIN TIPO: UN VALOR QUE NO ESTABA EN EL ENUM, GUARDADO SIN MODO
#     ESTRICTO, QUEDA COMO CADENA VACÍA. EL GENERADOR LO MANDA AL CUERPO
# 8.2 EL ESPACIO RESERVADO fm-00..fm-09 YA OCUPADO: ANTES DE DECLARAR LAS
#     PRIMERAS HAY QUE SABER QUÉ NOMBRES ESTÁN TOMADOS
echo
info "Informe de control 1: piezas con tipo_capitulo vacío o nulo"
mysql_adm "$DB" -t <<'SQL'
SELECT c.id_capitulo, c.id_libro, c.nombre_archivo, LEFT(c.titulo_capitulo, 40) AS titulo
FROM capitulos c
WHERE c.tipo_capitulo IS NULL OR c.tipo_capitulo = ''
ORDER BY c.id_libro, c.nombre_archivo;
SQL

echo
info "Informe de control 2: piezas que ya ocupan fm-00 a fm-09"
mysql_adm "$DB" -t <<'SQL'
SELECT c.id_libro, LEFT(l.titulo_libro, 30) AS libro, c.nombre_archivo, c.tipo_capitulo
FROM capitulos c
LEFT JOIN libros_md l ON l.id_libro = c.id_libro
WHERE c.nombre_archivo REGEXP '^fm-0[0-9]'
ORDER BY c.id_libro, c.nombre_archivo;
SQL
echo "Si una tabla no aparece, no hay filas. El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.4.0 lista.${RESET}"
