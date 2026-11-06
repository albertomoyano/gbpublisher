#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.21.0.sh
# Propósito : Actualización 1.21.0 de la base de gbpublisher, sobre una base
#             EN USO (decisiones de Alberto, 04/11/2026):
#               1. Tres idiomas en el libro, como en los capítulos. Al final
#                  de libros_md (SC-22), seis columnas:
#                    resumen_traducido_2, idioma_resumen_traducido_2
#                    palabras_clave_traducidas, idioma_palabras_clave_traducidas
#                    palabras_clave_traducidas_2, idioma_palabras_clave_traducidas_2
#                  El libro queda con el resumen en su idioma y dos
#                  traducciones, y lo mismo para las palabras clave.
#               2. Los puntos de venta: tabla libro_venta, una fila por
#                  tienda (amazon, apple, google, mercadolibre). Reemplaza a
#                  libros_md.url_compra: su valor se pasa a la fila de
#                  mercadolibre y la columna queda en NULL (en desuso; no se
#                  borra porque la lee la vista del contrato).
#               3. El contrato con gbWeb (SC-81):
#                    v_web_libro         + el nombre del idioma principal
#                                          (catálogo idiomas) y las seis
#                                          columnas de 1, al final
#                    v_web_libro_persona + id_autor, al final: gbWeb
#                                          reconoce al mismo autor en otros
#                                          libros por él y no por el nombre
#                    v_web_libro_venta   nueva
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.21.0.sh
# Requisitos: la 1.20.0 registrada.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Qué
#             cambiar lo decide el ESTADO REAL (information_schema).
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: libros_md pasa de 80 a
#             86; entra libro_venta 3. VA JUNTO CON EL .deb (Y LOS FUENTES)
#             QUE TRAEN ESE ÍNDICE Y EL FORMULARIO NUEVO.
# Cuenta    : crear-cuenta-gbweb.sh (repo gbWeb) da a gbweb_lector el SELECT
#             sobre v_web_libro_venta. CREATE OR REPLACE conserva los
#             permisos de las vistas que ya tenía (medido en 8.0.46, 04/11).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.21.0"
PREVIO="actualizacion-1.20.0"
DESCRIPCION="Libro en tres idiomas (resumen y palabras clave), puntos de venta (libro_venta) y contrato con gbWeb"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

COLS_LIBROS_ANTES=80
COLS_LIBROS=86
COLS_VENTA=3
COLS_LIBRO_ANTES=22
COLS_LIBRO=32
COLS_PERSONA_ANTES=7
COLS_PERSONA=8
COLS_VISTA_VENTA=3
CHECK_NUEVAS="'chk_libro_venta_url'"

# UNA SOLA SENTENCIA: O ENTRAN LAS SEIS COLUMNAS O NINGUNA. SIN AFTER (SC-22)
DDL_COLS="ALTER TABLE libros_md
  ADD COLUMN resumen_traducido_2 TEXT NULL DEFAULT NULL COMMENT 'Segunda traducción del resumen',
  ADD COLUMN idioma_resumen_traducido_2 VARCHAR(20) NULL DEFAULT NULL COMMENT 'Código del catálogo idiomas',
  ADD COLUMN palabras_clave_traducidas TEXT NULL DEFAULT NULL COMMENT 'Palabras clave traducidas, separadas por coma',
  ADD COLUMN idioma_palabras_clave_traducidas VARCHAR(20) NULL DEFAULT NULL COMMENT 'Código del catálogo idiomas',
  ADD COLUMN palabras_clave_traducidas_2 TEXT NULL DEFAULT NULL COMMENT 'Segunda traducción de las palabras clave',
  ADD COLUMN idioma_palabras_clave_traducidas_2 VARCHAR(20) NULL DEFAULT NULL COMMENT 'Código del catálogo idiomas';"

