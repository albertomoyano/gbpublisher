#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.1.0.sh
# Propósito : Actualización 2.1.0 de la base de gbpublisher. Cambia una sola
#             restricción: el CHECK chk_pieza_nombre de numero_pieza (las
#             preliminares del número, SC-88) pasa a aceptar la regla única
#             de los nombres de pieza, la del conversor de .docx (decisión
#             de Alberto del 21/11/2026):
#               fm-0N-NOMBRE, con NOMBRE en mayúsculas, dígitos y guiones, y
#               «NN-NOMBRE» de hasta 24 caracteres.
#             LO QUE YA ESTÁ QUEDA: el CHECK sigue aceptando la forma vieja
#             (fm-0N o fm-0N-nombre en minúsculas). No se modifica ninguna
#             fila. La aplicación nueva graba la forma nueva
#             (m_Numero.PiezasArchivos); al volver a guardar un número, sus
#             preliminares se reescriben con ella.
#             La misma regla está en m_OrdenPiezas.MotivoNombrePieza (Gambas)
#             y en el regex de engine/convertir_docx.sh (bash).
# Uso       : sudo bash actualizar-esquema-2.1.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Exige
#             la 2.0.0 registrada, como actualización o como baseline.
# Orden     : se aplica ANTES de usar la aplicación nueva: con el CHECK
#             viejo, grabar un número con preliminares falla. La aplicación
#             anterior sigue funcionando con el CHECK nuevo.
# Informe   : al final, SOLO DE LECTURA, cuenta los nombres que no siguen la
#             regla nueva en numero_pieza, capitulos y articulo. No los
#             corrige: se corrigen al escribirlos (alta o cambio).
# Volver    : volver a poner el CHECK viejo; el script muestra los dos
#             comandos. El respaldo queda por las dudas.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.1.0"
PREVIO="actualizacion-2.0.0"
PREVIO_BASELINE="baseline-2.0.0"
DESCRIPCION="Nombres de pieza: el CHECK de numero_pieza acepta la regla del conversor (fm-0N-NOMBRE)"
# EL RESPALDO VA A LA CARPETA DEL USUARIO QUE PIDIÓ EL PERMISO, NO A LA DE
# root: CON sudo, HOME ES /root (GV-235, MEDIDO EN MINT 22). sudo DEJA
# SUDO_USER Y pkexec DEJA PKEXEC_UID. GBP_DIR_RESPALDOS LO FIJA QUIEN LLAMA
USUARIO_RESPALDO="${SUDO_USER:-}"
if [ -z "$USUARIO_RESPALDO" ] && [ -n "${PKEXEC_UID:-}" ]; then
  USUARIO_RESPALDO="$(id -nu "$PKEXEC_UID" 2>/dev/null || true)"
fi
HOME_RESPALDO="$HOME"
if [ -n "$USUARIO_RESPALDO" ]; then
  HOME_RESPALDO="$(getent passwd "$USUARIO_RESPALDO" | cut -d: -f6 || true)"
  [ -n "$HOME_RESPALDO" ] || HOME_RESPALDO="$HOME"
fi
DIR_RESPALDO="${GBP_DIR_RESPALDOS:-${HOME_RESPALDO}/gbpublisher-respaldos}"

# AL SALIR, POR DONDE SEA, LA CARPETA Y LOS RESPALDOS QUEDAN A NOMBRE DE ESE
# USUARIO: SIN ESTO SERÍAN DE root Y NO LOS PODRÍA ABRIR NI BORRAR
entregar_respaldos() {
  if [ -n "$USUARIO_RESPALDO" ] && [ "$(id -u)" -eq 0 ] && [ -d "$DIR_RESPALDO" ]; then
    chown -R "${USUARIO_RESPALDO}:" "$DIR_RESPALDO" 2>/dev/null || true
  fi
}
trap entregar_respaldos EXIT
TABLA="numero_pieza"
RESTRICCION="chk_pieza_nombre"

