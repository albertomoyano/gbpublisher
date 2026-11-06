#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.22.0.sh
# Propósito : Actualización 1.22.0 de la base de gbpublisher, sobre una base
#             EN USO (decisiones de Alberto, 05/11/2026): el DESTINO de la
#             salida HTML del libro.
#               1. Al final de libros_md (SC-22), dos columnas:
#                    destino_html  ENUM('autonomo','portal'), NOT NULL,
#                                  'autonomo' por omisión: lo que hoy hace
#                                  la salida HTML. 'portal' es el HTML
#                                  integrado al portal de gbWeb
#                    url_portal    la dirección del portal (con su / final,
#                                  como gbweb.portal.url_base). De ahí el
#                                  HTML integrado descarga el marco
#                                  (cabecera, pie y estilo) y arma la vuelta
#                                  a la ficha: <url_portal>libro/<id>/
#                  Con dos CHECK: la forma de la URL, y que un libro con
#                  destino 'portal' tenga su URL. Sin catálogo de portales:
#                  el portal es estable y es una sola URL por libro.
#               2. El contrato con gbWeb (SC-81): v_web_libro suma las dos
#                  columnas al final. gbWeb avisa al construir si un libro
#                  de su portal declara otra URL.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.22.0.sh
# Requisitos: la 1.21.0 registrada.
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Qué
#             cambiar lo decide el ESTADO REAL (information_schema).
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: libros_md pasa de 86 a
#             88. VA JUNTO CON EL .deb (Y LOS FUENTES) QUE TRAEN ESE ÍNDICE
#             Y EL FORMULARIO NUEVO.
# Cuenta    : no cambia. CREATE OR REPLACE VIEW conserva el permiso de
#             gbweb_lector (GV-177).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.22.0"
PREVIO="actualizacion-1.21.0"
DESCRIPCION="Destino de la salida HTML del libro (autónomo o portal) y la URL del portal"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

COLS_LIBROS_ANTES=86
COLS_LIBROS=88
COLS_LIBRO_ANTES=32
COLS_LIBRO=34
CHECK_NUEVAS="'chk_libros_url_portal','chk_libros_destino_html'"

# UNA SOLA SENTENCIA: O ENTRA TODO O NADA. SIN AFTER (SC-22). url_portal ES
# NULL CUANDO NO HAY DATO, NUNCA '' (GV-74): EL FORMULARIO ESCRIBE NULL
DDL_COLS="ALTER TABLE libros_md
  ADD COLUMN destino_html ENUM('autonomo','portal') NOT NULL DEFAULT 'autonomo' COMMENT 'Dónde se publica la salida HTML: sitio propio o integrado al portal de gbWeb',
  ADD COLUMN url_portal VARCHAR(500) NULL DEFAULT NULL COMMENT 'Dirección del portal, con / final: de ahí sale el marco del HTML integrado',
  ADD CONSTRAINT chk_libros_url_portal CHECK (url_portal IS NULL OR REGEXP_LIKE(url_portal, '^https?://[^ ]+/\$', 'c')),
  ADD CONSTRAINT chk_libros_destino_html CHECK (destino_html = 'autonomo' OR url_portal IS NOT NULL);"

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
  l.palabras_clave_traducidas_2, l.idioma_palabras_clave_traducidas_2,
  l.destino_html, l.url_portal
FROM libros_md AS l
LEFT JOIN idiomas AS i ON i.codigo = l.idioma_principal
WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

# LA DE 1.21.0, PARA VOLVER ATRÁS: SE RESTAURA ANTES DE QUITAR LAS COLUMNAS
# (UNA VIEW QUE NOMBRA UNA COLUMNA BORRADA QUEDA ROTA, GV-169)
DDL_LIBRO_ANTERIOR="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro AS SELECT l.id_libro, l.titulo_libro, l.subtitulo, l.idioma_principal, l.isbn_impreso, l.isbn_electronico, l.numero_paginas, l.ano_publicacion, CASE LOWER(TRIM(l.mes_publicacion)) WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3 WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6 WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9 WHEN 'setiembre' THEN 9 WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12 ELSE NULL END AS mes_numero, l.fecha_publicacion_completa, l.id_coleccion, l.numero_en_coleccion, l.estado_publicacion, l.tipo_acceso, l.resumen_libro, l.palabras_clave_libro, l.url_libro, l.url_descarga_pdf, l.url_descarga_epub, l.url_compra, l.licencia_defecto AS licencia, l.url_licencia, i.nombre AS idioma_nombre, i.nombre_ingles AS idioma_nombre_ingles, l.resumen_traducido, l.idioma_resumen_traducido, l.resumen_traducido_2, l.idioma_resumen_traducido_2, l.palabras_clave_traducidas, l.idioma_palabras_clave_traducidas, l.palabras_clave_traducidas_2, l.idioma_palabras_clave_traducidas_2 FROM libros_md AS l LEFT JOIN idiomas AS i ON i.codigo = l.idioma_principal WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.22.0${RESET}"
echo "--------------------------------------------------"
echo "El destino de la salida HTML de cada libro: autónomo (como hasta"
echo "ahora) o integrado al portal, con la dirección del portal. Todos los"
echo "libros quedan como autónomos. No se borra ningún dato."
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