# UNA TIENDA POR LIBRO Y POR FILA. CASCADE: SIN LIBRO NO HAY VENTA
DDL_VENTA="CREATE TABLE IF NOT EXISTS libro_venta (
  id_libro INT NOT NULL,
  tienda ENUM('amazon','apple','google','mercadolibre') NOT NULL COMMENT 'El orden del ENUM es el de los botones en gbWeb',
  url VARCHAR(500) NOT NULL COMMENT 'Página del libro en la tienda',
  PRIMARY KEY (id_libro, tienda),
  CONSTRAINT fk_libro_venta_libro FOREIGN KEY (id_libro) REFERENCES libros_md (id_libro) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_libro_venta_url CHECK (REGEXP_LIKE(url, '^https?://[^ ]+\$', 'c'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Puntos de venta de cada libro (gbWeb: v_web_libro_venta)';"

# url_compra PASA A MERCADO LIBRE (DECISIÓN DE ALBERTO: ERA SU ÚNICO USO) Y
# QUEDA EN NULL: UN SOLO LUGAR PARA CADA DATO. INSERT IGNORE: SI LA FILA YA
# ESTÁ (UNA CORRIDA ANTERIOR CORTADA), NO SE DUPLICA NI SE PISA
DML_MIGRAR="INSERT IGNORE INTO libro_venta (id_libro, tienda, url)
  SELECT id_libro, 'mercadolibre', TRIM(url_compra) FROM libros_md
  WHERE url_compra IS NOT NULL AND REGEXP_LIKE(TRIM(url_compra), '^https?://[^ ]+\$', 'c');"
DML_VACIAR="UPDATE libros_md AS l JOIN libro_venta AS v ON v.id_libro = l.id_libro AND v.tienda = 'mercadolibre'
  SET l.url_compra = NULL WHERE l.url_compra IS NOT NULL;"

DDL_LIBRO="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro AS
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
  l.url_libro, l.url_descarga_pdf, l.url_descarga_epub, l.url_compra,
  l.licencia_defecto AS licencia, l.url_licencia,
  i.nombre AS idioma_nombre, i.nombre_ingles AS idioma_nombre_ingles,
  l.resumen_traducido, l.idioma_resumen_traducido,
  l.resumen_traducido_2, l.idioma_resumen_traducido_2,
  l.palabras_clave_traducidas, l.idioma_palabras_clave_traducidas,
  l.palabras_clave_traducidas_2, l.idioma_palabras_clave_traducidas_2
FROM libros_md AS l
LEFT JOIN idiomas AS i ON i.codigo = l.idioma_principal
WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

DDL_PERSONA="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro_persona AS
SELECT
  la.id_libro, la.id_relacion, la.orden_autoria, la.rol_libro,
  COALESCE(NULLIF(TRIM(a.nombre_preferido), ''), a.nombre_completo) AS nombre_mostrar,
  a.apellidos_nombre, a.orcid, la.id_autor
FROM libro_autor AS la
JOIN autores AS a ON a.id_autor = la.id_autor
JOIN v_web_libro AS v ON v.id_libro = la.id_libro;"

# HEREDA LA VISIBILIDAD DE v_web_libro. EL ORDEN LO PONE gbWeb (EL DEL ENUM)
DDL_VENTA_VISTA="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro_venta AS
SELECT lv.id_libro, lv.tienda, lv.url
FROM libro_venta AS lv
JOIN v_web_libro AS v ON v.id_libro = lv.id_libro;"

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

# -r (raw): SIN ÉL, EL MODO -B DUPLICA LAS BARRAS DE UN VALOR CON APÓSTROFO.
# CON LA BASE ELEGIDA: HAY CONSULTAS SOBRE libros_md SIN CALIFICAR
valor() {
  mysql_adm -N -B -r "$DB" -e "$1"
}

columnas_de() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

tipo_de() {
  valor "SELECT TABLE_TYPE FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.21.0${RESET}"
echo "--------------------------------------------------"
echo "El libro en tres idiomas (resumen y palabras clave), sus puntos de"
echo "venta, y lo que gbWeb necesita leer de eso. La URL de compra actual"
echo "pasa a Mercado Libre; no se borra ningún otro dato."
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

# LA CADENA ES ORDENADA: 1.21.0 VA SOBRE 1.20.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.20.0. Aplicala primero (actualizar-esquema-1.20.0.sh)."
  exit 1
fi

if [ "$(tipo_de idiomas)" != "BASE TABLE" ]; then
  error "La base no tiene la tabla idiomas (1.3.0). No se modificó nada."
  exit 1
fi

# --- 3. ESTADO REAL, OBJETO POR OBJETO ---
# 3.1 LAS SEIS COLUMNAS
AGREGAR_COLS=0
N="$(columnas_de libros_md)"
if [ "$(existe_columna libros_md resumen_traducido_2)" = "1" ]; then
  [ "$N" = "$COLS_LIBROS" ] || { error "libros_md tiene resumen_traducido_2 pero ${N} columnas (se esperaban ${COLS_LIBROS}). Revisala a mano. No se modificó nada."; exit 1; }
elif [ "$N" = "$COLS_LIBROS_ANTES" ]; then
  AGREGAR_COLS=1
else
  error "libros_md tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

# 3.2 LA TABLA libro_venta
CREAR_VENTA=0
TIPO="$(tipo_de libro_venta)"
if [ -z "$TIPO" ]; then
  CREAR_VENTA=1
elif [ "$TIPO" != "BASE TABLE" ] || [ "$(columnas_de libro_venta)" != "$COLS_VENTA" ]; then
  error "libro_venta tiene una forma inesperada. Revisala a mano. No se modificó nada."
  exit 1
fi

# 3.3 LA MIGRACIÓN: QUEDA ALGUNA url_compra CON VALOR
MIGRAR="$(valor "SELECT COUNT(*) FROM libros_md WHERE url_compra IS NOT NULL;")"

# 3.4 LAS VISTAS
REEMPLAZAR_LIBRO=0; REEMPLAZAR_PERSONA=0; CREAR_VENTA_VISTA=0
case "$(columnas_de v_web_libro)" in
  "$COLS_LIBRO_ANTES") REEMPLAZAR_LIBRO=1 ;;
  "$COLS_LIBRO") ;;
  *) error "v_web_libro tiene una forma inesperada. Revisala a mano. No se modificó nada."; exit 1 ;;