# LA REGLA NUEVA PRIMERO; DESPUÉS LA VIEJA, PARA LO QUE YA ESTÁ. «{1,21}»:
# «NN-» SON 3 CARACTERES Y «NN-NOMBRE» LLEGA A 24 (m_OrdenPiezas)
PATRON_NUEVO='^fm-0[0-9]-[A-Z0-9-]{1,21}$|^fm-0[0-9](-[a-z0-9-]+)?$'
PATRON_VIEJO='^fm-0[0-9](-[a-z0-9-]+)?$'
# LA MARCA DEL ESTADO: SOLO EL CHECK NUEVO TIENE LA CLASE EN MAYÚSCULAS
MARCA_NUEVO='A-Z0-9-'

# REGLA COMPLETA PARA EL INFORME DE capitulos Y articulo
PATRON_PIEZA='^(fm|a|bm)-[0-9]{2}-[A-Z0-9-]{1,21}$'

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

# EL TEXTO DEL CHECK TAL COMO LO GUARDÓ MySQL (NORMALIZADO: _utf8mb4'...')
clausula_check() {
  valor "SELECT CHECK_CLAUSE FROM information_schema.CHECK_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_NAME='${RESTRICCION}';"
}

check_es_nuevo() {
  case "$(clausula_check)" in
    *"${MARCA_NUEVO}"*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.1.0${RESET}"
echo "--------------------------------------------------"
echo "Las preliminares del número aceptan la regla única de los nombres de"
echo "pieza (fm-0N-NOMBRE, en mayúsculas). No se modifica ninguna fila: lo"
echo "que ya está queda como está."
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

# LA 2.1.0 VA SOBRE LA 2.0.0, APLICADA COMO ACTUALIZACIÓN O INCLUIDA EN EL
# BASELINE (BBDD_LEEME.md §5)
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche IN ('${PREVIO}', '${PREVIO_BASELINE}');")" = "0" ]; then
  error "Falta la 2.0.0. Aplique primero actualizar-esquema-2.0.0.sh."
  exit 1
fi

if [ "$(existe_tabla "${TABLA}")" != "1" ]; then
  error "No existe la tabla ${TABLA}. No se modificó nada."
  exit 1
fi

if [ -z "$(clausula_check)" ]; then
  error "No existe la restricción ${RESTRICCION} en ${TABLA}. No se modificó nada."
  exit 1
fi

# --- 3. ESTADO REAL ---
VOLVER_1="sudo mysql ${DB} -e \"ALTER TABLE ${TABLA} DROP CHECK ${RESTRICCION};\""
VOLVER_2="sudo mysql ${DB} -e \"ALTER TABLE ${TABLA} ADD CONSTRAINT ${RESTRICCION} CHECK (regexp_like(nombre_archivo, '${PATRON_VIEJO}', 'c'));\""
APLICADO_AHORA=0

if check_es_nuevo; then
  ok "El CHECK de ${TABLA} ya acepta la regla nueva."
