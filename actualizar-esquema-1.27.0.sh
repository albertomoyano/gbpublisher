#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.27.0.sh
# Propósito : Actualización 1.27.0 de la base de gbpublisher, sobre una base
#             EN USO. Cierra la mudanza de los datos de editorial de la
#             revista a la tabla editorial (decisión de Alberto del
#             12/11/2026: dos esquemas; claude/salidas-revistas.md, «B»):
#               1. borra de revista las nueve columnas que pasaron a la
#                  editorial en la 1.26.0:
#                    editorial, institucion_editora, ror_editorial, ciudad,
#                    pais, doi_prefix, licencia_defecto,
#                    url_licencia_defecto, titular_copyright_defecto
#               2. revista.id_editorial pasa a NOT NULL: toda revista tiene
#                  su editorial
#               3. revista.email_editorial queda, con su comentario nuevo:
#                  es el correo propio de la revista; vacío, vale el de la
#                  editorial
#             Desde las entregas B2 a B5 ningún código lee ni escribe esas
#             columnas (verificado en .src y en .hidden): sus valores son
#             la copia que hizo la 1.26.0, y la editorial es la fuente.
#             Antes de borrar, el script MUESTRA las revistas cuyos valores
#             viejos difieren de los de su editorial (por ejemplo, porque la
#             editorial se corrigió después): lo que se pierde se ve antes
#             de confirmar, y queda en el respaldo.
# Uso       : sudo bash actualizar-esquema-1.27.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.26.0 registrada. Qué cambiar lo decide el ESTADO
#             REAL.
# Lote      : m_ConexionBD.ObtenerEsquemaEsperado: revista pasa de 25 a 16
#             columnas. Va en la misma entrega (entregaB6).
# Volver    : escribe junto al respaldo un .sql que repone las columnas y
#             las llena desde la editorial (ver el apartado 8).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.27.0"
PREVIO="actualizacion-1.26.0"
DESCRIPCION="Borra de revista los datos de editorial (ya en editorial) y exige la editorial"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"

# LAS COLUMNAS QUE SE VAN Y LA DE editorial QUE LAS REEMPLAZA (MISMO ORDEN)
COLUMNAS=(editorial institucion_editora ror_editorial ciudad pais doi_prefix licencia_defecto url_licencia_defecto titular_copyright_defecto)
EN_EDITORIAL=(nombre institucion ror ciudad pais doi_prefix licencia_defecto url_licencia_defecto titular_copyright_defecto)

# LAS COLUMNAS DE revista DESPUÉS DE LA ACTUALIZACIÓN (ObtenerEsquemaEsperado)
COLUMNAS_FINALES=16

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

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.27.0${RESET}"
echo "--------------------------------------------------"
echo "Borra de la revista los datos que en la 1.26.0 pasaron a la editorial"
echo "y hace obligatoria la editorial de cada revista."
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

# LA CADENA ES ORDENADA: 1.27.0 VA SOBRE 1.26.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.26.0. Aplicala primero (actualizar-esquema-1.26.0.sh)."
  exit 1
fi

for t in revista editorial; do
  if [ "$(existe_tabla "$t")" != "1" ]; then
    error "No existe la tabla ${t}. No se modificó nada."
    exit 1
  fi
done

# --- 3. ESTADO REAL ---
QUEDAN=()
for c in "${COLUMNAS[@]}"; do
  [ "$(existe_columna revista "$c")" = "1" ] && QUEDAN+=("$c")
done
NULABLE="$(valor "SELECT IS_NULLABLE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='revista' AND COLUMN_NAME='id_editorial';")"
if [ -z "$NULABLE" ]; then
  error "revista no tiene la columna id_editorial: la 1.26.0 no quedó completa. No se modificó nada."
  exit 1
fi

