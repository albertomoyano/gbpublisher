#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.9.0.sh
# Propósito : Actualización 1.9.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos editoriales. Convierte
#             libros_md.estilo_cita del nombre de un archivo .csl al
#             identificador del estilo biblatex: el selector de libros ya no
#             lista archivos .csl sino las configuraciones
#             ~/.gbpublisher/latex/cita-<estilo>-config.tex (SC-57).
#             SOLO DATOS: no cambia el esquema. revistas_md NO SE TOCA: las
#             revistas siguen con .csl.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.9.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.8.0 registrada: la cadena es ordenada.
# Criterio  : por cada libro, cuatro estados posibles:
#               - NULL o vacío                      -> no se toca
#               - un identificador conocido         -> ya está, no se toca
#               - un .csl conocido (con o sin ruta,
#                 en cualquier caja, como lo leía
#                 LeerTipoCSL)                      -> se convierte
#               - cualquier otro valor              -> ABORTA sin modificar
#                                                      nada y lista las filas
#             Un valor desconocido no se adivina: lo corrige el editor en la
#             ficha del libro o a mano, y se vuelve a correr.
# Lote      : selector de estilos de libro (FMetadatosLibro, m_Metadatos,
#             m_GenerarSalidasLibro, m_GenerarPDFLibro). La aplicación nueva
#             con la base vieja cae en apa para HTML y EPUB y frena el PDF con
#             «Estilo de cita no reconocido»: aplicar este script junto con el
#             lote.
# Cadena    : 1.9.0 es este cambio; el refactor de bibtex pasa a 1.10.0.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.9.0"
DESCRIPCION="libros_md.estilo_cita: del archivo .csl al identificador del estilo biblatex"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="libros_md"

# LOS IDENTIFICADORES VÁLIDOS: LOS cita-<estilo>-config.tex DE .hidden/latex/.
# EL SCRIPT CORRE CON sudo Y NO PUEDE CONFIAR EN EL ~ DEL USUARIO: LA LISTA
# VA FIJA. UN ESTILO NUEVO NO NECESITA SCRIPT: NACE CON SU IDENTIFICADOR
IDS="'apa','ieee','iso690','vancouver','verona-modern'"

# CONVERSIÓN: LA MISMA TABLA QUE m_InicioCierre.LeerTipoCSL
CSL_VIEJOS=("apa.csl" "ieee.csl" "vancouver.csl" "iso690-author-date-es.csl")
IDS_NUEVOS=("apa"     "ieee"     "vancouver"     "iso690")

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

# EL NOMBRE DE ARCHIVO, EN MINÚSCULAS, COMO LO LEÍA LeerTipoCSL
# (Lower(File.Name(...))): UNA RUTA COMPLETA O «APA.csl» TAMBIÉN SE CONVIERTEN.
# BINARY: LA COMPARACIÓN DE LOS IDENTIFICADORES ES EXACTA, SIN LA COLACIÓN
BASE_CSL="LOWER(SUBSTRING_INDEX(TRIM(estilo_cita), '/', -1))"

# LA LISTA DE LOS .csl CONOCIDOS, PARA SQL
CSL_SQL=""
for c in "${CSL_VIEJOS[@]}"; do CSL_SQL+="${CSL_SQL:+,}'${c}'"; done

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.9.0${RESET}"
echo "-------------------------------------------------"
echo "Convierte el estilo de cita de los libros del archivo .csl al estilo biblatex."
echo "No cambia el esquema ni toca revistas ni datos editoriales."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}' AND COLUMN_NAME='estilo_cita';")" != "1" ]; then
  error "No existe la columna ${TABLA}.estilo_cita."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.9.0 VA SOBRE 1.8.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.8.0';")" != "1" ]; then
  error "Falta la actualización 1.8.0. Aplicala primero (actualizar-esquema-1.8.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DE CADA LIBRO ---
