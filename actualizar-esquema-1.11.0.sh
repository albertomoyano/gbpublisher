#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.11.0.sh
# Propósito : Actualización 1.11.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos. Lista de capitulos.tipo_capitulo:
#               1. AGREGA AL FINAL indice_concepto e indice_autores, que el
#                  código ofrece (FMetadatosCapitulos) y el baseline 1.0.0 no
#                  trae. Sin ellos, guardar una pieza de ese tipo falla con
#                  «Data truncated for column 'tipo_capitulo'» (modo estricto)
#               2. QUITA indice_tematico e indice_analitico: vienen del
#                  baseline 1.0.0 y no corresponden a ningún índice del
#                  sistema. Los índices son tres: onomástico, autores y
#                  concepto. SOLO SE QUITAN SI NINGUNA PIEZA LOS USA
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : ./actualizar-esquema-1.11.0.sh
# Requisitos: MySQL en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.10.0 registrada: la cadena es ordenada. Sobre esa
#             base, qué agregar y qué quitar lo decide el ESTADO REAL.
# Criterio  : la lista nueva es la REAL, sin los dos valores a quitar, más
#             los que falten AL FINAL. Un valor que el script no nombra se
#             conserva (mismo criterio que la 1.4.0). El orden de la lista
#             puede diferir entre bases: ningún código depende del ordinal
#             del ENUM.
# Lote      : no hay cambios de código. capitulos no cambia de conteo de
#             columnas, así que ObtenerEsquemaEsperado no se toca.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.11.0"
PREVIO="actualizacion-1.10.0"
DESCRIPCION="tipo_capitulo: agrega indice_concepto e indice_autores; quita indice_tematico e indice_analitico"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# VALORES QUE SE AGREGAN, EN ESE ORDEN, Y VALORES QUE SE QUITAN
TIPOS_AGREGAR="indice_concepto indice_autores"
TIPOS_QUITAR="indice_tematico indice_analitico"

# LA LISTA DEL CÓDIGO (FMetadatosCapitulos, APARTADO 1). LA VERIFICACIÓN
# EXIGE QUE TODOS ESTÉN; EL INFORME AVISA DE LOS QUE SOBREN
TIPOS_CODIGO="portadilla portada creditos prologo prefacio presentacion
palabras_preliminares introduccion dedicatoria agradecimientos nota_traductor
nota_editor lista_figuras lista_tablas lista_abreviaturas capitulo
conclusiones epilogo posfacio post_scriptum apendice glosario bibliografia
sobre_autores cronologia indice_onomastico indice_concepto indice_autores
colofon otro"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.11.0${RESET}"
echo "--------------------------------------------------"
echo "Corrige la lista de tipos de pieza de los libros: agrega los índices"
echo "de concepto y de autores, y quita dos tipos que no se usan."
echo "No modifica ninguna pieza."
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

# LA CADENA ES ORDENADA: 1.11.0 VA SOBRE 1.10.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.10.0. Aplicala primero (actualizar-esquema-1.10.0.sh)."
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

# DISTRIBUCIÓN DE PIEZAS POR TIPO. SE ORDENA POR EL TEXTO Y NO POR EL ENUM:
# QUITAR VALORES RENUMERA LOS ORDINALES Y CAMBIARÍA EL ORDEN DE UN GROUP BY
distribucion() {
  valor "SELECT IFNULL(GROUP_CONCAT(CONCAT(t, ':', n) ORDER BY t SEPARATOR ' '), '') FROM (SELECT IFNULL(CAST(tipo_capitulo AS CHAR), '(nulo)') AS t, COUNT(*) AS n FROM \`${DB}\`.capitulos GROUP BY t) AS d;"
}

ENUM_ANTES="$(tipo_enum)"
case "$ENUM_ANTES" in
  enum\(*\)) ;;
  *)
    error "capitulos.tipo_capitulo no es un ENUM (es: '${ENUM_ANTES}'): el esquema no es el previsto."
    exit 1
    ;;
esac

