#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.20.0.sh
# Propósito : Actualización 1.20.0 de la base de gbpublisher, sobre una base
#             EN USO. Contrato con gbWeb (SC-81), decisión de Alberto, 04/11:
#             la ficha de cada libro en el portal muestra su licencia.
#             La VIEW v_web_libro suma dos columnas AL FINAL:
#               licencia      libros_md.licencia_defecto (la etiqueta del
#                             catálogo de licencias: «CC BY 4.0»)
#               url_licencia  libros_md.url_licencia
#             No toca ninguna tabla: los datos ya están en libros_md. Las
#             otras tres VIEW no cambian (leen v_web_libro por nombre de
#             columna).
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.20.0.sh
# Requisitos: la 1.19.0 registrada.
# Reglas    : BBDD_LEEME.md §5 y SC-22 (columnas nuevas al final).
#             IDEMPOTENTE; respaldo verificado; verificación posterior; sin
#             efecto si ya está aplicado. Qué cambiar lo decide el ESTADO
#             REAL (information_schema).
# Lote      : ninguno. m_ConexionBD.ObtenerEsquemaEsperado cuenta tablas, no
#             VIEW: el .deb no cambia.
# Cuenta    : CREATE OR REPLACE VIEW conserva el permiso SELECT de
#             gbweb_lector sobre v_web_libro (medido en 8.0.46, 04/11).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.20.0"
PREVIO="actualizacion-1.19.0"
DESCRIPCION="Contrato con gbWeb: v_web_libro suma licencia y url_licencia"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

COLS_ANTES=20
COLS_DESPUES=22

# LA VIEW DE 1.19.0 MÁS LAS DOS COLUMNAS, AL FINAL. CREATE OR REPLACE: LA
# VIEW NO SE BORRA, Y LAS QUE SE APOYAN EN ELLA SIGUEN VÁLIDAS
DDL_NUEVA="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro AS
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
  l.licencia_defecto AS licencia, l.url_licencia
FROM libros_md AS l
WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

# LA DE 1.19.0, PARA VOLVER ATRÁS SIN RESTAURAR TODA LA BASE
DDL_ANTERIOR="CREATE OR REPLACE SQL SECURITY DEFINER VIEW v_web_libro AS SELECT l.id_libro, l.titulo_libro, l.subtitulo, l.idioma_principal, l.isbn_impreso, l.isbn_electronico, l.numero_paginas, l.ano_publicacion, CASE LOWER(TRIM(l.mes_publicacion)) WHEN 'enero' THEN 1 WHEN 'febrero' THEN 2 WHEN 'marzo' THEN 3 WHEN 'abril' THEN 4 WHEN 'mayo' THEN 5 WHEN 'junio' THEN 6 WHEN 'julio' THEN 7 WHEN 'agosto' THEN 8 WHEN 'septiembre' THEN 9 WHEN 'setiembre' THEN 9 WHEN 'octubre' THEN 10 WHEN 'noviembre' THEN 11 WHEN 'diciembre' THEN 12 ELSE NULL END AS mes_numero, l.fecha_publicacion_completa, l.id_coleccion, l.numero_en_coleccion, l.estado_publicacion, l.tipo_acceso, l.resumen_libro, l.palabras_clave_libro, l.url_libro, l.url_descarga_pdf, l.url_descarga_epub, l.url_compra FROM libros_md AS l WHERE l.estado_publicacion IN ('publicado', 'agotado', 'descatalogado');"

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

