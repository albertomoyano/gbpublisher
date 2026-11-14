#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.29.0.sh
# Propósito : Actualización 1.29.0 de la base de gbpublisher, sobre una base
#             EN USO. Congela al publicar los textos que el canónico toma del
#             catálogo (decisión de Alberto del 14/11/2026, C2d: la
#             reproducibilidad manda; claude/salidas-revistas.md):
#               1. articulo.licencia_texto: el texto de la licencia en el
#                  idioma del artículo, tal como estaba al publicarlo
#               2. contribuyente_credit.nombre_rol y uri_rol: el nombre del
#                  rol en el idioma del artículo y su URI, tal como estaban
#                  al publicarlo
#             Un artículo no publicado los toma del catálogo (credit_rol_nombre,
#             licencia_texto, credit_roles.uri) en cada volcado; uno
#             publicado, de estas columnas. PublicarArticulo las escribe.
#             LOS YA PUBLICADOS se congelan acá con el catálogo de hoy, con
#             la misma regla que m_CreditRoles.NombreRol y
#             m_Licencias.TextoLicencia: el idioma exacto, después su
#             subetiqueta primaria; sin nombre, el término en inglés; sin
#             texto, NULL (el canónico lleva solo la etiqueta).
# Uso       : sudo bash actualizar-esquema-1.29.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.28.0 registrada.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: articulo 31 → 32,
#             contribuyente_credit 2 → 4. Va en la misma entrega (entregaC2d).
# Volver    : escribe junto al respaldo un .sql que borra las tres columnas.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.29.0"
PREVIO="actualizacion-1.28.0"
DESCRIPCION="Congela al publicar el texto de la licencia y los nombres CRediT"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS COLUMNAS DESPUÉS DE LA ACTUALIZACIÓN (ObtenerEsquemaEsperado)
COLS_ARTICULO=32
COLS_CREDIT=4

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

existe_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

existe_columna() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1' AND COLUMN_NAME='$2';"
}