else
  info "CHECK actual: $(clausula_check)"

  # --- 4. CONFIRMACIÓN ---
  echo
  if [ "${GBP_SIN_PREGUNTAS:-0}" = "1" ]; then
    # LO LLAMA EL INSTALADOR, QUE YA PIDIÓ LA CONFIRMACIÓN (SC-107)
    RESPUESTA="SI"
  else
    read -r -p "Para continuar, escriba SI en mayúsculas: " RESPUESTA
  fi
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.1.0-$(date '+%Y%m%d-%H%M%S').sql"
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
  if ! grep -q "CREATE TABLE \`${TABLA}\`" "$RESPALDO"; then
    error "El respaldo no contiene la tabla ${TABLA}. No se modificó nada."
    exit 1
  fi
  ok "Respaldo verificado ($(du -h "$RESPALDO" | cut -f1))."

  FILAS_ANTES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA};")"

  # --- 6. EL CHECK ---
  # DOS SENTENCIAS: PRIMERO SE QUITA EL VIEJO, DESPUÉS SE PONE EL NUEVO CON
  # EL MISMO NOMBRE. SI EL NUEVO FALLA, SE REPONE EL VIEJO: LA TABLA NO
  # QUEDA SIN CONTROL
  mysql_adm "$DB" -e "ALTER TABLE ${TABLA} DROP CHECK ${RESTRICCION};"
  if ! mysql_adm "$DB" -e "ALTER TABLE ${TABLA} ADD CONSTRAINT ${RESTRICCION} CHECK (regexp_like(nombre_archivo, '${PATRON_NUEVO}', 'c'));"; then
    error "No se pudo poner el CHECK nuevo. Se repone el anterior."
    mysql_adm "$DB" -e "ALTER TABLE ${TABLA} ADD CONSTRAINT ${RESTRICCION} CHECK (regexp_like(nombre_archivo, '${PATRON_VIEJO}', 'c'));"
    exit 1
  fi
  APLICADO_AHORA=1

  # --- 7. VERIFICACIÓN POSTERIOR ---
  if ! check_es_nuevo; then
    error "El CHECK no quedó con la regla nueva: $(clausula_check)"
    error "NO se registra la actualización."
    exit 1
  fi
  FILAS_DESPUES="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA};")"
  if [ "$FILAS_ANTES" != "$FILAS_DESPUES" ]; then
    error "${TABLA} tenía ${FILAS_ANTES} filas y ahora tiene ${FILAS_DESPUES}. NO se registra la actualización."
    exit 1
  fi
  ok "Verificación correcta: CHECK nuevo, ${FILAS_DESPUES} filas sin cambios."
fi

# --- 8. REGISTRO ---
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
  mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 9. INFORME DE CONTROL (SOLO LECTURA) ---
# LOS NOMBRES QUE YA ESTÁN Y NO SIGUEN LA REGLA NUEVA. NO SE CORRIGEN: LA
# REGLA SE APLICA AL ESCRIBIR UN NOMBRE (ALTA O CAMBIO)
echo
info "Nombres que no siguen la regla nueva (quedan como están):"
N_NUMERO="$(valor "SELECT COUNT(*) FROM \`${DB}\`.numero_pieza
  WHERE NOT regexp_like(nombre_archivo, '^fm-0[0-9]-[A-Z0-9-]{1,21}$', 'c');")"
N_CAPITULOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.capitulos
  WHERE nombre_archivo IS NOT NULL AND NOT regexp_like(nombre_archivo, '${PATRON_PIEZA}', 'c');")"
N_ARTICULOS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.articulo
  WHERE nombre_archivo IS NOT NULL AND NOT regexp_like(nombre_archivo, '${PATRON_PIEZA}', 'c');")"
echo "  numero_pieza: ${N_NUMERO}   (se reescriben al volver a guardar cada número)"
echo "  capitulos:    ${N_CAPITULOS}"
echo "  articulo:     ${N_ARTICULOS}"
if [ "${N_CAPITULOS}" != "0" ]; then
  echo
  info "capitulos fuera de regla, por libro:"
  mysql_adm -t "$DB" -e "SELECT id_libro, nombre_archivo, tipo_capitulo FROM capitulos
    WHERE nombre_archivo IS NOT NULL AND NOT regexp_like(nombre_archivo, '${PATRON_PIEZA}', 'c')
    ORDER BY id_libro, nombre_archivo;"
fi

# --- 10. CÓMO VOLVER ATRÁS ---
if [ "$APLICADO_AHORA" = "1" ]; then
  echo
  info "Para volver atrás (CHECK anterior):"
  echo "  ${VOLVER_1}"
  echo "  ${VOLVER_2}"
fi

echo
ok "${NEGRITA}Actualización 2.1.0 lista.${RESET}"