# LA LISTA SE PARTE POR COMAS. ES SEGURO SOLO SI CADA VALOR ES UN
# IDENTIFICADOR SIMPLE ENTRE APÓSTROFOS; SI NO, EL ESQUEMA NO ES EL PREVISTO
CUERPO="${ENUM_ANTES#enum(}"
CUERPO="${CUERPO%)}"
IFS=',' read -r -a VALORES_ANTES <<< "$CUERPO"
for v in "${VALORES_ANTES[@]}"; do
  if ! [[ "$v" =~ ^\'[a-z_]+\'$ ]]; then
    error "Valor inesperado en tipo_capitulo: ${v}. El esquema no es el previsto."
    exit 1
  fi
done

TIPOS_FALTANTES=""
for t in $TIPOS_AGREGAR; do
  if [ "$(enum_tiene "$t")" = "0" ]; then
    TIPOS_FALTANTES="${TIPOS_FALTANTES} ${t}"
  fi
done
TIPOS_FALTANTES="${TIPOS_FALTANTES# }"

TIPOS_SOBRANTES=""
for t in $TIPOS_QUITAR; do
  if [ "$(enum_tiene "$t")" = "1" ]; then
    TIPOS_SOBRANTES="${TIPOS_SOBRANTES} ${t}"
  fi
done
TIPOS_SOBRANTES="${TIPOS_SOBRANTES# }"

# UN VALOR A QUITAR QUE ALGUNA PIEZA USA NO SE QUITA: EN MODO ESTRICTO EL
# ALTER FALLARÍA, Y SIN MODO ESTRICTO LA PIEZA QUEDARÍA CON TIPO VACÍO.
# SE ABORTA SIN TOCAR NADA Y SE LISTAN LAS PIEZAS PARA REASIGNARLAS
if [ -n "$TIPOS_SOBRANTES" ]; then
  LISTA_SQL="$(printf "'%s'," $TIPOS_SOBRANTES)"
  LISTA_SQL="${LISTA_SQL%,}"
  EN_USO="$(valor "SELECT COUNT(*) FROM \`${DB}\`.capitulos WHERE tipo_capitulo IN (${LISTA_SQL});")"
  if [ "$EN_USO" != "0" ]; then
    error "Hay ${EN_USO} pieza(s) con un tipo que se quiere quitar. No se modificó nada."
    mysql_adm "$DB" -t -e "SELECT c.id_capitulo, c.id_libro, c.nombre_archivo, c.tipo_capitulo, LEFT(c.titulo_capitulo, 40) AS titulo FROM capitulos c WHERE c.tipo_capitulo IN (${LISTA_SQL}) ORDER BY c.id_libro, c.nombre_archivo;"
    error "Asigná a esas piezas otro tipo desde la aplicación y volvé a correr el script."
    exit 1
  fi
fi

if [ -z "$TIPOS_FALTANTES" ] && [ -z "$TIPOS_SOBRANTES" ]; then
  ok "La lista de tipo_capitulo ya está corregida. No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente en tipo_capitulo:"
  [ -n "$TIPOS_FALTANTES" ] && echo "    - agregar: ${TIPOS_FALTANTES}"
  [ -n "$TIPOS_SOBRANTES" ] && echo "    - quitar:  ${TIPOS_SOBRANTES}"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.11.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`capitulos\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla capitulos. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # 5.1 LISTA NUEVA: LA REAL SIN LOS SOBRANTES, EN SU ORDEN, MÁS LOS
  # FALTANTES AL FINAL. LO QUE EL SCRIPT NO NOMBRA SE CONSERVA
  DISTRIB_ANTES="$(distribucion)"
  LISTA_NUEVA=""
  for v in "${VALORES_ANTES[@]}"; do
    case " ${TIPOS_SOBRANTES} " in
      *" ${v//\'/} "*) ;;
      *) LISTA_NUEVA="${LISTA_NUEVA},${v}" ;;
    esac
  done
  for t in $TIPOS_FALTANTES; do
    LISTA_NUEVA="${LISTA_NUEVA},'${t}'"
  done
  LISTA_NUEVA="${LISTA_NUEVA#,}"
  TIPO_NUEVO="enum(${LISTA_NUEVA})"

  # 5.2 EL MODIFY CONSERVA COLACIÓN, NULL, DEFAULT Y COMENTARIO (SC-22)
  ATRIBUTOS="$(valor "SELECT CONCAT(' COLLATE ', COLLATION_NAME, IF(IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'), IF(COLUMN_DEFAULT IS NULL, '', CONCAT(' DEFAULT ', QUOTE(COLUMN_DEFAULT))), IF(COLUMN_COMMENT = '', '', CONCAT(' COMMENT ', QUOTE(COLUMN_COMMENT)))) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='capitulos' AND COLUMN_NAME='tipo_capitulo';")"
  echo "ALTER TABLE \`capitulos\` MODIFY \`tipo_capitulo\` ${TIPO_NUEVO}${ATRIBUTOS};" | mysql_adm "$DB"
  ok "tipo_capitulo: lista corregida."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLAS=0

  # TODOS LOS TIPOS QUE OFRECE EL CÓDIGO TIENEN QUE ESTAR
  for t in $TIPOS_CODIGO; do
    [ "$(enum_tiene "$t")" = "1" ] || { error "tipo_capitulo no tiene '${t}'."; FALLAS=1; }
  done

  # LOS QUITADOS NO TIENEN QUE ESTAR
  for t in $TIPOS_QUITAR; do
    [ "$(enum_tiene "$t")" = "0" ] || { error "tipo_capitulo todavía tiene '${t}'."; FALLAS=1; }
  done

  # LA LISTA QUEDÓ EXACTAMENTE COMO SE ARMÓ
  [ "$(tipo_enum)" = "$TIPO_NUEVO" ] || { error "La lista de tipo_capitulo no es la prevista (quedó: $(tipo_enum))."; FALLAS=1; }

  # NINGUNA PIEZA CAMBIÓ DE TIPO
  DISTRIB_DESPUES="$(distribucion)"
  [ "$DISTRIB_ANTES" = "$DISTRIB_DESPUES" ] || { error "Cambió la distribución de piezas por tipo (antes: ${DISTRIB_ANTES}; después: ${DISTRIB_DESPUES})."; FALLAS=1; }

  # EL DEFAULT 'capitulo' TIENE QUE SOBREVIVIR AL MODIFY
  DEF_TIPO="$(valor "SELECT IFNULL(COLUMN_DEFAULT, '') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='capitulos' AND COLUMN_NAME='tipo_capitulo';")"
  [ "$DEF_TIPO" = "capitulo" ] || { error "tipo_capitulo perdió su DEFAULT 'capitulo' (quedó: '${DEF_TIPO}')."; FALLAS=1; }

  if [ "$FALLAS" -ne 0 ]; then
    error "La verificación falló. NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: lista completa, sin tipos sobrantes y sin piezas alteradas."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "La lista ya estaba corregida; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
# 8.1 PIEZAS SIN TIPO: UN GUARDADO HECHO ALGUNA VEZ SIN MODO ESTRICTO DEJA
#     CADENA VACÍA EN LUGAR DE ERROR. EL GENERADOR LAS MANDA AL CUERPO
# 8.2 VALORES DEL ENUM QUE EL CÓDIGO NO OFRECE: NO SE TOCAN, SE AVISAN
echo
info "Informe de control 1: piezas con tipo_capitulo vacío o nulo"
mysql_adm "$DB" -t <<'SQL'
SELECT c.id_capitulo, c.id_libro, c.nombre_archivo, LEFT(c.titulo_capitulo, 40) AS titulo
FROM capitulos c
WHERE c.tipo_capitulo IS NULL OR c.tipo_capitulo = ''
ORDER BY c.id_libro, c.nombre_archivo;
SQL

echo
info "Informe de control 2: valores de tipo_capitulo que el código no ofrece"
CUERPO_FINAL="$(tipo_enum)"
CUERPO_FINAL="${CUERPO_FINAL#enum(}"
CUERPO_FINAL="${CUERPO_FINAL%)}"
IFS=',' read -r -a VALORES_FINAL <<< "$CUERPO_FINAL"
AJENOS=""
for v in "${VALORES_FINAL[@]}"; do
  case " $(echo $TIPOS_CODIGO) " in
    *" ${v//\'/} "*) ;;
    *) AJENOS="${AJENOS} ${v//\'/}" ;;
  esac
done
if [ -n "$AJENOS" ]; then
  warn "Valores que el código no ofrece:${AJENOS}"
else
  ok "Ninguno: la lista coincide con la del código."
fi

echo "Si una tabla no aparece, no hay filas. El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.11.0 lista.${RESET}"