columnas_tabla() {
  valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='$1';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.29.0${RESET}"
echo "--------------------------------------------------"
echo "Congela, en cada artículo publicado, el texto de su licencia y los"
echo "nombres de los roles CRediT en su idioma."
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

if [ "$(existe_tabla esquema_version)" != "1" ]; then
  error "La base no tiene la tabla esquema_version: no parece instalada desde un baseline."
  exit 1
fi

# LA CADENA ES ORDENADA: 1.29.0 VA SOBRE 1.28.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.28.0. Aplicala primero (actualizar-esquema-1.28.0.sh)."
  exit 1
fi

for t in articulo contribuyente_credit credit_roles credit_rol_nombre licencia_texto; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
FALTA_TEXTO=0;   [ "$(existe_columna articulo licencia_texto)" = "1" ]         || FALTA_TEXTO=1
FALTA_NOMBRE=0;  [ "$(existe_columna contribuyente_credit nombre_rol)" = "1" ] || FALTA_NOMBRE=1
FALTA_URI=0;     [ "$(existe_columna contribuyente_credit uri_rol)" = "1" ]    || FALTA_URI=1

if [ $((FALTA_TEXTO + FALTA_NOMBRE + FALTA_URI)) -eq 0 ]; then
  ok "Las tres columnas ya están."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. LO QUE SE VA A HACER ---
  PUBLICADOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo WHERE estado = 'publicado';")"
  [ "$FALTA_TEXTO" -eq 1 ]  && info "articulo: columna licencia_texto."
  [ "$FALTA_NOMBRE" -eq 1 ] && info "contribuyente_credit: columna nombre_rol."
  [ "$FALTA_URI" -eq 1 ]    && info "contribuyente_credit: columna uri_rol."
  info "Se congelan los ${PUBLICADOS} artículo(s) publicados con el catálogo de hoy."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.29.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  for t in articulo contribuyente_credit; do
    if ! grep -q "CREATE TABLE \`${t}\`" "$RESPALDO"; then
      error "El respaldo no contiene la tabla ${t}. No se modificó nada."
      exit 1
    fi
  done
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 6. ESTRUCTURA ---
  # 6.1 EL TEXTO, JUNTO A LA LICENCIA Y SU URL QUE YA SE CONGELAN
  if [ "$FALTA_TEXTO" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE articulo ADD COLUMN licencia_texto TEXT COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'Texto de la licencia en el idioma del artículo, congelado al publicar; NULL: solo la etiqueta (1.29.0)' AFTER url_licencia;"
    ok "articulo.licencia_texto creada."
  fi
  # 6.2 EL NOMBRE Y LA URI DEL ROL. NULL EN UN NO PUBLICADO: EL VOLCADO VA AL
  # CATÁLOGO. EN UN PUBLICADO, uri_rol NULL ES UN ROL QUE NO ES DE CRediT
  if [ "$FALTA_NOMBRE" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE contribuyente_credit ADD COLUMN nombre_rol VARCHAR(100) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'Nombre del rol en el idioma del artículo, congelado al publicar (1.29.0)';"
    ok "contribuyente_credit.nombre_rol creada."
  fi
  if [ "$FALTA_URI" -eq 1 ]; then
    mysql_adm "$DB" -e "ALTER TABLE contribuyente_credit ADD COLUMN uri_rol VARCHAR(200) COLLATE utf8mb4_unicode_ci NULL DEFAULT NULL COMMENT 'URI del rol en credit.niso.org, congelada al publicar (1.29.0)';"
    ok "contribuyente_credit.uri_rol creada."
  fi

  # --- 7. LOS PUBLICADOS, CONGELADOS CON EL CATÁLOGO DE HOY ---
  # LA REGLA DE m_Licencias.TextoLicencia Y m_CreditRoles.NombreRol: EL IDIOMA
  # EXACTO, DESPUÉS SU SUBETIQUETA PRIMARIA (pt-BR → pt). SOLO DONDE TODAVÍA
  # NO HAY NADA: UNA SEGUNDA CORRIDA NO PISA
  mysql_adm "$DB" <<'SQL'
UPDATE articulo a
SET a.licencia_texto = COALESCE(
  (SELECT t.texto FROM licencia_texto t WHERE t.url = a.url_licencia AND t.idioma = a.idioma_principal),
  (SELECT t.texto FROM licencia_texto t WHERE t.url = a.url_licencia AND t.idioma = SUBSTRING_INDEX(a.idioma_principal, '-', 1)))
WHERE a.estado = 'publicado' AND a.licencia_texto IS NULL AND a.url_licencia IS NOT NULL;
SQL
  ok "Texto de la licencia congelado en los publicados que tienen uno en su idioma."
  mysql_adm "$DB" <<'SQL'
UPDATE contribuyente_credit cc
JOIN articulo_contribuyente ac ON ac.id_contribuyente = cc.id_contribuyente
JOIN articulo a ON a.id_articulo = ac.id_articulo
LEFT JOIN credit_roles r ON r.nombre = cc.rol_credit
SET cc.uri_rol = r.uri,
    cc.nombre_rol = COALESCE(
      (SELECT n.nombre FROM credit_rol_nombre n WHERE n.id_rol = r.id AND n.idioma = a.idioma_principal),
      (SELECT n.nombre FROM credit_rol_nombre n WHERE n.id_rol = r.id AND n.idioma = SUBSTRING_INDEX(a.idioma_principal, '-', 1)),
      cc.rol_credit)
WHERE a.estado = 'publicado' AND cc.nombre_rol IS NULL;
SQL
  ok "Nombres y URI de los roles congelados en los publicados."

  # --- 8. VOLVER ATRÁS ---
  VOLVER="${RESPALDO%.sql}-volver-atras.sql"
  cat > "$VOLVER" <<'SQL'
-- VOLVER ATRÁS LA 1.29.0 DE gbpublisher: sudo mysql gbpublisher < ESTE_ARCHIVO
ALTER TABLE articulo DROP COLUMN licencia_texto;
ALTER TABLE contribuyente_credit DROP COLUMN nombre_rol, DROP COLUMN uri_rol;
DELETE FROM esquema_version WHERE parche = 'actualizacion-1.29.0';
SQL
  ok "Para volver atrás: ${VOLVER}"

  # --- 9. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for par in "articulo:${COLS_ARTICULO}" "contribuyente_credit:${COLS_CREDIT}"; do
    t="${par%%:*}"; n="${par##*:}"
    CANTIDAD="$(columnas_tabla "$t")"
    if [ "$CANTIDAD" != "$n" ]; then
      error "${t} tiene ${CANTIDAD} columnas y se esperaban ${n}."
      FALLA=1
    fi
  done
  # TODO ROL DE UN PUBLICADO QUEDA CON NOMBRE (AL MENOS EL TÉRMINO)
  SIN_NOMBRE="$(valor "SELECT COUNT(*) FROM \`${DB}\`.contribuyente_credit cc JOIN \`${DB}\`.articulo_contribuyente ac ON ac.id_contribuyente = cc.id_contribuyente JOIN \`${DB}\`.articulo a ON a.id_articulo = ac.id_articulo WHERE a.estado = 'publicado' AND cc.nombre_rol IS NULL;")"
  if [ "$SIN_NOMBRE" != "0" ]; then
    error "${SIN_NOMBRE} rol(es) de artículos publicados quedaron sin nombre."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  sudo mysql ${DB} < ${VOLVER}"
    exit 1
  fi
  ok "Verificación correcta: columnas creadas y publicados congelados."

  # --- 10. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás (respaldo en ${RESPALDO}):"
  echo "  sudo mysql ${DB} < ${VOLVER}"

else
  # YA ESTABA: SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Ya estaba aplicada; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 11. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: los artículos publicados y lo congelado"
mysql_adm "$DB" -e "SELECT a.id_articulo, a.idioma_principal AS idioma, a.licencia,
  IF(a.licencia_texto IS NULL, '(solo la etiqueta)', LEFT(a.licencia_texto, 40)) AS texto,
  (SELECT COUNT(*) FROM contribuyente_credit cc JOIN articulo_contribuyente ac ON ac.id_contribuyente = cc.id_contribuyente WHERE ac.id_articulo = a.id_articulo) AS roles,
  (SELECT COUNT(*) FROM contribuyente_credit cc JOIN articulo_contribuyente ac ON ac.id_contribuyente = cc.id_contribuyente WHERE ac.id_articulo = a.id_articulo AND cc.nombre_rol <> cc.rol_credit) AS roles_traducidos
  FROM articulo a WHERE a.estado = 'publicado' ORDER BY a.id_articulo;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.29.0 lista.${RESET}"
