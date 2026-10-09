#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.8.0.sh
# Propósito : Actualización 1.8.0 de la base de gbpublisher, sobre una base
#             EN USO y preservando sus datos editoriales. Corrige los valores
#             de los formatos de sistema «Estudio 2A / 01…05» de formatos_pdf
#             para que coincidan con los que usa el estudio: un libro que se
#             compone en otra máquina tiene que salir con la misma caja.
#             SOLO DATOS: no cambia el esquema.
#             Al final emite un INFORME DE CONTROL, solo de lectura.
# Uso       : sudo bash actualizar-esquema-1.8.0.sh
# Requisitos: MySQL/MariaDB en ejecución; permisos sudo.
# Reglas    : BBDD_LEEME.md §5. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado.
#             Exige la 1.7.0 registrada: la cadena es ordenada. Sobre esa
#             base, qué corregir lo decide el ESTADO REAL de cada fila.
# Criterio  : por cada formato, tres estados posibles:
#               - valores del baseline 1.0.0  -> se actualiza
#               - valores nuevos              -> ya está, no se toca
#               - cualquier otro valor        -> ABORTA sin modificar nada
#             El formulario no permite editar los formatos de origen
#             'sistema'; un valor distinto es una intervención manual que
#             este script no debe pisar.
# Lote      : sin cambios en la aplicación. El baseline 1.0.0 conserva los
#             valores viejos; una instalación nueva los corrige con esta
#             cadena.
# Cadena    : la 1.8.0 la toma este arreglo; el refactor de bibtex tomará
#             el número que le corresponda (corrige lo anunciado en 1.7.0).
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.8.0"
DESCRIPCION="Valores reales de los formatos de sistema Estudio 2A en formatos_pdf"
DIR_RESPALDO="${HOME}/gbpublisher-respaldos"
TABLA="formatos_pdf"
CLASIFICACION="Editorial"

# FORMATO DE CADA VALOR: ancho|alto|interior|exterior|superior|inferior,
# CON DOS DECIMALES Y PUNTO, COMO LOS DEVUELVE MySQL PARA decimal(5,2)
NOMBRES=(
  "Estudio 2A / 01"
  "Estudio 2A / 02"
  "Estudio 2A / 03"
  "Estudio 2A / 04"
  "Estudio 2A / 05"
)
# VALORES DEL BASELINE 1.0.0 (gbpublisher-baseline-1.0.0.sql, ids 29 a 33)
VIEJOS=(
  "14.00|20.00|2.00|2.00|2.00|2.00"
  "15.00|23.00|2.22|2.22|2.22|2.22"
  "17.00|24.00|2.42|2.42|2.42|2.42"
  "12.00|17.00|1.71|1.71|1.71|1.71"
  "15.50|22.50|2.24|2.24|2.24|2.24"
)
# VALORES QUE USA ESTUDIO 2A (BASE DE ALBERTO, 2026-10-09)
NUEVOS=(
  "14.00|20.00|2.00|2.00|2.00|2.00"
  "15.00|22.00|2.00|2.00|2.00|2.00"
  "17.00|24.00|2.00|2.00|2.00|2.00"
  "15.50|23.00|2.00|2.00|2.00|2.00"
  "15.50|22.50|2.24|2.24|2.24|2.24"
)

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
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.8.0${RESET}"
echo "-------------------------------------------------"
echo "Corrige los valores de los formatos de sistema «Estudio 2A / 01…05»."
echo "No cambia el esquema ni toca formatos propios (custom) ni datos editoriales."
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

if [ "$(valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLA}';")" != "1" ]; then
  error "No existe la tabla ${TABLA}."
  exit 1
fi

