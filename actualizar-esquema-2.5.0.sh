#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-2.5.0.sh
# Propósito : Actualización 2.5.0 de la base de gbpublisher. BORRA la tabla
#             manual_ayudas, la de la ayuda contextual vieja (Ctrl+F1). La
#             ayuda es ahora un libro, l-AYUDA, hecho con la propia
#             aplicación; el menú «Acerca de…» abre su HTML instalado en
#             /usr/share/gbpublisher/manual (SC-112). La aplicación nueva ya
#             no lee la tabla ni la exige.
#             Antes de borrarla, deja un volcado SOLO de esa tabla junto al
#             respaldo completo: los textos de las ayudas viejas pueden servir
#             de borrador para el manual, y con ese archivo la tabla se
#             repone sola, sin restaurar toda la base.
# Uso       : sudo bash actualizar-esquema-2.5.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; respaldo verificado;
#             verificación posterior; sin efecto si ya está aplicado. Exige
#             la 2.4.0.
# Frenos    : una VIEW, una rutina o un disparador que nombre la tabla (se
#             romperían); una clave foránea que apunte a ella.
# Informa   : consultas guardadas de Estadísticas que nombran la tabla (van a
#             fallar al correrlas).
# Orden     : se aplica DESPUÉS de instalar la aplicación nueva, en todos los
#             puestos (SC-22, punto 5). La validación de arranque ignora una
#             tabla que sobra pero rechaza una esperada que falta: la versión
#             anterior de la aplicación no abre sin manual_ayudas.
# Volver    : sudo mysql gbpublisher < <volcado de la tabla>; el script
#             muestra el comando con el nombre del archivo.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-2.5.0"
PREVIO="actualizacion-2.4.0"
DESCRIPCION="Borra manual_ayudas: la ayuda es el libro l-AYUDA (SC-112)"
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
TABLA="manual_ayudas"

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

cantidad_tablas() {
  valor "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_TYPE='BASE TABLE';"
}

