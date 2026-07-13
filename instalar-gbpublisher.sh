#!/usr/bin/env bash
#
# ============================================
# Script    : instalar-gbpublisher.sh
# Propósito : Instalación LIMPIA de la base de datos de gbpublisher en
#             máquinas de prueba. BORRA la base existente y la recrea
#             desde el archivo de distribución.
# Uso       : ./instalar-gbpublisher.sh
# Requisitos: MySQL/MariaDB instalado y en ejecución; permisos sudo;
#             el archivo 'gbpublisher-distribucion.sql' en esta misma carpeta.
# ============================================

set -euo pipefail

# --- 0. CONFIGURACIÓN ---
DB="gbpublisher"
DB_USER="app_user"
DB_PASS="AppUser2024!"
DUMP="gbpublisher-distribucion.sql"

# COLORES SOLO SI LA SALIDA ES UNA TERMINAL
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

# UBICAR EL DUMP JUNTO AL SCRIPT, SIN IMPORTAR DESDE DÓNDE SE INVOQUE
DIR_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUTA_DUMP="${DIR_SCRIPT}/${DUMP}"

# --- 1. BIENVENIDA ---
echo
echo "${NEGRITA}Instalación de la base de datos de gbpublisher${RESET}"
echo "-----------------------------------------------"
echo "Este asistente prepara la base de datos en una máquina nueva."
echo

# --- 2. VERIFICACIONES PREVIAS ---

# 2.1 EL CLIENTE mysql DEBE ESTAR DISPONIBLE
if ! command -v mysql >/dev/null 2>&1; then
  error "No se encontró el programa 'mysql'."
  error "Verificá que MySQL o MariaDB estén instalados."
  exit 1
fi

# 2.2 EL ARCHIVO DE DISTRIBUCIÓN DEBE EXISTIR
if [ ! -f "$RUTA_DUMP" ]; then
  error "No se encontró el archivo de distribución:"
  error "    $RUTA_DUMP"
  echo
  error "Colocá '${DUMP}' en la misma carpeta que este script y volvé a ejecutarlo."
  exit 1
fi

# 2.3 OBTENER PERMISOS DE ADMINISTRADOR (UNA SOLA VEZ)
info "Se pedirá tu contraseña del sistema para trabajar con la base de datos."
if ! sudo -v; then
  error "No se pudieron obtener permisos de administrador (sudo)."
  exit 1
fi

# 2.4 EL SERVIDOR DEBE RESPONDER
if ! sudo mysql -e "SELECT 1;" >/dev/null 2>&1; then
  error "No se pudo conectar al servidor de base de datos."
  error "Comprobá que el servicio esté activo, por ejemplo con:"
  error "    sudo systemctl status mariadb"
  exit 1
fi
ok "Todo listo para instalar."

# --- 3. CONFIRMACIÓN DE LA ACCIÓN DESTRUCTIVA ---
echo
warn "${NEGRITA}ATENCIÓN:${RESET} se BORRARÁ por completo la base de datos '${DB}'"
warn "junto con todos los datos de prueba que contenga. Esto no se puede deshacer."
echo
read -r -p "Para continuar, escribí SI en mayúsculas: " RESPUESTA
if [ "$RESPUESTA" != "SI" ]; then
  echo
  info "Instalación cancelada. No se modificó nada."
  exit 0
fi

# --- 4. BORRAR Y RECREAR LA BASE ---
echo
info "Eliminando la base de datos anterior (si existe)..."
sudo mysql -e "DROP DATABASE IF EXISTS \`${DB}\`;"

info "Creando la base de datos nueva con codificación UTF-8..."
sudo mysql -e "CREATE DATABASE \`${DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
ok "Base de datos '${DB}' creada."

# --- 5. USUARIO DE LA APLICACIÓN ---
# SE CREA ANTES DE IMPORTAR PARA QUE LOS DEFINER DE ROUTINES/TRIGGERS EXISTAN
info "Configurando el usuario de la aplicación..."
sudo mysql <<SQL
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
ok "Usuario '${DB_USER}' configurado."

# --- 6. IMPORTAR ESTRUCTURA Y CONFIGURACIÓN ---
info "Importando estructura y datos de configuración..."
# SE DESACTIVA innodb_strict_mode SOLO PARA ESTA SESIÓN DE IMPORTACIÓN.
# ALGUNAS TABLAS DE CONFIGURACIÓN TIENEN MUCHAS COLUMNAS VARCHAR Y SU DEFINICIÓN
# SUPERA EL LÍMITE TEÓRICO DE FILA DE INNODB (8126 BYTES EN PÁGINAS DE 16 KB).
# CON STRICT MODE DESACTIVADO, ESO PASA A SER UNA ADVERTENCIA EN LUGAR DE UN
# ERROR Y LA TABLA SE CREA NORMALMENTE. EL 'SET' SE ANTEPONE AL DUMP PARA QUE
# VALGA EN LA MISMA SESIÓN QUE EJECUTA TODOS LOS CREATE TABLE.
{ echo "SET SESSION innodb_strict_mode=OFF;"; cat "$RUTA_DUMP"; } | sudo mysql "${DB}"
ok "Contenido importado."

# --- 7. VERIFICACIÓN ---
N_TABLAS="$(sudo mysql -N -B -e \
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB}';")"
if [ "${N_TABLAS:-0}" -gt 0 ]; then
  ok "Verificación correcta: ${N_TABLAS} tablas presentes en '${DB}'."
else
  error "La importación no creó tablas. Revisá el archivo '${DUMP}'."
  exit 1
fi

# --- 8. CIERRE ---
echo
echo "${VERDE}${NEGRITA}Instalación completada.${RESET}"
echo "Ya podés abrir gbpublisher."
echo
