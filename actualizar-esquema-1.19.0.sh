#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.19.0.sh
# Propósito : Actualización 1.19.0 de la base de gbpublisher, sobre una base
#             EN USO. Contrato con gbWeb (decisiones de Alberto, 02/11):
#               1. Columna nueva libros_md.url_compra: enlace al punto de
#                  venta externo (Mercado Libre u otro). «Sin dato» es NULL
#                  (GV-74), con CHECK (<> '').
#               2. Tabla nueva libro_tapa_web: la tapa en versión web, que
#                  gbpublisher genera al guardar con
#                  convert -resize '600x>' -strip -quality 80 (JPEG idéntico
#                  byte a byte entre corridas, medido en ImageMagick 6.9.12-98,
#                  02/11). gbWeb solo copia los bytes. Sin fecha de
#                  actualización a propósito: nada variable llega a la salida.
#               3. Cuatro VIEW v_web_*: lo único que gbWeb puede leer.
#                  Regla de visibilidad: solo queda afuera en_preparacion
#                  (descatalogado se muestra: sirve a las bibliotecas).
#                  SQL SECURITY DEFINER: la cuenta de gbWeb lee las VIEW sin
#                  permisos sobre las tablas (medido en 8.0.46, 02/11).
#             La cuenta de MySQL de gbWeb NO se crea acá: es una decisión de
#             cada instalación y va por un script aparte.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.19.0.sh
# Requisitos: MySQL 8.0.16 o posterior (CHECK).
# Reglas    : BBDD_LEEME.md §5 y SC-22 (columna nueva al final, lote 4). IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.18.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL (information_schema), objeto por objeto.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: libros_md pasa de 79 a 80;
#             entra libro_tapa_web 6. VA JUNTO CON EL .deb QUE ACTUALIZA ESE
#             ÍNDICE: con el .deb anterior la validación del esquema falla.
# Pendiente : generar-baseline.sh enumera solo BASE TABLE: hasta ajustarlo,
#             un baseline nuevo sale SIN las VIEW v_web_*.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.19.0"
PREVIO="actualizacion-1.18.0"
DESCRIPCION="Contrato con gbWeb: libros_md.url_compra, tabla libro_tapa_web y VIEW v_web_libro, v_web_libro_persona, v_web_coleccion, v_web_libro_tapa"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# COLUMNAS ESPERADAS (LAS DE hEsquema PARA LAS TABLAS)
COLS_LIBROS_ANTES=79
COLS_LIBROS=80
COLS_TAPA=6
# COLUMNAS DE CADA VIEW (information_schema.COLUMNS TAMBIÉN LISTA LAS VIEW)
declare -A COLS_VISTA=(
  [v_web_libro]=20
  [v_web_libro_persona]=7
  [v_web_coleccion]=6
  [v_web_libro_tapa]=6
)
# ORDEN DE CREACIÓN: LAS TRES ÚLTIMAS SE APOYAN EN v_web_libro
VISTAS=(v_web_libro v_web_libro_persona v_web_coleccion v_web_libro_tapa)
# RESTRICCIONES CHECK AL TERMINAR: 1 EN libros_md + 4 EN libro_tapa_web
CHECK_ESPERADAS=5

# AL FINAL DE LA TABLA, SIN AFTER: HAY CÓDIGO QUE LEE POR POSICIÓN (SC-22, LOTE 4)
DDL_COL="ALTER TABLE libros_md
  ADD COLUMN url_compra VARCHAR(500) NULL DEFAULT NULL COMMENT 'Enlace al punto de venta externo; NULL sin dato (GV-74)',
  ADD CONSTRAINT chk_libros_url_compra CHECK (url_compra <> '');"