esac
case "$(columnas_de v_web_libro_persona)" in
  "$COLS_PERSONA_ANTES") REEMPLAZAR_PERSONA=1 ;;
  "$COLS_PERSONA") ;;
  *) error "v_web_libro_persona tiene una forma inesperada. Revisala a mano. No se modificó nada."; exit 1 ;;
esac
TIPO="$(tipo_de v_web_libro_venta)"
if [ -z "$TIPO" ]; then
  CREAR_VENTA_VISTA=1
elif [ "$TIPO" != "VIEW" ] || [ "$(columnas_de v_web_libro_venta)" != "$COLS_VISTA_VENTA" ]; then
  error "v_web_libro_venta tiene una forma inesperada. Revisala a mano. No se modificó nada."
  exit 1
fi

# UNA url_compra QUE NO ES UNA DIRECCIÓN NO SE PUEDE MIGRAR: SE AVISA Y
# QUEDA DONDE ESTÁ, PARA CORREGIRLA A MANO
INVALIDAS="$(valor "SELECT COUNT(*) FROM libros_md WHERE url_compra IS NOT NULL AND NOT REGEXP_LIKE(TRIM(url_compra), '^https?://[^ ]+\$', 'c');")"

PENDIENTES=$(( AGREGAR_COLS + CREAR_VENTA + REEMPLAZAR_LIBRO + REEMPLAZAR_PERSONA + CREAR_VENTA_VISTA ))
[ "$MIGRAR" != "0" ] && [ "$MIGRAR" != "$INVALIDAS" ] && PENDIENTES=$(( PENDIENTES + 1 ))