tipo_de() {
  valor "SELECT TABLE_TYPE FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.20.0${RESET}"
echo "--------------------------------------------------"
echo "La vista v_web_libro, que lee gbWeb, suma la licencia de cada libro."
echo "No modifica ninguna tabla ni ningún dato."
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

# LA CADENA ES ORDENADA: 1.20.0 VA SOBRE 1.19.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.19.0. Aplicala primero (actualizar-esquema-1.19.0.sh)."
  exit 1
fi

# LAS COLUMNAS QUE LEE LA VIEW TIENEN QUE ESTAR EN libros_md
for C in licencia_defecto url_licencia; do
  if [ "$(existe_columna libros_md "$C")" != "1" ]; then
    error "libros_md no tiene la columna ${C}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
if [ "$(tipo_de v_web_libro)" != "VIEW" ]; then
  error "No existe la vista v_web_libro (1.19.0). No se modificó nada."
  exit 1
fi
N="$(columnas_de v_web_libro)"
REEMPLAZAR=0
if [ "$N" = "$COLS_ANTES" ]; then
  REEMPLAZAR=1
elif [ "$N" = "$COLS_DESPUES" ] && [ "$(existe_columna v_web_libro licencia)" = "1" ] && [ "$(existe_columna v_web_libro url_licencia)" = "1" ]; then
  :
else
  error "v_web_libro tiene una forma inesperada (${N} columnas). Revisala a mano. No se modificó nada."
  exit 1
fi

if [ "$REEMPLAZAR" -eq 0 ]; then
  ok "v_web_libro ya tiene la licencia. No hay nada que cambiar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Se agregan a v_web_libro: licencia y url_licencia."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. RESPALDO PREVIO VERIFICADO ---
  # LA REGLA DE TODOS LOS SCRIPTS DE ESQUEMA, AUNQUE ESTE NO TOQUE DATOS
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.20.0-$(date '+%Y%m%d-%H%M%S').sql"
  info "Respaldo en ${RESPALDO}"
  $SUDO mysqldump --single-transaction --routines --triggers --events \
    --default-character-set=utf8mb4 "$DB" > "$RESPALDO"
  if [ ! -s "$RESPALDO" ] || ! tail -n 1 "$RESPALDO" | grep -q "Dump completed"; then
    error "El respaldo no quedó completo. No se modificó nada."
    exit 1
  fi
  # TABLA TESTIGO (SC-22): LA QUE LEE LA VIEW
  if ! grep -q "CREATE TABLE \`libros_md\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla libros_md. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # VOLVER ATRÁS ES REPONER LA VIEW DE 1.19.0: NINGUNA TABLA CAMBIÓ
  VOLVER_ATRAS="sudo mysql ${DB} -e \"${DDL_ANTERIOR}\""

  # --- 5. CAMBIO ---
  mysql_adm "$DB" -e "${DDL_NUEVA}"
  ok "Reemplazada la vista v_web_libro."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  ORDEN_FIN="$(valor "SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='v_web_libro' AND ORDINAL_POSITION > ${COLS_ANTES};")"
  [ "$(columnas_de v_web_libro)" = "$COLS_DESPUES" ] || { error "v_web_libro no quedó con ${COLS_DESPUES} columnas."; FALLA=1; }
  [ "$ORDEN_FIN" = "licencia,url_licencia" ] || { error "Las columnas nuevas no quedaron al final («${ORDEN_FIN}»)."; FALLA=1; }
  [ "$(valor "SELECT SECURITY_TYPE FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='v_web_libro';")" = "DEFINER" ] || { error "v_web_libro no quedó con SQL SECURITY DEFINER."; FALLA=1; }
  # LAS QUE SE APOYAN EN ELLA SIGUEN FUNCIONANDO
  for V in v_web_libro_persona v_web_coleccion v_web_libro_tapa; do
    if ! mysql_adm "$DB" -e "SELECT COUNT(*) FROM ${V};" >/dev/null 2>&1; then
      error "La vista ${V} dejó de funcionar."
      FALLA=1
    fi
  done

  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    error "Para volver atrás: ${VOLVER_ATRAS}"
    exit 1
  fi
  ok "Verificación correcta: licencia y url_licencia al final de v_web_libro; las otras vistas funcionan."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."

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
mysql_adm "$DB" -e "SELECT (SELECT COUNT(*) FROM v_web_libro) AS libros_visibles, (SELECT COUNT(*) FROM v_web_libro WHERE licencia IS NOT NULL) AS con_licencia;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.20.0 lista.${RESET}"