# id_libro ES LA CLAVE: UNA TAPA WEB POR LIBRO. CASCADE: SIN LIBRO NO HAY TAPA
DDL_TAPA="CREATE TABLE IF NOT EXISTS libro_tapa_web (
  id_libro INT NOT NULL,
  imagen MEDIUMBLOB NOT NULL COMMENT 'JPEG ya convertido; gbWeb copia los bytes tal cual',
  formato VARCHAR(10) NOT NULL DEFAULT 'jpg',
  ancho INT NOT NULL COMMENT 'Píxeles; para width en <img>',
  alto INT NOT NULL COMMENT 'Píxeles; para height en <img>',
  sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT 'SHA2(imagen, 256); nombra el archivo publicado',
  PRIMARY KEY (id_libro),
  CONSTRAINT fk_tapaweb_libro FOREIGN KEY (id_libro) REFERENCES libros_md (id_libro) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_tapaweb_formato CHECK (formato = 'jpg'),
  CONSTRAINT chk_tapaweb_ancho CHECK (ancho > 0),
  CONSTRAINT chk_tapaweb_alto CHECK (alto > 0),
  CONSTRAINT chk_tapaweb_sha256 CHECK (REGEXP_LIKE(sha256, '^[0-9a-f]{64}\$', 'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Tapa en versión web, leída por gbWeb a través de v_web_libro_tapa';"

# EL ORDEN LO PONE gbWeb AL CONSULTAR: UNA VIEW NO GARANTIZA ORDEN
# (LIBROS: ano_publicacion DESC, mes_numero DESC, id_libro DESC)
declare -A DDL_VISTA
DDL_VISTA[v_web_libro]="CREATE SQL SECURITY DEFINER VIEW v_web_libro AS
SELECT
  l.id_libro, l.titulo_libro, l.subtitulo, l.idioma_principal,
  l.isbn_impreso, l.isbn_electronico, l.numero_paginas, l.ano_publicacion,
  CASE LOWER(TRIM(l.mes_publicacion))
    WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3
    WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6
    WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8
    WHEN 'septiembre' THEN 9 WHEN 'setiembre' THEN 9
    WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12
    ELSE NULL
  END AS mes_numero,
  l.fecha_publicacion_completa, l.id_coleccion, l.numero_en_coleccion,
  l.estado_publicacion, l.tipo_acceso, l.resumen_libro, l.palabras_clave_libro,
  l.url_libro, l.url_descarga_pdf, l.url_descarga_epub, l.url_compra
FROM libros_md AS l
WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

# HEREDA LA VISIBILIDAD DE v_web_libro. NO EXPONE EMAIL NI AFILIACIÓN.
# ORDEN EN gbWeb: id_libro, orden_autoria, id_relacion (DESEMPATE)
DDL_VISTA[v_web_libro_persona]="CREATE SQL SECURITY DEFINER VIEW v_web_libro_persona AS
SELECT
  la.id_libro, la.id_relacion, la.orden_autoria, la.rol_libro,
  COALESCE(NULLIF(TRIM(a.nombre_preferido), ''), a.nombre_completo) AS nombre_mostrar,
  a.apellidos_nombre, a.orcid
FROM libro_autor AS la
JOIN autores AS a ON a.id_autor = la.id_autor
JOIN v_web_libro AS v ON v.id_libro = la.id_libro;"

DDL_VISTA[v_web_coleccion]="CREATE SQL SECURITY DEFINER VIEW v_web_coleccion AS
SELECT c.id_coleccion, c.nombre, c.nombre_abreviado, c.descripcion, c.url_logo, c.activa
FROM colecciones AS c
WHERE EXISTS (SELECT 1 FROM v_web_libro AS v WHERE v.id_coleccion = c.id_coleccion);"

# VIEW SEPARADA: EL LISTADO DE LIBROS NO ARRASTRA LOS BLOBS
DDL_VISTA[v_web_libro_tapa]="CREATE SQL SECURITY DEFINER VIEW v_web_libro_tapa AS
SELECT t.id_libro, t.imagen, t.formato, t.ancho, t.alto, t.sha256
FROM libro_tapa_web AS t
JOIN v_web_libro AS v ON v.id_libro = t.id_libro;"

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

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

# 'BASE TABLE', 'VIEW' O VACÍO SI NO EXISTE
tipo_de() {
  valor "SELECT TABLE_TYPE FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# REGLA DE BORRADO DE UNA CLAVE FORÁNEA: CASCADE, RESTRICT...
regla_borrado() {
  valor "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND TABLE_NAME='$1' AND CONSTRAINT_NAME='$2';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.19.0${RESET}"
echo "--------------------------------------------------"
echo "Agrega lo que necesita gbWeb para armar el portal de la editorial:"
echo "el enlace de compra de cada libro, la tapa en versión web y cuatro"
echo "vistas de solo lectura. No modifica ni borra datos existentes."
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

# LA CADENA ES ORDENADA: 1.19.0 VA SOBRE 1.18.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.18.0. Aplicala primero (actualizar-esquema-1.18.0.sh)."
  exit 1
fi

# LAS VIEW LEEN ESTAS TABLAS: SIN ELLAS NO HAY NADA QUE HACER
for T in libros_md libro_autor autores colecciones; do
  if [ "$(tipo_de "$T")" != "BASE TABLE" ]; then
    error "La base no tiene la tabla ${T}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL, OBJETO POR OBJETO ---
# 3.1 COLUMNA url_compra: SE AGREGA SOLO SI libros_md TIENE LA FORMA CONOCIDA
AGREGAR_COL=0
N="$(columnas_de libros_md)"
if [ "$(existe_columna libros_md url_compra)" = "1" ]; then
  if [ "$N" != "${COLS_LIBROS}" ]; then
    error "libros_md tiene url_compra pero ${N} columnas (se esperaban ${COLS_LIBROS}). Revisala a mano. No se modificó nada."
    exit 1
  fi
elif [ "$N" = "${COLS_LIBROS_ANTES}" ]; then
  AGREGAR_COL=1
else
  error "libros_md tiene una forma inesperada (${N} columnas, sin url_compra). Revisala a mano. No se modificó nada."
  exit 1
fi

# 3.2 TABLA libro_tapa_web
CREAR_TAPA=0
TIPO="$(tipo_de libro_tapa_web)"
if [ -z "$TIPO" ]; then
  CREAR_TAPA=1
elif [ "$TIPO" != "BASE TABLE" ] || [ "$(columnas_de libro_tapa_web)" != "${COLS_TAPA}" ]; then
  error "libro_tapa_web tiene una forma inesperada. Revisala a mano. No se modificó nada."
  exit 1
fi

# 3.3 VIEW: UNA EXISTENTE CON OTRA FORMA ES ALGO QUE ESTE SCRIPT NO CONOCE
declare -A CREAR_VISTA
for V in "${VISTAS[@]}"; do
  CREAR_VISTA[$V]=0
  TIPO="$(tipo_de "$V")"
  if [ -z "$TIPO" ]; then
    CREAR_VISTA[$V]=1
  elif [ "$TIPO" != "VIEW" ] || [ "$(columnas_de "$V")" != "${COLS_VISTA[$V]}" ]; then
    error "${V} existe con una forma inesperada. Revisala a mano. No se modificó nada."
    exit 1
  fi
done

PENDIENTES=$(( AGREGAR_COL + CREAR_TAPA ))
for V in "${VISTAS[@]}"; do PENDIENTES=$(( PENDIENTES + CREAR_VISTA[$V] )); done

if [ "$PENDIENTES" -eq 0 ]; then
  ok "No hay nada que agregar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$AGREGAR_COL" -eq 1 ] && info "Se agrega libros_md.url_compra."
  [ "$CREAR_TAPA" -eq 1 ] && info "Se crea libro_tapa_web."
  for V in "${VISTAS[@]}"; do
    [ "${CREAR_VISTA[$V]}" -eq 1 ] && info "Se crea la vista ${V}."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.19.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # TABLA TESTIGO: LA QUE SE MODIFICA TIENE QUE ESTAR EN EL RESPALDO (SC-22)
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # LA RESTAURACIÓN NO BORRA LO QUE EL RESPALDO NO CONTIENE: LAS VIEW Y LA
  # TABLA NUEVAS QUEDARÍAN, Y v_web_libro APUNTARÍA A UNA COLUMNA INEXISTENTE
  # (MEDIDO EN 8.0.46, 02/11). SE BORRAN ANTES DE RESTAURAR.
  # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
  VOLVER_ATRAS="sudo mysql ${DB} -e \"DROP VIEW IF EXISTS v_web_libro_tapa, v_web_coleccion, v_web_libro_persona, v_web_libro; DROP TABLE IF EXISTS libro_tapa_web;\" && sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

  # --- 5. CAMBIOS ---
  # LA COLUMNA VA PRIMERO: v_web_libro LA LEE
  if [ "$AGREGAR_COL" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_COL}"
    ok "Agregada libros_md.url_compra."
  fi
  # LA TABLA ANTES QUE v_web_libro_tapa
  if [ "$CREAR_TAPA" -eq 1 ]; then
    mysql_adm "$DB" -e "${DDL_TAPA}"
    ok "Creada libro_tapa_web."
  fi
  # EN EL ORDEN DE VISTAS: LAS TRES ÚLTIMAS SE APOYAN EN v_web_libro
  for V in "${VISTAS[@]}"; do
    if [ "${CREAR_VISTA[$V]}" -eq 1 ]; then
      mysql_adm "$DB" -e "${DDL_VISTA[$V]}"
      ok "Creada la vista ${V}."
    fi
  done

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  if [ "$(columnas_de libros_md)" != "${COLS_LIBROS}" ] || [ "$(existe_columna libros_md url_compra)" != "1" ]; then
    error "libros_md no quedó como se esperaba (${COLS_LIBROS} columnas con url_compra)."
    FALLA=1
  fi
  if [ "$(tipo_de libro_tapa_web)" != "BASE TABLE" ] || [ "$(columnas_de libro_tapa_web)" != "${COLS_TAPA}" ]; then
    error "La tabla libro_tapa_web no quedó como se esperaba."
    FALLA=1
  fi
  if [ "$(regla_borrado libro_tapa_web fk_tapaweb_libro)" != "CASCADE" ]; then
    error "libro_tapa_web: la clave foránea no quedó como se esperaba (libro CASCADE)."
    FALLA=1
  fi
  # LAS VIEW: EXISTEN, TIENEN SUS COLUMNAS Y SE EJECUTAN CON LOS PERMISOS DE QUIEN LAS CREÓ
  for V in "${VISTAS[@]}"; do
    if [ "$(tipo_de "$V")" != "VIEW" ] || [ "$(columnas_de "$V")" != "${COLS_VISTA[$V]}" ]; then
      error "La vista ${V} no quedó como se esperaba."
      FALLA=1
    elif [ "$(valor "SELECT SECURITY_TYPE FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${V}';")" != "DEFINER" ]; then
      error "La vista ${V} no quedó con SQL SECURITY DEFINER."
      FALLA=1
    fi
  done
  CHK="$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND CONSTRAINT_NAME IN ('chk_libros_url_compra','chk_tapaweb_formato','chk_tapaweb_ancho','chk_tapaweb_alto','chk_tapaweb_sha256');")"
  if [ "$CHK" != "$CHECK_ESPERADAS" ]; then
    error "Hay ${CHK} restricciones CHECK nuevas (se esperaban ${CHECK_ESPERADAS})."
    FALLA=1
  fi

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: url_compra, libro_tapa_web, ${CHK} restricciones CHECK y cuatro vistas DEFINER."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: ${VOLVER_ATRAS}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: lo que vería gbWeb hoy"
mysql_adm "$DB" -e "SELECT (SELECT COUNT(*) FROM v_web_libro) AS libros_visibles, (SELECT COUNT(*) FROM v_web_libro_tapa) AS con_tapa_web, (SELECT COUNT(*) FROM v_web_libro WHERE url_compra IS NOT NULL) AS con_url_compra, (SELECT COUNT(*) FROM v_web_coleccion) AS colecciones;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.19.0 lista.${RESET}"