# LOS DESCONOCIDOS: NI VACÍOS, NI IDENTIFICADORES, NI .csl CONOCIDOS
DESCONOCIDOS="$(valor "SELECT CONCAT('    - id_libro ', id_libro, ': «', estilo_cita, '»')
  FROM \`${DB}\`.\`${TABLA}\`
  WHERE estilo_cita IS NOT NULL AND TRIM(estilo_cita) <> ''
    AND BINARY estilo_cita NOT IN (${IDS})
    AND ${BASE_CSL} NOT IN (${CSL_SQL})
  ORDER BY id_libro;")"

if [ -n "$DESCONOCIDOS" ]; then
  # VALOR DESCONOCIDO: NO SE ADIVINA NI SE PISA
  error "Hay libros con un estilo de cita que este script no conoce:"
  echo "$DESCONOCIDOS" >&2
  error "Se esperaba vacío, ${IDS//\'/} o uno de: ${CSL_VIEJOS[*]}."
  error "Corregí esos libros (ficha del libro o a mano) y volvé a correr el script. No se modificó nada."
  exit 1
fi

PENDIENTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.\`${TABLA}\`
  WHERE estilo_cita IS NOT NULL AND BINARY estilo_cita NOT IN (${IDS})
    AND ${BASE_CSL} IN (${CSL_SQL});")"

if [ "$PENDIENTES" -eq 0 ]; then
  ok "No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente (${PENDIENTES} libros):"
  valor "SELECT CONCAT('    - id_libro ', id_libro, ': «', estilo_cita, '»') FROM \`${DB}\`.\`${TABLA}\`
    WHERE estilo_cita IS NOT NULL AND BINARY estilo_cita NOT IN (${IDS})
      AND ${BASE_CSL} IN (${CSL_SQL}) ORDER BY id_libro;"
  echo "  Conversión:"
  for i in "${!CSL_VIEJOS[@]}"; do
    echo "    ${CSL_VIEJOS[$i]}  ->  ${IDS_NUEVOS[$i]}"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.9.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # LA TABLA TESTIGO ES LA QUE SE MODIFICA
  if ! grep -q "CREATE TABLE \`${TABLA}\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla ${TABLA}. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  # --- 5. APLICACIÓN ---
  # UNA SOLA TRANSACCIÓN: O SE CONVIERTEN TODOS O NINGUNO. CADA UPDATE
  # REPITE LA CONDICIÓN DEL PUNTO 3: UN LIBRO QUE CAMBIÓ ENTRE TANTO NO SE
  # TOCA Y LA VERIFICACIÓN POSTERIOR LO DETECTA
  SQL="START TRANSACTION;"
  for i in "${!CSL_VIEJOS[@]}"; do
    SQL+="
UPDATE \`${TABLA}\`
   SET estilo_cita='${IDS_NUEVOS[$i]}'
 WHERE estilo_cita IS NOT NULL AND BINARY estilo_cita NOT IN (${IDS})
   AND ${BASE_CSL}='${CSL_VIEJOS[$i]}';"
  done
  SQL+="
COMMIT;"
  mysql_adm "$DB" -e "$SQL"
  ok "Estilos convertidos."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  # EL ESTADO FINAL COMPLETO ES EL CONTRATO: TODO LIBRO, VACÍO O CON UN
  # IDENTIFICADOR VÁLIDO
  RESTO="$(valor "SELECT COUNT(*) FROM \`${DB}\`.\`${TABLA}\`
    WHERE estilo_cita IS NOT NULL AND TRIM(estilo_cita) <> ''
      AND BINARY estilo_cita NOT IN (${IDS});")"
  if [ "$RESTO" -ne 0 ]; then
    error "Quedaron ${RESTO} libros sin un identificador válido."
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: todos los libros tienen un identificador válido o ninguno."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA (O NO HABÍA LIBROS CON .csl): SE REGISTRA PARA QUE EL NIVEL
  # DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "No había nada que convertir; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: estilos de cita de los libros"
mysql_adm "$DB" -e "SELECT IFNULL(NULLIF(TRIM(estilo_cita), ''), '(sin estilo)') AS estilo_cita, COUNT(*) AS libros FROM \`${TABLA}\` GROUP BY 1 ORDER BY 1;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.9.0 lista.${RESET}"