if [ ${#QUEDAN[@]} -eq 0 ] && [ "$NULABLE" = "NO" ]; then
  ok "Las columnas viejas ya no están y la editorial ya es obligatoria."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
fi

if [ "$SOLO_INFORME" -eq 0 ]; then

  # --- 4. FRENOS: LO QUE IMPIDE APLICAR SIN DECIDIR ANTES ---
  # UNA REVISTA SIN EDITORIAL NO PUEDE PASAR A NOT NULL. SE ASIGNA EN
  # Administración, PESTAÑA «Editorial»; LA 1.26.0 LAS VINCULÓ A TODAS, ASÍ
  # QUE UNA SIN EDITORIAL ES UNA DADA DE ALTA FUERA DE LA APLICACIÓN
  SIN_EDITORIAL="$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista WHERE id_editorial IS NULL;")"
  if [ "$SIN_EDITORIAL" != "0" ]; then
    error "Hay revistas sin editorial: no se puede hacer obligatoria. No se modificó nada."
    mysql_adm "$DB" -e "SELECT id_revista, titulo FROM revista WHERE id_editorial IS NULL ORDER BY id_revista;"
    exit 1
  fi
  # UNA VISTA QUE NOMBRA LA TABLA revista PUEDE USAR UNA COLUMNA QUE SE VA:
  # MySQL BORRARÍA LA COLUMNA Y LA VISTA QUEDARÍA ROTA SIN AVISO
  VISTAS="$(valor "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}' AND VIEW_DEFINITION LIKE '%\`revista\`%';")"
  if [ -n "$VISTAS" ]; then
    error "Hay vistas que leen la tabla revista; revisalas antes de borrar columnas. No se modificó nada:"
    echo "$VISTAS" | sed 's/^/    /'
    exit 1
  fi

  # --- 5. LO QUE SE PIERDE: VALORES VIEJOS QUE NO SON LOS DE LA EDITORIAL ---
  # SOLO SE MUESTRA: LA EDITORIAL ES LA FUENTE DESDE B2 Y LO VIEJO QUEDA EN EL
  # RESPALDO. UN VALOR VIEJO NULO NO SE PIERDE
  if [ ${#QUEDAN[@]} -gt 0 ]; then
    CONDICION=""
    for i in "${!COLUMNAS[@]}"; do
      c="${COLUMNAS[$i]}"
      [ "$(existe_columna revista "$c")" = "1" ] || continue
      [ -n "$CONDICION" ] && CONDICION+=" OR "
      CONDICION+="(r.\`${c}\` IS NOT NULL AND NOT (r.\`${c}\` <=> e.\`${EN_EDITORIAL[$i]}\`))"
    done
    DIFIEREN="$(valor "SELECT COUNT(*) FROM \`${DB}\`.revista r JOIN \`${DB}\`.editorial e ON e.id_editorial = r.id_editorial WHERE ${CONDICION};")"
    if [ "$DIFIEREN" != "0" ]; then
      warn "${DIFIEREN} revista(s) tienen en las columnas viejas valores distintos de los"
      warn "de su editorial. Al borrar se pierden (quedan en el respaldo); vale lo de"
      warn "la editorial. Las filas:"
      for i in "${!COLUMNAS[@]}"; do
        c="${COLUMNAS[$i]}"
        [ "$(existe_columna revista "$c")" = "1" ] || continue
        mysql_adm "$DB" -e "SELECT r.id_revista, r.titulo, '${c}' AS dato, r.\`${c}\` AS en_la_revista, e.\`${EN_EDITORIAL[$i]}\` AS en_la_editorial
          FROM revista r JOIN editorial e ON e.id_editorial = r.id_editorial
          WHERE r.\`${c}\` IS NOT NULL AND NOT (r.\`${c}\` <=> e.\`${EN_EDITORIAL[$i]}\`) ORDER BY r.id_revista;"
      done
      echo
    else
      ok "Los valores viejos coinciden con los de cada editorial (o están vacíos): no se pierde nada."
    fi
    info "Columnas a borrar: ${QUEDAN[*]}"
  fi
  [ "$NULABLE" = "YES" ] && info "revista.id_editorial pasa a obligatoria."
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 6. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.27.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`revista\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla revista. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 7. ESTRUCTURA: UN SOLO ALTER (EN MySQL 8 EL DDL ES ATÓMICO) ---
  ALTER="ALTER TABLE revista"
  SEP=" "
  for c in "${QUEDAN[@]}"; do
    ALTER+="${SEP}DROP COLUMN \`${c}\`"
    SEP=", "
  done
  ALTER+="${SEP}MODIFY COLUMN id_editorial INT NOT NULL COMMENT 'La editorial de la revista (1.26.0; obligatoria desde la 1.27.0)'"
  ALTER+=", MODIFY COLUMN email_editorial VARCHAR(200) NULL DEFAULT NULL COMMENT 'Correo propio de la revista; vacío, vale el de la editorial (1.26.0)'"
  mysql_adm "$DB" -e "${ALTER};"
  ok "revista: ${#QUEDAN[@]} columna(s) borrada(s); id_editorial obligatoria."

  # --- 8. VOLVER ATRÁS ---
  # REPONE LAS COLUMNAS CON SUS TIPOS DE LA 1.13.0, EN SU LUGAR, Y LAS LLENA
  # DESDE LA EDITORIAL DE CADA REVISTA: QUEDA COMO DESPUÉS DE LA 1.26.0 (CON
  # LOS DATOS DE HOY DE LA EDITORIAL). LO VIEJO DISTINTO, SI LO HABÍA, ESTÁ
  # EN EL RESPALDO
  VOLVER="${RESPALDO%.sql}-volver-atras.sql"
  cat > "$VOLVER" <<'SQL'