# LA CADENA ES ORDENADA: 1.22.0 VA SOBRE 1.21.0
if [ "$(valor "SELECT COUNT(*) FROM esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.21.0. Aplicala primero (actualizar-esquema-1.21.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL ---
# 3.1 LAS DOS COLUMNAS
AGREGAR_COLS=0
N="$(columnas_de libros_md)"
if [ "$(existe_columna libros_md destino_html)" = "1" ]; then
  [ "$N" = "$COLS_LIBROS" ] || { error "libros_md tiene destino_html pero ${N} columnas (se esperaban ${COLS_LIBROS}). Revisala a mano. No se modificó nada."; exit 1; }
elif [ "$N" = "$COLS_LIBROS_ANTES" ]; then
  AGREGAR_COLS=1
else
  error "libros_md tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

# 3.2 LA VISTA
REEMPLAZAR_LIBRO=0
case "$(columnas_de v_web_libro)" in
  "$COLS_LIBRO_ANTES") REEMPLAZAR_LIBRO=1 ;;
  "$COLS_LIBRO") ;;
  *) error "v_web_libro tiene una forma inesperada. Revisala a mano. No se modificó nada."; exit 1 ;;
esac

PENDIENTES=$(( AGREGAR_COLS + REEMPLAZAR_LIBRO ))

if [ "$PENDIENTES" -eq 0 ]; then
  ok "No hay nada que cambiar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  [ "$AGREGAR_COLS" -eq 1 ] && info "Se agregan a libros_md destino_html y url_portal, con sus dos CHECK."
  [ "$REEMPLAZAR_LIBRO" -eq 1 ] && info "Se reemplaza la vista v_web_libro (suma las dos columnas al final)."
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.22.0-$(date '+%Y%m%d-%H%M%S').sql"
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

  # VOLVER ATRÁS SIN RESTAURAR TODA LA BASE: PRIMERO LA VISTA DE 1.21.0
  # (NO NOMBRA LAS COLUMNAS NUEVAS), DESPUÉS LAS CHECK Y LAS COLUMNAS
  VOLVER_ATRAS="sudo mysql ${DB} -e \"${DDL_LIBRO_ANTERIOR} ALTER TABLE libros_md DROP CHECK chk_libros_destino_html, DROP CHECK chk_libros_url_portal, DROP COLUMN url_portal, DROP COLUMN destino_html;\""

  # --- 5. CAMBIOS ---
  # LAS COLUMNAS PRIMERO: LA VISTA LAS LEE
  [ "$AGREGAR_COLS" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_COLS}"; ok "Agregadas destino_html y url_portal a libros_md."; }
  [ "$REEMPLAZAR_LIBRO" -eq 1 ] && { mysql_adm "$DB" -e "${DDL_LIBRO}"; ok "Reemplazada v_web_libro."; }

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  ULTIMAS="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='libros_md' AND ORDINAL_POSITION > ${COLS_LIBROS_ANTES};")"
  [ "$(columnas_de libros_md)" = "$COLS_LIBROS" ] || { error "libros_md no quedó con ${COLS_LIBROS} columnas."; FALLA=1; }
  [ "$ULTIMAS" = "destino_html,url_portal" ] || { error "Las columnas nuevas de libros_md no quedaron al final («${ULTIMAS}»)."; FALLA=1; }
  [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_TYPE='CHECK' AND CONSTRAINT_NAME IN (${CHECK_NUEVAS});")" = "2" ] || { error "Faltan las restricciones CHECK nuevas."; FALLA=1; }
  [ "$(valor "SELECT COUNT(*) FROM libros_md WHERE destino_html <> 'autonomo';")" = "0" ] || { error "Hay libros con un destino distinto de autónomo: no deberían, recién creada la columna."; FALLA=1; }
  if [ "$(tipo_de v_web_libro)" != "VIEW" ] || [ "$(columnas_de v_web_libro)" != "$COLS_LIBRO" ]; then
    error "La vista v_web_libro no quedó como se esperaba."; FALLA=1
  elif [ "$(valor "SELECT SECURITY_TYPE FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='v_web_libro';")" != "DEFINER" ]; then
    error "La vista v_web_libro no quedó con SQL SECURITY DEFINER."; FALLA=1
  fi
  for V in v_web_libro_persona v_web_coleccion v_web_libro_tapa v_web_libro_venta; do
    mysql_adm "$DB" -e "SELECT COUNT(*) FROM ${V};" >/dev/null 2>&1 || { error "La vista ${V} dejó de funcionar."; FALLA=1; }
  done

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: dos columnas al final de libros_md, dos CHECK y la vista DEFINER con 34 columnas."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (respaldo en ${RESPALDO}):"
  echo "  ${VOLVER_ATRAS}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: el destino de la salida HTML"
mysql_adm "$DB" -e "SELECT destino_html AS destino, COUNT(*) AS libros, SUM(url_portal IS NOT NULL) AS con_url_portal FROM libros_md GROUP BY destino_html ORDER BY destino_html;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.22.0 lista.${RESET}"