if [ "$PENDIENTES" -eq 0 ]; then
  ok "No hay nada que cambiar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$AGREGAR_COLS" -eq 1 ] && info "Se agregan a libros_md las seis columnas de los idiomas."
  [ "$CREAR_VENTA" -eq 1 ] && info "Se crea libro_venta."
  [ "$MIGRAR" != "0" ] && info "Se pasan a Mercado Libre ${MIGRAR} URL de compra (y url_compra queda en NULL)."
  [ "$INVALIDAS" != "0" ] && warn "${INVALIDAS} url_compra no son direcciones: quedan sin migrar, para corregir a mano."
  [ "$REEMPLAZAR_LIBRO" -eq 1 ] && info "Se reemplaza la vista v_web_libro."
  [ "$REEMPLAZAR_PERSONA" -eq 1 ] && info "Se reemplaza la vista v_web_libro_persona."
  [ "$CREAR_VENTA_VISTA" -eq 1 ] && info "Se crea la vista v_web_libro_venta."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.21.0-$(date '+%Y%m%d-%H%M%S').sql"
  info "Respaldo en ${RESPALDO}"
  $SUDO mysqldump --single-transaction --routines --triggers --events \
    --default-character-set=utf8mb4 "$DB" > "$RESPALDO"
  if [ ! -s "$RESPALDO" ] || ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
    error "El respaldo no quedó completo. No se modificó nada."
    exit 1
  fi
  # TABLA TESTIGO (SC-22): LA QUE SE MODIFICA
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # LA RESTAURACIÓN NO BORRA LO QUE EL RESPALDO NO TIENE (GV-169): PRIMERO SE
  # QUITA LO NUEVO. SIN innodb_strict_mode=0 FALLA EN articulos (GV-67)
  VOLVER_ATRAS="sudo mysql ${DB} -e \"DROP VIEW IF EXISTS v_web_libro_venta; DROP TABLE IF EXISTS libro_venta;\" && sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

  # --- 5. CAMBIOS ---
  # LAS COLUMNAS Y LA TABLA PRIMERO: LAS VISTAS LAS LEEN
  [ "$AGREGAR_COLS" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_COLS}"; ok "Agregadas las seis columnas de libros_md."; }
  [ "$CREAR_VENTA" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_VENTA}"; ok "Creada libro_venta."; }
  if [ "$MIGRAR" != "0" ]; then
    mysql_adm "$DB" -e "START TRANSACTION; ${DML_MIGRAR} ${DML_VACIAR} COMMIT;"
    ok "URL de compra pasadas a Mercado Libre."
  fi
  # v_web_libro ANTES QUE LAS QUE SE APOYAN EN ELLA
  [ "$REEMPLAZAR_LIBRO" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_LIBRO}"; ok "Reemplazada v_web_libro."; }
  [ "$REEMPLAZAR_PERSONA" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_PERSONA}"; ok "Reemplazada v_web_libro_persona."; }
  [ "$CREAR_VENTA_VISTA" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_VENTA_VISTA}"; ok "Creada v_web_libro_venta."; }

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  ULTIMAS="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND ORDINAL_POSITION > ${COLS_LIBROS_ANTES};")"
  [ "$(columnas_de libros_md)" = "$COLS_LIBROS" ] || { error "libros_md no quedó con ${COLS_LIBROS} columnas."; FALLA=1; }
  [ "$ULTIMAS" = "resumen_traducido_2,idioma_resumen_traducido_2,palabras_clave_traducidas,idioma_palabras_clave_traducidas,palabras_clave_traducidas_2,idioma_palabras_clave_traducidas_2" ] || { error "Las columnas nuevas de libros_md no quedaron al final («${ULTIMAS}»)."; FALLA=1; }
  [ "$(columnas_de libro_venta)" = "$COLS_VENTA" ] || { error "libro_venta no quedó como se esperaba."; FALLA=1; }
  [ "$(valor "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND TABLE_NAME='libro_venta' AND CONSTRAINT_NAME='fk_libro_venta_libro';")" = "CASCADE" ] || { error "libro_venta: la clave foránea no quedó en CASCADE."; FALLA=1; }
  [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND CONSTRAINT_NAME IN (${CHECK_NUEVAS});")" = "1" ] || { error "Falta la restricción CHECK de libro_venta."; FALLA=1; }
  [ "$(valor "SELECT COUNT(*) FROM libros_md AS l WHERE l.url_compra IS NOT NULL AND REGEXP_LIKE(TRIM(l.url_compra), '^https?://[^ ]+\$', 'c');")" = "0" ] || { error "Quedan url_compra sin migrar."; FALLA=1; }
  for PAR in "v_web_libro:${COLS_LIBRO}" "v_web_libro_persona:${COLS_PERSONA}" "v_web_libro_venta:${COLS_VISTA_VENTA}"; do
    V="${PAR%%:*}"; C="${PAR##*:}"
    if [ "$(tipo_de "$V")" != "VIEW" ] || [ "$(columnas_de "$V")" != "$C" ]; then
      error "La vista ${V} no quedó como se esperaba."; FALLA=1
    elif [ "$(valor "SELECT SECURITY_TYPE FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${V}';")" != "DEFINER" ]; then
      error "La vista ${V} no quedó con SQL SECURITY DEFINER."; FALLA=1
    fi
  done
  for V in v_web_coleccion v_web_libro_tapa; do
    mysql_adm "$DB" -e "SELECT COUNT(*) FROM ${V};" >/dev/null 2>&1 || { error "La vista ${V} dejó de funcionar."; FALLA=1; }
  done

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: seis columnas al final de libros_md, libro_venta, migración y tres vistas DEFINER."

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
mysql_adm "$DB" -e "SELECT (SELECT COUNT(*) FROM v_web_libro) AS libros_visibles, (SELECT COUNT(*) FROM v_web_libro WHERE resumen_traducido IS NOT NULL OR resumen_traducido_2 IS NOT NULL) AS con_resumen_traducido, (SELECT COUNT(*) FROM v_web_libro_venta) AS puntos_de_venta;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.21.0 lista.${RESET}"
echo "Siguiente paso: bash crear-cuenta-gbweb.sh (repo gbWeb, sin sudo), para el permiso sobre v_web_libro_venta."