-- VOLVER ATRÁS LA 1.27.0 DE gbpublisher: sudo mysql gbpublisher < ESTE_ARCHIVO
ALTER TABLE revista
  ADD COLUMN editorial VARCHAR(300) NULL DEFAULT NULL COMMENT 'JATS publisher-name' AFTER issn_electronico,
  ADD COLUMN institucion_editora VARCHAR(300) NULL DEFAULT NULL AFTER editorial,
  ADD COLUMN ror_editorial VARCHAR(50) NULL DEFAULT NULL AFTER institucion_editora,
  ADD COLUMN ciudad VARCHAR(200) NULL DEFAULT NULL COMMENT 'JATS publisher-loc' AFTER ror_editorial,
  ADD COLUMN pais VARCHAR(100) NULL DEFAULT NULL AFTER ciudad,
  ADD COLUMN doi_prefix VARCHAR(50) NULL DEFAULT NULL AFTER email_editorial,
  ADD COLUMN licencia_defecto VARCHAR(100) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar' AFTER idiomas_publicacion,
  ADD COLUMN url_licencia_defecto VARCHAR(500) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar' AFTER licencia_defecto,
  ADD COLUMN titular_copyright_defecto VARCHAR(300) NULL DEFAULT NULL COMMENT 'Se hereda hasta publicar' AFTER url_licencia_defecto,
  MODIFY COLUMN id_editorial INT NULL DEFAULT NULL COMMENT 'La editorial de la revista (1.26.0)';
UPDATE revista r JOIN editorial e ON e.id_editorial = r.id_editorial
  SET r.editorial = e.nombre, r.institucion_editora = e.institucion, r.ror_editorial = e.ror,
      r.ciudad = e.ciudad, r.pais = e.pais, r.doi_prefix = e.doi_prefix,
      r.licencia_defecto = e.licencia_defecto, r.url_licencia_defecto = e.url_licencia_defecto,
      r.titular_copyright_defecto = e.titular_copyright_defecto;
DELETE FROM esquema_version WHERE parche = 'actualizacion-1.27.0';
SQL
  ok "Para volver atrás: ${VOLVER}"

  # --- 9. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for c in "${COLUMNAS[@]}"; do
    if [ "$(existe_columna revista "$c")" = "1" ]; then
      error "La columna revista.${c} sigue estando."
      FALLA=1
    fi
  done
  if [ "$(valor "SELECT IS_NULLABLE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='revista' AND COLUMN_NAME='id_editorial';")" != "NO" ]; then
    error "revista.id_editorial sigue admitiendo nulos."
    FALLA=1
  fi
  if [ "$(existe_columna revista email_editorial)" != "1" ]; then
    error "Falta revista.email_editorial."
    FALLA=1
  fi
  CANTIDAD="$(valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='revista';")"
  if [ "$CANTIDAD" != "$COLUMNAS_FINALES" ]; then
    error "revista tiene ${CANTIDAD} columnas y se esperaban ${COLUMNAS_FINALES}."
    FALLA=1
  fi
  if [ "$FALLA" = "1" ]; then
    error "NO se registra la actualización. Para volver atrás:"
    error "  sudo mysql ${DB} < ${VOLVER}"
    exit 1
  fi
  ok "Verificación correcta: revista con ${COLUMNAS_FINALES} columnas y la editorial obligatoria."

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
info "Informe de control: cada revista y su editorial"
mysql_adm "$DB" -e "SELECT r.id_revista, r.titulo, e.nombre AS editorial, e.doi_prefix, e.licencia_defecto,
  COALESCE(r.email_editorial, e.email) AS correo
  FROM revista r JOIN editorial e ON e.id_editorial = r.id_editorial ORDER BY e.nombre, r.titulo;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.27.0 lista.${RESET}"