NIVEL="$(valor "SELECT GROUP_CONCAT(parche ORDER BY aplicado_en SEPARATOR ', ') FROM \`${DB}\`.esquema_version;")"
info "Nivel registrado: ${NIVEL}"

# LA CADENA ES ORDENADA: 1.8.0 VA SOBRE 1.7.0 (DECISIÓN DE ALBERTO: MISMA
# RIGIDEZ QUE EL RESTO DE LA CADENA, AUNQUE ESTE CAMBIO SEA SOLO DE DATOS)
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='actualizacion-1.7.0';")" != "1" ]; then
  error "Falta la actualización 1.7.0. Aplicala primero (actualizar-esquema-1.7.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL DE CADA FORMATO ---
# DEVUELVE LOS SEIS VALORES DE LA FILA DE SISTEMA, O VACÍO SI NO EXISTE.
# LA CLAVE ÚNICA ES (clasificacion, nombre_formato): A LO SUMO UNA FILA
valores_formato() {
  valor "SELECT CONCAT_WS('|', ancho, alto, margen_interior, margen_exterior, margen_superior, margen_inferior)
         FROM \`${DB}\`.\`${TABLA}\`
         WHERE clasificacion='${CLASIFICACION}' AND nombre_formato='$1' AND origen='sistema';"
}

PENDIENTES=()
for i in "${!NOMBRES[@]}"; do
  NOMBRE="${NOMBRES[$i]}"
  ACTUAL="$(valores_formato "$NOMBRE")"

  if [ -z "$ACTUAL" ]; then
    # SIN LA FILA NO HAY NADA QUE CORREGIR; UN ALTA NO ES TAREA DE ESTE SCRIPT
    error "No está el formato de sistema «${NOMBRE}» en ${CLASIFICACION}. No se modificó nada."
    exit 1
  elif [ "$ACTUAL" = "${NUEVOS[$i]}" ]; then
    ok "«${NOMBRE}» ya tiene los valores de Estudio 2A."
  elif [ "$ACTUAL" = "${VIEJOS[$i]}" ]; then
    PENDIENTES+=("$i")
  else
    # VALOR DESCONOCIDO: INTERVENCIÓN MANUAL QUE NO SE PISA
    error "«${NOMBRE}» tiene valores que este script no conoce: ${ACTUAL}"
    error "Se esperaba ${VIEJOS[$i]} (baseline) o ${NUEVOS[$i]} (Estudio 2A). No se modificó nada."
    exit 1
  fi
done

if [ "${#PENDIENTES[@]}" -eq 0 ]; then
  ok "No hay nada que modificar."
  SOLO_INFORME=1
else
  SOLO_INFORME=0
  info "Pendiente (ancho|alto|interior|exterior|superior|inferior, en cm):"
  for i in "${PENDIENTES[@]}"; do
    echo "    - ${NOMBRES[$i]}: ${VIEJOS[$i]}  ->  ${NUEVOS[$i]}"
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
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-1.8.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  # UNA SOLA TRANSACCIÓN: O SE CORRIGEN TODOS LOS PENDIENTES O NINGUNO.
  # EL WHERE REPITE LOS VALORES VIEJOS: SI ALGO CAMBIÓ DESDE EL PUNTO 3,
  # LA FILA NO SE TOCA Y LA VERIFICACIÓN POSTERIOR LO DETECTA
  SQL="START TRANSACTION;"
  for i in "${PENDIENTES[@]}"; do
    IFS='|' read -r V_AN V_AL V_MI V_ME V_MS V_MF <<< "${VIEJOS[$i]}"
    IFS='|' read -r N_AN N_AL N_MI N_ME N_MS N_MF <<< "${NUEVOS[$i]}"
    SQL+="
UPDATE \`${TABLA}\`
   SET ancho=${N_AN}, alto=${N_AL},
       margen_interior=${N_MI}, margen_exterior=${N_ME},
       margen_superior=${N_MS}, margen_inferior=${N_MF}
 WHERE clasificacion='${CLASIFICACION}' AND nombre_formato='${NOMBRES[$i]}' AND origen='sistema'
   AND ancho=${V_AN} AND alto=${V_AL}
   AND margen_interior=${V_MI} AND margen_exterior=${V_ME}
   AND margen_superior=${V_MS} AND margen_inferior=${V_MF};"
  done
  SQL+="
COMMIT;"
  mysql_adm "$DB" -e "$SQL"
  ok "Formatos actualizados."

  # --- 6. VERIFICACIÓN POSTERIOR ---
  # LOS CINCO, NO SOLO LOS PENDIENTES: EL ESTADO FINAL COMPLETO ES EL CONTRATO
  FALLA=0
  for i in "${!NOMBRES[@]}"; do
    ACTUAL="$(valores_formato "${NOMBRES[$i]}")"
    if [ "$ACTUAL" != "${NUEVOS[$i]}" ]; then
      error "«${NOMBRES[$i]}» quedó con ${ACTUAL}; se esperaba ${NUEVOS[$i]}."
      FALLA=1
    fi
  done
  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    # SIN innodb_strict_mode=0 LA RESTAURACIÓN FALLA EN articulos (GV-67)
    error "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"
    exit 1
  fi
  ok "Verificación correcta: los cinco formatos tienen los valores de Estudio 2A."

  # --- 7. REGISTRO ---
  mysql_adm "$DB" -e "INSERT IGNORE INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
  info "Para volver atrás: sudo mysql --init-command=\"SET SESSION innodb_strict_mode=0\" ${DB} < ${RESPALDO}"

else
  # YA ESTABA APLICADO DE HECHO (CASO DE LA MÁQUINA DE ALBERTO, CORREGIDA A
  # MANO): SE REGISTRA PARA QUE EL NIVEL DECLARADO REFLEJE EL ESTADO REAL
  if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
    mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
    ok "Los valores ya estaban; registrado en esquema_version como ${PARCHE}."
  fi
fi

# --- 8. INFORME DE CONTROL (SOLO LECTURA) ---
echo
info "Informe de control: formatos de sistema Estudio 2A"
mysql_adm "$DB" -e "SELECT nombre_formato, ancho, alto, margen_interior AS interior, margen_exterior AS exterior, margen_superior AS superior, margen_inferior AS inferior, activo FROM \`${TABLA}\` WHERE clasificacion='${CLASIFICACION}' AND nombre_formato LIKE 'Estudio 2A%' ORDER BY orden;"
echo "El informe no modifica nada."
echo
ok "${NEGRITA}Actualización 1.8.0 lista.${RESET}"