# UNA LISTA VACÍA DE GROUP_CONCAT LLEGA COMO NULL
lista() {
  local v
  v="$(valor "$1")"
  [ "$v" = "NULL" ] && v=""
  printf '%s' "$v"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 2.5.0${RESET}"
echo "--------------------------------------------------"
echo "Borra la tabla de la ayuda vieja (manual_ayudas): la ayuda es ahora el"
echo "manual que abre el menú «Acerca de…»."
echo
warn "Aplíquela DESPUÉS de instalar la versión nueva de gbpublisher en todos"
warn "los puestos: la versión anterior no abre sin esta tabla."
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

if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" = "0" ]; then
  error "Falta la 2.4.0. Aplique primero actualizar-esquema-2.4.0.sh."
  exit 1
fi

# --- 3. ESTADO REAL ---
if [ "$(existe_tabla "${TABLA}")" = "0" ]; then
  ok "La tabla ${TABLA} ya no está."
else
  FILAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.${TABLA};")"
  info "La tabla ${TABLA} tiene ${FILAS} ayudas. Se borra entera."

  # --- 4. FRENOS ---
  # LO QUE NOMBRA LA TABLA QUEDARÍA ROTO: UNA VIEW (ERROR 1356 AL LEERLA), UNA
  # RUTINA O UN DISPARADOR DE OTRA TABLA (FALLAN AL EJECUTARSE)
  FRENO=0
  VISTAS="$(lista "SELECT GROUP_CONCAT(TABLE_NAME) FROM information_schema.VIEWS
    WHERE TABLE_SCHEMA='${DB}' AND VIEW_DEFINITION LIKE '%\`${TABLA}\`%';")"
  if [ -n "$VISTAS" ]; then
    error "La tabla la usa la vista: ${VISTAS}"
    FRENO=1
  fi
  RUTINAS="$(lista "SELECT GROUP_CONCAT(ROUTINE_NAME) FROM information_schema.ROUTINES
    WHERE ROUTINE_SCHEMA='${DB}' AND ROUTINE_DEFINITION LIKE '%${TABLA}%';")"
  if [ -n "$RUTINAS" ]; then
    error "La tabla la usa la rutina: ${RUTINAS}"
    FRENO=1
  fi
  DISPARADORES="$(lista "SELECT GROUP_CONCAT(TRIGGER_NAME) FROM information_schema.TRIGGERS
    WHERE TRIGGER_SCHEMA='${DB}' AND EVENT_OBJECT_TABLE <> '${TABLA}'
      AND ACTION_STATEMENT LIKE '%${TABLA}%';")"
  if [ -n "$DISPARADORES" ]; then
    error "La tabla la usa el disparador: ${DISPARADORES}"
    FRENO=1
  fi
  # UNA CLAVE FORÁNEA HACIA LA TABLA HACE FALLAR EL DROP (ERROR 3730)
  CLAVES="$(lista "SELECT GROUP_CONCAT(CONCAT(TABLE_NAME, '.', CONSTRAINT_NAME))
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA='${DB}' AND REFERENCED_TABLE_NAME='${TABLA}';")"
  if [ -n "$CLAVES" ]; then
    error "Apuntan a la tabla las claves foráneas: ${CLAVES}"
    FRENO=1
  fi
  if [ "$FRENO" = "1" ]; then
    error "No se modificó nada."
    exit 1
  fi
  ok "Ninguna vista, rutina, disparador ni clave foránea usa la tabla."

  # --- 5. INFORME: LAS CONSULTAS GUARDADAS QUE VAN A FALLAR ---
  # SU TEXTO NO SE TOCA: SE AVISA PARA REVISARLAS EN Estadísticas
  if [ "$(existe_tabla consultas)" = "1" ]; then
    N_CONSULTAS="$(valor "SELECT COUNT(*) FROM \`${DB}\`.consultas WHERE editor_consultas LIKE '%${TABLA}%';")"
    if [ "$N_CONSULTAS" != "0" ]; then
      warn "${N_CONSULTAS} consulta(s) guardada(s) nombran la tabla. Revíselas en Estadísticas:"
      mysql_adm -t "$DB" -e "SELECT id, nombre FROM consultas WHERE editor_consultas LIKE '%${TABLA}%';"
    else
      ok "Ninguna consulta guardada nombra la tabla."
    fi
  fi

  # --- 6. CONFIRMACIÓN ---
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

  # --- 7. RESPALDO PREVIO VERIFICADO ---
  mkdir -p "$DIR_RESPALDO"
  SELLO="$(date '+%Y%m%d-%H%M%S')"
  RESPALDO="${DIR_RESPALDO}/gbpublisher-antes-2.5.0-${SELLO}.sql"
  VOLCADO_TABLA="${DIR_RESPALDO}/gbpublisher-${TABLA}-2.5.0-${SELLO}.sql"
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

  # --- 8. VOLCADO DE LA TABLA SOLA ---
  # CON ÉL LA TABLA SE REPONE SIN RESTAURAR TODA LA BASE, Y SUS TEXTOS QUEDAN
  # A MANO COMO BORRADOR DEL MANUAL
  info "Volcado de la tabla en ${VOLCADO_TABLA}"
  $SUDO mysqldump --single-transaction --default-character-set=utf8mb4 \
    "$DB" "$TABLA" > "$VOLCADO_TABLA"

  if [ ! -s "$VOLCADO_TABLA" ] || ! tail -n 1 "$VOLCADO_TABLA" | grep -q "Dump completed" \
     || ! grep -q "CREATE TABLE \`${TABLA}\`" "$VOLCADO_TABLA"; then
    error "El volcado de la tabla no quedó completo. No se modificó nada."
    exit 1
  fi
  if [ "$FILAS" != "0" ] && ! grep -q "INSERT INTO \`${TABLA}\`" "$VOLCADO_TABLA"; then
    error "El volcado de la tabla no trae sus ${FILAS} filas. No se modificó nada."
    exit 1
  fi
  ok "Volcado de la tabla verificado ($(du -h "$VOLCADO_TABLA" | cut -f1))."

  TABLAS_ANTES="$(cantidad_tablas)"

  # --- 9. BORRAR LA TABLA ---
  mysql_adm "$DB" -e "DROP TABLE \`${TABLA}\`;"

  # --- 10. VERIFICACIÓN POSTERIOR ---
  if [ "$(existe_tabla "${TABLA}")" != "0" ] || [ "$(cantidad_tablas)" != "$((TABLAS_ANTES - 1))" ]; then
    error "La tabla sigue o la cuenta de tablas no da. NO se registra la actualización."
    echo "  Para volver: sudo mysql ${DB} < ${RESPALDO}"
    exit 1
  fi
  # LAS VIEW SIGUEN LEYÉNDOSE
  for v in $(valor "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA='${DB}';"); do
    if ! mysql_adm "$DB" -e "SELECT 1 FROM \`${v}\` LIMIT 1;" >/dev/null 2>&1; then
      error "La vista ${v} quedó rota. NO se registra la actualización."
      echo "  Para volver: sudo mysql ${DB} < ${VOLCADO_TABLA}"
      exit 1
    fi
  done
  ok "Verificación correcta: ${TABLA} borrada; quedan $(cantidad_tablas) tablas y las vistas se leen."
  echo
  info "Para volver atrás (repone solo la tabla):"
  echo "  sudo mysql ${DB} < ${VOLCADO_TABLA}"
fi

# --- 11. REGISTRO ---
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
  mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

echo
ok "${NEGRITA}Actualización 2.5.0 lista.${RESET}"
