#!/usr/bin/env bash
#
# ============================================
# Script    : actualizar-esquema-1.34.0.sh
# Propósito : Actualización 1.34.0 de la base de gbpublisher. No toca tablas
#             ni datos: le da a la cuenta de la aplicación (app_user) el
#             permiso SHOW VIEW sobre la base, de solo lectura.
#             Por qué: el respaldo que la aplicación hace al cerrar
#             (FMain.RespaldarBaseDatos, con mysqldump y app_user) cortaba en
#             la primera VIEW de gbWeb (1.19.0) con «SHOW VIEW command
#             denied», y el archivo quedaba incompleto: sin las vistas ni las
#             tablas que mysqldump escribe después (vocabulario_termino). El
#             corte no se veía porque nadie miraba el resultado.
#             NO se da el permiso TRIGGER: con él, app_user podría borrar los
#             disparadores que hacen de articulo_reapertura un registro solo
#             de altas (1.23.0). El respaldo de la aplicación va sin
#             disparadores (--skip-triggers); tras restaurarlo, se reponen
#             corriendo otra vez la 1.23.0.
# Uso       : sudo bash actualizar-esquema-1.34.0.sh
# Reglas    : BBDD_LEEME.md §5 y SC-22. IDEMPOTENTE; verificación posterior;
#             sin efecto si ya está aplicado. Exige la 1.33.0 registrada.
#             SIN RESPALDO DE DATOS: no se modifica ninguna tabla. El permiso
#             vive en la base mysql, no en gbpublisher.
# Volver    : REVOKE SHOW VIEW ON `gbpublisher`.* FROM 'app_user'@'<host>';
#             el script muestra el comando para cada host.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
PARCHE="actualizacion-1.34.0"
PREVIO="actualizacion-1.33.0"
DESCRIPCION="Permiso SHOW VIEW para app_user: el respaldo de la aplicación incluye las vistas"
CUENTA="app_user"

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

# 1 SI LA CUENTA EN ESE HOST YA TIENE SHOW VIEW SOBRE LA BASE (POR SÍ O POR
# ALL PRIVILEGES, QUE information_schema DESPLIEGA PERMISO POR PERMISO)
tiene_show_view() {
  valor "SELECT COUNT(*) FROM information_schema.SCHEMA_PRIVILEGES
    WHERE GRANTEE = \"'${CUENTA}'@'$1'\" AND TABLE_SCHEMA = '${DB}' AND PRIVILEGE_TYPE = 'SHOW VIEW';"
}

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Actualización del esquema de gbpublisher a 1.34.0${RESET}"
echo "--------------------------------------------------"
echo "Le da a ${CUENTA} el permiso SHOW VIEW, para que el respaldo que hace"
echo "la aplicación al cerrar incluya las vistas. No toca tablas ni datos."
echo

# --- 2. VERIFICACIONES PREVIAS ---
if ! command -v mysql >/dev/null 2>&1; then
  error "Falta el cliente mysql."
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

# LA CADENA ES ORDENADA: 1.34.0 VA SOBRE 1.33.0
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PREVIO}';")" != "1" ]; then
  error "Falta la actualización 1.33.0. Aplicala primero (actualizar-esquema-1.33.0.sh)."
  exit 1
fi

# --- 3. ESTADO REAL: CADA HOST DE LA CUENTA ---
# LA CUENTA PUEDE EXISTIR PARA localhost Y PARA EL RANGO DE LA RED
# (instalar-gbpublisher.sh, INSTALACIONES CON SERVIDOR): CADA UNA ES UNA
# CUENTA DISTINTA PARA MySQL Y LLEVA SU PROPIO PERMISO
mapfile -t HOSTS < <(valor "SELECT Host FROM mysql.user WHERE User='${CUENTA}' ORDER BY Host;")
if [ "${#HOSTS[@]}" -eq 0 ]; then
  error "No existe la cuenta ${CUENTA} en el servidor. No se modificó nada."
  exit 1
fi

FALTAN=()
for H in "${HOSTS[@]}"; do
  if [ "$(tiene_show_view "$H")" = "1" ]; then
    ok "'${CUENTA}'@'${H}' ya tiene SHOW VIEW."
  else
    info "'${CUENTA}'@'${H}' no tiene SHOW VIEW."
    FALTAN+=("$H")
  fi
done

if [ "${#FALTAN[@]}" -gt 0 ]; then

  # --- 4. CONFIRMACIÓN ---
  echo
  read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
  if [ "$RESPUESTA" != "SI" ]; then
    warn "Cancelado. No se modificó nada."
    exit 0
  fi

  # --- 5. EL PERMISO ---
  for H in "${FALTAN[@]}"; do
    mysql_adm -e "GRANT SHOW VIEW ON \`${DB}\`.* TO '${CUENTA}'@'${H}';"
    ok "SHOW VIEW dado a '${CUENTA}'@'${H}'."
  done

  # --- 6. VERIFICACIÓN POSTERIOR ---
  FALLA=0
  for H in "${HOSTS[@]}"; do
    if [ "$(tiene_show_view "$H")" != "1" ]; then
      error "'${CUENTA}'@'${H}' sigue sin SHOW VIEW."
      FALLA=1
    fi
  done
  if [ "$FALLA" -ne 0 ]; then
    error "NO se registra la actualización."
    exit 1
  fi
  ok "Verificación correcta."
fi

# --- 7. REGISTRO ---
if [ "$(valor "SELECT COUNT(*) FROM \`${DB}\`.esquema_version WHERE parche='${PARCHE}';")" = "0" ]; then
  mysql_adm "$DB" -e "INSERT INTO esquema_version (parche, descripcion) VALUES ('${PARCHE}', '${DESCRIPCION}');"
  ok "Registrado en esquema_version como ${PARCHE}."
fi

# --- 8. CÓMO VOLVER ATRÁS ---
if [ "${#FALTAN[@]}" -gt 0 ]; then
  info "Para volver atrás:"
  for H in "${FALTAN[@]}"; do
    echo "  sudo mysql -e \"REVOKE SHOW VIEW ON \\\`${DB}\\\`.* FROM '${CUENTA}'@'${H}';\""
  done
fi

echo
ok "${NEGRITA}Actualización 1.34.0 lista.${RESET}"
